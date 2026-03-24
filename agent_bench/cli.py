#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Agent Bench 评测系统 - CLI 入口

本脚本是整个评测系统的唯一入口，提供 5 个子命令，对应三阶段流水线的不同执行方式。

用法:
    # ── 完整流水线（最常用）──────────────────────────────────────
    # 一次性完成：Agent 运行 → 规则评分 → LLM 评分 → 生成报告
    python cli.py run --profile <profile_name> --cases <scenario>

    # 示例：用 bug_fix_enhanced 配置跑 bug_fix 场景的所有用例
    python cli.py run --profile bug_fix_enhanced --cases bug_fix

    # 干跑模式：不调用 Agent 和 LLM，用模拟数据走完流程，用于验证流水线配置
    python cli.py run --profile bug_fix_enhanced --cases bug_fix --dry-run

    # 指定 run-id（默认自动按时间戳生成，如 20260324_153000）
    python cli.py run --profile bug_fix_enhanced --cases bug_fix --run-id my_test_001

    # ── 分阶段运行（用于断点续跑 / 单独重跑某阶段）────────────────
    # 仅运行 Agent，不评分不出报告（⚠️ 当前为空实现）
    python cli.py run-agents --profile <profile_name> --cases <scenario>

    # 仅对已有结果评分（需先通过 run 或 run-agents 生成结果）（⚠️ 当前为空实现）
    python cli.py evaluate --run-id <run_id>

    # 仅生成报告（需先有评分结果）
    python cli.py report --run-id <run_id>

    # ── 基线管理 ────────────────────────────────────────────────
    # 单独跑基线并缓存（⚠️ 当前为空实现）
    python cli.py baseline --cases <scenario>

参数说明:
    --profile   Profile 名称，对应 profiles/<name>.yaml 文件
                Profile 定义了 Agent 的增强配置（Skill、MCP Tool、System Prompt）
    --cases     测试场景名称，对应 test_cases/<scenario>/ 目录
                如 bug_fix、requirement、refactor 等
    --run-id    运行 ID，用于标识和定位本次运行的所有结果
                默认按时间戳自动生成（格式：YYYYMMDD_HHMMSS）
    --dry-run   干跑模式，跳过 Agent 调用和 LLM 评分，使用模拟数据
                适用于调试流水线、验证配置、检查报告格式

依赖: pip install pyyaml
"""

import argparse
import json
import os
import sys
import time
from datetime import datetime

import yaml

# 将当前脚本所在目录加入模块搜索路径，确保子模块可正常导入
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

# 三阶段流水线的核心模块：
# - runner:    阶段1，驱动 Agent 执行用例（创建沙箱、调用 opencode run）
# - evaluator: 阶段2，对 Agent 输出评分（规则匹配 + LLM-as-Judge）
# - report:    阶段3，汇总评分结果生成增益报告
from runner.agent_runner import create_sandbox, run_agent, run_baseline, run_enhanced
from evaluator.rule_checker import check as rule_check
from evaluator.llm_judge import judge as llm_judge
from report.reporter import generate as generate_report

# 项目根目录，所有相对路径（profiles/、test_cases/、results/）均基于此目录解析
BASE_DIR = os.path.dirname(os.path.abspath(__file__))


def load_config() -> dict:
    """加载全局配置 config.yaml

    全局配置包含：
    - concurrency: 并发控制（agent_runs、llm_judge 并发数）
    - scoring: 评分权重（rule_weight、llm_weight）
    - judge: LLM Judge 模型配置（provider、model、temperature）
    """
    config_path = os.path.join(BASE_DIR, "config.yaml")
    with open(config_path, "r", encoding="utf-8") as f:
        return yaml.safe_load(f)


def load_profile(profile_name: str) -> dict:
    """加载 Agent 配置 Profile

    Profile 文件位于 profiles/<profile_name>.yaml，定义了：
    - name: Profile 名称
    - description: 描述
    - scenarios: 归属场景列表（决定跑哪些场景用例）
    - enhancements: 增强配置（skills、mcp_servers、system_prompt）
    - agent: Agent 运行参数（model、timeout）
    """
    profile_path = os.path.join(BASE_DIR, "profiles", f"{profile_name}.yaml")
    if not os.path.exists(profile_path):
        print(f"[ERROR] Profile not found: {profile_path}", file=sys.stderr)
        sys.exit(1)
    with open(profile_path, "r", encoding="utf-8") as f:
        return yaml.safe_load(f)


def load_test_cases(scenario: str) -> list:
    """加载指定场景目录下的所有测试用例

    扫描 test_cases/<scenario>/ 目录下的 .yaml/.yml 文件，按文件名排序加载。
    注意：只扫描一级目录，不递归子目录。用例的关联代码文件通过 code_file 字段引用。
    """
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
    """加载测试用例关联的代码文件

    Args:
        scenario: 场景名称（如 bug_fix），对应 test_cases/ 下的子目录
        relative_path: 用例 YAML 中 code_file / reference_file 指定的相对路径
                       如 cases/bug_fix_001/input.ets
    """
    path = os.path.join(BASE_DIR, "test_cases", scenario, relative_path)
    with open(path, "r", encoding="utf-8") as f:
        return f.read()


def generate_run_id() -> str:
    """生成基于时间戳的 run_id，格式：YYYYMMDD_HHMMSS（如 20260324_153000）"""
    return datetime.now().strftime("%Y%m%d_%H%M%S")


def compute_total(rule_score: float, llm_scores: list, rubric: list,
                  rule_weight: float, llm_weight: float) -> float:
    """综合评分 = 规则分 × rule_weight + LLM加权均分 × llm_weight

    计算过程：
    1. LLM 分数按 rubric 中各维度的 weight 加权平均（如 correctness:40, completeness:30, code_quality:30）
    2. 规则分（0-100）和 LLM 均分（0-100）再按 rule_weight / llm_weight 混合

    ⚠️ 已知问题：如果 LLM Judge 漏返回某个维度的分数，默认给 50 分且无警告，
    可能静默掩盖评分异常。后续应加日志告警。
    """
    llm_weighted = 0
    total_weight = 0
    for rubric_item in rubric:
        name = rubric_item["name"]
        weight = rubric_item["weight"]
        # TODO: 当 LLM 未返回某维度分数时，应记录警告而非静默使用默认值 50
        score = next((s["score"] for s in llm_scores if s["name"] == name), 50)
        llm_weighted += score * weight
        total_weight += weight

    llm_avg = llm_weighted / total_weight if total_weight > 0 else 50
    return round(rule_weight * rule_score + llm_weight * llm_avg, 1)


def run_single_case(case: dict, scenario: str, profile: dict, config: dict,
                    run_id: str, dry_run: bool = False) -> dict:
    """执行单个测试用例的完整流程

    流程：
    1. 创建沙箱目录（sandbox/{run_id}/{case_id}/）
    2. 基线运行：裸 Agent 执行用例，获取基线输出
    3. 增强运行：加载 Profile 增强配置后执行同一用例
    4. 规则评分：对基线和增强输出分别做 must_contain / must_not_contain 检查
    5. LLM 评分：调用独立 Judge 模型按 rubric 维度打分
    6. 汇总：计算综合分数和各维度对比

    ⚠️ 当前实现中基线和增强是串行执行的，且没有使用基线缓存机制，
    每次评测都会重跑基线，后续应接入 baselines/ 缓存。
    """
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
    """将运行结果持久化到 results/{run_id}/results.json

    持久化数据包含本次运行的元信息和所有用例的评分结果，
    供后续 evaluate / report 子命令读取使用，实现断点续跑。
    """
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
    """从 results/{run_id}/results.json 加载已有的运行结果，供 evaluate / report 子命令使用"""
    results_path = os.path.join(BASE_DIR, "results", run_id, "results.json")
    if not os.path.exists(results_path):
        print(f"[ERROR] Results not found: {results_path}", file=sys.stderr)
        sys.exit(1)
    with open(results_path, "r", encoding="utf-8") as f:
        return json.load(f)


# ── 子命令实现 ──────────────────────────────────────────────
# 每个 cmd_* 函数对应一个 CLI 子命令，通过 argparse 的 set_defaults(func=...) 分发调用


def cmd_run(args):
    """完整流水线：Runner → Evaluator → Reporter 一次跑完

    这是最常用的命令，串行执行所有用例的完整评测流程。
    结果持久化到 results/{run_id}/，同时生成 JSON + Markdown 报告。
    """
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
    """仅运行 Agent 阶段（阶段1），不评分、不生成报告

    用途：当只需要重新采集 Agent 输出时（如更换了 Profile 配置），
    可以单独跑此阶段，然后用 evaluate + report 补全后续阶段。

    ⚠️ 当前为空实现，需要：
    - 独立持久化 Agent 输出（agent_output.ets + agent_log.json）
    - 支持并发控制（config.yaml 中的 concurrency.agent_runs）
    - 支持断点续跑（跳过已有输出的用例）
    """
    config = load_config()
    profile = load_profile(args.profile)
    cases = load_test_cases(args.cases)
    run_id = args.run_id or generate_run_id()

    print(f"[run-agents] Run ID: {run_id}, Profile: {profile.get('name')}, "
          f"Scenario: {args.cases}, Cases: {len(cases)}")
    print("[run-agents] Agent 运行尚未实现独立持久化，请使用 `run` 子命令")
    # TODO: 实现独立的 Agent 运行 + 结果持久化


def cmd_evaluate(args):
    """仅运行评分阶段（阶段2），基于已有的 Agent 输出进行评分

    用途：当调整了评分规则（rubric）或更换了 Judge 模型时，
    可以单独重跑评分，无需重新调用 Agent。

    ⚠️ 当前为空实现，需要：
    - 从 results/{run_id}/cases/ 读取 Agent 输出
    - 重新执行规则评分 + LLM 评分
    - 覆盖写入评分结果
    """
    run_id = args.run_id
    data = load_results(run_id)
    print(f"[evaluate] 加载了 run {run_id} 的 {len(data['cases'])} 条结果")
    print("[evaluate] 独立评分尚未实现，请使用 `run` 子命令")
    # TODO: 实现基于持久化结果的独立评分


def cmd_report(args):
    """仅运行报告阶段（阶段3），基于已有的评分结果生成增益报告

    这是唯一已完整实现的独立阶段命令。
    读取 results/{run_id}/results.json，输出 JSON + Markdown 报告。
    """
    run_id = args.run_id
    data = load_results(run_id)

    output_dir = os.path.join(BASE_DIR, "results", run_id)
    profile_name = data.get("profile", "unknown")
    scenario = data.get("scenario", "unknown")

    json_path, md_path = generate_report(data["cases"], scenario, profile_name, output_dir)
    print(f"[report] JSON: {json_path}")
    print(f"[report] Markdown: {md_path}")


def cmd_baseline(args):
    """单独运行基线并缓存结果

    用途：预跑基线结果到 baselines/ 目录，后续评测直接读取缓存，
    避免每次评测都重跑基线（时间减半）。

    基线缓存失效条件：Agent 版本或模型版本变更时需重跑。

    ⚠️ 当前为空实现，需要：
    - 用裸 Agent（无增强配置）跑所有用例
    - 结果写入 baselines/{baseline_id}/cases/{case_id}/
    - 记录 meta.json（agent_version、model_version、timestamp）
    - cmd_run 中检查缓存有效性，有效则跳过基线运行
    """
    config = load_config()
    cases = load_test_cases(args.cases)
    run_id = args.run_id or generate_run_id()

    print(f"[baseline] Run ID: {run_id}, Scenario: {args.cases}, Cases: {len(cases)}")
    print("[baseline] 独立基线运行尚未实现，请使用 `run --profile baseline` 代替")
    # TODO: 实现独立的基线运行


# ── CLI 定义 ────────────────────────────────────────────────
# 使用 argparse 的子命令模式，每个子命令对应一个 cmd_* 函数。
# 子命令设计遵循"阶段解耦"原则：可以单独运行某个阶段，也可以一次跑完。


def main():
    parser = argparse.ArgumentParser(
        description="Agent Bench - Agent 能力评测系统",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
示例:
  %(prog)s run --profile bug_fix_enhanced --cases bug_fix          # 完整评测
  %(prog)s run --profile bug_fix_enhanced --cases bug_fix --dry-run # 干跑验证
  %(prog)s report --run-id 20260324_153000                          # 重新生成报告
  %(prog)s baseline --cases bug_fix                                 # 预跑基线缓存
        """,
    )
    subparsers = parser.add_subparsers(dest="command", help="子命令")

    # ── run: 完整流水线（Runner → Evaluator → Reporter）
    p_run = subparsers.add_parser("run", help="完整流水线: 运行 Agent → 评分 → 报告")
    p_run.add_argument("--profile", required=True,
                       help="Profile 名称，对应 profiles/<name>.yaml（如 bug_fix_enhanced）")
    p_run.add_argument("--cases", required=True,
                       help="测试场景名称，对应 test_cases/<scenario>/ 目录（如 bug_fix）")
    p_run.add_argument("--run-id", default=None,
                       help="运行 ID，用于标识本次运行（默认按时间戳自动生成）")
    p_run.add_argument("--dry-run", action="store_true",
                       help="干跑模式：跳过 Agent 调用和 LLM 评分，用模拟数据验证流水线")
    p_run.set_defaults(func=cmd_run)

    # ── run-agents: 仅运行 Agent（阶段1）
    p_agents = subparsers.add_parser("run-agents",
                                     help="仅运行 Agent，不评分不出报告（⚠️ 未完整实现）")
    p_agents.add_argument("--profile", required=True, help="Profile 名称")
    p_agents.add_argument("--cases", required=True, help="测试场景名称")
    p_agents.add_argument("--run-id", default=None, help="运行 ID")
    p_agents.add_argument("--dry-run", action="store_true", help="干跑模式")
    p_agents.set_defaults(func=cmd_run_agents)

    # ── evaluate: 仅评分（阶段2）
    p_eval = subparsers.add_parser("evaluate",
                                   help="仅对已有结果评分（⚠️ 未完整实现）")
    p_eval.add_argument("--run-id", required=True,
                        help="运行 ID，需已有 results/<run_id>/results.json")
    p_eval.set_defaults(func=cmd_evaluate)

    # ── report: 仅生成报告（阶段3）
    p_report = subparsers.add_parser("report",
                                     help="仅生成报告（需已有评分结果）")
    p_report.add_argument("--run-id", required=True,
                          help="运行 ID，需已有 results/<run_id>/results.json")
    p_report.set_defaults(func=cmd_report)

    # ── baseline: 预跑基线并缓存
    p_base = subparsers.add_parser("baseline",
                                   help="预跑基线结果到缓存（⚠️ 未完整实现）")
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
