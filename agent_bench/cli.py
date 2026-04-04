#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""单 agent CLI。"""

import argparse
import os
import sys
import threading

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from agent_bench.pipeline.engine import ALL_STAGES, run_pipeline
from agent_bench.runner.discovery import ensure_opencode_server
from agent_bench.runner.opencode_adapter import DEFAULT_API_BASE

_print_lock = threading.Lock()


def cli_progress_callback(event: str, data: dict):
    with _print_lock:
        if event == "pipeline_start":
            print("=" * 50)
            print("  Agent 测试系统")
            print(f"  Run ID:      {data['run_id']}")
            print(f"  API Base:    {data['api_base']}")
            print(f"  Agent Model: {data['agent_model']}")
            print(f"  Scenarios:   {', '.join(data['scenarios'])}")
            print(f"  Stages:      {', '.join(data['stages'])}")
            print(f"  Parallel:    {data['max_workers']} workers")
            print("=" * 50)
        elif event == "scenario_start":
            print(f"\n{'='*50}")
            print(f"  场景: {data['scenario']}")
            print(f"  用例数: {data['case_count']}")
            print(f"{'='*50}")
        elif event == "stage_done":
            case_id = data.get("case_id", "")
            stage = data["stage"]
            if data.get("skipped"):
                print(f"  [{case_id}] {stage}... 跳过")
            else:
                print(f"  [{case_id}] {stage}... 完成 ({data.get('elapsed', 0):.0f}s)")
        elif event == "case_done":
            print(f"\n  [{data['scenario']} {data['index']}/{data['total']}] {data['case_id']} - {data['title']}")
            print(f"  -> 分数: {data.get('score', 'N/A')}")
        elif event == "pipeline_done":
            print("\n" + "=" * 50)
            print("  执行完成")
            print(f"  Run ID:        {data['run_id']}")
            print(f"  总用例数:      {data['total_cases']}")
            if data.get("json_path"):
                print(f"  JSON 报告:     {data['json_path']}")
            if data.get("md_path"):
                print(f"  Markdown 报告: {data['md_path']}")
            print("=" * 50)
        elif event == "log":
            level = data.get("level", "INFO")
            message = data.get("message", "")
            if level == "DEBUG":
                print(f"  [DEBUG] {message}")
            elif level == "WARN":
                print(f"  [WARN]  {message}")
            else:
                print(f"  {message}")
        elif event == "error":
            case_id = data.get("case_id", "")
            prefix = f"[{case_id}] " if case_id else ""
            print(f"\n  [ERROR] {prefix}{data['message']}", file=sys.stderr)


def main():
    parser = argparse.ArgumentParser(description="Agent 测试 CLI")
    parser.add_argument("--profile", required=True, help="Profile 名称")
    parser.add_argument("--cases", default=None, help="测试场景覆盖")
    parser.add_argument("--api-base", default=DEFAULT_API_BASE, help="OpenCode API 服务地址")
    parser.add_argument("--model", default=None, help="使用的模型")
    parser.add_argument("--dry-run", action="store_true", help="干跑模式")
    parser.add_argument("--output-dir", default=None, help="输出目录")
    parser.add_argument("--run-id", default=None, help="运行 ID")
    parser.add_argument("--max-workers", type=int, default=None, help="场景内并行数")
    parser.add_argument("--case-id", default=None, help="只运行指定 ID 的用例")
    parser.add_argument("--stages", default=None, help="阶段: runner,reporter")
    parser.add_argument("--agent-id", default=None, help="执行 Agent ID")
    args = parser.parse_args()

    stages = None
    if args.stages:
        stages = [s.strip() for s in args.stages.split(",")]
        for s in stages:
            if s not in ALL_STAGES:
                parser.error(f"无效的阶段: {s}，可选: {','.join(ALL_STAGES)}")

    api_base = args.api_base
    need_api = stages is None or "runner" in stages
    if need_api and not args.dry_run:
        api_base = ensure_opencode_server()

    result = run_pipeline(
        profile=args.profile,
        cases_override=args.cases,
        api_base=api_base,
        agent_model=args.model,
        max_workers=args.max_workers,
        dry_run=args.dry_run,
        case_id_filter=args.case_id,
        run_id=args.run_id,
        output_dir=args.output_dir,
        stages=stages,
        agent_id=args.agent_id,
        on_progress=cli_progress_callback,
    )

    all_results = result["results"]
    if all_results:
        scores = [r["score"] for r in all_results if isinstance(r.get("score"), (int, float))]
        print("\n总结:")
        print(f"  总用例数: {len(all_results)}")
        print(f"  平均分:   {round(sum(scores) / len(scores), 1) if scores else 'N/A'}")
    else:
        print("\n没有运行任何测试用例")


if __name__ == "__main__":
    main()
