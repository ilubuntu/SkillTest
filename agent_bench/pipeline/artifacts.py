# -*- coding: utf-8 -*-
"""产物持久化

按阶段子目录组织：
  side_a/     — A 侧运行工程与元数据
  side_b/     — B 侧运行工程与元数据
  rule_check/ — 内部规则评分结果
  llm_judge/  — LLM Judge 评分结果
  result.json — 汇总结果（case 根目录）
"""

import json
import os

META_DIR_NAME = ".agent_bench"


def stage_dir(case_dir: str, stage: str) -> str:
    """返回指定阶段的子目录路径并确保存在"""
    d = os.path.join(case_dir, stage)
    os.makedirs(d, exist_ok=True)
    return d


def stage_meta_dir(case_dir: str, stage: str) -> str:
    """返回阶段元数据目录路径并确保存在"""
    d = os.path.join(stage_dir(case_dir, stage), META_DIR_NAME)
    os.makedirs(d, exist_ok=True)
    return d


# ── Runner 阶段 ──────────────────────────────────────────────

def save_runner_stage_artifacts(case_dir: str,
                                stage: str,
                                output: str,
                                task_prompt: str = "",
                                enhancements: dict = None):
    """保存单个 Runner 阶段产物，支持失败时保留已完成阶段。"""
    sd = stage_meta_dir(case_dir, stage)
    with open(os.path.join(sd, "output.txt"), "w", encoding="utf-8") as f:
        f.write(output)
    if task_prompt:
        with open(os.path.join(sd, "input.txt"), "w", encoding="utf-8") as f:
            f.write(task_prompt)
    if stage == "side_b" and enhancements:
        with open(os.path.join(sd, "enhancements.json"), "w", encoding="utf-8") as f:
            json.dump(enhancements, f, ensure_ascii=False, indent=2)

def save_runner_artifacts(case_dir: str,
                          side_a_output: str, side_b_output: str,
                          task_prompt: str = "",
                          enhancements: dict = None,
                          include_side_b: bool = True):
    """保存 Runner 阶段产物到 side_a/ 和 side_b/ 子目录"""
    save_runner_stage_artifacts(case_dir, "side_a", side_a_output, task_prompt=task_prompt)
    if include_side_b:
        save_runner_stage_artifacts(case_dir, "side_b", side_b_output, task_prompt=task_prompt, enhancements=enhancements)


def save_interaction_metrics(case_dir: str, stage: str, metrics: dict):
    """保存统一交互指标文件。"""
    if not metrics:
        return
    target_dir = stage_meta_dir(case_dir, stage) if stage in ("side_a", "side_b") else stage_dir(case_dir, stage)
    with open(os.path.join(target_dir, "interaction_metrics.json"), "w", encoding="utf-8") as f:
        json.dump(metrics, f, ensure_ascii=False, indent=2)


def save_compile_artifacts(case_dir: str, stage: str, compile_result: dict):
    """保存编译阶段产物。"""
    target_dir = stage_dir(case_dir, stage)
    with open(os.path.join(target_dir, "compile_result.json"), "w", encoding="utf-8") as f:
        json.dump(compile_result, f, ensure_ascii=False, indent=2)
    with open(os.path.join(target_dir, "compile.log.txt"), "w", encoding="utf-8") as f:
        f.write(compile_result.get("error", "") or ("编译成功" if compile_result.get("compilable") else ""))


def load_runner_artifacts(case_dir: str) -> tuple:
    """加载 Runner 阶段产物

    Returns:
        (side_a_output, side_b_output)
    """
    side_a_path = os.path.join(case_dir, "side_a", META_DIR_NAME, "output.txt")
    side_b_path = os.path.join(case_dir, "side_b", META_DIR_NAME, "output.txt")
    if not os.path.exists(side_a_path):
        raise FileNotFoundError(f"Runner 产物不存在: {case_dir}，请先运行 runner 阶段")
    with open(side_a_path, "r", encoding="utf-8") as f:
        side_a_output = f.read()
    if os.path.exists(side_b_path):
        with open(side_b_path, "r", encoding="utf-8") as f:
            side_b_output = f.read()
    else:
        side_b_output = ""
    return side_a_output, side_b_output


# ── Evaluator 阶段 ───────────────────────────────────────────

def save_evaluator_artifacts(case_dir: str,
                             internal_score: dict,
                             judge_result: dict,
                             result: dict):
    """保存 Evaluator 阶段产物到 rule_check/ 和 llm_judge/ 子目录"""
    rule_dir = os.path.join(case_dir, "rule_check")
    os.makedirs(rule_dir, exist_ok=True)
    with open(os.path.join(rule_dir, "internal_score.json"), "w", encoding="utf-8") as f:
        json.dump(internal_score, f, ensure_ascii=False, indent=2)

    judge_dir = os.path.join(case_dir, "llm_judge")
    os.makedirs(judge_dir, exist_ok=True)
    with open(os.path.join(judge_dir, "judge.json"), "w", encoding="utf-8") as f:
        json.dump(judge_result, f, ensure_ascii=False, indent=2)

    with open(os.path.join(case_dir, "result.json"), "w", encoding="utf-8") as f:
        json.dump(result, f, ensure_ascii=False, indent=2)


def save_case_result(case_dir: str, result: dict):
    """单独保存 case 汇总结果。"""
    os.makedirs(case_dir, exist_ok=True)
    with open(os.path.join(case_dir, "result.json"), "w", encoding="utf-8") as f:
        json.dump(result, f, ensure_ascii=False, indent=2)


def save_rule_check_artifact(case_dir: str, internal_score: dict):
    """单独保存规则检查结果，避免后续阶段失败时丢失。"""
    rule_dir = os.path.join(case_dir, "rule_check")
    os.makedirs(rule_dir, exist_ok=True)
    with open(os.path.join(rule_dir, "internal_score.json"), "w", encoding="utf-8") as f:
        json.dump(internal_score, f, ensure_ascii=False, indent=2)


def load_evaluator_result(case_dir: str) -> dict:
    """加载 Evaluator 阶段的 result.json"""
    result_path = os.path.join(case_dir, "result.json")
    if not os.path.exists(result_path):
        raise FileNotFoundError(f"Evaluator 产物不存在: {case_dir}，请先运行 evaluator 阶段")
    with open(result_path, "r", encoding="utf-8") as f:
        return json.load(f)
