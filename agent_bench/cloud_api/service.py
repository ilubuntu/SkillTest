# -*- coding: utf-8 -*-
"""云测桥接执行管理器。"""

import json
import logging
import os
import shutil
import tempfile
import threading
import time
import urllib.parse
import urllib.request
import zipfile
from datetime import datetime
from typing import Any, Dict, Optional

from agent_bench.cloud_api.client import report_status, upload_execution_result
from agent_bench.cloud_api.converter import (
    build_case,
    build_execution_result_payload,
    build_prompt,
    build_status_payload,
    map_internal_status_to_remote,
    stage_to_local_status,
)
from agent_bench.cloud_api.models import CloudExecutionStartRequest, RemoteExecutionStatus
from agent_bench.pipeline.case_runner import run_single_case
from agent_bench.pipeline.loader import load_agent, load_agent_defaults, load_agents
try:
    from agent_bench.storage_uploader import AgcStorageUploader
    HAS_STORAGE_UPLOADER = True
except ImportError:
    HAS_STORAGE_UPLOADER = False

RESULTS_ROOT = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "results", "cloud_api")
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
STATUS_PUSH_MAX_BATCH_SIZE = 20
STATUS_PUSH_MAX_SSE_BATCH_SIZE = 5
logger = logging.getLogger("agent_bench.executor")


def _now_iso() -> str:
    return datetime.now().isoformat(timespec="seconds")


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


def _download_file(file_url: str, target_path: str):
    parsed = urllib.parse.urlparse(file_url)
    if parsed.scheme in ("http", "https", "file"):
        with urllib.request.urlopen(file_url, timeout=60) as response, open(target_path, "wb") as f:
            shutil.copyfileobj(response, f)
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


def _prepare_project_from_file_url(file_url: str, target_dir: str) -> str:
    os.makedirs(target_dir, exist_ok=True)
    parsed = urllib.parse.urlparse(file_url)

    if not parsed.scheme and os.path.isdir(file_url):
        return _find_project_root(file_url)

    archive_path = os.path.join(target_dir, "source.zip")
    _download_file(file_url, archive_path)

    if not zipfile.is_zipfile(archive_path):
        raise ValueError(f"当前仅支持 zip 类型工程包: {file_url}")

    extract_dir = os.path.join(target_dir, "extracted")
    os.makedirs(extract_dir, exist_ok=True)
    with zipfile.ZipFile(archive_path, "r") as zip_ref:
        zip_ref.extractall(extract_dir)

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
            "last_enqueued_event_id": 0,
            "last_imported_sse_line": 0,
            "last_attempted_event_id": 0,
            "last_uploaded_event_id": 0,
            "last_attempted_at": "",
            "last_uploaded_at": "",
            "last_response_ok": None,
            "interval_seconds": STATUS_PUSH_INTERVAL_SECONDS,
            "max_batch_size": STATUS_PUSH_MAX_BATCH_SIZE,
            "max_sse_batch_size": STATUS_PUSH_MAX_SSE_BATCH_SIZE,
        }

    def _load_progress_upload_state(self, path: str) -> Dict[str, Any]:
        state = self._default_progress_upload_state()
        state.update(_load_json_if_exists(path))
        return state

    def _save_progress_upload_state(self, path: str, state: Dict[str, Any]):
        _write_json(path, state)

    def _enqueue_progress_event(self, state: Dict[str, Any], event: Dict[str, Any]):
        queue_path = str(state.get("progress_queue_path") or "").strip()
        upload_state_path = str(state.get("progress_upload_state_path") or "").strip()
        if not queue_path or not upload_state_path:
            return
        upload_state = self._load_progress_upload_state(upload_state_path)
        next_id = int(upload_state.get("last_enqueued_event_id") or 0) + 1
        payload = {
            "id": next_id,
            "source": event.get("source") or "local",
            "timestamp": event.get("timestamp") or _now_iso(),
            "eventType": event.get("eventType") or "unknown",
            "label": event.get("label") or "",
            "message": _truncate_message(event.get("message")),
        }
        level = str(event.get("level") or "").strip()
        if level:
            payload["level"] = level
        _append_jsonl(queue_path, payload)
        upload_state["last_enqueued_event_id"] = next_id
        self._save_progress_upload_state(upload_state_path, upload_state)

    def _import_sse_progress_events(self, state: Dict[str, Any]):
        sse_path = str(state.get("sse_progress_log_path") or "").strip()
        queue_path = str(state.get("progress_queue_path") or "").strip()
        upload_state_path = str(state.get("progress_upload_state_path") or "").strip()
        if not sse_path or not queue_path or not upload_state_path or not os.path.exists(sse_path):
            return
        upload_state = self._load_progress_upload_state(upload_state_path)
        start_line = int(upload_state.get("last_imported_sse_line") or 0)
        imported = 0
        try:
            with open(sse_path, "r", encoding="utf-8") as f:
                for idx, line in enumerate(f, start=1):
                    if idx <= start_line:
                        continue
                    line = line.strip()
                    if not line:
                        continue
                    try:
                        item = json.loads(line)
                    except Exception:
                        continue
                    if not isinstance(item, dict):
                        continue
                    self._enqueue_progress_event(state, {
                        "source": "sse",
                        "timestamp": item.get("timestamp") or _now_iso(),
                        "eventType": item.get("eventType") or "unknown",
                        "label": item.get("label") or "",
                        "message": item.get("message") or "",
                    })
                    upload_state = self._load_progress_upload_state(upload_state_path)
                    upload_state["last_imported_sse_line"] = idx
                    self._save_progress_upload_state(upload_state_path, upload_state)
                    imported += 1
        except Exception as exc:
            self._append_local_event(state, "progress_import_error", {"error": str(exc)})
        if imported:
            self._append_local_event(state, "progress_import", {"count": imported})

    def _build_progress_batch(self, state: Dict[str, Any]) -> list[Dict[str, Any]]:
        queue_path = str(state.get("progress_queue_path") or "").strip()
        upload_state_path = str(state.get("progress_upload_state_path") or "").strip()
        if not queue_path or not upload_state_path:
            return []
        upload_state = self._load_progress_upload_state(upload_state_path)
        last_uploaded = int(upload_state.get("last_uploaded_event_id") or 0)
        max_batch = int(upload_state.get("max_batch_size") or STATUS_PUSH_MAX_BATCH_SIZE)
        max_sse = int(upload_state.get("max_sse_batch_size") or STATUS_PUSH_MAX_SSE_BATCH_SIZE)
        events = [item for item in _read_jsonl(queue_path) if int(item.get("id") or 0) > last_uploaded]
        if not events:
            return []
        local_events = [item for item in events if str(item.get("source") or "") != "sse"]
        sse_events = [item for item in events if str(item.get("source") or "") == "sse"][:max_sse]
        batch = local_events + sse_events
        batch.sort(key=lambda item: (str(item.get("timestamp") or ""), int(item.get("id") or 0)))
        return batch[:max_batch]

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
                "local_stage": "preparing",
                "error_message": "",
                "conversation": [],
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
        state["updated_at"] = _now_iso()
        self._log_runtime_event(state, record)
        self._append_local_event(state, "conversation", record)
        normalized = self._normalize_local_conversation(record)
        if normalized:
            normalized["source"] = "local"
            self._enqueue_progress_event(state, normalized)

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

    def _report_remote_status(self, state: Dict[str, Any]):
        self._import_sse_progress_events(state)
        remote_status = map_internal_status_to_remote(state.get("local_status"))
        conversation = self._build_progress_batch(state)
        payload = build_status_payload(
            remote_status,
            state.get("error_message"),
            conversation=conversation or None,
        )
        state["last_status_payload"] = payload
        response = report_status(
            cloud_base_url=state.get("cloud_base_url") or CLOUD_BASE_URL,
            execution_id=int(state.get("execution_id") or 0),
            payload=payload,
            token=(state.get("token") or "").strip() or None,
        )
        state["last_status_response"] = response
        state["updated_at"] = _now_iso()
        upload_state_path = str(state.get("progress_upload_state_path") or "").strip()
        if upload_state_path and conversation:
            upload_state = self._load_progress_upload_state(upload_state_path)
            upload_state["last_attempted_event_id"] = int(conversation[-1].get("id") or upload_state.get("last_attempted_event_id") or 0)
            upload_state["last_attempted_at"] = _now_iso()
            upload_state["last_response_ok"] = bool(response.get("ok"))
            if response.get("ok"):
                upload_state["last_uploaded_event_id"] = int(conversation[-1].get("id") or upload_state.get("last_uploaded_event_id") or 0)
                upload_state["last_uploaded_at"] = _now_iso()
            self._save_progress_upload_state(upload_state_path, upload_state)
        self._append_local_event(state, "status_report", {
            "payload": payload,
            "response": response,
        })

    def _normalize_local_conversation(self, item: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        item_type = str(item.get("type") or "").strip()
        message = str(item.get("message") or "").strip()
        if not item_type:
            return None
        label_map = {
            "status": "本地状态更新",
            "prepare": "工程准备",
            "stage_start": "流程开始",
            "stage_done": "流程结束",
            "error": "本地执行错误",
            "case_done": "用例执行完成",
            "log": "本地日志",
        }
        payload = {
            "timestamp": item.get("timestamp"),
            "eventType": item_type,
            "label": label_map.get(item_type, item_type),
            "message": _truncate_message(message),
        }
        level = str(item.get("level") or "").strip()
        if level:
            payload["level"] = level
        return payload

    def _build_status_conversation(self, state: Dict[str, Any]) -> list[Dict[str, Any]]:
        return self._build_progress_batch(state)

    def _status_report_loop(self, execution_id: int):
        last_payload = None
        while True:
            time.sleep(STATUS_PUSH_INTERVAL_SECONDS)
            with self._lock:
                state = self._states.get(execution_id)
                if not state:
                    return
                should_stop = bool(state.get("status_push_stop"))
                upload_state_path = str(state.get("progress_upload_state_path") or "").strip()
                upload_state = self._load_progress_upload_state(upload_state_path) if upload_state_path else self._default_progress_upload_state()
                try:
                    payload = build_status_payload(
                        map_internal_status_to_remote(state.get("local_status")),
                        state.get("error_message"),
                        conversation=self._build_progress_batch(state) or None,
                    )
                except Exception as exc:
                    self._append_local_event(state, "status_report_error", {"error": str(exc)})
                    payload = None
            if payload and payload != last_payload:
                with self._lock:
                    state = self._states.get(execution_id)
                    if state:
                        try:
                            self._report_remote_status(state)
                            last_payload = payload
                        except Exception as exc:
                            self._append_local_event(state, "status_report_error", {"error": str(exc)})
            interval_seconds = float(upload_state.get("interval_seconds") or STATUS_PUSH_INTERVAL_SECONDS)
            if should_stop:
                with self._lock:
                    state = self._states.get(execution_id)
                    if state:
                        try:
                            self._report_remote_status(state)
                        except Exception:
                            pass
                return
            if interval_seconds != STATUS_PUSH_INTERVAL_SECONDS:
                time.sleep(max(0.0, interval_seconds - STATUS_PUSH_INTERVAL_SECONDS))

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
                state["updated_at"] = _now_iso()

        def on_progress(event: str, data: Dict[str, Any]):
            with self._lock:
                current = self._states[execution_id]
                if event == "log":
                    message = data.get("message", "")
                    self._append_conversation(current, "log", message, data.get("level", "INFO"))
                elif event == "stage_start":
                    stage = stage_to_local_status(data.get("stage", ""))
                    if stage:
                        current["local_stage"] = stage
                    self._append_conversation(current, "stage_start", data.get("stage", ""))
                elif event == "stage_done":
                    stage = stage_to_local_status(data.get("stage", ""))
                    if stage and data.get("status") == "error":
                        current["local_stage"] = "failed"
                    self._append_conversation(current, "stage_done", f"{data.get('stage', '')}:{data.get('status', 'done')}")
                elif event == "error":
                    current["error_message"] = data.get("message", "")
                    current["local_stage"] = "failed"
                    self._append_conversation(current, "error", data.get("message", ""), "ERROR")
                elif event == "case_done":
                    self._append_conversation(current, "case_done", data.get("case_id", ""))
                current["updated_at"] = _now_iso()

        try:
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            run_dir = os.path.join(RESULTS_ROOT, f"execution_{execution_id}_{timestamp}")
            source_dir = os.path.join(run_dir, "source")
            case_dir = os.path.join(run_dir, "case")
            os.makedirs(run_dir, exist_ok=True)
            with self._lock:
                state["run_dir"] = run_dir
                state["case_dir"] = case_dir
                state["sse_log_path"] = os.path.join(case_dir, "agent_meta", "opencode_sse_events.jsonl")
                state["sse_progress_log_path"] = os.path.join(case_dir, "agent_meta", "opencode_progress_events.jsonl")
                state["progress_queue_path"] = os.path.join(run_dir, "progress_events.jsonl")
                state["progress_upload_state_path"] = os.path.join(run_dir, "progress_upload_state.json")
                self._save_progress_upload_state(state["progress_upload_state_path"], self._default_progress_upload_state())

            update_local_status("running", "preparing")
            with self._lock:
                self._append_conversation(state, "status", "任务开始执行")
                self._append_conversation(state, "prepare", f"本地产物目录: {run_dir}")
            project_root = _prepare_project_from_file_url(payload.testCase.fileUrl, source_dir)
            raw_input = (payload.testCase.input or "").strip()
            raw_expected_output = (payload.testCase.expectedOutput or "").strip()
            input_text = raw_input
            expected_output = raw_expected_output
            if not input_text.strip() or not expected_output.strip():
                raise ValueError("缺少真实的任务输入或期望结果，已终止执行")
            prompt = build_prompt(input_text, expected_output)
            case = build_case(execution_id, project_root, prompt)

            with self._lock:
                state["run_dir"] = run_dir
                state["case_dir"] = case_dir
                state["sse_log_path"] = os.path.join(case_dir, "agent_meta", "opencode_sse_events.jsonl")
                state["sse_progress_log_path"] = os.path.join(case_dir, "agent_meta", "opencode_progress_events.jsonl")
                state["case_id"] = case.get("id") or f"cloud_execution_{execution_id}"
                state["case_title"] = case.get("title") or f"Cloud Execution {execution_id}"
                state["project_source_url"] = payload.testCase.fileUrl
                self._append_conversation(state, "prepare", f"工程已就绪: {project_root}")

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

            uploaded_output_code_url = _upload_output_code_dir(
                os.path.join(case_dir, "agent_workspace"),
                execution_id,
                on_progress=on_progress,
            )
            output_code_url = uploaded_output_code_url or ""
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

            with self._lock:
                state["last_result_response"] = None
                self._append_local_event(state, "result_report", {
                    "payload": result_payload,
                    "response": None,
                })

            update_local_status("completed", "completed")
            with self._lock:
                self._append_conversation(state, "status", "任务执行完成")
        except Exception as exc:
            with self._lock:
                state["error_message"] = str(exc)
                self._append_conversation(state, "error", str(exc), "ERROR")
            update_local_status("failed", "failed")
        finally:
            with self._lock:
                state["status_push_stop"] = True
                self._active_execution_id = None


cloud_execution_manager = CloudExecutionManager()
