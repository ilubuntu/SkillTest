# -*- coding: utf-8 -*-
"""云测桥接接口。"""

import logging
import socket

from fastapi import APIRouter, Header, HTTPException, Query, Request
from pydantic import BaseModel, Field

from agent_bench.cloud_api.interaction_trace import load_agent_interaction_trace
from agent_bench.cloud_api.models import CloudExecutionStartRequest
from agent_bench.pipeline.loader import load_agent, load_llm_catalog
from agent_bench.task_manager import cloud_execution_manager

router = APIRouter(prefix="/api/cloud-api", tags=["cloud_api"])
logger = logging.getLogger(__name__)


class StopExecutionsRequest(BaseModel):
    executionIds: list[int] = Field(default_factory=list)


def _clip_cloud_request_text(value: str, limit: int = 100) -> str:
    text = str(value or "")
    if len(text) <= limit:
        return text
    return text[:limit] + f"...[已截断，原始长度={len(text)}]"


def _validate_cloud_execution_request(payload: CloudExecutionStartRequest):
    agent_config = payload.agentConfig
    if agent_config is None:
        raise HTTPException(status_code=400, detail="缺少 agentConfig")
    if not str(agent_config.id or "").strip():
        raise HTTPException(status_code=400, detail="缺少 agentConfig.id")
    opencode_agent = str(agent_config.agent or "").strip()
    if opencode_agent not in {"build", "harmonyos-plugin"}:
        raise HTTPException(status_code=400, detail="agentConfig.agent 仅支持 build/harmonyos-plugin")
    if not str(agent_config.llm.providerId or "").strip():
        raise HTTPException(status_code=400, detail="缺少 agentConfig.llm.providerId")
    if not str(agent_config.llm.modelId or "").strip():
        raise HTTPException(status_code=400, detail="缺少 agentConfig.llm.modelId")

    for skill in list(agent_config.defaultSkills or []) + list(payload.dynamicSkills or []):
        if not str(skill.name or "").strip():
            raise HTTPException(status_code=400, detail="Skill name 不能为空")
        if not str(skill.version or "").strip():
            raise HTTPException(status_code=400, detail=f"Skill version 不能为空: {skill.name}")
        skill_path = str(skill.path or "").strip()
        if not skill_path:
            raise HTTPException(status_code=400, detail=f"Skill path 不能为空: {skill.name}")
        if not (skill_path.startswith("http://") or skill_path.startswith("https://")):
            raise HTTPException(status_code=400, detail=f"Skill path 仅支持 HTTP/HTTPS: {skill.name}")


@router.get("/llm-catalog")
async def get_llm_catalog():
    """返回当前执行器本地配置的可用 LLM 列表，供云测选择模型和供应商。"""
    return load_llm_catalog()


@router.post("/executions")
async def start_cloud_execution(
    payload: CloudExecutionStartRequest,
    request: Request,
    authorization: str | None = Header(default=None),
):
    """新协议任务下发入口：Agent/Skill/LLM 全部由请求体提供。"""
    local_base_url = str(request.base_url).rstrip("/")
    if authorization and authorization.lower().startswith("bearer "):
        payload.token = authorization[7:].strip()
    payload.requestHost = str(request.headers.get("host") or request.url.netloc or "").strip()
    payload.executorHostname = socket.gethostname()
    _validate_cloud_execution_request(payload)
    agent_config = payload.agentConfig
    payload.agentId = str(agent_config.id).strip()
    logger.info(
        "云端任务下发请求: executionId=%s agent=%s protocol=executions requestHost=%s hostname=%s input=%s expectedOutput=%s fileUrl=%s",
        payload.executionId,
        payload.agentId,
        payload.requestHost,
        payload.executorHostname,
        _clip_cloud_request_text(payload.testCase.input),
        _clip_cloud_request_text(payload.testCase.expectedOutput),
        payload.testCase.fileUrl or "",
    )
    success, message = cloud_execution_manager.start(payload, local_base_url)
    if not success:
        logger.warning(
            "云端任务下发被拒绝: executionId=%s agent=%s protocol=executions reason=%s",
            payload.executionId,
            payload.agentId,
            message,
        )
        raise HTTPException(status_code=400, detail=message)
    logger.info(
        "云端任务下发返回: executionId=%s agent=%s protocol=executions status=200 accepted=True message=%s",
        payload.executionId,
        payload.agentId,
        message,
    )
    return {
        "accepted": True,
        "executionId": payload.executionId,
        "message": message,
    }


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


@router.post("/maintenance/prepare-update")
async def prepare_executor_update(
    action: str = Query(default="enable", description="enable=进入更新准备; disable=恢复正常调度"),
):
    """进入/退出更新准备状态。enable: 停止启动新任务; disable: 恢复正常调度。"""
    return cloud_execution_manager.prepare_update(action=action)


@router.get("/maintenance/status")
async def get_executor_maintenance_status():
    """查询是否已经可以安全重启更新程序。"""
    return cloud_execution_manager.maintenance_status()


@router.post("/maintenance/stop-executions")
async def stop_executor_executions(payload: StopExecutionsRequest):
    """从 pending 等待队列移除任务；running 任务不主动停止。"""
    return cloud_execution_manager.stop_executions(payload.executionIds)


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
