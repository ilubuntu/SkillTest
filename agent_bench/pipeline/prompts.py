# -*- coding: utf-8 -*-
"""Pipeline Prompt 组装。"""

import json

from agent_bench.agent_runner import AgentSpec
from agent_bench.pipeline.constraint_adapter import sanitize_all_constraints_for_review

TASK_PROMPT = """{prompt}"""
TASK_PROMPT_MULTI_PAGE = """{prompt}

## 参考补充文件
{additional_pages}
"""
def build_agent_task_prompt(case: dict, prompt: str, on_progress, agent_spec: AgentSpec) -> str:
    full_prompt = prompt
    if agent_spec.extra_prompt:
        full_prompt = f"{prompt}\n\n## 额外执行要求\n{agent_spec.extra_prompt}"

    additional_files = case.get("additional_files", {}) or {}
    sibling_files = additional_files.get("sibling_files", {}) or {}
    pages_files = additional_files.get("pages", {}) or {}
    if sibling_files or pages_files:
        all_additional = {**sibling_files, **pages_files}
        additional_pages_text = "\n\n".join(
            f"=== {filename} ===\n{content}" for filename, content in all_additional.items()
        )
        if on_progress:
            on_progress("log", {
                "level": "INFO",
                "message": f"多页面场景：检测到 {len(all_additional)} 个额外页面文件",
            })
        return TASK_PROMPT_MULTI_PAGE.format(
            prompt=full_prompt,
            additional_pages=additional_pages_text,
        )
    return TASK_PROMPT.format(prompt=full_prompt)


def _build_scenario_instruction(scenario: str) -> str:
    """根据场景生成评分指引，注入到约束评分 prompt 中。"""
    scenario_labels = {
        "bug_fix": "缺陷修复",
        "performance": "性能优化",
        "requirement": "需求实现",
        "project_gen": "工程生成",
    }
    label = scenario_labels.get(scenario, scenario)

    incremental_scenarios = {"bug_fix", "performance", "requirement"}
    if scenario in incremental_scenarios:
        return (
            f"当前场景：{label}。"
            "这是在已有工程上做增量修改的任务。"
            "对于公共约束（id 以 HM-PUBLIC- 开头），应采用宽容评分原则："
            "如果原始工程中已存在同样的违规模式（如魔法数、未使用设计 Token 等），"
            "且本次修改未引入新的同类违规，则该公共约束应判为通过（得分不为 0）；"
            "只有当本次修改引入了新的同类违规时才应扣分。"
            "对 case 约束（id 不以 HM-PUBLIC- 开头）仍严格评分。"
        )
    elif scenario == "project_gen":
        return (
            f"当前场景：{label}。"
            "这是从零生成工程的任务，所有约束（包括公共约束）均严格评分。"
        )
    return f"当前场景：{label}。"


def build_constraint_review_prompt(case: dict,
                                   original_project_root: str,
                                   repaired_project_root: str,
                                   repair_patch_file: str,
                                   agent_spec: AgentSpec) -> str:
    case_spec = case.get("case_spec") or {}
    case_prompt = str(case.get("prompt") or "").strip()
    scenario = case.get("scenario", "")
    constraints = sanitize_all_constraints_for_review(case_spec.get("constraints") or [], scenario)
    patch_input = repair_patch_file or "(patch unavailable; score directly from repaired_project_root)"
    sections = [
        "请对当前修复结果执行约束规则评分，并严格按约束检查修复后的工程。",
        "",
        "## 输入 1：原始工程目录",
        original_project_root,
        "",
        "## 输入 2：修复后的 patch 文件",
        patch_input,
        "",
        "## 输入 3：修复后工程目录",
        repaired_project_root,
        "",
        "## 输入 4：用例输入内容",
        case_prompt,
        "",
        "## 输入 5：用例约束规则",
        json.dumps(constraints, ensure_ascii=False, indent=2),
    ]
    scenario_instruction = _build_scenario_instruction(scenario)
    if scenario_instruction:
        sections.extend(["", "## 评分场景指引", scenario_instruction])
    if not repair_patch_file:
        sections.extend([
            "",
            "## Patch Availability",
            "repair_patch_file unavailable. Read repaired_project_root directly and complete constraint scoring without waiting for patch access.",
        ])
    prompt = "\n".join(sections).strip()
    if agent_spec.extra_prompt:
        prompt = f"{prompt}\n\n## 额外执行要求\n{agent_spec.extra_prompt}"
    return prompt


def build_static_review_prompt(case: dict,
                               original_project_root: str,
                               repaired_project_root: str,
                               repair_patch_file: str,
                               agent_spec: AgentSpec) -> str:
    case_prompt = str(case.get("prompt") or "").strip()
    patch_input = repair_patch_file or "(patch unavailable; score directly from repaired_project_root)"
    sections = [
        "请基于修复后的工程，对这次 AI 修改结果执行静态代码质量评分。",
        "",
        "## 输入 1：原始工程目录",
        original_project_root,
        "",
        "## 输入 2：修复后的 patch 文件",
        patch_input,
        "",
        "## 输入 3：修复后工程目录",
        repaired_project_root,
        "",
        "## 输入 4：用例输入内容",
        case_prompt,
        "",
        "原始工程只作为基线证据，patch 文件只用于帮助理解改动范围，最终评分对象是修复后工程。",
    ]
    prompt = "\n".join(sections).strip()
    if agent_spec.extra_prompt:
        prompt = f"{prompt}\n\n## 额外执行要求\n{agent_spec.extra_prompt}"
    return prompt
