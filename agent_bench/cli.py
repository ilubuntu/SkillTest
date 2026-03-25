#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Skill 评测 CLI - 编排层

职责：
- CLI 参数解析
- 场景解析（resolve_scenarios）
- 并行调度（ThreadPoolExecutor）
- 串联 Runner → Evaluator → Reporter 流程
- 进度打印

不包含任何 HTTP 调用、评分逻辑或报告渲染，
这些由 runner / evaluator / report 模块负责。

用法:
    python cli.py --profile project_gen
    python cli.py --profile project_gen --cases project_gen
    python cli.py --profile all --cases all
    python cli.py --profile project_gen --dry-run
"""

import argparse
import concurrent.futures
import json
import os
import sys
import threading
import time
from datetime import datetime

# 将 agent_bench 的父目录加入 sys.path，使 agent_bench 可作为包导入
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from agent_bench.runner.agent_runner import (
    AgentRunner,
    ensure_opencode_server,
    DEFAULT_API_BASE,
)
from agent_bench.evaluator.rule_checker import check as rule_check
from agent_bench.evaluator.llm_judge import LLMJudge
from agent_bench.report.reporter import generate as generate_report

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
CONFIG_PATH = os.path.join(BASE_DIR, "config.yaml")


def load_config() -> dict:
    """加载全局配置文件"""
    if os.path.exists(CONFIG_PATH):
        return load_yaml(CONFIG_PATH) or {}
    return {}


# 场景 → Skill 文件的映射
PROFILE_MAP = {
    "project_gen": "skills/create-harmony-project.md",
    "compilable": "skills/compilable.md",
    "performance": "skills/performance.md",
    "bug_fix": "skills/bug_fix.md",
}


# ── 工具函数 ─────────────────────────────────────────────────

def load_yaml(file_path: str) -> dict:
    """加载 YAML 文件"""
    import yaml
    with open(file_path, "r", encoding="utf-8") as f:
        return yaml.safe_load(f)


def load_file(relative_path: str) -> str:
    """加载测试用例关联的代码文件"""
    path = os.path.join(BASE_DIR, relative_path)
    with open(path, "r", encoding="utf-8") as f:
        return f.read()


def load_test_cases(scenario: str) -> list:
    """加载指定场景目录下的所有测试用例"""
    cases_dir = os.path.join(BASE_DIR, "test_cases", scenario)
    if not os.path.isdir(cases_dir):
        print(f"[WARN] 场景目录不存在: {cases_dir}")
        return []

    cases = []
    for f in sorted(os.listdir(cases_dir)):
        if f.endswith(".yaml") or f.endswith(".yml"):
            filepath = os.path.join(cases_dir, f)
            case = load_yaml(filepath)
            cases.append(case)
    return cases


def resolve_scenarios(profile_name: str, cases_override: str = None) -> list:
    """解析要运行的场景列表

    优先级：--cases 覆盖 > Profile YAML 的 scenarios 字段 > profile_name 本身
    """
    all_scenarios = list(PROFILE_MAP.keys())

    if cases_override:
        if cases_override == "all":
            return all_scenarios
        return [cases_override]

    if profile_name == "all":
        return all_scenarios

    profile_path = os.path.join(BASE_DIR, "profiles", f"{profile_name}.yaml")
    if os.path.exists(profile_path):
        profile_data = load_yaml(profile_path)
        scenarios = profile_data.get("scenarios", [])
        if scenarios:
            return scenarios

    return [profile_name]


def load_skill_content(scenario: str) -> str:
    """加载场景对应的 Skill 文件内容"""
    skill_rel = PROFILE_MAP.get(scenario)
    if not skill_rel:
        return ""
    skill_path = os.path.join(BASE_DIR, skill_rel)
    if not os.path.isfile(skill_path):
        print(f"[WARN] Skill 文件不存在: {skill_path}")
        return ""
    with open(skill_path, "r", encoding="utf-8") as f:
        return f.read()


def compute_total(rule_score: float, llm_scores: list, rubric: list,
                  rule_weight: float = 0.3, llm_weight: float = 0.7) -> float:
    """综合评分 = 规则分 × 30% + LLM 维度加权分 × 70%"""
    llm_weighted = 0
    total_weight = 0
    for rubric_item in rubric:
        name = rubric_item["name"]
        weight = rubric_item["weight"]
        score = next(
            (s["score"] for s in llm_scores if s["name"] == name), 50
        )
        llm_weighted += score * weight
        total_weight += weight

    llm_avg = llm_weighted / total_weight if total_weight > 0 else 50
    return round(rule_weight * rule_score + llm_weight * llm_avg, 1)


# ── 单用例执行（线程安全） ───────────────────────────────────

def run_single_case(case: dict, scenario: str, skill_content: str,
                    agent_runner: AgentRunner, llm_judge: LLMJudge,
                    dry_run: bool = False) -> dict:
    """执行单个测试用例，返回结果 dict（含 _logs 供打印）"""
    case_id = case["id"]
    title = case["title"]
    prompt = case["input"]["prompt"]
    input_code = load_file(
        os.path.join("test_cases", scenario, case["input"]["code_file"])
    )
    reference_code = load_file(
        os.path.join("test_cases", scenario, case["expected"]["reference_file"])
    )
    rubric = case["expected"]["rubric"]

    logs = []

    # 基线运行
    if dry_run:
        baseline_output = "// dry run - no output"
        logs.append("  -> 基线运行... 跳过 (dry-run)")
    else:
        t0 = time.time()
        baseline_output = agent_runner.run_baseline(prompt, input_code)
        logs.append(f"  -> 基线运行... 完成 ({time.time() - t0:.0f}s)")

    # 增强运行
    if dry_run:
        enhanced_output = reference_code
        logs.append("  -> 增强运行... 跳过 (dry-run, 使用参考答案)")
    else:
        t0 = time.time()
        enhanced_output = agent_runner.run_enhanced(
            prompt, input_code, skill_content
        )
        logs.append(f"  -> 增强运行... 完成 ({time.time() - t0:.0f}s)")

    # 规则评分
    baseline_rule = rule_check(baseline_output, case["expected"])
    enhanced_rule = rule_check(enhanced_output, case["expected"])
    logs.append(
        f"  -> 规则检查... 基线={baseline_rule['rule_score']}, "
        f"增强={enhanced_rule['rule_score']}"
    )

    # LLM 评分（一次调用，同时对比 baseline 和 enhanced）
    if dry_run:
        judge_result = {
            "baseline": [
                {"name": r["name"], "score": 30, "reason": "dry-run"}
                for r in rubric
            ],
            "enhanced": [
                {"name": r["name"], "score": 85, "reason": "dry-run"}
                for r in rubric
            ],
        }
        logs.append("  -> LLM 评分... 跳过 (dry-run)")
    else:
        judge_result = llm_judge.judge(
            input_code, baseline_output, enhanced_output,
            reference_code, rubric
        )
        logs.append("  -> LLM 评分... 完成")

    baseline_llm_scores = judge_result["baseline"]
    enhanced_llm_scores = judge_result["enhanced"]

    # 汇总
    baseline_total = compute_total(
        baseline_rule["rule_score"], baseline_llm_scores, rubric
    )
    enhanced_total = compute_total(
        enhanced_rule["rule_score"], enhanced_llm_scores, rubric
    )

    dimension_scores = {}
    for r_item in rubric:
        name = r_item["name"]
        b_score = next(
            (s["score"] for s in baseline_llm_scores if s["name"] == name),
            50,
        )
        e_score = next(
            (s["score"] for s in enhanced_llm_scores if s["name"] == name),
            50,
        )
        dimension_scores[name] = {"baseline": b_score, "enhanced": e_score}

    gain = enhanced_total - baseline_total
    sign = "+" if gain >= 0 else ""
    logs.append(
        f"  -> 结果: 基线={baseline_total}, "
        f"增强={enhanced_total}, 增益={sign}{gain}"
    )

    return {
        "case_id": case_id,
        "title": title,
        "scenario": case.get("scenario", scenario),
        "baseline_rule": baseline_rule["rule_score"],
        "enhanced_rule": enhanced_rule["rule_score"],
        "baseline_total": baseline_total,
        "enhanced_total": enhanced_total,
        "dimension_scores": dimension_scores,
        # 保留完整产物，持久化时写入独立文件
        "_baseline_output": baseline_output,
        "_enhanced_output": enhanced_output,
        "_judge": judge_result,
        "_baseline_rule_detail": baseline_rule,
        "_enhanced_rule_detail": enhanced_rule,
        "_logs": logs,
    }


# ── 线程安全打印 ─────────────────────────────────────────────

_print_lock = threading.Lock()


def _print_case_result(case_id: str, title: str, index: str, logs: list):
    """线程安全地打印单个用例的完整执行日志"""
    with _print_lock:
        print(f"\n[{index}] {case_id} - {title}")
        for line in logs:
            print(line)


# ── 主入口 ───────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(
        description="Skill 评测系统 - 评测工程生成/可编译/性能优化 Skill",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
示例:
  %(prog)s --profile project_gen
  %(prog)s --profile project_gen --cases project_gen
  %(prog)s --profile all --cases all
  %(prog)s --profile project_gen --dry-run
        """,
    )
    parser.add_argument("--profile", required=True,
                        help="Profile 名称: project_gen, compilable, performance, bug_fix_enhanced, baseline, all")
    parser.add_argument("--cases", default=None,
                        help="测试场景（可选），覆盖 Profile 中的 scenarios 配置。支持 all")
    parser.add_argument("--api-base", default=DEFAULT_API_BASE,
                        help="OpenCode API 服务地址")
    parser.add_argument("--model", default=None,
                        help="使用的模型（默认使用 OpenCode 配置）")
    parser.add_argument("--dry-run", action="store_true",
                        help="干跑模式：跳过 Agent 调用")
    parser.add_argument("--output-dir", default=None,
                        help="输出目录 (默认: results/<run_id>)")
    parser.add_argument("--run-id", default=None,
                        help="运行 ID (默认: 时间戳)")
    parser.add_argument("--max-workers", type=int, default=3,
                        help="场景内用例并行数 (默认: 3)")
    parser.add_argument("--case-id", default=None,
                        help="只运行指定 ID 的用例，如 bug_fix_001")

    args = parser.parse_args()

    # 加载全局配置
    config = load_config()
    agent_conf = config.get("agent", {})
    judge_conf = config.get("judge", {})
    concurrency_conf = config.get("concurrency", {})

    # CLI 参数 > 配置文件 > 默认值
    agent_model = args.model or agent_conf.get("model")
    judge_model = args.model or judge_conf.get("model")
    max_workers = args.max_workers or concurrency_conf.get("agent_runs", 3)

    # 服务发现
    api_base = args.api_base
    if not args.dry_run:
        api_base = ensure_opencode_server()

    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    run_id = args.run_id or f"{timestamp}_{args.profile}"
    output_dir = args.output_dir or os.path.join(BASE_DIR, "results", run_id)

    # 解析场景
    scenarios_to_run = resolve_scenarios(args.profile, args.cases)

    os.makedirs(os.path.join(output_dir, "cases"), exist_ok=True)

    # 初始化 Runner 和 Judge
    agent_runner = AgentRunner(api_base=api_base, model=agent_model)
    llm_judge = LLMJudge(api_base=api_base, model=judge_model)

    all_results = []

    # 打印运行信息
    print("=" * 50)
    print("  Skill 评测系统")
    print(f"  Run ID:   {run_id}")
    print(f"  API Base: {api_base}")
    print(f"  Agent Model: {agent_model or 'OpenCode 默认'}")
    print(f"  Judge Model: {judge_model or 'OpenCode 默认'}")
    print(f"  Scenarios: {', '.join(scenarios_to_run)}")
    print(f"  Parallel: {max_workers} workers")
    print(f"  Mode:     {'dry-run' if args.dry_run else '正式运行'}")
    print("=" * 50)

    # 按场景串行，场景内用例并行
    for scenario in scenarios_to_run:
        skill_content = load_skill_content(scenario)
        cases = load_test_cases(scenario)

        if args.case_id:
            cases = [c for c in cases if c["id"] == args.case_id]

        print(f"\n{'='*50}")
        print(f"  场景: {scenario}")
        print(f"  Skill: {PROFILE_MAP.get(scenario, 'N/A')}")
        print(f"  用例数: {len(cases)}")
        print(f"{'='*50}")

        if not cases:
            print("没有找到测试用例，跳过")
            continue

        # 并行执行
        futures = {}
        with concurrent.futures.ThreadPoolExecutor(
            max_workers=max_workers
        ) as executor:
            for i, case in enumerate(cases):
                future = executor.submit(
                    run_single_case, case, scenario, skill_content,
                    agent_runner, llm_judge,
                    dry_run=args.dry_run,
                )
                futures[future] = (i, case)

            for future in concurrent.futures.as_completed(futures):
                i, case = futures[future]
                try:
                    result = future.result()
                    index = f"{scenario} {i + 1}/{len(cases)}"
                    _print_case_result(
                        result["case_id"], result["title"],
                        index, result.pop("_logs", []),
                    )

                    # 提取产物，写入独立文件
                    baseline_output = result.pop("_baseline_output", "")
                    enhanced_output = result.pop("_enhanced_output", "")
                    judge_result = result.pop("_judge", {})
                    baseline_rule_detail = result.pop("_baseline_rule_detail", {})
                    enhanced_rule_detail = result.pop("_enhanced_rule_detail", {})

                    case_dir = os.path.join(
                        output_dir, "cases", result["case_id"]
                    )
                    os.makedirs(case_dir, exist_ok=True)

                    # Agent 输出
                    with open(os.path.join(case_dir, "baseline_output.txt"), "w",
                              encoding="utf-8") as f:
                        f.write(baseline_output)
                    with open(os.path.join(case_dir, "enhanced_output.txt"), "w",
                              encoding="utf-8") as f:
                        f.write(enhanced_output)

                    # LLM Judge 对比评分（含理由）
                    with open(os.path.join(case_dir, "judge.json"), "w",
                              encoding="utf-8") as f:
                        json.dump(judge_result, f, ensure_ascii=False, indent=2)

                    # 规则检查明细
                    with open(os.path.join(case_dir, "rule_check.json"), "w",
                              encoding="utf-8") as f:
                        json.dump({
                            "baseline": baseline_rule_detail,
                            "enhanced": enhanced_rule_detail,
                        }, f, ensure_ascii=False, indent=2)

                    # 综合评分结果
                    with open(os.path.join(case_dir, "result.json"), "w",
                              encoding="utf-8") as f:
                        json.dump(result, f, ensure_ascii=False, indent=2)

                    all_results.append(result)

                except Exception as e:
                    print(
                        f"\n[ERROR] {case['id']} 执行失败: {e}",
                        file=sys.stderr,
                    )

    # 生成报告
    if all_results:
        scenarios_str = ",".join(scenarios_to_run)
        json_path, md_path = generate_report(
            all_results, scenarios_str, args.profile, output_dir
        )

        print("\n" + "=" * 50)
        print("  评测完成!")
        print(f"  Run ID:        {run_id}")
        print(f"  JSON 报告:     {json_path}")
        print(f"  Markdown 报告: {md_path}")
        print("=" * 50)

        # 汇总
        baseline_avg = round(
            sum(r["baseline_total"] for r in all_results) / len(all_results), 1
        )
        enhanced_avg = round(
            sum(r["enhanced_total"] for r in all_results) / len(all_results), 1
        )
        gain = round(enhanced_avg - baseline_avg, 1)

        print(f"\n总结:")
        print(f"  总用例数: {len(all_results)}")
        print(f"  基线均分: {baseline_avg}")
        print(f"  增强均分: {enhanced_avg}")
        print(f"  增益:     +{gain}")
    else:
        print("\n没有运行任何测试用例")


if __name__ == "__main__":
    main()
