#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Agent Bench 评测系统 - CLI 入口

用法:
    python cli.py run --profile <name> --cases <scenario>       # 完整流水线
    python cli.py run-agents --profile <name> --cases <scenario> # 仅运行 Agent
    python cli.py evaluate --run-id <id>                        # 仅评分
    python cli.py report --run-id <id>                          # 仅生成报告
    python cli.py baseline --cases <scenario>                   # 仅运行基线

依赖: pip install pyyaml
"""

import argparse
import json
import os
import sys
import time
from datetime import datetime

import yaml

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from runner.agent_runner import create_sandbox, run_agent, run_baseline, run_enhanced
from evaluator.rule_checker import check as rule_check
from evaluator.llm_judge import judge as llm_judge
from report.reporter import generate as generate_report

BASE_DIR = os.path.dirname(os.path.abspath(__file__))


def load_config() -> dict:
    """加载全局配置 config.yaml"""
    config_path = os.path.join(BASE_DIR, "config.yaml")
    with open(config_path, "r", encoding="utf-8") as f:
        return yaml.safe_load(f)


def load_profile(profile_name: str) -> dict:
    """加载 Agent 配置 profile"""
    profile_path = os.path.join(BASE_DIR, "profiles", f"{profile_name}.yaml")
    if not os.path.exists(profile_path):
        print(f"[ERROR] Profile not found: {profile_path}", file=sys.stderr)
        sys.exit(1)
    with open(profile_path, "r", encoding="utf-8") as f:
        return yaml.safe_load(f)


def load_test_cases(scenario: str) -> list:
    """加载指定场景的所有测试用例（YAML 格式）"""
    cases_dir = os.path.join(BASE_DIR, "test_cases", scenario)
    if not os.path.isdir(cases_dir):
        print(f"[ERROR] Test case directory not found: {cases_dir}", file=sys.stderr)
        sys.exit(1)

    cases = []
    for f in sorted(os.listdir(cases_dir)):
        if f.endswith(".yaml") or f.endswith(".yml"):
            filepath = os.path.join(cases_dir, f)
            with open(filepath, "r", encoding="utf-8") as fh:
                case = yaml.safe_load(fh)
                cases.append(case)
    return cases


def load_file(scenario: str, relative_path: str) -> str:
    """加载测试用例关联的文件（如 .ets 代码文件）"""
    path = os.path.join(BASE_DIR, "test_cases", scenario, relative_path)
    with open(path, "r", encoding="utf-8") as f:
        return f.read()


def generate_run_id() -> str:
    """生成基于时间戳的 run_id"""
    return datetime.now().strftime("%Y%m%d_%H%M%S")


def compute_total(rule_score: float, llm_scores: list, rubric: list,
                  rule_weight: float, llm_weight: float) -> float:
    """综合评分：规则分 * rule_weight + LLM分 * llm_weight"""
    llm_weighted = 0
    total_weight = 0
    for rubric_item in rubric:
        name = rubric_item["name"]
        weight = rubric_item["weight"]
        score = next((s["score"] for s in llm_scores if s["name"] == name), 50)
        llm_weighted += score * weight
        total_weight += weight

    llm_avg = llm_weighted / total_weight if total_weight > 0 else 50
    return round(rule_weight * rule_score + llm_weight * llm_avg, 1)


def run_single_case(case: dict, scenario: str, profile: dict, config: dict,
                    run_id: str, dry_run: bool = False) -> dict:
    """执行单个测试用例的完整流程：Agent运行 -> 规则检查 -> LLM评分"""
    case_id = case["id"]
    title = case["title"]
    prompt = case["input"]["prompt"]
    input_code = load_file(scenario, case["input"]["code_file"])
    reference_code = load_file(scenario, case["expected"]["reference_file"])
    rubric = case["expected"]["rubric"]

    scoring = config.get("scoring", {})
    rule_weight = scoring.get("rule_weight", 0.3)
    llm_weight = scoring.get("llm_weight", 0.7)

    # 创建 sandbox 目录
    sandbox_dir = create_sandbox(run_id, case_id, profile)

    # 基线运行
    print(f"  -> 基线运行...", end=" ", flush=True)
    if dry_run:
        baseline_output = "// dry run - no output"
        print("跳过 (dry-run)")
    else:
        t0 = time.time()
        baseline_output = run_baseline(prompt, input_code)
        print(f"完成 ({time.time() - t0:.0f}s)")

    # 增强运行
    profile_name = profile.get("name", "unknown")
    print(f"  -> 增强运行 (profile: {profile_name})...", end=" ", flush=True)
    if dry_run:
        enhanced_output = reference_code
        print("跳过 (dry-run, 使用参考答案)")
    else:
        t0 = time.time()
        enhanced_output = run_enhanced(prompt, input_code, profile, sandbox_dir)
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
    baseline_total = compute_total(baseline_rule["rule_score"], baseline_llm["scores"],
                                   rubric, rule_weight, llm_weight)
    enhanced_total = compute_total(enhanced_rule["rule_score"], enhanced_llm["scores"],
                                   rubric, rule_weight, llm_weight)

    dimension_scores = {}
    for r_item in rubric:
        name = r_item["name"]
        b_score = next((s["score"] for s in baseline_llm["scores"] if s["name"] == name), 50)
        e_score = next((s["score"] for s in enhanced_llm["scores"] if s["name"] == name), 50)
        dimension_scores[name] = {"baseline": b_score, "enhanced": e_score}

    return {
        "case_id": case_id,
        "title": title,
        "scenario": case.get("scenario", scenario),
        "category": case.get("category", "specialized"),
        "baseline_rule": baseline_rule["rule_score"],
        "enhanced_rule": enhanced_rule["rule_score"],
        "baseline_total": baseline_total,
        "enhanced_total": enhanced_total,
        "dimension_scores": dimension_scores,
    }


def persist_results(results: list, run_id: str, scenario: str, profile_name: str):
    """将运行结果持久化到 results/{run_id}/"""
    results_dir = os.path.join(BASE_DIR, "results", run_id)
    os.makedirs(results_dir, exist_ok=True)

    data = {
        "run_id": run_id,
        "timestamp": datetime.now().isoformat(),
        "scenario": scenario,
        "profile": profile_name,
        "cases": results,
    }

    results_path = os.path.join(results_dir, "results.json")
    with open(results_path, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

    return results_path


def load_results(run_id: str) -> dict:
    """从 results/{run_id}/ 加载已有结果"""
    results_path = os.path.join(BASE_DIR, "results", run_id, "results.json")
    if not os.path.exists(results_path):
        print(f"[ERROR] Results not found: {results_path}", file=sys.stderr)
        sys.exit(1)
    with open(results_path, "r", encoding="utf-8") as f:
        return json.load(f)


# ── 子命令实现 ──────────────────────────────────────────────


def cmd_run(args):
    """完整流水线：运行 Agent -> 评分 -> 生成报告"""
    config = load_config()
    profile = load_profile(args.profile)
    cases = load_test_cases(args.cases)
    run_id = args.run_id or generate_run_id()

    profile_name = profile.get("name", args.profile)
    scenario = args.cases

    print("=" * 50)
    print("  Agent Bench 评测系统")
    print(f"  Run ID:   {run_id}")
    print(f"  Profile:  {profile_name}")
    print(f"  Scenario: {scenario}")
    print(f"  Mode:     {'dry-run' if args.dry_run else '正式运行'}")
    print("=" * 50)
    print(f"\n加载了 {len(cases)} 个测试用例")

    if not cases:
        print("没有匹配的测试用例，退出")
        return

    results = []
    for i, case in enumerate(cases):
        print(f"\n[{i + 1}/{len(cases)}] {case['id']} - {case['title']}")
        result = run_single_case(case, scenario, profile, config, run_id,
                                 dry_run=args.dry_run)
        results.append(result)
        gain = result["enhanced_total"] - result["baseline_total"]
        sign = "+" if gain >= 0 else ""
        print(f"  -> 结果: 基线={result['baseline_total']}, "
              f"增强={result['enhanced_total']}, 增益={sign}{gain}")

    # 持久化结果
    results_path = persist_results(results, run_id, scenario, profile_name)
    print(f"\n结果已保存: {results_path}")

    # 生成报告
    output_dir = os.path.join(BASE_DIR, "results", run_id)
    json_path, md_path = generate_report(results, scenario, profile_name, output_dir)

    print("\n" + "=" * 50)
    print("  评测完成!")
    print(f"  JSON 报告: {json_path}")
    print(f"  Markdown 报告: {md_path}")
    print("=" * 50)


def cmd_run_agents(args):
    """仅运行 Agent（不评分、不生成报告）"""
    config = load_config()
    profile = load_profile(args.profile)
    cases = load_test_cases(args.cases)
    run_id = args.run_id or generate_run_id()

    print(f"[run-agents] Run ID: {run_id}, Profile: {profile.get('name')}, "
          f"Scenario: {args.cases}, Cases: {len(cases)}")
    print("[run-agents] Agent 运行尚未实现独立持久化，请使用 `run` 子命令")
    # TODO: 实现独立的 Agent 运行 + 结果持久化


def cmd_evaluate(args):
    """仅评分（基于已有的运行结果）"""
    run_id = args.run_id
    data = load_results(run_id)
    print(f"[evaluate] 加载了 run {run_id} 的 {len(data['cases'])} 条结果")
    print("[evaluate] 独立评分尚未实现，请使用 `run` 子命令")
    # TODO: 实现基于持久化结果的独立评分


def cmd_report(args):
    """仅生成报告（基于已有的运行结果）"""
    run_id = args.run_id
    data = load_results(run_id)

    output_dir = os.path.join(BASE_DIR, "results", run_id)
    profile_name = data.get("profile", "unknown")
    scenario = data.get("scenario", "unknown")

    json_path, md_path = generate_report(data["cases"], scenario, profile_name, output_dir)
    print(f"[report] JSON: {json_path}")
    print(f"[report] Markdown: {md_path}")


def cmd_baseline(args):
    """仅运行基线"""
    config = load_config()
    cases = load_test_cases(args.cases)
    run_id = args.run_id or generate_run_id()

    print(f"[baseline] Run ID: {run_id}, Scenario: {args.cases}, Cases: {len(cases)}")
    print("[baseline] 独立基线运行尚未实现，请使用 `run --profile baseline` 代替")
    # TODO: 实现独立的基线运行


# ── CLI 定义 ────────────────────────────────────────────────


def main():
    parser = argparse.ArgumentParser(
        description="Agent Bench - Agent 能力评测系统",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    subparsers = parser.add_subparsers(dest="command", help="子命令")

    # run: 完整流水线
    p_run = subparsers.add_parser("run", help="完整流水线: 运行 Agent -> 评分 -> 报告")
    p_run.add_argument("--profile", required=True, help="Agent profile 名称")
    p_run.add_argument("--cases", required=True, help="测试场景名称 (test_cases/ 下的目录)")
    p_run.add_argument("--run-id", default=None, help="运行 ID (默认自动生成)")
    p_run.add_argument("--dry-run", action="store_true", help="干跑模式，不调用 Agent")
    p_run.set_defaults(func=cmd_run)

    # run-agents: 仅运行 Agent
    p_agents = subparsers.add_parser("run-agents", help="仅运行 Agent")
    p_agents.add_argument("--profile", required=True, help="Agent profile 名称")
    p_agents.add_argument("--cases", required=True, help="测试场景名称")
    p_agents.add_argument("--run-id", default=None, help="运行 ID")
    p_agents.add_argument("--dry-run", action="store_true", help="干跑模式")
    p_agents.set_defaults(func=cmd_run_agents)

    # evaluate: 仅评分
    p_eval = subparsers.add_parser("evaluate", help="仅评分（需先运行 Agent）")
    p_eval.add_argument("--run-id", required=True, help="运行 ID")
    p_eval.set_defaults(func=cmd_evaluate)

    # report: 仅生成报告
    p_report = subparsers.add_parser("report", help="仅生成报告（需先运行评分）")
    p_report.add_argument("--run-id", required=True, help="运行 ID")
    p_report.set_defaults(func=cmd_report)

    # baseline: 仅运行基线
    p_base = subparsers.add_parser("baseline", help="仅运行基线 Agent")
    p_base.add_argument("--cases", required=True, help="测试场景名称")
    p_base.add_argument("--run-id", default=None, help="运行 ID")
    p_base.add_argument("--dry-run", action="store_true", help="干跑模式")
    p_base.set_defaults(func=cmd_baseline)

    args = parser.parse_args()

    if not args.command:
        parser.print_help()
        sys.exit(1)

    args.func(args)


if __name__ == "__main__":
    main()
