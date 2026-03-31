# -*- coding: utf-8 -*-
"""AgentAdapter 工厂"""

from agent_bench.runner.opencode_adapter import OpenCodeAdapter


def create_adapter(agent: dict, timeout: int, on_progress=None, temperature: float = None):
    """根据 Agent 定义创建适配器实例。"""
    if not agent:
        raise ValueError("Agent 配置不能为空")

    adapter_type = agent.get("adapter", "opencode")
    if adapter_type == "opencode":
        return OpenCodeAdapter(
            api_base=agent.get("api_base", "http://localhost:4096"),
            model=agent.get("model"),
            timeout=timeout,
            temperature=temperature,
            on_progress=on_progress,
        )

    raise ValueError(f"暂不支持的 adapter 类型: {adapter_type}")
