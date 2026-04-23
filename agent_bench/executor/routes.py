# -*- coding: utf-8 -*-
"""云测桥接接口。"""

from fastapi import APIRouter, Header, HTTPException, Query, Request

from agent_bench.cloud_api.models import CloudExecutionStartRequest
from agent_bench.pipeline.loader import load_agent
from agent_bench.task_manager import cloud_execution_manager

router = APIRouter(prefix="/api/cloud-api", tags=["cloud_api"])


async def _start_named_agent_execution(
    agent_id: str,
    payload: CloudExecutionStartRequest,
    request: Request,
    authorization: str | None = Header(default=None),
):
    local_base_url = str(request.base_url).rstrip("/")
    if authorization and authorization.lower().startswith("bearer "):
        payload.token = authorization[7:].strip()
    normalized_agent_id = str(agent_id or "").strip()
    agent = load_agent(normalized_agent_id)
    if not agent:
        raise HTTPException(status_code=400, detail=f"未找到 agent 配置: {normalized_agent_id}")
    payload.agentId = normalized_agent_id
    success, message = cloud_execution_manager.start(payload, local_base_url)
    if not success:
        raise HTTPException(status_code=400, detail=message)
    return {
        "accepted": True,
        "executionId": payload.executionId,
        "message": message,
        "agentId": normalized_agent_id,
    }


@router.post("/agent/{agent_id}")
async def start_dynamic_agent_execution(
    agent_id: str,
    payload: CloudExecutionStartRequest,
    request: Request,
    authorization: str | None = Header(default=None),
):
    return await _start_named_agent_execution(agent_id, payload, request, authorization)


@router.post("/agent/id={agent_id}")
async def start_dynamic_agent_execution_compat(
    agent_id: str,
    payload: CloudExecutionStartRequest,
    request: Request,
    authorization: str | None = Header(default=None),
):
    return await _start_named_agent_execution(agent_id, payload, request, authorization)


@router.post("/baseline")
async def start_baseline_execution(
    payload: CloudExecutionStartRequest,
    request: Request,
    authorization: str | None = Header(default=None),
):
    return await _start_named_agent_execution("baseline", payload, request, authorization)


@router.post("/harmonyos-plugin")
async def start_harmonyos_plugin_execution(
    payload: CloudExecutionStartRequest,
    request: Request,
    authorization: str | None = Header(default=None),
):
    return await _start_named_agent_execution("harmonyos-plugin", payload, request, authorization)


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
