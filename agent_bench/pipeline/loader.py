# -*- coding: utf-8 -*-
"""配置与数据加载

职责：
- 全局配置 (config.yaml)
- Profile 管理（加载、列举、场景解析）
- 测试用例加载
- Skill 文件内容加载
- 通用文件读取
"""

import os
from typing import List, Optional

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CONFIG_PATH = os.path.join(BASE_DIR, "config.yaml")
PROFILES_DIR = os.path.join(BASE_DIR, "profiles")
INTERNAL_RULES_PATH = os.path.join(BASE_DIR, "config", "internal_rules.yaml")
SCORING_STANDARDS_PATH = os.path.join(BASE_DIR, "scoring", "standard.yaml")


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


# ── 全局配置 ─────────────────────────────────────────────────

def load_config() -> dict:
    """加载全局配置文件 config.yaml"""
    if os.path.exists(CONFIG_PATH):
        return load_yaml(CONFIG_PATH) or {}
    return {}


# ── Profile 管理 ─────────────────────────────────────────────

def load_profile(profile_name: str) -> dict:
    """加载 Profile 配置

    Returns:
        Profile dict，包含 name, description, scenarios, enhancements 等
        找不到时返回空 dict
    """
    profile_path = os.path.join(PROFILES_DIR, f"{profile_name}.yaml")
    if os.path.exists(profile_path):
        return load_yaml(profile_path) or {}
    return {}


def list_all_profiles() -> List[str]:
    """列出所有可用的 Profile 名称"""
    if not os.path.isdir(PROFILES_DIR):
        return []
    profiles = []
    for f in sorted(os.listdir(PROFILES_DIR)):
        if f.endswith(".yaml") or f.endswith(".yml"):
            profiles.append(f.rsplit(".", 1)[0])
    return profiles


def _collect_all_scenarios() -> List[str]:
    """从所有 Profile 中收集场景（去重保序）"""
    all_scenarios = []
    seen = set()
    for pname in list_all_profiles():
        pdata = load_profile(pname)
        for s in pdata.get("scenarios", []):
            if s not in seen:
                all_scenarios.append(s)
                seen.add(s)
    return all_scenarios


def resolve_scenarios(profile_name: str, cases_override: str = None) -> List[str]:
    """解析要运行的场景列表

    优先级：cases_override > Profile YAML 的 scenarios 字段 > profile_name 本身
    """
    if cases_override:
        if cases_override == "all":
            result = _collect_all_scenarios()
            return result if result else [profile_name]
        return [s.strip() for s in cases_override.split(",") if s.strip()]

    if profile_name == "all":
        return _collect_all_scenarios()

    profile_data = load_profile(profile_name)
    scenarios = profile_data.get("scenarios", [])
    if scenarios:
        return scenarios

    return [profile_name]


# ── 测试用例 ─────────────────────────────────────────────────

def load_test_cases(scenario: str) -> list:
    """加载指定场景目录下的所有测试用例"""
    cases_dir = os.path.join(BASE_DIR, "test_cases", scenario)
    if not os.path.isdir(cases_dir):
        return []

    cases = []
    for f in sorted(os.listdir(cases_dir)):
        if f.endswith(".yaml") or f.endswith(".yml"):
            filepath = os.path.join(cases_dir, f)
            case = load_yaml(filepath)
            cases.append(case)
    return cases


# ── 内部规则库 & 评分标准 ────────────────────────────────────

def load_internal_rules() -> dict:
    """加载 config/internal_rules.yaml（全局确定性评分规则）"""
    if os.path.exists(INTERNAL_RULES_PATH):
        return load_yaml(INTERNAL_RULES_PATH) or {}
    return {}


def load_scoring_standards() -> dict:
    """加载 scoring/standard.yaml（评分标准）"""
    if os.path.exists(SCORING_STANDARDS_PATH):
        return load_yaml(SCORING_STANDARDS_PATH) or {}
    return {}


def load_rubric(scenario: str = None) -> list:
    """加载评分维度列表

    Returns:
        [{dimension_id, name, weight, criteria}, ...]
    """
    standards = load_scoring_standards()
    dimensions = standards.get("dimensions", [])

    return [
        {
            "dimension_id": d.get("dimension_id", ""),
            "name": d.get("name", ""),
            "weight": d.get("weight", 0),
            "criteria": d.get("description", ""),
        }
        for d in dimensions
    ]


# ── Skill 文件 ───────────────────────────────────────────────

def load_skill_content(scenario: str, profile_name: Optional[str] = None) -> str:
    """加载场景对应的 Skill 文件内容

    从匹配该 scenario 的 Profile YAML 中读取 enhancements.skills[].path。
    如果指定了 profile_name 则只查该 profile，否则遍历所有 profile。
    """
    profiles_to_check = [profile_name] if profile_name else list_all_profiles()

    for pname in profiles_to_check:
        pdata = load_profile(pname)
        if scenario not in pdata.get("scenarios", []):
            continue
        skills = pdata.get("enhancements", {}).get("skills", [])
        for skill in skills:
            skill_path = os.path.join(BASE_DIR, skill["path"])
            if os.path.isfile(skill_path):
                with open(skill_path, "r", encoding="utf-8") as f:
                    return f.read()
    return ""


# ── 增强配置加载 ─────────────────────────────────────────────

def load_enhancements(scenario: str, profile_name: Optional[str] = None) -> dict:
    """加载场景对应的完整增强配置（供 AgentAdapter.setup 使用）

    读取 Profile 的 enhancements 字段，并将 skills 的文件路径
    替换为实际文件内容，生成 adapter 可直接消费的格式。

    Args:
        scenario: 场景名
        profile_name: Profile 名称（可选，不指定则自动匹配）

    Returns:
        {
            "skills": [{"name": "...", "content": "..."}],
            "mcp_servers": [{"name": "...", "command": "...", "args": [...]}],
            "system_prompt": "...",
            "tools": {...}
        }
        无增强时返回空 dict
    """
    profiles_to_check = [profile_name] if profile_name else list_all_profiles()

    for pname in profiles_to_check:
        pdata = load_profile(pname)
        if scenario not in pdata.get("scenarios", []):
            continue

        raw = pdata.get("enhancements", {})
        if not raw:
            return {}

        result = {}

        # skills: 路径 → 内容
        raw_skills = raw.get("skills", [])
        if raw_skills:
            skills = []
            for skill in raw_skills:
                name = skill.get("name", "unknown")
                path = skill.get("path", "")
                content = ""
                if path:
                    full_path = os.path.join(BASE_DIR, path)
                    if os.path.isfile(full_path):
                        with open(full_path, "r", encoding="utf-8") as f:
                            content = f.read()
                skills.append({"name": name, "content": content})
            result["skills"] = skills

        # mcp_servers: 透传
        mcp_servers = raw.get("mcp_servers", [])
        if mcp_servers:
            result["mcp_servers"] = mcp_servers

        # system_prompt: 透传
        system_prompt = raw.get("system_prompt", "")
        if system_prompt:
            result["system_prompt"] = system_prompt

        # tools: 透传
        tools = raw.get("tools")
        if tools:
            result["tools"] = tools

        return result

    return {}
