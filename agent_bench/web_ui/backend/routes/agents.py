# -*- coding: utf-8 -*-
"""Agent 查询路由"""

from fastapi import APIRouter

from agent_bench.pipeline.loader import load_agents

router = APIRouter(prefix="/api", tags=["agents"])


@router.get("/agents")
async def get_agents():
    return load_agents()
