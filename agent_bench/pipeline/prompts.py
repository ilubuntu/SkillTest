# -*- coding: utf-8 -*-
"""Pipeline Prompt 组装。"""

from agent_bench.agent_runner import AgentSpec

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
