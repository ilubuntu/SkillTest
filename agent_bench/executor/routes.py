# -*- coding: utf-8 -*-
"""云测桥接接口。"""

from fastapi import APIRouter, Header, HTTPException, Query, Request

from agent_bench.cloud_api.models import CloudExecutionStartRequest
from agent_bench.task_manager import cloud_execution_manager

router = APIRouter(prefix="/api/cloud-api", tags=["cloud_api"])


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