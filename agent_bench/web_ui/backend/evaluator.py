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
        self._log_queue: queue.Queue = queue.Queue()
        self._stop_event = threading.Event()

    def _add_log(self, level: str, message: str, detail: Optional[str] = None):
        entry = LogEntry(
            timestamp=datetime.now().strftime("%H:%M:%S"),
            level=level,
            message=message,
            detail=detail
        )
        self._logs.append(entry)
        self._log_queue.put(entry)

    def _parse_progress_from_log(self, line: str) -> tuple:
        msg = line.strip()
        progress = self._progress
        current_case = self._current_case
        current_profile = self._current_profile
        current_scenario = self._current_scenario

        if "基线运行" in msg:
            self._add_log("INFO", "基线评测任务启动", current_case)
        elif "增强运行" in msg:
            self._add_log("INFO", "增强评测任务启动", current_case)
        elif "] " in msg and "-" in msg:
            parts = msg.split("] ", 1)
            if len(parts) > 1:
                case_info = parts[1].split(" - ")
                if len(case_info) > 1:
                    current_case = case_info[0].strip()
                    self._current_case = current_case
        
        if "[INFO]" in msg or "[DEBUG]" in msg:
            if "OpenCode" in msg or "Server" in msg:
                self._add_log("INFO", "OpenCode Server 启动")
            elif "评测系统" in msg:
                self._add_log("INFO", "评测系统初始化完成")
        
        if "完成" in msg and "s)" in msg:
            self._progress += 2
            progress = min(self._progress, 100)

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

    def start_evaluation(self, profiles: List[str], scenarios: List[str], skip_baseline: bool = False):
        if self._status == EvaluationStatus.RUNNING:
            return False, "评测正在进行中"
        
        self._stop_event.clear()
        self._status = EvaluationStatus.RUNNING
        self._progress = 0
        self._logs = []
        self._result = None
        self._current_case = None
        
        self._add_log("INFO", "评测任务开始")
        
        profile_arg = "all" if "all" in profiles else ",".join(profiles)
        scenario_arg = "all" if "all" in scenarios else ",".join(scenarios)
        
        cli_path = BASE_DIR / "cli.py"
        cmd = [
            sys.executable,
            str(cli_path),
            "--profile", profile_arg,
            "--cases", scenario_arg
        ]
        if skip_baseline:
            cmd.append("--skip-baseline")
        
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
                target=self._monitor_process,
                daemon=True
            )
            self._monitor_thread.start()
            
            return True, "评测已启动"
        except Exception as e:
            self._status = EvaluationStatus.ERROR
            self._add_log("ERROR", f"启动失败: {str(e)}")
            return False, str(e)

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
            result=self._result
        )

    def get_log_queue(self) -> queue.Queue:
        return self._log_queue


evaluator_manager = EvaluatorManager()
