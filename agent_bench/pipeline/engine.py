# -*- coding: utf-8 -*-
"""Pipeline Engine。"""

import os
from datetime import datetime
from typing import Callable

from agent_bench.pipeline.artifacts import load_evaluator_result
from agent_bench.pipeline.case_runner import run_scenario
from agent_bench.pipeline.loader import load_agent, load_agent_defaults, load_config, load_test_cases, resolve_scenarios
from agent_bench.report.reporter import generate as generate_report

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ALL_STAGES = ["runner", "reporter"]


def _notify(on_progress, event: str, data: dict):
    if on_progress:
        on_progress(event, data)


def run_pipeline(profile: str,
                 cases_override: str = None,
                 api_base: str = None,
                 agent_model: str = None,
                 judge_model: str = None,
                 max_workers: int = None,
                 dry_run: bool = False,
                 case_id_filter: str = None,
                 case_ids: list = None,
                 agent_id: str = None,
                 run_id: str = None,
                 output_dir: str = None,
                 stages: list = None,
                 on_progress: Callable = None,
                 **legacy_kwargs) -> dict:
    _ = (judge_model, legacy_kwargs)
    stages = stages or ALL_STAGES

    config = load_config()
    agent_defaults = load_agent_defaults()
    concurrency_conf = config.get("concurrency", {}) or {}
    if max_workers is None:
        max_workers = concurrency_conf.get("agent_runs", 3)
    if agent_model is None:
        agent_model = agent_defaults.get("model")
    if api_base is None:
        api_base = agent_defaults.get("api_base")

    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    if run_id is None:
        run_id = f"{timestamp}_{profile}"
    if output_dir is None:
        output_dir = os.path.join(BASE_DIR, "results", run_id)
    os.makedirs(os.path.join(output_dir, "cases"), exist_ok=True)

    scenarios_to_run = resolve_scenarios(profile, cases_override)
    selected_case_ids = case_ids or []
    if not selected_case_ids and case_id_filter:
        selected_case_ids = [item.strip() for item in str(case_id_filter).split(",") if item.strip()]

    agent = None
    if agent_id:
        agent = load_agent(agent_id)
        if not agent:
            raise ValueError(f"未找到 Agent: {agent_id}")
    if not agent:
        agent = {
            "id": "default_agent",
            "name": "Default",
            "adapter": agent_defaults.get("adapter", "opencode"),
            "api_base": agent_defaults.get("api_base", api_base),
            "model": agent_model,
        }

    _notify(on_progress, "pipeline_start", {
        "run_id": run_id,
        "profile": profile,
        "scenarios": scenarios_to_run,
        "stages": stages,
        "api_base": api_base,
        "agent_model": agent_model or "默认",
        "max_workers": max_workers,
        "agent": {
            "id": agent.get("id"),
            "name": agent.get("name"),
            "adapter": agent.get("adapter"),
        },
    })

    case_stages = [s for s in stages if s == "runner"]
    all_results = []
    for scenario in scenarios_to_run:
        if case_stages:
            results = run_scenario(
                scenario,
                None,
                output_dir,
                profile_name=profile,
                stages=case_stages,
                max_workers=max_workers,
                dry_run=dry_run,
                case_ids=selected_case_ids,
                on_progress=on_progress,
                agent_config=agent,
                agent_compare_mode=bool(agent_id),
            )
            all_results.extend(results)
        else:
            cases = load_test_cases(scenario)
            if selected_case_ids:
                selected_case_id_set = set(selected_case_ids)
                cases = [c for c in cases if c["id"] in selected_case_id_set]
            for case in cases:
                case_dir = os.path.join(output_dir, "cases", case["id"])
                try:
                    all_results.append(load_evaluator_result(case_dir))
                except FileNotFoundError as exc:
                    _notify(on_progress, "error", {"message": str(exc)})

    json_path = None
    md_path = None
    if "reporter" in stages and all_results:
        scenarios_str = ",".join(scenarios_to_run)
        json_path, md_path = generate_report(all_results, scenarios_str, profile, output_dir, agent_label=agent.get("name", "执行Agent"))

    if all_results:
        scores = [r["score"] for r in all_results if isinstance(r.get("score"), (int, float))]
        if scores:
            avg_score = sum(scores) / len(scores)
            _notify(on_progress, "log", {"level": "INFO", "message": f"评测汇总: 用例数={len(all_results)}, 平均分={avg_score:.1f}"})
        else:
            _notify(on_progress, "log", {"level": "INFO", "message": f"评测汇总: 用例数={len(all_results)}"})

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
        "agent": {
            "id": agent.get("id"),
            "name": agent.get("name"),
            "adapter": agent.get("adapter"),
            "model": agent.get("model"),
        },
    }
