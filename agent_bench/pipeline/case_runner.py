# -*- coding: utf-8 -*-
"""用例执行

职责：
- 单用例执行（run_single_case）：编排 Runner → Evaluator 两阶段
- 场景执行（run_scenario）：并行调度多个用例

Runner 阶段通过 AgentAdapter 与 Agent 交互：
- 基线运行：adapter.setup({}) → execute(task_prompt)
- 增强运行：adapter.setup(enhancements) → execute(task_prompt)
"""

import concurrent.futures
import os
import time
from typing import Callable

import yaml
from agent_bench.runner.adapter import AgentAdapter
from agent_bench.evaluator.rule_checker import check as rule_check
from agent_bench.evaluator.llm_judge import LLMJudge
from agent_bench.evaluator.internal_rule_checker import InternalRuleChecker

from agent_bench.pipeline.loader import (
    load_file, load_test_cases, load_enhancements,
)
from agent_bench.pipeline.artifacts import (
    save_runner_artifacts, load_runner_artifacts,
    save_evaluator_artifacts, load_evaluator_result,
)
from agent_bench.pipeline.scoring import compute_total


# ── 任务 Prompt 模板 ─────────────────────────────────────────

TASK_PROMPT = """请完成以下任务。

## 任务
{prompt}

## 代码
```typescript
{code}
```

## 要求
- 只输出完整的代码
- 不要解释过程
"""


def _notify(on_progress, event: str, data: dict):
    """安全地调用回调"""
    if on_progress:
        on_progress(event, data)


# ── 单用例执行 ───────────────────────────────────────────────

def run_single_case(case: dict, scenario: str, enhancements: dict,
                    adapter: AgentAdapter, llm_judge: LLMJudge,
                    case_dir: str,
                    stages: list = None,
                    dry_run: bool = False,
                    skip_baseline: bool = False,
                    on_progress: Callable = None) -> dict:
    """执行单个测试用例的指定阶段

    Args:
        case: 用例配置 dict
        scenario: 场景名
        enhancements: 增强配置（已加载 skill 内容）
        adapter: AgentAdapter 实例
        llm_judge: LLMJudge 实例
        case_dir: 产物存放目录
        stages: 要执行的阶段列表，默认 ["runner", "evaluator"]
        dry_run: 干跑模式
        skip_baseline: 跳过基线运行
        on_progress: 进度回调

    Returns:
        用例结果 dict
    """
    stages = stages or ["runner", "evaluator"]
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

    # 构建纯任务 prompt（不含 skill，skill 由 adapter 通过 system 字段注入）
    task_prompt = TASK_PROMPT.format(prompt=prompt, code=input_code)

    os.makedirs(case_dir, exist_ok=True)
    _notify(on_progress, "log", {"level": "INFO",
        "message": f"[{case_id}] 开始处理用例: {title}"})

    # ── Runner 阶段 ──
    if "runner" in stages:
        baseline_output, enhanced_output = _run_runner_stage(
            case_id, task_prompt, enhancements,
            adapter, reference_code,
            dry_run=dry_run, skip_baseline=skip_baseline,
            on_progress=on_progress,
        )
        _notify(on_progress, "log", {"level": "DEBUG", "message": f"[{case_id}] 保存 Runner 产物..."})
        save_runner_artifacts(case_dir, baseline_output, enhanced_output)
    else:
        _notify(on_progress, "log", {"level": "INFO", "message": f"[{case_id}] 从磁盘加载 Runner 产物..."})
        baseline_output, enhanced_output = load_runner_artifacts(case_dir)
        _notify(on_progress, "log", {"level": "DEBUG",
            "message": f"[{case_id}] 已加载: 基线={len(baseline_output)}字符, 增强={len(enhanced_output)}字符"})

    # ── Evaluator 阶段 ──
    if "evaluator" in stages:
        result = _run_evaluator_stage(
            case_id, title, scenario, case,
            input_code, reference_code, rubric,
            baseline_output, enhanced_output,
            llm_judge, case_dir,
            dry_run=dry_run, on_progress=on_progress,
        )
    else:
        _notify(on_progress, "log", {"level": "INFO", "message": f"[{case_id}] 从磁盘加载 Evaluator 产物..."})
        result = load_evaluator_result(case_dir)

    return result


def _run_runner_stage(case_id, task_prompt, enhancements,
                      adapter, reference_code,
                      dry_run, skip_baseline, on_progress):
    """执行 Runner 阶段，返回 (baseline_output, enhanced_output)

    基线运行：adapter.setup({}) → 无增强
    增强运行：adapter.setup(enhancements) → 注入 skill/system_prompt/mcp
    """
    # ── 基线运行 ──
    if dry_run:
        baseline_output = "// dry run - no output"
        _notify(on_progress, "stage_done", {"case_id": case_id, "stage": "基线运行", "elapsed": 0, "skipped": True})
    elif skip_baseline:
        baseline_output = ""
        _notify(on_progress, "log", {"level": "INFO", "message": f"[{case_id}] 跳过基线运行 (skip_baseline)"})
        _notify(on_progress, "stage_done", {"case_id": case_id, "stage": "基线运行", "elapsed": 0, "skipped": True})
    else:
        _notify(on_progress, "log", {"level": "INFO", "message": f"[{case_id}] 配置基线模式 (无增强)..."})
        adapter.setup({}, on_progress=on_progress)
        _notify(on_progress, "log", {"level": "INFO", "message": f"[{case_id}] 开始基线运行..."})
        _notify(on_progress, "log", {"level": "DEBUG",
            "message": f"[{case_id}] Task Prompt={len(task_prompt)}字符"})
        t0 = time.time()
        tag = f"[{case_id}][基线] "
        baseline_output = adapter.execute(task_prompt, tag=tag)
        elapsed = time.time() - t0
        adapter.teardown()
        _notify(on_progress, "log", {"level": "INFO",
            "message": f"[{case_id}] 基线运行完成, 输出={len(baseline_output)}字符, 耗时={elapsed:.1f}s"})
        _notify(on_progress, "stage_done", {"case_id": case_id, "stage": "基线运行", "elapsed": elapsed})

    # ── 增强运行 ──
    if dry_run:
        enhanced_output = reference_code
        _notify(on_progress, "stage_done", {"case_id": case_id, "stage": "增强运行", "elapsed": 0, "skipped": True})
    else:
        _notify(on_progress, "log", {"level": "INFO", "message": f"[{case_id}] 配置增强模式..."})
        adapter.setup(enhancements, on_progress=on_progress)
        _notify(on_progress, "log", {"level": "INFO", "message": f"[{case_id}] 开始增强运行..."})
        t0 = time.time()
        tag = f"[{case_id}][增强] "
        enhanced_output = adapter.execute(task_prompt, tag=tag)
        elapsed = time.time() - t0
        adapter.teardown()
        _notify(on_progress, "log", {"level": "INFO",
            "message": f"[{case_id}] 增强运行完成, 输出={len(enhanced_output)}字符, 耗时={elapsed:.1f}s"})
        _notify(on_progress, "stage_done", {"case_id": case_id, "stage": "增强运行", "elapsed": elapsed})

    return baseline_output, enhanced_output


def _run_evaluator_stage(case_id, title, scenario, case,
                         input_code, reference_code, rubric,
                         baseline_output, enhanced_output,
                         llm_judge, case_dir,
                         dry_run, on_progress):
    """执行 Evaluator 阶段，返回结果 dict"""
    internal_checker = InternalRuleChecker()

    baseline_internal = {}
    enhanced_internal = {}
    baseline_internal_score = 100.0
    enhanced_internal_score = 100.0

    if not dry_run:
        _notify(on_progress, "log", {"level": "INFO", "message": f"[{case_id}] 开始内部规则检查..."})
        baseline_internal = internal_checker.check_code(baseline_output or "") if baseline_output else {}
        enhanced_internal = internal_checker.check_code(enhanced_output or "") if enhanced_output else {}
        baseline_internal_score = internal_checker.get_level_weighted_score(baseline_internal) if baseline_internal else 100.0
        enhanced_internal_score = internal_checker.get_level_weighted_score(enhanced_internal) if enhanced_internal else 100.0
        _notify(on_progress, "log", {"level": "INFO",
            "message": f"[{case_id}] 内部规则检查完成: 基线={baseline_internal_score}, 增强={enhanced_internal_score}"})

    baseline_rule = {"rule_score": 0}
    enhanced_rule = {"rule_score": 0}

    if dry_run:
        judge_result = {
            "baseline": [{"name": r["name"], "score": 30, "reason": "dry-run"} for r in rubric],
            "enhanced": [{"name": r["name"], "score": 85, "reason": "dry-run"} for r in rubric],
        }
        _notify(on_progress, "log", {"level": "DEBUG", "message": f"[{case_id}] LLM评分跳过 (dry-run)"})
        _notify(on_progress, "stage_done", {"case_id": case_id, "stage": "LLM评分", "elapsed": 0, "skipped": True})
    else:
        _notify(on_progress, "log", {"level": "INFO",
            "message": f"[{case_id}] 开始 LLM 评分 ({len(rubric)} 个维度)..."})
        t0 = time.time()
        judge_result = llm_judge.judge(
            input_code, baseline_output or "", enhanced_output or "",
            reference_code, rubric, case_id=case_id
        )
        elapsed = time.time() - t0
        _notify(on_progress, "log", {"level": "INFO",
            "message": f"[{case_id}] LLM 评分完成, 耗时={elapsed:.1f}s"})
        _notify(on_progress, "stage_done", {"case_id": case_id, "stage": "LLM评分", "elapsed": elapsed})

    baseline_llm_scores = judge_result["baseline"]
    enhanced_llm_scores = judge_result["enhanced"]

    baseline_total = compute_total(baseline_llm_scores, rubric, baseline_internal)
    enhanced_total = compute_total(enhanced_llm_scores, rubric, enhanced_internal)

    dimension_scores = {}
    for r_item in rubric:
        name = r_item["name"]
        b_score = next((s["score"] for s in baseline_llm_scores if s["name"] == name), 50)
        e_score = next((s["score"] for s in enhanced_llm_scores if s["name"] == name), 50)
        dimension_scores[name] = {"baseline": b_score, "enhanced": e_score}
        _notify(on_progress, "log", {"level": "DEBUG",
            "message": f"[{case_id}]   维度 [{name}]: 基线={b_score}, 增强={e_score}"})

    _notify(on_progress, "log", {"level": "INFO",
        "message": f"[{case_id}] 综合评分: 基线={baseline_total}, 增强={enhanced_total}, "
                   f"增益={'+' if enhanced_total >= baseline_total else ''}{enhanced_total - baseline_total:.1f}"})

    result = {
        "case_id": case_id,
        "title": title,
        "scenario": case.get("scenario", scenario),
        "baseline_rule": baseline_rule["rule_score"],
        "enhanced_rule": enhanced_rule["rule_score"],
        "baseline_internal": baseline_internal_score,
        "enhanced_internal": enhanced_internal_score,
        "baseline_total": baseline_total,
        "enhanced_total": enhanced_total,
        "dimension_scores": dimension_scores,
        "_baseline_internal_detail": baseline_internal,
        "_enhanced_internal_detail": enhanced_internal,
    }

    _notify(on_progress, "log", {"level": "DEBUG", "message": f"[{case_id}] 保存 Evaluator 产物..."})
    save_evaluator_artifacts(
        case_dir,
        {"baseline": baseline_rule, "enhanced": enhanced_rule},
        judge_result,
        result,
    )

    internal_result = {
        "case_id": case_id,
        "baseline": {
            "results": baseline_internal,
            "summary": {"total_score": baseline_internal_score}
        },
        "enhanced": {
            "results": enhanced_internal,
            "summary": {"total_score": enhanced_internal_score}
        }
    }
    internal_path = os.path.join(case_dir, "internal_rules.yaml")
    with open(internal_path, "w", encoding="utf-8") as f:
        yaml.dump(internal_result, f, allow_unicode=True, default_flow_style=False)

    return result


# ── 场景执行 ─────────────────────────────────────────────────

def run_scenario(scenario: str,
                 adapter: AgentAdapter,
                 llm_judge: LLMJudge,
                 output_dir: str,
                 profile_name: str = None,
                 stages: list = None,
                 max_workers: int = 1,
                 dry_run: bool = False,
                 skip_baseline: bool = False,
                 case_id_filter: str = None,
                 on_progress: Callable = None) -> list:
    """执行单个场景下的所有用例

    Returns:
        用例结果列表
    """
    stages = stages or ["runner", "evaluator"]

    # 加载增强配置
    _notify(on_progress, "log", {"level": "INFO", "message": f"加载场景 [{scenario}] 的增强配置..."})
    enhancements = load_enhancements(scenario, profile_name=profile_name)
    if enhancements:
        parts = []
        if enhancements.get("skills"):
            parts.append(f"{len(enhancements['skills'])} skills")
        if enhancements.get("mcp_servers"):
            parts.append(f"{len(enhancements['mcp_servers'])} mcp")
        if enhancements.get("system_prompt"):
            parts.append("system_prompt")
        _notify(on_progress, "log", {"level": "INFO",
            "message": f"增强配置已加载: {', '.join(parts)}"})
    else:
        _notify(on_progress, "log", {"level": "INFO", "message": f"场景 [{scenario}] 无增强配置"})

    cases = load_test_cases(scenario)
    _notify(on_progress, "log", {"level": "INFO",
        "message": f"场景 [{scenario}] 加载了 {len(cases)} 个测试用例"})

    if case_id_filter:
        cases = [c for c in cases if c["id"] == case_id_filter]
        _notify(on_progress, "log", {"level": "INFO",
            "message": f"过滤后保留 {len(cases)} 个用例 (filter={case_id_filter})"})

    _notify(on_progress, "scenario_start", {
        "scenario": scenario,
        "case_count": len(cases),
        "skill_file": f"profile:{profile_name or 'auto'}",
    })

    if not cases:
        _notify(on_progress, "scenario_done", {"scenario": scenario, "case_count": 0})
        return []

    results = []
    futures = {}

    with concurrent.futures.ThreadPoolExecutor(max_workers=max_workers) as executor:
        for i, case in enumerate(cases):
            case_dir = os.path.join(output_dir, "cases", case["id"])
            future = executor.submit(
                run_single_case, case, scenario, enhancements,
                adapter, llm_judge, case_dir,
                stages=stages, dry_run=dry_run,
                skip_baseline=skip_baseline,
                on_progress=on_progress,
            )
            futures[future] = (i, case)

        for future in concurrent.futures.as_completed(futures):
            i, case = futures[future]
            try:
                result = future.result()
                gain = result["enhanced_total"] - result["baseline_total"]
                _notify(on_progress, "case_done", {
                    "case_id": result["case_id"],
                    "title": result["title"],
                    "index": i + 1,
                    "total": len(cases),
                    "scenario": scenario,
                    "baseline_total": result["baseline_total"],
                    "enhanced_total": result["enhanced_total"],
                    "gain": gain,
                })
                results.append(result)
            except Exception as e:
                _notify(on_progress, "error", {
                    "case_id": case["id"],
                    "message": str(e),
                })

    _notify(on_progress, "scenario_done", {
        "scenario": scenario,
        "case_count": len(results),
    })
    return results
