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

from agent_bench.runner.adapter import AgentAdapter
from agent_bench.evaluator.llm_judge import LLMJudge
from agent_bench.evaluator import internal_scorer, aggregator
from dataclasses import asdict

from agent_bench.pipeline.loader import (
    load_file, load_test_cases, load_enhancements,
    load_internal_rules, load_rubric,
)
from agent_bench.pipeline.artifacts import (
    save_runner_artifacts, load_runner_artifacts,
    save_evaluator_artifacts, load_evaluator_result,
    stage_dir,
)
from agent_bench.pipeline.compile_checker import check_compilable


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
                    on_progress: Callable = None,
                    phase_weights: dict = None,
                    is_general_case: bool = False) -> dict:
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

    # 对于 general 场景，不需要加载代码文件，直接编译验证
    if is_general_case or scenario == "general":
        input_code = ""
        reference_code = ""
        task_prompt = ""
        _notify(on_progress, "log", {"level": "INFO",
            "message": f"[{case_id}] 通用用例：直接编译 empty_hos_project 验证"})
    else:
        input_code = load_file(case["input"]["code_file"])
        reference_code = load_file(case["expected"]["reference_file"])
        task_prompt = TASK_PROMPT.format(prompt=prompt, code=input_code)

    # rubric 从 scoring_standards.json 按场景加载，不再依赖 case YAML
    rubric = load_rubric(scenario)

    os.makedirs(case_dir, exist_ok=True)
    _notify(on_progress, "log", {"level": "INFO",
        "message": f"[{case_id}] 开始处理用例: {title}"})

    compile_results = None

    # ── Runner 阶段 ──
    if "runner" in stages:
        baseline_output, enhanced_output, compile_results = _run_runner_stage(
            case_id, task_prompt, enhancements,
            adapter, reference_code, input_code,
            dry_run=dry_run, skip_baseline=skip_baseline,
            on_progress=on_progress,
            scenario=scenario,
            case_dir=case_dir,
            is_general_case=is_general_case or scenario == "general",
        )
        _notify(on_progress, "log", {"level": "DEBUG", "message": f"[{case_id}] 保存 Runner 产物..."})
        save_runner_artifacts(case_dir, baseline_output, enhanced_output,
                              task_prompt=task_prompt, enhancements=enhancements)
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
            phase_weights=phase_weights,
            compile_results=compile_results,
        )
    else:
        _notify(on_progress, "log", {"level": "INFO", "message": f"[{case_id}] 从磁盘加载 Evaluator 产物..."})
        result = load_evaluator_result(case_dir)

    if compile_results:
        result["compile_results"] = compile_results

    return result


def _run_runner_stage(case_id, task_prompt, enhancements,
                      adapter, reference_code, input_code,
                      dry_run, skip_baseline, on_progress,
                      scenario: str = None, case_dir: str = None,
                      is_general_case: bool = False):
    """执行 Runner 阶段，返回 (baseline_output, enhanced_output, compile_results)

    基线运行：adapter.setup({}) → 无增强
    增强运行：adapter.setup(enhancements) → 注入 skill/system_prompt/mcp
    
    对于非 project_gen 场景，还会在生成代码后进行编译检查。
    对于 general 场景，直接编译 empty_hos_project 验证可编译性。
    compile_results: {
        "baseline_compilable": bool,
        "baseline_error": str,
        "enhanced_compilable": bool,
        "enhanced_error": str,
    }
    """
    compile_results = {
        "baseline_compilable": None,
        "baseline_error": "",
        "enhanced_compilable": None,
        "enhanced_error": "",
    }

    # general 场景：直接编译 empty_hos_project 验证
    if is_general_case:
        _notify(on_progress, "log", {"level": "INFO", "message": f"[{case_id}] 通用用例：直接编译验证 empty_hos_project 可编译性"})
        t0 = time.time()
        compile_result = check_compilable("", case_dir=stage_dir(case_dir, "baseline"), is_general_check=True)
        elapsed = time.time() - t0
        compile_results["baseline_compilable"] = compile_result["compilable"]
        compile_results["baseline_error"] = compile_result.get("error", "")
        if compile_result["compilable"]:
            _notify(on_progress, "log", {"level": "INFO", "message": f"[{case_id}] 通用用例编译成功"})
        else:
            _notify(on_progress, "log", {"level": "ERROR", 
                "message": f"[{case_id}] 通用用例编译失败: {compile_result.get('error', '未知错误')[:200]}"})
        _notify(on_progress, "stage_done", {"case_id": case_id, "stage": "通用编译检查", "elapsed": elapsed})
        return "", "", compile_results

    need_compile_check = scenario and scenario != "project_gen"
    _notify(on_progress, "log", {"level": "DEBUG",
        "message": f"[{case_id}] 编译检查配置: scenario={scenario}, need_compile_check={need_compile_check}"})

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
        try:
            baseline_output = adapter.execute(task_prompt, tag=tag)
        except TimeoutError as e:
            adapter.teardown()
            _notify(on_progress, "error", {"case_id": case_id, "message": str(e)})
            raise
        elapsed = time.time() - t0
        adapter.teardown()
        _notify(on_progress, "log", {"level": "INFO",
            "message": f"[{case_id}] 基线运行完成, 输出={len(baseline_output)}字符, 耗时={elapsed:.1f}s"})
        
        if need_compile_check:
            _notify(on_progress, "log", {"level": "INFO", "message": f"[{case_id}] 检查基线代码可编译性..."})
            code_to_check = baseline_output if baseline_output.strip() else input_code
            if not baseline_output.strip():
                _notify(on_progress, "log", {"level": "WARNING",
                    "message": f"[{case_id}] 基线未生成有效代码({len(baseline_output)}字符), 使用输入代码检查编译"})
            compile_result = check_compilable(code_to_check, case_dir=stage_dir(case_dir, "baseline"))
            compile_results["baseline_compilable"] = compile_result["compilable"]
            compile_results["baseline_error"] = compile_result.get("error", "")
            if compile_result["compilable"]:
                _notify(on_progress, "log", {"level": "INFO", "message": f"[{case_id}] 基线代码可编译"})
            else:
                _notify(on_progress, "log", {"level": "WARNING", 
                    "message": f"[{case_id}] 基线代码编译失败: {compile_result.get('error', '未知错误')[:100]}"})
        
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
        try:
            enhanced_output = adapter.execute(task_prompt, tag=tag)
        except TimeoutError as e:
            adapter.teardown()
            _notify(on_progress, "error", {"case_id": case_id, "message": str(e)})
            raise
        elapsed = time.time() - t0
        adapter.teardown()
        _notify(on_progress, "log", {"level": "INFO",
            "message": f"[{case_id}] 增强运行完成, 输出={len(enhanced_output)}字符, 耗时={elapsed:.1f}s"})
        
        if need_compile_check:
            _notify(on_progress, "log", {"level": "INFO", "message": f"[{case_id}] 检查增强代码可编译性..."})
            compile_result = check_compilable(enhanced_output, case_dir=stage_dir(case_dir, "enhanced"))
            compile_results["enhanced_compilable"] = compile_result["compilable"]
            compile_results["enhanced_error"] = compile_result.get("error", "")
            if compile_result["compilable"]:
                _notify(on_progress, "log", {"level": "INFO", "message": f"[{case_id}] 增强代码可编译"})
            else:
                _notify(on_progress, "log", {"level": "WARNING", 
                    "message": f"[{case_id}] 增强代码编译失败: {compile_result.get('error', '未知错误')[:100]}"})
        
        _notify(on_progress, "stage_done", {"case_id": case_id, "stage": "增强运行", "elapsed": elapsed})

    return baseline_output, enhanced_output, compile_results


def _run_evaluator_stage(case_id, title, scenario, case,
                         input_code, reference_code, rubric,
                         baseline_output, enhanced_output,
                         llm_judge, case_dir,
                         dry_run, on_progress,
                         phase_weights=None,
                         compile_results=None):
    """执行 Evaluator 阶段，返回结果 dict

    流程：内部评分（全局规则）→ LLM 评分 → 聚合 → 编译结果附加
    
    对于 general 场景：直接返回编译结果，跳过 LLM 评分。
    
    Args:
        compile_results: 编译检查结果，包含 baseline_compilable, baseline_error,
                        enhanced_compilable, enhanced_error
    """
    # general 场景：只返回编译结果
    if scenario == "general":
        is_compilable = compile_results.get("baseline_compilable", False) if compile_results else False
        result = {
            "case_id": case_id,
            "title": title,
            "scenario": scenario,
            "baseline_rule": 0,
            "enhanced_rule": 0,
            "baseline_total": 100 if is_compilable else 0,
            "enhanced_total": 100 if is_compilable else 0,
            "dimension_scores": {},
            "general_pass": is_compilable,
        }
        if compile_results:
            result["compile_results"] = compile_results
        _notify(on_progress, "log", {"level": "INFO",
            "message": f"[{case_id}] 通用用例结果: {'PASS' if is_compilable else 'FAIL'}"})
        save_evaluator_artifacts(case_dir, {}, {}, result)
        return result

    all_dim_names = [r["name"] for r in rubric]

    # ── 内部评分（全局规则库）──────────────────────────────────
    _notify(on_progress, "log", {"level": "INFO", "message": f"[{case_id}] 开始规则检查..."})
    rules_config = load_internal_rules()

    import json as _json
    rc_dir = stage_dir(case_dir, "rule_check")
    with open(os.path.join(rc_dir, "rules.json"), "w", encoding="utf-8") as f:
        _json.dump(rules_config, f, ensure_ascii=False, indent=2)

    baseline_internal = internal_scorer.score(baseline_output, rules_config)
    enhanced_internal = internal_scorer.score(enhanced_output, rules_config)
    _notify(on_progress, "log", {"level": "INFO",
        "message": f"[{case_id}] 规则检查完成: 基线={baseline_internal.total:.1f}/30, "
                   f"增强={enhanced_internal.total:.1f}/30"})
    _notify(on_progress, "stage_done", {
        "case_id": case_id, "stage": "规则检查",
        "baseline_rule": baseline_internal.total,
        "enhanced_rule": enhanced_internal.total,
    })

    # ── LLM 评分 ──────────────────────────────────────────────
    if dry_run:
        from agent_bench.evaluator.models import LLMDimensionScore, LLMScoringResult
        def _mock_llm_result(score_val):
            dims = [LLMDimensionScore(name=r["name"], score=score_val,
                                     weight=r["weight"], reason="dry-run")
                    for r in rubric]
            return LLMScoringResult(dimensions=dims, weighted_avg=float(score_val))
        baseline_llm = _mock_llm_result(30)
        enhanced_llm = _mock_llm_result(85)
        judge_raw = {
            "baseline": [{"name": r["name"], "score": 30, "reason": "dry-run"} for r in rubric],
            "enhanced": [{"name": r["name"], "score": 85, "reason": "dry-run"} for r in rubric],
        }
        _notify(on_progress, "stage_done", {"case_id": case_id, "stage": "LLM评分", "elapsed": 0, "skipped": True})
    else:
        _notify(on_progress, "log", {"level": "INFO",
            "message": f"[{case_id}] 开始 LLM 评分 ({len(rubric)} 个维度)..."})
        t0 = time.time()
        judge_scores = llm_judge.judge(
            input_code, baseline_output, enhanced_output,
            reference_code, rubric, case_id=case_id,
            case_dir=case_dir,
        )
        elapsed = time.time() - t0
        baseline_llm = judge_scores["baseline"]
        enhanced_llm = judge_scores["enhanced"]
        judge_raw = {
            "baseline": [{"name": d.name, "score": d.score, "reason": d.reason}
                         for d in baseline_llm.dimensions],
            "enhanced": [{"name": d.name, "score": d.score, "reason": d.reason}
                         for d in enhanced_llm.dimensions],
        }
        _notify(on_progress, "log", {"level": "INFO",
            "message": f"[{case_id}] LLM 评分完成, 耗时={elapsed:.1f}s"})
        _notify(on_progress, "stage_done", {"case_id": case_id, "stage": "LLM评分", "elapsed": elapsed})

    # ── 聚合最终分数 ───────────────────────────────────────────
    baseline_total = aggregator.compute(baseline_internal, baseline_llm, all_dim_names, phase_weights)
    enhanced_total = aggregator.compute(enhanced_internal, enhanced_llm, all_dim_names, phase_weights)

    # 维度得分明细（同时包含 LLM 和内部评分）
    dimension_scores = {}
    llm_b_map = {d.name: d.score for d in baseline_llm.dimensions}
    llm_e_map = {d.name: d.score for d in enhanced_llm.dimensions}
    internal_b_map = {k: v.score for k, v in baseline_internal.dimensions.items()}
    internal_e_map = {k: v.score for k, v in enhanced_internal.dimensions.items()}
    for r_item in rubric:
        name = r_item["name"]
        dim_id = r_item.get("dimension_id", name)
        llm_b = llm_b_map.get(name, 50)
        llm_e = llm_e_map.get(name, 50)
        internal_b = internal_b_map.get(dim_id, 100)  # 内部评分归一化后是0-100
        internal_e = internal_e_map.get(dim_id, 100)
        dimension_scores[dim_id] = {
            "name": name,
            "baseline": {"llm": llm_b, "internal": internal_b},
            "enhanced": {"llm": llm_e, "internal": internal_e},
        }
        _notify(on_progress, "log", {"level": "DEBUG",
            "message": f"[{case_id}]   维度 [{name}]: 基线(LLM={llm_b},内部={internal_b}), 增强(LLM={llm_e},内部={internal_e})"})

    gain = enhanced_total - baseline_total
    _notify(on_progress, "log", {"level": "INFO",
        "message": f"[{case_id}] 综合评分: 基线={baseline_total:.1f}, 增强={enhanced_total:.1f}, "
                   f"增益={'+' if gain >= 0 else ''}{gain:.1f}"})

    # ── 序列化内部评分结果 ─────────────────────────────────────
    def _serialize_internal(r):
        return {
            "total": r.total,
            "dimensions": {
                k: {
                    "score": v.score,
                    "raw_score": v.raw_score,
                    "max_score": v.max_score,
                    "rules": [
                        {"name": rule.name, "level": rule.level,
                         "passed": rule.passed, "matched": rule.matched,
                         "description": rule.description}
                        for rule in v.rules
                    ],
                }
                for k, v in r.dimensions.items()
            },
        }

    internal_artifact = {
        "baseline": _serialize_internal(baseline_internal),
        "enhanced": _serialize_internal(enhanced_internal),
    }

    result = {
        "case_id": case_id,
        "title": title,
        "scenario": case.get("scenario", scenario),
        "baseline_rule": baseline_internal.total,
        "enhanced_rule": enhanced_internal.total,
        "baseline_total": baseline_total,
        "enhanced_total": enhanced_total,
        "dimension_scores": dimension_scores,
    }

    if compile_results:
        result["compile_results"] = compile_results

    _notify(on_progress, "log", {"level": "DEBUG", "message": f"[{case_id}] 保存 Evaluator 产物..."})
    save_evaluator_artifacts(case_dir, internal_artifact, judge_raw, result)

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
                 on_progress: Callable = None,
                 phase_weights: dict = None) -> list:
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
                phase_weights=phase_weights,
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
