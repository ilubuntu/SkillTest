from pydantic import BaseModel
from typing import List, Optional, Dict, Any
from enum import Enum


class CascaderOption(BaseModel):
    value: str
    label: str
    children: List[Dict[str, Any]]


class ProfileInfo(BaseModel):
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


class InternalRuleResult(BaseModel):
    compatibility: Optional[Dict[str, Any]] = None
    ecosystem: Optional[Dict[str, Any]] = None
    code_quality: Optional[Dict[str, Any]] = None


class CaseResult(BaseModel):
    case_id: str
    title: str
    scenario: str
    baseline_rule: float
    enhanced_rule: float
    baseline_internal: float = 0.0
    enhanced_internal: float = 0.0
    baseline_total: float
    enhanced_total: float
    gain: float
    dimension_scores: Dict[str, Dict[str, float]]
    baseline_internal_detail: Optional[InternalRuleResult] = None
    enhanced_internal_detail: Optional[InternalRuleResult] = None


class EvaluationSummary(BaseModel):
    total_cases: int
    baseline_avg: float
    enhanced_avg: float
    gain: float
    baseline_pass_rate: str
    enhanced_pass_rate: str
    dimensions: Dict[str, Dict[str, float]]


class EvaluationResult(BaseModel):
    run_id: str
    profile: str
    scenario: str
    summary: EvaluationSummary
    cases: List[CaseResult]


class EvaluationProgress(BaseModel):
    status: EvaluationStatus
    progress: int
    current_case: Optional[str] = None
    current_profile: Optional[str] = None
    current_scenario: Optional[str] = None
    logs: List[LogEntry]
    result: Optional[EvaluationResult] = None
    results: List[EvaluationResult] = []
