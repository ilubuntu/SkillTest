#!/usr/bin/env python3
"""Agent Bench 评测系统 - 主入口

支持三种评测类型:
  - skill:          Skill 文本注入 prompt
  - mcp_tool:       MCP Tool 通过 --mcp-config 挂载
  - system_prompt:   System Prompt 通过 -s 注入

用法:
    python3 run_eval.py                          # 运行所有 bug_fix 用例
    python3 run_eval.py --suite bug_fix          # 指定测试套件
    python3 run_eval.py --dry-run                # 干跑模式，不调用 Agent
    python3 run_eval.py --eval-type skill        # 只运行指定评测类型的用例
"""

import argparse
import json
import os
import sys
import time

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from runner.agent_runner import run_baseline, run_enhanced
from evaluator.rule_checker import check as rule_check
from evaluator.llm_judge import judge as llm_judge
from report.reporter import generate as generate_report

# 评分权重：规则 30%，LLM 70%
RULE_WEIGHT = 0.3
LLM_WEIGHT = 0.7

BASE_DIR = os.path.dirname(os.path.abspath(__file__))

# eval_type → 被测对象文件目录和扩展名
SUBJECT_REGISTRY = {
    "skill":         {"dir": "subjects/skill",          "ext": ".md"},
    "mcp_tool":      {"dir": "subjects/mcp_tool",       "ext": ".json"},
    "system_prompt": {"dir": "subjects/system_prompt",   "ext": ".md"},
}


def load_test_cases(suite: str, eval_type_filter: str = None) -> list:
    """加载测试套件下的所有用例，可按 eval_type 过滤"""
    cases_dir = os.path.join(BASE_DIR, "test_cases", suite)
    cases = []
    for f in sorted(os.listdir(cases_dir)):
        if f.endswith(".json"):
            with open(os.path.join(cases_dir, f), "r", encoding="utf-8") as fh:
                case = json.load(fh)
                # 兼容旧格式：无 eval_type 默认 skill，无 subject 取 skill_type
                case.setdefault("eval_type", "skill")
                case.setdefault("subject", case.get("skill_type", suite))
                if eval_type_filter and case["eval_type"] != eval_type_filter:
                    continue
                cases.append(case)
    return cases


def load_file(suite: str, relative_path: str) -> str:
    path = os.path.join(BASE_DIR, "test_cases", suite, relative_path)
    with open(path, "r", encoding="utf-8") as f:
        return f.read()


def load_subject(eval_type: str, subject_name: str):
    """根据 eval_type 加载被测对象

    Returns:
        (subject_content, subject_path)
        - skill / system_prompt: content 为文本, path 为文件路径
        - mcp_tool: content 为 None, path 为配置文件路径
    """
    reg = SUBJECT_REGISTRY.get(eval_type)
    if not reg:
        raise ValueError(f"Unknown eval_type: {eval_type}")

    path = os.path.join(BASE_DIR, reg["dir"], f"{subject_name}{reg['ext']}")

    if eval_type == "mcp_tool":
        # MCP Tool 不需要读取内容，runner 直接传路径给 --mcp-config
        return None, path

    with open(path, "r", encoding="utf-8") as f:
        return f.read(), path


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


def run_case(case: dict, suite: str, dry_run: bool = False) -> dict:
    case_id = case["id"]
    title = case["title"]
    eval_type = case["eval_type"]
    subject_name = case["subject"]
    description = case["input"]["description"]
    input_code = load_file(suite, case["input"]["code_file"])
    reference_code = load_file(suite, case["expected"]["reference_file"])
    rubric = case["expected"]["rubric"]

    # 加载被测对象
    subject_content, subject_path = load_subject(eval_type, subject_name)

    type_labels = {"skill": "Skill", "mcp_tool": "MCP Tool", "system_prompt": "System Prompt"}
    type_label = type_labels.get(eval_type, eval_type)

    # 基线运行
    print(f"  -> 基线运行 (无 {type_label})...", end=" ", flush=True)
    if dry_run:
        baseline_output = "// dry run - no output"
        print("跳过 (dry-run)")
    else:
        t0 = time.time()
        baseline_output = run_baseline(description, input_code)
        print(f"完成 ({time.time() - t0:.0f}s)")

    # 增强运行
    print(f"  -> 增强运行 (挂载 {type_label}: {subject_name})...", end=" ", flush=True)
    if dry_run:
        enhanced_output = reference_code
        print("跳过 (dry-run, 使用参考答案)")
    else:
        t0 = time.time()
        enhanced_output = run_enhanced(
            description, input_code, eval_type,
            subject_content=subject_content,
            subject_path=subject_path,
        )
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
        "eval_type": eval_type,
        "subject": subject_name,
        "baseline_rule": baseline_rule["rule_score"],
        "enhanced_rule": enhanced_rule["rule_score"],
        "baseline_total": baseline_total,
        "enhanced_total": enhanced_total,
        "dimension_scores": dimension_scores,
    }


def main():
    parser = argparse.ArgumentParser(description="Skill 评测系统")
    parser.add_argument("--suite", default="bug_fix",
                        help="测试套件名称（test_cases 下的目录名）")
    parser.add_argument("--eval-type", default=None,
                        choices=["skill", "mcp_tool", "system_prompt"],
                        help="只运行指定评测类型的用例")
    parser.add_argument("--dry-run", action="store_true",
                        help="干跑模式，不调用 Agent")
    args = parser.parse_args()

    suite = args.suite

    print(f"========================================")
    print(f"  Agent Bench 评测系统")
    print(f"  测试套件: {suite}")
    if args.eval_type:
        print(f"  评测类型: {args.eval_type}")
    print(f"  模式: {'dry-run' if args.dry_run else '正式运行'}")
    print(f"========================================")

    cases = load_test_cases(suite, eval_type_filter=args.eval_type)
    print(f"\n加载了 {len(cases)} 个测试用例")

    if not cases:
        print("没有匹配的测试用例，退出")
        return

    results = []
    for i, case in enumerate(cases):
        print(f"\n[{i + 1}/{len(cases)}] {case['id']} - {case['title']} [{case['eval_type']}]")
        result = run_case(case, suite, dry_run=args.dry_run)
        results.append(result)
        gain = result["enhanced_total"] - result["baseline_total"]
        print(f"  -> 结果: 基线={result['baseline_total']}, 增强={result['enhanced_total']}, 增益={'+' if gain >= 0 else ''}{gain}")

    output_dir = os.path.join(BASE_DIR, "report", "output")
    json_path, md_path = generate_report(results, suite, output_dir)

    print(f"\n========================================")
    print(f"  评测完成!")
    print(f"  JSON 报告: {json_path}")
    print(f"  Markdown 报告: {md_path}")
    print(f"========================================")


if __name__ == "__main__":
    main()
