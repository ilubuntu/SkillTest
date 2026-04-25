# -*- coding: utf-8 -*-
"""AgentAdapter 工厂。"""

from agent_bench.agent_runner.discovery import check_api_available, ensure_opencode_server
from agent_bench.agent_runner.opencode_adapter import OpenCodeAdapter


def create_adapter(agent: dict,
                   timeout: int,
                   sse_filter: str = "medium",
                   on_progress=None,
                   artifact_prefix: str = "agent",
                   artifact_base_dir: str = "generate"):
    """根据 Agent 定义创建 OpenCode 适配器实例。"""
    if not agent:
        raise ValueError("Agent 配置不能为空")

    def emit(level: str, message: str):
        if on_progress:
            on_progress("log", {"level": level, "message": message})

    emit("WARNING", "检查 OpenCode 服务状态...")
    api_base = ensure_opencode_server()
    if check_api_available(api_base):
        emit("INFO", f"OpenCode 服务已就绪: {api_base}")
    else:
        emit("ERROR", f"OpenCode 服务不可用: {api_base}")
        raise RuntimeError(f"OpenCode 服务不可用: {api_base}")
    return OpenCodeAdapter(
        api_base=api_base,
        agent=agent.get("opencode_agent"),
        model=agent.get("model"),
        target_skills=[
            str(item.get("name") or "").strip()
            for item in (agent.get("mounted_skills") or [])
            if isinstance(item, dict) and str(item.get("name") or "").strip()
        ],
        timeout=timeout,
        sse_filter=sse_filter,
        on_progress=on_progress,
        artifact_prefix=artifact_prefix,
        artifact_base_dir=artifact_base_dir,
    )
