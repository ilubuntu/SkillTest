# -*- coding: utf-8 -*-
"""产物持久化

职责：
- Runner 阶段产物的保存与加载（baseline_output / enhanced_output）
- Evaluator 阶段产物的保存与加载（rule_check / judge / result）
"""

import json
import os


def save_runner_artifacts(case_dir: str, baseline_output: str, enhanced_output: str):
    """保存 Runner 阶段产物"""
    os.makedirs(case_dir, exist_ok=True)
    with open(os.path.join(case_dir, "baseline_output.txt"), "w", encoding="utf-8") as f:
        f.write(baseline_output)
    with open(os.path.join(case_dir, "enhanced_output.txt"), "w", encoding="utf-8") as f:
        f.write(enhanced_output)


def load_runner_artifacts(case_dir: str) -> tuple:
    """加载 Runner 阶段产物

    Returns:
        (baseline_output, enhanced_output)
    """
    baseline_path = os.path.join(case_dir, "baseline_output.txt")
    enhanced_path = os.path.join(case_dir, "enhanced_output.txt")
    if not os.path.exists(baseline_path) or not os.path.exists(enhanced_path):
        raise FileNotFoundError(f"Runner 产物不存在: {case_dir}，请先运行 runner 阶段")
    with open(baseline_path, "r", encoding="utf-8") as f:
        baseline_output = f.read()
    with open(enhanced_path, "r", encoding="utf-8") as f:
        enhanced_output = f.read()
    return baseline_output, enhanced_output


def save_evaluator_artifacts(case_dir: str,
                             internal_score: dict,
                             judge_result: dict,
                             result: dict):
    """保存 Evaluator 阶段产物

    Args:
        case_dir: 产物目录
        internal_score: 内部评分结果 (internal_score.json)
        judge_result: LLM Judge 原始结果 (judge.json)
        result: 最终汇总结果 (result.json)
    """
    os.makedirs(case_dir, exist_ok=True)
    with open(os.path.join(case_dir, "internal_score.json"), "w", encoding="utf-8") as f:
        json.dump(internal_score, f, ensure_ascii=False, indent=2)
    with open(os.path.join(case_dir, "judge.json"), "w", encoding="utf-8") as f:
        json.dump(judge_result, f, ensure_ascii=False, indent=2)
    with open(os.path.join(case_dir, "result.json"), "w", encoding="utf-8") as f:
        json.dump(result, f, ensure_ascii=False, indent=2)


def load_evaluator_result(case_dir: str) -> dict:
    """加载 Evaluator 阶段的 result.json"""
    result_path = os.path.join(case_dir, "result.json")
    if not os.path.exists(result_path):
        raise FileNotFoundError(f"Evaluator 产物不存在: {case_dir}，请先运行 evaluator 阶段")
    with open(result_path, "r", encoding="utf-8") as f:
        return json.load(f)
