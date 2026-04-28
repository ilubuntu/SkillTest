# -*- coding: utf-8 -*-
"""云测桥接执行管理器。"""

import json
import logging
import os
import shutil
import hashlib
import sys
import threading
import time
import zipfile
from datetime import datetime
from typing import Any, Dict, Optional

from agent_bench.common.build_profile import sanitize_root_build_profile_signing_configs
from agent_bench.cloud_api.client import report_status, upload_execution_result
from agent_bench.cloud_api.converter import (
    build_execution_result_payload,
    build_status_payload,
    map_internal_status_to_remote,
)
from agent_bench.pipeline.artifacts import agent_workspace_dir, diff_dir
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
    if stage == STAGE_GENERATING:
        if "任务已发送" in text:
            return "任务已发送"
        if "已收到任务" in text:
            return "Agent已收到任务，仅展示部分处理流程"
        if any(token in text for token in (
            "文件检查完成",
            "代码修改完成",
            "工具执行完成",
            "TODO列表刷新",
            "已生成代码补丁",
            "开始输出结果:",
            "输出预览",
        )):
            return _truncate_message(text, 160)
        if "Agent处理完成, output=" in text:
            return _truncate_message(text, 180)
        if any(token in text for token in (
            "运行完成",
            "处理完成",
        )):
            return "Agent处理完成"
        return None
    if text.startswith("开始处理用例:"):
        return None
    if text.endswith("已开始") and not text.startswith("[开始]"):
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
    file_url = str(file_url or "").strip()
    if not file_url:
        _emit_prepare_log(on_progress, "未提供 fileUrl，使用空工程目录作为 workspace 初始内容")
        return target_dir
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


def _cleanup_download_source_dir(source_dir: str, on_progress=None):
    """
    `_download/` 只承担下载和解压中转职责。

    一旦原始工程已经复制到 `original/`，后续主流程只会再使用 `original/`
    和由其派生出来的 `workspace/`，中转目录就没有保留价值了。
    """
    if not source_dir or not os.path.exists(source_dir):
        return
    shutil.rmtree(source_dir, ignore_errors=True)
    _emit_prepare_log(on_progress, f"已清理下载中转目录: {source_dir}")


def _sanitize_original_project_signing_configs(original_dir: str, on_progress=None):
    result = sanitize_root_build_profile_signing_configs(original_dir)
    if result == "updated":
        _emit_prepare_log(on_progress, "清空原始工程签名信息成功，默认为[]")
    elif result == "already_empty":
        _emit_prepare_log(on_progress, "原始签名信息为空，无需清理")


class CloudExecutionManager:
    # 这套 manager 现在只服务 /api/local/* 本地调试接口；
    # 云测主链路已经迁到 task_manager/manager.py。
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
            execution_time_s=execution_time_ms,
            output_code_url=output_code_url,
            diff_file_url=diff_file_url,
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

cloud_execution_manager = CloudExecutionManager()
