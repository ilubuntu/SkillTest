# -*- coding: utf-8 -*-
"""用例执行

职责：
- 单用例执行（run_single_case）：编排 Runner → Compile → Evaluator
- 场景执行（run_scenario）：并行调度多个用例

Runner 阶段通过 AgentAdapter 与 Agent 交互：
- A 侧运行：adapter.setup({}) → 在 side_a 工程中直接修改文件
- B 侧运行：adapter.setup(enhancements) → 在 side_b 工程中直接修改文件
"""

import concurrent.futures
import json
import os
import time
from typing import Callable

from agent_bench.runner.factory import create_adapter
from agent_bench.evaluator.llm_judge import LLMJudge
from agent_bench.evaluator import internal_scorer, aggregator

from agent_bench.pipeline.loader import (
    load_test_cases, load_enhancements, load_config,
    load_internal_rules, load_rubric, resolve_case_original_project,
)
from agent_bench.pipeline.artifacts import (
    save_runner_artifacts, load_runner_artifacts,
    save_evaluator_artifacts, load_evaluator_result,
    save_interaction_metrics,
    save_compile_artifacts,
    save_rule_check_artifact,
    stage_dir, stage_meta_dir, META_DIR_NAME,
)
from agent_bench.pipeline.compile_checker import (
    prepare_project_workspace,
    check_project_compilable,
)


# ── 任务 Prompt 模板 ─────────────────────────────────────────

TASK_PROMPT = """请直接在指定工程目录中修改代码完成任务。

## 工作方式
- 这是一个已经准备好的 HarmonyOS ArkTS 工程
- 你应直接修改工程目录中的文件，而不是只返回单个代码片段
- 完成后请简要说明修改了哪些文件、主要修改内容和最终效果

## 任务
{prompt}
"""

TASK_PROMPT_MULTI_PAGE = """请直接在指定工程目录中修改代码完成任务。

## 工作方式
- 这是一个已经准备好的 HarmonyOS ArkTS 工程
- 你应直接修改工程目录中的文件，而不是只返回单个代码片段
- 完成后请简要说明修改了哪些文件、主要修改内容和最终效果

## 任务
{prompt}

## 参考补充文件
{additional_pages}
"""

MAX_LOGGED_PROMPT_CHARS = 4000


def _summarize_compile_error(error_text: str, limit: int = 160) -> str:
    text = (error_text or "").strip()
    if not text:
        return "未知错误"
    compact = " ".join(line.strip() for line in text.splitlines() if line.strip())
    return compact[:limit]


def _case_related_files(case: dict) -> list:
    case_spec = case.get("case_spec", {}) or {}
    problem = case_spec.get("problem", {}) or {}
    related = []
    for item in problem.get("related_files", []) or []:
        path = item.get("path") if isinstance(item, dict) else item
        if not path:
            continue
        if path.startswith("original_project/"):
            path = path[len("original_project/"):]
        related.append(path)
    return related


def _load_changed_files(side_dir: str) -> list:
    changed_path = os.path.join(side_dir, META_DIR_NAME, "changed_files.json")
    if not os.path.exists(changed_path):
        return []
    try:
        import json
        with open(changed_path, "r", encoding="utf-8") as f:
            data = json.load(f) or {}
        return data.get("changed_files", []) or []
    except Exception:
        return []


def _build_scoring_text(case: dict, side_dir: str, fallback_output: str = "") -> str:
    paths = []
    seen = set()
    for path in _load_changed_files(side_dir) + _case_related_files(case):
        if not path or path in seen:
            continue
        seen.add(path)
        paths.append(path)

    chunks = []
    for rel_path in paths:
        abs_path = os.path.join(side_dir, rel_path)
        if not os.path.isfile(abs_path):
            continue
        try:
            with open(abs_path, "r", encoding="utf-8") as f:
                content = f.read()
            chunks.append(f"// FILE: {rel_path}\n{content}")
        except Exception:
            continue

    if chunks:
        return "\n\n".join(chunks)
    return fallback_output or ""


def _notify(on_progress, event: str, data: dict):
    """安全地调用回调"""
    if on_progress:
        on_progress(event, data)


# ── 单用例执行 ───────────────────────────────────────────────

def run_single_case(case: dict, scenario: str, enhancements: dict,
                    llm_judge: LLMJudge,
                    case_dir: str,
                    stages: list = None,
                    dry_run: bool = False,
                    skip_baseline: bool = False,
                    only_run_baseline: bool = False,
                    on_progress: Callable = None,
                    phase_weights: dict = None,
                    baseline_agent: dict = None,
                    enhanced_agent: dict = None,
                    comparison_labels: dict = None,
                    active_sides: list = None,
                    agent_timeout: int = 180,
                    agent_temperature: float = None,
                    is_general_case: bool = False) -> dict:
    """执行单个测试用例的指定阶段

    Args:
        case: 用例配置 dict
        scenario: 场景名
        enhancements: 增强配置（已加载 skill 内容）
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
    prompt = case["prompt"]

    # 场景名标准化（兼容 "General" / "general" / "Project Gen" 等写法）
    _scenario_key = scenario.lower().replace(" ", "_")

    # 对于 general 场景，不需要加载代码文件，直接编译当前用例的模板工程
    if is_general_case or _scenario_key == "general":
        task_prompt = ""
        _notify(on_progress, "log", {"level": "INFO",
            "message": f"[{case_id}] 通用用例：直接编译 current case 的 original_project 验证"})
    else:
        additional_files = case.get("additional_files", {})
        sibling_files = additional_files.get("sibling_files", {})
        pages_files = additional_files.get("pages", {})

        if sibling_files or pages_files:
            all_additional = {**sibling_files, **pages_files}
            additional_pages_text = "\n\n".join(
                f"=== {filename} ===\n{content}" for filename, content in all_additional.items()
            )
            task_prompt = TASK_PROMPT_MULTI_PAGE.format(
                prompt=prompt,
                additional_pages=additional_pages_text
            )
            _notify(on_progress, "log", {"level": "INFO",
                "message": f"[{case_id}] 多页面场景：检测到 {len(all_additional)} 个额外页面文件"})
        else:
            task_prompt = TASK_PROMPT.format(prompt=prompt)

    if task_prompt:
        prompt_preview = task_prompt[:MAX_LOGGED_PROMPT_CHARS]
        if len(task_prompt) > MAX_LOGGED_PROMPT_CHARS:
            prompt_preview += "\n...<truncated>"
        _notify(on_progress, "log", {
            "level": "DEBUG",
            "message": f"[{case_id}] Agent Task Prompt:\n{prompt_preview}"
        })

    # rubric 从 scoring_standards.json 按场景加载，不再依赖 case YAML
    rubric = load_rubric(scenario)

    os.makedirs(case_dir, exist_ok=True)
    _notify(on_progress, "log", {"level": "INFO",
        "message": f"[{case_id}] 开始处理用例: {title}"})

    compile_results = {
        "side_a_compilable": None,
        "side_a_error": "",
        "side_b_compilable": None,
        "side_b_error": "",
    }

    # ── Runner 阶段 ──
    if "runner" in stages:
        # 若产物已存在则直接复用，避免重复调用 Agent 引入随机性
        side_a_path = os.path.join(case_dir, "side_a", META_DIR_NAME, "output.txt")
        side_b_path = os.path.join(case_dir, "side_b", META_DIR_NAME, "output.txt")
        use_runner_cache = os.path.exists(side_a_path) and (os.path.exists(side_b_path) or only_run_baseline)
        if use_runner_cache:
            _notify(on_progress, "log", {"level": "INFO",
                "message": f"[{case_id}] Runner 产物已存在，跳过 Agent 执行（复用缓存）"})
            side_a_output, side_b_output = load_runner_artifacts(case_dir)
        else:
            side_a_output, side_b_output, compile_results = _run_runner_stage(
                case, case_id, task_prompt, enhancements,
                dry_run=dry_run, skip_baseline=skip_baseline,
                only_run_baseline=only_run_baseline,
                on_progress=on_progress,
                scenario=scenario,
                case_dir=case_dir,
                baseline_agent=baseline_agent,
                enhanced_agent=enhanced_agent,
                comparison_labels=comparison_labels,
                active_sides=active_sides,
                agent_timeout=agent_timeout,
                agent_temperature=agent_temperature,
                is_general_case=is_general_case or _scenario_key == "general",
            )
            _notify(on_progress, "log", {"level": "DEBUG", "message": f"[{case_id}] 保存 Runner 产物..."})
            save_runner_artifacts(case_dir, side_a_output, side_b_output,
                                  task_prompt=task_prompt, enhancements=enhancements,
                                  include_side_b=not only_run_baseline)
    else:
        _notify(on_progress, "log", {"level": "INFO", "message": f"[{case_id}] 从磁盘加载 Runner 产物..."})
        side_a_output, side_b_output = load_runner_artifacts(case_dir)
        _notify(on_progress, "log", {"level": "DEBUG",
            "message": f"[{case_id}] 已加载: side_a={len(side_a_output)}字符, side_b={len(side_b_output)}字符"})

    compile_results = _run_compile_stage(
        case=case,
        case_id=case_id,
        scenario=scenario,
        case_dir=case_dir,
        only_run_baseline=only_run_baseline,
        on_progress=on_progress,
        compile_results=compile_results,
        comparison_labels=comparison_labels,
        is_general_case=is_general_case or _scenario_key == "general",
    )

    # ── Evaluator 阶段 ──
    if "evaluator" in stages:
        result = _run_evaluator_stage(
            case_id, title, scenario, case,
            prompt,
            rubric,
            side_a_output, side_b_output,
            llm_judge, case_dir,
            dry_run=dry_run, on_progress=on_progress,
            only_run_baseline=only_run_baseline,
            phase_weights=phase_weights,
            compile_results=compile_results,
            comparison_labels=comparison_labels,
            active_sides=active_sides,
        )
    else:
        _notify(on_progress, "log", {"level": "INFO", "message": f"[{case_id}] 从磁盘加载 Evaluator 产物..."})
        result = load_evaluator_result(case_dir)

    if compile_results:
        result["compile_results"] = compile_results
        with open(os.path.join(case_dir, "result.json"), "w", encoding="utf-8") as f:
            json.dump(result, f, ensure_ascii=False, indent=2)

    return result


def _run_runner_stage(case, case_id, task_prompt, enhancements,
                      dry_run, skip_baseline, only_run_baseline, on_progress,
                      scenario: str = None, case_dir: str = None,
                      baseline_agent: dict = None, enhanced_agent: dict = None,
                      comparison_labels: dict = None,
                      active_sides: list = None,
                      agent_timeout: int = 180, agent_temperature: float = None,
                      is_general_case: bool = False):
    """执行 Runner 阶段，返回 (side_a_output, side_b_output, compile_results)

    A 侧运行：adapter.setup({}) → 在 side_a 工程目录直接修改
    B 侧运行：adapter.setup(enhancements) → 在 side_b 工程目录直接修改
    
    对于非 project_gen 场景，仅执行 agent 修改，不做编译。
    编译检查会在 Evaluator 之前执行，但失败不会阻塞后续评分。
    对于 general 场景，直接编译当前用例的 original_project 验证可编译性。
    compile_results: {
        "baseline_compilable": bool,
        "baseline_error": str,
        "enhanced_compilable": bool,
        "enhanced_error": str,
    }
    """
    compile_results = {
        "side_a_compilable": None,
        "side_a_error": "",
        "side_b_compilable": None,
        "side_b_error": "",
    }
    side_a_label = (comparison_labels or {}).get("side_a") or (comparison_labels or {}).get("baseline", "Agent A")
    side_b_label = (comparison_labels or {}).get("side_b") or (comparison_labels or {}).get("enhanced", "Agent B")
    template_project_path = resolve_case_original_project(case) if case else None
    if not template_project_path:
        missing_msg = f"[{case_id}] 未找到 original_project 模板，请在测试用例目录下提供 original_project"
        compile_results["side_a_compilable"] = False
        compile_results["side_a_error"] = missing_msg
        if not only_run_baseline:
            compile_results["side_b_compilable"] = False
            compile_results["side_b_error"] = missing_msg
        _notify(on_progress, "log", {"level": "ERROR", "message": missing_msg})
        if is_general_case:
            return "", "", compile_results

    side_a_dir = stage_dir(case_dir, "side_a")
    side_b_dir = os.path.join(case_dir, "side_b")

    # general 场景：直接编译当前用例的 original_project 验证
    if is_general_case:
        prepare_project_workspace(template_project_path, side_a_dir)
        _notify(on_progress, "log", {"level": "INFO", "message": f"[{case_id}] 通用用例：直接编译验证模板工程 {template_project_path}"})
        t0 = time.time()
        compile_result = check_project_compilable(
            side_a_dir,
            template_project_path=template_project_path,
        )
        elapsed = time.time() - t0
        compile_results["side_a_compilable"] = compile_result["compilable"]
        compile_results["side_a_error"] = compile_result.get("error", "")
        if not compile_result["compilable"]:
            error_text = compile_result.get("error", "未知错误")
            _notify(on_progress, "log", {
                "level": "ERROR",
                "message": f"[{case_id}] 通用用例完整编译失败原因见下方详情",
                "detail": error_text,
            })
        if only_run_baseline:
            compile_results["side_b_compilable"] = None
            compile_results["side_b_error"] = ""
        if compile_result["compilable"]:
            _notify(on_progress, "log", {"level": "INFO", "message": f"[{case_id}] 通用用例编译成功"})
            stage_status = "done"
        else:
            _notify(on_progress, "log", {"level": "ERROR", 
                "message": f"[{case_id}] 通用用例编译失败: {compile_result.get('error', '未知错误')[:200]}"})
            stage_status = "error"
        _notify(on_progress, "stage_done", {"case_id": case_id, "stage": "A侧运行", "elapsed": elapsed, "status": stage_status})
        return "", "", compile_results

    # ── A 侧运行 ──
    if dry_run:
        prepare_project_workspace(template_project_path, side_a_dir)
        side_a_output = "// dry run - no output"
        _notify(on_progress, "stage_done", {"case_id": case_id, "stage": "A侧运行", "elapsed": 0, "skipped": True})
    elif skip_baseline:
        prepare_project_workspace(template_project_path, side_a_dir)
        side_a_output = ""
        _notify(on_progress, "log", {"level": "INFO", "message": f"[{case_id}] 跳过 {side_a_label} 运行 (skip_baseline)"})
        _notify(on_progress, "stage_done", {"case_id": case_id, "stage": "A侧运行", "elapsed": 0, "skipped": True})
    else:
        prepare_project_workspace(template_project_path, side_a_dir)
        baseline_adapter = create_adapter(
            baseline_agent or enhanced_agent,
            timeout=agent_timeout,
            on_progress=on_progress,
            temperature=agent_temperature,
        )
        try:
            _notify(on_progress, "stage_start", {"case_id": case_id, "stage": "A侧运行"})
            _notify(on_progress, "log", {"level": "INFO", "message": f"[{case_id}] 配置 {side_a_label} 运行..."})
            baseline_adapter.setup({}, on_progress=on_progress)
            _notify(on_progress, "log", {"level": "INFO", "message": f"[{case_id}] 开始 {side_a_label} 运行..."})
            _notify(on_progress, "log", {"level": "DEBUG",
                "message": f"[{case_id}] Task Prompt={len(task_prompt)}字符, workspace={side_a_dir}"})
            t0 = time.time()
            tag = f"[{case_id}][{side_a_label}] "
            side_a_output = baseline_adapter.execute(task_prompt, tag=tag, workspace_dir=side_a_dir)
        except TimeoutError as e:
            _notify(on_progress, "error", {"case_id": case_id, "message": str(e)})
            raise
        finally:
            save_interaction_metrics(case_dir, "side_a", baseline_adapter.get_last_interaction_metrics())
            baseline_adapter.teardown()
        elapsed = time.time() - t0
        _notify(on_progress, "log", {"level": "INFO",
            "message": f"[{case_id}] {side_a_label} 运行完成, 输出={len(side_a_output)}字符, 耗时={elapsed:.1f}s"})
        
        _notify(on_progress, "stage_done", {"case_id": case_id, "stage": "A侧运行", "elapsed": elapsed})

    # ── B 侧运行 ──
    if only_run_baseline:
        side_b_output = ""
        compile_results["side_b_compilable"] = None
        compile_results["side_b_error"] = ""
        _notify(on_progress, "log", {"level": "INFO", "message": f"[{case_id}] 仅运行 {side_a_label}，{side_b_label} 跳过执行"})
        _notify(on_progress, "stage_done", {"case_id": case_id, "stage": "B侧运行", "elapsed": 0, "skipped": True})
    elif dry_run:
        prepare_project_workspace(template_project_path, side_b_dir)
        side_b_output = "// dry run - no output"
        _notify(on_progress, "stage_done", {"case_id": case_id, "stage": "B侧运行", "elapsed": 0, "skipped": True})
    else:
        prepare_project_workspace(template_project_path, side_b_dir)
        enhanced_adapter = create_adapter(
            enhanced_agent or baseline_agent,
            timeout=agent_timeout,
            on_progress=on_progress,
            temperature=agent_temperature,
        )
        try:
            _notify(on_progress, "stage_start", {"case_id": case_id, "stage": "B侧运行"})
            _notify(on_progress, "log", {"level": "INFO", "message": f"[{case_id}] 配置 {side_b_label} 运行..."})
            enhanced_adapter.setup(enhancements or {}, on_progress=on_progress)
            _notify(on_progress, "log", {"level": "INFO", "message": f"[{case_id}] 开始 {side_b_label} 运行..."})
            t0 = time.time()
            tag = f"[{case_id}][{side_b_label}] "
            side_b_output = enhanced_adapter.execute(task_prompt, tag=tag, workspace_dir=side_b_dir)
        except TimeoutError as e:
            _notify(on_progress, "error", {"case_id": case_id, "message": str(e)})
            raise
        finally:
            save_interaction_metrics(case_dir, "side_b", enhanced_adapter.get_last_interaction_metrics())
            enhanced_adapter.teardown()
        elapsed = time.time() - t0
        _notify(on_progress, "log", {"level": "INFO",
            "message": f"[{case_id}] {side_b_label} 运行完成, 输出={len(side_b_output)}字符, 耗时={elapsed:.1f}s"})
        
        _notify(on_progress, "stage_done", {"case_id": case_id, "stage": "B侧运行", "elapsed": elapsed})

    return side_a_output, side_b_output, compile_results


def _run_compile_stage(case: dict,
                       case_id: str,
                       scenario: str,
                       case_dir: str,
                       only_run_baseline: bool,
                       on_progress,
                       compile_results: dict,
                       comparison_labels: dict = None,
                       is_general_case: bool = False) -> dict:
    """在评分之前执行编译验证，但失败不会中断后续流程。"""
    compile_results = compile_results or {
        "side_a_compilable": None,
        "side_a_error": "",
        "side_b_compilable": None,
        "side_b_error": "",
    }
    scenario_key = (scenario or "").lower().replace(" ", "_")
    if is_general_case or scenario_key == "general":
        return compile_results
    if not scenario_key or scenario_key == "project_gen":
        return compile_results

    template_project_path = resolve_case_original_project(case) if case else None
    if not template_project_path:
        missing_msg = f"[{case_id}] 未找到 original_project 模板，请在测试用例目录下提供 original_project"
        compile_results["side_a_compilable"] = False
        compile_results["side_a_error"] = missing_msg
        if not only_run_baseline:
            compile_results["side_b_compilable"] = False
            compile_results["side_b_error"] = missing_msg
        _notify(on_progress, "log", {"level": "ERROR", "message": missing_msg})
        return compile_results

    side_a_dir = os.path.join(case_dir, "side_a")
    side_b_dir = os.path.join(case_dir, "side_b")
    side_a_label = (comparison_labels or {}).get("side_a") or "A侧"
    side_b_label = (comparison_labels or {}).get("side_b") or "B侧"

    _notify(on_progress, "log", {"level": "INFO", "message": f"[{case_id}] 开始编译验证..."})

    if os.path.isdir(side_a_dir):
        _notify(on_progress, "stage_start", {"case_id": case_id, "stage": "A侧编译"})
        _notify(on_progress, "log", {"level": "INFO", "message": f"[{case_id}] 检查 {side_a_label} 工程可编译性..."})
        t0 = time.time()
        compile_result = check_project_compilable(side_a_dir, template_project_path=template_project_path)
        save_compile_artifacts(case_dir, "side_a_compile", compile_result)
        compile_results["side_a_compilable"] = compile_result["compilable"]
        compile_results["side_a_error"] = compile_result.get("error", "")
        if not compile_result["compilable"]:
            error_text = compile_result.get("error", "未知错误")
            _notify(on_progress, "log", {
                "level": "WARNING",
                "message": f"[{case_id}] {side_a_label} 完整编译失败原因见下方详情",
                "detail": error_text,
            })
        if compile_result["compilable"]:
            _notify(on_progress, "log", {"level": "INFO", "message": f"[{case_id}] {side_a_label} 工程可编译"})
            stage_status = "done"
        else:
            _notify(on_progress, "log", {"level": "WARNING",
                "message": f"[{case_id}] {side_a_label} 工程编译失败: {compile_result.get('error', '未知错误')[:100]}"})
            stage_status = "error"
        _notify(on_progress, "stage_done", {"case_id": case_id, "stage": "A侧编译", "elapsed": time.time() - t0, "status": stage_status})

    if only_run_baseline:
        compile_results["side_b_compilable"] = None
        compile_results["side_b_error"] = ""
        _notify(on_progress, "stage_done", {"case_id": case_id, "stage": "B侧编译", "elapsed": 0, "skipped": True})
        return compile_results

    if os.path.isdir(side_b_dir):
        _notify(on_progress, "stage_start", {"case_id": case_id, "stage": "B侧编译"})
        _notify(on_progress, "log", {"level": "INFO", "message": f"[{case_id}] 检查 {side_b_label} 工程可编译性..."})
        t0 = time.time()
        compile_result = check_project_compilable(side_b_dir, template_project_path=template_project_path)
        save_compile_artifacts(case_dir, "side_b_compile", compile_result)
        compile_results["side_b_compilable"] = compile_result["compilable"]
        compile_results["side_b_error"] = compile_result.get("error", "")
        if not compile_result["compilable"]:
            error_text = compile_result.get("error", "未知错误")
            _notify(on_progress, "log", {
                "level": "WARNING",
                "message": f"[{case_id}] {side_b_label} 完整编译失败原因见下方详情",
                "detail": error_text,
            })
        if compile_result["compilable"]:
            _notify(on_progress, "log", {"level": "INFO", "message": f"[{case_id}] {side_b_label} 工程可编译"})
            stage_status = "done"
        else:
            _notify(on_progress, "log", {"level": "WARNING",
                "message": f"[{case_id}] {side_b_label} 工程编译失败: {compile_result.get('error', '未知错误')[:100]}"})
            stage_status = "error"
        _notify(on_progress, "stage_done", {"case_id": case_id, "stage": "B侧编译", "elapsed": time.time() - t0, "status": stage_status})

    return compile_results


def _run_evaluator_stage(case_id, title, scenario, case,
                         prompt,
                         rubric,
                         side_a_output, side_b_output,
                         llm_judge, case_dir,
                         dry_run, on_progress,
                         only_run_baseline: bool = False,
                         phase_weights=None,
                         compile_results=None,
                         comparison_labels: dict = None,
                         active_sides: list = None):
    """执行 Evaluator 阶段，返回结果 dict

    流程：内部评分（全局规则）→ LLM 评分 → 聚合 → 编译结果附加
    
    对于 general 场景：直接返回编译结果，跳过 LLM 评分。
    
    Args:
        compile_results: 编译检查结果，包含 side_a_compilable, side_a_error,
                        side_b_compilable, side_b_error
    """
    side_a_label = (comparison_labels or {}).get("side_a") or (comparison_labels or {}).get("baseline", "Agent A")
    side_b_label = (comparison_labels or {}).get("side_b") or (comparison_labels or {}).get("enhanced", "Agent B")
    side_a_dir = os.path.join(case_dir, "side_a")
    side_b_dir = os.path.join(case_dir, "side_b")
    side_a_scoring_text = _build_scoring_text(case, side_a_dir, fallback_output=side_a_output)
    side_b_scoring_text = _build_scoring_text(case, side_b_dir, fallback_output=side_b_output)

    # general 场景：只返回编译结果
    if scenario.lower().replace(" ", "_") == "general":
        is_compilable = compile_results.get("side_a_compilable", False) if compile_results else False
        result = {
            "case_id": case_id,
            "title": title,
            "scenario": scenario,
            "side_a_rule": 0,
            "side_b_rule": None if only_run_baseline else 0,
            "side_a_total": 100 if is_compilable else 0,
            "side_b_total": None if only_run_baseline else (100 if is_compilable else 0),
            "gain": None,
            "dimension_scores": {},
            "general_pass": is_compilable,
        }
        if compile_results:
            result["compile_results"] = compile_results
        _notify(on_progress, "log", {"level": "INFO",
            "message": f"[{case_id}] 通用用例结果: {'PASS' if is_compilable else 'FAIL'}"})
        save_evaluator_artifacts(case_dir, {}, {}, result)
        return result

    # ── 内部评分（全局规则库）──────────────────────────────────
    _notify(on_progress, "stage_start", {"case_id": case_id, "stage": "规则检查"})
    _notify(on_progress, "log", {"level": "INFO", "message": f"[{case_id}] 开始规则检查..."})
    rules_config = load_internal_rules()

    import json as _json
    rc_dir = stage_dir(case_dir, "rule_check")
    with open(os.path.join(rc_dir, "rules.json"), "w", encoding="utf-8") as f:
        _json.dump(rules_config, f, ensure_ascii=False, indent=2)

    try:
        side_a_internal = internal_scorer.score(side_a_scoring_text, rules_config)
        side_b_internal = internal_scorer.score(side_b_scoring_text, rules_config) if not only_run_baseline else None
    except Exception:
        _notify(on_progress, "stage_done", {"case_id": case_id, "stage": "规则检查", "status": "error"})
        raise

    sides_to_log = [("side_a", side_a_internal, side_a_label)]
    if not only_run_baseline:
        sides_to_log.append(("side_b", side_b_internal, side_b_label))
    for side, result, label in sides_to_log:
        for dim_name, dim in result.dimensions.items():
            for rule in dim.rules:
                status = "✓" if rule.passed else "✗"
                detail = ""
                if rule.matched and not rule.passed:
                    detail = f" → {rule.matched_text}"
                _notify(on_progress, "log", {"level": "DEBUG",
                    "message": f"[{case_id}] 规则[{label}] {status} {rule.name} ({rule.level}){detail}"})

    if only_run_baseline:
        _notify(on_progress, "log", {"level": "INFO",
            "message": f"[{case_id}] 规则检查完成: {side_a_label}={side_a_internal.total:.1f}/30"})
    else:
        _notify(on_progress, "log", {"level": "INFO",
            "message": f"[{case_id}] 规则检查完成: {side_a_label}={side_a_internal.total:.1f}/30, "
                       f"{side_b_label}={side_b_internal.total:.1f}/30"})
    _notify(on_progress, "stage_done", {
        "case_id": case_id, "stage": "规则检查",
        "side_a_rule": side_a_internal.total,
        "side_b_rule": side_b_internal.total if side_b_internal else None,
    })

    # ── LLM 评分 ──────────────────────────────────────────────
    if dry_run:
        from agent_bench.evaluator.models import LLMDimensionScore, LLMScoringResult
        def _mock_llm_result(score_val):
            dims = [LLMDimensionScore(name=r["name"], score=score_val,
                                     weight=r["weight"], reason="dry-run")
                    for r in rubric]
            return LLMScoringResult(dimensions=dims, weighted_avg=float(score_val))
        side_a_llm = _mock_llm_result(30)
        side_b_llm = None if only_run_baseline else _mock_llm_result(85)
        judge_raw = {
            "side_a": [{"name": r["name"], "score": 30, "reason": "dry-run"} for r in rubric],
            "side_b": [] if only_run_baseline else [{"name": r["name"], "score": 85, "reason": "dry-run"} for r in rubric],
        }
        _notify(on_progress, "stage_done", {"case_id": case_id, "stage": "LLM评分", "elapsed": 0, "skipped": True})
    else:
        _notify(on_progress, "log", {"level": "INFO",
            "message": f"[{case_id}] 开始{'单侧' if only_run_baseline else '双侧'} LLM 评分 ({len(rubric)} 个维度)..."})
        _notify(on_progress, "stage_start", {"case_id": case_id, "stage": "LLM评分"})
        t0 = time.time()
        try:
            if only_run_baseline:
                side_a_llm = llm_judge.judge_baseline(
                    prompt, side_a_scoring_text,
                    rubric, case_id=case_id, case_dir=case_dir,
                )
                side_b_llm = None
                judge_raw = {
                    "side_a": [{"name": d.name, "score": d.score, "reason": d.reason}
                               for d in side_a_llm.dimensions],
                    "side_b": [],
                }
            else:
                judge_scores = llm_judge.judge(
                    prompt, side_a_scoring_text, side_b_scoring_text,
                    rubric, case_id=case_id,
                    case_dir=case_dir,
                )
                side_a_llm = judge_scores["baseline"]
                side_b_llm = judge_scores["enhanced"]
                judge_raw = {
                    "side_a": [{"name": d.name, "score": d.score, "reason": d.reason}
                               for d in side_a_llm.dimensions],
                    "side_b": [{"name": d.name, "score": d.score, "reason": d.reason}
                               for d in side_b_llm.dimensions],
                }
        except Exception:
            _notify(on_progress, "stage_done", {"case_id": case_id, "stage": "LLM评分", "status": "error"})
            raise
        elapsed = time.time() - t0
        _notify(on_progress, "log", {"level": "INFO",
            "message": f"[{case_id}] LLM 评分完成, 耗时={elapsed:.1f}s"})
        _notify(on_progress, "stage_done", {"case_id": case_id, "stage": "LLM评分", "elapsed": elapsed})

    # ── 聚合最终分数 ───────────────────────────────────────────
    side_a_total = aggregator.compute(side_a_internal, side_a_llm, rubric, phase_weights)
    side_b_total = None if only_run_baseline else aggregator.compute(side_b_internal, side_b_llm, rubric, phase_weights)

    # 维度得分明细（同时包含 LLM 和内部评分）
    dimension_scores = {}
    llm_a_map = {d.name: d.score for d in side_a_llm.dimensions}
    llm_b_map = {d.name: d.score for d in side_b_llm.dimensions} if side_b_llm else {}
    internal_a_map = {k: v.score for k, v in side_a_internal.dimensions.items()}
    internal_b_map = {k: v.score for k, v in side_b_internal.dimensions.items()} if side_b_internal else {}
    for r_item in rubric:
        name = r_item["name"]
        dim_id = r_item.get("dimension_id", name)
        llm_a = llm_a_map.get(name, 50)
        llm_b = llm_b_map.get(name)
        internal_a = internal_a_map.get(dim_id, 100)
        internal_b = internal_b_map.get(dim_id, 100) if not only_run_baseline else None
        score_entry = {
            "name": name,
            "side_a": {"llm": llm_a, "internal": internal_a},
        }
        if not only_run_baseline:
            score_entry["side_b"] = {"llm": llm_b, "internal": internal_b}
        dimension_scores[dim_id] = score_entry
        if only_run_baseline:
            _notify(on_progress, "log", {"level": "DEBUG",
                "message": f"[{case_id}]   维度 [{name}]: {side_a_label}(LLM={llm_a},本地={internal_a})"})
        else:
            _notify(on_progress, "log", {"level": "DEBUG",
                "message": f"[{case_id}]   维度 [{name}]: {side_a_label}(LLM={llm_a},本地={internal_a}), {side_b_label}(LLM={llm_b},本地={internal_b})"})

    gain = None if only_run_baseline else side_b_total - side_a_total
    if only_run_baseline:
        _notify(on_progress, "log", {"level": "INFO",
            "message": f"[{case_id}] 综合评分: {side_a_label}={side_a_total:.1f}"})
    else:
        _notify(on_progress, "log", {"level": "INFO",
            "message": f"[{case_id}] 综合评分: {side_a_label}={side_a_total:.1f}, {side_b_label}={side_b_total:.1f}, "
                       f"差值={'+' if gain >= 0 else ''}{gain:.1f}"})

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
                         "matched_text": rule.matched_text,
                         "description": rule.description,
                         "max_score": rule.max_score,
                         "earned_score": rule.earned_score}
                        for rule in v.rules
                    ],
                }
                for k, v in r.dimensions.items()
            },
        }

    internal_artifact = {
        "side_a": _serialize_internal(side_a_internal),
        "side_b": _serialize_internal(side_b_internal) if side_b_internal else None,
    }
    save_rule_check_artifact(case_dir, internal_artifact)

    result = {
        "case_id": case_id,
        "title": title,
        "scenario": case.get("scenario", scenario),
        "side_a_rule": side_a_internal.total,
        "side_b_rule": side_b_internal.total if side_b_internal else None,
        "side_a_total": side_a_total,
        "side_b_total": side_b_total,
        "gain": gain,
        "dimension_scores": dimension_scores,
    }

    if compile_results:
        result["compile_results"] = compile_results

    _notify(on_progress, "log", {"level": "DEBUG", "message": f"[{case_id}] 保存 Evaluator 产物..."})
    save_evaluator_artifacts(case_dir, internal_artifact, judge_raw, result)

    return result


# ── 场景执行 ─────────────────────────────────────────────────

def run_scenario(scenario: str,
                 llm_judge: LLMJudge,
                 output_dir: str,
                 profile_name: str = None,
                 stages: list = None,
                 max_workers: int = 1,
                 dry_run: bool = False,
                 skip_baseline: bool = False,
                 only_run_baseline: bool = False,
                 case_id_filter: str = None,
                 case_ids: list = None,
                 on_progress: Callable = None,
                 phase_weights: dict = None,
                 baseline_agent: dict = None,
                 enhanced_agent: dict = None,
                 comparison_labels: dict = None,
                 active_sides: list = None,
                 agent_compare_mode: bool = False) -> list:
    """执行单个场景下的所有用例

    Returns:
        用例结果列表
    """
    stages = stages or ["runner", "evaluator"]

    # 加载增强配置
    enhancements = {}
    if agent_compare_mode:
        _notify(on_progress, "log", {"level": "INFO", "message": f"场景 [{scenario}] 使用 Agent 对比模式，跳过 Profile 增强配置"})
    else:
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

    config = load_config()
    agent_timeout = config.get("agent", {}).get("timeout", 180)
    agent_temperature = config.get("agent", {}).get("temperature")

    cases = load_test_cases(scenario)
    _notify(on_progress, "log", {"level": "INFO",
        "message": f"场景 [{scenario}] 加载了 {len(cases)} 个测试用例"})

    selected_case_ids = case_ids or []
    if not selected_case_ids and case_id_filter:
        selected_case_ids = [item.strip() for item in str(case_id_filter).split(",") if item.strip()]

    if selected_case_ids:
        selected_case_id_set = set(selected_case_ids)
        cases = [c for c in cases if c["id"] in selected_case_id_set]
        _notify(on_progress, "log", {"level": "INFO",
            "message": f"过滤后保留 {len(cases)} 个用例 (filter={','.join(selected_case_ids)})"})

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
                llm_judge, case_dir,
                stages=stages, dry_run=dry_run,
                skip_baseline=skip_baseline,
                only_run_baseline=only_run_baseline,
                on_progress=on_progress,
                phase_weights=phase_weights,
                baseline_agent=baseline_agent,
                enhanced_agent=enhanced_agent,
                comparison_labels=comparison_labels,
                active_sides=active_sides,
                agent_timeout=agent_timeout,
                agent_temperature=agent_temperature,
            )
            futures[future] = (i, case)

        for future in concurrent.futures.as_completed(futures):
            i, case = futures[future]
            try:
                result = future.result()
                gain = result.get("gain")
                if gain is None and result.get("side_b_total") is not None and result.get("side_a_total") is not None:
                    gain = result.get("side_b_total", 0) - result.get("side_a_total", 0)
                _notify(on_progress, "case_done", {
                    "case_id": result["case_id"],
                    "title": result["title"],
                    "index": i + 1,
                    "total": len(cases),
                    "scenario": scenario,
                    "side_a_total": result.get("side_a_total"),
                    "side_b_total": result.get("side_b_total"),
                    "gain": gain,
                })
                results.append(result)
            except Exception as e:
                failed_result = {
                    "case_id": case["id"],
                    "title": case.get("title", case["id"]),
                    "scenario": scenario,
                    "status": "error",
                    "error": str(e),
                    "side_a_rule": 0,
                    "side_b_rule": None if only_run_baseline else 0,
                    "side_a_total": 0,
                    "side_b_total": None if only_run_baseline else 0,
                    "gain": None,
                    "dimension_scores": {},
                    "compile_results": {
                        "side_a_compilable": None,
                        "side_a_error": "",
                        "side_b_compilable": None,
                        "side_b_error": "",
                    },
                }
                _notify(on_progress, "error", {
                    "case_id": case["id"],
                    "message": str(e),
                })
                results.append(failed_result)

    _notify(on_progress, "scenario_done", {
        "scenario": scenario,
        "case_count": len(results),
    })
    return results
