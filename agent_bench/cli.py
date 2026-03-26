#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Skill 评测 CLI — 命令行入口（薄壳）

职责：
- CLI 参数解析
- OpenCode 服务发现
- 调用 pipeline.run_pipeline()
- 通过 print 回调展示进度

不包含任何评测业务逻辑，所有编排由 pipeline/engine.py 负责。

用法:
    python cli.py --profile project_gen
    python cli.py --profile all --cases all
    python cli.py --profile project_gen --dry-run
    python cli.py --profile project_gen --skip-baseline
    python cli.py --run-id 20260326_xxx --stages evaluator,reporter
    python cli.py --run-id 20260326_xxx --stages reporter
"""

import argparse
import os
import sys
import threading

# 将 agent_bench 的父目录加入 sys.path，使 agent_bench 可作为包导入
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from agent_bench.runner.agent_runner import (
    ensure_opencode_server,
    DEFAULT_API_BASE,
)
from agent_bench.pipeline.engine import run_pipeline, ALL_STAGES


# ── 进度回调（print） ────────────────────────────────────────

_print_lock = threading.Lock()


def cli_progress_callback(event: str, data: dict):
    """将 pipeline 事件格式化为终端输出"""
    with _print_lock:
        if event == "pipeline_start":
            print("=" * 50)
            print("  Skill 评测系统")
            print(f"  Run ID:      {data['run_id']}")
            print(f"  API Base:    {data['api_base']}")
            print(f"  Agent Model: {data['agent_model']}")
            print(f"  Judge Model: {data['judge_model']}")
            print(f"  Scenarios:   {', '.join(data['scenarios'])}")
            print(f"  Stages:      {', '.join(data['stages'])}")
            print(f"  Parallel:    {data['max_workers']} workers")
            print("=" * 50)

        elif event == "scenario_start":
            print(f"\n{'='*50}")
            print(f"  场景: {data['scenario']}")
            print(f"  Skill: {data['skill_file']}")
            print(f"  用例数: {data['case_count']}")
            print(f"{'='*50}")
            if data["case_count"] == 0:
                print("没有找到测试用例，跳过")

        elif event == "stage_done":
            stage = data["stage"]
            case_id = data.get("case_id", "")
            if data.get("skipped"):
                print(f"  [{case_id}] {stage}... 跳过")
            else:
                elapsed = data.get("elapsed", 0)
                msg = f"  [{case_id}] {stage}... 完成 ({elapsed:.0f}s)"
                if "baseline_rule" in data:
                    msg = (f"  [{case_id}] {stage}... "
                           f"基线={data['baseline_rule']}, 增强={data['enhanced_rule']}")
                print(msg)

        elif event == "case_done":
            gain = data["gain"]
            sign = "+" if gain >= 0 else ""
            print(f"\n  [{data['scenario']} {data['index']}/{data['total']}] "
                  f"{data['case_id']} - {data['title']}")
            print(f"  -> 结果: 基线={data['baseline_total']}, "
                  f"增强={data['enhanced_total']}, 增益={sign}{gain:.1f}")

        elif event == "pipeline_done":
            print("\n" + "=" * 50)
            print("  评测完成!")
            print(f"  Run ID:        {data['run_id']}")
            print(f"  总用例数:      {data['total_cases']}")
            if data.get("json_path"):
                print(f"  JSON 报告:     {data['json_path']}")
            if data.get("md_path"):
                print(f"  Markdown 报告: {data['md_path']}")
            print("=" * 50)

        elif event == "error":
            case_id = data.get("case_id", "")
            prefix = f"[{case_id}] " if case_id else ""
            print(f"\n  [ERROR] {prefix}{data['message']}", file=sys.stderr)


# ── 主入口 ───────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(
        description="Skill 评测系统 - 评测工程生成/可编译/性能优化 Skill",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
示例:
  %(prog)s --profile project_gen
  %(prog)s --profile all --cases all
  %(prog)s --profile project_gen --dry-run
  %(prog)s --profile project_gen --skip-baseline
  %(prog)s --run-id 20260326_xxx --stages evaluator,reporter
  %(prog)s --run-id 20260326_xxx --stages runner --case-id bug_fix_001
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
    parser.add_argument("--skip-baseline", action="store_true",
                        help="跳过基线运行，只跑增强配置")
    parser.add_argument("--output-dir", default=None,
                        help="输出目录 (默认: results/<run_id>)")
    parser.add_argument("--run-id", default=None,
                        help="运行 ID (默认: 时间戳。重跑时指定已有 run_id)")
    parser.add_argument("--max-workers", type=int, default=None,
                        help="场景内用例并行数 (默认: 从 config.yaml 读取)")
    parser.add_argument("--case-id", default=None,
                        help="只运行指定 ID 的用例，如 bug_fix_001")
    parser.add_argument("--stages", default=None,
                        help="要执行的阶段（逗号分隔）: runner,evaluator,reporter。默认全部")

    args = parser.parse_args()

    # 解析 stages
    stages = None
    if args.stages:
        stages = [s.strip() for s in args.stages.split(",")]
        for s in stages:
            if s not in ALL_STAGES:
                parser.error(f"无效的阶段: {s}，可选: {','.join(ALL_STAGES)}")

    # 服务发现（仅在需要 runner 或 evaluator 且非 dry-run 时）
    api_base = args.api_base
    need_api = stages is None or "runner" in stages or "evaluator" in stages
    if need_api and not args.dry_run:
        api_base = ensure_opencode_server()

    result = run_pipeline(
        profile=args.profile,
        cases_override=args.cases,
        api_base=api_base,
        agent_model=args.model,
        judge_model=args.model,
        max_workers=args.max_workers,
        dry_run=args.dry_run,
        skip_baseline=args.skip_baseline,
        case_id_filter=args.case_id,
        run_id=args.run_id,
        output_dir=args.output_dir,
        stages=stages,
        on_progress=cli_progress_callback,
    )

    # 打印汇总
    all_results = result["results"]
    if all_results:
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
