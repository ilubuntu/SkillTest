# -*- coding: utf-8 -*-
"""任务管理器。"""

import json
import logging
import os
import shutil
import hashlib
import sys
import threading
import time
import urllib.parse
import urllib.request
import zipfile
from datetime import datetime
from typing import Any, Dict, Optional

from agent_bench.cloud_api.converter import (
    build_case,
    build_execution_result_payload,
    build_prompt,
)
from agent_bench.cloud_api.client import build_agent_log_url, upload_agent_log
from agent_bench.cloud_api.models import CloudExecutionStartRequest
from agent_bench.common.build_profile import sanitize_root_build_profile_signing_configs
from agent_bench.pipeline.case_runner import run_single_case
from agent_bench.pipeline.loader import load_agent, load_agents, load_config, load_logging_config
from agent_bench.pipeline.artifacts import agent_meta_dir, agent_workspace_dir, diff_dir, original_project_dir
from agent_bench.task_manager.artifacts import TaskArtifactUploader
from agent_bench.task_manager.file_queue import LocalTaskFileQueue
from agent_bench.task_manager.progress import TaskProgressTracker
from agent_bench.task_manager.registry import TaskRegistry
from agent_bench.task_manager.result_reporting import TaskResultReporter
from agent_bench.task_manager.state import create_task_state, now_iso


def _runtime_results_root() -> str:
    if getattr(sys, "frozen", False):
        base_dir = os.path.dirname(os.path.abspath(sys.executable))
    else:
        base_dir = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    return os.path.join(base_dir, "results")


RESULTS_ROOT = _runtime_results_root()
CACHE_ROOT = os.path.join(os.path.dirname(RESULTS_ROOT), "cache", "case_packages")
TASK_QUEUE_ROOT = os.path.join(os.path.dirname(RESULTS_ROOT), "taskqueue")

STATUS_PUSH_INTERVAL_SECONDS = 2.0
STATUS_PUSH_DETAIL_FLUSH_SECONDS = 3.0
logger = logging.getLogger("agent_bench.executor")

STAGE_PENDING = "pending"
STAGE_PREPARING = "preparing"
STAGE_GENERATING = "generating"
STAGE_VALIDATING = "validating"
STAGE_COMPLETED = "completed"


def _now_stage_time() -> str:
    return datetime.now().strftime("%Y%m%d-%H:%M:%S")

def _truncate_message(value: Any, limit: int = 100) -> str:
    text = str(value or "").strip()
    if len(text) <= limit:
        return text
    return text[:limit] + "..."


def _safe_json(data: Any) -> str:
    try:
        return json.dumps(data, ensure_ascii=False, indent=2)
    except Exception:
        return str(data)


def _emit_prepare_log(on_progress, message: str):
    if on_progress:
        on_progress("log", {"level": "INFO", "message": message})


def _executor_info_suffix(state: Dict[str, Any]) -> str:
    parts = [f"executor_id={state.get('execution_id')}"]
    request_host = str(state.get("request_host") or "").strip()
    executor_hostname = str(state.get("executor_hostname") or "").strip()
    if request_host:
        parts.append(f"request_host={request_host}")
    if executor_hostname:
        parts.append(f"hostname={executor_hostname}")
    return f" ({', '.join(parts)})"


def _cache_archive_path(file_url: str) -> str:
    parsed = urllib.parse.urlparse(file_url)
    suffix = os.path.splitext(parsed.path or "")[1] or ".zip"
    cache_key = hashlib.sha256(file_url.encode("utf-8")).hexdigest()
    os.makedirs(CACHE_ROOT, exist_ok=True)
    return os.path.join(CACHE_ROOT, f"{cache_key}{suffix}")


def _download_file(file_url: str, target_path: str, on_progress=None):
    parsed = urllib.parse.urlparse(file_url)
    if parsed.scheme in ("http", "https", "file"):
        _emit_prepare_log(on_progress, "缓存不存在，从网上下载工程包")
        _emit_prepare_log(on_progress, f"正在下载工程包: {file_url}")
        with urllib.request.urlopen(file_url, timeout=60) as response, open(target_path, "wb") as f:
            shutil.copyfileobj(response, f)
        _emit_prepare_log(on_progress, f"工程包下载完成: {target_path}")
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


def _extract_zip_with_normalized_paths(archive_path: str, extract_dir: str, on_progress=None):
    """
    兼容 Windows 打包出来的 zip。

    某些工程包内部文件名使用反斜杠 `\\` 作为分隔符。macOS/Linux 下如果直接
    `extractall()`，这些反斜杠会被当成普通字符，最终整个工程会被拍扁成一堆
    “文件名里带反斜杠”的文件，后续自然找不到 entry/src/main 这类目录结构。
    这里统一把 zip 条目路径规范化后再落盘。
    """
    with zipfile.ZipFile(archive_path, "r") as zip_ref:
        member_names = zip_ref.namelist()
        if any("\\" in name for name in member_names):
            _emit_prepare_log(on_progress, "检测到工程包使用 Windows 路径分隔符，按标准目录结构重建解压内容")
        for member in zip_ref.infolist():
            raw_name = member.filename or ""
            normalized_name = raw_name.replace("\\", "/").lstrip("/")
            if not normalized_name:
                continue
            target_path = os.path.normpath(os.path.join(extract_dir, normalized_name))
            if not target_path.startswith(os.path.abspath(extract_dir)):
                continue
            if raw_name.endswith(("/", "\\")) or member.is_dir():
                os.makedirs(target_path, exist_ok=True)
                continue
            os.makedirs(os.path.dirname(target_path), exist_ok=True)
            with zip_ref.open(member, "r") as source, open(target_path, "wb") as target:
                shutil.copyfileobj(source, target)


def _prepare_project_from_file_url(file_url: str, target_dir: str, on_progress=None) -> str:
    os.makedirs(target_dir, exist_ok=True)
    file_url = str(file_url or "").strip()
    if not file_url:
        _emit_prepare_log(on_progress, "未提供 fileUrl，使用空工程目录作为 workspace 初始内容")
        return target_dir
    parsed = urllib.parse.urlparse(file_url)
    _emit_prepare_log(on_progress, f"测试用例工程地址: {file_url}")

    if not parsed.scheme and os.path.isdir(file_url):
        _emit_prepare_log(on_progress, f"检测到本地工程目录，直接使用: {file_url}")
        return _find_project_root(file_url)

    archive_path = os.path.join(target_dir, "source.zip")
    cache_path = _cache_archive_path(file_url)
    _emit_prepare_log(on_progress, f"先检查本地缓存: {cache_path}")
    if os.path.exists(cache_path) and os.path.getsize(cache_path) > 0:
        _emit_prepare_log(on_progress, f"本地缓存已命中，使用缓存工程包: {cache_path}")
    else:
        _download_file(file_url, cache_path, on_progress=on_progress)
    shutil.copyfile(cache_path, archive_path)

    if not zipfile.is_zipfile(archive_path):
        raise ValueError(f"当前仅支持 zip 类型工程包: {file_url}")

    extract_dir = os.path.join(target_dir, "extracted")
    os.makedirs(extract_dir, exist_ok=True)
    _extract_zip_with_normalized_paths(archive_path, extract_dir, on_progress=on_progress)
    _emit_prepare_log(on_progress, f"工程包已解压到任务执行沙箱: {extract_dir}")

    return _find_project_root(extract_dir)


def _cleanup_download_source_dir(source_dir: str, on_progress=None):
    """
    `_download/` 只承担下载和解压中转职责。

    一旦原始工程已经复制到 `original/`，后续主流程只会再使用 `original/`
    和由其派生出来的 `workspace/`，中转目录就没有保留价值了。
    """
    if not source_dir or not os.path.exists(source_dir):
        return
    shutil.rmtree(source_dir, ignore_errors=True)
    _emit_prepare_log(on_progress, f"已清理下载中转目录: {source_dir}")


def _sanitize_original_project_signing_configs(original_dir: str, on_progress=None):
    result = sanitize_root_build_profile_signing_configs(original_dir)
    if result == "updated":
        _emit_prepare_log(on_progress, "清空原始工程签名信息成功，默认为[]")
    elif result == "already_empty":
        _emit_prepare_log(on_progress, "原始签名信息为空，无需清理")


class CloudExecutionManager:
    def __init__(self):
        self._lock = threading.Lock()
        self._registry = TaskRegistry()
        self._progress = TaskProgressTracker()
        self._artifacts = TaskArtifactUploader()
        self._result_reporter = TaskResultReporter(self._progress)
        config = load_config()
        task_manager_config = config.get("task_manager") if isinstance(config, dict) else {}
        configured_concurrency = 3
        if isinstance(task_manager_config, dict):
            configured_concurrency = int(task_manager_config.get("max_concurrency") or 3)
        self._max_concurrency = max(1, configured_concurrency)
        cloud_base_url = task_manager_config.get("cloud_base_url") if isinstance(task_manager_config, dict) else None
        if not cloud_base_url or not str(cloud_base_url).strip():
            raise ValueError("配置缺失: task_manager.cloud_base_url 未在 config/config.yaml 中配置")
        self._cloud_base_url = str(cloud_base_url).strip()
        # 超过并发上限的任务先进入等待队列，空出槽位后再启动。
        self._pending_queue: list[int] = []
        self._server_started_time = int(time.time() * 1000)
        self._file_queue = LocalTaskFileQueue(TASK_QUEUE_ROOT)
        self._update_pending = False
        self._pending_restored = False

    def _current_load_summary_locked(self) -> str:
        running_count = self._registry.running_execution_count()
        queued_count = len(self._pending_queue)
        return f"当前运行中={running_count}，排队中={queued_count}"

    def _can_start_new_execution(self) -> tuple[bool, str]:
        if self._update_pending:
            return False, "程序准备更新，任务暂不进入执行状态"
        running_count = self._registry.running_execution_count()
        if running_count >= self._max_concurrency:
            return False, f"当前运行中的任务数量已达上限: {self._max_concurrency}"
        return True, ""

    def _launch_execution_locked(self, payload: CloudExecutionStartRequest, local_base_url: str):
        execution_id = payload.executionId
        thread = threading.Thread(
            target=self._run_execution,
            args=(payload, local_base_url),
            daemon=True,
            name=f"execution-worker-{execution_id}",
        )
        self._registry.set_handle_metadata(
            execution_id,
            worker_thread=thread,
            queued=False,
            started_at=now_iso(),
            local_base_url=local_base_url,
        )
        self._file_queue.mark_running(execution_id)
        thread.start()

    def _start_queued_executions_locked(self):
        # 每次任务结束后尽量补满可用并发槽位。
        while (
            not self._update_pending
            and self._pending_queue
            and self._registry.running_execution_count() < self._max_concurrency
        ):
            next_execution_id = self._pending_queue.pop(0)
            state = self._registry.get(next_execution_id)
            if not state:
                continue
            handle = self._registry.get_handle_metadata(next_execution_id)
            payload = handle.get("payload")
            local_base_url = str(handle.get("local_base_url") or "").strip()
            if payload is None or not local_base_url:
                continue
            logger.info("任务从等待队列启动 taskId=%s", next_execution_id)
            self._progress.append_conversation(state, "status", "排队结束，准备开始执行")
            self._progress.append_execution_detail(state, STAGE_PENDING, "排队结束，准备开始执行")
            self._launch_execution_locked(payload, local_base_url)

    def restore_pending_tasks(self):
        """服务启动后恢复 pending 文件队列；running 文件只保留为异常中断证据。"""
        with self._lock:
            if self._pending_restored:
                return
            self._pending_restored = True
            restored_count = 0
            for record in self._file_queue.load_pending_records():
                payload_data = record.get("payload")
                if not isinstance(payload_data, dict):
                    continue
                try:
                    payload = CloudExecutionStartRequest.model_validate(payload_data)
                except Exception:
                    continue
                if self._registry.get(payload.executionId):
                    continue
                local_base_url = str(record.get("localBaseUrl") or "").strip()
                state = create_task_state(payload, payload.cloudBaseUrl or self._cloud_base_url)
                self._registry.create(payload.executionId, state)
                self._progress.ensure_stage_entry(state, STAGE_PENDING, "任务排队中")
                self._pending_queue.append(payload.executionId)
                self._registry.set_handle_metadata(
                    payload.executionId,
                    payload=payload,
                    local_base_url=local_base_url,
                    queued=True,
                    queued_at=now_iso(),
                )
                status_thread = threading.Thread(
                    target=self._status_report_loop,
                    args=(payload.executionId,),
                    daemon=True,
                    name=f"execution-status-{payload.executionId}",
                )
                self._registry.set_handle_metadata(payload.executionId, status_thread=status_thread)
                status_thread.start()
                restored_count += 1
            if restored_count:
                logger.info("已从本地 pending 队列恢复任务数量=%s", restored_count)
            self._start_queued_executions_locked()

    def start(self, payload: CloudExecutionStartRequest, local_base_url: str):
        if not str(payload.testCase.input or "").strip():
            logger.warning(
                "任务启动前置校验失败 taskId=%s: 缺少真实的任务输入",
                payload.executionId,
            )
            return False, "缺少真实的任务输入，已终止执行"
        with self._lock:
            existing_state = self._registry.get(payload.executionId)
            existing_handle = self._registry.get_handle_metadata(payload.executionId)
            existing_worker = existing_handle.get("worker_thread")
            if existing_worker and existing_worker.is_alive():
                return False, f"任务 {payload.executionId} 已在运行中"
            if existing_state and str(existing_state.get("local_status") or "") in {"pending", "running"}:
                return False, f"任务 {payload.executionId} 已存在，当前状态={existing_state.get('local_status')}"
            can_start, deny_message = self._can_start_new_execution()

            state = create_task_state(payload, payload.cloudBaseUrl or self._cloud_base_url)
            self._registry.create(payload.executionId, state)
            self._file_queue.write_pending(payload, local_base_url)
            logger.info(
                "收到任务下发 taskId=%s 任务=%s 工程包=%s",
                payload.executionId,
                _truncate_message(payload.testCase.input, 100),
                payload.testCase.fileUrl,
            )
            self._progress.ensure_stage_entry(state, STAGE_PENDING, "任务排队中")

            status_thread = threading.Thread(
                target=self._status_report_loop,
                args=(payload.executionId,),
                daemon=True,
                name=f"execution-status-{payload.executionId}",
            )
            self._registry.set_handle_metadata(
                payload.executionId,
                status_thread=status_thread,
                payload=payload,
                local_base_url=local_base_url,
            )
            status_thread.start()

            if can_start:
                self._launch_execution_locked(payload, local_base_url)
                return True, "任务已接收"

            self._pending_queue.append(payload.executionId)
            queue_index = len(self._pending_queue)
            self._registry.set_handle_metadata(
                payload.executionId,
                queued=True,
                queued_at=now_iso(),
            )
            executor_suffix = _executor_info_suffix(state)
            queue_message = f"任务进入等待队列，当前排队序号={queue_index}{executor_suffix}"
            logger.info("任务进入等待队列 taskId=%s 当前排队序号=%s%s", payload.executionId, queue_index, executor_suffix)
            self._progress.append_conversation(state, "status", queue_message)
            self._progress.append_execution_detail(state, STAGE_PENDING, queue_message)
            return True, f"任务已接收，当前排队序号={queue_index}"

    def prepare_update(self, action: str = "enable") -> Dict[str, Any]:
        """进入/退出更新准备状态。

        action="enable": 进入更新准备，停止启动新任务。
        action="disable": 恢复正常，继续启动排队任务。
        """
        with self._lock:
            if action == "enable":
                self._update_pending = True
            elif action == "disable":
                self._update_pending = False
                self._start_queued_executions_locked()
            return self.maintenance_status_locked()

    def maintenance_status(self) -> Dict[str, Any]:
        with self._lock:
            return self.maintenance_status_locked()

    def maintenance_status_locked(self) -> Dict[str, Any]:
        running_execution_ids = self._registry.running_execution_ids()
        pending_execution_ids = list(self._pending_queue)
        return {
            "updatePending": self._update_pending,
            "canUpdate": self._update_pending and not running_execution_ids,
            "runningExecutionIds": running_execution_ids,
            "pendingExecutionIds": pending_execution_ids,
            "runningFileExecutionIds": self._file_queue.running_ids(),
            "pendingFileExecutionIds": self._file_queue.pending_ids(),
        }

    def stop_executions(self, execution_ids: list[int]) -> Dict[str, Any]:
        requested_ids = []
        successed_ids = []
        failed_ids = []
        with self._lock:
            for raw_execution_id in execution_ids or []:
                try:
                    execution_id = int(raw_execution_id)
                except Exception:
                    continue
                if execution_id in requested_ids:
                    continue
                requested_ids.append(execution_id)
                if execution_id in self._pending_queue:
                    if self._file_queue.remove_pending(execution_id):
                        self._pending_queue = [item for item in self._pending_queue if item != execution_id]
                        self._registry.delete(execution_id)
                        successed_ids.append(execution_id)
                        logger.info("已移除 pending 任务: executionId=%s", execution_id)
                    else:
                        failed_ids.append(execution_id)
                        logger.warning("pending 任务移除失败，本地队列文件不存在: executionId=%s", execution_id)
                    continue
                if execution_id in self._registry.running_execution_ids():
                    failed_ids.append(execution_id)
                    logger.info("运行中任务不执行主动停止，已跳过: executionId=%s", execution_id)
                    continue
                failed_ids.append(execution_id)
        return {"successedIDs": successed_ids, "failedIds": failed_ids}

    def get_state(self, execution_id: Optional[int] = None) -> Optional[Dict[str, Any]]:
        with self._lock:
            return self._registry.snapshot(execution_id)

    def list_states(self) -> list[Dict[str, Any]]:
        with self._lock:
            return self._registry.snapshot_list()

    def summary(self) -> Dict[str, Any]:
        """返回执行器当前任务负载摘要。"""
        with self._lock:
            running_execution_ids = self._registry.running_execution_ids()
            queued_execution_ids = list(self._pending_queue)
            return {
                "serverStartedTime": self._server_started_time,
                "totalReceived": len(self._registry.snapshot_list()),
                "runningCount": len(running_execution_ids),
                "runningExecutionIds": running_execution_ids,
                "queuedCount": len(queued_execution_ids),
                "queuedExecutionIds": queued_execution_ids,
                "maxConcurrency": self._max_concurrency,
            }

    def _status_report_loop(self, execution_id: int):
        # 状态线程只服务于当前 execution，按 execution_id 拉取状态并推送远端。
        while True:
            time.sleep(STATUS_PUSH_INTERVAL_SECONDS)
            with self._lock:
                state = self._registry.get(execution_id)
                if not state:
                    return
                should_stop = bool(state.get("status_push_stop"))
                should_report = self._progress.should_report_status(state, should_stop)
            if should_report:
                with self._lock:
                    state = self._registry.get(execution_id)
                if state:
                    try:
                        self._progress.report_remote_status(state, self._cloud_base_url)
                    except Exception as exc:
                        self._progress.write_execution_log(state, "WARNING", f"状态上报异常: {exc}")
            if should_stop:
                return

    def _upload_agent_interaction_log(self, execution_id: int, trace_path: str):
        """Agent/LLM 交互流程 JSON 生成后立即上传云测，失败不影响主流程。"""
        trace_path = str(trace_path or "").strip()
        if not trace_path:
            return
        if not os.path.isfile(trace_path):
            with self._lock:
                state = self._registry.get(execution_id)
                if state is not None:
                    self._progress.write_execution_log(state, "WARNING", f"Agent/LLM 交互日志文件不存在，跳过上传: {trace_path}")
            return

        with self._lock:
            state = self._registry.get(execution_id)
            if state is None:
                return
            base_url = str(state.get("cloud_base_url") or self._cloud_base_url).strip()
            token = (state.get("token") or "").strip() or None
            self._progress.append_cloud_event(state, "agent_log_upload_request", {
                "url": build_agent_log_url(base_url, execution_id),
                "file": trace_path,
                "has_token": bool(token),
            })
            self._progress.write_execution_log(state, "INFO", f"开始上传 Agent/LLM 交互日志: {trace_path}")

        response = upload_agent_log(
            cloud_base_url=base_url,
            execution_id=execution_id,
            file_path=trace_path,
            token=token,
        )
        response_summary = {
            "ok": bool(response.get("ok")),
            "status_code": response.get("status_code"),
            "message": _truncate_message(str(response.get("body") or ""), 200),
        }
        with self._lock:
            state = self._registry.get(execution_id)
            if state is None:
                return
            state["last_agent_log_upload_response"] = response
            self._progress.append_cloud_event(state, "agent_log_upload_response", {
                "file": trace_path,
                "response": response,
            })
            if response.get("ok"):
                self._progress.write_execution_log(state, "INFO", f"Agent/LLM 交互日志上传完成: {_safe_json(response_summary)}")
                self._progress.append_execution_detail(state, STAGE_VALIDATING, "Agent/LLM 交互流程信息已上传服务器")
            else:
                self._progress.write_execution_log(state, "WARNING", f"Agent/LLM 交互日志上传失败，继续执行后续流程: {_safe_json(response_summary)}")

    def _run_execution(self, payload: CloudExecutionStartRequest, local_base_url: str):
        # 每个 execution 在自己的线程里完整执行一条 pipeline，互不共享运行上下文。
        execution_id = payload.executionId
        with self._lock:
            state = self._registry.require(execution_id)

        def update_local_status(status: str, stage: Optional[str] = None):
            with self._lock:
                state["local_status"] = status
                if stage:
                    state["local_stage"] = stage
                    self._progress.ensure_stage_entry(state, stage, self._progress.stage_message(status, stage))
                state["updated_at"] = now_iso()

        def on_progress(event: str, data: Dict[str, Any]):
            upload_workspace_dir = ""
            upload_patch_path = ""
            upload_checks_dir = ""
            upload_checks_stage = ""
            upload_agent_log_path = ""
            with self._lock:
                current = self._registry.require(execution_id)
                if event == "log":
                    message = data.get("message", "")
                    self._progress.append_conversation(current, "log", message, data.get("level", "INFO"))
                    if str(current.get("local_status") or "") == "running":
                        self._progress.append_execution_detail(current, str(current.get("local_stage") or STAGE_PENDING), message)
                elif event == "stage_start":
                    stage_name = str(data.get("stage", "")).strip()
                    stage_map = {
                        "generating": STAGE_GENERATING,
                        "pre_compile_check": STAGE_PREPARING,
                        "preparing": STAGE_PREPARING,
                        "post_compile_check": STAGE_VALIDATING,
                        "validating": STAGE_VALIDATING,
                    }
                    mapped_stage = stage_map.get(stage_name)
                    if mapped_stage:
                        current["local_stage"] = mapped_stage
                        self._progress.ensure_stage_entry(current, mapped_stage, self._progress.stage_message(str(current.get("local_status") or ""), mapped_stage))
                        current["updated_at"] = now_iso()
                    self._progress.append_conversation(current, "stage_start", data.get("stage", ""))
                elif event == "stage_done":
                    self._progress.append_conversation(current, "stage_done", f"{data.get('stage', '')}:{data.get('status', 'done')}")
                elif event == "artifacts_ready":
                    upload_workspace_dir = str(data.get("workspace_dir") or "").strip()
                    upload_patch_path = str(data.get("patch_path") or "").strip()
                elif event == "compile_check_failed":
                    upload_checks_dir = str(data.get("checks_dir") or "").strip()
                    upload_checks_stage = str(data.get("stage") or "").strip()
                elif event == "agent_interaction_trace_start":
                    self._progress.write_execution_log(current, "INFO", "开始准备 Agent/LLM 交互流程信息")
                elif event == "agent_interaction_trace_done":
                    trace_path = str(data.get("trace_path") or "").strip()
                    current["agent_interaction_trace_path"] = trace_path
                    message = "Agent/LLM 交互流程信息已生成"
                    self._progress.write_execution_log(current, "INFO", f"{message}: {trace_path}" if trace_path else message)
                    upload_agent_log_path = trace_path
                elif event == "agent_interaction_trace_failed":
                    error = str(data.get("error") or "").strip()
                    message = "Agent/LLM 交互流程信息准备失败"
                    self._progress.write_execution_log(current, "WARNING", f"{message}: {error}" if error else message)
                elif event == "error":
                    current["error_message"] = data.get("message", "")
                    current["updated_at"] = now_iso()
                    current_stage = str(current.get("local_stage") or STAGE_PENDING)
                    self._progress.append_execution_detail(current, current_stage, "任务执行失败")
                    self._progress.append_conversation(current, "error", data.get("message", ""), "ERROR")
                elif event == "case_done":
                    self._progress.append_conversation(current, "case_done", data.get("case_id", ""))
            if event == "artifacts_ready":
                output_code_url = self._artifacts.upload_output_code_dir(
                    upload_workspace_dir,
                    execution_id=execution_id,
                    on_progress=on_progress,
                )
                harmonyos_url = self._artifacts.upload_harmonyos_dir(
                    upload_workspace_dir,
                    execution_id=execution_id,
                    on_progress=on_progress,
                )
                diff_file_url = self._artifacts.upload_diff_file(
                    upload_patch_path,
                    execution_id=execution_id,
                    on_progress=on_progress,
                )
                with self._lock:
                    current = self._registry.get(execution_id)
                    if current is not None:
                        current["output_code_url"] = output_code_url
                        current["harmonyos_url"] = harmonyos_url
                        current["diff_file_url"] = diff_file_url
            elif event == "agent_interaction_trace_done" and upload_agent_log_path:
                self._upload_agent_interaction_log(execution_id, upload_agent_log_path)
            elif event == "compile_check_failed":
                checks_url = self._artifacts.upload_checks_dir(
                    upload_checks_dir,
                    execution_id=execution_id,
                    stage_name=upload_checks_stage,
                    on_progress=on_progress,
                )
                if checks_url:
                    with self._lock:
                        current = self._registry.get(execution_id)
                        if current is not None:
                            current.setdefault("checks_urls", {})[upload_checks_stage or "unknown"] = checks_url

        try:
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            run_dir = os.path.join(RESULTS_ROOT, f"execution_{execution_id}_{timestamp}")
            source_dir = os.path.join(run_dir, "_download")
            case_dir = run_dir
            os.makedirs(run_dir, exist_ok=True)
            with self._lock:
                state["run_dir"] = run_dir
                state["case_dir"] = case_dir
                state["sse_log_path"] = os.path.join(agent_meta_dir(case_dir), "agent_opencode_sse_events.jsonl")
                state["progress_upload_state_path"] = os.path.join(run_dir, "progress_upload_state.json")
                self._progress.save_progress_upload_state(
                    state["progress_upload_state_path"],
                    self._progress.default_progress_upload_state(),
                )

            update_local_status("running", STAGE_PREPARING)
            with self._lock:
                self._progress.append_conversation(state, "status", "任务开始执行")
                self._progress.append_execution_detail(
                    state,
                    STAGE_PENDING,
                    f"任务开始执行{_executor_info_suffix(state)}",
                )
                self._progress.append_execution_detail(state, STAGE_PREPARING, f"本地产物目录: {run_dir}")
                executor_log = os.path.join(
                    run_dir,
                    str(load_logging_config().get("local_execution_log_filename") or "local_execution.log"),
                )
                if executor_log:
                    self._progress.append_execution_detail(state, STAGE_PREPARING, f"可用 tail -f {executor_log} 查看实时执行日志")
            downloaded_project_root = _prepare_project_from_file_url(payload.testCase.fileUrl, source_dir, on_progress=on_progress)
            original_dir = original_project_dir(case_dir)
            if os.path.exists(original_dir):
                shutil.rmtree(original_dir)
            shutil.copytree(downloaded_project_root, original_dir)
            _sanitize_original_project_signing_configs(original_dir, on_progress=on_progress)
            _emit_prepare_log(on_progress, f"原始工程已准备完成: {original_dir}")
            _cleanup_download_source_dir(source_dir, on_progress=on_progress)
            raw_input = (payload.testCase.input or "").strip()
            raw_expected_output = (payload.testCase.expectedOutput or "").strip()
            input_text = raw_input
            expected_output = raw_expected_output
            if not input_text.strip():
                raise ValueError("缺少真实的任务输入，已终止执行")
            prompt = build_prompt(input_text, expected_output)
            case_spec = {
                "case": {
                    "id": f"cloud_execution_{execution_id}",
                    "title": f"Cloud Execution {execution_id}",
                    "scenario": "cloud_api",
                    "prompt": prompt,
                    "skip_pre_compile_check": not bool(str(payload.testCase.fileUrl or "").strip()),
                },
            }
            case = build_case(
                execution_id,
                original_dir,
                prompt,
                case_spec=case_spec,
            )
            case["_cloud_execution_id"] = execution_id

            with self._lock:
                state["run_dir"] = run_dir
                state["case_dir"] = case_dir
                state["sse_log_path"] = os.path.join(agent_meta_dir(case_dir), "agent_opencode_sse_events.jsonl")
                state["case_id"] = case.get("id") or f"cloud_execution_{execution_id}"
                state["case_title"] = case.get("title") or f"Cloud Execution {execution_id}"
                state["project_source_url"] = payload.testCase.fileUrl
                self._progress.append_conversation(state, "prepare", f"工程已就绪: {original_dir}")

            agent = load_agent(payload.agentId or "")
            if not agent:
                agents = load_agents()
                agent = load_agent(agents[0].get("id")) if agents else None
            if not agent:
                raise ValueError("必须选择一个可用 agent")
            from agent_bench.agent_runner.spec import configured_agent_timeout
            default_timeout = configured_agent_timeout()
            with self._lock:
                self._progress.append_conversation(
                    state,
                    "status",
                    f"执行计划已确认: Agent={agent.get('name') or agent.get('id') or '未知'}，即将开始处理工程",
                )
            agent_started_at = time.time()
            result = run_single_case(
                case=case,
                case_dir=case_dir,
                stages=["runner"],
                dry_run=False,
                on_progress=on_progress,
                agent_config=agent,
                agent_timeout=default_timeout,
            )
            agent_elapsed_s = result.get("agent_elapsed_s") or int(time.time() - agent_started_at)

            if str(result.get("status") or "").lower() not in {"completed", "success"}:
                raise RuntimeError(f"Agent 执行失败: {result.get('status') or 'unknown'}")
            output_code_url = str(state.get("output_code_url") or "").strip()
            diff_file_url = str(state.get("diff_file_url") or "").strip()
            if not output_code_url:
                output_code_url = self._artifacts.upload_output_code_dir(
                    agent_workspace_dir(case_dir),
                    execution_id=execution_id,
                    on_progress=on_progress,
                )
            harmonyos_url = str(state.get("harmonyos_url") or "").strip()
            if not harmonyos_url:
                harmonyos_url = self._artifacts.upload_harmonyos_dir(
                    agent_workspace_dir(case_dir),
                    execution_id=execution_id,
                    on_progress=on_progress,
                )
            if not diff_file_url:
                diff_file_url = self._artifacts.upload_diff_file(
                    os.path.join(diff_dir(case_dir), "changes.patch"),
                    execution_id=execution_id,
                    on_progress=on_progress,
                )
            result_payload = build_execution_result_payload(
                execution_id=execution_id,
                case_dir=case_dir,
                result=result,
                expected_output=expected_output,
                execution_time_s=agent_elapsed_s,
                output_code_url=output_code_url,
                diff_file_url=diff_file_url,
            )

            with self._lock:
                state["output_code_url"] = output_code_url
                state["harmonyos_url"] = harmonyos_url
                state["diff_file_url"] = diff_file_url
                state["result"] = result
                state["last_result_payload"] = result_payload
            self._result_reporter.report(
                state=state,
                result_payload=result_payload,
                cloud_base_url=self._cloud_base_url,
                completed_stage=STAGE_COMPLETED,
            )

            update_local_status("completed", STAGE_COMPLETED)
            with self._lock:
                self._progress.append_execution_detail(state, STAGE_COMPLETED, "任务执行完成")
                self._progress.append_conversation(state, "status", "任务执行完成")
        except Exception as exc:
            with self._lock:
                state["error_message"] = str(exc)
                self._progress.append_conversation(state, "error", str(exc), "ERROR")
            update_local_status("failed", str(state.get("local_stage") or STAGE_PENDING))
        finally:
            with self._lock:
                state["status_push_stop"] = True
                self._file_queue.remove_running(execution_id)
                self._registry.set_handle_metadata(execution_id, finished_at=now_iso())
                self._registry.clear_handle_metadata(execution_id, "worker_thread", "status_thread")
                self._start_queued_executions_locked()
                if self._update_pending and not self._registry.running_execution_ids():
                    logger.info("更新准备完成：当前无运行任务，可以重启更新程序")
                load_summary = self._current_load_summary_locked()
                self._progress.append_conversation(
                    state,
                    "status",
                    f"任务已结束，{load_summary}",
                )


cloud_execution_manager = CloudExecutionManager()
