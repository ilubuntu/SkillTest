"""任务进度聚合与状态上报。"""

from __future__ import annotations

import json
import logging
import os
import time
from datetime import datetime
from typing import Any, Dict, Optional

from agent_bench.cloud_api.client import report_status
from agent_bench.cloud_api.converter import build_status_payload, map_internal_status_to_remote
from agent_bench.task_manager.state import now_iso

STATUS_PUSH_DETAIL_FLUSH_SECONDS = 3.0

STAGE_PENDING = "pending"
STAGE_PREPARING = "preparing"
STAGE_GENERATING = "generating"
STAGE_VALIDATING = "validating"
STAGE_CONSTRAINT_SCORING = "constraint_scoring"
STAGE_STATIC_SCORING = "static_scoring"
STAGE_COMPLETED = "completed"

logger = logging.getLogger("agent_bench.executor")


def _now_stage_time() -> str:
    return datetime.now().strftime("%Y%m%d-%H:%M:%S")


def _append_jsonl(path: str, payload: Dict[str, Any]):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "a", encoding="utf-8") as f:
        f.write(json.dumps(payload, ensure_ascii=False) + "\n")


def _append_text_line(path: str, line: str):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "a", encoding="utf-8") as f:
        f.write(line + "\n")


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


def _truncate_message(value: Any, limit: int = 100) -> str:
    text = str(value or "").strip()
    if len(text) <= limit:
        return text
    return text[:limit] + "..."


class TaskProgressTracker:
    def _execution_log_path(self, state: Dict[str, Any]) -> str:
        run_dir = str(state.get("run_dir") or "").strip()
        if not run_dir:
            return ""
        return os.path.join(run_dir, "execution.log")

    def write_execution_log(self, state: Dict[str, Any], level: str, message: str):
        log_path = self._execution_log_path(state)
        if not log_path:
            return
        execution_id = state.get("execution_id")
        timestamp = now_iso()
        level_name = str(level or "INFO").upper()
        _append_text_line(log_path, f"{timestamp} {level_name} [execution={execution_id}] {message}")

    def default_progress_upload_state(self) -> Dict[str, Any]:
        return {
            "last_payload_signature": "",
            "last_reported_stage": "",
            "last_reported_status": "",
            "last_detail_change_at": 0.0,
            "last_reported_at_epoch": 0.0,
            "last_response_ok": None,
        }

    def load_progress_upload_state(self, path: str) -> Dict[str, Any]:
        state = self.default_progress_upload_state()
        state.update(_load_json_if_exists(path))
        return state

    def save_progress_upload_state(self, path: str, state: Dict[str, Any]):
        _write_json(path, state)

    def stage_message(self, local_status: str, local_stage: str) -> str:
        mapping = {
            STAGE_PENDING: "排队",
            STAGE_PREPARING: "环境准备",
            STAGE_GENERATING: "Agent处理",
            STAGE_VALIDATING: "结果验证",
            STAGE_CONSTRAINT_SCORING: "约束打分",
            STAGE_STATIC_SCORING: "代码打分",
            STAGE_COMPLETED: "完成",
        }
        return mapping.get(local_stage, "任务处理中")

    def ensure_stage_entry(self, state: Dict[str, Any], stage: str, message: Optional[str] = None):
        logs = state.setdefault("execution_log", [])
        for entry in logs:
            if str(entry.get("stage") or "") != stage:
                continue
            if message:
                entry["message"] = message
            return entry
        entry = {
            "stage": stage,
            "message": message or self.stage_message(str(state.get("local_status") or ""), stage),
            "detail": [],
        }
        logs.append(entry)
        state["updated_at"] = now_iso()
        return entry

    def append_execution_detail(self, state: Dict[str, Any], stage: str, message: str):
        normalized_message = _normalize_execution_detail_message(stage, message)
        if not normalized_message:
            return
        entry = self.ensure_stage_entry(state, stage)
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
        state["updated_at"] = now_iso()
        upload_state_path = str(state.get("progress_upload_state_path") or "").strip()
        if upload_state_path:
            upload_state = self.load_progress_upload_state(upload_state_path)
            upload_state["last_detail_change_at"] = time.time()
            self.save_progress_upload_state(upload_state_path, upload_state)

    def build_execution_log_snapshot(self, state: Dict[str, Any]) -> list[Dict[str, Any]]:
        return json.loads(json.dumps(state.get("execution_log") or []))

    def should_report_status(self, state: Dict[str, Any], should_stop: bool) -> bool:
        upload_state_path = str(state.get("progress_upload_state_path") or "").strip()
        upload_state = self.load_progress_upload_state(upload_state_path) if upload_state_path else self.default_progress_upload_state()
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

    def log_runtime_event(self, state: Dict[str, Any], record: Dict[str, Any]):
        item_type = str(record.get("type") or "").strip() or "event"
        message = str(record.get("message") or "").strip()
        level_name = str(record.get("level") or "INFO").upper()
        execution_id = state.get("execution_id")
        item_label = {
            "status": "状态",
            "prepare": "准备",
            "stage_start": "开始",
            "stage_done": "结束",
            "error": "错误",
            "case_done": "完成",
        }.get(item_type, item_type)
        prefix = "" if item_type == "log" else f"[{item_label}] "
        log_fn = {
            "DEBUG": logger.debug,
            "INFO": logger.info,
            "WARN": logger.warning,
            "WARNING": logger.warning,
            "ERROR": logger.error,
        }.get(level_name, logger.info)
        self.write_execution_log(state, level_name, f"{prefix}{message}".strip())
        # 详细过程日志只写到 execution.log，避免并发时全局日志和控制台混杂。
        if item_type == "log":
            return
        log_fn("[execution=%s] %s%s", execution_id, prefix, message)

    def append_local_event(self, state: Dict[str, Any], event_type: str, payload: Dict[str, Any]):
        run_dir = str(state.get("run_dir") or "").strip()
        if not run_dir:
            return
        log_path = os.path.join(run_dir, "executor_events.jsonl")
        _append_jsonl(log_path, {
            "timestamp": now_iso(),
            "event": event_type,
            "payload": payload,
        })

    def append_cloud_event(self, state: Dict[str, Any], event_type: str, payload: Dict[str, Any]):
        run_dir = str(state.get("run_dir") or "").strip()
        if not run_dir:
            return
        log_path = os.path.join(run_dir, "cloud_api_events.jsonl")
        _append_jsonl(log_path, {
            "timestamp": now_iso(),
            "event": event_type,
            "payload": payload,
        })

    def append_conversation(self, state: Dict[str, Any], item_type: str, message: str, level: str = "INFO"):
        record = {
            "timestamp": now_iso(),
            "type": item_type,
            "level": level,
            "message": message,
        }
        state["conversation"].append(record)
        state["conversation"] = state["conversation"][-200:]
        self.log_runtime_event(state, record)
        self.append_local_event(state, "conversation", record)

    def report_remote_status(self, state: Dict[str, Any], cloud_base_url: str):
        remote_status = map_internal_status_to_remote(state.get("local_status"))
        execution_log = self.build_execution_log_snapshot(state)
        payload = build_status_payload(
            remote_status,
            state.get("error_message"),
            conversation=[],
            execution_log=execution_log,
        )
        state["last_status_payload"] = payload
        request_record = {
            "url": f"{(state.get('cloud_base_url') or cloud_base_url).rstrip('/')}/api/test-executions/{int(state.get('execution_id') or 0)}/report",
            "payload": payload,
            "has_token": bool((state.get("token") or "").strip()),
        }
        self.append_cloud_event(state, "status_report_request", request_record)
        response = report_status(
            cloud_base_url=state.get("cloud_base_url") or cloud_base_url,
            execution_id=int(state.get("execution_id") or 0),
            payload=payload,
            token=(state.get("token") or "").strip() or None,
        )
        state["last_status_response"] = response
        upload_state_path = str(state.get("progress_upload_state_path") or "").strip()
        if upload_state_path:
            upload_state = self.load_progress_upload_state(upload_state_path)
            upload_state["last_reported_status"] = str(state.get("local_status") or "")
            upload_state["last_reported_stage"] = str(state.get("local_stage") or "")
            upload_state["last_reported_at_epoch"] = time.time()
            upload_state["last_payload_signature"] = json.dumps(payload, ensure_ascii=False, sort_keys=True)
            upload_state["last_response_ok"] = bool(response.get("ok"))
            self.save_progress_upload_state(upload_state_path, upload_state)
        self.append_cloud_event(state, "status_report_response", {
            "payload": payload,
            "response": response,
        })
