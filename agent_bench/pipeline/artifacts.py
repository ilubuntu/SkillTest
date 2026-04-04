# -*- coding: utf-8 -*-
"""产物持久化。

当前执行模型为单 agent：
  agent_workspace/ — Agent 修改后的工程目录
  agent_meta/      — prompt / output / metrics / changed_files 等元数据
  result.json      — 汇总结果
"""

import json
import os

def stage_dir(case_dir: str, stage: str) -> str:
    """返回指定阶段目录并确保存在。"""
    d = os.path.join(case_dir, stage)
    os.makedirs(d, exist_ok=True)
    return d


def stage_meta_dir(case_dir: str, stage: str) -> str:
    """返回阶段元数据目录并确保存在。"""
    d = os.path.join(case_dir, f"{stage}_meta")
    os.makedirs(d, exist_ok=True)
    return d


def agent_workspace_dir(case_dir: str) -> str:
    return stage_dir(case_dir, "agent_workspace")


def agent_meta_dir(case_dir: str) -> str:
    return stage_meta_dir(case_dir, "agent")


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
    with open(os.path.join(target_dir, "interaction_metrics.json"), "w", encoding="utf-8") as f:
        json.dump(metrics, f, ensure_ascii=False, indent=2)


def save_constraint_review_artifacts(case_dir: str,
                                     stage: str,
                                     raw_output: str,
                                     display_output: str,
                                     skill_content: str,
                                     score_result: dict):
    """保存约束评分 skill、评分结果，并将 output.txt 更新为带评分摘要的展示版本。"""
    target_dir = stage_meta_dir(case_dir, stage)

    with open(os.path.join(target_dir, "raw_output.txt"), "w", encoding="utf-8") as f:
        f.write(raw_output or "")
    with open(os.path.join(target_dir, "output.txt"), "w", encoding="utf-8") as f:
        f.write(display_output or raw_output or "")
    with open(os.path.join(target_dir, "constraint_review_skill.md"), "w", encoding="utf-8") as f:
        f.write(skill_content or "")
    with open(os.path.join(target_dir, "constraint_review_score.json"), "w", encoding="utf-8") as f:
        json.dump(score_result or {}, f, ensure_ascii=False, indent=2)


def save_compile_artifacts(case_dir: str, stage: str, compile_result: dict):
    """保存编译阶段产物。"""
    target_dir = stage_dir(case_dir, stage)
    with open(os.path.join(target_dir, "compile_result.json"), "w", encoding="utf-8") as f:
        json.dump(compile_result, f, ensure_ascii=False, indent=2)
    with open(os.path.join(target_dir, "compile.log.txt"), "w", encoding="utf-8") as f:
        f.write(compile_result.get("error", "") or ("编译成功" if compile_result.get("compilable") else ""))


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
