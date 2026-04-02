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


class AgentInfo(BaseModel):
    id: str
    name: str
    adapter: str
    api_base: str
    model: Optional[str] = None


class AgentSideConfig(BaseModel):
    agent_id: str
    label: Optional[str] = None


class EvaluationStatus(str, Enum):
    IDLE = "idle"
    RUNNING = "running"
    COMPLETED = "completed"
    STOPPED = "stopped"
    ERROR = "error"


class EvaluationConfig(BaseModel):
    mode: str = "agent_compare"
    run_target: str = "both"
    profiles: List[str] = []
    scenarios: List[str]
    case_ids: List[str] = []
    agent_a: Optional[AgentSideConfig] = None
    agent_b: Optional[AgentSideConfig] = None
    skip_baseline: bool = False
    only_run_baseline: bool = False


class LogEntry(BaseModel):
    timestamp: str
    level: str
    message: str
    detail: Optional[str] = None


class CompileResult(BaseModel):
    side_a_compilable: Optional[bool] = None
    side_a_error: str = ""
    side_b_compilable: Optional[bool] = None
    side_b_error: str = ""


class CaseResult(BaseModel):
    case_id: str
    title: str
    scenario: str
    side_a_rule: Optional[float] = None
    side_b_rule: Optional[float] = None
    side_a_total: float
    side_b_total: Optional[float] = None
    gain: Optional[float] = None
    dimension_scores: Dict[str, Any]  # {dimId: {name, side_a: {llm, internal}, side_b: {llm, internal}}}
    compile_results: Optional[CompileResult] = None


class GeneralResult(BaseModel):
    side_a_compile_pass_rate: str = "N/A"
    side_b_compile_pass_rate: str = "N/A"
    note: Optional[str] = None
    comparison_labels: Dict[str, str] = {}
    active_sides: List[str] = []


class EvaluationSummary(BaseModel):
    total_cases: int
    side_a_avg: float
    side_b_avg: Optional[float] = None
    gain: Optional[float] = None
    side_a_pass_rate: str
    side_b_pass_rate: str
    dimensions: Dict[str, Any]  # {dimId: {name, side_a_llm_avg, side_a_internal_avg, side_b_llm_avg, side_b_internal_avg, gain}}


class EvaluationResult(BaseModel):
    run_id: str
    profile: str
    scenario: str
    summary: EvaluationSummary
    cases: List[CaseResult]
    general: Optional[GeneralResult] = None
    comparison_labels: Dict[str, str] = {}
    active_sides: List[str] = []


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
    side_a_total: Optional[float] = None
    side_b_total: Optional[float] = None
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
    comparison_labels: Dict[str, str] = {}
    active_sides: List[str] = []
