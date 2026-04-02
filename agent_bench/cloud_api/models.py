from enum import Enum
from typing import Any, Dict, List, Optional

from pydantic import BaseModel, Field


class RemoteExecutionStatus(str, Enum):
    PENDING = "pending"
    RUNNING = "running"
    COMPLETED = "completed"
    FAILED = "failed"


class CloudTestCasePayload(BaseModel):
    input: str = ""
    expectedOutput: str = ""
    fileUrl: str


class CloudDispatchPayload(BaseModel):
    executionId: int
    testCase: CloudTestCasePayload


class CloudExecutionStartRequest(CloudDispatchPayload):
    cloudBaseUrl: str
    agentId: str


class CloudStatusReportPayload(BaseModel):
    status: RemoteExecutionStatus
    errorMessage: Optional[str] = None
    conversation: Optional[List[Dict[str, Any]]] = None


class CloudExecutionResultData(BaseModel):
    isBuildSuccess: bool
    executionTime: int
    tokenConsumption: int
    iterationCount: int
    codeQualityScore: int
    expectedOutputScore: int
    outputCodeUrl: str


class CloudExecutionResultPayload(BaseModel):
    testExecutionId: int = Field(..., alias="testExecutionId")
    data: CloudExecutionResultData

    model_config = {
        "populate_by_name": True,
    }
