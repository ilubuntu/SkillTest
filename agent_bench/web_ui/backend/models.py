from pydantic import BaseModel
from typing import List, Optional, Dict, Any
from enum import Enum


class CascaderOption(BaseModel):
    value: str
    label: str
    children: List[Dict[str, Any]]


class ProfileInfo(BaseModel):
    id: str = ""
    name: str
    description: str
    scenarios: List[str]


class ScenarioInfo(BaseModel):
    name: str
    description: str
    case_count: int


class EvaluationStatus(str, Enum):
    IDLE = "idle"
    RUNNING = "running"
    COMPLETED = "completed"
    STOPPED = "stopped"
    ERROR = "error"


class EvaluationConfig(BaseModel):
    profiles: List[str]
    scenarios: List[str]
    skip_baseline: bool = False


class LogEntry(BaseModel):
    timestamp: str
    level: str
    message: str
    detail: Optional[str] = None


class CompileResult(BaseModel):
    baseline_compilable: Optional[bool] = None
    baseline_error: str = ""
    enhanced_compilable: Optional[bool] = None
    enhanced_error: str = ""


class CaseResult(BaseModel):
    case_id: str
    title: str
    scenario: str
    baseline_rule: float
    enhanced_rule: float
    baseline_total: float
    enhanced_total: float
    gain: float
    dimension_scores: Dict[str, Any]  # {dimId: {name, baseline: {llm, internal}, enhanced: {llm, internal}}}
    compile_results: Optional[CompileResult] = None


class GeneralResult(BaseModel):
    baseline_compile_pass_rate: str = "N/A"
    enhanced_compile_pass_rate: str = "N/A"
    note: Optional[str] = None


class EvaluationSummary(BaseModel):
    total_cases: int
    baseline_avg: float
    enhanced_avg: float
    gain: float
    baseline_pass_rate: str
    enhanced_pass_rate: str
    dimensions: Dict[str, Any]  # {dimId: {name, baseline_llm_avg, baseline_internal_avg, enhanced_llm_avg, enhanced_internal_avg, gain}}


class EvaluationResult(BaseModel):
    run_id: str
    profile: str
    scenario: str
    summary: EvaluationSummary
    cases: List[CaseResult]
    general: Optional[GeneralResult] = None


class CaseStage(BaseModel):
    name: str
    status: str = "pending"       # pending, running, done, skipped, error
    elapsed: Optional[float] = None

class CaseProgress(BaseModel):
    case_id: str
    title: str
    scenario: str
    status: str = "pending"       # pending, running, done, error
    stages: List[CaseStage] = []
    baseline_total: Optional[float] = None
    enhanced_total: Optional[float] = None
    gain: Optional[float] = None
    error: Optional[str] = None

class EvaluationProgress(BaseModel):
    status: EvaluationStatus
    run_id: Optional[str] = None
    total_cases: int = 0
    done_cases: int = 0
    current_case: Optional[str] = None
    current_profile: Optional[str] = None
    current_scenario: Optional[str] = None
    scenarios: List[str] = []
    case_progresses: List[CaseProgress] = []
    logs: List[LogEntry]
    result: Optional[EvaluationResult] = None
    results: List[EvaluationResult] = []
    elapsed_time: int = 0
    general_result: Optional[EvaluationResult] = None
