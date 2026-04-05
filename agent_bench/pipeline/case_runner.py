# -*- coding: utf-8 -*-
"""单 agent 用例执行。"""

import concurrent.futures
import json
import os
import shutil
import subprocess
import time
from typing import Callable

from agent_bench.agent_runtime import AgentRuntime, build_agent_spec, build_agent_task_prompt
from agent_bench.pipeline.artifacts import (
    agent_meta_dir,
    agent_workspace_dir,
    original_project_dir,
    review_dir,
    load_runner_artifacts,
    save_compile_artifacts,
    save_case_result,
    save_interaction_metrics,
    save_runner_artifacts,
)
from agent_bench.pipeline.compile_checker import check_project_compilable, prepare_project_workspace
from agent_bench.pipeline.loader import (
    load_agent_defaults,
    load_enhancements,
    load_test_cases,
    resolve_case_original_project,
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

MAX_LOGGED_PROMPT_CHARS = 4000
MAX_LOGGED_OUTPUT_CHARS = 1000
WORKSPACE_GITIGNORE = """build/
.hvigor/
oh_modules/
node_modules/
oh-package-lock.json5
*.log
"""


def _notify(on_progress, event: str, data: dict):
    if on_progress:
        on_progress(event, data)


def _clip_text(text: str, limit: int) -> str:
    text = text or ""
    return text if len(text) <= limit else text[:limit] + "\n...<truncated>"


def _get_case_upload_root(case: dict) -> str:
    cached = str((case or {}).get("_upload_root") or "").strip()
    if cached:
        return cached
    upload_root = "agent_execution"
    case["_upload_root"] = upload_root
    return upload_root


def _build_case_stage_object_name(case: dict, stage_name: str) -> str:
    upload_root = _get_case_upload_root(case)
    case_id = str(case.get("id") or "case").strip()
    safe_stage = str(stage_name or "").strip().lower()
    return f"{upload_root}/{safe_stage}/{case_id}.zip"


def _upload_original_project(case: dict, on_progress: Callable = None) -> str:
    if not HAS_STORAGE_UPLOADER:
        return ""
    original_project_dir = case.get("original_project_dir")
    if not original_project_dir or not os.path.exists(original_project_dir):
        return ""
    try:
        object_name = _build_case_stage_object_name(case, "original")
        _notify(on_progress, "log", {
            "level": "INFO",
            "message": f"[{case['id']}] 正在上传 original_project: {object_name}",
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
        result = uploader.upload_directory(original_project_dir, object_name=object_name)
        upload_url = result.get("download_url") or result.get("url") or ""
        _notify(on_progress, "log", {
            "level": "INFO",
            "message": f"[{case['id']}] original_project 上传成功: {upload_url}",
        })
        return upload_url
    except Exception as exc:
        _notify(on_progress, "log", {
            "level": "ERROR",
            "message": f"[{case['id']}] original_project 上传失败: {exc}",
        })
        return ""


def _load_stage_interaction_metrics(case_dir: str, stage: str) -> dict:
    metrics_path = os.path.join(agent_meta_dir(case_dir), "interaction_metrics.json") if stage == "agent" else ""
    if not metrics_path or not os.path.exists(metrics_path):
        return {}
    try:
        with open(metrics_path, "r", encoding="utf-8") as f:
            return json.load(f) or {}
    except Exception:
        return {}


def _log_compile_self_check_signal(case_id: str, agent_label: str, output_text: str, on_progress):
    marker = "[[BUILD_HARMONY_PROJECT_CALLED]]"
    if marker in (output_text or ""):
        _notify(on_progress, "log", {
            "level": "WARNING",
            "message": f"{agent_label} 模型输出中自报已调用 build-harmony-project",
        })
        return
    _notify(on_progress, "log", {
        "level": "WARNING",
        "message": f"{agent_label} 未观察到显式 skill 事件，且模型输出中未包含 build-harmony-project 调用标记",
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


def _log_skill_call_detection(case_id: str, agent_label: str, case_dir: str, stage: str, output_text: str, on_progress):
    metrics = _load_stage_interaction_metrics(case_dir, stage)
    raw = metrics.get("raw") or {}
    message_info = raw.get("message_info") or {}
    raw_parts = message_info.get("parts") if isinstance(message_info.get("parts"), list) else []
    explicit_skill_matches = []
    compile_command_matches = []
    for part in raw_parts:
        if not isinstance(part, dict):
            continue
        serialized = json.dumps(part, ensure_ascii=False).lower()
        part_type = str(part.get("type") or "unknown")
        if part_type in {"tool", "skill"} and "build-harmony-project" in serialized:
            explicit_skill_matches.append(part_type)
            continue
        if any(token in serialized for token in ("hvigor", "assemblehap", "--stop-daemon")):
            compile_command_matches.append(part_type)
    if explicit_skill_matches:
        summary = ",".join(str(item) for item in explicit_skill_matches[:3])
        _notify(on_progress, "log", {
        "level": "WARNING",
            "message": f"{agent_label} 在 interaction_metrics 中观察到 build-harmony-project 明确调用痕迹，事件={summary}",
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
    _log_compile_self_check_signal(case_id, agent_label, output_text, on_progress)
def _build_runner_only_result(case: dict, case_dir: str, agent: dict) -> dict:
    post_compile_result = case.get("_post_compile_result") or {}
    pre_compile_result = case.get("_pre_compile_result") or {}
    return {
        "case_id": case["id"],
        "title": case["title"],
        "scenario": case.get("scenario"),
        "status": "completed",
        "score": None,
        "agent": {
            "id": agent.get("id") or "",
            "name": agent.get("name") or "",
            "adapter": agent.get("adapter") or "",
            "model": agent.get("model") or "",
        },
        "workspace_dir": agent_workspace_dir(case_dir),
        "meta_dir": agent_meta_dir(case_dir),
        "original_dir": original_project_dir(case_dir),
        "review_dir": review_dir(case_dir),
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
    review_root = review_dir(case_dir)
    os.makedirs(review_root, exist_ok=True)
    gitignore_path = os.path.join(workspace_dir, ".gitignore")
    with open(gitignore_path, "w", encoding="utf-8") as f:
        f.write(WORKSPACE_GITIGNORE)
    _notify(on_progress, "log", {"level": "INFO", "message": f"已写入工作区 Git 忽略规则: {gitignore_path}"})

    subprocess.run(["git", "init"], cwd=workspace_dir, capture_output=True, text=True, check=False)
    subprocess.run(["git", "config", "user.name", "agent-bench"], cwd=workspace_dir, capture_output=True, text=True, check=False)
    subprocess.run(["git", "config", "user.email", "agent-bench@example.local"], cwd=workspace_dir, capture_output=True, text=True, check=False)
    subprocess.run(["git", "add", "."], cwd=workspace_dir, capture_output=True, text=True, check=False)
    commit_result = subprocess.run(
        ["git", "commit", "-m", "baseline"],
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
    baseline_commit = str(rev_result.stdout or "").strip()
    if not baseline_commit:
        raise RuntimeError("未能读取 workspace 基线 commit")
    baseline_commit_path = os.path.join(review_root, "baseline_commit.txt")
    with open(baseline_commit_path, "w", encoding="utf-8") as f:
        f.write(baseline_commit + "\n")
    _notify(on_progress, "log", {"level": "INFO", "message": f"工作区 Git 基线已建立: {baseline_commit}"})
    return baseline_commit


def _generate_review_patch(case_dir: str, workspace_dir: str, baseline_commit: str, on_progress):
    review_root = review_dir(case_dir)
    os.makedirs(review_root, exist_ok=True)
    patch_path = os.path.join(review_root, "changes.patch")
    diff_result = subprocess.run(
        ["git", "diff", "--binary", baseline_commit],
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
    _notify(on_progress, "log", {"level": "WARNING", "message": f"[开始] {stage_label}"})
    t0 = time.time()
    compile_result = check_project_compilable(
        project_path,
        timeout=300,
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
    return compile_result


def run_single_case(case: dict, scenario: str, enhancements: dict,
                    llm_judge,
                    case_dir: str,
                    stages: list = None,
                    dry_run: bool = False,
                    on_progress: Callable = None,
                    phase_weights: dict = None,
                    agent_config: dict = None,
                    agent_timeout: int = 180,
                    agent_temperature: float = None) -> dict:
    _ = (llm_judge, phase_weights, scenario)
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
            baseline_commit = _initialize_workspace_git(case_dir, workspace_dir, on_progress)
            pre_compile_result = _run_compile_check(
                case,
                case_dir,
                workspace_dir,
                "pre_compile_check",
                "预编译验证",
                on_progress,
            )
            case["_pre_compile_result"] = pre_compile_result
            runtime = AgentRuntime(
                agent_spec=agent_spec,
                enhancements=enhancements,
                on_progress=on_progress,
                fallback_timeout=agent_timeout,
                temperature=agent_temperature,
            )
            try:
                _notify(on_progress, "stage_start", {"case_id": case_id, "stage": "Agent运行"})
                runtime.prepare()
                output_text, elapsed = runtime.execute(
                    task_prompt,
                    workspace_dir=workspace_dir,
                    tag=f"[{agent_spec.display_name}] ",
                )
                last_error_message = runtime.get_last_error_message()
                if not output_text and last_error_message:
                    raise RuntimeError(last_error_message)
            finally:
                save_interaction_metrics(case_dir, "agent", runtime.get_last_interaction_metrics())
                runtime.teardown()
            save_runner_artifacts(case_dir, output_text, task_prompt=task_prompt)
            _notify(on_progress, "log", {"level": "WARNING", "message": f"{agent_spec.display_name} 运行完成, 输出={len(output_text)}字符, 耗时={elapsed:.1f}s"})
            if output_text:
                _notify(on_progress, "log", {"level": "WARNING", "message": f"{agent_spec.display_name} 输出预览:\n{_clip_text(output_text, MAX_LOGGED_OUTPUT_CHARS)}"})
            post_compile_result = _run_compile_check(
                case,
                case_dir,
                workspace_dir,
                "post_compile_check",
                "Agent 修改后编译验证",
                on_progress,
            )
            case["_post_compile_result"] = post_compile_result
            _generate_review_patch(case_dir, workspace_dir, baseline_commit, on_progress)
            _log_skill_call_detection(case_id, agent_spec.display_name, case_dir, "agent", output_text, on_progress)
            _notify(on_progress, "stage_done", {"case_id": case_id, "stage": "Agent运行", "elapsed": elapsed})

    result = _build_runner_only_result(case, case_dir, agent)
    save_case_result(case_dir, result)
    return result


def run_scenario(scenario: str,
                 llm_judge,
                 output_dir: str,
                 profile_name: str = None,
                 stages: list = None,
                 max_workers: int = 1,
                 dry_run: bool = False,
                 case_id_filter: str = None,
                 case_ids: list = None,
                 on_progress: Callable = None,
                 phase_weights: dict = None,
                 agent_config: dict = None,
                 agent_compare_mode: bool = False) -> list:
    _ = (llm_judge, phase_weights)
    stages = stages or ["runner"]
    enhancements = {} if agent_compare_mode else load_enhancements(scenario, profile_name=profile_name)
    agent_defaults = load_agent_defaults()
    agent_timeout = agent_defaults.get("timeout", 180)
    agent_temperature = agent_defaults.get("temperature")
    cases = load_test_cases(scenario)
    selected_case_ids = case_ids or []
    if not selected_case_ids and case_id_filter:
        selected_case_ids = [item.strip() for item in str(case_id_filter).split(",") if item.strip()]
    if selected_case_ids:
        selected = set(selected_case_ids)
        cases = [c for c in cases if c["id"] in selected]
    _notify(on_progress, "scenario_start", {"scenario": scenario, "case_count": len(cases)})
    if not cases:
        _notify(on_progress, "scenario_done", {"scenario": scenario, "case_count": 0})
        return []

    if HAS_STORAGE_UPLOADER:
        upload_root = os.path.basename(os.path.abspath(output_dir.rstrip(os.sep)))
        for case in cases:
            case["_upload_root"] = upload_root
            _upload_original_project(case, on_progress=on_progress)

    agent = agent_config
    if not agent:
        raise ValueError("缺少 agent 配置")

    results = []
    futures = {}
    with concurrent.futures.ThreadPoolExecutor(max_workers=max_workers) as executor:
        for i, case in enumerate(cases):
            case_dir = os.path.join(output_dir, "cases", case["id"])
            future = executor.submit(
                run_single_case,
                case,
                scenario,
                enhancements,
                None,
                case_dir,
                stages=stages,
                dry_run=dry_run,
                agent_config=agent,
                agent_timeout=agent_timeout,
                agent_temperature=agent_temperature,
                on_progress=on_progress,
            )
            futures[future] = (i, case)

        for future in concurrent.futures.as_completed(futures):
            i, case = futures[future]
            try:
                result = future.result()
                _notify(on_progress, "case_done", {
                    "case_id": result["case_id"],
                    "title": result["title"],
                    "index": i + 1,
                    "total": len(cases),
                    "scenario": scenario,
                    "score": result.get("score"),
                })
                results.append(result)
            except Exception as exc:
                failed_result = {
                    "case_id": case["id"],
                    "title": case.get("title", case["id"]),
                    "scenario": scenario,
                    "status": "error",
                    "error": str(exc),
                    "score": None,
                    "compile_results": {
                        "compilable": None,
                        "error": "",
                    },
                }
                _notify(on_progress, "error", {"case_id": case["id"], "message": str(exc)})
                results.append(failed_result)

    _notify(on_progress, "scenario_done", {"scenario": scenario, "case_count": len(results)})
    return results
