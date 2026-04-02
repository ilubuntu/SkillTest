# -*- coding: utf-8 -*-
"""云测桥接执行管理器。"""

import json
import os
import shutil
import tempfile
import threading
import time
import urllib.parse
import urllib.request
import zipfile
from datetime import datetime
from typing import Any, Dict, Optional

from agent_bench.cloud_api.client import report_status, upload_execution_result
from agent_bench.cloud_api.converter import (
    CLOUD_SCORE_RUBRIC,
    build_case,
    build_execution_result_payload,
    build_prompt,
    build_status_payload,
    is_placeholder_text,
    load_side_output,
    load_side_scoring_text,
    load_template_case_defaults,
    map_internal_status_to_remote,
    stage_to_local_status,
)
from agent_bench.cloud_api.models import CloudExecutionStartRequest, RemoteExecutionStatus
from agent_bench.evaluator.llm_judge import LLMJudge
from agent_bench.pipeline.case_runner import run_single_case
from agent_bench.pipeline.loader import load_agent, load_agent_defaults, load_config
from agent_bench.runner.opencode_adapter import OpenCodeAdapter

RESULTS_ROOT = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "results", "cloud_api")


def _now_iso() -> str:
    return datetime.now().isoformat(timespec="seconds")


def _safe_json(data: Any) -> str:
    try:
        return json.dumps(data, ensure_ascii=False, indent=2)
    except Exception:
        return str(data)


def _build_cloud_llm_judge(on_progress=None) -> LLMJudge:
    config = load_config()
    agent_defaults = load_agent_defaults()
    judge_config = config.get("judge", {}) or {}
    judge_adapter = OpenCodeAdapter(
        api_base=agent_defaults.get("api_base", "http://localhost:4096"),
        model=judge_config.get("model"),
        timeout=int(judge_config.get("timeout") or 300),
        temperature=judge_config.get("temperature", 0),
        on_progress=on_progress,
    )
    return LLMJudge(
        llm_fn=lambda prompt, tag: judge_adapter.execute(prompt, tag=tag),
        on_progress=on_progress,
        metrics_fn=lambda: judge_adapter.get_last_interaction_metrics(),
    )


def _score_cloud_case(case_dir: str,
                      case: Dict[str, Any],
                      prompt: str,
                      expected_output: str,
                      on_progress=None) -> Dict[str, Any]:
    side = "side_a"
    scoring_text = load_side_scoring_text(case_dir, side, case, fallback_output=load_side_output(case_dir, side))
    if not scoring_text.strip():
        raise ValueError("缺少可用于评分的代码或输出内容")

    judge = _build_cloud_llm_judge(on_progress=on_progress)
    task_context = prompt
    if expected_output.strip():
        task_context = f"{prompt}\n\n期望结果：{expected_output}"

    result = judge.judge_baseline(
        task_context=task_context,
        baseline_code=scoring_text,
        rubric=CLOUD_SCORE_RUBRIC,
        case_id=case.get("id", "cloud_case"),
        case_dir=case_dir,
    )
    score_map = {item.name: int(round(item.score)) for item in result.dimensions}
    return {
        "code_quality_score": score_map.get("代码质量"),
        "expected_output_score": score_map.get("期望结果符合度"),
        "weighted_avg": int(round(result.weighted_avg)),
    }


def _download_file(file_url: str, target_path: str):
    parsed = urllib.parse.urlparse(file_url)
    if parsed.scheme in ("http", "https", "file"):
        with urllib.request.urlopen(file_url, timeout=60) as response, open(target_path, "wb") as f:
            shutil.copyfileobj(response, f)
        return

    if os.path.exists(file_url):
        shutil.copyfile(file_url, target_path)
        return

    raise FileNotFoundError(f"无法访问 fileUrl: {file_url}")


def _looks_like_project_root(path: str) -> bool:
    markers = [
        os.path.join(path, "entry", "src", "main"),
        os.path.join(path, "build-profile.json5"),
        os.path.join(path, "hvigorfile.ts"),
    ]
    return any(os.path.exists(marker) for marker in markers)


def _find_project_root(search_root: str) -> str:
    if _looks_like_project_root(search_root):
        return search_root

    candidates = []
    for current_root, dirs, _files in os.walk(search_root):
        if _looks_like_project_root(current_root):
            depth = current_root.count(os.sep)
            candidates.append((depth, current_root))
    if candidates:
        candidates.sort(key=lambda item: item[0])
        return candidates[0][1]
    raise FileNotFoundError(f"未在下载内容中找到可执行工程目录: {search_root}")


def _prepare_project_from_file_url(file_url: str, target_dir: str) -> str:
    os.makedirs(target_dir, exist_ok=True)
    parsed = urllib.parse.urlparse(file_url)

    if not parsed.scheme and os.path.isdir(file_url):
        return _find_project_root(file_url)

    archive_path = os.path.join(target_dir, "source.zip")
    _download_file(file_url, archive_path)

    if not zipfile.is_zipfile(archive_path):
        raise ValueError(f"当前仅支持 zip 类型工程包: {file_url}")

    extract_dir = os.path.join(target_dir, "extracted")
    os.makedirs(extract_dir, exist_ok=True)
    with zipfile.ZipFile(archive_path, "r") as zip_ref:
        zip_ref.extractall(extract_dir)

    return _find_project_root(extract_dir)


class CloudExecutionManager:
    def __init__(self):
        self._lock = threading.Lock()
        self._states: Dict[int, Dict[str, Any]] = {}
        self._active_execution_id: Optional[int] = None
        self._worker_thread: Optional[threading.Thread] = None

    def start(self, payload: CloudExecutionStartRequest, local_base_url: str):
        with self._lock:
            if self._worker_thread and self._worker_thread.is_alive():
                return False, "当前已有云测执行任务运行中"

            state = {
                "execution_id": payload.executionId,
                "cloud_base_url": payload.cloudBaseUrl.rstrip("/"),
                "agent_id": payload.agentId,
                "test_case": payload.testCase.model_dump(),
                "local_status": "pending",
                "local_stage": "preparing",
                "error_message": "",
                "conversation": [],
                "created_at": _now_iso(),
                "updated_at": _now_iso(),
                "run_dir": "",
                "case_dir": "",
                "output_code_url": "",
                "reporting_side": "side_a",
                "last_status_payload": None,
                "last_status_response": None,
                "last_result_payload": None,
                "last_result_response": None,
            }
            self._states[payload.executionId] = state
            self._active_execution_id = payload.executionId

            thread = threading.Thread(
                target=self._run_execution,
                args=(payload, local_base_url),
                daemon=True,
            )
            self._worker_thread = thread
            thread.start()
            return True, "任务已接收"

    def get_state(self, execution_id: Optional[int] = None) -> Optional[Dict[str, Any]]:
        with self._lock:
            if execution_id is None:
                if self._active_execution_id is not None:
                    execution_id = self._active_execution_id
                elif self._states:
                    execution_id = list(sorted(self._states.keys()))[-1]
            if execution_id is None:
                return None
            state = self._states.get(execution_id)
            if not state:
                return None
            return json.loads(json.dumps(state))

    def _append_conversation(self, state: Dict[str, Any], item_type: str, message: str, level: str = "INFO"):
        state["conversation"].append({
            "timestamp": _now_iso(),
            "type": item_type,
            "level": level,
            "message": message,
        })
        state["conversation"] = state["conversation"][-200:]
        state["updated_at"] = _now_iso()

    def _payload_dir(self, state: Dict[str, Any]) -> str:
        run_dir = state.get("run_dir") or RESULTS_ROOT
        payload_dir = os.path.join(run_dir, "cloud_payloads")
        os.makedirs(payload_dir, exist_ok=True)
        return payload_dir

    def _persist_local_payload(self, state: Dict[str, Any], filename: str, payload: Dict[str, Any]) -> str:
        payload_dir = self._payload_dir(state)
        path = os.path.join(payload_dir, filename)
        with open(path, "w", encoding="utf-8") as f:
            json.dump(payload, f, ensure_ascii=False, indent=2)
        return path

    def _report_remote_status(self, state: Dict[str, Any]):
        remote_status = map_internal_status_to_remote(state.get("local_status"))
        payload = build_status_payload(remote_status, state.get("error_message"))
        if state["cloud_base_url"]:
            response = report_status(state["cloud_base_url"], state["execution_id"], payload)
        else:
            latest_path = self._persist_local_payload(state, "status_report_latest.json", payload)
            history_path = os.path.join(self._payload_dir(state), "status_report_history.jsonl")
            with open(history_path, "a", encoding="utf-8") as f:
                f.write(json.dumps(payload, ensure_ascii=False) + "\n")
            response = {
                "ok": True,
                "mode": "local_file",
                "latest_path": latest_path,
                "history_path": history_path,
            }
        state["last_status_payload"] = payload
        state["last_status_response"] = response
        state["last_status_file"] = response.get("latest_path")
        state["updated_at"] = _now_iso()

    def _run_execution(self, payload: CloudExecutionStartRequest, local_base_url: str):
        execution_id = payload.executionId
        started_at = time.time()
        with self._lock:
            state = self._states[execution_id]

        def update_local_status(status: str, stage: Optional[str] = None):
            with self._lock:
                state["local_status"] = status
                if stage:
                    state["local_stage"] = stage
                state["updated_at"] = _now_iso()

        def on_progress(event: str, data: Dict[str, Any]):
            should_push_running = False
            with self._lock:
                current = self._states[execution_id]
                if event == "log":
                    message = data.get("message", "")
                    self._append_conversation(current, "log", message, data.get("level", "INFO"))
                elif event == "stage_start":
                    stage = stage_to_local_status(data.get("stage", ""))
                    if stage:
                        current["local_stage"] = stage
                    self._append_conversation(current, "stage_start", data.get("stage", ""))
                    should_push_running = True
                elif event == "stage_done":
                    stage = stage_to_local_status(data.get("stage", ""))
                    if stage and data.get("status") == "error":
                        current["local_stage"] = "failed"
                    self._append_conversation(current, "stage_done", f"{data.get('stage', '')}:{data.get('status', 'done')}")
                    should_push_running = True
                elif event == "error":
                    current["error_message"] = data.get("message", "")
                    current["local_stage"] = "failed"
                    self._append_conversation(current, "error", data.get("message", ""), "ERROR")
                elif event == "case_done":
                    self._append_conversation(current, "case_done", data.get("case_id", ""))
                current["updated_at"] = _now_iso()
            if should_push_running:
                self._report_remote_status(state)

        try:
            update_local_status("running", "preparing")
            with self._lock:
                self._append_conversation(state, "status", "任务开始执行")
            self._report_remote_status(state)

            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            run_dir = os.path.join(RESULTS_ROOT, f"execution_{execution_id}_{timestamp}")
            source_dir = os.path.join(run_dir, "source")
            case_dir = os.path.join(run_dir, "case")
            os.makedirs(run_dir, exist_ok=True)

            project_root = _prepare_project_from_file_url(payload.testCase.fileUrl, source_dir)
            template_defaults = load_template_case_defaults("bug_fix_001")
            raw_input = (payload.testCase.input or "").strip()
            raw_expected_output = (payload.testCase.expectedOutput or "").strip()
            input_text = template_defaults.get("prompt", "") if is_placeholder_text(raw_input) else raw_input
            expected_output = (
                template_defaults.get("output_requirements", "")
                if is_placeholder_text(raw_expected_output) else raw_expected_output
            )
            if not input_text.strip() or not expected_output.strip():
                raise ValueError("缺少真实的任务输入或期望结果，已终止执行")
            prompt = build_prompt(input_text, expected_output)
            case = build_case(execution_id, project_root, prompt)

            with self._lock:
                state["run_dir"] = run_dir
                state["case_dir"] = case_dir
                self._append_conversation(state, "prepare", f"工程已就绪: {project_root}")

            defaults = load_agent_defaults()
            default_timeout = int(defaults.get("timeout") or 480)
            default_temperature = defaults.get("temperature")

            baseline_agent = load_agent(payload.agentId or "")
            if not baseline_agent:
                raise ValueError("必须选择一个可用 agent")
            candidate_agent = None
            only_run_baseline = True
            comparison_labels = {
                "side_a": baseline_agent.get("name") or "执行Agent",
                "side_b": "",
            }
            active_sides = ["side_a"]

            result = run_single_case(
                case=case,
                scenario="cloud_api",
                enhancements={},
                llm_judge=None,
                case_dir=case_dir,
                stages=["runner"],
                dry_run=False,
                skip_baseline=False,
                only_run_baseline=only_run_baseline,
                on_progress=on_progress,
                baseline_agent=baseline_agent,
                enhanced_agent=candidate_agent,
                comparison_labels=comparison_labels,
                active_sides=active_sides,
                agent_timeout=default_timeout,
                agent_temperature=default_temperature,
            )

            output_code_url = f"{local_base_url.rstrip('/')}/api/cloud-api/executions/{execution_id}/output-code"
            result_payload = build_execution_result_payload(
                execution_id=execution_id,
                case_dir=case_dir,
                result=result,
                expected_output=expected_output,
                execution_time_ms=int((time.time() - started_at) * 1000),
                output_code_url=output_code_url,
                code_quality_score=None,
                expected_output_score=None,
            )

            try:
                with self._lock:
                    self._append_conversation(state, "status", "开始模型评分")
                llm_scores = _score_cloud_case(
                    case_dir=case_dir,
                    case=case,
                    prompt=input_text,
                    expected_output=expected_output,
                    on_progress=on_progress,
                )
                result_payload["data"]["codeQualityScore"] = llm_scores.get("code_quality_score") or 0
                result_payload["data"]["expectedOutputScore"] = llm_scores.get("expected_output_score") or 0
                with self._lock:
                    state["llm_scores"] = llm_scores
                    self._append_conversation(
                        state,
                        "status",
                        f"模型评分完成: codeQualityScore={result_payload['data']['codeQualityScore']}, expectedOutputScore={result_payload['data']['expectedOutputScore']}",
                    )
            except Exception as exc:
                with self._lock:
                    state["llm_scores_error"] = str(exc)
                    self._append_conversation(state, "error", f"模型评分失败，回退本地规则: {exc}", "WARNING")

            with self._lock:
                state["output_code_url"] = output_code_url
                state["reporting_side"] = "side_a"
                state["result"] = result
                state["last_result_payload"] = result_payload

            if state["cloud_base_url"]:
                result_response = upload_execution_result(state["cloud_base_url"], result_payload)
            else:
                result_path = self._persist_local_payload(state, "execution_result.json", result_payload)
                result_response = {
                    "ok": True,
                    "mode": "local_file",
                    "path": result_path,
                }
            with self._lock:
                state["last_result_response"] = result_response
                state["last_result_file"] = result_response.get("path")

            update_local_status("completed", "completed")
            with self._lock:
                self._append_conversation(state, "status", "任务执行完成")
            self._report_remote_status(state)
        except Exception as exc:
            with self._lock:
                state["error_message"] = str(exc)
                self._append_conversation(state, "error", str(exc), "ERROR")
            update_local_status("failed", "failed")
            self._report_remote_status(state)
        finally:
            with self._lock:
                self._active_execution_id = None


cloud_execution_manager = CloudExecutionManager()
