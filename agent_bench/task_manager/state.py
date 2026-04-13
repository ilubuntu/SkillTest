"""任务状态模型与辅助函数。"""

from __future__ import annotations

import json
from datetime import datetime
from typing import Any, Dict

from agent_bench.cloud_api.models import CloudExecutionStartRequest


def now_iso() -> str:
    return datetime.now().isoformat(timespec="seconds")


def create_task_state(payload: CloudExecutionStartRequest, cloud_base_url: str) -> Dict[str, Any]:
    return {
        "execution_id": payload.executionId,
        "cloud_base_url": cloud_base_url.rstrip("/"),
        "agent_id": payload.agentId,
        "token": (payload.token or "").strip(),
        "test_case": payload.testCase.model_dump(),
        "local_status": "pending",
        "local_stage": "pending",
        "error_message": "",
        "conversation": [],
        "execution_log": [],
        "status_push_stop": False,
        "created_at": now_iso(),
        "updated_at": now_iso(),
        "run_dir": "",
        "case_dir": "",
        "output_code_url": "",
        "diff_file_url": "",
        "sse_log_path": "",
        "sse_progress_log_path": "",
        "progress_queue_path": "",
        "progress_upload_state_path": "",
        "last_status_payload": None,
        "last_status_response": None,
        "last_result_payload": None,
        "last_result_response": None,
    }


def clone_task_state(state: Dict[str, Any]) -> Dict[str, Any]:
    return json.loads(json.dumps(state))
