# -*- coding: utf-8 -*-
"""Pipeline Engine — 评测流水线核心

职责：
- 编排 Runner → Evaluator → Reporter 三阶段流水线
- 支持分阶段重跑（stages 参数）
- 通过 on_progress 回调向调用方推送进度
- CLI 和 Web UI 共享此模块，不直接依赖任何 IO 方式

不做的事：不包含 CLI 参数解析、服务发现、打印逻辑。
"""

import concurrent.futures
import json
import os
import time
from datetime import datetime
from typing import Callable, Optional

from agent_bench.runner.agent_runner import (
    AgentRunner,
    DEFAULT_API_BASE,
)
from agent_bench.evaluator.rule_checker import check as rule_check
from agent_bench.evaluator.llm_judge import LLMJudge
from agent_bench.report.reporter import generate as generate_report


BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CONFIG_PATH = os.path.join(BASE_DIR, "config.yaml")

# 场景 → Skill 文件的映射
PROFILE_MAP = {
    "project_gen": "skills/create-harmony-project.md",
    "compilable": "skills/compilable.md",
    "performance": "skills/performance.md",
    "bug_fix": "skills/bug_fix.md",
}

ALL_STAGES = ["runner", "evaluator", "reporter"]


# ── 工具函数 ─────────────────────────────────────────────────

def load_yaml(file_path: str) -> dict:
    """加载 YAML 文件"""
    import yaml
    with open(file_path, "r", encoding="utf-8") as f:
        return yaml.safe_load(f)


def load_config() -> dict:
    """加载全局配置文件"""
    if os.path.exists(CONFIG_PATH):
        return load_yaml(CONFIG_PATH) or {}
    return {}


def load_file(relative_path: str) -> str:
    """加载测试用例关联的代码文件"""
    path = os.path.join(BASE_DIR, relative_path)
    with open(path, "r", encoding="utf-8") as f:
        return f.read()


def load_test_cases(scenario: str) -> list:
    """加载指定场景目录下的所有测试用例"""
    cases_dir = os.path.join(BASE_DIR, "test_cases", scenario)
    if not os.path.isdir(cases_dir):
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

    优先级：cases_override > Profile YAML 的 scenarios 字段 > profile_name 本身
    """
    all_scenarios = list(PROFILE_MAP.keys())

    if cases_override:
        if cases_override == "all":
            return all_scenarios
        return [s.strip() for s in cases_override.split(",") if s.strip()]

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
        return ""
    with open(skill_path, "r", encoding="utf-8") as f:
        return f.read()


# ── 评分计算 ─────────────────────────────────────────────────

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


# ── 产物持久化 ───────────────────────────────────────────────

def _save_runner_artifacts(case_dir: str, baseline_output: str, enhanced_output: str):
    """保存 Runner 阶段产物"""
    os.makedirs(case_dir, exist_ok=True)
    with open(os.path.join(case_dir, "baseline_output.txt"), "w", encoding="utf-8") as f:
        f.write(baseline_output)
    with open(os.path.join(case_dir, "enhanced_output.txt"), "w", encoding="utf-8") as f:
        f.write(enhanced_output)


def _load_runner_artifacts(case_dir: str) -> tuple:
    """加载 Runner 阶段产物"""
    baseline_path = os.path.join(case_dir, "baseline_output.txt")
    enhanced_path = os.path.join(case_dir, "enhanced_output.txt")
    if not os.path.exists(baseline_path) or not os.path.exists(enhanced_path):
        raise FileNotFoundError(f"Runner 产物不存在: {case_dir}，请先运行 runner 阶段")
    with open(baseline_path, "r", encoding="utf-8") as f:
        baseline_output = f.read()
    with open(enhanced_path, "r", encoding="utf-8") as f:
        enhanced_output = f.read()
    return baseline_output, enhanced_output


def _save_evaluator_artifacts(case_dir: str, rule_detail: dict, judge_result: dict,
                              result: dict):
    """保存 Evaluator 阶段产物"""
    os.makedirs(case_dir, exist_ok=True)
    with open(os.path.join(case_dir, "rule_check.json"), "w", encoding="utf-8") as f:
        json.dump(rule_detail, f, ensure_ascii=False, indent=2)
    with open(os.path.join(case_dir, "judge.json"), "w", encoding="utf-8") as f:
        json.dump(judge_result, f, ensure_ascii=False, indent=2)
    with open(os.path.join(case_dir, "result.json"), "w", encoding="utf-8") as f:
        json.dump(result, f, ensure_ascii=False, indent=2)


def _load_evaluator_result(case_dir: str) -> dict:
    """加载 Evaluator 阶段的 result.json"""
    result_path = os.path.join(case_dir, "result.json")
    if not os.path.exists(result_path):
        raise FileNotFoundError(f"Evaluator 产物不存在: {case_dir}，请先运行 evaluator 阶段")
    with open(result_path, "r", encoding="utf-8") as f:
        return json.load(f)


# ── 回调辅助 ─────────────────────────────────────────────────

def _notify(on_progress, event: str, data: dict):
    """安全地调用回调"""
    if on_progress:
        on_progress(event, data)


# ── 单用例执行 ───────────────────────────────────────────────

def run_single_case(case: dict, scenario: str, skill_content: str,
                    agent_runner: AgentRunner, llm_judge: LLMJudge,
                    case_dir: str,
                    stages: list = None,
                    dry_run: bool = False,
                    skip_baseline: bool = False,
                    on_progress: Callable = None) -> dict:
    """执行单个测试用例的指定阶段

    Args:
        case: 用例配置 dict
        scenario: 场景名
        skill_content: Skill 文件内容
        agent_runner: AgentRunner 实例
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

    os.makedirs(case_dir, exist_ok=True)

    # ── Runner 阶段 ──
    if "runner" in stages:
        # 基线运行
        if dry_run:
            baseline_output = "// dry run - no output"
            _notify(on_progress, "stage_done", {"case_id": case_id, "stage": "基线运行", "elapsed": 0, "skipped": True})
        elif skip_baseline:
            baseline_output = ""
            _notify(on_progress, "stage_done", {"case_id": case_id, "stage": "基线运行", "elapsed": 0, "skipped": True})
        else:
            t0 = time.time()
            baseline_output = agent_runner.run_baseline(prompt, input_code)
            _notify(on_progress, "stage_done", {"case_id": case_id, "stage": "基线运行", "elapsed": time.time() - t0})

        # 增强运行
        if dry_run:
            enhanced_output = reference_code
            _notify(on_progress, "stage_done", {"case_id": case_id, "stage": "增强运行", "elapsed": 0, "skipped": True})
        else:
            t0 = time.time()
            enhanced_output = agent_runner.run_enhanced(prompt, input_code, skill_content)
            _notify(on_progress, "stage_done", {"case_id": case_id, "stage": "增强运行", "elapsed": time.time() - t0})

        _save_runner_artifacts(case_dir, baseline_output, enhanced_output)
    else:
        # 从磁盘加载上次 Runner 的结果
        baseline_output, enhanced_output = _load_runner_artifacts(case_dir)

    # ── Evaluator 阶段 ──
    if "evaluator" in stages:
        # 规则评分
        baseline_rule = rule_check(baseline_output, case["expected"])
        enhanced_rule = rule_check(enhanced_output, case["expected"])
        _notify(on_progress, "stage_done", {
            "case_id": case_id, "stage": "规则检查",
            "baseline_rule": baseline_rule["rule_score"],
            "enhanced_rule": enhanced_rule["rule_score"],
        })

        # LLM 评分
        if dry_run:
            judge_result = {
                "baseline": [{"name": r["name"], "score": 30, "reason": "dry-run"} for r in rubric],
                "enhanced": [{"name": r["name"], "score": 85, "reason": "dry-run"} for r in rubric],
            }
            _notify(on_progress, "stage_done", {"case_id": case_id, "stage": "LLM评分", "elapsed": 0, "skipped": True})
        else:
            t0 = time.time()
            judge_result = llm_judge.judge(
                input_code, baseline_output, enhanced_output,
                reference_code, rubric
            )
            _notify(on_progress, "stage_done", {"case_id": case_id, "stage": "LLM评分", "elapsed": time.time() - t0})

        baseline_llm_scores = judge_result["baseline"]
        enhanced_llm_scores = judge_result["enhanced"]

        # 汇总评分
        baseline_total = compute_total(baseline_rule["rule_score"], baseline_llm_scores, rubric)
        enhanced_total = compute_total(enhanced_rule["rule_score"], enhanced_llm_scores, rubric)

        dimension_scores = {}
        for r_item in rubric:
            name = r_item["name"]
            b_score = next((s["score"] for s in baseline_llm_scores if s["name"] == name), 50)
            e_score = next((s["score"] for s in enhanced_llm_scores if s["name"] == name), 50)
            dimension_scores[name] = {"baseline": b_score, "enhanced": e_score}

        result = {
            "case_id": case_id,
            "title": title,
            "scenario": case.get("scenario", scenario),
            "baseline_rule": baseline_rule["rule_score"],
            "enhanced_rule": enhanced_rule["rule_score"],
            "baseline_total": baseline_total,
            "enhanced_total": enhanced_total,
            "dimension_scores": dimension_scores,
        }

        _save_evaluator_artifacts(
            case_dir,
            {"baseline": baseline_rule, "enhanced": enhanced_rule},
            judge_result,
            result,
        )
    else:
        # 从磁盘加载上次 Evaluator 的结果
        result = _load_evaluator_result(case_dir)

    return result


# ── 场景执行 ─────────────────────────────────────────────────

def run_scenario(scenario: str,
                 agent_runner: AgentRunner,
                 llm_judge: LLMJudge,
                 output_dir: str,
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
    skill_content = load_skill_content(scenario)
    cases = load_test_cases(scenario)

    if case_id_filter:
        cases = [c for c in cases if c["id"] == case_id_filter]

    _notify(on_progress, "scenario_start", {
        "scenario": scenario,
        "case_count": len(cases),
        "skill_file": PROFILE_MAP.get(scenario, "N/A"),
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
                run_single_case, case, scenario, skill_content,
                agent_runner, llm_judge, case_dir,
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


# ── 顶层入口 ─────────────────────────────────────────────────

def run_pipeline(profile: str,
                 cases_override: str = None,
                 api_base: str = DEFAULT_API_BASE,
                 agent_model: str = None,
                 judge_model: str = None,
                 max_workers: int = None,
                 dry_run: bool = False,
                 skip_baseline: bool = False,
                 case_id_filter: str = None,
                 run_id: str = None,
                 output_dir: str = None,
                 stages: list = None,
                 on_progress: Callable = None) -> dict:
    """评测流水线顶层入口

    Args:
        profile: Profile 名称
        cases_override: 场景覆盖（逗号分隔或 "all"）
        api_base: OpenCode API 地址
        agent_model: Agent 模型
        judge_model: Judge 模型
        max_workers: 并行数
        dry_run: 干跑模式
        skip_baseline: 跳过基线
        case_id_filter: 只跑指定用例
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

    # 加载配置
    config = load_config()
    concurrency_conf = config.get("concurrency", {})
    if max_workers is None:
        max_workers = concurrency_conf.get("agent_runs", 3)

    # 如果没有指定模型，从配置文件读
    if agent_model is None:
        agent_model = config.get("agent", {}).get("model")
    if judge_model is None:
        judge_model = config.get("judge", {}).get("model")

    # 生成 run_id 和 output_dir
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    if run_id is None:
        run_id = f"{timestamp}_{profile}"
    if output_dir is None:
        output_dir = os.path.join(BASE_DIR, "results", run_id)

    # 解析场景
    scenarios_to_run = resolve_scenarios(profile, cases_override)

    os.makedirs(os.path.join(output_dir, "cases"), exist_ok=True)

    # 初始化 Runner 和 Judge（仅在需要时）
    need_runner_or_evaluator = "runner" in stages or "evaluator" in stages
    agent_runner = AgentRunner(api_base=api_base, model=agent_model) if need_runner_or_evaluator else None
    llm_judge = LLMJudge(api_base=api_base, model=judge_model) if need_runner_or_evaluator else None

    # 只传给 run_scenario 的阶段（不含 reporter）
    case_stages = [s for s in stages if s in ("runner", "evaluator")]

    _notify(on_progress, "pipeline_start", {
        "run_id": run_id,
        "profile": profile,
        "scenarios": scenarios_to_run,
        "stages": stages,
        "api_base": api_base,
        "agent_model": agent_model or "OpenCode 默认",
        "judge_model": judge_model or "OpenCode 默认",
        "max_workers": max_workers,
    })

    # 按场景串行执行
    all_results = []
    for scenario in scenarios_to_run:
        if case_stages:
            results = run_scenario(
                scenario, agent_runner, llm_judge, output_dir,
                stages=case_stages, max_workers=max_workers,
                dry_run=dry_run, skip_baseline=skip_baseline,
                case_id_filter=case_id_filter,
                on_progress=on_progress,
            )
            all_results.extend(results)
        else:
            # reporter-only: 从磁盘加载所有用例结果
            cases = load_test_cases(scenario)
            if case_id_filter:
                cases = [c for c in cases if c["id"] == case_id_filter]
            for case in cases:
                case_dir = os.path.join(output_dir, "cases", case["id"])
                try:
                    result = _load_evaluator_result(case_dir)
                    all_results.append(result)
                except FileNotFoundError as e:
                    _notify(on_progress, "error", {"message": str(e)})

    # Reporter 阶段
    json_path = None
    md_path = None
    if "reporter" in stages and all_results:
        scenarios_str = ",".join(scenarios_to_run)
        json_path, md_path = generate_report(
            all_results, scenarios_str, profile, output_dir
        )

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
    }
