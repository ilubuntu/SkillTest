# -*- coding: utf-8 -*-
"""Agent Prompt 组装。"""

import json

from agent_bench.agent_runtime.spec import AgentSpec

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


def build_constraint_review_prompt(case: dict,
                                   original_project_root: str,
                                   repaired_project_root: str,
                                   repair_patch_file: str,
                                   agent_spec: AgentSpec) -> str:
    case_spec = case.get("case_spec") or {}
    case_prompt = str(case.get("prompt") or "").strip()
    constraints = case_spec.get("constraints") or []
    prompt = (
        "你是 ArkTS 代码专家和 HarmonyOS 约束规则评分专家。"
        "现在有一份由 AI 修改后的 HarmonyOS/ArkTS 工程，需要你对这次 AI 修改结果进行约束规则评分。"
        "你需要基于以下材料完成本次评分："
        f"原始问题：{case_prompt}；"
        f"原始工程目录：{original_project_root}；"
        f"修复后的 patch 文件：{repair_patch_file}；"
        f"修复后工程目录：{repaired_project_root}；"
        f"约束规则：{json.dumps(constraints, ensure_ascii=False)}。"
        "请先理解原始问题，再结合 patch 理解 AI 修改了哪些文件和逻辑，必要时对照原始工程与修复后工程确认修改实际落地结果，"
        "然后基于修复后工程中的真实文件，严格按照约束规则对本次 AI 修改结果进行评分。"
        "原始工程只作为基线证据，patch 文件只用于帮助理解改动范围，最终评分对象是修复后工程。"
        "如果原始问题与约束规则存在冲突，以约束规则为准。"
    ).strip()
    if agent_spec.extra_prompt:
        prompt = f"{prompt}\n\n## 额外执行要求\n{agent_spec.extra_prompt}"
    return prompt
