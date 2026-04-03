# -*- coding: utf-8 -*-
"""用例执行

职责：
- 单用例执行（run_single_case）：编排 Runner → Compile → Evaluator
- 场景执行（run_scenario）：并行调度多个用例

Runner 阶段通过 AgentAdapter 与 Agent 交互：
- A 侧运行：adapter.setup(agent_enhancements) → 在 side_a 工程中直接修改文件
- B 侧运行：adapter.setup(agent_enhancements + scenario_enhancements) → 在 side_b 工程中直接修改文件
"""

import concurrent.futures
import json
import os
import re
import time
from typing import Callable

from agent_bench.runner.factory import create_adapter
from agent_bench.evaluator.llm_judge import LLMJudge
from agent_bench.evaluator import internal_scorer, aggregator
from agent_bench.evaluator.constraint_scorer import (
    build_constraint_review_skill,
    evaluate_constraints,
    build_constraint_review_report,
    append_constraint_review_report,
    strip_constraint_review_report,
)

from agent_bench.pipeline.loader import (
    load_test_cases, load_enhancements,
    load_internal_rules, load_rubric, resolve_case_original_project, load_agent_defaults,
    build_agent_runtime_enhancements, merge_enhancements,
)
from agent_bench.pipeline.artifacts import (
    save_runner_artifacts, load_runner_artifacts,
    save_evaluator_artifacts,
    save_interaction_metrics,
    save_constraint_review_artifacts,
    save_compile_artifacts,
    save_rule_check_artifact,
    save_case_result,
    stage_dir, stage_meta_dir, META_DIR_NAME,
)
from agent_bench.pipeline.compile_checker import (
    prepare_project_workspace,
    check_project_compilable,
)

try:
    from agent_bench.storage_uploader import AgcStorageUploader
    HAS_STORAGE_UPLOADER = True
except ImportError:
    HAS_STORAGE_UPLOADER = False


AGC_BUCKET_NAME = "agent-bench-lpgvk"
AGC_PROJECT_CLIENT_CONFIG = {
    "type": "project_client_id",
    "developer_id": "900086000150224722",
    "project_id": "101653523863785276",
    "client_id": "1919775246739619200",
    "client_secret": "D1A9970837E38AAB4B7D4AFBDCAEC1B0D6511662C7026DAE1808298342F9192C",
    "configuration_version": "3.0",
    "region": "CN",
}


def _get_case_upload_root(case: dict) -> str:
    cached = str((case or {}).get("_upload_root") or "").strip()
    if cached:
        return cached
    upload_root = "agent_compare"
    case["_upload_root"] = upload_root
    return upload_root


def _build_case_stage_object_name(case: dict, stage_name: str) -> str:
    upload_root = _get_case_upload_root(case)
    case_id = str(case.get("id") or "case").strip()
    safe_stage = str(stage_name or "").strip().lower()
    return f"{upload_root}/{safe_stage}/{case_id}.zip"


def _upload_original_project(case: dict, on_progress: Callable = None) -> str:
    """上传用例的 original_project 到云存储

    Returns:
        上传成功后的 download_url；无需上传或上传失败时返回空字符串
    """
    if not HAS_STORAGE_UPLOADER:
        return ""

    original_project_dir = case.get("original_project_dir")
    if not original_project_dir:
        return ""

    if not os.path.exists(original_project_dir):
        _notify(on_progress, "log", {
            "level": "WARN",
            "message": f"[{case['id']}] original_project 不存在，跳过上传: {original_project_dir}"
        })
        return ""

    try:
        object_name = _build_case_stage_object_name(case, "original")
        _notify(on_progress, "log", {
            "level": "INFO",
            "message": f"[{case['id']}] 正在上传 original_project: {object_name}"
        })

        uploader = AgcStorageUploader(
            **{
                "project_id": AGC_PROJECT_CLIENT_CONFIG["project_id"],
                "client_id": AGC_PROJECT_CLIENT_CONFIG["client_id"],
                "client_secret": AGC_PROJECT_CLIENT_CONFIG["client_secret"],
                "developer_id": AGC_PROJECT_CLIENT_CONFIG["developer_id"],
                "credential_type": AGC_PROJECT_CLIENT_CONFIG["type"],
                "region": AGC_PROJECT_CLIENT_CONFIG["region"],
                "bucket_name": AGC_BUCKET_NAME,
            },
        )
        result = uploader.upload_directory(
            original_project_dir,
            object_name=object_name,
        )
        upload_url = result.get("download_url") or result.get("url") or ""
        _notify(on_progress, "log", {
            "level": "INFO",
            "message": f"[{case['id']}] original_project 上传成功: {object_name} | url={upload_url}"
        })
        return upload_url
    except Exception as e:
        _notify(on_progress, "log", {
            "level": "ERROR",
            "message": f"[{case['id']}] original_project 上传失败: {e}"
        })
        return ""


# ── 任务 Prompt 模板 ─────────────────────────────────────────

TASK_PROMPT = """{prompt}"""

TASK_PROMPT_MULTI_PAGE = """{prompt}

## 参考补充文件
{additional_pages}
"""

MAX_LOGGED_PROMPT_CHARS = 4000
MAX_LOGGED_OUTPUT_CHARS = 1000


def _resolve_agent_timeout(agent: dict, fallback_timeout: int) -> int:
    raw_timeout = (agent or {}).get("timeout")
    try:
        timeout = int(raw_timeout)
        return timeout if timeout > 0 else fallback_timeout
    except (TypeError, ValueError):
        return fallback_timeout


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
    case_dir = os.path.dirname(side_dir)
    changed_path = os.path.join(stage_meta_dir(case_dir, os.path.basename(side_dir)), "changed_files.json")
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


def _clip_text(text: str, limit: int) -> str:
    text = text or ""
    return text if len(text) <= limit else text[:limit] + "\n...<truncated>"


def _append_dynamic_skill(enhancements: dict, skill_payload: dict):
    if not skill_payload:
        return enhancements
    result = dict(enhancements or {})
    skills = list(result.get("skills") or [])
    skills.append(skill_payload)
    result["skills"] = skills
    return result


def _should_attach_constraint_skill(agent_config: dict) -> bool:
    adapter = str((agent_config or {}).get("adapter") or "").strip().lower()
    return adapter not in {"codex_local", "codex_http"}


def _log_skill_mount_status(case_id: str, side_label: str, enhancements: dict, on_progress):
    skills = [item.get("name", "unknown") for item in (enhancements.get("skills") or []) if isinstance(item, dict)]
    if not skills:
        return
    compile_loop_enabled = "hvigor" in (enhancements.get("system_prompt") or "").lower()
    extra = "，已注入编译循环约束" if compile_loop_enabled else ""
    _notify(on_progress, "log", {
        "level": "WARNING",
        "message": f"[{case_id}] {side_label} 已挂载 skill: {', '.join(skills)}{extra}"
    })


def _log_compile_self_check_signal(case_id: str, side_label: str, output_text: str, on_progress):
    marker = "[[BUILD_HARMONY_PROJECT_CALLED]]"
    if marker in (output_text or ""):
        _notify(on_progress, "log", {
            "level": "WARNING",
            "message": f"[{case_id}] {side_label} 输出中观察到 build-harmony-project 调用标记"
        })
        return

    _notify(on_progress, "log", {
        "level": "WARNING",
        "message": f"[{case_id}] {side_label} 输出中未观察到 build-harmony-project 调用标记"
    })


def _load_stage_interaction_metrics(case_dir: str, stage: str) -> dict:
    metrics_path = os.path.join(stage_meta_dir(case_dir, stage), "interaction_metrics.json")
    if not os.path.exists(metrics_path):
        return {}
    try:
        with open(metrics_path, "r", encoding="utf-8") as f:
            return json.load(f) or {}
    except Exception:
        return {}


def _log_skill_call_detection(case_id: str, side_label: str, case_dir: str, stage: str, output_text: str, on_progress):
    metrics = _load_stage_interaction_metrics(case_dir, stage)
    raw = metrics.get("raw") or {}
    raw_parts = []
    message_info = raw.get("message_info") or {}
    if isinstance(message_info, dict) and isinstance(message_info.get("parts"), list):
        raw_parts.extend(message_info.get("parts") or [])
    if isinstance(raw.get("parts"), list):
        raw_parts.extend(raw.get("parts") or [])

    matched_entries = []
    for part in raw_parts:
        if not isinstance(part, dict):
            continue
        serialized = json.dumps(part, ensure_ascii=False).lower()
        if "build-harmony-project" in serialized or '"type": "skill"' in serialized or '"tool"' in serialized:
            matched_entries.append(part.get("type") or "unknown")

    if matched_entries:
        summary = ",".join(str(item) for item in matched_entries[:3])
        _notify(on_progress, "log", {
            "level": "WARNING",
            "message": f"[{case_id}] {side_label} 在 interaction_metrics 中观察到 build-harmony-project 调用痕迹，事件={summary}"
        })
        return

    _log_compile_self_check_signal(case_id, side_label, output_text, on_progress)


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
        stages: 要执行的阶段列表，默认 ["runner"]
        dry_run: 干跑模式
        skip_baseline: 跳过基线运行
        on_progress: 进度回调

    Returns:
        用例结果 dict
    """
    stages = stages or ["runner"]
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

    if prompt:
        prompt_preview = prompt[:MAX_LOGGED_PROMPT_CHARS]
        if len(prompt) > MAX_LOGGED_PROMPT_CHARS:
            prompt_preview += "\n...<truncated>"
        _notify(on_progress, "log", {
            "level": "WARN",
            "message": f"[{case_id}] Case Prompt:\n{prompt_preview}"
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
        side_a_path = os.path.join(stage_meta_dir(case_dir, "side_a"), "output.txt")
        side_b_path = os.path.join(stage_meta_dir(case_dir, "side_b"), "output.txt")
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

    result = _build_runner_only_result(
        case_id=case_id,
        title=title,
        scenario=case.get("scenario", scenario),
        only_run_baseline=only_run_baseline,
    )
    save_case_result(case_dir, result)

    return result


def _build_compile_only_result(case_id: str,
                               title: str,
                               scenario: str,
                               compile_results: dict,
                               only_run_baseline: bool) -> dict:
    side_a_compilable = bool((compile_results or {}).get("side_a_compilable"))
    side_b_compilable_value = (compile_results or {}).get("side_b_compilable")
    side_b_compilable = bool(side_b_compilable_value) if side_b_compilable_value is not None else None

    side_a_total = 100 if side_a_compilable else 0
    side_b_total = None if only_run_baseline else (100 if side_b_compilable else 0)
    gain = None if only_run_baseline or side_b_total is None else side_b_total - side_a_total

    result = {
        "case_id": case_id,
        "title": title,
        "scenario": scenario,
        "side_a_rule": None,
        "side_b_rule": None if only_run_baseline else None,
        "side_a_total": side_a_total,
        "side_b_total": side_b_total,
        "gain": gain,
        "dimension_scores": {},
        "compile_results": compile_results or {},
    }
    if str(scenario).lower().replace(" ", "_") == "general":
        result["general_pass"] = side_a_compilable
    return result


def _build_runner_only_result(case_id: str,
                              title: str,
                              scenario: str,
                              only_run_baseline: bool) -> dict:
    return {
        "case_id": case_id,
        "title": title,
        "scenario": scenario,
        "side_a_rule": None,
        "side_b_rule": None if only_run_baseline else None,
        "side_a_total": None,
        "side_b_total": None if only_run_baseline else None,
        "gain": None,
        "dimension_scores": {},
    }


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
    side_a_label = (comparison_labels or {}).get("side_a") or (comparison_labels or {}).get("baseline", "基线Agent")
    side_b_label = (comparison_labels or {}).get("side_b") or (comparison_labels or {}).get("enhanced", "评测Agent")
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

    # general 场景：当前调试阶段不做编译验证，直接跳过
    if is_general_case:
        prepare_project_workspace(template_project_path, side_a_dir)
        _notify(on_progress, "log", {"level": "WARNING", "message": f"[{case_id}] 通用用例：当前已跳过编译验证，仅保留工程准备"})
        _notify(on_progress, "stage_done", {"case_id": case_id, "stage": "A侧运行", "elapsed": 0, "skipped": True})
        return "", "", compile_results

    scenario_key = (scenario or "").lower().replace(" ", "_")
    should_compile = False
    side_a_enhancements = build_agent_runtime_enhancements(baseline_agent or enhanced_agent)
    side_b_enhancements = merge_enhancements(
        build_agent_runtime_enhancements(enhanced_agent or baseline_agent),
        enhancements or {},
    )
    # ── A 侧运行 ──
    if dry_run:
        prepare_project_workspace(template_project_path, side_a_dir)
        side_a_output = "// dry run - no output"
        _notify(on_progress, "stage_done", {"case_id": case_id, "stage": "A侧运行", "elapsed": 0, "skipped": True})
    elif skip_baseline:
        prepare_project_workspace(template_project_path, side_a_dir)
        side_a_output = ""
        _notify(on_progress, "log", {"level": "WARNING", "message": f"[{case_id}] 跳过 {side_a_label} 运行 (skip_baseline)"})
        _notify(on_progress, "stage_done", {"case_id": case_id, "stage": "A侧运行", "elapsed": 0, "skipped": True})
    else:
        prepare_project_workspace(template_project_path, side_a_dir)
        baseline_agent_config = baseline_agent or enhanced_agent
        baseline_timeout = _resolve_agent_timeout(baseline_agent_config, agent_timeout)
        baseline_adapter = create_adapter(
            baseline_agent_config,
            timeout=baseline_timeout,
            on_progress=on_progress,
            temperature=agent_temperature,
        )
        try:
            _notify(on_progress, "stage_start", {"case_id": case_id, "stage": "A侧运行"})
            _notify(on_progress, "log", {"level": "WARNING", "message": f"[{case_id}] 配置 {side_a_label} 运行..."})
            _log_skill_mount_status(case_id, side_a_label, side_a_enhancements, on_progress)
            baseline_adapter.setup(side_a_enhancements, on_progress=on_progress)
            _notify(on_progress, "log", {"level": "WARNING", "message": f"[{case_id}] 开始 {side_a_label} 运行..."})
            _notify(on_progress, "log", {"level": "DEBUG",
                "message": f"[{case_id}] Task Prompt={len(task_prompt)}字符, workspace={side_a_dir}, timeout={baseline_timeout}s"})
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
        _notify(on_progress, "log", {"level": "WARNING",
            "message": f"[{case_id}] {side_a_label} 运行完成, 输出={len(side_a_output)}字符, 耗时={elapsed:.1f}s"})
        if side_a_output:
            _notify(on_progress, "log", {
                "level": "WARNING",
                "message": f"[{case_id}] {side_a_label} 输出预览:\n{_clip_text(side_a_output, MAX_LOGGED_OUTPUT_CHARS)}"
            })
        _log_skill_call_detection(case_id, side_a_label, case_dir, "side_a", side_a_output, on_progress)
        
        _notify(on_progress, "stage_done", {"case_id": case_id, "stage": "A侧运行", "elapsed": elapsed})

    # ── B 侧运行 ──
    if only_run_baseline:
        side_b_output = ""
        compile_results["side_b_compilable"] = None
        compile_results["side_b_error"] = ""
        _notify(on_progress, "log", {"level": "WARNING", "message": f"[{case_id}] 仅运行 {side_a_label}，{side_b_label} 跳过执行"})
        _notify(on_progress, "stage_done", {"case_id": case_id, "stage": "B侧运行", "elapsed": 0, "skipped": True})
    elif dry_run:
        prepare_project_workspace(template_project_path, side_b_dir)
        side_b_output = "// dry run - no output"
        _notify(on_progress, "stage_done", {"case_id": case_id, "stage": "B侧运行", "elapsed": 0, "skipped": True})
    else:
        prepare_project_workspace(template_project_path, side_b_dir)
        enhanced_agent_config = enhanced_agent or baseline_agent
        enhanced_timeout = _resolve_agent_timeout(enhanced_agent_config, agent_timeout)
        enhanced_adapter = create_adapter(
            enhanced_agent_config,
            timeout=enhanced_timeout,
            on_progress=on_progress,
            temperature=agent_temperature,
        )
        try:
            _notify(on_progress, "stage_start", {"case_id": case_id, "stage": "B侧运行"})
            _notify(on_progress, "log", {"level": "WARNING", "message": f"[{case_id}] 配置 {side_b_label} 运行..."})
            _log_skill_mount_status(case_id, side_b_label, side_b_enhancements, on_progress)
            enhanced_adapter.setup(side_b_enhancements, on_progress=on_progress)
            _notify(on_progress, "log", {"level": "WARNING", "message": f"[{case_id}] 开始 {side_b_label} 运行..."})
            _notify(on_progress, "log", {"level": "DEBUG",
                "message": f"[{case_id}] Task Prompt={len(task_prompt)}字符, workspace={side_b_dir}, timeout={enhanced_timeout}s"})
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
        _notify(on_progress, "log", {"level": "WARNING",
            "message": f"[{case_id}] {side_b_label} 运行完成, 输出={len(side_b_output)}字符, 耗时={elapsed:.1f}s"})
        if side_b_output:
            _notify(on_progress, "log", {
                "level": "WARNING",
                "message": f"[{case_id}] {side_b_label} 输出预览:\n{_clip_text(side_b_output, MAX_LOGGED_OUTPUT_CHARS)}"
            })
        _log_skill_call_detection(case_id, side_b_label, case_dir, "side_b", side_b_output, on_progress)
        
        _notify(on_progress, "stage_done", {"case_id": case_id, "stage": "B侧运行", "elapsed": elapsed})

    return side_a_output, side_b_output, compile_results


def _compile_single_side(case_id: str,
                         stage_name: str,
                         side_dir: str,
                         template_project_path: str,
                         side_label: str,
                         result_key: str,
                         compile_results: dict,
                         case_dir: str,
                         artifact_stage: str,
                         on_progress):
    _notify(on_progress, "stage_start", {"case_id": case_id, "stage": stage_name})
    _notify(on_progress, "log", {"level": "WARNING", "message": f"[{case_id}] 检查 {side_label} 工程可编译性..."})
    t0 = time.time()
    compile_result = check_project_compilable(side_dir, template_project_path=template_project_path)
    elapsed = time.time() - t0
    save_compile_artifacts(case_dir, artifact_stage, compile_result)
    compile_results[f"{result_key}_compilable"] = compile_result["compilable"]
    compile_results[f"{result_key}_error"] = compile_result.get("error", "")
    if not compile_result["compilable"]:
        error_text = compile_result.get("error", "未知错误")
        _notify(on_progress, "log", {
            "level": "WARNING",
            "message": f"[{case_id}] {side_label} 完整编译失败原因见下方详情",
            "detail": error_text,
        })
        stage_status = "error"
    else:
        _notify(on_progress, "log", {"level": "WARNING", "message": f"[{case_id}] {side_label} 工程可编译"})
        stage_status = "done"
    _notify(on_progress, "stage_done", {"case_id": case_id, "stage": stage_name, "elapsed": elapsed, "status": stage_status})


def _warmup_single_side(case_id: str,
                        side_dir: str,
                        side_label: str,
                        on_progress):
    """在 agent 修改前先预编译一次工程，预热依赖和缓存。

    这是性能优化步骤，不参与最终结果判定，也不写正式编译产物。
    """
    _notify(on_progress, "log", {
        "level": "WARNING",
        "message": f"[{case_id}] 开始预编译预热 {side_label} 工程..."
    })
    t0 = time.time()
    compile_result = check_project_compilable(side_dir)
    elapsed = time.time() - t0
    if compile_result.get("compilable"):
        _notify(on_progress, "log", {
            "level": "WARNING",
            "message": f"[{case_id}] {side_label} 工程预编译完成 ({elapsed:.1f}s)"
        })
    else:
        _notify(on_progress, "log", {
            "level": "WARNING",
            "message": f"[{case_id}] {side_label} 工程预编译失败，但继续执行 Agent ({elapsed:.1f}s)",
            "detail": compile_result.get("error", "") or "未知错误",
        })


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
    side_a_label = (comparison_labels or {}).get("side_a") or "基线Agent"
    side_b_label = (comparison_labels or {}).get("side_b") or "评测Agent"

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
    stages = stages or ["runner"]

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

    agent_defaults = load_agent_defaults()
    agent_timeout = agent_defaults.get("timeout", 180)
    agent_temperature = agent_defaults.get("temperature")

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

    if HAS_STORAGE_UPLOADER:
        upload_root = os.path.basename(os.path.abspath(output_dir.rstrip(os.sep)))
        for case in cases:
            case["_upload_root"] = upload_root
        _notify(on_progress, "log", {"level": "INFO",
            "message": f"开始上传 {len(cases)} 个用例的 original_project 到目录 {upload_root} 下的 original"})
        for case in cases:
            _upload_original_project(case, on_progress=on_progress)

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
