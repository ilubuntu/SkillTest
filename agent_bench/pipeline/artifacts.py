# -*- coding: utf-8 -*-
"""产物持久化。"""

import json
import os
import re

ANSI_ESCAPE_RE = re.compile(r"\x1b\[[0-9;]*[A-Za-z]")


def _strip_ansi_sequences(value):
    if isinstance(value, str):
        return ANSI_ESCAPE_RE.sub("", value)
    if isinstance(value, dict):
        return {key: _strip_ansi_sequences(item) for key, item in value.items()}
    if isinstance(value, list):
        return [_strip_ansi_sequences(item) for item in value]
    return value

def stage_dir(case_dir: str, stage: str) -> str:
    """返回指定阶段目录并确保存在。"""
    d = os.path.join(case_dir, stage)
    os.makedirs(d, exist_ok=True)
    return d


def agent_workspace_dir(case_dir: str) -> str:
    return stage_dir(case_dir, "workspace")


def agent_meta_dir(case_dir: str) -> str:
    return stage_dir(case_dir, "generate")


def original_project_dir(case_dir: str) -> str:
    return stage_dir(case_dir, "original")


def diff_dir(case_dir: str) -> str:
    return stage_dir(case_dir, "diff")


def opencode_runtime_dir(case_dir: str) -> str:
    return stage_dir(case_dir, "opencode")


def checks_dir(case_dir: str) -> str:
    return stage_dir(case_dir, "checks")


# ── Runner 阶段 ──────────────────────────────────────────────

def save_runner_artifacts(case_dir: str,
                          output: str,
                          task_prompt: str = ""):
    """保存单 agent 执行产物。"""
    sd = agent_meta_dir(case_dir)
    with open(os.path.join(sd, "output.txt"), "w", encoding="utf-8") as f:
        f.write(output)
    if task_prompt:
        with open(os.path.join(sd, "input.txt"), "w", encoding="utf-8") as f:
            f.write(task_prompt)


def save_interaction_metrics(case_dir: str, stage: str, metrics: dict):
    """保存统一交互指标文件。"""
    if not metrics:
        return
    target_dir = agent_meta_dir(case_dir) if stage == "agent" else stage_dir(case_dir, stage)
    filename = f"{stage}_interaction_metrics.json" if stage else "interaction_metrics.json"
    with open(os.path.join(target_dir, filename), "w", encoding="utf-8") as f:
        json.dump(metrics, f, ensure_ascii=False, indent=2)


def save_compile_artifacts(case_dir: str, stage: str, compile_result: dict):
    """保存编译阶段产物。"""
    target_dir = os.path.join(checks_dir(case_dir), stage)
    os.makedirs(target_dir, exist_ok=True)
    sanitized_result = _strip_ansi_sequences(compile_result or {})
    with open(os.path.join(target_dir, "compile_result.json"), "w", encoding="utf-8") as f:
        json.dump(sanitized_result, f, ensure_ascii=False, indent=2)
    with open(os.path.join(target_dir, "compile.log.txt"), "w", encoding="utf-8") as f:
        f.write(sanitized_result.get("error", "") or ("编译成功" if sanitized_result.get("compilable") else ""))


def load_runner_artifacts(case_dir: str) -> tuple:
    """加载单 agent Runner 产物。"""
    meta_dir = agent_meta_dir(case_dir)
    display_path = os.path.join(meta_dir, "output.txt")
    raw_path = os.path.join(meta_dir, "raw_output.txt")
    if not os.path.exists(raw_path) and not os.path.exists(display_path):
        raise FileNotFoundError(f"Runner 产物不存在: {case_dir}，请先运行 runner 阶段")
    with open(raw_path if os.path.exists(raw_path) else display_path, "r", encoding="utf-8") as f:
        output = f.read()
    return output


def save_case_result(case_dir: str, result: dict):
    """单独保存 case 汇总结果。"""
    os.makedirs(case_dir, exist_ok=True)
    with open(os.path.join(case_dir, "result.json"), "w", encoding="utf-8") as f:
        json.dump(result, f, ensure_ascii=False, indent=2)
