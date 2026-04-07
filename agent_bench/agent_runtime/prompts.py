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
