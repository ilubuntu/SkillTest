# -*- coding: utf-8 -*-
"""评测任务管理器

管理评测生命周期（启动/停止/进度查询），
通过回调接收 pipeline 进度，维护状态供前端查询。
追踪每个 case 的阶段级进度。
"""

import json
import os
import queue
import re
import threading
from datetime import datetime
from typing import Optional, List, Dict

from backend.models import (
    EvaluationStatus, LogEntry, CaseResult, EvaluationResult,
    EvaluationSummary, EvaluationProgress,
    CaseProgress, CaseStage, GeneralResult, CompileResult,
)

# case 执行的阶段顺序
CASE_STAGES = ["基线运行", "增强运行", "规则检查", "LLM评分"]


class EvaluatorManager:
    """评测任务单例管理器"""

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
        self._reset_state()
        self._log_queue: queue.Queue = queue.Queue()
        self._stop_event = threading.Event()
        self._worker_thread: Optional[threading.Thread] = None
        self._max_logs = 1000

    def _reset_state(self):
        self._status = EvaluationStatus.IDLE
        self._total_cases = 0
        self._done_cases = 0
        self._current_case: Optional[str] = None
        self._current_profile: Optional[str] = None
        self._current_scenario: Optional[str] = None
        self._scenarios: List[str] = []
        self._case_progresses: Dict[str, CaseProgress] = {}
        self._logs: List[LogEntry] = []
        self._result: Optional[EvaluationResult] = None
        self._results: List[EvaluationResult] = []
        self._general_result: Optional[EvaluationResult] = None

    # ── 日志 ──────────────────────────────────────────────────

    def _add_log(self, level: str, message: str, detail: Optional[str] = None):
        entry = LogEntry(
            timestamp=datetime.now().strftime("%H:%M:%S"),
            level=level,
            message=message,
            detail=detail,
        )
        if len(self._logs) >= self._max_logs:
            self._logs = self._logs[-self._max_logs:]
        self._logs.append(entry)
        try:
            self._log_queue.put_nowait(entry)
        except queue.Full:
            pass

    # ── Case 进度追踪 ────────────────────────────────────────

    def _ensure_case(self, case_id: str, title: str = "", scenario: str = ""):
        """确保 case 进度条目存在"""
        if case_id not in self._case_progresses:
            self._case_progresses[case_id] = CaseProgress(
                case_id=case_id,
                title=title,
                scenario=scenario or self._current_scenario or "",
                status="pending",
                stages=[CaseStage(name=s) for s in CASE_STAGES],
            )

    def _update_case_stage(self, case_id: str, stage_name: str,
                           status: str, elapsed: float = None):
        """更新某 case 某阶段的状态"""
        cp = self._case_progresses.get(case_id)
        if not cp:
            return
        for stage in cp.stages:
            if stage.name == stage_name:
                stage.status = status
                if elapsed is not None:
                    stage.elapsed = round(elapsed, 1)
                break
        # 如果有阶段在跑，case 状态为 running
        if status == "running":
            cp.status = "running"

    # ── Pipeline 回调 ─────────────────────────────────────────

    def _pipeline_callback(self, event: str, data: dict):
        """pipeline 进度回调 — 在工作线程中被调用"""
        if self._stop_event.is_set():
            raise InterruptedError("评测已被用户中止")

        if event == "pipeline_start":
            self._current_profile = data.get("profile")
            self._scenarios = data.get("scenarios", [])
            self._add_log("INFO", f"评测启动: profile={data['profile']}, "
                          f"scenarios={','.join(data['scenarios'])}")

        elif event == "scenario_start":
            self._current_scenario = data["scenario"]
            self._total_cases += data["case_count"]
            self._add_log("INFO", f"场景: {data['scenario']} ({data['case_count']} 用例)")

        elif event == "stage_done":
            case_id = data.get("case_id", "")
            stage = data["stage"]
            if case_id:
                self._ensure_case(case_id)
                if data.get("skipped"):
                    self._update_case_stage(case_id, stage, "skipped")
                    self._add_log("DEBUG", f"[{case_id}] {stage} 跳过")
                else:
                    elapsed = data.get("elapsed", 0)
                    self._update_case_stage(case_id, stage, "done", elapsed)
                    self._add_log("INFO", f"[{case_id}] {stage} 完成 ({elapsed:.0f}s)")

        elif event == "case_done":
            self._done_cases += 1
            case_id = data["case_id"]
            self._current_case = case_id
            self._ensure_case(case_id, data.get("title", ""), data.get("scenario", ""))
            cp = self._case_progresses[case_id]
            cp.status = "done"
            cp.baseline_total = data.get("baseline_total")
            cp.enhanced_total = data.get("enhanced_total")
            cp.gain = data.get("gain")
            gain = data["gain"]
            sign = "+" if gain >= 0 else ""
            self._add_log("INFO",
                          f"用例完成: {case_id} - {data['title']} "
                          f"(基线={data['baseline_total']:.1f}, 增强={data['enhanced_total']:.1f}, "
                          f"增益={sign}{gain:.1f})")

        elif event == "scenario_done":
            self._add_log("INFO", f"场景完成: {data['scenario']} ({data['case_count']} 用例)")

        elif event == "pipeline_done":
            self._add_log("INFO", f"评测完成: 共 {data['total_cases']} 用例")

        elif event == "log":
            level = data.get("level", "INFO")
            message = data.get("message", "")
            # 从日志中推断 case 进度（当 log 包含 [case_id] 开始xxx 时）
            self._infer_case_stage_from_log(message)
            self._add_log(level, message)

        elif event == "error":
            case_id = data.get("case_id", "")
            prefix = f"[{case_id}] " if case_id else ""
            if case_id and case_id in self._case_progresses:
                self._case_progresses[case_id].status = "error"
                self._case_progresses[case_id].error = data.get("message", "")
            self._add_log("ERROR", f"{prefix}{data['message']}")

    def _infer_case_stage_from_log(self, message: str):
        """从 log message 推断 case 当前正在执行的阶段"""
        # 匹配 [case_id] 开始基线运行/增强运行/规则检查/LLM评分
        m = re.match(r'\[(\w+)\]\s+开始(基线运行|增强运行|规则检查|LLM)', message)
        if m:
            case_id = m.group(1)
            stage_keyword = m.group(2)
            stage_map = {
                "基线运行": "基线运行",
                "增强运行": "增强运行",
                "规则检查": "规则检查",
                "LLM": "LLM评分",
            }
            stage_name = stage_map.get(stage_keyword)
            if stage_name and case_id in self._case_progresses:
                self._update_case_stage(case_id, stage_name, "running")
            return

        # 匹配 [case_id] 开始处理用例: xxx — 初始化 case
        m = re.match(r'\[(\w+)\]\s+开始处理用例:\s+(.+)', message)
        if m:
            case_id = m.group(1)
            title = m.group(2)
            self._ensure_case(case_id, title)
            self._case_progresses[case_id].status = "running"

    # ── 工作线程 ──────────────────────────────────────────────

    def _run_pipeline_thread(self, profiles, scenarios, skip_baseline):
        try:
            from agent_bench.runner.discovery import ensure_opencode_server
            from agent_bench.pipeline.engine import run_pipeline

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

            self._result = self._build_result(result)
            self._general_result = self._build_general_result(result.get("results", []))
            self._status = EvaluationStatus.COMPLETED
            self._add_log("INFO", "评测任务已完成")

        except InterruptedError:
            self._status = EvaluationStatus.STOPPED
            self._add_log("INFO", "评测任务已停止")
        except Exception as e:
            self._status = EvaluationStatus.ERROR
            self._add_log("ERROR", f"评测失败: {str(e)}")

    def _build_general_result(self, general_results: list) -> Optional[EvaluationResult]:
        """从 general_results 构建通用用例的评测结果"""
        if not general_results:
            return None

        try:
            baseline_compilable_count = 0
            baseline_compilable_total = 0
            enhanced_compilable_count = 0
            enhanced_compilable_total = 0

            for r in general_results:
                compile_results = r.get("compile_results")
                if compile_results:
                    if compile_results.get("baseline_compilable") is not None:
                        baseline_compilable_total += 1
                        if compile_results.get("baseline_compilable"):
                            baseline_compilable_count += 1
                    if compile_results.get("enhanced_compilable") is not None:
                        enhanced_compilable_total += 1
                        if compile_results.get("enhanced_compilable"):
                            enhanced_compilable_count += 1

            baseline_rate = f"{baseline_compilable_count}/{baseline_compilable_total}" if baseline_compilable_total > 0 else "N/A"
            enhanced_rate = f"{enhanced_compilable_count}/{enhanced_compilable_total}" if enhanced_compilable_total > 0 else "N/A"

            general_data = {
                "baseline_compile_pass_rate": baseline_rate,
                "enhanced_compile_pass_rate": enhanced_rate,
            }

            general = GeneralResult(
                baseline_compile_pass_rate=baseline_rate,
                enhanced_compile_pass_rate=enhanced_rate,
                note="通用用例编译检查结果" if baseline_compilable_total > 0 or enhanced_compilable_total > 0 else None,
            )

            cases = []
            for c in general_results:
                compile_results_data = c.get("compile_results")
                compile_results = None
                if compile_results_data:
                    compile_results = CompileResult(
                        baseline_compilable=compile_results_data.get("baseline_compilable"),
                        baseline_error=compile_results_data.get("baseline_error", ""),
                        enhanced_compilable=compile_results_data.get("enhanced_compilable"),
                        enhanced_error=compile_results_data.get("enhanced_error", ""),
                    )
                cases.append(CaseResult(
                    case_id=c.get("case_id", ""),
                    title=c.get("title", ""),
                    scenario=c.get("scenario", "general"),
                    baseline_rule=c.get("baseline_rule", 0),
                    enhanced_rule=c.get("enhanced_rule", 0),
                    baseline_total=c.get("baseline_total", 0),
                    enhanced_total=c.get("enhanced_total", 0),
                    gain=c.get("enhanced_total", 0) - c.get("baseline_total", 0),
                    dimension_scores=c.get("dimension_scores", {}),
                    compile_results=compile_results,
                ))

            return EvaluationResult(
                run_id="",
                profile="general",
                scenario="general",
                summary=EvaluationSummary(
                    total_cases=len(cases),
                    baseline_avg=0,
                    enhanced_avg=0,
                    gain=0,
                    baseline_pass_rate="0/0",
                    enhanced_pass_rate="0/0",
                    dimensions={},
                ),
                cases=cases,
                general=general,
            )
        except Exception as e:
            self._add_log("ERROR", f"构建通用用例结果失败: {str(e)}")
            return None

    def _build_result(self, pipeline_result: dict) -> Optional[EvaluationResult]:
        """从 pipeline 返回的 JSON 报告构建前端 EvaluationResult"""
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
                compile_results_data = c.get("compile_results")
                compile_results = None
                if compile_results_data:
                    compile_results = CompileResult(
                        baseline_compilable=compile_results_data.get("baseline_compilable"),
                        baseline_error=compile_results_data.get("baseline_error", ""),
                        enhanced_compilable=compile_results_data.get("enhanced_compilable"),
                        enhanced_error=compile_results_data.get("enhanced_error", ""),
                    )
                cases.append(CaseResult(
                    case_id=c.get("case_id", ""),
                    title=c.get("title", ""),
                    scenario=c.get("scenario", ""),
                    baseline_rule=c.get("baseline_rule", 0),
                    enhanced_rule=c.get("enhanced_rule", 0),
                    baseline_total=c.get("baseline_total", 0),
                    enhanced_total=c.get("enhanced_total", 0),
                    gain=gain,
                    dimension_scores=c.get("dimension_scores", {}),
                    compile_results=compile_results,
                ))

            general_data = data.get("general", {})
            general = None
            if general_data:
                general = GeneralResult(
                    baseline_compile_pass_rate=general_data.get("baseline_compile_pass_rate", "N/A"),
                    enhanced_compile_pass_rate=general_data.get("enhanced_compile_pass_rate", "N/A"),
                    note=general_data.get("note"),
                )

            eval_result = EvaluationResult(
                run_id=pipeline_result["run_id"],
                profile=data.get("profile", ""),
                scenario=data.get("scenario", ""),
                summary=EvaluationSummary(
                    total_cases=summary.get("total_cases", 0),
                    baseline_avg=summary.get("baseline_avg", 0),
                    enhanced_avg=summary.get("enhanced_avg", 0),
                    gain=summary.get("gain", 0),
                    baseline_pass_rate=summary.get("baseline_pass_rate", "0/0"),
                    enhanced_pass_rate=summary.get("enhanced_pass_rate", "0/0"),
                    dimensions=summary.get("dimensions", {}),
                ),
                cases=cases,
                general=general,
            )
            self._results.append(eval_result)
            return eval_result
        except Exception as e:
            self._add_log("ERROR", f"加载结果失败: {str(e)}")
            return None

    # ── 公开接口 ──────────────────────────────────────────────

    def start_evaluation(self, profiles: List[str], scenarios: List[str],
                         skip_baseline: bool = False):
        if self._status == EvaluationStatus.RUNNING:
            return False, "评测正在进行中"

        self._stop_event.clear()
        self._reset_state()
        self._status = EvaluationStatus.RUNNING
        # 清空日志队列
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
            total_cases=self._total_cases,
            done_cases=self._done_cases,
            current_case=self._current_case,
            current_profile=self._current_profile,
            current_scenario=self._current_scenario,
            scenarios=self._scenarios,
            case_progresses=list(self._case_progresses.values()),
            logs=self._logs.copy(),
            result=self._result,
            results=self._results.copy(),
            general_result=self._general_result,
        )

    def get_log_queue(self) -> queue.Queue:
        return self._log_queue


evaluator_manager = EvaluatorManager()
