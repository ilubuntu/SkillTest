# -*- coding: utf-8 -*-
"""云测桥接执行管理器。"""

import json
import logging
import os
import shutil
import hashlib
import sys
import tempfile
import threading
import time
import urllib.parse
import urllib.request
import zipfile
from datetime import datetime
from typing import Any, Dict, Optional
import yaml

from agent_bench.cloud_api.client import report_status, upload_execution_result
from agent_bench.cloud_api.converter import (
    build_case,
    build_execution_result_payload,
    build_prompt,
    build_status_payload,
    map_internal_status_to_remote,
)
from agent_bench.cloud_api.models import CloudExecutionStartRequest, LocalCaseRunRequest, LocalTextStartRequest, RemoteExecutionStatus
from agent_bench.case_generation import generate_case_from_text
from agent_bench.pipeline.case_runner import run_single_case
from agent_bench.pipeline.constraint_adapter import sanitize_constraints_for_semantic_review
from agent_bench.pipeline.loader import load_agent, load_agents, load_yaml
from agent_bench.pipeline.artifacts import agent_meta_dir, agent_workspace_dir, diff_dir, original_project_dir, review_dir, static_dir
try:
    from agent_bench.uploader import create_uploader
    HAS_STORAGE_UPLOADER = True
except ImportError:
    HAS_STORAGE_UPLOADER = False


def _runtime_results_root() -> str:
    if getattr(sys, "frozen", False):
        base_dir = os.path.dirname(os.path.abspath(sys.executable))
    else:
        base_dir = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    return os.path.join(base_dir, "results")


RESULTS_ROOT = _runtime_results_root()
CACHE_ROOT = os.path.join(os.path.dirname(RESULTS_ROOT), "cache", "case_packages")
CLOUD_BASE_URL = "http://47.100.28.161:3000"
AGC_BUCKET_NAME = "agent-bench-lpgvk"
AGC_PROJECT_CLIENT_CONFIG = {
    "type": "project_client_id",
    "developer_id": "900086000150224722",
    "project_id": "101653523863785276",
    "client_id": "1919775246739619200",
    "client_secret": "D1A9970837E38AAB4B7D4AFBDCAEC1B0D6511662C7026DAE1808298342F9192C",
    "configuration_version": "3.0",
    "region": "CN",
}

STATUS_PUSH_INTERVAL_SECONDS = 2.0
STATUS_PUSH_DETAIL_FLUSH_SECONDS = 3.0
logger = logging.getLogger("agent_bench.executor")

STAGE_PENDING = "pending"
STAGE_PREPARING = "preparing"
STAGE_GENERATING = "generating"
STAGE_VALIDATING = "validating"
STAGE_CONSTRAINT_SCORING = "constraint_scoring"
STAGE_STATIC_SCORING = "static_scoring"
STAGE_COMPLETED = "completed"


def _now_iso() -> str:
    return datetime.now().isoformat(timespec="seconds")


def _now_stage_time() -> str:
    return datetime.now().strftime("%Y%m%d-%H:%M:%S")


def _safe_json(data: Any) -> str:
    try:
        return json.dumps(data, ensure_ascii=False, indent=2)
    except Exception:
        return str(data)


def _log_local_only(message: str, level: str = "INFO"):
    level_name = str(level or "INFO").upper()
    log_fn = {
        "DEBUG": logger.debug,
        "INFO": logger.info,
        "WARN": logger.warning,
        "WARNING": logger.warning,
        "ERROR": logger.error,
    }.get(level_name, logger.info)
    log_fn("%s", message)


def _append_jsonl(path: str, payload: Dict[str, Any]):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "a", encoding="utf-8") as f:
        f.write(json.dumps(payload, ensure_ascii=False) + "\n")


def _load_json_if_exists(path: str) -> Dict[str, Any]:
    if not path or not os.path.exists(path):
        return {}
    try:
        with open(path, "r", encoding="utf-8") as f:
            data = json.load(f)
        return data if isinstance(data, dict) else {}
    except Exception:
        return {}


def _write_json(path: str, payload: Dict[str, Any]):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        json.dump(payload, f, ensure_ascii=False, indent=2)


def _load_jsonl_tail(path: str, limit: int = 20) -> list[Dict[str, Any]]:
    if not path or not os.path.exists(path):
        return []
    items: list[Dict[str, Any]] = []
    try:
        with open(path, "r", encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                try:
                    item = json.loads(line)
                except Exception:
                    continue
                if isinstance(item, dict):
                    items.append(item)
    except Exception:
        return []
    return items[-limit:]


def _truncate_message(value: Any, limit: int = 100) -> str:
    text = str(value or "").strip()
    if len(text) <= limit:
        return text
    return text[:limit] + "..."


def _normalize_execution_detail_message(stage: str, message: str) -> Optional[str]:
    text = str(message or "").strip()
    if not text:
        return None
    if stage in {STAGE_GENERATING, STAGE_CONSTRAINT_SCORING, STAGE_STATIC_SCORING}:
        if "任务已发送" in text:
            return "任务已发送"
        if "已收到任务" in text:
            return "Agent已收到任务，会展示部分处理流程"
        if any(token in text for token in (
            "文件检查完成",
            "代码修改完成",
            "工具执行完成",
            "已生成代码补丁",
            "开始输出结果:",
            "输出预览",
        )):
            return _truncate_message(text, 160)
        if any(token in text for token in (
            "约束规则打分结果:",
            "静态代码打分结果:",
        )):
            return _truncate_message(text, 180)
        if any(token in text for token in (
            "开始处理任务",
            "模型开始思考",
            "开始分析",
            "开始检查工程和读取文件",
            "开始调用工具",
            "开始输出结果",
        )):
            return "正在处理"
        if "Agent处理完成, output=" in text:
            return _truncate_message(text, 180)
        if any(token in text for token in (
            "运行完成",
            "处理完成",
            "打分完成",
            "本轮执行结束: stop",
        )):
            return "Agent处理完成"
        return None
    return text


def _read_jsonl(path: str) -> list[Dict[str, Any]]:
    if not path or not os.path.exists(path):
        return []
    items: list[Dict[str, Any]] = []
    try:
        with open(path, "r", encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                try:
                    item = json.loads(line)
                except Exception:
                    continue
                if isinstance(item, dict):
                    items.append(item)
    except Exception:
        return []
    return items


def _upload_output_code_dir(side_dir: str, execution_id: int, on_progress=None) -> str:
    if not HAS_STORAGE_UPLOADER:
        return ""
    if not os.path.isdir(side_dir):
        return ""
    try:
        object_name = f"cloud_api/output_code/execution_{execution_id}_output.zip"
        if on_progress:
            on_progress("log", {"level": "WARN", "message": f"[cloud_api] 开始上传输出代码: {object_name}"})
        uploader = create_uploader(
            provider="agcCloudStorage",
            **{
                "project_id": AGC_PROJECT_CLIENT_CONFIG["project_id"],
                "client_id": AGC_PROJECT_CLIENT_CONFIG["client_id"],
                "client_secret": AGC_PROJECT_CLIENT_CONFIG["client_secret"],
                "developer_id": AGC_PROJECT_CLIENT_CONFIG["developer_id"],
                "credential_type": AGC_PROJECT_CLIENT_CONFIG["type"],
                "region": AGC_PROJECT_CLIENT_CONFIG["region"],
                "bucket_name": AGC_BUCKET_NAME,
            },
        )
        result = uploader.upload_directory(
            side_dir,
            object_name=object_name,
        )
        upload_url = result.get("download_url") or ""
        if on_progress:
            on_progress("log", {"level": "WARN", "message": f"[cloud_api] 输出代码上传完成: {upload_url}"})
        return upload_url
    except Exception as exc:
        if on_progress:
            on_progress("log", {"level": "ERROR", "message": f"[cloud_api] 输出代码上传失败: {exc}"})
        return ""


def _upload_diff_file(file_path: str, execution_id: int, on_progress=None) -> str:
    if not HAS_STORAGE_UPLOADER:
        return ""
    if not file_path or not os.path.isfile(file_path):
        return ""
    try:
        object_name = f"cloud_api/diff/execution_{execution_id}_changes.patch"
        if on_progress:
            on_progress("log", {"level": "WARN", "message": f"[cloud_api] 开始上传 diff 文件: {object_name}"})
        uploader = create_uploader(
            provider="agcCloudStorage",
            **{
                "project_id": AGC_PROJECT_CLIENT_CONFIG["project_id"],
                "client_id": AGC_PROJECT_CLIENT_CONFIG["client_id"],
                "client_secret": AGC_PROJECT_CLIENT_CONFIG["client_secret"],
                "developer_id": AGC_PROJECT_CLIENT_CONFIG["developer_id"],
                "credential_type": AGC_PROJECT_CLIENT_CONFIG["type"],
                "region": AGC_PROJECT_CLIENT_CONFIG["region"],
                "bucket_name": AGC_BUCKET_NAME,
            },
        )
        result = uploader.upload_file(
            file_path=file_path,
            object_name=object_name,
            content_type="text/x-diff",
        )
        upload_url = result.get("download_url") or ""
        if on_progress:
            on_progress("log", {"level": "WARN", "message": f"[cloud_api] diff 文件上传完成: {upload_url}"})
        return upload_url
    except Exception as exc:
        if on_progress:
            on_progress("log", {"level": "ERROR", "message": f"[cloud_api] diff 文件上传失败: {exc}"})
        return ""


def _emit_prepare_log(on_progress, message: str):
    if on_progress:
        on_progress("log", {"level": "INFO", "message": message})


def _parse_constraints_from_expected_output(expected_output: str) -> list[dict]:
    text = str(expected_output or "").strip()
    if not text:
        return []
    try:
        parsed = yaml.safe_load(text)
    except Exception:
        return []

    if isinstance(parsed, dict):
        constraints = parsed.get("constraints")
        return sanitize_constraints_for_semantic_review(constraints) if isinstance(constraints, list) else []
    if isinstance(parsed, list):
        return sanitize_constraints_for_semantic_review(parsed)
    return []


def _infer_scenario_from_constraints(constraints: list[dict]) -> str:
    if not isinstance(constraints, list):
        return ""

    for item in constraints:
        if not isinstance(item, dict):
            continue
        constraint_id = str(item.get("id") or "").strip().upper()
        if constraint_id.startswith("HM-BUG_FIX-") or constraint_id.startswith("HM-BUGFIX-"):
            return "bug_fix"
        if constraint_id.startswith("HM-PERF-"):
            return "performance"
        if constraint_id.startswith("HM-REQ-"):
            return "requirement"
    return ""


def _log_constraints_summary(on_progress, constraints: list[dict]):
    if not constraints:
        return
    public_count = sum(
        1
        for item in constraints
        if isinstance(item, dict) and bool(item.get("is_public"))
    )
    if public_count > 0:
        _emit_prepare_log(on_progress, f"已解析约束规则，共 {len(constraints)} 条，其中公共约束 {public_count} 条:")
    else:
        _emit_prepare_log(on_progress, f"已解析约束规则，共 {len(constraints)} 条:")
    for item in constraints:
        if not isinstance(item, dict):
            continue
        rule_id = str(item.get("id") or "").strip()
        name = str(item.get("name") or "").strip()
        description = str(item.get("description") or "").strip()
        prefix = "[公共] " if bool(item.get("is_public")) else ""
        summary = f"- {prefix}{rule_id} | {name}"
        if description:
            summary += f" | {description}"
        _emit_prepare_log(on_progress, summary)


def _cache_archive_path(file_url: str) -> str:
    parsed = urllib.parse.urlparse(file_url)
    suffix = os.path.splitext(parsed.path or "")[1] or ".zip"
    cache_key = hashlib.sha256(file_url.encode("utf-8")).hexdigest()
    os.makedirs(CACHE_ROOT, exist_ok=True)
    return os.path.join(CACHE_ROOT, f"{cache_key}{suffix}")


def _download_file(file_url: str, target_path: str, on_progress=None):
    parsed = urllib.parse.urlparse(file_url)
    if parsed.scheme in ("http", "https", "file"):
        _emit_prepare_log(on_progress, "缓存不存在，从网上下载工程包")
        _emit_prepare_log(on_progress, f"正在下载工程包: {file_url}")
        with urllib.request.urlopen(file_url, timeout=60) as response, open(target_path, "wb") as f:
            shutil.copyfileobj(response, f)
        _emit_prepare_log(on_progress, f"工程包下载完成: {target_path}")
        return

    if os.path.exists(file_url):
        shutil.copyfile(file_url, target_path)
        return

    raise FileNotFoundError(f"无法访问 fileUrl: {file_url}")


def _looks_like_project_root(path: str) -> bool:
    markers = [
        os.path.join(path, "entry", "src", "main"),
        os.path.join(path, "build-profile.json5"),
        os.path.join(path, "hvigorfile.ts"),
    ]
    return any(os.path.exists(marker) for marker in markers)


def _find_project_root(search_root: str) -> str:
    if _looks_like_project_root(search_root):
        return search_root

    candidates = []
    for current_root, dirs, _files in os.walk(search_root):
        if _looks_like_project_root(current_root):
            depth = current_root.count(os.sep)
            candidates.append((depth, current_root))
    if candidates:
        candidates.sort(key=lambda item: item[0])
        return candidates[0][1]
    raise FileNotFoundError(f"未在下载内容中找到可执行工程目录: {search_root}")


def _prepare_project_from_file_url(file_url: str, target_dir: str, on_progress=None) -> str:
    os.makedirs(target_dir, exist_ok=True)
    parsed = urllib.parse.urlparse(file_url)
    _emit_prepare_log(on_progress, f"测试用例工程地址: {file_url}")

    if not parsed.scheme and os.path.isdir(file_url):
        _emit_prepare_log(on_progress, f"检测到本地工程目录，直接使用: {file_url}")
        return _find_project_root(file_url)

    archive_path = os.path.join(target_dir, "source.zip")
    cache_path = _cache_archive_path(file_url)
    _emit_prepare_log(on_progress, f"先检查本地缓存: {cache_path}")
    if os.path.exists(cache_path) and os.path.getsize(cache_path) > 0:
        _emit_prepare_log(on_progress, f"本地缓存已命中，使用缓存工程包: {cache_path}")
    else:
        _download_file(file_url, cache_path, on_progress=on_progress)
    shutil.copyfile(cache_path, archive_path)

    if not zipfile.is_zipfile(archive_path):
        raise ValueError(f"当前仅支持 zip 类型工程包: {file_url}")

    extract_dir = os.path.join(target_dir, "extracted")
    os.makedirs(extract_dir, exist_ok=True)
    with zipfile.ZipFile(archive_path, "r") as zip_ref:
        zip_ref.extractall(extract_dir)
    _emit_prepare_log(on_progress, f"工程包已解压到任务执行沙箱: {extract_dir}")

    return _find_project_root(extract_dir)


class CloudExecutionManager:
    def __init__(self):
        self._lock = threading.Lock()
        self._states: Dict[int, Dict[str, Any]] = {}
        self._active_execution_id: Optional[int] = None
        self._worker_thread: Optional[threading.Thread] = None
        self._status_threads: Dict[int, threading.Thread] = {}

    def reset_runtime_state(self) -> Dict[str, int]:
        with self._lock:
            local_state_count = len(self._states)
            status_thread_count = len(self._status_threads)
            for state in self._states.values():
                state["status_push_stop"] = True
            self._states.clear()
            self._active_execution_id = None
            self._worker_thread = None
            self._status_threads.clear()
        return {
            "local_state_count": local_state_count,
            "status_thread_count": status_thread_count,
        }

    def _default_progress_upload_state(self) -> Dict[str, Any]:
        return {
            "last_payload_signature": "",
            "last_reported_stage": "",
            "last_reported_status": "",
            "last_detail_change_at": 0.0,
            "last_reported_at_epoch": 0.0,
            "last_response_ok": None,
        }

    def _load_progress_upload_state(self, path: str) -> Dict[str, Any]:
        state = self._default_progress_upload_state()
        state.update(_load_json_if_exists(path))
        return state

    def _save_progress_upload_state(self, path: str, state: Dict[str, Any]):
        _write_json(path, state)

    def _stage_message(self, local_status: str, local_stage: str) -> str:
        if local_status == "failed":
            return "任务执行失败"
        mapping = {
            STAGE_PENDING: "任务排队中",
            STAGE_PREPARING: "执行环境准备中",
            STAGE_GENERATING: "Agent正在处理",
            STAGE_VALIDATING: "结果验证中",
            STAGE_CONSTRAINT_SCORING: "约束规则打分中",
            STAGE_STATIC_SCORING: "静态代码打分中",
            STAGE_COMPLETED: "任务执行完成",
        }
        return mapping.get(local_stage, "任务处理中")

    def _ensure_stage_entry(self, state: Dict[str, Any], stage: str, message: Optional[str] = None):
        logs = state.setdefault("execution_log", [])
        for entry in logs:
            if str(entry.get("stage") or "") != stage:
                continue
            if message:
                entry["message"] = message
            return entry
        entry = {
            "stage": stage,
            "message": message or self._stage_message(str(state.get("local_status") or ""), stage),
            "detail": [],
        }
        logs.append(entry)
        state["updated_at"] = _now_iso()
        return entry

    def _append_execution_detail(self, state: Dict[str, Any], stage: str, message: str):
        normalized_message = _normalize_execution_detail_message(stage, message)
        if not normalized_message:
            return
        entry = self._ensure_stage_entry(state, stage)
        details = entry.setdefault("detail", [])
        if normalized_message == "正在处理":
            for item in details:
                if str(item.get("message") or "").strip() == normalized_message:
                    return
        if details and str(details[-1].get("message") or "").strip() == normalized_message:
            return
        details.append({
            "time": _now_stage_time(),
            "message": normalized_message,
        })
        state["updated_at"] = _now_iso()
        upload_state_path = str(state.get("progress_upload_state_path") or "").strip()
        if upload_state_path:
            upload_state = self._load_progress_upload_state(upload_state_path)
            upload_state["last_detail_change_at"] = time.time()
            self._save_progress_upload_state(upload_state_path, upload_state)

    def _build_execution_log_snapshot(self, state: Dict[str, Any]) -> list[Dict[str, Any]]:
        return json.loads(json.dumps(state.get("execution_log") or []))

    def _should_report_status(self, state: Dict[str, Any], should_stop: bool) -> bool:
        upload_state_path = str(state.get("progress_upload_state_path") or "").strip()
        upload_state = self._load_progress_upload_state(upload_state_path) if upload_state_path else self._default_progress_upload_state()
        current_status = str(state.get("local_status") or "")
        current_stage = str(state.get("local_stage") or "")
        last_status = str(upload_state.get("last_reported_status") or "")
        last_stage = str(upload_state.get("last_reported_stage") or "")
        last_detail_change_at = float(upload_state.get("last_detail_change_at") or 0.0)
        last_reported_at = float(upload_state.get("last_reported_at_epoch") or 0.0)
        if should_stop or current_status in {"completed", "failed"}:
            return True
        if current_status != last_status or current_stage != last_stage:
            return True
        if last_reported_at > 0 and (time.time() - last_reported_at) < STATUS_PUSH_DETAIL_FLUSH_SECONDS:
            return False
        if last_detail_change_at > last_reported_at and (time.time() - last_reported_at) >= STATUS_PUSH_DETAIL_FLUSH_SECONDS:
            return True
        return False

    def _get_report_execution_id(self, state: Dict[str, Any]) -> int:
        try:
            target = int(state.get("report_execution_id") or 0)
        except Exception:
            target = 0
        if target > 0:
            return target
        return int(state.get("execution_id") or 0)

    def _should_push_remote_status(self, state: Dict[str, Any]) -> bool:
        return (
            self._get_report_execution_id(state) > 0
            and bool(str(state.get("cloud_base_url") or "").strip())
        )

    def _start_status_thread_locked(self, execution_id: int):
        thread = self._status_threads.get(execution_id)
        if thread and thread.is_alive():
            return
        status_thread = threading.Thread(
            target=self._status_report_loop,
            args=(execution_id,),
            daemon=True,
        )
        self._status_threads[execution_id] = status_thread
        status_thread.start()

    def _ensure_progress_upload_state(self, state: Dict[str, Any], run_dir: str):
        if not self._should_push_remote_status(state):
            return
        normalized_run_dir = str(run_dir or "").strip()
        if not normalized_run_dir:
            return
        current_path = str(state.get("progress_upload_state_path") or "").strip()
        if current_path:
            return
        state["progress_upload_state_path"] = os.path.join(normalized_run_dir, "progress_upload_state.json")
        self._save_progress_upload_state(state["progress_upload_state_path"], self._default_progress_upload_state())

    def _upload_remote_result(
        self,
        state: Dict[str, Any],
        case_dir: str,
        result: Dict[str, Any],
        expected_output: str,
        execution_time_ms: int,
        on_progress=None,
    ):
        if not self._should_push_remote_status(state):
            return

        report_execution_id = self._get_report_execution_id(state)
        output_code_url = str(state.get("output_code_url") or "").strip()
        diff_file_url = str(state.get("diff_file_url") or "").strip()
        if not output_code_url:
            output_code_url = _upload_output_code_dir(
                agent_workspace_dir(case_dir),
                execution_id=report_execution_id,
                on_progress=on_progress,
            )
        if not diff_file_url:
            diff_file_url = _upload_diff_file(
                os.path.join(diff_dir(case_dir), "changes.patch"),
                execution_id=report_execution_id,
                on_progress=on_progress,
            )

        result_payload = build_execution_result_payload(
            execution_id=report_execution_id,
            case_dir=case_dir,
            result=result,
            expected_output=expected_output,
            execution_time_ms=execution_time_ms,
            output_code_url=output_code_url,
            diff_file_url=diff_file_url,
            code_quality_score=None,
            expected_output_score=None,
        )

        state["output_code_url"] = output_code_url
        state["diff_file_url"] = diff_file_url
        state["last_result_payload"] = result_payload
        self._append_cloud_event(state, "result_report_request", {
            "url": f"{(state.get('cloud_base_url') or CLOUD_BASE_URL).rstrip('/')}/api/execution-results",
            "payload": result_payload,
            "has_token": bool((state.get("token") or "").strip()),
        })
        self._append_local_event(state, "result_report_request", {
            "payload": result_payload,
        })
        _log_local_only(f"上传任务报告请求:\n{_safe_json(result_payload)}")

        result_response = upload_execution_result(
            cloud_base_url=state.get("cloud_base_url") or CLOUD_BASE_URL,
            payload=result_payload,
            token=(state.get("token") or "").strip() or None,
        )
        state["last_result_response"] = result_response
        self._append_cloud_event(state, "result_report_response", {
            "payload": result_payload,
            "response": result_response,
        })
        self._append_local_event(state, "result_report_response", {
            "response": result_response,
        })
        _log_local_only(f"上传任务报告响应:\n{_safe_json(result_response)}")

    def start(self, payload: CloudExecutionStartRequest, local_base_url: str):
        with self._lock:
            if self._worker_thread and self._worker_thread.is_alive():
                return False, "当前已有云测执行任务运行中"

            state = {
                "execution_id": payload.executionId,
                "report_execution_id": payload.executionId,
                "cloud_base_url": (payload.cloudBaseUrl or CLOUD_BASE_URL).rstrip("/"),
                "agent_id": payload.agentId,
                "token": (payload.token or "").strip(),
                "test_case": payload.testCase.model_dump(),
                "local_status": "pending",
                "local_stage": STAGE_PENDING,
                "error_message": "",
                "conversation": [],
                "execution_log": [],
                "status_push_stop": False,
                "created_at": _now_iso(),
                "updated_at": _now_iso(),
                "run_dir": "",
                "case_dir": "",
                "output_code_url": "",
                "sse_log_path": "",
                "sse_progress_log_path": "",
                "progress_queue_path": "",
                "progress_upload_state_path": "",
                "last_status_payload": None,
                "last_status_response": None,
                "last_result_payload": None,
                "last_result_response": None,
            }
            self._states[payload.executionId] = state
            self._active_execution_id = payload.executionId
            logger.info(
                "收到任务下发 taskId=%s 任务=%s 工程包=%s",
                payload.executionId,
                _truncate_message(payload.testCase.input, 300),
                payload.testCase.fileUrl,
            )
            self._ensure_stage_entry(state, STAGE_PENDING, "任务排队中")

            self._start_status_thread_locked(payload.executionId)

            thread = threading.Thread(
                target=self._run_execution,
                args=(payload, local_base_url),
                daemon=True,
            )
            self._worker_thread = thread
            thread.start()
            return True, "任务已接收"

    def start_local_text(self, payload: LocalTextStartRequest, local_base_url: str):
        with self._lock:
            if self._worker_thread and self._worker_thread.is_alive():
                return False, "Task already running", None

            execution_id = int(time.time() * 1000)
            while execution_id in self._states:
                execution_id += 1

            report_execution_id = int(payload.reportExecutionId or 0)
            state = {
                "execution_id": execution_id,
                "report_execution_id": report_execution_id,
                "cloud_base_url": (payload.cloudBaseUrl or CLOUD_BASE_URL).rstrip("/") if report_execution_id > 0 else "",
                "agent_id": payload.agentId,
                "token": (payload.token or "").strip(),
                "test_case": {
                    "input": payload.input,
                    "expectedOutput": payload.expectedOutput,
                    "fileUrl": payload.originalProjectDir,
                },
                "local_status": "pending",
                "local_stage": STAGE_PENDING,
                "error_message": "",
                "conversation": [],
                "execution_log": [],
                "status_push_stop": not (report_execution_id > 0),
                "created_at": _now_iso(),
                "updated_at": _now_iso(),
                "run_dir": "",
                "case_dir": "",
                "case_id": "",
                "case_title": payload.title or "",
                "output_code_url": "",
                "sse_log_path": "",
                "sse_progress_log_path": "",
                "progress_queue_path": "",
                "progress_upload_state_path": "",
                "last_status_payload": None,
                "last_status_response": None,
                "last_result_payload": None,
                "last_result_response": None,
                "mode": "local_text",
            }
            self._states[execution_id] = state
            self._active_execution_id = execution_id
            self._ensure_stage_entry(state, STAGE_PENDING, "queued")

            if self._should_push_remote_status(state):
                self._start_status_thread_locked(execution_id)

            thread = threading.Thread(
                target=self._run_local_text_execution,
                args=(execution_id, payload, local_base_url),
                daemon=True,
            )
            self._worker_thread = thread
            thread.start()
            return True, "Task accepted", execution_id

    def generate_local_text_case(self, payload: LocalTextStartRequest, local_base_url: str):
        _ = local_base_url
        execution_id = int(time.time() * 1000)
        with self._lock:
            while execution_id in self._states:
                execution_id += 1

            report_execution_id = int(payload.reportExecutionId or 0)
            state = {
                "execution_id": execution_id,
                "report_execution_id": report_execution_id,
                "cloud_base_url": (payload.cloudBaseUrl or CLOUD_BASE_URL).rstrip("/") if report_execution_id > 0 else "",
                "agent_id": payload.agentId,
                "token": (payload.token or "").strip(),
                "test_case": {
                    "input": payload.input,
                    "expectedOutput": payload.expectedOutput,
                    "fileUrl": payload.originalProjectDir,
                },
                "local_status": "running",
                "local_stage": STAGE_PREPARING,
                "error_message": "",
                "conversation": [],
                "execution_log": [],
                "status_push_stop": not (report_execution_id > 0),
                "created_at": _now_iso(),
                "updated_at": _now_iso(),
                "run_dir": "",
                "case_dir": "",
                "case_id": "",
                "case_title": payload.title or "",
                "output_code_url": "",
                "sse_log_path": "",
                "sse_progress_log_path": "",
                "progress_queue_path": "",
                "progress_upload_state_path": "",
                "last_status_payload": None,
                "last_status_response": None,
                "last_result_payload": None,
                "last_result_response": None,
                "mode": "local_text_generate_only",
            }
            self._states[execution_id] = state
            self._active_execution_id = execution_id
            self._ensure_stage_entry(state, STAGE_PREPARING, "generating_case")
            self._append_conversation(state, "status", "Case generation started")
            if self._should_push_remote_status(state):
                self._start_status_thread_locked(execution_id)

        try:
            generated = generate_case_from_text(
                text=payload.input,
                source_project_dir=payload.originalProjectDir,
                preferred_scenario=payload.scenario,
                title=payload.title,
                expected_output=payload.expectedOutput,
            )
            with self._lock:
                state = self._states[execution_id]
                state["case_dir"] = str(generated.get("case_dir") or "")
                state["case_id"] = str(generated.get("case_id") or "")
                state["case_title"] = str(generated.get("title") or payload.title or "")
                state["generated_case"] = generated
                state["local_status"] = "completed"
                state["local_stage"] = STAGE_COMPLETED
                state["updated_at"] = _now_iso()
                self._ensure_stage_entry(state, STAGE_COMPLETED, "case_generated")
                self._append_execution_detail(state, STAGE_PREPARING, f"case ??: {state['case_dir']}")
                self._append_execution_detail(state, STAGE_COMPLETED, "Case generation completed")
                self._append_conversation(state, "status", f"Generated case {state['case_id']}")
            return True, "Task accepted", execution_id
        except Exception as exc:
            with self._lock:
                state = self._states[execution_id]
                state["local_status"] = "failed"
                state["error_message"] = str(exc)
                state["updated_at"] = _now_iso()
                self._append_conversation(state, "error", str(exc), "ERROR")
            return False, str(exc), execution_id
        finally:
            with self._lock:
                current = self._states.get(execution_id) or {}
                if self._should_push_remote_status(current):
                    current["status_push_stop"] = True
                self._active_execution_id = None

    def start_local_text_pipeline(self, payload: LocalTextStartRequest, local_base_url: str):
        with self._lock:
            if self._worker_thread and self._worker_thread.is_alive():
                return False, "Task already running", None

            execution_id = int(time.time() * 1000)
            while execution_id in self._states:
                execution_id += 1

            report_execution_id = int(payload.reportExecutionId or 0)
            state = {
                "execution_id": execution_id,
                "report_execution_id": report_execution_id,
                "cloud_base_url": (payload.cloudBaseUrl or CLOUD_BASE_URL).rstrip("/") if report_execution_id > 0 else "",
                "agent_id": "agent_default",
                "generation_agent_id": payload.agentId or "case_generation_agent",
                "token": (payload.token or "").strip(),
                "test_case": {
                    "input": payload.input,
                    "expectedOutput": payload.expectedOutput,
                    "fileUrl": payload.originalProjectDir,
                },
                "local_status": "pending",
                "local_stage": STAGE_PENDING,
                "error_message": "",
                "conversation": [],
                "execution_log": [],
                "status_push_stop": not (report_execution_id > 0),
                "created_at": _now_iso(),
                "updated_at": _now_iso(),
                "run_dir": "",
                "case_dir": "",
                "generated_case_dir": "",
                "case_id": "",
                "case_title": payload.title or "",
                "output_code_url": "",
                "sse_log_path": "",
                "sse_progress_log_path": "",
                "progress_queue_path": "",
                "progress_upload_state_path": "",
                "last_status_payload": None,
                "last_status_response": None,
                "last_result_payload": None,
                "last_result_response": None,
                "mode": "local_text_pipeline",
            }
            self._states[execution_id] = state
            self._active_execution_id = execution_id
            self._ensure_stage_entry(state, STAGE_PENDING, "queued")

            if self._should_push_remote_status(state):
                self._start_status_thread_locked(execution_id)

            thread = threading.Thread(
                target=self._run_local_text_pipeline,
                args=(execution_id, payload, local_base_url),
                daemon=True,
            )
            self._worker_thread = thread
            thread.start()
            return True, "Task accepted", execution_id

    def start_local_case_execution(self, payload: LocalCaseRunRequest, local_base_url: str):
        with self._lock:
            if self._worker_thread and self._worker_thread.is_alive():
                return False, "Task already running", None

            execution_id = int(time.time() * 1000)
            while execution_id in self._states:
                execution_id += 1

            report_execution_id = int(payload.reportExecutionId or 0)
            state = {
                "execution_id": execution_id,
                "report_execution_id": report_execution_id,
                "cloud_base_url": (payload.cloudBaseUrl or CLOUD_BASE_URL).rstrip("/") if report_execution_id > 0 else "",
                "agent_id": payload.agentId or "agent_default",
                "generation_agent_id": "",
                "token": (payload.token or "").strip(),
                "test_case": {
                    "input": "",
                    "expectedOutput": "",
                    "fileUrl": payload.caseDir,
                },
                "local_status": "pending",
                "local_stage": STAGE_PENDING,
                "error_message": "",
                "conversation": [],
                "execution_log": [],
                "status_push_stop": not (report_execution_id > 0),
                "created_at": _now_iso(),
                "updated_at": _now_iso(),
                "run_dir": "",
                "case_dir": "",
                "generated_case_dir": payload.caseDir,
                "case_id": "",
                "case_title": "",
                "output_code_url": "",
                "sse_log_path": "",
                "sse_progress_log_path": "",
                "progress_queue_path": "",
                "progress_upload_state_path": "",
                "last_status_payload": None,
                "last_status_response": None,
                "last_result_payload": None,
                "last_result_response": None,
                "mode": "local_case_execution",
            }
            self._states[execution_id] = state
            self._active_execution_id = execution_id
            self._ensure_stage_entry(state, STAGE_PENDING, "queued")

            if self._should_push_remote_status(state):
                self._start_status_thread_locked(execution_id)

            thread = threading.Thread(
                target=self._run_local_case_execution,
                args=(execution_id, payload, local_base_url),
                daemon=True,
            )
            self._worker_thread = thread
            thread.start()
            return True, "Case execution accepted", execution_id

    def get_state(self, execution_id: Optional[int] = None) -> Optional[Dict[str, Any]]:
        with self._lock:
            if execution_id is None:
                if self._active_execution_id is not None:
                    execution_id = self._active_execution_id
                elif self._states:
                    execution_id = list(sorted(self._states.keys()))[-1]
            if execution_id is None:
                return None
            state = self._states.get(execution_id)
            if not state:
                return None
            return json.loads(json.dumps(state))

    def list_states(self) -> list[Dict[str, Any]]:
        with self._lock:
            states = [json.loads(json.dumps(item)) for item in self._states.values()]
        states.sort(key=lambda item: (item.get("created_at") or "", item.get("execution_id") or 0), reverse=True)
        return states

    def _append_conversation(self, state: Dict[str, Any], item_type: str, message: str, level: str = "INFO"):
        record = {
            "timestamp": _now_iso(),
            "type": item_type,
            "level": level,
            "message": message,
        }
        state["conversation"].append(record)
        state["conversation"] = state["conversation"][-200:]
        self._log_runtime_event(state, record)
        self._append_local_event(state, "conversation", record)

    def _log_runtime_event(self, state: Dict[str, Any], record: Dict[str, Any]):
        item_type = str(record.get("type") or "").strip() or "event"
        message = str(record.get("message") or "").strip()
        level_name = str(record.get("level") or "INFO").upper()
        item_label = {
            "status": "状态",
            "prepare": "准备",
            "stage_start": "开始",
            "stage_done": "结束",
            "error": "错误",
            "case_done": "完成",
        }.get(item_type, item_type)
        if item_type == "log":
            prefix = ""
        else:
            prefix = f"[{item_label}] "
        log_fn = {
            "DEBUG": logger.debug,
            "INFO": logger.info,
            "WARN": logger.warning,
            "WARNING": logger.warning,
            "ERROR": logger.error,
        }.get(level_name, logger.info)
        log_fn("%s%s", prefix, message)

    def _append_local_event(self, state: Dict[str, Any], event_type: str, payload: Dict[str, Any]):
        run_dir = str(state.get("run_dir") or "").strip()
        if not run_dir:
            return
        log_path = os.path.join(run_dir, "executor_events.jsonl")
        _append_jsonl(log_path, {
            "timestamp": _now_iso(),
            "event": event_type,
            "payload": payload,
        })

    def _append_cloud_event(self, state: Dict[str, Any], event_type: str, payload: Dict[str, Any]):
        run_dir = str(state.get("run_dir") or "").strip()
        if not run_dir:
            return
        log_path = os.path.join(run_dir, "cloud_api_events.jsonl")
        _append_jsonl(log_path, {
            "timestamp": _now_iso(),
            "event": event_type,
            "payload": payload,
        })

    def _report_remote_status(self, state: Dict[str, Any]):
        if not self._should_push_remote_status(state):
            return
        report_execution_id = self._get_report_execution_id(state)
        remote_status = map_internal_status_to_remote(state.get("local_status"))
        execution_log = self._build_execution_log_snapshot(state)
        payload = build_status_payload(
            remote_status,
            state.get("error_message"),
            conversation=[],
            execution_log=execution_log,
        )
        state["last_status_payload"] = payload
        request_record = {
            "url": f"{(state.get('cloud_base_url') or CLOUD_BASE_URL).rstrip('/')}/api/test-executions/{report_execution_id}/report",
            "payload": payload,
            "has_token": bool((state.get("token") or "").strip()),
        }
        self._append_cloud_event(state, "status_report_request", request_record)
        response = report_status(
            cloud_base_url=state.get("cloud_base_url") or CLOUD_BASE_URL,
            execution_id=report_execution_id,
            payload=payload,
            token=(state.get("token") or "").strip() or None,
        )
        state["last_status_response"] = response
        upload_state_path = str(state.get("progress_upload_state_path") or "").strip()
        if upload_state_path:
            upload_state = self._load_progress_upload_state(upload_state_path)
            upload_state["last_reported_status"] = str(state.get("local_status") or "")
            upload_state["last_reported_stage"] = str(state.get("local_stage") or "")
            upload_state["last_reported_at_epoch"] = time.time()
            upload_state["last_payload_signature"] = json.dumps(payload, ensure_ascii=False, sort_keys=True)
            upload_state["last_response_ok"] = bool(response.get("ok"))
            self._save_progress_upload_state(upload_state_path, upload_state)
        self._append_cloud_event(state, "status_report_response", {
            "payload": payload,
            "response": response,
        })

    def _status_report_loop(self, execution_id: int):
        while True:
            time.sleep(STATUS_PUSH_INTERVAL_SECONDS)
            with self._lock:
                state = self._states.get(execution_id)
                if not state:
                    return
                should_stop = bool(state.get("status_push_stop"))
                should_report = self._should_report_status(state, should_stop)
            if should_report:
                with self._lock:
                    state = self._states.get(execution_id)
                    if state:
                        try:
                            self._report_remote_status(state)
                        except Exception as exc:
                            self._append_local_event(state, "status_report_error", {"error": str(exc)})
            if should_stop:
                return

    def _run_execution(self, payload: CloudExecutionStartRequest, local_base_url: str):
        execution_id = payload.executionId
        started_at = time.time()
        with self._lock:
            state = self._states[execution_id]

        def update_local_status(status: str, stage: Optional[str] = None):
            with self._lock:
                state["local_status"] = status
                if stage:
                    state["local_stage"] = stage
                    self._ensure_stage_entry(state, stage, self._stage_message(status, stage))
                state["updated_at"] = _now_iso()

        def on_progress(event: str, data: Dict[str, Any]):
            upload_workspace_dir = ""
            upload_patch_path = ""
            with self._lock:
                current = self._states[execution_id]
                if event == "log":
                    message = data.get("message", "")
                    self._append_conversation(current, "log", message, data.get("level", "INFO"))
                    if str(current.get("local_status") or "") == "running":
                        self._append_execution_detail(current, str(current.get("local_stage") or STAGE_PENDING), message)
                elif event == "stage_start":
                    stage_name = str(data.get("stage", "")).strip()
                    stage_map = {
                        "Agent运行": STAGE_GENERATING,
                        "constraint_review": STAGE_CONSTRAINT_SCORING,
                        "约束规则打分": STAGE_CONSTRAINT_SCORING,
                        "post_compile_check": STAGE_VALIDATING,
                        "结果验证": STAGE_VALIDATING,
                        "static_review": STAGE_STATIC_SCORING,
                        "静态代码打分": STAGE_STATIC_SCORING,
                    }
                    mapped_stage = stage_map.get(stage_name)
                    if mapped_stage:
                        current["local_stage"] = mapped_stage
                        self._ensure_stage_entry(current, mapped_stage, self._stage_message(str(current.get("local_status") or ""), mapped_stage))
                        current["updated_at"] = _now_iso()
                    self._append_conversation(current, "stage_start", data.get("stage", ""))
                elif event == "stage_done":
                    self._append_conversation(current, "stage_done", f"{data.get('stage', '')}:{data.get('status', 'done')}")
                elif event == "artifacts_ready":
                    upload_workspace_dir = str(data.get("workspace_dir") or "").strip()
                    upload_patch_path = str(data.get("patch_path") or "").strip()
                elif event == "error":
                    current["error_message"] = data.get("message", "")
                    current["updated_at"] = _now_iso()
                    current_stage = str(current.get("local_stage") or STAGE_PENDING)
                    self._append_execution_detail(current, current_stage, "任务执行失败")
                    self._append_conversation(current, "error", data.get("message", ""), "ERROR")
                elif event == "case_done":
                    self._append_conversation(current, "case_done", data.get("case_id", ""))
            if event == "artifacts_ready":
                output_code_url = _upload_output_code_dir(
                    upload_workspace_dir,
                    execution_id=execution_id,
                    on_progress=on_progress,
                )
                diff_file_url = _upload_diff_file(
                    upload_patch_path,
                    execution_id=execution_id,
                    on_progress=on_progress,
                )
                with self._lock:
                    current = self._states.get(execution_id)
                    if current is not None:
                        current["output_code_url"] = output_code_url
                        current["diff_file_url"] = diff_file_url

        try:
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            run_dir = os.path.join(RESULTS_ROOT, f"execution_{execution_id}_{timestamp}")
            source_dir = os.path.join(run_dir, "_download")
            case_dir = run_dir
            os.makedirs(run_dir, exist_ok=True)
            with self._lock:
                state["run_dir"] = run_dir
                state["case_dir"] = case_dir
                state["sse_log_path"] = os.path.join(agent_meta_dir(case_dir), "agent_opencode_sse_events.jsonl")
                state["sse_progress_log_path"] = os.path.join(agent_meta_dir(case_dir), "agent_opencode_progress_events.jsonl")
                state["progress_upload_state_path"] = os.path.join(run_dir, "progress_upload_state.json")
                self._save_progress_upload_state(state["progress_upload_state_path"], self._default_progress_upload_state())

            update_local_status("running", STAGE_PREPARING)
            with self._lock:
                self._append_conversation(state, "status", "任务开始执行")
                self._append_execution_detail(state, STAGE_PENDING, "任务已接收，等待执行")
                self._append_execution_detail(state, STAGE_PREPARING, f"本地产物目录: {run_dir}")
            downloaded_project_root = _prepare_project_from_file_url(payload.testCase.fileUrl, source_dir, on_progress=on_progress)
            original_dir = original_project_dir(case_dir)
            if os.path.exists(original_dir):
                shutil.rmtree(original_dir)
            shutil.copytree(downloaded_project_root, original_dir)
            _emit_prepare_log(on_progress, f"原始工程已准备完成: {original_dir}")
            raw_input = (payload.testCase.input or "").strip()
            raw_expected_output = (payload.testCase.expectedOutput or "").strip()
            input_text = raw_input
            expected_output = raw_expected_output
            if not input_text.strip() or not expected_output.strip():
                raise ValueError("缺少真实的任务输入或期望结果，已终止执行")
            prompt = build_prompt(input_text, expected_output)
            constraints = _parse_constraints_from_expected_output(expected_output)
            inferred_scenario = _infer_scenario_from_constraints(constraints) or "cloud_api"
            case_spec = {
                "case": {
                    "id": f"cloud_execution_{execution_id}",
                    "title": f"Cloud Execution {execution_id}",
                    "scenario": inferred_scenario,
                    "prompt": prompt,
                },
                "constraints": constraints,
            } if constraints else {
                "case": {
                    "id": f"cloud_execution_{execution_id}",
                    "title": f"Cloud Execution {execution_id}",
                    "scenario": "cloud_api",
                    "prompt": prompt,
                },
            }
            case = build_case(
                execution_id,
                original_dir,
                prompt,
                case_spec=case_spec,
            )
            _log_constraints_summary(on_progress, constraints)

            with self._lock:
                state["run_dir"] = run_dir
                state["case_dir"] = case_dir
                state["sse_log_path"] = os.path.join(agent_meta_dir(case_dir), "agent_opencode_sse_events.jsonl")
                state["sse_progress_log_path"] = os.path.join(agent_meta_dir(case_dir), "agent_opencode_progress_events.jsonl")
                state["case_id"] = case.get("id") or f"cloud_execution_{execution_id}"
                state["case_title"] = case.get("title") or f"Cloud Execution {execution_id}"
                state["project_source_url"] = payload.testCase.fileUrl
                self._append_conversation(state, "prepare", f"工程已就绪: {original_dir}")

            agent = load_agent(payload.agentId or "")
            if not agent:
                agents = load_agents()
                agent = load_agent(agents[0].get("id")) if agents else None
            if not agent:
                raise ValueError("必须选择一个可用 agent")
            default_timeout = int(agent.get("timeout") or 480)
            default_temperature = agent.get("temperature")
            with self._lock:
                self._append_conversation(
                    state,
                    "status",
                    f"执行计划已确认: Agent={agent.get('name') or agent.get('id') or '未知'}，即将开始处理工程",
                )

            result = run_single_case(
                case=case,
                case_dir=case_dir,
                stages=["runner"],
                dry_run=False,
                on_progress=on_progress,
                agent_config=agent,
                agent_timeout=default_timeout,
                agent_temperature=default_temperature,
            )

            if str(result.get("status") or "").lower() not in {"completed", "success"}:
                raise RuntimeError(f"Agent 执行失败: {result.get('status') or 'unknown'}")

            output_code_url = str(state.get("output_code_url") or "").strip()
            diff_file_url = str(state.get("diff_file_url") or "").strip()
            if not output_code_url:
                output_code_url = _upload_output_code_dir(
                    agent_workspace_dir(case_dir),
                    execution_id=execution_id,
                    on_progress=on_progress,
                )
            if not diff_file_url:
                diff_file_url = _upload_diff_file(
                    os.path.join(diff_dir(case_dir), "changes.patch"),
                    execution_id=execution_id,
                    on_progress=on_progress,
                )
            result_payload = build_execution_result_payload(
                execution_id=execution_id,
                case_dir=case_dir,
                result=result,
                expected_output=expected_output,
                execution_time_ms=int((time.time() - started_at) * 1000),
                output_code_url=output_code_url,
                diff_file_url=diff_file_url,
                code_quality_score=None,
                expected_output_score=None,
            )

            with self._lock:
                state["output_code_url"] = output_code_url
                state["diff_file_url"] = diff_file_url
                state["result"] = result
                state["last_result_payload"] = result_payload

            self._append_cloud_event(state, "result_report_request", {
                "url": f"{(state.get('cloud_base_url') or CLOUD_BASE_URL).rstrip('/')}/api/execution-results",
                "payload": result_payload,
                "has_token": bool((state.get("token") or "").strip()),
            })
            self._append_local_event(state, "result_report_request", {
                "payload": result_payload,
            })
            _log_local_only(f"上传任务报告请求:\n{_safe_json(result_payload)}")
            result_response = upload_execution_result(
                cloud_base_url=state.get("cloud_base_url") or CLOUD_BASE_URL,
                payload=result_payload,
                token=(state.get("token") or "").strip() or None,
            )
            with self._lock:
                state["last_result_response"] = result_response
                self._append_cloud_event(state, "result_report_response", {
                    "payload": result_payload,
                    "response": result_response,
                })
                self._append_local_event(state, "result_report_response", {
                    "response": result_response,
                })
                _log_local_only(f"上传任务报告响应:\n{_safe_json(result_response)}")

            update_local_status("completed", STAGE_COMPLETED)
            with self._lock:
                self._append_execution_detail(
                    state,
                    STAGE_COMPLETED,
                    f"上传任务报告请求: {_truncate_message(_safe_json(result_payload), 500)}",
                )
                self._append_execution_detail(
                    state,
                    STAGE_COMPLETED,
                    f"上传任务报告响应: {_truncate_message(_safe_json(result_response), 500)}",
                )
                self._append_execution_detail(state, STAGE_COMPLETED, "任务执行完成")
                self._append_conversation(state, "status", "任务执行完成")
        except Exception as exc:
            with self._lock:
                state["error_message"] = str(exc)
                self._append_conversation(state, "error", str(exc), "ERROR")
            update_local_status("failed", str(state.get("local_stage") or STAGE_PENDING))
        finally:
            with self._lock:
                state["status_push_stop"] = True
                self._active_execution_id = None

    def _run_local_text_execution(self, execution_id: int, payload: LocalTextStartRequest, local_base_url: str):
        started_at = time.time()
        with self._lock:
            state = self._states[execution_id]

        def update_local_status(status: str, stage: Optional[str] = None):
            with self._lock:
                state["local_status"] = status
                if stage:
                    state["local_stage"] = stage
                    self._ensure_stage_entry(state, stage, self._stage_message(status, stage))
                state["updated_at"] = _now_iso()

        def on_progress(event: str, data: Dict[str, Any]):
            with self._lock:
                current = self._states[execution_id]
                if event == "log":
                    message = data.get("message", "")
                    self._append_conversation(current, "log", message, data.get("level", "INFO"))
                    if str(current.get("local_status") or "") == "running":
                        self._append_execution_detail(current, str(current.get("local_stage") or STAGE_PENDING), message)
                elif event == "stage_start":
                    stage_name = str(data.get("stage", "")).strip()
                    stage_map = {
                        "Agent运行": STAGE_GENERATING,
                        "constraint_review": STAGE_CONSTRAINT_SCORING,
                        "结果验证": STAGE_VALIDATING,
                        "static_review": STAGE_STATIC_SCORING,
                    }
                    mapped_stage = stage_map.get(stage_name)
                    if mapped_stage:
                        current["local_stage"] = mapped_stage
                        self._ensure_stage_entry(current, mapped_stage, self._stage_message(str(current.get("local_status") or ""), mapped_stage))
                        current["updated_at"] = _now_iso()
                    self._append_conversation(current, "stage_start", data.get("stage", ""))
                elif event == "stage_done":
                    self._append_conversation(current, "stage_done", f"{data.get('stage', '')}:{data.get('status', 'done')}")
                elif event == "error":
                    current["error_message"] = data.get("message", "")
                    current["updated_at"] = _now_iso()
                    current_stage = str(current.get("local_stage") or STAGE_PENDING)
                    self._append_execution_detail(current, current_stage, "任务执行失败")
                    self._append_conversation(current, "error", data.get("message", ""), "ERROR")
                elif event == "case_done":
                    self._append_conversation(current, "case_done", data.get("case_id", ""))

        try:
            _ = local_base_url
            update_local_status("running", STAGE_PREPARING)
            with self._lock:
                self._append_conversation(state, "status", "开始生成本地测试用例")
                self._append_execution_detail(state, STAGE_PREPARING, "正在根据一句话需求生成标准 case")

            generated = generate_case_from_text(
                text=payload.input,
                source_project_dir=payload.originalProjectDir,
                preferred_scenario=payload.scenario,
                title=payload.title,
                expected_output=payload.expectedOutput,
            )

            case_dir = str(generated.get("case_dir") or "")
            case_yaml_path = str(generated.get("case_yaml_path") or "")
            case_spec = load_yaml(case_yaml_path) or {}
            case_meta = case_spec.get("case") or {}
            case = {
                "id": case_meta.get("id") or generated.get("case_id") or f"local_execution_{execution_id}",
                "title": case_meta.get("title") or generated.get("title") or f"Local Execution {execution_id}",
                "scenario": case_meta.get("scenario") or generated.get("scenario") or "requirement",
                "prompt": case_meta.get("prompt") or payload.input,
                "case_spec": case_spec,
                "original_project_dir": generated.get("original_project_dir") or "",
            }

            with self._lock:
                state["case_dir"] = case_dir
                state["case_id"] = case["id"]
                state["case_title"] = case["title"]
                state["generated_case"] = generated
                state["sse_log_path"] = os.path.join(agent_meta_dir(case_dir), "agent_opencode_sse_events.jsonl")
                state["sse_progress_log_path"] = os.path.join(agent_meta_dir(case_dir), "agent_opencode_progress_events.jsonl")
                self._ensure_progress_upload_state(state, case_dir)
                self._append_conversation(state, "status", f"已生成测试用例: {case['id']}")
                self._append_execution_detail(state, STAGE_PREPARING, f"case 目录: {case_dir}")

            agent = load_agent(payload.agentId or "")
            if not agent:
                agents = load_agents()
                agent = load_agent(agents[0].get("id")) if agents else None
            if not agent:
                raise ValueError("必须选择一个可用 agent")

            default_timeout = int(agent.get("timeout") or 480)
            default_temperature = agent.get("temperature")

            result = run_single_case(
                case=case,
                case_dir=case_dir,
                stages=["runner"],
                dry_run=False,
                on_progress=on_progress,
                agent_config=agent,
                agent_timeout=default_timeout,
                agent_temperature=default_temperature,
            )

            if str(result.get("status") or "").lower() not in {"completed", "success"}:
                raise RuntimeError(f"Agent 执行失败: {result.get('status') or 'unknown'}")

            with self._lock:
                state["result"] = result
                self._upload_remote_result(
                    state=state,
                    case_dir=case_dir,
                    result=result,
                    expected_output=payload.expectedOutput,
                    execution_time_ms=int((time.time() - started_at) * 1000),
                    on_progress=on_progress,
                )
                self._append_conversation(state, "status", "本地文本任务执行完成")
                self._append_execution_detail(state, STAGE_COMPLETED, "任务执行完成")
            update_local_status("completed", STAGE_COMPLETED)
        except Exception as exc:
            logger.exception("Local text execution failed: %s", exc)
            with self._lock:
                state["error_message"] = str(exc)
                self._append_conversation(state, "error", str(exc), "ERROR")
            update_local_status("failed", str(state.get("local_stage") or STAGE_PENDING))
        finally:
            with self._lock:
                state["status_push_stop"] = True
                self._active_execution_id = None

    def _run_local_text_pipeline(self, execution_id: int, payload: LocalTextStartRequest, local_base_url: str):
        started_at = time.time()
        _ = local_base_url
        with self._lock:
            state = self._states[execution_id]

        def update_local_status(status: str, stage: Optional[str] = None):
            with self._lock:
                current = self._states[execution_id]
                current["local_status"] = status
                if stage:
                    current["local_stage"] = stage
                    self._ensure_stage_entry(current, stage, self._stage_message(status, stage))
                current["updated_at"] = _now_iso()

        def on_progress(event: str, data: Dict[str, Any]):
            with self._lock:
                current = self._states[execution_id]
                if event == "log":
                    message = data.get("message", "")
                    self._append_conversation(current, "log", message, data.get("level", "INFO"))
                    if str(current.get("local_status") or "") == "running":
                        self._append_execution_detail(current, str(current.get("local_stage") or STAGE_PENDING), message)
                elif event == "stage_start":
                    stage_name = str(data.get("stage", "")).strip()
                    stage_map = {
                        "Agent运行": STAGE_GENERATING,
                        "pre_compile_check": STAGE_VALIDATING,
                        "post_compile_check": STAGE_VALIDATING,
                        "结果验证": STAGE_VALIDATING,
                        "constraint_review": STAGE_CONSTRAINT_SCORING,
                        "static_review": STAGE_STATIC_SCORING,
                        "用例生成": STAGE_PREPARING,
                    }
                    mapped_stage = stage_map.get(stage_name)
                    if mapped_stage:
                        current["local_stage"] = mapped_stage
                        self._ensure_stage_entry(current, mapped_stage, self._stage_message(str(current.get("local_status") or ""), mapped_stage))
                        current["updated_at"] = _now_iso()
                    self._append_conversation(current, "stage_start", data.get("stage", ""))
                elif event == "stage_done":
                    self._append_conversation(current, "stage_done", f"{data.get('stage', '')}:{data.get('status', 'done')}")
                elif event == "error":
                    current["error_message"] = data.get("message", "")
                    current["updated_at"] = _now_iso()
                    current_stage = str(current.get("local_stage") or STAGE_PENDING)
                    self._append_execution_detail(current, current_stage, "任务执行失败")
                    self._append_conversation(current, "error", data.get("message", ""), "ERROR")
                elif event == "case_done":
                    self._append_conversation(current, "case_done", data.get("case_id", ""))

        try:
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            run_dir = os.path.join(RESULTS_ROOT, f"local_text_execution_{execution_id}_{timestamp}")
            os.makedirs(run_dir, exist_ok=True)

            with self._lock:
                current = self._states[execution_id]
                current["run_dir"] = run_dir
                current["case_dir"] = run_dir
                current["sse_log_path"] = os.path.join(agent_meta_dir(run_dir), "agent_opencode_sse_events.jsonl")
                current["sse_progress_log_path"] = os.path.join(agent_meta_dir(run_dir), "agent_opencode_progress_events.jsonl")
                self._ensure_progress_upload_state(current, run_dir)

            update_local_status("running", STAGE_PREPARING)
            with self._lock:
                self._append_conversation(state, "status", "开始生成测试用例")
                self._append_execution_detail(state, STAGE_PREPARING, "正在根据需求生成标准 case")

            generation_agent_config = load_agent(payload.agentId or "case_generation_agent")
            if not generation_agent_config:
                generation_agent_config = load_agent("case_generation_agent")

            if generation_agent_config:
                from agent_bench.agent_runner.execution import AgentRunner
                from agent_bench.agent_runner.spec import build_agent_spec

                generation_agent_spec = build_agent_spec(generation_agent_config)
                generation_runner = AgentRunner(
                    agent_spec=generation_agent_spec,
                    runtime_options=None,
                    on_progress=on_progress,
                    fallback_timeout=300,
                    artifact_prefix="case_generation",
                    artifact_base_dir="generate",
                )
                generation_runner.prepare()

                generation_prompt = f"""请根据以下需求生成 HarmonyOS 测试用例：

## 用户需求
{payload.input or '无具体需求，请从种子目录中选择合适的场景'}

## 场景类型
{payload.scenario or 'requirement'}

## 任务标题
{payload.title or '未指定标题'}

## 生成要求
1. 参考 config/case_catalogs/seed_catalogs.yaml 中的种子数据结构
2. 输出标准 YAML 格式的 case.yaml 内容
3. 必须包含以下字段：
   - case.id: 用例 ID（格式：{payload.scenario or 'requirement'}_XXX）
   - case.scenario: 场景类型
   - case.title: 用例标题
   - case.prompt: 详细任务描述
   - case.output_requirements: 输出要求列表
   - constraints: 约束规则列表

请直接输出 YAML 内容，不要添加额外说明文字。"""

                generation_output, generation_time = generation_runner.execute(
                    task_prompt=generation_prompt,
                    workspace_dir=run_dir,
                    tag="case_generation",
                )
                generation_runner.teardown()

                with self._lock:
                    self._append_conversation(state, "log", f"用例生成完成，耗时 {generation_time:.1f}s", "INFO")
                    self._append_execution_detail(state, STAGE_PREPARING, f"Agent 生成输出长度: {len(generation_output)} 字符")

                try:
                    yaml_content = generation_output.strip()
                    if yaml_content.startswith("```yaml"):
                        yaml_content = yaml_content.split("```yaml")[1].split("```")[0].strip()
                    elif yaml_content.startswith("```"):
                        yaml_content = yaml_content.split("```")[1].split("```")[0].strip()
                    case_spec = yaml.safe_load(yaml_content) or {}
                except Exception as yaml_exc:
                    self._append_conversation(state, "log", f"YAML 解析失败，使用种子数据: {yaml_exc}", "WARN")
                    case_spec = {}

                if not case_spec.get("case"):
                    generated = generate_case_from_text(
                        text=payload.input,
                        source_project_dir=payload.originalProjectDir,
                        preferred_scenario=payload.scenario,
                        title=payload.title,
                        expected_output=payload.expectedOutput,
                    )
                    case_yaml_path = str(generated.get("case_yaml_path") or "")
                    case_spec = load_yaml(case_yaml_path) or {}
                    generated_case_dir = str(generated.get("case_dir") or "")
                    generated_original_project_dir = str(generated.get("original_project_dir") or "")
                else:
                    generated_case_dir = ""
                    generated_original_project_dir = payload.originalProjectDir or ""
            else:
                generated = generate_case_from_text(
                    text=payload.input,
                    source_project_dir=payload.originalProjectDir,
                    preferred_scenario=payload.scenario,
                    title=payload.title,
                    expected_output=payload.expectedOutput,
                )
                case_yaml_path = str(generated.get("case_yaml_path") or "")
                case_spec = load_yaml(case_yaml_path) or {}
                generated_case_dir = str(generated.get("case_dir") or "")
                generated_original_project_dir = str(generated.get("original_project_dir") or "")

            case_meta = case_spec.get("case") or {}
            prompt = str(case_meta.get("prompt") or payload.input or "").strip()

            case = {
                "id": case_meta.get("id") or f"local_execution_{execution_id}",
                "title": case_meta.get("title") or payload.title or f"Local Execution {execution_id}",
                "scenario": case_meta.get("scenario") or payload.scenario or "requirement",
                "prompt": prompt,
                "case_spec": case_spec,
                "original_project_dir": generated_original_project_dir,
            }

            with self._lock:
                current = self._states[execution_id]
                current["generated_case_dir"] = generated_case_dir
                current["case_id"] = case["id"]
                current["case_title"] = case["title"]
                current["generated_case"] = {"case_dir": generated_case_dir, "original_project_dir": generated_original_project_dir}
                self._append_conversation(current, "status", f"已生成测试用例: {case['id']}")
                self._append_execution_detail(current, STAGE_PREPARING, f"用例 ID: {case['id']}")
                self._append_execution_detail(current, STAGE_PREPARING, f"用例标题: {case['title']}")

            run_agent = load_agent("agent_default")
            if not run_agent:
                raise ValueError("未找到 agent_default 配置")

            default_timeout = int(run_agent.get("timeout") or 480)
            default_temperature = run_agent.get("temperature")
            with self._lock:
                current = self._states[execution_id]
                self._append_conversation(current, "status", "开始执行生成后的测试用例")
                self._append_execution_detail(current, STAGE_PREPARING, f"执行目录: {run_dir}")

            update_local_status("running", STAGE_VALIDATING)
            on_progress("stage_start", {"stage": "Agent运行"})

            result = run_single_case(
                case=case,
                case_dir=run_dir,
                stages=["runner"],
                dry_run=False,
                on_progress=on_progress,
                agent_config=run_agent,
                agent_timeout=default_timeout,
                agent_temperature=default_temperature,
            )

            if str(result.get("status") or "").lower() not in {"completed", "success"}:
                raise RuntimeError(f"流水线执行失败: {result.get('status') or 'unknown'}")

            with self._lock:
                current = self._states[execution_id]
                current["result"] = result
                self._upload_remote_result(
                    state=current,
                    case_dir=run_dir,
                    result=result,
                    expected_output=payload.expectedOutput,
                    execution_time_ms=int((time.time() - started_at) * 1000),
                    on_progress=on_progress,
                )
                self._append_conversation(current, "status", "测试用例执行与评分完成")
                self._append_execution_detail(current, STAGE_COMPLETED, "完整流水线执行完成")
            update_local_status("completed", STAGE_COMPLETED)
        except Exception as exc:
            logger.exception("Local text pipeline failed: %s", exc)
            with self._lock:
                current = self._states[execution_id]
                current["error_message"] = str(exc)
                self._append_conversation(current, "error", str(exc), "ERROR")
            update_local_status("failed", str(state.get("local_stage") or STAGE_PENDING))
        finally:
            with self._lock:
                state["status_push_stop"] = True
                self._active_execution_id = None

    def _run_local_case_execution(self, execution_id: int, payload: LocalCaseRunRequest, local_base_url: str):
        started_at = time.time()
        _ = local_base_url
        with self._lock:
            state = self._states[execution_id]

        def update_local_status(status: str, stage: Optional[str] = None):
            with self._lock:
                current = self._states[execution_id]
                current["local_status"] = status
                if stage:
                    current["local_stage"] = stage
                    self._ensure_stage_entry(current, stage, self._stage_message(status, stage))
                current["updated_at"] = _now_iso()

        def on_progress(event: str, data: Dict[str, Any]):
            with self._lock:
                current = self._states[execution_id]
                if event == "log":
                    message = data.get("message", "")
                    self._append_conversation(current, "log", message, data.get("level", "INFO"))
                    if str(current.get("local_status") or "") == "running":
                        self._append_execution_detail(current, str(current.get("local_stage") or STAGE_PENDING), message)
                elif event == "stage_start":
                    stage_name = str(data.get("stage", "")).strip()
                    stage_map = {
                        "Agent杩愯": STAGE_GENERATING,
                        "pre_compile_check": STAGE_VALIDATING,
                        "post_compile_check": STAGE_VALIDATING,
                        "缁撴灉楠岃瘉": STAGE_VALIDATING,
                        "constraint_review": STAGE_CONSTRAINT_SCORING,
                        "static_review": STAGE_STATIC_SCORING,
                    }
                    mapped_stage = stage_map.get(stage_name)
                    if mapped_stage:
                        current["local_stage"] = mapped_stage
                        self._ensure_stage_entry(current, mapped_stage, self._stage_message(str(current.get("local_status") or ""), mapped_stage))
                        current["updated_at"] = _now_iso()
                    self._append_conversation(current, "stage_start", data.get("stage", ""))
                elif event == "stage_done":
                    self._append_conversation(current, "stage_done", f"{data.get('stage', '')}:{data.get('status', 'done')}")
                elif event == "error":
                    current["error_message"] = data.get("message", "")
                    current["updated_at"] = _now_iso()
                    current_stage = str(current.get("local_stage") or STAGE_PENDING)
                    self._append_execution_detail(current, current_stage, "任务执行失败")
                    self._append_conversation(current, "error", data.get("message", ""), "ERROR")
                elif event == "case_done":
                    self._append_conversation(current, "case_done", data.get("case_id", ""))

        try:
            source_case_dir = os.path.abspath(str(payload.caseDir or "").strip())
            case_yaml_path = os.path.join(source_case_dir, "case.yaml")
            original_project = os.path.join(source_case_dir, "original_project")
            if not os.path.isfile(case_yaml_path):
                raise FileNotFoundError(f"Case file not found: {case_yaml_path}")
            if not os.path.isdir(original_project):
                raise FileNotFoundError(f"Original project not found: {original_project}")

            case_spec = load_yaml(case_yaml_path) or {}
            case_meta = case_spec.get("case") or {}
            prompt = str(case_meta.get("prompt") or "").strip()

            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            run_dir = os.path.join(RESULTS_ROOT, f"local_case_execution_{execution_id}_{timestamp}")
            os.makedirs(run_dir, exist_ok=True)

            case = {
                "id": case_meta.get("id") or f"local_execution_{execution_id}",
                "title": case_meta.get("title") or f"Local Execution {execution_id}",
                "scenario": case_meta.get("scenario") or "requirement",
                "prompt": prompt,
                "case_spec": case_spec,
                "original_project_dir": original_project,
            }

            update_local_status("running", STAGE_PREPARING)
            with self._lock:
                current = self._states[execution_id]
                current["run_dir"] = run_dir
                current["case_dir"] = run_dir
                current["generated_case_dir"] = source_case_dir
                current["case_id"] = case["id"]
                current["case_title"] = case["title"]
                current["sse_log_path"] = os.path.join(agent_meta_dir(run_dir), "agent_opencode_sse_events.jsonl")
                current["sse_progress_log_path"] = os.path.join(agent_meta_dir(run_dir), "agent_opencode_progress_events.jsonl")
                self._ensure_progress_upload_state(current, run_dir)
                self._append_conversation(current, "status", f"开始执行已生成的测试用例: {case['id']}")
                self._append_execution_detail(current, STAGE_PREPARING, f"用例目录: {source_case_dir}")
                self._append_execution_detail(current, STAGE_PREPARING, f"执行目录: {run_dir}")

            run_agent = load_agent(payload.agentId or "agent_default")
            if not run_agent:
                raise ValueError(f"未找到 {payload.agentId or 'agent_default'} 配置")

            default_timeout = int(run_agent.get("timeout") or 480)
            default_temperature = run_agent.get("temperature")
            result = run_single_case(
                case=case,
                case_dir=run_dir,
                stages=["runner"],
                dry_run=False,
                on_progress=on_progress,
                agent_config=run_agent,
                agent_timeout=default_timeout,
                agent_temperature=default_temperature,
            )

            if str(result.get("status") or "").lower() not in {"completed", "success"}:
                raise RuntimeError(f"流水线执行失败: {result.get('status') or 'unknown'}")

            with self._lock:
                current = self._states[execution_id]
                current["result"] = result
                self._upload_remote_result(
                    state=current,
                    case_dir=run_dir,
                    result=result,
                    expected_output="",
                    execution_time_ms=int((time.time() - started_at) * 1000),
                    on_progress=on_progress,
                )
                self._append_conversation(current, "status", "测试用例执行与评分完成")
                self._append_execution_detail(current, STAGE_COMPLETED, "完整流水线执行完成")
            update_local_status("completed", STAGE_COMPLETED)
        except Exception as exc:
            logger.exception("Local case execution failed: %s", exc)
            with self._lock:
                current = self._states[execution_id]
                current["error_message"] = str(exc)
                self._append_conversation(current, "error", str(exc), "ERROR")
            update_local_status("failed", str(state.get("local_stage") or STAGE_PENDING))
        finally:
            with self._lock:
                state["status_push_stop"] = True
                self._active_execution_id = None


cloud_execution_manager = CloudExecutionManager()
