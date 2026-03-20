#!/usr/bin/env python3
"""Skill 评测系统 - 主入口

用法:
    python3 run_eval.py                          # 运行所有 bug_fix 用例
    python3 run_eval.py --skill-type bug_fix     # 指定 skill 类型
    python3 run_eval.py --dry-run                # 干跑模式，不调用 Agent
"""

import argparse
import json
import os
import sys
import time

# 将项目根目录加入 path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from runner.agent_runner import run_baseline, run_enhanced
from evaluator.rule_checker import check as rule_check
from evaluator.llm_judge import judge as llm_judge
from report.reporter import generate as generate_report

# 评分权重：规则 30%，LLM 70%
RULE_WEIGHT = 0.3
LLM_WEIGHT = 0.7

BASE_DIR = os.path.dirname(os.path.abspath(__file__))


def load_test_cases(skill_type: str) -> list:
    cases_dir = os.path.join(BASE_DIR, "test_cases", skill_type)
    cases = []
    for f in sorted(os.listdir(cases_dir)):
        if f.endswith(".json"):
            with open(os.path.join(cases_dir, f), "r", encoding="utf-8") as fh:
                cases.append(json.load(fh))
    return cases


def load_file(skill_type: str, relative_path: str) -> str:
    path = os.path.join(BASE_DIR, "test_cases", skill_type, relative_path)
    with open(path, "r", encoding="utf-8") as f:
        return f.read()


def load_skill(skill_name: str) -> str:
    path = os.path.join(BASE_DIR, "skills", f"{skill_name}.md")
    with open(path, "r", encoding="utf-8") as f:
        return f.read()


def compute_total(rule_score: float, llm_scores: list, rubric: list) -> float:
    llm_weighted = 0
    total_weight = 0
    for rubric_item in rubric:
        name = rubric_item["name"]
        weight = rubric_item["weight"]
        score = next((s["score"] for s in llm_scores if s["name"] == name), 50)
        llm_weighted += score * weight
        total_weight += weight

    llm_avg = llm_weighted / total_weight if total_weight > 0 else 50
    return round(RULE_WEIGHT * rule_score + LLM_WEIGHT * llm_avg, 1)


def run_case(case: dict, skill_type: str, skill_content: str, dry_run: bool = False) -> dict:
    case_id = case["id"]
    title = case["title"]
    description = case["input"]["description"]
    input_code = load_file(skill_type, case["input"]["code_file"])
    reference_code = load_file(skill_type, case["expected"]["reference_file"])
    rubric = case["expected"]["rubric"]

    print(f"\n  -> 基线运行 (无 Skill)...", end=" ", flush=True)
    if dry_run:
        baseline_output = "// dry run - no output"
        print("跳过 (dry-run)")
    else:
        t0 = time.time()
        baseline_output = run_baseline(description, input_code)
        print(f"完成 ({time.time() - t0:.0f}s)")

    print(f"  -> 增强运行 (挂载 Skill)...", end=" ", flush=True)
    if dry_run:
        enhanced_output = reference_code  # dry-run 用参考答案模拟
        print("跳过 (dry-run, 使用参考答案)")
    else:
        t0 = time.time()
        enhanced_output = run_enhanced(description, input_code, skill_content)
        print(f"完成 ({time.time() - t0:.0f}s)")

    # 规则评分
    print(f"  -> 规则检查...", end=" ", flush=True)
    baseline_rule = rule_check(baseline_output, case["expected"])
    enhanced_rule = rule_check(enhanced_output, case["expected"])
    print(f"基线={baseline_rule['rule_score']}, 增强={enhanced_rule['rule_score']}")

    # LLM 评分
    print(f"  -> LLM 评分...", end=" ", flush=True)
    if dry_run:
        baseline_llm = {"scores": [{"name": r["name"], "score": 30, "reason": "dry-run"} for r in rubric]}
        enhanced_llm = {"scores": [{"name": r["name"], "score": 85, "reason": "dry-run"} for r in rubric]}
        print("跳过 (dry-run)")
    else:
        baseline_llm = llm_judge(input_code, baseline_output, reference_code, rubric)
        enhanced_llm = llm_judge(input_code, enhanced_output, reference_code, rubric)
        print("完成")

    # 汇总
    baseline_total = compute_total(baseline_rule["rule_score"], baseline_llm["scores"], rubric)
    enhanced_total = compute_total(enhanced_rule["rule_score"], enhanced_llm["scores"], rubric)

    dimension_scores = {}
    for r_item in rubric:
        name = r_item["name"]
        b_score = next((s["score"] for s in baseline_llm["scores"] if s["name"] == name), 50)
        e_score = next((s["score"] for s in enhanced_llm["scores"] if s["name"] == name), 50)
        dimension_scores[name] = {"baseline": b_score, "enhanced": e_score}

    return {
        "case_id": case_id,
        "title": title,
        "baseline_rule": baseline_rule["rule_score"],
        "enhanced_rule": enhanced_rule["rule_score"],
        "baseline_total": baseline_total,
        "enhanced_total": enhanced_total,
        "dimension_scores": dimension_scores,
    }


def main():
    parser = argparse.ArgumentParser(description="Skill 评测系统")
    parser.add_argument("--skill-type", default="bug_fix", help="要测试的 skill 类型")
    parser.add_argument("--dry-run", action="store_true", help="干跑模式，不调用 Agent")
    args = parser.parse_args()

    skill_type = args.skill_type

    print(f"========================================")
    print(f"  Skill 评测系统")
    print(f"  被测 Skill: {skill_type}")
    print(f"  模式: {'dry-run' if args.dry_run else '正式运行'}")
    print(f"========================================")

    cases = load_test_cases(skill_type)
    print(f"\n加载了 {len(cases)} 个测试用例")

    skill_content = load_skill(skill_type)

    results = []
    for i, case in enumerate(cases):
        print(f"\n[{i + 1}/{len(cases)}] {case['id']} - {case['title']}")
        result = run_case(case, skill_type, skill_content, dry_run=args.dry_run)
        results.append(result)
        gain = result["enhanced_total"] - result["baseline_total"]
        print(f"  -> 结果: 基线={result['baseline_total']}, 增强={result['enhanced_total']}, 增益={'+' if gain >= 0 else ''}{gain}")

    output_dir = os.path.join(BASE_DIR, "report", "output")
    json_path, md_path = generate_report(results, skill_type, output_dir)

    print(f"\n========================================")
    print(f"  评测完成!")
    print(f"  JSON 报告: {json_path}")
    print(f"  Markdown 报告: {md_path}")
    print(f"========================================")


if __name__ == "__main__":
    main()
