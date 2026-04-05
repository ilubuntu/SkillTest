# -*- coding: utf-8 -*-
"""Agent 配置规格化。"""

from dataclasses import dataclass, field
from typing import Any, Dict, List, Optional


@dataclass
class MountedSkillSpec:
    name: str
    path: str = ""


@dataclass
class AgentSpec:
    id: str = ""
    name: str = ""
    adapter: str = ""
    api_base: str = ""
    opencode_agent: str = ""
    model: str = ""
    timeout: int = 180
    temperature: Optional[float] = None
    tools: Any = None
    extra_prompt: str = ""
    transport: str = ""
    cli_path: str = ""
    profile: str = ""
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
        adapter=str(agent.get("adapter") or "").strip(),
        api_base=str(agent.get("api_base") or "").strip(),
        opencode_agent=str(agent.get("opencode_agent") or "").strip(),
        model=str(agent.get("model") or "").strip(),
        timeout=int(agent.get("timeout") or 180),
        temperature=agent.get("temperature"),
        tools=agent.get("tools"),
        extra_prompt=str(agent.get("extra_prompt") or "").strip(),
        transport=str(agent.get("transport") or "").strip(),
        cli_path=str(agent.get("cli_path") or "").strip(),
        profile=str(agent.get("profile") or "").strip(),
        env=dict(agent.get("env") or {}),
        mcp_servers=list(agent.get("mcp_servers") or []),
        mounted_skills=mounted_skills,
        raw=raw,
    )
