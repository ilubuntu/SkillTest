# -*- coding: utf-8 -*-
"""单 agent 用例执行。"""

import concurrent.futures
import json
import os
import subprocess
import time
from typing import Callable

from agent_bench.pipeline.artifacts import (
    agent_meta_dir,
    agent_workspace_dir,
    load_runner_artifacts,
    save_case_result,
    save_interaction_metrics,
    save_runner_artifacts,
)
from agent_bench.pipeline.compile_checker import prepare_project_workspace
from agent_bench.pipeline.loader import (
    build_agent_runtime_enhancements,
    load_agent_defaults,
    load_enhancements,
    load_test_cases,
    merge_enhancements,
    resolve_case_original_project,
)
from agent_bench.runner.factory import create_adapter

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

TASK_PROMPT = """{prompt}"""
TASK_PROMPT_MULTI_PAGE = """{prompt}

## 参考补充文件
{additional_pages}
"""

MAX_LOGGED_PROMPT_CHARS = 4000
MAX_LOGGED_OUTPUT_CHARS = 1000
_SKILL_DISCOVERY_CACHE: dict[str, bool] = {}


def _notify(on_progress, event: str, data: dict):
    if on_progress:
        on_progress(event, data)


def _clip_text(text: str, limit: int) -> str:
    text = text or ""
    return text if len(text) <= limit else text[:limit] + "\n...<truncated>"


def _resolve_agent_timeout(agent: dict, fallback_timeout: int) -> int:
    raw_timeout = (agent or {}).get("timeout")
    try:
        timeout = int(raw_timeout)
        return timeout if timeout > 0 else fallback_timeout
    except (TypeError, ValueError):
        return fallback_timeout


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


def _log_skill_mount_status(case_id: str, agent_label: str, enhancements: dict, on_progress):
    return


def _opencode_has_skill(skill_name: str) -> bool:
    cached = _SKILL_DISCOVERY_CACHE.get(skill_name)
    if cached is not None:
        return cached
    try:
        result = subprocess.run(
            ["opencode", "debug", "skill"],
            capture_output=True,
            text=True,
            timeout=10,
            check=False,
        )
        if result.returncode != 0:
            _SKILL_DISCOVERY_CACHE[skill_name] = False
            return False
        payload = json.loads(result.stdout or "[]")
        found = any(
            isinstance(item, dict) and str(item.get("name") or "").strip() == skill_name
            for item in (payload if isinstance(payload, list) else [])
        )
        _SKILL_DISCOVERY_CACHE[skill_name] = found
        return found
    except Exception:
        _SKILL_DISCOVERY_CACHE[skill_name] = False
        return False


def _try_mount_opencode_skill(skill_name: str, enhancements: dict, on_progress) -> bool:
    _notify(on_progress, "log", {
        "level": "WARNING",
        "message": f"{skill_name} 当前未实现自动挂载，跳过挂载尝试",
    })
    return False


def _log_skill_runtime_discovery(agent_label: str, enhancements: dict, on_progress):
    skill_names = [
        str(item.get("name") or "").strip()
        for item in (enhancements.get("skills") or [])
        if isinstance(item, dict) and str(item.get("name") or "").strip()
    ]
    if "build-harmony-project" not in skill_names:
        return
    skill_name = "build-harmony-project"
    _notify(on_progress, "log", {
        "level": "WARNING",
        "message": f"{agent_label} skill 检测开始: 正在检查 OpenCode 是否正确配置 {skill_name}",
    })
    if _opencode_has_skill(skill_name):
        _notify(on_progress, "log", {
            "level": "INFO",
            "message": f"{agent_label} skill 检测完成: OpenCode 已正确配置 {skill_name}",
        })
        return
    _notify(on_progress, "log", {
        "level": "ERROR",
        "message": f"{agent_label} skill 初次检测结果: OpenCode 未正确配置 {skill_name}",
    })
    if _try_mount_opencode_skill(skill_name, enhancements, on_progress):
        _SKILL_DISCOVERY_CACHE.pop(skill_name, None)
        if _opencode_has_skill(skill_name):
            _notify(on_progress, "log", {
                "level": "INFO",
                "message": f"{agent_label} skill 检测完成: 尝试挂载后 OpenCode 已正确配置 {skill_name}",
            })
            return
    _notify(on_progress, "log", {
        "level": "ERROR",
        "message": f"{agent_label} skill 检测完成: 尝试挂载后 OpenCode 仍未正确配置 {skill_name}",
    })


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
            "message": f"{agent_label} 输出中观察到 build-harmony-project 调用标记",
        })
        return
    _notify(on_progress, "log", {
        "level": "WARNING",
        "message": f"{agent_label} 输出中未观察到 build-harmony-project 调用标记",
    })


def _log_skill_call_detection(case_id: str, agent_label: str, case_dir: str, stage: str, output_text: str, on_progress):
    metrics = _load_stage_interaction_metrics(case_dir, stage)
    raw = metrics.get("raw") or {}
    message_info = raw.get("message_info") or {}
    raw_parts = message_info.get("parts") if isinstance(message_info.get("parts"), list) else []
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
            "message": f"{agent_label} 在 interaction_metrics 中观察到 build-harmony-project 调用痕迹，事件={summary}",
        })
        return
    _log_compile_self_check_signal(case_id, agent_label, output_text, on_progress)


def _build_task_prompt(case: dict, prompt: str, on_progress, case_id: str) -> str:
    additional_files = case.get("additional_files", {}) or {}
    sibling_files = additional_files.get("sibling_files", {}) or {}
    pages_files = additional_files.get("pages", {}) or {}
    if sibling_files or pages_files:
        all_additional = {**sibling_files, **pages_files}
        additional_pages_text = "\n\n".join(
            f"=== {filename} ===\n{content}" for filename, content in all_additional.items()
        )
        _notify(on_progress, "log", {
            "level": "INFO",
            "message": f"多页面场景：检测到 {len(all_additional)} 个额外页面文件",
        })
        return TASK_PROMPT_MULTI_PAGE.format(prompt=prompt, additional_pages=additional_pages_text)
    return TASK_PROMPT.format(prompt=prompt)


def _log_agent_configuration(agent: dict, enhancements: dict, on_progress):
    mounted_skills = [
        str(item.get("name") or "").strip()
        for item in (agent.get("mounted_skills") or [])
        if isinstance(item, dict) and str(item.get("name") or "").strip()
    ]
    _notify(on_progress, "log", {
        "level": "INFO",
        "message": "，".join(
            part for part in [
                f"读取 Agent 配置: 名称={agent.get('name') or ''}",
                f"适配器={agent.get('adapter') or ''}",
                f"模型={agent.get('model') or ''}",
                f"skills={', '.join(mounted_skills)}" if mounted_skills else "",
            ] if part
        ),
    })

    if mounted_skills:
        _notify(on_progress, "log", {
            "level": "WARNING",
            "message": f"检测 Agent 是否正确挂载 skill: {', '.join(mounted_skills)}",
        })


def _build_runner_only_result(case: dict, case_dir: str, agent: dict) -> dict:
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
        "compile_results": {
            "compilable": None,
            "error": "",
        },
    }


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
    case_id = case["id"]
    prompt = case["prompt"]
    task_prompt = _build_task_prompt(case, prompt, on_progress, case_id)
    os.makedirs(case_dir, exist_ok=True)
    _notify(on_progress, "log", {"level": "INFO", "message": f"开始处理用例: {case['title']}"})

    agent = agent_config
    if not agent:
        raise ValueError("缺少 agent 配置")

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
            runtime_enhancements = merge_enhancements(build_agent_runtime_enhancements(agent), enhancements or {})
            timeout = _resolve_agent_timeout(agent, agent_timeout)
            adapter = create_adapter(agent, timeout=timeout, on_progress=on_progress, temperature=agent_temperature)
            try:
                _notify(on_progress, "log", {"level": "WARNING", "message": f"开始准备 {agent.get('name') or '执行Agent'} 运行配置..."})
                _log_agent_configuration(agent, runtime_enhancements, on_progress)
                _log_skill_runtime_discovery(agent.get("name") or "执行Agent", runtime_enhancements, on_progress)
                _notify(on_progress, "stage_start", {"case_id": case_id, "stage": "Agent运行"})
                adapter.setup(runtime_enhancements, on_progress=on_progress)
                _notify(on_progress, "log", {"level": "WARNING", "message": f"{agent.get('name') or '执行Agent'} 准备完成，开始处理任务..."})
                t0 = time.time()
                output_text = adapter.execute(task_prompt, tag=f"[{agent.get('name') or 'Agent'}] ", workspace_dir=workspace_dir)
            finally:
                save_interaction_metrics(case_dir, "agent", adapter.get_last_interaction_metrics())
                adapter.teardown()
            elapsed = time.time() - t0
            save_runner_artifacts(case_dir, output_text, task_prompt=task_prompt)
            _notify(on_progress, "log", {"level": "WARNING", "message": f"{agent.get('name') or '执行Agent'} 运行完成, 输出={len(output_text)}字符, 耗时={elapsed:.1f}s"})
            if output_text:
                _notify(on_progress, "log", {"level": "WARNING", "message": f"{agent.get('name') or '执行Agent'} 输出预览:\n{_clip_text(output_text, MAX_LOGGED_OUTPUT_CHARS)}"})
            _log_skill_call_detection(case_id, agent.get("name") or "执行Agent", case_dir, "agent", output_text, on_progress)
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
