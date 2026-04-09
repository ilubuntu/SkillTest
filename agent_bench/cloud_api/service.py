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
from agent_bench.cloud_api.models import CloudExecutionStartRequest, RemoteExecutionStatus
from agent_bench.pipeline.case_runner import run_single_case
from agent_bench.pipeline.loader import load_agent, load_agent_defaults, load_agents
from agent_bench.pipeline.artifacts import agent_meta_dir, agent_workspace_dir, original_project_dir, review_dir, static_dir
try:
    from agent_bench.storage_uploader import AgcStorageUploader
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
        uploader = AgcStorageUploader(
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
        return constraints if isinstance(constraints, list) else []
    if isinstance(parsed, list):
        return parsed
    return []


def _log_constraints_summary(on_progress, constraints: list[dict]):
    if not constraints:
        return
    _emit_prepare_log(on_progress, f"已解析约束规则，共 {len(constraints)} 条:")
    for item in constraints:
        if not isinstance(item, dict):
            continue
        rule_id = str(item.get("id") or "").strip()
        name = str(item.get("name") or "").strip()
        description = str(item.get("description") or "").strip()
        summary = f"- {rule_id} | {name}"
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

    def start(self, payload: CloudExecutionStartRequest, local_base_url: str):
        with self._lock:
            if self._worker_thread and self._worker_thread.is_alive():
                return False, "当前已有云测执行任务运行中"

            state = {
                "execution_id": payload.executionId,
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

            status_thread = threading.Thread(
                target=self._status_report_loop,
                args=(payload.executionId,),
                daemon=True,
            )
            self._status_threads[payload.executionId] = status_thread
            status_thread.start()

            thread = threading.Thread(
                target=self._run_execution,
                args=(payload, local_base_url),
                daemon=True,
            )
            self._worker_thread = thread
            thread.start()
            return True, "任务已接收"

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
            "url": f"{(state.get('cloud_base_url') or CLOUD_BASE_URL).rstrip('/')}/api/test-executions/{int(state.get('execution_id') or 0)}/report",
            "payload": payload,
            "has_token": bool((state.get("token") or "").strip()),
        }
        self._append_cloud_event(state, "status_report_request", request_record)
        response = report_status(
            cloud_base_url=state.get("cloud_base_url") or CLOUD_BASE_URL,
            execution_id=int(state.get("execution_id") or 0),
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
            _log_constraints_summary(on_progress, constraints)
            case = build_case(
                execution_id,
                original_dir,
                prompt,
                case_spec={"constraints": constraints} if constraints else {},
            )

            with self._lock:
                state["run_dir"] = run_dir
                state["case_dir"] = case_dir
                state["sse_log_path"] = os.path.join(agent_meta_dir(case_dir), "agent_opencode_sse_events.jsonl")
                state["sse_progress_log_path"] = os.path.join(agent_meta_dir(case_dir), "agent_opencode_progress_events.jsonl")
                state["case_id"] = case.get("id") or f"cloud_execution_{execution_id}"
                state["case_title"] = case.get("title") or f"Cloud Execution {execution_id}"
                state["project_source_url"] = payload.testCase.fileUrl
                self._append_conversation(state, "prepare", f"工程已就绪: {original_dir}")

            defaults = load_agent_defaults()
            default_timeout = int(defaults.get("timeout") or 480)
            default_temperature = defaults.get("temperature")

            agent = load_agent(payload.agentId or "")
            if not agent:
                agents = load_agents()
                agent = load_agent(agents[0].get("id")) if agents else None
            if not agent:
                raise ValueError("必须选择一个可用 agent")
            with self._lock:
                self._append_conversation(
                    state,
                    "status",
                    f"执行计划已确认: Agent={agent.get('name') or agent.get('id') or '未知'}，即将开始处理工程",
                )

            result = run_single_case(
                case=case,
                scenario="cloud_api",
                enhancements={},
                llm_judge=None,
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

            output_code_url = ""
            result_payload = build_execution_result_payload(
                execution_id=execution_id,
                case_dir=case_dir,
                result=result,
                expected_output=expected_output,
                execution_time_ms=int((time.time() - started_at) * 1000),
                output_code_url=output_code_url,
                code_quality_score=None,
                expected_output_score=None,
            )

            with self._lock:
                state["output_code_url"] = output_code_url
                state["result"] = result
                state["last_result_payload"] = result_payload

            self._append_cloud_event(state, "result_report_request", {
                "url": f"{(state.get('cloud_base_url') or CLOUD_BASE_URL).rstrip('/')}/api/execution-results",
                "payload": result_payload,
                "has_token": bool((state.get("token") or "").strip()),
            })
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

            update_local_status("completed", STAGE_COMPLETED)
            with self._lock:
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


cloud_execution_manager = CloudExecutionManager()
