# -*- coding: utf-8 -*-
"""配置与数据加载。"""

import os
import re
import sys
from typing import List, Optional, Dict

from agent_bench.agent_runner.runtime_options import resolve_skill_mount_path
from agent_bench.agent_runner.spec import AgentSpec, build_agent_spec

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
REPO_DIR = os.path.dirname(BASE_DIR)


def _runtime_root_dir() -> str:
    if getattr(sys, "frozen", False):
        return os.path.dirname(os.path.abspath(sys.executable))
    return REPO_DIR


def _external_config_dir() -> str:
    return os.path.join(_runtime_root_dir(), "config")


CONFIG_PATH = os.path.join(_external_config_dir(), "config.yaml")
AGENTS_DIR = _external_config_dir()
AGENTS_REGISTRY_PATH = os.path.join(AGENTS_DIR, "agents.yaml")

DEFAULT_LOGGING_CONFIG = {
    "level": "INFO",
    "executor_log_filename": "agent_bench.log",
    "current_executor_log_filename": "current_executor_log",
    "local_execution_log_filename": "local_execution.log",
    "rotation_when": "H",
    "backup_count": 72,
}

# ── 缓存（避免重复加载） ─────────────────────────────────────

_registry_cache = {
    "agents": None,           # agents.yaml 内容
}


# ── YAML / 文件读取 ─────────────────────────────────────────

def load_yaml(file_path: str) -> dict:
    """加载 YAML 文件"""
    import yaml
    with open(file_path, "r", encoding="utf-8") as f:
        return yaml.safe_load(f)


def load_logging_config() -> dict:
    config = load_config() or {}
    logging_config = config.get("logging") if isinstance(config, dict) else {}
    result = dict(DEFAULT_LOGGING_CONFIG)
    if isinstance(logging_config, dict):
        for key in DEFAULT_LOGGING_CONFIG:
            value = logging_config.get(key)
            if value is not None and str(value).strip() != "":
                result[key] = value
    result["level"] = str(result.get("level") or "INFO").upper()
    result["backup_count"] = int(result.get("backup_count") or 72)
    result["rotation_when"] = str(result.get("rotation_when") or "H").upper()
    return result


def _format_prompt_value(value) -> str:
    if value is None:
        return ""
    if isinstance(value, str):
        return value.strip()
    if isinstance(value, dict):
        parts = []
        for key, item in value.items():
            key_text = str(key).strip()
            value_text = _format_prompt_value(item)
            if key_text and value_text:
                parts.append(f"{key_text}: {value_text}")
            elif key_text:
                parts.append(key_text)
            elif value_text:
                parts.append(value_text)
        return "；".join(part for part in parts if part)
    if isinstance(value, list):
        return "；".join(
            item for item in (_format_prompt_value(item) for item in value) if item
        )
    return str(value).strip()


def _normalize_workspace_relative_path(path: str) -> str:
    normalized = _format_prompt_value(path).replace("\\", "/").strip()
    prefixes = ("original_project/", "agent_workspace/")
    for prefix in prefixes:
        if normalized.startswith(prefix):
            return normalized[len(prefix):]
    return normalized


def _format_constraint_lines(item) -> List[str]:
    if isinstance(item, str):
        formatted = _format_prompt_value(item)
        return [f"- {formatted}"] if formatted else []

    if not isinstance(item, dict):
        formatted = _format_prompt_value(item)
        return [f"- {formatted}"] if formatted else []

    priority = _format_prompt_value(item.get("priority"))
    name = _format_prompt_value(item.get("name"))
    title = name or _format_prompt_value(item)
    if not title:
        return []
    priority_prefix = f"[{priority}] " if priority else ""
    return [f"- {priority_prefix}{title}"]


def resolve_case_original_project(case: dict) -> Optional[str]:
    """解析测试用例对应的 original_project 路径（绝对路径）"""
    explicit_dir = case.get("original_project_dir")
    if explicit_dir:
        return os.path.join(BASE_DIR, explicit_dir)

    return None


# ── 全局配置 ─────────────────────────────────────────────────

def load_config() -> dict:
    """加载全局配置文件 config.yaml"""
    if not os.path.exists(CONFIG_PATH):
        raise FileNotFoundError(f"配置文件不存在: {CONFIG_PATH}")
    return load_yaml(CONFIG_PATH) or {}


def load_agents_registry() -> dict:
    """加载 agents/agents.yaml，总是返回带 agents 列表的 dict。"""
    if _registry_cache["agents"] is None:
        if not os.path.exists(AGENTS_REGISTRY_PATH):
            raise FileNotFoundError(f"Agent 配置文件不存在: {AGENTS_REGISTRY_PATH}")
        data = load_yaml(AGENTS_REGISTRY_PATH) or {}
        _registry_cache["agents"] = data if isinstance(data, dict) else {}

    registry = _registry_cache["agents"] or {}
    agents = registry.get("agents")
    if isinstance(agents, list):
        return registry
    raise ValueError(f"Agent 配置格式无效: {AGENTS_REGISTRY_PATH}")


def load_agents() -> List[dict]:
    """返回 Agent 列表。"""
    registry = load_agents_registry()
    agents = registry.get("agents", [])
    return [agent for agent in agents if isinstance(agent, dict)]


def _normalize_mounted_skills(agent: dict) -> List[dict]:
    """规格化 Agent 自身声明的 mounted_skills，并按顺序去重。"""
    normalized = []
    seen = set()

    for source in list(agent.get("mounted_skills") or []):
        if not isinstance(source, dict):
            continue
        name = str(source.get("name") or "").strip()
        path = str(source.get("path") or "").strip()
        if not name or not path:
            continue
        key = (name, path)
        if key in seen:
            continue
        seen.add(key)
        normalized.append({
            "name": name,
            "path": path,
        })

    return normalized


def load_agent(agent_id: str) -> Optional[dict]:
    """根据 agent_id 获取 Agent 定义。"""
    if not agent_id:
        return None
    for agent in load_agents():
        if agent.get("id") == agent_id:
            merged = dict(agent)
            merged["mounted_skills"] = _normalize_mounted_skills(agent)
            return merged
    return None


def load_agent_spec(agent_id: str) -> Optional[AgentSpec]:
    """根据 agent_id 获取规格化后的 Agent 配置。"""
    agent = load_agent(agent_id)
    if not agent:
        return None
    return build_agent_spec(agent)


def validate_runtime_config() -> None:
    """校验运行时外置 config 目录是否完整。"""
    config_dir = _external_config_dir()
    if not os.path.isdir(config_dir):
        raise FileNotFoundError(f"配置目录不存在: {config_dir}")
    if not os.path.isfile(CONFIG_PATH):
        raise FileNotFoundError(f"配置文件不存在: {CONFIG_PATH}")
    if not os.path.isfile(AGENTS_REGISTRY_PATH):
        raise FileNotFoundError(f"Agent 配置文件不存在: {AGENTS_REGISTRY_PATH}")
    registry = load_agents_registry()
    for agent in registry.get("agents", []) or []:
        merged = dict(agent)
        for skill in merged.get("mounted_skills", []) or []:
            if not isinstance(skill, dict):
                continue
            resolve_skill_mount_path(skill.get("path", ""))
