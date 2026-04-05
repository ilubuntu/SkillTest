# -*- coding: utf-8 -*-
"""Agent Skill 检查与日志。"""

import json
import subprocess

from agent_bench.agent_runtime.spec import AgentSpec

_SKILL_DISCOVERY_CACHE: dict[str, bool] = {}


def _notify(on_progress, level: str, message: str):
    if on_progress:
        on_progress("log", {"level": level, "message": message})


def log_agent_configuration(agent_spec: AgentSpec, on_progress):
    _notify(on_progress, "INFO", "，".join(
        part for part in [
            f"读取 Agent 配置: 名称={agent_spec.display_name}",
            f"适配器={agent_spec.adapter}",
            f"内部Agent={agent_spec.opencode_agent}" if agent_spec.adapter.lower() == "opencode" and agent_spec.opencode_agent else "",
            f"模型={agent_spec.model}",
            f"skills={', '.join(agent_spec.mounted_skill_names)}" if agent_spec.mounted_skill_names else "",
        ] if part
    ))
    if agent_spec.mounted_skill_names:
        _notify(on_progress, "WARNING", f"检测 Agent 是否正确挂载 skill: {', '.join(agent_spec.mounted_skill_names)}")


def _opencode_has_skill(skill_name: str) -> bool:
    cached = _SKILL_DISCOVERY_CACHE.get(skill_name)
    if cached is not None:
        return cached
    try:
        result = subprocess.run(
            ["opencode", "debug", "skill"],
            capture_output=True,
            text=True,
            timeout=10,
            check=False,
        )
        if result.returncode != 0:
            _SKILL_DISCOVERY_CACHE[skill_name] = False
            return False
        payload = json.loads(result.stdout or "[]")
        found = any(
            isinstance(item, dict) and str(item.get("name") or "").strip() == skill_name
            for item in (payload if isinstance(payload, list) else [])
        )
        _SKILL_DISCOVERY_CACHE[skill_name] = found
        return found
    except Exception:
        _SKILL_DISCOVERY_CACHE[skill_name] = False
        return False


def _try_mount_opencode_skill(skill_name: str, agent_spec: AgentSpec, on_progress) -> bool:
    _ = agent_spec
    _notify(on_progress, "WARNING", f"{skill_name} 当前未实现自动挂载，跳过挂载尝试")
    return False


def verify_runtime_skills(agent_spec: AgentSpec, on_progress):
    if agent_spec.adapter.lower() != "opencode":
        return
    if "build-harmony-project" not in agent_spec.mounted_skill_names:
        return

    skill_name = "build-harmony-project"
    _notify(on_progress, "WARNING", f"{agent_spec.display_name} skill 检测开始: 正在检查 OpenCode 是否正确配置 {skill_name}")
    if _opencode_has_skill(skill_name):
        _notify(on_progress, "INFO", f"{agent_spec.display_name} skill 检测完成: OpenCode 已正确配置 {skill_name}")
        return

    _notify(on_progress, "ERROR", f"{agent_spec.display_name} skill 初次检测结果: OpenCode 未正确配置 {skill_name}")
    if _try_mount_opencode_skill(skill_name, agent_spec, on_progress):
        _SKILL_DISCOVERY_CACHE.pop(skill_name, None)
        if _opencode_has_skill(skill_name):
            _notify(on_progress, "INFO", f"{agent_spec.display_name} skill 检测完成: 尝试挂载后 OpenCode 已正确配置 {skill_name}")
            return
    _notify(on_progress, "ERROR", f"{agent_spec.display_name} skill 检测完成: 尝试挂载后 OpenCode 仍未正确配置 {skill_name}")
