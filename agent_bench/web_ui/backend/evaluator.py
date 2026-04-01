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
CASE_STAGES = ["A侧运行", "B侧运行", "A侧编译", "B侧编译", "规则检查", "LLM评分"]


def _normalize_dimension_scores(dimensions: Dict) -> Dict:
    normalized = {}
    for dim_id, scores in (dimensions or {}).items():
        if not isinstance(scores, dict):
            continue
        normalized[dim_id] = {
            "name": scores.get("name", dim_id),
            "side_a": scores.get("side_a", scores.get("baseline", {})),
            "side_b": scores.get("side_b", scores.get("enhanced", {})),
        }
    return normalized


def _normalize_summary_dimensions(dimensions: Dict) -> Dict:
    normalized = {}
    for dim_id, data in (dimensions or {}).items():
        if not isinstance(data, dict):
            continue
        normalized[dim_id] = {
            "name": data.get("name", dim_id),
            "side_a_avg": data.get("side_a_avg", data.get("baseline_avg")),
            "side_b_avg": data.get("side_b_avg", data.get("enhanced_avg")),
            "side_a_llm_avg": data.get("side_a_llm_avg", data.get("baseline_llm_avg")),
            "side_b_llm_avg": data.get("side_b_llm_avg", data.get("enhanced_llm_avg")),
            "side_a_internal_avg": data.get("side_a_internal_avg", data.get("baseline_internal_avg")),
            "side_b_internal_avg": data.get("side_b_internal_avg", data.get("enhanced_internal_avg")),
            "gain": data.get("gain"),
        }
    return normalized


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
        self._comparison_labels: Dict[str, str] = {}
        self._active_sides: List[str] = ["side_a", "side_b"]
        self._scenarios: List[str] = []
        self._case_progresses: Dict[str, CaseProgress] = {}
        self._logs: List[LogEntry] = []
        self._result: Optional[EvaluationResult] = None
        self._results: List[EvaluationResult] = []
        self._start_time: Optional[float] = None
        self._general_result: Optional[EvaluationResult] = None
        self._run_id: Optional[str] = None
        self._run_generation: int = getattr(self, '_run_generation', 0) + 1

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

    def _side_label(self, side: str) -> str:
        defaults = {
            "side_a": "Agent A",
            "side_b": "Agent B",
        }
        return self._comparison_labels.get(side, defaults.get(side, side))

    # ── Pipeline 回调 ─────────────────────────────────────────

    def _pipeline_callback(self, event: str, data: dict):
        """pipeline 进度回调 — 在工作线程中被调用"""
        if self._stop_event.is_set():
            raise InterruptedError("评测已被用户中止")

        if event == "pipeline_start":
            self._current_profile = data.get("profile")
            self._scenarios = data.get("scenarios", [])
            self._run_id = data.get("run_id")
            raw_labels = data.get("comparison_labels", {}) or self._comparison_labels
            self._comparison_labels = {
                "side_a": raw_labels.get("side_a") or raw_labels.get("baseline") or "Agent A",
                "side_b": raw_labels.get("side_b") or raw_labels.get("enhanced") or "Agent B",
            }
            raw_active_sides = data.get("active_sides", self._active_sides) or ["side_a", "side_b"]
            self._active_sides = ["side_a" if s in ("baseline", "side_a") else "side_b" for s in raw_active_sides]
            self._add_log("INFO", f"评测启动: mode={data['profile']}, "
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
                elif data.get("status") == "error":
                    elapsed = data.get("elapsed", 0)
                    self._update_case_stage(case_id, stage, "error", elapsed)
                    self._add_log("ERROR", f"[{case_id}] {stage} 失败")
                else:
                    elapsed = data.get("elapsed", 0)
                    self._update_case_stage(case_id, stage, "done", elapsed)
                    self._add_log("INFO", f"[{case_id}] {stage} 完成 ({elapsed:.0f}s)")

        elif event == "stage_start":
            case_id = data.get("case_id", "")
            stage = data.get("stage")
            if case_id and stage:
                self._ensure_case(case_id)
                self._update_case_stage(case_id, stage, "running")

        elif event == "case_done":
            self._done_cases += 1
            case_id = data["case_id"]
            self._current_case = case_id
            self._ensure_case(case_id, data.get("title", ""), data.get("scenario", ""))
            cp = self._case_progresses[case_id]
            cp.status = "done"
            cp.side_a_total = data.get("side_a_total")
            cp.side_b_total = data.get("side_b_total")
            cp.gain = data.get("gain")
            gain = data["gain"]
            if cp.side_b_total is not None and gain is not None:
                sign = "+" if gain >= 0 else ""
                self._add_log("INFO",
                              f"用例完成: {case_id} - {data['title']} "
                              f"({self._side_label('side_a')}={cp.side_a_total:.1f}, "
                              f"{self._side_label('side_b')}={cp.side_b_total:.1f}, "
                              f"差值={sign}{gain:.1f})")
            else:
                self._add_log("INFO",
                              f"用例完成: {case_id} - {data['title']} "
                              f"({self._side_label('side_a')}={cp.side_a_total:.1f})")

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
                cp = self._case_progresses[case_id]
                cp.status = "error"
                cp.error = data.get("message", "")
                for stage in cp.stages:
                    if stage.status == "running":
                        stage.status = "error"
            self._add_log("ERROR", f"{prefix}{data['message']}")

    def _infer_case_stage_from_log(self, message: str):
        """从 log message 推断 case 当前正在执行的阶段"""
        # 匹配 [case_id] 开始基线运行/增强运行/规则检查/LLM评分
        m = re.match(r'\[(\w+)\]\s+开始(A侧运行|B侧运行|规则检查|LLM)', message)
        if m:
            case_id = m.group(1)
            stage_keyword = m.group(2)
            stage_map = {
                "A侧运行": "A侧运行",
                "B侧运行": "B侧运行",
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

    def _run_pipeline_thread(self, mode, run_target, profiles, scenarios, case_ids,
                             agent_a, agent_b, skip_baseline,
                             only_run_baseline, generation):
        """工作线程，generation 用于防止旧线程回写状态到新评测"""
        def is_stale():
            return self._run_generation != generation

        try:
            from agent_bench.runner.discovery import ensure_opencode_server
            from agent_bench.pipeline.engine import run_pipeline

            self._add_log("INFO", "正在连接 OpenCode Server...")
            api_base = ensure_opencode_server()
            self._add_log("INFO", f"OpenCode Server 已连接: {api_base}")

            scenario_arg = "all" if "all" in scenarios else ",".join(scenarios)
            case_ids = list(dict.fromkeys(case_ids or []))
            case_ids_arg = ",".join(case_ids) if case_ids else "ALL"
            if mode == "agent_compare":
                if run_target == "both":
                    if not agent_a or not agent_b:
                        raise ValueError("请选择 Agent A 和 Agent B")
                    baseline_agent_id = agent_a.get("agent_id")
                    enhanced_agent_id = agent_b.get("agent_id")
                    comparison_labels = {
                        "side_a": agent_a.get("label") or agent_a.get("agent_id") or "Agent A",
                        "side_b": agent_b.get("label") or agent_b.get("agent_id") or "Agent B",
                    }
                    active_sides = ["side_a", "side_b"]
                    effective_only_run_baseline = False
                elif run_target == "agent_a":
                    if not agent_a:
                        raise ValueError("请选择 Agent A")
                    baseline_agent_id = agent_a.get("agent_id")
                    enhanced_agent_id = None
                    comparison_labels = {
                        "side_a": agent_a.get("label") or agent_a.get("agent_id") or "Agent A",
                        "side_b": "",
                    }
                    active_sides = ["side_a"]
                    effective_only_run_baseline = True
                elif run_target == "agent_b":
                    if not agent_b:
                        raise ValueError("请选择 Agent B")
                    baseline_agent_id = agent_b.get("agent_id")
                    enhanced_agent_id = None
                    comparison_labels = {
                        "side_a": agent_b.get("label") or agent_b.get("agent_id") or "Agent B",
                        "side_b": "",
                    }
                    active_sides = ["side_a"]
                    effective_only_run_baseline = True
                else:
                    raise ValueError(f"不支持的 run_target: {run_target}")

                self._comparison_labels = comparison_labels
                self._active_sides = active_sides
                self._add_log("INFO", f"评测参数: mode={mode}, run_target={run_target}, scenarios={scenario_arg}, "
                              f"case_ids={case_ids_arg}, side_a={comparison_labels['side_a'] or '-'}, "
                              f"side_b={comparison_labels['side_b'] or '-'}")

                result = run_pipeline(
                    profile=mode,
                    cases_override=scenario_arg,
                    case_ids=case_ids,
                    api_base=api_base,
                    dry_run=False,
                    skip_baseline=False,
                    only_run_baseline=effective_only_run_baseline,
                    baseline_agent_id=baseline_agent_id,
                    enhanced_agent_id=enhanced_agent_id,
                    comparison_labels=comparison_labels,
                    active_sides=active_sides,
                    on_progress=self._pipeline_callback,
                )
            else:
                if not profiles:
                    raise ValueError("未选择 Profile")

                profile_arg = profiles[0]
                if len(profiles) > 1:
                    self._add_log("WARN", f"检测到多个 Profile，仅使用第一个: {profile_arg}")

                self._comparison_labels = {}
                self._active_sides = ["side_a", "side_b"]
                self._add_log("INFO", f"评测参数: profile={profile_arg}, scenarios={scenario_arg}, "
                              f"case_ids={case_ids_arg}, skip_baseline={skip_baseline}, "
                              f"only_run_baseline={only_run_baseline}")

                result = run_pipeline(
                    profile=profile_arg,
                    cases_override=scenario_arg,
                    case_ids=case_ids,
                    api_base=api_base,
                    dry_run=False,
                    skip_baseline=skip_baseline,
                    only_run_baseline=only_run_baseline,
                    on_progress=self._pipeline_callback,
                )

            if is_stale():
                return

            if self._stop_event.is_set():
                self._status = EvaluationStatus.STOPPED
                self._add_log("INFO", "评测任务已停止")
                return

            self._result = self._build_result(result)
            self._general_result = self._build_general_result(result.get("results", []))
            self._status = EvaluationStatus.COMPLETED
            self._add_log("INFO", "评测任务已完成")

        except InterruptedError:
            if is_stale():
                return
            self._status = EvaluationStatus.STOPPED
            self._add_log("INFO", "评测任务已停止")
        except Exception as e:
            if is_stale():
                return
            self._status = EvaluationStatus.ERROR
            self._add_log("ERROR", f"评测失败: {str(e)}")

    def _build_general_result(self, general_results: list) -> Optional[EvaluationResult]:
        """从 general_results 构建通用用例的评测结果"""
        if not general_results:
            return None

        try:
            side_a_compilable_count = 0
            side_a_compilable_total = 0
            side_b_compilable_count = 0
            side_b_compilable_total = 0

            for r in general_results:
                compile_results = r.get("compile_results")
                if compile_results:
                    if compile_results.get("side_a_compilable") is not None:
                        side_a_compilable_total += 1
                        if compile_results.get("side_a_compilable"):
                            side_a_compilable_count += 1
                    if compile_results.get("side_b_compilable") is not None:
                        side_b_compilable_total += 1
                        if compile_results.get("side_b_compilable"):
                            side_b_compilable_count += 1

            side_a_rate = f"{side_a_compilable_count}/{side_a_compilable_total}" if side_a_compilable_total > 0 else "N/A"
            side_b_rate = f"{side_b_compilable_count}/{side_b_compilable_total}" if side_b_compilable_total > 0 else "N/A"

            general_data = {
                "side_a_compile_pass_rate": side_a_rate,
                "side_b_compile_pass_rate": side_b_rate,
            }

            general = GeneralResult(
                side_a_compile_pass_rate=side_a_rate,
                side_b_compile_pass_rate=side_b_rate,
                note="通用用例编译检查结果" if side_a_compilable_total > 0 or side_b_compilable_total > 0 else None,
                comparison_labels=self._comparison_labels.copy(),
                active_sides=self._active_sides.copy(),
            )

            cases = []
            for c in general_results:
                compile_results_data = c.get("compile_results")
                compile_results = None
                if compile_results_data:
                    compile_results = CompileResult(
                        side_a_compilable=compile_results_data.get("side_a_compilable"),
                        side_a_error=compile_results_data.get("side_a_error", ""),
                        side_b_compilable=compile_results_data.get("side_b_compilable"),
                        side_b_error=compile_results_data.get("side_b_error", ""),
                    )
                cases.append(CaseResult(
                    case_id=c.get("case_id", ""),
                    title=c.get("title", ""),
                    scenario=c.get("scenario", "general"),
                    side_a_rule=c.get("side_a_rule", 0),
                    side_b_rule=c.get("side_b_rule"),
                    side_a_total=c.get("side_a_total", 0),
                    side_b_total=c.get("side_b_total"),
                    gain=c.get("gain"),
                    dimension_scores=c.get("dimension_scores", {}),
                    compile_results=compile_results,
                ))

            return EvaluationResult(
                run_id="",
                profile="general",
                scenario="general",
                summary=EvaluationSummary(
                    total_cases=len(cases),
                    side_a_avg=0,
                    side_b_avg=None,
                    gain=None,
                    side_a_pass_rate="0/0",
                    side_b_pass_rate="N/A",
                    dimensions={},
                ),
                cases=cases,
                general=general,
                comparison_labels=self._comparison_labels.copy(),
                active_sides=self._active_sides.copy(),
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
                gain = c.get("gain")
                if gain is None and c.get("side_b_total") is not None and c.get("side_a_total") is not None:
                    gain = c.get("side_b_total", 0) - c.get("side_a_total", 0)
                compile_results_data = c.get("compile_results")
                compile_results = None
                if compile_results_data:
                    compile_results = CompileResult(
                        side_a_compilable=compile_results_data.get("side_a_compilable"),
                        side_a_error=compile_results_data.get("side_a_error", ""),
                        side_b_compilable=compile_results_data.get("side_b_compilable"),
                        side_b_error=compile_results_data.get("side_b_error", ""),
                    )
                cases.append(CaseResult(
                    case_id=c.get("case_id", ""),
                    title=c.get("title", ""),
                    scenario=c.get("scenario", ""),
                    side_a_rule=c.get("side_a_rule", 0),
                    side_b_rule=c.get("side_b_rule"),
                    side_a_total=c.get("side_a_total", 0),
                    side_b_total=c.get("side_b_total"),
                    gain=gain,
                    dimension_scores=_normalize_dimension_scores(c.get("dimension_scores", {})),
                    compile_results=compile_results,
                ))

            comparison_labels = data.get("comparison_labels", {}) or pipeline_result.get("comparison_labels", {}) or self._comparison_labels.copy()
            active_sides = data.get("active_sides", []) or pipeline_result.get("active_sides", []) or self._active_sides.copy()

            general_data = data.get("general", {})
            general = None
            if general_data:
                general = GeneralResult(
                    side_a_compile_pass_rate=general_data.get("side_a_compile_pass_rate", "N/A"),
                    side_b_compile_pass_rate=general_data.get("side_b_compile_pass_rate", "N/A"),
                    note=general_data.get("note"),
                    comparison_labels=comparison_labels,
                    active_sides=active_sides,
                )

            eval_result = EvaluationResult(
                run_id=pipeline_result["run_id"],
                profile=data.get("profile", ""),
                scenario=data.get("scenario", ""),
                summary=EvaluationSummary(
                    total_cases=summary.get("total_cases", 0),
                    side_a_avg=summary.get("side_a_avg", 0),
                    side_b_avg=summary.get("side_b_avg"),
                    gain=summary.get("gain"),
                    side_a_pass_rate=summary.get("side_a_pass_rate", "0/0"),
                    side_b_pass_rate=summary.get("side_b_pass_rate", "N/A"),
                    dimensions=_normalize_summary_dimensions(summary.get("dimensions", {})),
                ),
                cases=cases,
                general=general,
                comparison_labels=comparison_labels,
                active_sides=active_sides,
            )
            self._results.append(eval_result)
            return eval_result
        except Exception as e:
            self._add_log("ERROR", f"加载结果失败: {str(e)}")
            return None

    # ── 公开接口 ──────────────────────────────────────────────

    def start_evaluation(self, mode: str, run_target: str, profiles: List[str], scenarios: List[str],
                         case_ids: List[str] = None,
                         agent_a: Dict = None,
                         agent_b: Dict = None,
                         skip_baseline: bool = False, only_run_baseline: bool = False):
        if self._status == EvaluationStatus.RUNNING:
            return False, "评测正在进行中"
        if not scenarios:
            return False, "请选择场景"
        if not case_ids:
            return False, "请选择用例"
        if mode == "agent_compare":
            if run_target == "both" and (not agent_a or not agent_b):
                return False, "请选择 Agent A 和 Agent B"
            if run_target == "agent_a" and not agent_a:
                return False, "请选择 Agent A"
            if run_target == "agent_b" and not agent_b:
                return False, "请选择 Agent B"
        elif not profiles:
            return False, "请选择 Profile"

        self._stop_event.clear()
        self._reset_state()
        self._start_time = datetime.now().timestamp()
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
            args=(mode, run_target, profiles, scenarios, case_ids or [], agent_a, agent_b,
                  skip_baseline, only_run_baseline, self._run_generation),
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
        elapsed = 0
        if self._start_time is not None:
            elapsed = int(datetime.now().timestamp() - self._start_time)
        return EvaluationProgress(
            status=self._status,
            run_id=self._run_id,
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
            elapsed_time=elapsed,
            general_result=self._general_result,
            comparison_labels=self._comparison_labels.copy(),
            active_sides=self._active_sides.copy(),
        )

    def get_log_queue(self) -> queue.Queue:
        return self._log_queue


evaluator_manager = EvaluatorManager()
