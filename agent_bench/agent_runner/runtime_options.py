# -*- coding: utf-8 -*-
"""Agent Runner 运行时配置组装。"""

import os
import sys
from typing import Optional


def _runtime_root_dir() -> str:
    if getattr(sys, "frozen", False):
        return os.path.dirname(os.path.abspath(sys.executable))
    return os.getcwd()


def load_text_file(file_path: str) -> str:
    with open(file_path, "r", encoding="utf-8") as f:
        return f.read()


def resolve_skill_mount_path(path: str) -> str:
    if not path:
        raise ValueError("Skill 路径不能为空")

    candidate_paths = []
    if os.path.isabs(path):
        candidate_paths.append(path)
    else:
        cwd_root = _runtime_root_dir()
        package_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
        repo_root = os.path.dirname(package_root)
        candidate_paths.extend([
            path,
            os.path.join(cwd_root, path),
            os.path.join(package_root, path),
            os.path.join(repo_root, path),
        ])

    checked = set()
    for candidate_path in candidate_paths:
        normalized_path = os.path.normpath(candidate_path)
        if normalized_path in checked:
            continue
        checked.add(normalized_path)

        if os.path.isdir(normalized_path):
            skill_md_path = os.path.join(normalized_path, "SKILL.md")
            if os.path.isfile(skill_md_path):
                return skill_md_path
        if os.path.isfile(normalized_path):
            return normalized_path

    raise FileNotFoundError(f"Skill 文件不存在: {path}")


def _cleanup_runtime_options_dict(data: dict) -> dict:
    result = dict(data or {})
    if not result.get("skills"):
        result.pop("skills", None)
    if not result.get("mcp_servers"):
        result.pop("mcp_servers", None)
    if not result.get("system_prompt"):
        result.pop("system_prompt", None)
    if result.get("tools") is None:
        result.pop("tools", None)
    return result


def merge_runtime_options(base: Optional[dict], extra: Optional[dict]) -> dict:
    base = base or {}
    extra = extra or {}
    merged = {
        "skills": list(base.get("skills") or []) + list(extra.get("skills") or []),
        "mcp_servers": list(base.get("mcp_servers") or []) + list(extra.get("mcp_servers") or []),
        "system_prompt": "",
        "tools": extra.get("tools") if extra.get("tools") is not None else base.get("tools"),
    }

    prompts = []
    if base.get("system_prompt"):
        prompts.append(str(base["system_prompt"]).strip())
    if extra.get("system_prompt"):
        prompts.append(str(extra["system_prompt"]).strip())
    merged["system_prompt"] = "\n\n".join(item for item in prompts if item)

    return _cleanup_runtime_options_dict(merged)


def build_agent_runtime_options(agent: Optional[dict]) -> dict:
    if not agent:
        return {}

    result = {
        "skills": [],
        "mcp_servers": list(agent.get("mcp_servers") or []),
        "tools": {
            "skill": True,
        },
    }

    for skill in agent.get("mounted_skills", []) or []:
        if not isinstance(skill, dict):
            continue
        skill_name = skill.get("name") or "external-skill"
        skill_path = resolve_skill_mount_path(skill.get("path", ""))
        skill_content = load_text_file(skill_path).strip()
        result["skills"].append({
            "name": skill_name,
            "path": skill_path,
            "content": skill_content,
        })

    return _cleanup_runtime_options_dict(result)
