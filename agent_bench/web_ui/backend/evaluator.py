import os
import sys
import subprocess
import threading
import queue
import json
import time
from datetime import datetime
from typing import Optional, List, Dict, Any
from pathlib import Path

BASE_DIR = Path(__file__).parent.parent.parent
sys.path.insert(0, str(Path(__file__).parent.parent))
sys.path.insert(0, str(BASE_DIR))

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
        
        self._process: Optional[subprocess.Popen] = None
        self._status = EvaluationStatus.IDLE
        self._progress = 0
        self._current_case: Optional[str] = None
        self._current_profile: Optional[str] = None
        self._current_scenario: Optional[str] = None
        self._logs: List[LogEntry] = []
        self._result: Optional[EvaluationResult] = None
        self._results: List[EvaluationResult] = []
        self._log_queue: queue.Queue = queue.Queue()
        self._stop_event = threading.Event()
        self._max_logs = 500
        self._max_queue_size = 500
        self._reader_thread: Optional[threading.Thread] = None
        self._monitor_thread: Optional[threading.Thread] = None
        self._task_start_time: Optional[float] = None

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
        while self._log_queue.qsize() >= self._max_queue_size:
            try:
                self._log_queue.get_nowait()
            except queue.Empty:
                break
        self._log_queue.put(entry)

    def _parse_progress_from_log(self, line: str) -> tuple:
        msg = line.strip()
        progress = self._progress
        current_case = self._current_case
        current_profile = self._current_profile
        current_scenario = self._current_scenario

        if not msg:
            return progress, current_case

        self._add_log("DEBUG", msg)

        if "基线运行" in msg:
            self._add_log("INFO", "开始基线运行", current_case)
        elif "增强运行" in msg:
            self._add_log("INFO", "开始增强运行", current_case)
        elif "] " in msg and "-" in msg:
            parts = msg.split("] ", 1)
            if len(parts) > 1:
                case_info = parts[1].split(" - ")
                if len(case_info) > 1:
                    current_case = case_info[0].strip()
                    self._current_case = current_case
                    self._add_log("INFO", f"开始评测用例: {case_info[1].strip() if len(case_info) > 1 else ''}", current_case)
        
        if "[INFO]" in msg or "[DEBUG]" in msg:
            if "OpenCode" in msg or "Server" in msg:
                self._add_log("INFO", "正在连接 OpenCode Server...")
            elif "评测系统" in msg:
                self._add_log("INFO", "评测系统初始化中...")
            elif "启动命令" in msg:
                self._add_log("INFO", "评测命令已启动")
            elif "加载了" in msg:
                self._add_log("INFO", msg.split("INFO")[1].strip() if "INFO" in msg else msg)
            elif "等待" in msg or "starting" in msg.lower():
                self._add_log("INFO", "正在启动 Agent，请稍后...")
            elif "准备" in msg or "init" in msg.lower():
                self._add_log("INFO", "正在准备环境...")
            elif "执行" in msg or "running" in msg.lower():
                self._add_log("INFO", "正在执行任务...")
        
        if "完成" in msg and "s)" in msg:
            self._progress += 2
            progress = min(self._progress, 100)
            if "基线" in msg:
                self._add_log("INFO", f"基线运行完成 {self._current_case or ''}")
            elif "增强" in msg:
                self._add_log("INFO", f"增强运行完成 {self._current_case or ''}")
            else:
                self._add_log("INFO", f"评测步骤完成 {msg.split('完成')[0].split('...')[-1].strip() if '...' in msg else ''}")

        if "[ERROR]" in msg:
            self._add_log("ERROR", msg.split("[ERROR]")[1].strip() if "[ERROR]" in msg else msg)
        elif "[WARN]" in msg:
            self._add_log("WARN", msg.split("[WARN]")[1].strip() if "[WARN]" in msg else msg)

        return progress, current_case

    def _read_process_output(self, stdout, stderr):
        try:
            for line in iter(stdout.readline, ''):
                if self._stop_event.is_set():
                    break
                if line:
                    progress, current_case = self._parse_progress_from_log(line)
                    self._progress = progress
        except Exception as e:
            self._add_log("ERROR", f"读取stdout异常: {str(e)}")
        
        try:
            for line in iter(stderr.readline, ''):
                if self._stop_event.is_set():
                    break
                if line and ("[ERROR]" in line or "[WARN]" in line):
                    self._add_log("WARN", line.strip())
        except Exception as e:
            self._add_log("ERROR", f"读取stderr异常: {str(e)}")

    def _load_results(self, run_id: str) -> Optional[EvaluationResult]:
        result_path = BASE_DIR / "results" / run_id / "report.json"
        if not result_path.exists():
            return None
        
        try:
            with open(result_path, "r", encoding="utf-8") as f:
                data = json.load(f)
            
            summary = data.get("summary", {})
            cases = []
            for c in data.get("cases", []):
                gain = c.get("enhanced_total", 0) - c.get("baseline_total", 0)
                dim_scores = c.get("dimension_scores", {})
                cases.append(CaseResult(
                    case_id=c.get("case_id", ""),
                    title=c.get("title", ""),
                    scenario=c.get("scenario", ""),
                    baseline_rule=c.get("baseline_rule", 0),
                    enhanced_rule=c.get("enhanced_rule", 0),
                    baseline_total=c.get("baseline_total", 0),
                    enhanced_total=c.get("enhanced_total", 0),
                    gain=gain,
                    dimension_scores=dim_scores
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
            
            return EvaluationResult(
                run_id=run_id,
                profile=data.get("profile", ""),
                scenario=data.get("scenario", ""),
                summary=summary_obj,
                cases=cases
            )
        except Exception as e:
            self._add_log("ERROR", f"加载结果失败: {str(e)}")
            return None

    def start_evaluation(self, profiles: List[str], scenarios: List[str]):
        if self._status == EvaluationStatus.RUNNING:
            return False, "评测正在进行中"
        
        self._stop_event.clear()
        self._status = EvaluationStatus.RUNNING
        self._progress = 0
        self._logs = []
        self._result = None
        self._results = []
        self._current_case = None
        while not self._log_queue.empty():
            try:
                self._log_queue.get_nowait()
            except queue.Empty:
                break
        
        self._add_log("INFO", "评测任务开始")
        
        self._evaluation_tasks = []
        if len(profiles) == len(scenarios):
            for profile, scenario in zip(profiles, scenarios):
                self._evaluation_tasks.append((profile, scenario))
        else:
            for scenario in scenarios:
                for profile in profiles:
                    self._evaluation_tasks.append((profile, scenario))
        
        self._current_task_index = 0
        self._total_tasks = len(self._evaluation_tasks)
        self._add_log("INFO", f"共 {self._total_tasks} 个评测任务")
        
        self._run_next_task()
        
        return True, "评测已启动"

    def _run_next_task(self):
        if self._stop_event.is_set():
            return
            
        if self._current_task_index >= self._total_tasks:
            self._status = EvaluationStatus.COMPLETED
            self._progress = 100
            self._add_log("INFO", "所有评测任务已完成")
            self._result = self._results[0] if self._results else None
            return
        
        self._task_start_time = time.time()
        profile, scenario = self._evaluation_tasks[self._current_task_index]
        self._current_profile = profile
        self._current_scenario = scenario
        self._add_log("INFO", f"开始任务 {self._current_task_index + 1}/{self._total_tasks}: {scenario} + {profile}")
        
        cli_path = BASE_DIR / "cli.py"
        cmd = [
            sys.executable,
            str(cli_path),
            "--profile", profile,
            "--cases", scenario
        ]
        
        self._add_log("INFO", f"启动命令: {' '.join(cmd)}")
        
        try:
            self._process = subprocess.Popen(
                cmd,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
                bufsize=1,
                cwd=str(BASE_DIR)
            )
            
            self._reader_thread = threading.Thread(
                target=self._read_process_output,
                args=(self._process.stdout, self._process.stderr),
                daemon=True
            )
            self._reader_thread.start()
            
            self._monitor_thread = threading.Thread(
                target=self._monitor_single_task,
                daemon=True
            )
            self._monitor_thread.start()
            
        except Exception as e:
            self._add_log("ERROR", f"启动失败: {str(e)}")
            self._status = EvaluationStatus.ERROR

    def _monitor_single_task(self):
        while not self._stop_event.is_set():
            if self._process and self._process.poll() is not None:
                break
            time.sleep(0.5)
        
        if self._stop_event.is_set():
            self._status = EvaluationStatus.STOPPED
            self._add_log("INFO", "评测任务已停止")
            return
        
        if self._process and self._process.poll() is not None:
            return_code = self._process.wait()
            
            if return_code == 0:
                self._progress = int((self._current_task_index + 1) / self._total_tasks * 100)
                
                profile, scenario = self._evaluation_tasks[self._current_task_index]
                run_id = self._find_run_id_for_task(profile, scenario)
                if run_id:
                    result = self._load_results(run_id)
                    if result:
                        self._results.append(result)
                
                self._current_task_index += 1
                self._add_log("INFO", f"任务 {self._current_task_index}/{self._total_tasks} 完成")
                
                if self._reader_thread:
                    self._reader_thread.join(timeout=2)
                    self._reader_thread = None
                
                self._run_next_task()
            else:
                self._status = EvaluationStatus.ERROR
                self._add_log("ERROR", f"评测失败，退出码: {return_code}")
        
        if self._reader_thread:
            self._reader_thread.join(timeout=2)
            self._reader_thread = None

    def _monitor_process(self):
        while not self._stop_event.is_set():
            if self._process and self._process.poll() is not None:
                break
            time.sleep(0.5)
        
        if self._process and self._process.poll() is not None:
            return_code = self._process.wait()
            
            if self._stop_event.is_set():
                self._status = EvaluationStatus.STOPPED
                self._add_log("INFO", "评测任务已停止")
            elif return_code == 0:
                self._status = EvaluationStatus.COMPLETED
                self._progress = 100
                self._add_log("INFO", "评测任务已完成")
                
                run_id = self._find_latest_run_id()
                if run_id:
                    self._result = self._load_results(run_id)
            else:
                self._status = EvaluationStatus.ERROR
                self._add_log("ERROR", f"评测失败，退出码: {return_code}")
        
        if self._reader_thread:
            self._reader_thread.join(timeout=2)
            self._reader_thread = None

    def _find_latest_run_id(self) -> Optional[str]:
        results_dir = BASE_DIR / "results"
        if not results_dir.exists():
            return None
        
        run_ids = []
        for d in results_dir.iterdir():
            if d.is_dir() and (d / "report.json").exists():
                run_ids.append((d.name, d.stat().st_mtime))
        
        if not run_ids:
            return None
        
        run_ids.sort(key=lambda x: x[1], reverse=True)
        return run_ids[0][0]

    def _find_run_id_for_task(self, profile: str, scenario: str) -> Optional[str]:
        results_dir = BASE_DIR / "results"
        if not results_dir.exists():
            return None
        
        start_time = self._task_start_time
        if start_time is None:
            start_time = 0
        candidate = None
        
        for d in results_dir.iterdir():
            if not d.is_dir() or not (d / "report.json").exists():
                continue
            if d.stat().st_mtime < start_time:
                continue
            if profile in d.name and scenario in d.name:
                if candidate is None or d.stat().st_mtime > candidate[1]:
                    candidate = (d.name, d.stat().st_mtime)
        
        return candidate[0] if candidate else None

    def stop_evaluation(self):
        if self._status != EvaluationStatus.RUNNING:
            return False, "没有正在运行的评测任务"
        
        self._stop_event.set()
        
        if self._process:
            self._process.terminate()
            try:
                self._process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                self._process.kill()
                self._process.wait()
        
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
