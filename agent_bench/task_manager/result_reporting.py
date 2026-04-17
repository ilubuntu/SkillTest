"""任务最终结果上报。"""

from __future__ import annotations

import json
from typing import Any, Dict

from agent_bench.cloud_api.client import upload_execution_result


def _safe_json(data: Any) -> str:
    try:
        return json.dumps(data, ensure_ascii=False, indent=2)
    except Exception:
        return str(data)


def _truncate_message(value: Any, limit: int = 100) -> str:
    text = str(value or "").strip()
    if len(text) <= limit:
        return text
    return text[:limit] + "..."


class TaskResultReporter:
    def __init__(self, progress_tracker):
        self._progress = progress_tracker

    def report(self, state: Dict[str, Any], result_payload: Dict[str, Any], cloud_base_url: str, completed_stage: str):
        self._progress.append_cloud_event(state, "result_report_request", {
            "url": f"{(state.get('cloud_base_url') or cloud_base_url).rstrip('/')}/api/execution-results",
            "payload": result_payload,
            "has_token": bool((state.get("token") or "").strip()),
        })
        self._progress.write_execution_log(state, "INFO", f"上传任务报告请求: {_truncate_message(_safe_json(result_payload), 500)}")

        result_response = upload_execution_result(
            cloud_base_url=state.get("cloud_base_url") or cloud_base_url,
            payload=result_payload,
            token=(state.get("token") or "").strip() or None,
        )
        result_response_summary = {
            "ok": bool(result_response.get("ok")),
            "status_code": result_response.get("status_code"),
            "message": _truncate_message(str(result_response.get("body") or ""), 200),
        }

        state["last_result_response"] = result_response
        self._progress.append_cloud_event(state, "result_report_response", {
            "payload": result_payload,
            "response": result_response,
        })
        self._progress.write_execution_log(state, "INFO", f"上传任务报告响应: {_safe_json(result_response_summary)}")

        self._progress.append_execution_detail(
            state,
            completed_stage,
            f"上传任务报告请求: {_truncate_message(_safe_json(result_payload), 500)}",
        )
        self._progress.append_execution_detail(
            state,
            completed_stage,
            f"上传任务报告响应: {_safe_json(result_response_summary)}",
        )
        return result_response
