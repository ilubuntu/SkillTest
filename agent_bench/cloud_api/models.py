# -*- coding: utf-8 -*-
"""云测协议数据模型。

定义与云测平台交互的请求/响应结构体，包括：
- 任务下发（CloudExecutionStartRequest）
- 进度上报（CloudStatusReportPayload）
- 最终结果上报（CloudExecutionResultPayload）
"""

from enum import Enum
from typing import Any, Dict, List, Optional

from pydantic import BaseModel, Field, field_validator


class RemoteExecutionStatus(str, Enum):
    """任务远程状态枚举，映射本地执行阶段到云测平台状态。"""
    PENDING = "pending"
    RUNNING = "running"
    COMPLETED = "completed"
    FAILED = "failed"


class CloudTestCasePayload(BaseModel):
    """云测平台下发的测试用例载荷。"""
    input: str = ""
    expectedOutput: str = ""
    fileUrl: str = ""

    @field_validator("fileUrl", mode="before")
    @classmethod
    def _normalize_file_url(cls, value):
        return "" if value is None else value


class CloudDispatchPayload(BaseModel):
    """云测平台下发的任务调度载荷。"""
    executionId: int
    testCase: CloudTestCasePayload


class CloudExecutionStartRequest(CloudDispatchPayload):
    """任务启动请求，在调度载荷基础上附带云端连接信息。"""
    cloudBaseUrl: str = ""
    agentId: str = ""
    token: str = ""
    requestHost: str = ""
    executorHostname: str = ""


class CloudStatusReportPayload(BaseModel):
    """进度上报载荷，包含当前状态、错误信息、会话记录和执行日志。"""
    status: RemoteExecutionStatus
    errorMessage: Optional[str] = None
    conversation: Optional[List[Dict[str, Any]]] = None
    executionLog: Optional[str] = None


class CloudExecutionResultData(BaseModel):
    """最终结果上报的数据字段。"""
    isBuildSuccess: bool
    executionTime: int
    tokenConsumption: int
    iterationCount: int
    codeQualityScore: int
    expectedOutputScore: int
    outputCodeUrl: str
    diffFileUrl: str


class CloudExecutionResultPayload(BaseModel):
    """最终结果上报载荷，关联任务ID与结果数据。"""
    testExecutionId: int = Field(..., alias="testExecutionId")
    data: CloudExecutionResultData

    model_config = {
        "populate_by_name": True,
    }
