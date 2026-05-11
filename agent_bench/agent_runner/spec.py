# -*- coding: utf-8 -*-
"""Agent 配置规格化。"""

from dataclasses import dataclass, field
from typing import Any, Dict, List, Optional

from agent_bench.common.default_constants import DEFAULT_TIMEOUT_SECONDS

DEFAULT_MAX_TASK_RUNTIME_SECONDS = 6000


@dataclass
class MountedSkillSpec:
    name: str
    path: str = ""


@dataclass
class AgentSpec:
    id: str = ""
    name: str = ""
    opencode_agent: str = ""
    model: str = ""
    timeout: int = DEFAULT_TIMEOUT_SECONDS
    extra_prompt: str = ""
    transport: str = ""
    cli_path: str = ""
    env: Dict[str, Any] = field(default_factory=dict)
    mcp_servers: List[Dict[str, Any]] = field(default_factory=list)
    mounted_skills: List[MountedSkillSpec] = field(default_factory=list)
    raw: Dict[str, Any] = field(default_factory=dict)

    @property
    def display_name(self) -> str:
        return self.name or self.id or "执行Agent"

    @property
    def mounted_skill_names(self) -> List[str]:
        return [item.name for item in self.mounted_skills if item.name]


def build_agent_spec(agent: Optional[dict]) -> AgentSpec:
    if not agent:
        raise ValueError("缺少 agent 配置")

    mounted_skills = []
    for item in (agent.get("mounted_skills") or []):
        if not isinstance(item, dict):
            continue
        name = str(item.get("name") or "").strip()
        if not name:
            continue
        mounted_skills.append(MountedSkillSpec(
            name=name,
            path=str(item.get("path") or "").strip(),
        ))

    raw = dict(agent)
    return AgentSpec(
        id=str(agent.get("id") or "").strip(),
        name=str(agent.get("name") or "").strip(),
        opencode_agent=str(agent.get("opencode_agent") or "").strip(),
        model=str(agent.get("model") or "").strip(),
        timeout=configured_agent_timeout(),
        extra_prompt=str(agent.get("extra_prompt") or "").strip(),
        transport=str(agent.get("transport") or "").strip(),
        cli_path=str(agent.get("cli_path") or "").strip(),
        env=dict(agent.get("env") or {}),
        mcp_servers=list(agent.get("mcp_servers") or []),
        mounted_skills=mounted_skills,
        raw=raw,
    )


def configured_agent_timeout() -> int:
    try:
        from agent_bench.pipeline.loader import load_config

        config = load_config() or {}
    except Exception:
        return DEFAULT_TIMEOUT_SECONDS

    opencode_config = config.get("opencode") if isinstance(config, dict) else {}
    if not isinstance(opencode_config, dict):
        return DEFAULT_TIMEOUT_SECONDS

    value = opencode_config.get("timeout")
    if value is None or str(value).strip() == "":
        return DEFAULT_TIMEOUT_SECONDS
    try:
        return int(value)
    except (TypeError, ValueError):
        return DEFAULT_TIMEOUT_SECONDS


def configured_max_task_runtime_seconds() -> int:
    try:
        from agent_bench.pipeline.loader import load_config

        config = load_config() or {}
    except Exception:
        return DEFAULT_MAX_TASK_RUNTIME_SECONDS

    opencode_config = config.get("opencode") if isinstance(config, dict) else {}
    if not isinstance(opencode_config, dict):
        return DEFAULT_MAX_TASK_RUNTIME_SECONDS

    value = opencode_config.get("max_task_runtime_seconds")
    if value is None or str(value).strip() == "":
        return DEFAULT_MAX_TASK_RUNTIME_SECONDS
    try:
        return max(1, int(value))
    except (TypeError, ValueError):
        return DEFAULT_MAX_TASK_RUNTIME_SECONDS
