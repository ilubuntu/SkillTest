# -*- coding: utf-8 -*-
"""AgentAdapter 工厂"""

from agent_bench.runner.codex_adapter import CodexAdapter
from agent_bench.runner.opencode_adapter import OpenCodeAdapter
from agent_bench.runner.codex_local_adapter import CodexLocalAdapter


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
    if adapter_type == "codex_local":
        return CodexLocalAdapter(
            cli_path=agent.get("cli_path", "codex"),
            model=agent.get("model"),
            timeout=timeout,
            temperature=temperature,
            on_progress=on_progress,
            profile=agent.get("profile"),
            env=agent.get("env"),
        )

    raise ValueError(f"暂不支持的 adapter 类型: {adapter_type}")
