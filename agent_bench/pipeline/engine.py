# -*- coding: utf-8 -*-
"""Pipeline Engine — 评测流水线顶层编排

职责：
- 编排 Runner → Evaluator → Reporter 三阶段流水线
- 解析配置，初始化组件，串联场景执行
- 通过 on_progress 回调向调用方推送进度
- CLI 和 Web UI 共享此模块，不直接依赖任何 IO 方式

不做的事：不包含 CLI 参数解析、服务发现、打印逻辑、
         具体的用例执行逻辑、产物管理、评分计算。
"""

import os
from datetime import datetime
from typing import Callable

from agent_bench.runner.opencode_adapter import OpenCodeAdapter, DEFAULT_API_BASE
from agent_bench.evaluator.llm_judge import LLMJudge
from agent_bench.report.reporter import generate as generate_report

from agent_bench.pipeline.loader import (
    load_config, load_test_cases, resolve_scenarios, load_agent, load_agent_defaults,
)
from agent_bench.pipeline.artifacts import load_evaluator_result
from agent_bench.pipeline.case_runner import run_scenario

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

ALL_STAGES = ["runner", "evaluator", "reporter"]


def _notify(on_progress, event: str, data: dict):
    """安全地调用回调"""
    if on_progress:
        on_progress(event, data)


def _normalize_side_labels(labels: dict = None) -> dict:
    labels = labels or {}
    return {
        "side_a": labels.get("side_a") or labels.get("baseline") or "基线Agent",
        "side_b": labels.get("side_b") or labels.get("enhanced") or "评测Agent",
    }


def _normalize_active_sides(active_sides: list = None) -> list:
    active_sides = active_sides or ["side_a", "side_b"]
    normalized = []
    for side in active_sides:
        if side in ("baseline", "side_a"):
            normalized.append("side_a")
        elif side in ("enhanced", "side_b"):
            normalized.append("side_b")
    return normalized or ["side_a", "side_b"]


def run_pipeline(profile: str,
                 cases_override: str = None,
                 api_base: str = DEFAULT_API_BASE,
                 agent_model: str = None,
                 judge_model: str = None,
                 max_workers: int = None,
                 dry_run: bool = False,
                 skip_baseline: bool = False,
                 only_run_baseline: bool = False,
                 case_id_filter: str = None,
                 case_ids: list = None,
                 baseline_agent_id: str = None,
                 enhanced_agent_id: str = None,
                 comparison_labels: dict = None,
                 active_sides: list = None,
                 run_id: str = None,
                 output_dir: str = None,
                 stages: list = None,
                 on_progress: Callable = None) -> dict:
    """评测流水线顶层入口

    Args:
        profile: Profile 名称
        cases_override: 场景覆盖（逗号分隔或 "all"）
        api_base: Agent API 地址
        agent_model: Agent 模型
        judge_model: Judge 模型
        max_workers: 并行数
        dry_run: 干跑模式
        skip_baseline: 跳过基线
        case_id_filter: 只跑指定用例
        case_ids: 只跑指定用例列表
        baseline_agent_id: A 侧 Agent ID
        enhanced_agent_id: B 侧 Agent ID
        comparison_labels: 两侧展示标签
        run_id: 运行 ID（重跑时指定已有的）
        output_dir: 输出目录
        stages: 要执行的阶段 ["runner", "evaluator", "reporter"]
        on_progress: 进度回调 (event: str, data: dict) -> None

    Returns:
        {
            "run_id": str,
            "output_dir": str,
            "results": list,
            "json_path": str | None,
            "md_path": str | None,
        }
    """
    stages = stages or ALL_STAGES

    # ── 加载配置 ──
    _notify(on_progress, "log", {"level": "DEBUG", "message": "加载全局配置..."})
    config = load_config()
    agent_defaults = load_agent_defaults()
    concurrency_conf = config.get("concurrency", {})
    if max_workers is None:
        max_workers = concurrency_conf.get("agent_runs", 3)
    if agent_model is None:
        agent_model = agent_defaults.get("model")
    if judge_model is None:
        judge_model = config.get("judge", {}).get("model")

    agent_timeout = agent_defaults.get("timeout", 180)

    # 评分阶段权重（从 config.yaml scoring.phase 读取）
    scoring_conf = config.get("scoring", {})
    phase = scoring_conf.get("phase", "current")
    phase_weights = scoring_conf.get("phases", {}).get(phase)

    _notify(on_progress, "log", {"level": "INFO",
        "message": f"配置: 并行数={max_workers}, Agent模型={agent_model or '默认'}, "
                   f"Judge模型={judge_model or '默认'}"})

    # ── 生成 run_id 和 output_dir ──
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    if run_id is None:
        run_id = f"{timestamp}_{profile}"
    if output_dir is None:
        output_dir = os.path.join(BASE_DIR, "results", run_id)

    _notify(on_progress, "log", {"level": "INFO", "message": f"Run ID: {run_id}"})
    _notify(on_progress, "log", {"level": "DEBUG", "message": f"输出目录: {output_dir}"})

    # ── 解析场景 ──
    scenarios_to_run = resolve_scenarios(profile, cases_override)
    selected_case_ids = case_ids or []
    if not selected_case_ids and case_id_filter:
        selected_case_ids = [item.strip() for item in str(case_id_filter).split(",") if item.strip()]
    _notify(on_progress, "log", {"level": "INFO",
        "message": f"待评测场景: {', '.join(scenarios_to_run)} (共{len(scenarios_to_run)}个)"})

    os.makedirs(os.path.join(output_dir, "cases"), exist_ok=True)

    baseline_agent = None
    enhanced_agent = None
    if baseline_agent_id:
        baseline_agent = load_agent(baseline_agent_id)
        if not baseline_agent:
            raise ValueError(f"未找到 Agent: {baseline_agent_id}")
    if enhanced_agent_id:
        enhanced_agent = load_agent(enhanced_agent_id)
        if not enhanced_agent:
            raise ValueError(f"未找到 Agent: {enhanced_agent_id}")

    if not baseline_agent:
        baseline_agent = {
            "id": "default_baseline",
            "name": "Baseline",
            "adapter": agent_defaults.get("adapter", "opencode"),
            "api_base": agent_defaults.get("api_base", api_base),
            "model": agent_model,
        }
    if not enhanced_agent:
        enhanced_agent = {
            "id": "default_enhanced",
            "name": "Enhanced",
            "adapter": agent_defaults.get("adapter", "opencode"),
            "api_base": agent_defaults.get("api_base", api_base),
            "model": agent_model,
        }

    comparison_labels = _normalize_side_labels(comparison_labels or {
        "side_a": baseline_agent.get("name", "基线Agent"),
        "side_b": enhanced_agent.get("name", "评测Agent"),
    })
    active_sides = _normalize_active_sides(active_sides)
    agent_compare_mode = bool(baseline_agent_id or enhanced_agent_id)

    # ── 初始化组件 ──
    need_runner_or_evaluator = "runner" in stages or "evaluator" in stages
    llm_judge = None

    if need_runner_or_evaluator:
        # LLM Judge（评分用的 LLM 调用，通过 adapter 提供）
        _notify(on_progress, "log", {"level": "INFO", "message": "初始化 LLMJudge..."})
        judge_temperature = config.get("judge", {}).get("temperature", 0)
        judge_adapter = OpenCodeAdapter(
            api_base=agent_defaults.get("api_base", api_base),
            model=judge_model,
            timeout=config.get("judge", {}).get("timeout", 60),
            temperature=judge_temperature,
            on_progress=on_progress,
        )
        llm_judge = LLMJudge(
            llm_fn=lambda prompt, tag: judge_adapter.execute(prompt, tag=tag),
            on_progress=on_progress,
            metrics_fn=lambda: judge_adapter.get_last_interaction_metrics(),
        )

    case_stages = [s for s in stages if s in ("runner", "evaluator")]

    _notify(on_progress, "log", {"level": "INFO",
        "message": f"执行阶段: {' → '.join(stages)}"})

    _notify(on_progress, "pipeline_start", {
        "run_id": run_id,
        "profile": profile,
        "scenarios": scenarios_to_run,
        "stages": stages,
        "api_base": api_base,
        "agent_model": agent_model or "默认",
        "judge_model": judge_model or "默认",
        "max_workers": max_workers,
        "comparison_labels": comparison_labels,
        "active_sides": active_sides,
    })

    # ── 按场景串行执行 ──
    all_results = []

    for scenario in scenarios_to_run:
        if case_stages:
            results = run_scenario(
                scenario, llm_judge, output_dir,
                profile_name=profile,
                stages=case_stages, max_workers=max_workers,
                dry_run=dry_run, skip_baseline=skip_baseline,
                only_run_baseline=only_run_baseline,
                case_ids=selected_case_ids,
                on_progress=on_progress,
                phase_weights=phase_weights,
                baseline_agent=baseline_agent,
                enhanced_agent=enhanced_agent,
                comparison_labels=comparison_labels,
                active_sides=active_sides,
                agent_compare_mode=agent_compare_mode,
            )
            all_results.extend(results)
        else:
            # reporter-only: 从磁盘加载所有用例结果
            cases = load_test_cases(scenario)
            if selected_case_ids:
                selected_case_id_set = set(selected_case_ids)
                cases = [c for c in cases if c["id"] in selected_case_id_set]
            for case in cases:
                case_dir = os.path.join(output_dir, "cases", case["id"])
                try:
                    result = load_evaluator_result(case_dir)
                    all_results.append(result)
                except FileNotFoundError as e:
                    _notify(on_progress, "error", {"message": str(e)})

    # ── Reporter 阶段 ──
    json_path = None
    md_path = None
    if "reporter" in stages and all_results:
        _notify(on_progress, "log", {"level": "INFO",
            "message": f"开始生成报告 ({len(all_results)} 个用例结果)..."})
        scenarios_str = ",".join(scenarios_to_run)
        json_path, md_path = generate_report(
            all_results, scenarios_str, profile, output_dir,
            comparison_labels=comparison_labels,
            active_sides=active_sides,
        )
        if json_path:
            _notify(on_progress, "log", {"level": "INFO", "message": f"JSON 报告: {json_path}"})
        if md_path:
            _notify(on_progress, "log", {"level": "INFO", "message": f"Markdown 报告: {md_path}"})
    elif "reporter" in stages and not all_results:
        _notify(on_progress, "log", {"level": "WARN", "message": "无用例结果，跳过报告生成"})

    # ── 汇总统计 ──
    if all_results:
        side_a_avg = sum(r["side_a_total"] for r in all_results) / len(all_results)
        side_b_scores = [r["side_b_total"] for r in all_results if r.get("side_b_total") is not None]
        if side_b_scores:
            side_b_avg = sum(side_b_scores) / len(side_b_scores)
            gain = side_b_avg - side_a_avg
            _notify(on_progress, "log", {"level": "INFO",
                "message": f"评测汇总: 用例数={len(all_results)}, "
                           f"A侧均分={side_a_avg:.1f}, B侧均分={side_b_avg:.1f}, "
                           f"平均增益={'+' if gain >= 0 else ''}{gain:.1f}"})
        else:
            _notify(on_progress, "log", {"level": "INFO",
                "message": f"评测汇总: 用例数={len(all_results)}, "
                           f"A侧均分={side_a_avg:.1f}"})

    _notify(on_progress, "pipeline_done", {
        "run_id": run_id,
        "total_cases": len(all_results),
        "json_path": json_path,
        "md_path": md_path,
    })

    return {
        "run_id": run_id,
        "output_dir": output_dir,
        "results": all_results,
        "json_path": json_path,
        "md_path": md_path,
        "comparison_labels": comparison_labels,
        "active_sides": active_sides,
    }
