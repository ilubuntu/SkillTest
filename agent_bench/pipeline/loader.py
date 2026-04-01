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
import re
from typing import List, Optional, Dict

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CONFIG_PATH = os.path.join(BASE_DIR, "config.yaml")
PROFILES_DIR = os.path.join(BASE_DIR, "profiles")
AGENTS_DIR = os.path.join(BASE_DIR, "agents")
INTERNAL_RULES_PATH = os.path.join(BASE_DIR, "config", "internal_rules.yaml")
TEST_CASES_REGISTRY_PATH = os.path.join(BASE_DIR, "test_cases", "test_cases.yaml")
ENHANCEMENTS_REGISTRY_PATH = os.path.join(BASE_DIR, "enhancements", "enhancements.yaml")
SCORING_STANDARDS_PATH = os.path.join(BASE_DIR, "evaluator", "standard.yaml")
AGENTS_REGISTRY_PATH = os.path.join(AGENTS_DIR, "agents.yaml")

# ── 缓存（避免重复加载） ─────────────────────────────────────

_registry_cache = {
    "test_cases": None,       # test_cases.yaml 内容
    "enhancements": None,     # enhancements.yaml 内容
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


def load_text_file(file_path: str) -> str:
    """加载任意文本文件。"""
    with open(file_path, "r", encoding="utf-8") as f:
        return f.read()


def _load_skill_frontmatter(skill_file_path: str) -> dict:
    content = load_text_file(skill_file_path)
    match = re.match(r"^---\n(.*?)\n---\n", content, re.DOTALL)
    if not match:
        return {}
    import yaml
    try:
        data = yaml.safe_load(match.group(1)) or {}
        return data if isinstance(data, dict) else {}
    except Exception:
        return {}


def _build_skill_summary(skill_name: str, skill_file_path: str) -> str:
    """构造简版 skill 摘要，避免把整份 SKILL.md 注入 prompt。"""
    frontmatter = _load_skill_frontmatter(skill_file_path)
    description = (frontmatter.get("description") or "").strip()

    if skill_name == "harmonyos-hvigor":
        lines = [
            f"Skill 名称: {skill_name}",
        ]
        if description:
            lines.append(f"Skill 说明: {description}")
        lines.extend([
            "使用原则:",
            "- 修改代码后立即执行一次 hvigor 编译自检",
            "- 使用 DevEco Studio 内置 node、hvigorw.js、sdk、java",
            "- 不要依赖系统 node，不要调用裸 hvigorw",
            "- 编译失败时读取完整编译日志，继续修复并再次编译",
            "关键命令:",
            "- DEVECO_PATH=/Applications/DevEco-Studio.app",
            "- NODE_BIN=$DEVECO_PATH/Contents/tools/node/bin/node",
            "- HVIGOR_JS=$DEVECO_PATH/Contents/tools/hvigor/bin/hvigorw.js",
            "- export DEVECO_SDK_HOME=$DEVECO_PATH/Contents/sdk",
            "- export JAVA_HOME=$DEVECO_PATH/Contents/jbr/Contents/Home",
            "- unset NODE_HOME && unset HVIGOR_APP_HOME",
            "- \"$NODE_BIN\" \"$HVIGOR_JS\" --mode module -p product=default assembleHap --analyze=normal --parallel --incremental --no-daemon",
            "- \"$NODE_BIN\" \"$HVIGOR_JS\" --stop-daemon",
            "环境关键点:",
            "- 不要修改签名配置和 build-profile.json5",
            "- 如果日志出现 NODE_HOME / hvigorw.js / ohpm 错误，优先修正环境变量和工具路径",
        ])
        return "\n".join(lines)

    lines = [f"Skill 名称: {skill_name}"]
    if description:
        lines.append(f"Skill 说明: {description}")
    lines.append("该 Skill 已挂载，请按其说明执行，不要忽略。")
    return "\n".join(lines)


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
    """根据最小可用 case.yaml 生成发给 agent 的任务描述"""
    project = case_spec.get("project", {})
    problem = case_spec.get("problem", {})
    agent = case_spec.get("agent", {})
    constraints = case_spec.get("constraints", []) or []

    lines = [
        "这是一个已有的 HarmonyOS ArkTS 工程，请直接在当前工程中修改代码完成修复。",
        "",
        "## 工程说明",
        project.get("summary", "").strip(),
        "",
        "## 当前问题",
        problem.get("summary", "").strip(),
        "",
        "## 重点相关文件",
    ]

    for path in problem.get("related_files", []) or []:
        lines.append(f"- {path}")

    lines.extend([
        "",
        "## 期望效果",
    ])
    for item in problem.get("expected_result", []) or []:
        lines.append(f"- {item}")

    lines.extend([
        "",
        "## 结果输出要求",
    ])
    for item in agent.get("output_requirements", []) or []:
        lines.append(f"- {item}")

    if constraints:
        lines.extend([
            "",
            "## 约束",
        ])
        for item in constraints:
            lines.append(f"- {item}")

    return "\n".join([line for line in lines if line is not None]).strip()


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


def load_agents_registry() -> dict:
    """加载 agents/agents.yaml，总是返回带 agents 列表的 dict。"""
    if _registry_cache["agents"] is None:
        if os.path.exists(AGENTS_REGISTRY_PATH):
            data = load_yaml(AGENTS_REGISTRY_PATH) or {}
            _registry_cache["agents"] = data if isinstance(data, dict) else {}
        else:
            _registry_cache["agents"] = {}

    registry = _registry_cache["agents"] or {}
    agents = registry.get("agents")
    if isinstance(agents, list):
        registry.setdefault("defaults", {})
        return registry

    fallback_agent = {
        "id": "agent_default",
        "name": "OpenCode Default",
        "adapter": "opencode",
        "api_base": "http://localhost:4096",
        "model": None,
        "enabled": True,
    }
    return {"defaults": {}, "agents": [fallback_agent]}


def load_agent_defaults() -> dict:
    """返回 Agent 默认配置。"""
    registry = load_agents_registry()
    defaults = registry.get("defaults")
    return defaults if isinstance(defaults, dict) else {}


def load_agents() -> List[dict]:
    """返回可用 Agent 列表。"""
    registry = load_agents_registry()
    agents = registry.get("agents", [])
    return [agent for agent in agents if agent.get("enabled", True)]


def load_agent(agent_id: str) -> Optional[dict]:
    """根据 agent_id 获取 Agent 定义。"""
    if not agent_id:
        return None
    defaults = load_agent_defaults()
    for agent in load_agents():
        if agent.get("id") == agent_id:
            merged = dict(defaults)
            merged.update(agent)
            return merged
    return None


def _resolve_skill_mount_path(path: str) -> str:
    if not path:
        raise ValueError("Skill 路径不能为空")
    if os.path.isdir(path):
        candidate = os.path.join(path, "SKILL.md")
        if os.path.isfile(candidate):
            return candidate
    if os.path.isfile(path):
        return path
    raise FileNotFoundError(f"Skill 文件不存在: {path}")


def _cleanup_enhancement_dict(data: dict) -> dict:
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


def merge_enhancements(base: Optional[dict], extra: Optional[dict]) -> dict:
    """合并两份增强配置。"""
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

    return _cleanup_enhancement_dict(merged)


def build_agent_runtime_enhancements(agent: Optional[dict]) -> dict:
    """根据 Agent 配置构造运行时增强项。"""
    if not agent:
        return {}

    result = {
        "skills": [],
        "mcp_servers": list(agent.get("mcp_servers") or []),
        "system_prompt": "",
        "tools": agent.get("tools"),
    }

    for skill in agent.get("mounted_skills", []) or []:
        if not isinstance(skill, dict):
            continue
        skill_name = skill.get("name") or "external-skill"
        skill_path = _resolve_skill_mount_path(skill.get("path", ""))
        result["skills"].append({
            "name": skill_name,
            "path": skill_path,
            "content": _build_skill_summary(skill_name, skill_path),
        })

    compile_loop = agent.get("compile_loop") or {}
    if compile_loop.get("enabled"):
        max_rounds = int(compile_loop.get("max_rounds") or 5)
        skill_name = compile_loop.get("skill_name") or "harmonyos-hvigor"
        result["system_prompt"] = (
            f"你已挂载 Skill `{skill_name}`，必须使用它执行当前 HarmonyOS 工程的内部编译自检。\n"
            f"每次完成一轮代码修改后，必须立即按该 Skill 的方法对当前工程执行一次 hvigor 编译检查。\n"
            f"如果编译失败，必须把完整编译日志作为下一轮分析输入，继续修改并再次编译。\n"
            f"重复“修改 -> 编译 -> 读取日志 -> 继续修复”的循环，最多执行 {max_rounds} 轮，直到编译通过。\n"
            "达到最大轮次仍未通过时，必须明确说明最后一次编译错误、已尝试的修复和当前阻塞点。\n"
            "这条内部编译循环只是 agent 自检，不替代评测系统最终的外部编译验证。"
        )

    return _cleanup_enhancement_dict(result)


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
    返回的 case 格式统一为 {id, title, prompt, case_dir, case_spec, ...}
    """
    registry = load_test_cases_registry()
    for s in registry.get("scenarios", []):
        if s.get("id") == scenario or s.get("name") == scenario:
            raw_cases = s.get("cases", [])
            return [_transform_case(c) for c in raw_cases]
    return []


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
