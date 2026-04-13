# -*- coding: utf-8 -*-
"""云测桥接接口。"""

import json
import os
import shutil
import tempfile

from fastapi import APIRouter, Header, HTTPException, Query, Request
from fastapi.responses import FileResponse

from agent_bench.cloud_api.models import CloudExecutionStartRequest
from agent_bench.task_manager import cloud_execution_manager
from agent_bench.pipeline.artifacts import agent_meta_dir, agent_workspace_dir, review_dir, static_dir

router = APIRouter(prefix="/api/cloud-api", tags=["cloud_api"])
local_router = APIRouter(prefix="/api/local", tags=["local_execution"])


@router.post("/start")
async def start_cloud_execution(
    payload: CloudExecutionStartRequest,
    request: Request,
    authorization: str | None = Header(default=None),
):
    local_base_url = str(request.base_url).rstrip("/")
    if authorization and authorization.lower().startswith("bearer "):
        payload.token = authorization[7:].strip()
    success, message = cloud_execution_manager.start(payload, local_base_url)
    if not success:
        raise HTTPException(status_code=400, detail=message)
    return {
        "accepted": True,
        "executionId": payload.executionId,
        "message": message,
    }


@router.get("/status")
async def get_cloud_execution_status(execution_id: int | None = Query(default=None)):
    if execution_id is None:
        return {
            "items": cloud_execution_manager.list_states(),
        }
    state = cloud_execution_manager.get_state(execution_id)
    if not state:
        return {
            "status": "idle",
            "executionId": execution_id,
        }
    return state


@router.get("/executions/{execution_id}/output-code")
async def download_output_code(execution_id: int):
    state = cloud_execution_manager.get_state(execution_id)
    if not state:
        raise HTTPException(status_code=404, detail="执行记录不存在")

    case_dir = state.get("case_dir")
    if not case_dir:
        raise HTTPException(status_code=404, detail="执行目录不存在")

    source_dir = agent_workspace_dir(case_dir)
    if not os.path.isdir(source_dir):
        raise HTTPException(status_code=404, detail="输出代码目录不存在")

    archive_root = os.path.join(tempfile.gettempdir(), f"cloud_execution_{execution_id}_output")
    archive_path = shutil.make_archive(archive_root, "zip", root_dir=source_dir)
    return FileResponse(
        archive_path,
        media_type="application/zip",
        filename=os.path.basename(archive_path),
    )


def _read_jsonl(path: str) -> list[dict]:
    if not os.path.isfile(path):
        return []
    items = []
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
    return items


def _event_files_for_agent(case_dir: str, agent_name: str) -> tuple[str, str]:
    agent_key = str(agent_name or "").strip().lower()
    if agent_key == "generate":
        base_dir = agent_meta_dir(case_dir)
        return (
            os.path.join(base_dir, "agent_opencode_progress_events.jsonl"),
            os.path.join(base_dir, "agent_opencode_sse_events.jsonl"),
        )
    if agent_key == "constraint":
        base_dir = review_dir(case_dir)
        return (
            os.path.join(base_dir, "constraint_review_opencode_progress_events.jsonl"),
            os.path.join(base_dir, "constraint_review_opencode_sse_events.jsonl"),
        )
    if agent_key == "static":
        base_dir = static_dir(case_dir)
        return (
            os.path.join(base_dir, "static_review_opencode_progress_events.jsonl"),
            os.path.join(base_dir, "static_review_opencode_sse_events.jsonl"),
        )
    raise HTTPException(status_code=400, detail="无效的 agent 名称")


def _normalize_event_item(item: dict, seq: int) -> dict:
    if "eventType" in item:
        return {
            "seq": seq,
            "timestamp": item.get("timestamp") or "",
            "type": item.get("eventType") or "unknown",
            "message": item.get("message") or "",
        }
    payload = (item.get("data") or {}).get("payload") if isinstance(item.get("data"), dict) else {}
    props = payload.get("properties") if isinstance(payload, dict) else {}
    message = ""
    if isinstance(props, dict):
        state = props.get("part", {}) if isinstance(props.get("part"), dict) else {}
        if isinstance(state, dict):
            message = state.get("text") or ""
        if not message:
            message = props.get("message") or ""
    return {
        "seq": seq,
        "timestamp": item.get("timestamp") or "",
        "type": (payload.get("type") if isinstance(payload, dict) else None) or item.get("event") or "unknown",
        "message": str(message or ""),
    }


def _agent_finished(state: dict, agent_name: str) -> bool:
    status = str((state or {}).get("local_status") or "")
    stage = str((state or {}).get("local_stage") or "")
    if status in {"completed", "failed"}:
        return True
    if agent_name == "generate":
        return stage in {"validating", "constraint_scoring", "static_scoring", "completed"}
    if agent_name == "constraint":
        return stage in {"static_scoring", "completed"}
    if agent_name == "static":
        return stage == "completed"
    return False


@local_router.get("/executions/{execution_id}/{agent_name}/events")
async def get_local_execution_events(
    execution_id: int,
    agent_name: str,
    cursor: int = Query(default=0, ge=0),
):
    state = cloud_execution_manager.get_state(execution_id)
    if not state:
        raise HTTPException(status_code=404, detail="执行记录不存在")
    case_dir = str(state.get("case_dir") or "").strip()
    if not case_dir:
        raise HTTPException(status_code=404, detail="执行目录不存在")

    progress_path, sse_path = _event_files_for_agent(case_dir, agent_name)
    source_path = progress_path if os.path.isfile(progress_path) else sse_path
    items = _read_jsonl(source_path)
    normalized = [_normalize_event_item(item, idx) for idx, item in enumerate(items, start=1)]
    delta_items = [item for item in normalized if int(item.get("seq") or 0) > cursor]
    next_cursor = int(normalized[-1]["seq"]) if normalized else cursor
    return {
        "items": delta_items,
        "nextCursor": next_cursor,
        "finished": _agent_finished(state, agent_name.lower()),
    }
