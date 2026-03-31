# -*- coding: utf-8 -*-
"""配置与数据加载

职责：
- 全局配置 (config.yaml)
- Profile 管理（加载、列举、场景解析）
- 测试用例加载（test_cases.yaml 总表）
- 增强配置加载（enhancements.yaml 总表）
- Skill 文件内容加载
- 通用文件读取
"""

import os
from typing import List, Optional, Dict

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CONFIG_PATH = os.path.join(BASE_DIR, "config.yaml")
PROFILES_DIR = os.path.join(BASE_DIR, "profiles")
INTERNAL_RULES_PATH = os.path.join(BASE_DIR, "config", "internal_rules.yaml")
TEST_CASES_REGISTRY_PATH = os.path.join(BASE_DIR, "test_cases", "test_cases.yaml")
ENHANCEMENTS_REGISTRY_PATH = os.path.join(BASE_DIR, "enhancements", "enhancements.yaml")
SCORING_STANDARDS_PATH = os.path.join(BASE_DIR, "evaluator", "standard.yaml")

# ── 缓存（避免重复加载） ─────────────────────────────────────

_registry_cache = {
    "test_cases": None,       # test_cases.yaml 内容
    "enhancements": None,     # enhancements.yaml 内容
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


def get_case_additional_files(input_file: str) -> dict:
    """检测用例是否存在 pages 子目录或同目录下的多页面文件

    对于多页面用例（如 004），input_file 指向 baseline/A_baseline.ets，
    同级目录下可能存在：
    1. pages 子目录包含其他页面文件
    2. 同目录下的 B_*.ets 等页面文件（如 B_baseline.ets）

    Returns:
        {"pages": {"filename.ets": "content", ...}}
    """
    input_path = os.path.join(BASE_DIR, input_file)
    case_dir = os.path.dirname(input_path)
    pages_dir = os.path.join(case_dir, "pages")

    additional = {}

    # 1. 检测 pages 子目录
    if os.path.isdir(pages_dir):
        pages_files = {}
        for filename in os.listdir(pages_dir):
            if filename.endswith(".ets"):
                file_path = os.path.join(pages_dir, filename)
                relative_path = os.path.relpath(file_path, BASE_DIR)
                pages_files[filename] = load_file(relative_path)
        if pages_files:
            additional["pages"] = pages_files

    # 2. 检测同目录下的其他 .ets 文件（排除 input_file 自身）
    input_filename = os.path.basename(input_path)
    sibling_files = {}
    for filename in os.listdir(case_dir):
        if filename.endswith(".ets") and filename != input_filename:
            file_path = os.path.join(case_dir, filename)
            sibling_files[filename] = load_file(os.path.relpath(file_path, BASE_DIR))
    if sibling_files:
        additional["sibling_files"] = sibling_files

    return additional


# ── 全局配置 ─────────────────────────────────────────────────

def load_config() -> dict:
    """加载全局配置文件 config.yaml"""
    if os.path.exists(CONFIG_PATH):
        return load_yaml(CONFIG_PATH) or {}
    return {}


# ── Registry 加载 ─────────────────────────────────────────────

def load_test_cases_registry() -> dict:
    """加载 test_cases/test_cases.yaml 总表"""
    if _registry_cache["test_cases"] is None:
        if os.path.exists(TEST_CASES_REGISTRY_PATH):
            _registry_cache["test_cases"] = load_yaml(TEST_CASES_REGISTRY_PATH) or {}
        else:
            _registry_cache["test_cases"] = {}
    return _registry_cache["test_cases"]


def load_enhancements_registry() -> dict:
    """加载 enhancements/enhancements.yaml 总表"""
    if _registry_cache["enhancements"] is None:
        if os.path.exists(ENHANCEMENTS_REGISTRY_PATH):
            _registry_cache["enhancements"] = load_yaml(ENHANCEMENTS_REGISTRY_PATH) or {}
        else:
            _registry_cache["enhancements"] = {}
    return _registry_cache["enhancements"]


def _get_scenario_by_id(scenario_id: str) -> Optional[dict]:
    """根据 scenario_id 获取场景定义"""
    registry = load_test_cases_registry()
    for scenario in registry.get("scenarios", []):
        if scenario.get("id") == scenario_id:
            return scenario
    return None


def _get_scenario_name_by_id(scenario_id: str) -> Optional[str]:
    """根据 scenario_id 获取场景 name"""
    scenario = _get_scenario_by_id(scenario_id)
    return scenario.get("name") if scenario else None


def _get_enhancement_by_id(enhancement_id: str) -> Optional[dict]:
    """根据 enhancement_id 获取增强配置定义（skill 或 system_prompt）"""
    registry = load_enhancements_registry()

    # 先查 skills
    for skill in registry.get("skills", []):
        if skill.get("id") == enhancement_id:
            return skill

    # 再查 system_prompts
    for sp in registry.get("system_prompts", []):
        if sp.get("id") == enhancement_id:
            return sp

    # 再查 mcp_servers
    for mcp in registry.get("mcp_servers", []):
        if mcp.get("id") == enhancement_id:
            return mcp

    return None


# ── Profile 管理 ─────────────────────────────────────────────

def load_profile(profile_name: str) -> dict:
    """加载 Profile 配置

    支持通过文件名、name 或 id 查找。

    Returns:
        Profile dict，包含 id, name, description, scenario_ids, enhancement_ids 等
        找不到时返回空 dict
    """
    # 1. 直接用文件名查找
    profile_path = os.path.join(PROFILES_DIR, f"{profile_name}.yaml")
    if os.path.exists(profile_path):
        return load_yaml(profile_path) or {}

    # 2. 遍历所有 profile，通过 name 或 id 查找
    for f in sorted(os.listdir(PROFILES_DIR)):
        if not (f.endswith(".yaml") or f.endswith(".yml")):
            continue
        data = load_yaml(os.path.join(PROFILES_DIR, f)) or {}
        if data.get("name") == profile_name or data.get("id") == profile_name:
            return data

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


def _collect_all_scenario_ids() -> List[str]:
    """从所有 Profile 中收集场景 ID（去重保序）"""
    all_ids = []
    seen = set()
    for pname in list_all_profiles():
        pdata = load_profile(pname)
        for sid in pdata.get("scenario_ids", []):
            if sid not in seen:
                all_ids.append(sid)
                seen.add(sid)
    return all_ids


def resolve_scenarios(profile_name: str, cases_override: str = None) -> List[str]:
    """解析要运行的场景名称列表

    优先级：cases_override > Profile 的 scenario_ids > profile_name 本身
    cases_override 可以是 "all" 或逗号分隔的场景 ID/名称列表
    """
    # cases_override 处理
    if cases_override:
        if cases_override == "all":
            # 从 registry 获取所有场景
            registry = load_test_cases_registry()
            all_scenarios = registry.get("scenarios", [])
            if all_scenarios:
                return [s.get("name", s.get("id")) for s in all_scenarios]
            return [profile_name]
        # 可能是 ID 或 name，尝试解析
        result = []
        for item in cases_override.split(","):
            item = item.strip()
            if not item:
                continue
            # 尝试当作 scenario_id 解析
            scenario = _get_scenario_by_id(item)
            if scenario:
                result.append(scenario.get("name"))
            else:
                # 直接当作 name
                result.append(item)
        return result

    if profile_name == "all":
        registry = load_test_cases_registry()
        all_scenarios = registry.get("scenarios", [])
        if all_scenarios:
            return [s.get("name", s.get("id")) for s in all_scenarios]
        return []

    profile_data = load_profile(profile_name)
    scenario_ids = profile_data.get("scenario_ids", [])

    if scenario_ids:
        # 将 scenario_ids 转换为场景名称
        names = []
        for sid in scenario_ids:
            name = _get_scenario_name_by_id(sid)
            if name:
                names.append(name)
        return names if names else [profile_name]

    return [profile_name]


def resolve_scenario_id_to_name(scenario_id: str) -> Optional[str]:
    """将 scenario_id 转换为场景名称"""
    return _get_scenario_name_by_id(scenario_id)


# ── 测试用例 ─────────────────────────────────────────────────

def load_test_cases(scenario: str) -> list:
    """加载指定场景下的所有测试用例

    从 test_cases.yaml 总表读取，路径已相对于 agent_bench/ 目录。
    返回的 case 格式统一为 {id, title, input: {prompt, code_file}, expected: {reference_file}, ...}
    """
    registry = load_test_cases_registry()
    for s in registry.get("scenarios", []):
        if s.get("id") == scenario or s.get("name") == scenario:
            raw_cases = s.get("cases", [])
            return [_transform_case(c) for c in raw_cases]
    return []


def _transform_case(case: dict) -> dict:
    """将 registry 格式转换为运行时格式

    registry 格式: {case_id, prompt, input_file, expected_file, ...}
    运行时格式: {id, title, input: {prompt, code_file}, expected: {reference_file}, ...}
    """
    if "input" in case and isinstance(case["input"], dict):
        return case

    input_file = case.get("input_file", "")
    additional_files = get_case_additional_files(input_file)

    result = {
        "id": case.get("case_id", case.get("id", "")),
        "title": case.get("title", ""),
        "category": case.get("category", ""),
        "scenario": case.get("scenario", ""),
        "input": {
            "prompt": case.get("prompt", ""),
            "code_file": input_file,
        },
        "expected": {
            "reference_file": case.get("expected_file", ""),
        },
    }

    if additional_files:
        result["additional_files"] = additional_files

    return result


def get_all_scenarios() -> List[dict]:
    """获取所有场景定义（从 registry）"""
    registry = load_test_cases_registry()
    return registry.get("scenarios", [])


# ── 内部规则库 & 评分标准 ────────────────────────────────────

def load_internal_rules() -> dict:
    """加载 config/internal_rules.yaml（全局确定性评分规则）"""
    if os.path.exists(INTERNAL_RULES_PATH):
        return load_yaml(INTERNAL_RULES_PATH) or {}
    return {}


def load_scoring_standards() -> dict:
    """加载 evaluator/standard.yaml（评分标准）"""
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

    通过 profile 的 enhancement_ids 解析实际的 skill 文件路径。
    """
    if profile_name:
        profile_data = load_profile(profile_name)
        # 检查该 profile 是否包含此场景
        scenario_ids = profile_data.get("scenario_ids", [])
        matched = False
        for sid in scenario_ids:
            name = _get_scenario_name_by_id(sid)
            if name == scenario:
                matched = True
                break
        if not matched:
            return ""

        # 从 enhancement_ids 加载
        for eid in profile_data.get("enhancement_ids", []):
            enhancement = _get_enhancement_by_id(eid)
            if enhancement and enhancement.get("id", "").startswith("skill_"):
                path = enhancement.get("path", "")
                if path:
                    full_path = os.path.join(BASE_DIR, path)
                    if os.path.isfile(full_path):
                        with open(full_path, "r", encoding="utf-8") as f:
                            return f.read()
        return ""

    # 未指定 profile，遍历所有 profile 查找匹配场景
    for pname in list_all_profiles():
        profile_data = load_profile(pname)
        scenario_ids = profile_data.get("scenario_ids", [])
        for sid in scenario_ids:
            name = _get_scenario_name_by_id(sid)
            if name != scenario:
                continue
            for eid in profile_data.get("enhancement_ids", []):
                enhancement = _get_enhancement_by_id(eid)
                if enhancement and enhancement.get("id", "").startswith("skill_"):
                    path = enhancement.get("path", "")
                    if path:
                        full_path = os.path.join(BASE_DIR, path)
                        if os.path.isfile(full_path):
                            with open(full_path, "r", encoding="utf-8") as f:
                                return f.read()
    return ""


# ── 增强配置加载 ─────────────────────────────────────────────

def load_enhancements(scenario: str, profile_name: Optional[str] = None) -> dict:
    """加载场景对应的完整增强配置（供 AgentAdapter.setup 使用）

    通过 profile 的 enhancement_ids 解析实际的增强配置内容。

    Returns:
        {
            "skills": [{"name": "...", "content": "..."}],
            "mcp_servers": [{"name": "...", "command": "...", "args": [...]}],
            "system_prompt": "...",
            "tools": {...}
        }
        无增强时返回空 dict
    """
    if profile_name:
        profile_data = load_profile(profile_name)
        # 检查该 profile 是否包含此场景
        scenario_ids = profile_data.get("scenario_ids", [])
        matched = False
        for sid in scenario_ids:
            name = _get_scenario_name_by_id(sid)
            if name == scenario:
                matched = True
                break
        if not matched:
            return {}

        return _resolve_enhancement_ids(profile_data.get("enhancement_ids", []))

    # 未指定 profile，遍历所有 profile 查找匹配场景
    for pname in list_all_profiles():
        profile_data = load_profile(pname)
        scenario_ids = profile_data.get("scenario_ids", [])
        for sid in scenario_ids:
            name = _get_scenario_name_by_id(sid)
            if name == scenario:
                return _resolve_enhancement_ids(profile_data.get("enhancement_ids", []))
    return {}


def _resolve_enhancement_ids(enhancement_ids: List[str]) -> dict:
    """将 enhancement_ids 列表解析为实际的增强配置"""
    result = {"skills": [], "mcp_servers": [], "system_prompt": "", "tools": None}

    if not enhancement_ids:
        return result

    # 确保是列表而非 None
    if not isinstance(enhancement_ids, (list, tuple)):
        enhancement_ids = []

    for eid in enhancement_ids:
        enhancement = _get_enhancement_by_id(eid)
        if not enhancement:
            continue

        eid_str = enhancement.get("id", "")

        # Skill
        if eid_str.startswith("skill_"):
            path = enhancement.get("path", "")
            content = ""
            if path:
                full_path = os.path.join(BASE_DIR, path)
                if os.path.isfile(full_path):
                    with open(full_path, "r", encoding="utf-8") as f:
                        content = f.read()
            result["skills"].append({
                "name": enhancement.get("name", "unknown"),
                "content": content
            })

        # System Prompt
        elif eid_str.startswith("sp_"):
            path = enhancement.get("path", "")
            content = ""
            if path:
                full_path = os.path.join(BASE_DIR, path)
                if os.path.isfile(full_path):
                    with open(full_path, "r", encoding="utf-8") as f:
                        content = f.read()
            if content:
                result["system_prompt"] = content

        # MCP Server
        elif eid_str.startswith("mcp_"):
            result["mcp_servers"].append({
                "name": enhancement.get("name", "unknown"),
                "command": enhancement.get("command", ""),
                "args": enhancement.get("args", []),
            })

    # 清理空值
    if not result["skills"]:
        result.pop("skills", None)
    if not result["mcp_servers"]:
        result.pop("mcp_servers", None)
    if not result["system_prompt"]:
        result.pop("system_prompt", None)
    if result.get("tools") is None:
        result.pop("tools", None)

    return result if result else {}
