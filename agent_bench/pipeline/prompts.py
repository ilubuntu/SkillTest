# -*- coding: utf-8 -*-
"""Pipeline Prompt 组装。"""

from agent_bench.agent_runner import AgentSpec

TASK_PROMPT = """{prompt}"""
TASK_PROMPT_MULTI_PAGE = """{prompt}

## 参考补充文件
{additional_pages}
"""

BUILD_HARMONY_PROJECT_EXTRA_PROMPT = (
    "你已挂载harmonyos-build这个skill，完成一轮代码修改并准备结束时，"
    "必须先调用skill对当前工程执行一次编译验证，如果编译失败，"
    "必须根据编译错误继续修改代码并再次验证，最多重试5轮。"
)


def _extra_prompt_with_skill_requirements(agent_spec: AgentSpec) -> str:
    extra_prompt = str(agent_spec.extra_prompt or "").strip()
    skill_names = set(agent_spec.mounted_skill_names)
    if "harmonyos-build" not in skill_names:
        return extra_prompt
    if BUILD_HARMONY_PROJECT_EXTRA_PROMPT in extra_prompt:
        return extra_prompt
    if not extra_prompt:
        return BUILD_HARMONY_PROJECT_EXTRA_PROMPT
    return f"{BUILD_HARMONY_PROJECT_EXTRA_PROMPT}\n{extra_prompt}"


def build_agent_task_prompt(case: dict, prompt: str, on_progress, agent_spec: AgentSpec) -> str:
    full_prompt = prompt
    extra_prompt = _extra_prompt_with_skill_requirements(agent_spec)
    if extra_prompt:
        full_prompt = f"{prompt}\n\n## 额外执行要求\n{extra_prompt}"

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
