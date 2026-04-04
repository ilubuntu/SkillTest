# -*- coding: utf-8 -*-
"""AgentAdapter 工厂。"""

import os

from agent_bench.runner.codex_http_adapter import CodexHttpAdapter
from agent_bench.runner.codex_local_adapter import CodexLocalAdapter
from agent_bench.runner.discovery import check_api_available, ensure_opencode_server
from agent_bench.runner.opencode_adapter import OpenCodeAdapter


def _resolve_codex_adapter_type(agent: dict, adapter_type: str) -> str:
    """允许通过环境变量在 Codex 的 HTTP / CLI 模式之间切换。"""
    if adapter_type not in {"codex_http", "codex_local"}:
        return adapter_type

    transport = str(
        os.environ.get("AGENT_BENCH_CODEX_TRANSPORT")
        or agent.get("transport")
        or ""
    ).strip().lower()

    if transport in {"cli", "local", "direct"}:
        return "codex_local"
    if transport in {"http", "remote", "service"}:
        return "codex_http"
    return adapter_type


def create_adapter(agent: dict, timeout: int, on_progress=None, temperature: float = None):
    """根据 Agent 定义创建适配器实例。"""
    if not agent:
        raise ValueError("Agent 配置不能为空")

    def emit(level: str, message: str):
        if on_progress:
            on_progress("log", {"level": level, "message": message})

    adapter_type = _resolve_codex_adapter_type(agent, agent.get("adapter", "opencode"))
    if adapter_type == "opencode":
        emit("WARNING", "检查 OpenCode 服务状态...")
        api_base = ensure_opencode_server()
        if check_api_available(api_base):
            emit("INFO", f"OpenCode 服务已就绪: {api_base}")
        else:
            emit("ERROR", f"OpenCode 服务不可用: {api_base}")
            raise RuntimeError(f"OpenCode 服务不可用: {api_base}")
        return OpenCodeAdapter(
            api_base=api_base or agent.get("api_base", "http://localhost:4096"),
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
    if adapter_type == "codex_http":
        return CodexHttpAdapter(
            api_base=agent.get("api_base", "http://127.0.0.1:8001"),
            cli_path=agent.get("cli_path", "codex"),
            model=agent.get("model"),
            timeout=timeout,
            temperature=temperature,
            on_progress=on_progress,
            profile=agent.get("profile"),
            env=agent.get("env"),
        )

    raise ValueError(f"暂不支持的 adapter 类型: {adapter_type}")
