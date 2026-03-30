# -*- coding: utf-8 -*-
"""Profile 查询路由 — 从 profiles/*.yaml + enhancements.yaml 加载真实数据"""

import os
from typing import List

from fastapi import APIRouter

from agent_bench.pipeline.loader import (
    BASE_DIR, list_all_profiles, load_profile,
    resolve_scenario_id_to_name, load_file,
)

router = APIRouter(prefix="/api", tags=["profiles"])

ENHANCEMENTS_REGISTRY = None


def _load_enhancements_registry():
    global ENHANCEMENTS_REGISTRY
    if ENHANCEMENTS_REGISTRY is None:
        from agent_bench.pipeline.loader import load_enhancements_registry
        ENHANCEMENTS_REGISTRY = load_enhancements_registry()
    return ENHANCEMENTS_REGISTRY


def _resolve_enhancement(eid: str) -> dict:
    """根据 enhancement_id 解析出详情（含文件内容）"""
    registry = _load_enhancements_registry()

    for skill in registry.get("skills", []):
        if skill.get("id") == eid:
            content = ""
            path = skill.get("path", "")
            if path:
                full_path = os.path.join(BASE_DIR, path)
                if os.path.isfile(full_path):
                    with open(full_path, "r", encoding="utf-8") as f:
                        content = f.read()
            return {
                "type": "skill",
                "id": eid,
                "name": skill.get("name", ""),
                "description": skill.get("description", ""),
                "path": path,
                "content": content,
            }

    for sp in registry.get("system_prompts", []):
        if sp.get("id") == eid:
            content = ""
            path = sp.get("path", "")
            if path:
                full_path = os.path.join(BASE_DIR, path)
                if os.path.isfile(full_path):
                    with open(full_path, "r", encoding="utf-8") as f:
                        content = f.read()
            return {
                "type": "system_prompt",
                "id": eid,
                "name": sp.get("name", ""),
                "description": sp.get("description", ""),
                "path": path,
                "content": content,
            }

    for mcp in registry.get("mcp_servers", []):
        if mcp.get("id") == eid:
            return {
                "type": "mcp_server",
                "id": eid,
                "name": mcp.get("name", ""),
                "description": mcp.get("description", ""),
                "command": mcp.get("command", ""),
                "args": mcp.get("args", []),
            }

    return {"type": "unknown", "id": eid, "name": eid}


def _load_all_profiles() -> List[dict]:
    results = []
    for pname in list_all_profiles():
        data = load_profile(pname)

        scenario_names = []
        for sid in data.get("scenario_ids", []):
            name = resolve_scenario_id_to_name(sid)
            if name:
                scenario_names.append(name)

        enhancements = []
        skills = []
        system_prompts = []
        mcp_servers = []
        for eid in data.get("enhancement_ids", []):
            detail = _resolve_enhancement(eid)
            enhancements.append(detail)
            if detail["type"] == "skill":
                skills.append(detail)
            elif detail["type"] == "system_prompt":
                system_prompts.append(detail)
            elif detail["type"] == "mcp_server":
                mcp_servers.append(detail)

        results.append({
            "id": data.get("id", ""),
            "name": data.get("name", pname),
            "file": f"{pname}.yaml",
            "description": data.get("description", ""),
            "scenario_ids": data.get("scenario_ids", []),
            "scenarios": scenario_names,
            "enhancement_ids": data.get("enhancement_ids", []),
            "enhancements": enhancements,
            "skills": skills,
            "system_prompts": system_prompts,
            "mcp_servers": mcp_servers,
        })

    return results


@router.get("/profiles/detail")
async def get_profiles_detail():
    return _load_all_profiles()


@router.get("/profiles/detail/{profile_name}")
async def get_profile_detail(profile_name: str):
    for p in _load_all_profiles():
        if p["name"] == profile_name or p["file"] == f"{profile_name}.yaml":
            return p
    return {"error": "Profile 不存在"}
