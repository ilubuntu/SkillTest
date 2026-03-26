# -*- coding: utf-8 -*-
"""评测任务管理器

直接调用 pipeline.run_pipeline()，通过回调接收进度，
不再通过 subprocess 调用 cli.py。
"""

import os
import sys
import threading
import queue
import json
from datetime import datetime
from typing import Optional, List
from pathlib import Path

BASE_DIR = Path(__file__).parent.parent.parent  # agent_bench/
REPO_DIR = BASE_DIR.parent                      # agent_bench 的父目录
sys.path.insert(0, str(Path(__file__).parent.parent))
sys.path.insert(0, str(BASE_DIR))
sys.path.insert(0, str(REPO_DIR))

from backend.models import (
    EvaluationStatus, LogEntry, CaseResult, EvaluationResult,
    EvaluationSummary, EvaluationProgress
)


class EvaluatorManager:
    _instance = None
    _lock = threading.Lock()

    def __new__(cls):
        if cls._instance is None:
            with cls._lock:
                if cls._instance is None:
                    cls._instance = super().__new__(cls)
                    cls._instance._initialized = False
        return cls._instance

    def __init__(self):
        if self._initialized:
            return
        self._initialized = True

        self._status = EvaluationStatus.IDLE
        self._progress = 0
        self._total_cases = 0
        self._done_cases = 0
        self._current_case: Optional[str] = None
        self._current_profile: Optional[str] = None
        self._current_scenario: Optional[str] = None
        self._logs: List[LogEntry] = []
        self._result: Optional[EvaluationResult] = None
        self._results: List[EvaluationResult] = []
        self._log_queue: queue.Queue = queue.Queue()
        self._stop_event = threading.Event()
        self._max_logs = 1000
        self._worker_thread: Optional[threading.Thread] = None

    def _add_log(self, level: str, message: str, detail: Optional[str] = None):
        entry = LogEntry(
            timestamp=datetime.now().strftime("%H:%M:%S"),
            level=level,
            message=message,
            detail=detail
        )
        if len(self._logs) >= self._max_logs:
            self._logs = self._logs[-self._max_logs:]
        self._logs.append(entry)
        try:
            self._log_queue.put_nowait(entry)
        except queue.Full:
            pass

    # ── Pipeline 回调 ────────────────────────────────────────

    def _pipeline_callback(self, event: str, data: dict):
        """pipeline 进度回调 — 在工作线程中被调用"""
        # 检查是否需要中止
        if self._stop_event.is_set():
            raise InterruptedError("评测已被用户中止")

        if event == "pipeline_start":
            self._current_profile = data.get("profile")
            self._add_log("INFO", f"评测启动: profile={data['profile']}, "
                          f"scenarios={','.join(data['scenarios'])}")

        elif event == "scenario_start":
            self._current_scenario = data["scenario"]
            self._total_cases += data["case_count"]
            self._add_log("INFO", f"场景: {data['scenario']} ({data['case_count']} 用例)")

        elif event == "stage_done":
            stage = data["stage"]
            case_id = data.get("case_id", "")
            if data.get("skipped"):
                self._add_log("DEBUG", f"[{case_id}] {stage} 跳过")
            else:
                elapsed = data.get("elapsed", 0)
                self._add_log("INFO", f"[{case_id}] {stage} 完成 ({elapsed:.0f}s)")

        elif event == "case_done":
            self._done_cases += 1
            self._current_case = data["case_id"]
            if self._total_cases > 0:
                self._progress = int(self._done_cases / self._total_cases * 100)
            gain = data["gain"]
            sign = "+" if gain >= 0 else ""
            self._add_log("INFO",
                          f"用例完成: {data['case_id']} - {data['title']} "
                          f"(基线={data['baseline_total']}, 增强={data['enhanced_total']}, "
                          f"增益={sign}{gain:.1f})")

        elif event == "scenario_done":
            self._add_log("INFO", f"场景完成: {data['scenario']} ({data['case_count']} 用例)")

        elif event == "pipeline_done":
            self._add_log("INFO", f"评测完成: 共 {data['total_cases']} 用例")

        elif event == "log":
            level = data.get("level", "INFO")
            message = data.get("message", "")
            self._add_log(level, message)

        elif event == "error":
            case_id = data.get("case_id", "")
            prefix = f"[{case_id}] " if case_id else ""
            self._add_log("ERROR", f"{prefix}{data['message']}")

    # ── 工作线程 ─────────────────────────────────────────────

    def _run_pipeline_thread(self, profiles, scenarios, skip_baseline):
        try:
            from agent_bench.runner.agent_runner import ensure_opencode_server
            from agent_bench.pipeline.engine import run_pipeline

            # 服务发现
            self._add_log("INFO", "正在连接 OpenCode Server...")
            api_base = ensure_opencode_server()
            self._add_log("INFO", f"OpenCode Server 已连接: {api_base}")

            profile_arg = "all" if "all" in profiles else ",".join(profiles)
            scenario_arg = "all" if "all" in scenarios else ",".join(scenarios)

            self._add_log("INFO", f"评测参数: profiles={profile_arg}, scenarios={scenario_arg}, "
                          f"skip_baseline={skip_baseline}")

            result = run_pipeline(
                profile=profile_arg,
                cases_override=scenario_arg,
                api_base=api_base,
                dry_run=False,
                skip_baseline=skip_baseline,
                on_progress=self._pipeline_callback,
            )

            if self._stop_event.is_set():
                self._status = EvaluationStatus.STOPPED
                self._add_log("INFO", "评测任务已停止")
                return

            # 构建结果
            self._result = self._build_result(result)
            self._status = EvaluationStatus.COMPLETED
            self._progress = 100
            self._add_log("INFO", "评测任务已完成")

        except InterruptedError:
            self._status = EvaluationStatus.STOPPED
            self._add_log("INFO", "评测任务已停止")
        except Exception as e:
            self._status = EvaluationStatus.ERROR
            self._add_log("ERROR", f"评测失败: {str(e)}")

    def _build_result(self, pipeline_result: dict) -> Optional[EvaluationResult]:
        """从 pipeline 返回值构建 EvaluationResult"""
        json_path = pipeline_result.get("json_path")
        if not json_path or not os.path.exists(json_path):
            return None

        try:
            with open(json_path, "r", encoding="utf-8") as f:
                data = json.load(f)

            summary = data.get("summary", {})
            cases = []
            for c in data.get("cases", []):
                gain = c.get("enhanced_total", 0) - c.get("baseline_total", 0)
                cases.append(CaseResult(
                    case_id=c.get("case_id", ""),
                    title=c.get("title", ""),
                    scenario=c.get("scenario", ""),
                    baseline_rule=c.get("baseline_rule", 0),
                    enhanced_rule=c.get("enhanced_rule", 0),
                    baseline_total=c.get("baseline_total", 0),
                    enhanced_total=c.get("enhanced_total", 0),
                    gain=gain,
                    dimension_scores=c.get("dimension_scores", {})
                ))

            summary_obj = EvaluationSummary(
                total_cases=summary.get("total_cases", 0),
                baseline_avg=summary.get("baseline_avg", 0),
                enhanced_avg=summary.get("enhanced_avg", 0),
                gain=summary.get("gain", 0),
                baseline_pass_rate=summary.get("baseline_pass_rate", "0/0"),
                enhanced_pass_rate=summary.get("enhanced_pass_rate", "0/0"),
                dimensions=summary.get("dimensions", {})
            )

            eval_result = EvaluationResult(
                run_id=pipeline_result["run_id"],
                profile=data.get("profile", ""),
                scenario=data.get("scenario", ""),
                summary=summary_obj,
                cases=cases
            )
            self._results.append(eval_result)
            return eval_result
        except Exception as e:
            self._add_log("ERROR", f"加载结果失败: {str(e)}")
            return None

    # ── 公开接口 ─────────────────────────────────────────────

    def start_evaluation(self, profiles: List[str], scenarios: List[str],
                         skip_baseline: bool = False):
        if self._status == EvaluationStatus.RUNNING:
            return False, "评测正在进行中"

        self._stop_event.clear()
        self._status = EvaluationStatus.RUNNING
        self._progress = 0
        self._total_cases = 0
        self._done_cases = 0
        self._logs = []
        self._result = None
        self._results = []
        self._current_case = None
        self._current_profile = None
        self._current_scenario = None
        while not self._log_queue.empty():
            try:
                self._log_queue.get_nowait()
            except queue.Empty:
                break

        self._add_log("INFO", "评测任务开始")

        self._worker_thread = threading.Thread(
            target=self._run_pipeline_thread,
            args=(profiles, scenarios, skip_baseline),
            daemon=True,
        )
        self._worker_thread.start()
        return True, "评测已启动"

    def stop_evaluation(self):
        if self._status != EvaluationStatus.RUNNING:
            return False, "没有正在运行的评测任务"

        self._stop_event.set()
        self._status = EvaluationStatus.STOPPED
        self._add_log("INFO", "评测任务已停止")
        return True, "评测任务已停止"

    def get_progress(self) -> EvaluationProgress:
        return EvaluationProgress(
            status=self._status,
            progress=self._progress,
            current_case=self._current_case,
            current_profile=self._current_profile,
            current_scenario=self._current_scenario,
            logs=self._logs.copy(),
            result=self._result,
            results=self._results.copy()
        )

    def get_log_queue(self) -> queue.Queue:
        return self._log_queue


evaluator_manager = EvaluatorManager()
