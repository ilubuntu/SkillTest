# -*- coding: utf-8 -*-
"""云测桥接接口。"""

import logging
import socket

from fastapi import APIRouter, Header, HTTPException, Query, Request

from agent_bench.cloud_api.interaction_trace import load_agent_interaction_trace
from agent_bench.cloud_api.models import CloudExecutionStartRequest
from agent_bench.pipeline.loader import load_agent
from agent_bench.task_manager import cloud_execution_manager

router = APIRouter(prefix="/api/cloud-api", tags=["cloud_api"])
logger = logging.getLogger(__name__)


def _clip_cloud_request_text(value: str, limit: int = 100) -> str:
    text = str(value or "")
    if len(text) <= limit:
        return text
    return text[:limit] + f"...[已截断，原始长度={len(text)}]"


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
    payload.requestHost = str(request.headers.get("host") or request.url.netloc or "").strip()
    payload.executorHostname = socket.gethostname()
    logger.info(
        "云端任务下发请求: executionId=%s agent=%s requestHost=%s hostname=%s input=%s expectedOutput=%s fileUrl=%s",
        payload.executionId,
        normalized_agent_id,
        payload.requestHost,
        payload.executorHostname,
        _clip_cloud_request_text(payload.testCase.input),
        _clip_cloud_request_text(payload.testCase.expectedOutput),
        payload.testCase.fileUrl or "",
    )
    agent = load_agent(normalized_agent_id)
    if not agent:
        logger.warning("云端任务下发参数校验失败: executionId=%s agent=%s 未找到 agent 配置", payload.executionId, normalized_agent_id)
        detail = f"未找到 agent 配置: {normalized_agent_id}"
        logger.info(
            "云端任务下发返回: executionId=%s agent=%s status=400 detail=%s",
            payload.executionId,
            normalized_agent_id,
            detail,
        )
        raise HTTPException(status_code=400, detail=detail)
    payload.agentId = normalized_agent_id
    success, message = cloud_execution_manager.start(payload, local_base_url)
    if not success:
        logger.warning(
            "云端任务下发被拒绝: executionId=%s agent=%s reason=%s",
            payload.executionId,
            normalized_agent_id,
            message,
        )
        logger.info(
            "云端任务下发返回: executionId=%s agent=%s status=400 detail=%s",
            payload.executionId,
            normalized_agent_id,
            message,
        )
        raise HTTPException(status_code=400, detail=message)
    logger.info(
        "云端任务下发返回: executionId=%s agent=%s status=200 accepted=True message=%s",
        payload.executionId,
        normalized_agent_id,
        message,
    )
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


@router.get("/summary")
async def get_cloud_execution_summary():
    return cloud_execution_manager.summary()


def _load_agent_interaction_payload(execution_id: int):
    """云测主动拉取 Agent/LLM 交互流程快照。"""
    payload = load_agent_interaction_trace(execution_id)
    if payload is None:
        state = cloud_execution_manager.get_state(execution_id)
        case_dir = str((state or {}).get("case_dir") or "").strip()
        local_status = str((state or {}).get("local_status") or "").strip().lower()
        if state and local_status not in {"completed", "failed"}:
            return {
                "executionId": execution_id,
                "status": "not_ready",
                "message": f"executionId={execution_id} 的 Agent/LLM 交互流程数据尚未准备好，或该任务 ID 不存在",
            }
        payload = load_agent_interaction_trace(
            execution_id,
            case_dir=case_dir or None,
            status=local_status or "completed",
            agent=str((state or {}).get("agent_id") or "").strip() or None,
        )
    if payload is None:
        return {
            "executionId": execution_id,
            "status": "not_ready",
            "message": f"executionId={execution_id} 的 Agent/LLM 交互流程数据尚未准备好，或该任务 ID 不存在",
        }
    return payload


@router.get("/agent-interaction")
async def get_agent_interaction(execution_id: int = Query(alias="executionId")):
    return _load_agent_interaction_payload(execution_id)


@router.get("/agent-interaction/{execution_id}")
async def get_agent_interaction_compat(execution_id: int):
    return _load_agent_interaction_payload(execution_id)
