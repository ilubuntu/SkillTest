# -*- coding: utf-8 -*-
"""配置与数据加载

职责：
- 全局配置 (config.yaml)
- 测试用例加载（test_cases.yaml 总表）
- 通用文件读取
"""

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
TEST_CASES_REGISTRY_PATH = os.path.join(BASE_DIR, "test_cases", "test_cases.yaml")
AGENTS_REGISTRY_PATH = os.path.join(AGENTS_DIR, "agents.yaml")

# ── 缓存（避免重复加载） ─────────────────────────────────────

_registry_cache = {
    "test_cases": None,       # test_cases.yaml 内容
    "agents": None,           # agents.yaml 内容
}


# ── YAML / 文件读取 ─────────────────────────────────────────

def load_yaml(file_path: str) -> dict:
    """加载 YAML 文件"""
    import yaml
    with open(file_path, "r", encoding="utf-8") as f:
        return yaml.safe_load(f)


def load_file(relative_path: str) -> str:
    """加载测试用例关联的代码文件（相对于 agent_bench/ 目录）"""
    path = os.path.join(BASE_DIR, relative_path)
    with open(path, "r", encoding="utf-8") as f:
        return f.read()


def _resolve_case_dir(case: dict) -> str:
    """解析测试用例目录（相对于 agent_bench/）"""
    explicit_case_dir = case.get("case_dir", "")
    if explicit_case_dir:
        return explicit_case_dir

    case_id = case.get("case_id", case.get("id", ""))
    if not case_id or "_" not in case_id:
        return ""

    scenario_key, case_no = case_id.rsplit("_", 1)
    if not scenario_key or not case_no:
        return ""
    return os.path.join("test_cases", scenario_key, case_no)


def get_case_additional_files(case: dict) -> dict:
    """收集 case 目录下用于补充上下文的额外 .ets 文件。

    规则：
    - pages/ 子目录下的 .ets 文件全部纳入
    - case 根目录下的 .ets 文件纳入
    """
    case_dir = _resolve_case_dir(case)
    if not case_dir:
        return {}

    absolute_case_dir = os.path.join(BASE_DIR, case_dir)
    if not os.path.isdir(absolute_case_dir):
        return {}

    additional = {}

    pages_dir = os.path.join(absolute_case_dir, "pages")
    if os.path.isdir(pages_dir):
        pages_files = {}
        for filename in sorted(os.listdir(pages_dir)):
            if not filename.endswith(".ets"):
                continue
            file_path = os.path.join(pages_dir, filename)
            relative_path = os.path.relpath(file_path, BASE_DIR)
            pages_files[filename] = load_file(relative_path)
        if pages_files:
            additional["pages"] = pages_files

    sibling_files = {}
    for filename in sorted(os.listdir(absolute_case_dir)):
        if not filename.endswith(".ets"):
            continue
        file_path = os.path.join(absolute_case_dir, filename)
        if not os.path.isfile(file_path):
            continue
        sibling_files[filename] = load_file(os.path.relpath(file_path, BASE_DIR))
    if sibling_files:
        additional["sibling_files"] = sibling_files

    return additional


def _load_case_spec(case: dict) -> dict:
    """加载 case 目录下的 case.yaml，找不到时返回空 dict"""
    case_dir = _resolve_case_dir(case)
    if not case_dir:
        return {}

    case_yaml_path = os.path.join(BASE_DIR, case_dir, "case.yaml")
    if not os.path.exists(case_yaml_path):
        return {}

    return load_yaml(case_yaml_path) or {}


def _build_prompt_from_case_spec(case_spec: dict) -> str:
    """根据最小 case.yaml 生成发给 agent 的任务描述。
    当前只拼接两个字段：
    - prompt
    - output_requirements
    """
    case_meta = case_spec.get("case", {}) or {}
    agent = case_spec.get("agent", {}) or {}

    prompt = _format_prompt_value(case_meta.get("prompt") or case_spec.get("prompt"))
    output_requirements = case_meta.get("output_requirements")
    if output_requirements is None:
        output_requirements = agent.get("output_requirements")

    if not prompt:
        return ""

    lines = []
    lines.append(prompt)

    if output_requirements:
        lines.extend(["", "## 结果输出要求"])
        if isinstance(output_requirements, list):
            for item in output_requirements:
                formatted = _format_prompt_value(item)
                if formatted:
                    lines.append(f"- {formatted}")
        else:
            formatted = _format_prompt_value(output_requirements)
            if formatted:
                lines.append(f"- {formatted}")

    return "\n".join(line for line in lines if line is not None).strip()


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


def _format_check_method_lines(check_method) -> List[str]:
    if not check_method:
        return []

    if isinstance(check_method, str):
        formatted = _format_prompt_value(check_method)
        return [f"  检查方式: {formatted}"] if formatted else []

    if not isinstance(check_method, dict):
        formatted = _format_prompt_value(check_method)
        return [f"  检查方式: {formatted}"] if formatted else []

    lines = []

    rules = check_method.get("rules") or []
    for rule in rules:
        if not isinstance(rule, dict):
            formatted = _format_prompt_value(rule)
            if formatted:
                lines.append(f"  规则: {formatted}")
            continue

        rule_id = _format_prompt_value(rule.get("rule_id"))
        target_file = _normalize_workspace_relative_path(rule.get("target_file"))
        match_type = _format_prompt_value(rule.get("match_type"))
        snippet = _compact_prompt_hint(
            _format_prompt_value(rule.get("snippet")) or _format_prompt_value(rule.get("pattern"))
        )
        header_parts = [part for part in [rule_id, target_file, match_type] if part]
        if header_parts:
            lines.append(f"  规则: {' | '.join(header_parts)}")
        if snippet:
            lines.append(f"    hint: {snippet}")

    return lines


def _compact_prompt_hint(text: str, limit: int = 120) -> str:
    compact = " ".join((text or "").split())
    if len(compact) <= limit:
        return compact
    return compact[:limit] + "..."


def resolve_case_original_project(case: dict) -> Optional[str]:
    """解析测试用例对应的 original_project 路径（绝对路径）"""
    explicit_dir = case.get("original_project_dir")
    if explicit_dir:
        return os.path.join(BASE_DIR, explicit_dir)

    case_dir = case.get("case_dir", "") or _resolve_case_dir(case)
    if case_dir:
        return os.path.join(BASE_DIR, case_dir, "original_project")

    return None


# ── 全局配置 ─────────────────────────────────────────────────

def load_config() -> dict:
    """加载全局配置文件 config.yaml"""
    if not os.path.exists(CONFIG_PATH):
        raise FileNotFoundError(f"配置文件不存在: {CONFIG_PATH}")
    return load_yaml(CONFIG_PATH) or {}


# ── Registry 加载 ─────────────────────────────────────────────

def load_test_cases_registry() -> dict:
    """加载 test_cases/test_cases.yaml 总表"""
    if _registry_cache["test_cases"] is None:
        if os.path.exists(TEST_CASES_REGISTRY_PATH):
            _registry_cache["test_cases"] = load_yaml(TEST_CASES_REGISTRY_PATH) or {}
        else:
            _registry_cache["test_cases"] = {}
    return _registry_cache["test_cases"]


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
def _transform_case(case: dict) -> dict:
    """将 registry 格式转换为运行时格式

    registry 格式: {case_id, prompt, ...}
    运行时格式: {id, title, prompt, case_dir, case_spec, ...}
    """
    if "prompt" in case and "case_dir" in case and "case_spec" in case:
        return case

    case_dir = _resolve_case_dir(case)
    case_spec = _load_case_spec(case)
    case_meta = case_spec.get("case", {})
    project_meta = case_spec.get("project", {})
    additional_files = get_case_additional_files(case)

    prompt = case.get("prompt", "")
    if case_spec:
        generated_prompt = _build_prompt_from_case_spec(case_spec)
        if generated_prompt:
            prompt = generated_prompt

    original_project_dir = case.get("original_project_dir", "")
    project_dir = project_meta.get("project_dir", "")
    if case_dir and project_dir:
        original_project_dir = os.path.join(case_dir, project_dir)
    elif case_dir:
        default_project_dir = os.path.join(case_dir, "original_project")
        if os.path.isdir(os.path.join(BASE_DIR, default_project_dir)):
            original_project_dir = default_project_dir

    result = {
        "id": case_meta.get("id", case.get("case_id", case.get("id", ""))),
        "title": case_meta.get("title", case.get("title", "")),
        "category": case.get("category", ""),
        "scenario": case_meta.get("scenario", case.get("scenario", "")),
        "case_dir": case_dir,
        "case_spec": case_spec,
        "original_project_dir": original_project_dir,
        "prompt": prompt,
    }

    if additional_files:
        result["additional_files"] = additional_files

    return result
