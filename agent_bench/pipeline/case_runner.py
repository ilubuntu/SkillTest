# -*- coding: utf-8 -*-
"""单 agent 用例执行。"""

import json
import os
import shutil
import subprocess
import time
from typing import Callable

from agent_bench.common.default_constants import DEFAULT_TIMEOUT_SECONDS
from agent_bench.pipeline.artifacts import (
    agent_meta_dir,
    agent_workspace_dir,
    diff_dir,
    original_project_dir,
    load_runner_artifacts,
    save_compile_artifacts,
    save_case_result,
    save_interaction_metrics,
    save_runner_artifacts,
)
from agent_bench.pipeline.compile_checker import check_project_compilable, prepare_project_workspace
from agent_bench.pipeline.loader import (
    resolve_case_original_project,
)
from agent_bench.pipeline.prompts import (
    build_agent_task_prompt,
)
from agent_bench.agent_runner import AgentRunner, build_agent_spec

MAX_LOGGED_OUTPUT_CHARS = 1000
WORKSPACE_GIT_EXCLUDE = """build/
.hvigor/
oh_modules/
node_modules/
oh-package-lock.json5
.opencode/
opencode.json
*.log
BuildProfile.ets
"""


def _notify(on_progress, event: str, data: dict):
    if on_progress:
        on_progress(event, data)


def _clip_text(text: str, limit: int) -> str:
    text = text or ""
    return text if len(text) <= limit else text[:limit] + "\n...<truncated>"


def _coerce_int(value):
    try:
        if value is None or value == "":
            return None
        return int(value)
    except Exception:
        return None


def _metrics_derived(metrics: dict) -> dict:
    if not isinstance(metrics, dict):
        return {}
    derived = metrics.get("derived")
    return derived if isinstance(derived, dict) else {}


def _metrics_http(metrics: dict) -> dict:
    if not isinstance(metrics, dict):
        return {}
    http = metrics.get("http")
    return http if isinstance(http, dict) else {}


def _metrics_message_parts(metrics: dict) -> list[dict]:
    http = _metrics_http(metrics)
    message_info = http.get("message_info") if isinstance(http, dict) else {}
    parts = message_info.get("parts") if isinstance(message_info, dict) else []
    return parts if isinstance(parts, list) else []


def _extract_cumulative_usage(metrics: dict) -> dict:
    http = _metrics_http(metrics)
    message_history = http.get("message_history") if isinstance(http.get("message_history"), list) else []
    if message_history:
        totals = {
            "input_tokens": 0,
            "output_tokens": 0,
            "reasoning_tokens": 0,
            "cache_read_tokens": 0,
            "cache_write_tokens": 0,
        }
        seen_any = False
        for msg in message_history:
            if not isinstance(msg, dict):
                continue
            info = msg.get("info") if isinstance(msg.get("info"), dict) else {}
            tokens = info.get("tokens") if isinstance(info.get("tokens"), dict) else {}
            if not tokens:
                continue
            seen_any = True
            totals["input_tokens"] += int(tokens.get("input", 0) or 0)
            totals["output_tokens"] += int(tokens.get("output", 0) or 0)
            totals["reasoning_tokens"] += int(tokens.get("reasoning", 0) or 0)
            cache = tokens.get("cache") if isinstance(tokens.get("cache"), dict) else {}
            totals["cache_read_tokens"] += int(cache.get("read", 0) or 0)
            totals["cache_write_tokens"] += int(cache.get("write", 0) or 0)
        if seen_any:
            return totals

    usage = _metrics_derived(metrics).get("usage") if isinstance(metrics, dict) else {}
    if not isinstance(usage, dict):
        return {}
    return {
        "input_tokens": _coerce_int(usage.get("input_tokens")),
        "output_tokens": _coerce_int(usage.get("output_tokens")),
        "reasoning_tokens": _coerce_int(usage.get("reasoning_tokens")),
        "cache_read_tokens": _coerce_int(usage.get("cache_read_tokens")),
        "cache_write_tokens": _coerce_int(usage.get("cache_write_tokens")),
    }


def _format_usage_suffix(metrics: dict) -> str:
    usage = _extract_cumulative_usage(metrics)
    if not isinstance(usage, dict) or not usage:
        return ""
    input_tokens = _coerce_int(usage.get("input_tokens"))
    output_tokens = _coerce_int(usage.get("output_tokens"))
    reasoning_tokens = _coerce_int(usage.get("reasoning_tokens"))
    cache_read_tokens = _coerce_int(usage.get("cache_read_tokens"))
    cache_write_tokens = _coerce_int(usage.get("cache_write_tokens"))
    values = [
        value
        for value in (
            input_tokens,
            output_tokens,
            reasoning_tokens,
            cache_read_tokens,
            cache_write_tokens,
        )
        if value is not None
    ]
    if not values:
        return ""
    total_tokens = sum(values)
    segments = [f"tokens={total_tokens}"]
    if input_tokens is not None:
        segments.append(f"in={input_tokens}")
    if output_tokens is not None:
        segments.append(f"out={output_tokens}")
    if reasoning_tokens is not None:
        segments.append(f"reasoning={reasoning_tokens}")
    if cache_read_tokens is not None:
        segments.append(f"cache_read={cache_read_tokens}")
    if cache_write_tokens is not None:
        segments.append(f"cache_write={cache_write_tokens}")
    return ", " + ", ".join(segments)


def _format_completion_message(prefix: str, output_text: str, elapsed: float, metrics: dict) -> str:
    output_chars = len(output_text or "")
    return f"{prefix}, output={output_chars} chars, elapsed={elapsed:.1f}s{_format_usage_suffix(metrics)}"


def _load_stage_interaction_metrics(case_dir: str, stage: str) -> dict:
    metrics_path = ""
    legacy_metrics_path = ""
    if stage == "agent":
        metrics_path = os.path.join(agent_meta_dir(case_dir), "agent_interaction_metrics.json")
        legacy_metrics_path = os.path.join(agent_meta_dir(case_dir), "interaction_metrics.json")
    if not metrics_path or not os.path.exists(metrics_path):
        metrics_path = legacy_metrics_path
    if not metrics_path or not os.path.exists(metrics_path):
        return {}
    try:
        with open(metrics_path, "r", encoding="utf-8") as f:
            return json.load(f) or {}
    except Exception:
        return {}


def _log_compile_self_check_signal(case_id: str,
                                   agent_label: str,
                                   output_text: str,
                                   on_progress,
                                   target_skills: list[str] | None = None):
    normalized_output = (output_text or "").lower()
    expected_skills = [
        str(name or "").strip().lower()
        for name in (target_skills or [])
        if str(name or "").strip()
    ]
    matched = [name for name in expected_skills if name in normalized_output]
    if matched:
        _notify(on_progress, "log", {
            "level": "WARNING",
            "message": f"{agent_label} 模型输出中自报已调用预期 skill: {', '.join(matched)}",
        })
        return
    _notify(on_progress, "log", {
        "level": "WARNING",
        "message": f"{agent_label} 未观察到显式 skill 事件，且模型输出中未包含预期 skill 调用标记",
    })


def _find_generated_hap_files(case_dir: str, stage: str) -> list[str]:
    workspace_dir = agent_workspace_dir(case_dir) if stage == "agent" else ""
    if not workspace_dir or not os.path.isdir(workspace_dir):
        return []
    hap_files = []
    for root, _, files in os.walk(workspace_dir):
        for name in files:
            if name.lower().endswith(".hap"):
                hap_files.append(os.path.join(root, name))
    return hap_files


def _log_skill_call_detection(case_id: str,
                              agent_label: str,
                              case_dir: str,
                              stage: str,
                              output_text: str,
                              on_progress,
                              target_skills: list[str] | None = None):
    metrics = _load_stage_interaction_metrics(case_dir, stage)
    raw_parts = _metrics_message_parts(metrics)
    explicit_skill_matches = []
    compile_command_matches = []
    expected_skills = [
        str(name or "").strip().lower()
        for name in (target_skills or [])
        if str(name or "").strip()
    ]
    for part in raw_parts:
        if not isinstance(part, dict):
            continue
        serialized = json.dumps(part, ensure_ascii=False).lower()
        part_type = str(part.get("type") or "unknown")
        matched_skill = next((name for name in expected_skills if name in serialized), "")
        if part_type in {"tool", "skill"} and matched_skill:
            explicit_skill_matches.append(f"{part_type}:{matched_skill}")
            continue
        if "build-harmony-project" in expected_skills and any(token in serialized for token in ("hvigor", "assemblehap", "--stop-daemon")):
            compile_command_matches.append(part_type)
    if explicit_skill_matches:
        summary = ",".join(str(item) for item in explicit_skill_matches[:3])
        _notify(on_progress, "log", {
            "level": "WARNING",
            "message": f"{agent_label} 在 interaction_metrics 中观察到预期 skill 明确调用痕迹，事件={summary}",
        })
        return
    if compile_command_matches:
        summary = ",".join(str(item) for item in compile_command_matches[:3])
        _notify(on_progress, "log", {
            "level": "WARNING",
            "message": f"{agent_label} 在 interaction_metrics 中观察到 HarmonyOS 编译命令痕迹，事件={summary}",
        })
        return
    hap_files = _find_generated_hap_files(case_dir, stage)
    if hap_files:
        rel_files = [os.path.relpath(path, agent_workspace_dir(case_dir)) for path in hap_files[:2]]
        _notify(on_progress, "log", {
            "level": "WARNING",
            "message": f"{agent_label} 未观察到显式 skill 事件，但检测到真实编译产物: {', '.join(rel_files)}",
        })
        return
    _log_compile_self_check_signal(case_id, agent_label, output_text, on_progress, expected_skills)
def _build_runner_only_result(case: dict, case_dir: str, agent: dict) -> dict:
    post_compile_result = case.get("_post_compile_result") or {}
    pre_compile_result = case.get("_pre_compile_result") or {}
    return {
        "case_id": case["id"],
        "title": case["title"],
        "scenario": case.get("scenario"),
        "status": "completed",
        "agent_elapsed_s": case.get("_agent_elapsed_s"),
        "agent": {
            "id": agent.get("id") or "",
            "name": agent.get("name") or "",
            "model": agent.get("model") or "",
        },
        "workspace_dir": agent_workspace_dir(case_dir),
        "meta_dir": agent_meta_dir(case_dir),
        "original_dir": original_project_dir(case_dir),
        "compile_results": {
            "compilable": post_compile_result.get("compilable"),
            "error": post_compile_result.get("error", "") or "",
            "before": pre_compile_result or {},
            "after": post_compile_result or {},
            "regressed": (
                bool(pre_compile_result.get("compilable"))
                and post_compile_result.get("compilable") is False
            ),
        },
    }


def _initialize_workspace_git(case_dir: str, workspace_dir: str, on_progress):
    patch_root = diff_dir(case_dir)
    os.makedirs(patch_root, exist_ok=True)
    subprocess.run(["git", "init"], cwd=workspace_dir, capture_output=True, text=True, check=False)
    subprocess.run(["git", "config", "user.name", "agent-bench"], cwd=workspace_dir, capture_output=True, text=True, check=False)
    subprocess.run(["git", "config", "user.email", "agent-bench@example.local"], cwd=workspace_dir, capture_output=True, text=True, check=False)
    git_exclude_path = os.path.join(workspace_dir, ".git", "info", "exclude")
    os.makedirs(os.path.dirname(git_exclude_path), exist_ok=True)
    with open(git_exclude_path, "w", encoding="utf-8") as f:
        f.write(WORKSPACE_GIT_EXCLUDE)
    _notify(on_progress, "log", {"level": "INFO", "message": f"已写入工作区 Git 本地排除规则: {git_exclude_path}"})
    subprocess.run(["git", "add", "."], cwd=workspace_dir, capture_output=True, text=True, check=False)
    commit_result = subprocess.run(
        ["git", "commit", "--allow-empty", "-m", "workspace_base"],
        cwd=workspace_dir,
        capture_output=True,
        text=True,
        check=False,
    )
    if commit_result.returncode != 0:
        raise RuntimeError(f"初始化工作区 Git 基线失败: {commit_result.stderr or commit_result.stdout}")
    rev_result = subprocess.run(
        ["git", "rev-parse", "HEAD"],
        cwd=workspace_dir,
        capture_output=True,
        text=True,
        check=False,
    )
    workspace_base_commit = str(rev_result.stdout or "").strip()
    if not workspace_base_commit:
        raise RuntimeError("未能读取 workspace 基线 commit")
    workspace_base_commit_path = os.path.join(patch_root, "commit.txt")
    with open(workspace_base_commit_path, "w", encoding="utf-8") as f:
        f.write(workspace_base_commit + "\n")
    _notify(on_progress, "log", {"level": "INFO", "message": f"工作区 Git 基线已建立: {workspace_base_commit}"})
    return workspace_base_commit


def _cleanup_workspace_runtime_files(workspace_dir: str, on_progress):
    removed = []
    for relative_path in [".opencode", "opencode.json"]:
        target_path = os.path.join(workspace_dir, relative_path)
        if os.path.isdir(target_path):
            shutil.rmtree(target_path, ignore_errors=True)
            removed.append(relative_path)
        elif os.path.exists(target_path):
            os.remove(target_path)
            removed.append(relative_path)
    if removed:
        _notify(on_progress, "log", {
            "level": "INFO",
            "message": f"已清理工作区运行时文件: {', '.join(removed)}",
        })


def _generate_review_patch(case_dir: str, workspace_dir: str, workspace_base_commit: str, on_progress):
    patch_root = diff_dir(case_dir)
    os.makedirs(patch_root, exist_ok=True)
    patch_path = os.path.join(patch_root, "changes.patch")
    _cleanup_workspace_runtime_files(workspace_dir, on_progress)
    add_result = subprocess.run(
        ["git", "add", "-A", "--", "."],
        cwd=workspace_dir,
        capture_output=True,
        text=True,
        check=False,
    )
    if add_result.returncode != 0:
        raise RuntimeError(f"暂存 workspace 变更失败: {add_result.stderr or add_result.stdout}")
    diff_result = subprocess.run(
        ["git", "diff", "--binary", workspace_base_commit],
        cwd=workspace_dir,
        capture_output=True,
        text=True,
        check=False,
    )
    if diff_result.returncode not in (0, 1):
        raise RuntimeError(f"生成 patch 失败: {diff_result.stderr or diff_result.stdout}")
    with open(patch_path, "w", encoding="utf-8") as f:
        f.write(diff_result.stdout or "")
    _notify(on_progress, "log", {"level": "INFO", "message": f"已生成评审 patch: {patch_path}"})
    return patch_path


def _run_compile_check(case: dict,
                       case_dir: str,
                       project_path: str,
                       stage_name: str,
                       stage_label: str,
                       on_progress):
    template_project_path = resolve_case_original_project(case)
    case_meta = case.get("case_spec") if isinstance(case.get("case_spec"), dict) else {}
    case_info = case_meta.get("case") if isinstance(case_meta.get("case"), dict) else {}
    _notify(on_progress, "stage_start", {"case_id": case["id"], "stage": stage_name})
    _notify(on_progress, "log", {
        "level": "INFO",
        "message": f"{stage_label} 已开始",
    })
    _notify(on_progress, "log", {"level": "WARNING", "message": f"[开始] {stage_label}"})
    if stage_name == "pre_compile_check" and bool(case_info.get("skip_pre_compile_check")):
        compile_result = {
            "compilable": False,
            "checked": False,
            "skipped": True,
            "error": "fileUrl 为空，空工程前置编译无意义，已跳过",
        }
        save_compile_artifacts(case_dir, stage_name, compile_result)
        _notify(on_progress, "log", {
            "level": "INFO",
            "message": "fileUrl为空，跳过预编译",
        })
        _notify(on_progress, "log", {
            "level": "INFO",
            "message": f"[结束] {stage_label}: 已跳过",
        })
        _notify(on_progress, "stage_done", {"case_id": case["id"], "stage": stage_name, "status": "skipped", "elapsed": 0})
        return compile_result
    t0 = time.time()
    compile_result = check_project_compilable(
        project_path,
        timeout=DEFAULT_TIMEOUT_SECONDS,
        template_project_path=template_project_path,
    )
    elapsed = time.time() - t0
    save_compile_artifacts(case_dir, stage_name, compile_result)
    if compile_result.get("compilable"):
        _notify(on_progress, "log", {
            "level": "INFO",
            "message": f"[结束] {stage_label}: 编译通过 ({elapsed:.1f}s)",
        })
    else:
        _notify(on_progress, "log", {
            "level": "ERROR",
            "message": f"[结束] {stage_label}: 编译失败 ({elapsed:.1f}s)",
        })
        error_preview = _clip_text(str(compile_result.get("error") or "").strip(), 1200)
        if error_preview:
            _notify(on_progress, "log", {
                "level": "ERROR",
                "message": f"{stage_label} 错误摘要:\n{error_preview}",
            })
    _notify(on_progress, "stage_done", {"case_id": case["id"], "stage": stage_name, "status": "done", "elapsed": elapsed})
    return compile_result


def run_single_case(case: dict,
                    case_dir: str,
                    stages: list = None,
                    dry_run: bool = False,
                    on_progress: Callable = None,
                    agent_config: dict = None,
                    agent_timeout: int = 180,
                    agent_temperature: float = None) -> dict:
    stages = stages or ["runner"]
    case["_agent_config"] = agent_config or {}
    case_id = case["id"]
    prompt = case["prompt"]
    os.makedirs(case_dir, exist_ok=True)
    _notify(on_progress, "log", {"level": "INFO", "message": f"开始处理用例: {case['title']}"})

    agent = agent_config
    if not agent:
        raise ValueError("缺少 agent 配置")
    agent_spec = build_agent_spec(agent)
    task_prompt = build_agent_task_prompt(case, prompt, on_progress, agent_spec)

    if "runner" in stages:
        output_path = os.path.join(agent_meta_dir(case_dir), "output.txt")
        if os.path.exists(output_path):
            _notify(on_progress, "log", {"level": "INFO", "message": "Runner 产物已存在，跳过 Agent 执行（复用缓存）"})
            output_text = load_runner_artifacts(case_dir)
        else:
            template_project_path = resolve_case_original_project(case)
            if not template_project_path:
                raise FileNotFoundError(f"[{case_id}] 未找到 original_project 模板")
            workspace_dir = agent_workspace_dir(case_dir)
            prepare_project_workspace(template_project_path, workspace_dir)
            workspace_base_commit = _initialize_workspace_git(case_dir, workspace_dir, on_progress)
            pre_compile_result = _run_compile_check(
                case,
                case_dir,
                workspace_dir,
                "pre_compile_check",
                "预编译验证",
                on_progress,
            )
            case["_pre_compile_result"] = pre_compile_result
            runtime = AgentRunner(
                agent_spec=agent_spec,
                runtime_options={},
                on_progress=on_progress,
                fallback_timeout=agent_timeout,
                artifact_prefix="agent",
                artifact_base_dir="generate",
            )
            try:
                _notify(on_progress, "stage_start", {"case_id": case_id, "stage": "generating"})
                runtime.prepare(workspace_dir=workspace_dir)
                output_text, elapsed = runtime.execute(
                    task_prompt,
                    workspace_dir=workspace_dir,
                    tag="",
                )
                last_error_message = runtime.get_last_error_message()
                if not output_text and last_error_message:
                    raise RuntimeError(last_error_message)
            finally:
                metrics = runtime.get_last_interaction_metrics()
                save_interaction_metrics(case_dir, "agent", metrics)
                runtime.teardown()
            save_runner_artifacts(case_dir, output_text, task_prompt=task_prompt)
            _notify(on_progress, "log", {
                "level": "WARNING",
                "message": _format_completion_message("Agent处理完成", output_text, elapsed, metrics),
            })
            if output_text:
                _notify(on_progress, "log", {"level": "WARNING", "message": f"{agent_spec.display_name} 输出预览:\n{_clip_text(output_text, MAX_LOGGED_OUTPUT_CHARS)}"})
            case["_agent_elapsed_s"] = int(elapsed)
            _notify(on_progress, "stage_done", {"case_id": case_id, "stage": "generating", "elapsed": elapsed})
            post_compile_result = _run_compile_check(
                case,
                case_dir,
                workspace_dir,
                "post_compile_check",
                "Agent 修改后编译验证",
                on_progress,
            )
            case["_post_compile_result"] = post_compile_result
            patch_path = _generate_review_patch(case_dir, workspace_dir, workspace_base_commit, on_progress)
            _notify(on_progress, "artifacts_ready", {
                "case_id": case_id,
                "workspace_dir": workspace_dir,
                "patch_path": patch_path,
            })
            # 当前主链只负责主修复 Agent 执行、产物准备和结果上报。
            # 约束打分与代码打分已从主流程移除，避免修复完成后继续阻塞。
            _log_skill_call_detection(
                case_id,
                agent_spec.display_name,
                case_dir,
                "agent",
                output_text,
                on_progress,
                [item.name for item in agent_spec.mounted_skills],
            )

    result = _build_runner_only_result(case, case_dir, agent)
    save_case_result(case_dir, result)
    return result
