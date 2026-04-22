# -*- coding: utf-8 -*-
"""云测协议与本地执行结果的转换。

职责：
1. 将云测平台下发的任务数据转换为本地 case 结构
2. 将本地执行状态映射为云测平台状态枚举
3. 组装进度上报和最终结果上报的载荷
4. 从本地 Agent 产物中提取 metrics、评分等数据
"""

import difflib
import json
import os
from typing import Any, Dict, List, Optional

from agent_bench.cloud_api.iteration_counter import IterationCounter
from agent_bench.cloud_api.models import (
    CloudExecutionResultData,
    CloudExecutionResultPayload,
    CloudStatusReportPayload,
    RemoteExecutionStatus,
)
from agent_bench.pipeline.artifacts import agent_meta_dir, agent_workspace_dir
from agent_bench.pipeline.constraint_adapter import sanitize_constraints_for_semantic_review


# ── 任务数据转换 ──────────────────────────────────────────────


def build_prompt(input_text: str, expected_output: str) -> str:
    """构建 Agent 输入 prompt，当前只取 input_text（expected_output 暂不拼入）。"""
    _ = expected_output
    return (input_text or "").strip()


def build_case(execution_id: int,
               project_dir: str,
               prompt: str,
               case_spec: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
    """将云测任务数据转换为本地 case 字典，供 pipeline 消费。"""
    normalized_case_spec = dict(case_spec or {})
    constraints = normalized_case_spec.get("constraints")
    if isinstance(constraints, list):
        normalized_case_spec["constraints"] = sanitize_constraints_for_semantic_review(constraints)
    case_meta = normalized_case_spec.get("case")
    if not isinstance(case_meta, dict):
        case_meta = {}
    case_meta.setdefault("id", f"cloud_execution_{execution_id}")
    case_meta.setdefault("title", f"Cloud Execution {execution_id}")
    case_meta.setdefault("scenario", "cloud_api")
    case_meta.setdefault("prompt", prompt)
    normalized_case_spec["case"] = case_meta
    return {
        "id": case_meta.get("id", f"cloud_execution_{execution_id}"),
        "title": case_meta.get("title", f"Cloud Execution {execution_id}"),
        "scenario": case_meta.get("scenario", "cloud_api"),
        "prompt": prompt,
        "case_spec": normalized_case_spec,
        "original_project_dir": project_dir,
    }


# ── 状态映射 ──────────────────────────────────────────────────


def map_internal_status_to_remote(local_status: str) -> RemoteExecutionStatus:
    """将本地执行阶段状态字符串映射为云测平台 RemoteExecutionStatus 枚举。"""
    normalized = (local_status or "").lower()
    if normalized == "running":
        return RemoteExecutionStatus.RUNNING
    if normalized == "completed":
        return RemoteExecutionStatus.COMPLETED
    if normalized == "failed":
        return RemoteExecutionStatus.FAILED
    return RemoteExecutionStatus.PENDING


# ── 载荷组装 ──────────────────────────────────────────────────


def build_status_payload(remote_status: RemoteExecutionStatus,
                         error_message: Optional[str],
                         conversation: Optional[list] = None,
                         execution_log: Optional[list] = None) -> Dict[str, Any]:
    """组装进度上报载荷，execution_log 序列化为 JSON 字符串。"""
    execution_log_text = None
    if execution_log is not None:
        execution_log_text = json.dumps(execution_log, ensure_ascii=False)
    payload = CloudStatusReportPayload(
        status=remote_status,
        errorMessage=error_message,
        conversation=conversation,
        executionLog=execution_log_text,
    )
    return payload.model_dump(by_alias=True, exclude_none=True)


# ── 本地产物读取 ──────────────────────────────────────────────


def _load_json_if_exists(path: str) -> Dict[str, Any]:
    """读取 JSON 文件，不存在或解析失败时返回空字典。"""
    if not os.path.exists(path):
        return {}
    try:
        with open(path, "r", encoding="utf-8") as f:
            return json.load(f) or {}
    except Exception:
        return {}


def _load_text_if_exists(path: str) -> str:
    """读取文本文件，不存在或读取失败时返回空字符串。"""
    if not os.path.exists(path):
        return ""
    try:
        with open(path, "r", encoding="utf-8") as f:
            return f.read()
    except Exception:
        return ""


def load_agent_metrics(case_dir: str) -> Dict[str, Any]:
    """加载 Agent 交互指标，优先读取 agent_interaction_metrics.json，回退到 interaction_metrics.json。"""
    metrics = _load_json_if_exists(os.path.join(agent_meta_dir(case_dir), "agent_interaction_metrics.json"))
    if metrics:
        return metrics
    return _load_json_if_exists(os.path.join(agent_meta_dir(case_dir), "interaction_metrics.json"))


def load_agent_output(case_dir: str) -> str:
    """加载 Agent 输出文本。"""
    return _load_text_if_exists(os.path.join(agent_meta_dir(case_dir), "output.txt"))


# ── 指标提取 ──────────────────────────────────────────────────

_ITERATION_COUNTER = IterationCounter()


def _extract_total_tokens(metrics: Dict[str, Any]) -> int:
    """从 metrics 中提取总 token 数。

    优先级：
    1. message_history 中所有消息的 token 求和（覆盖多轮交互的真实消耗）
    2. derived.usage.total_tokens
    3. http.message_info.info.tokens.total（仅最后一条消息，作为兜底）
    """
    http = metrics.get("http") if isinstance(metrics.get("http"), dict) else {}
    message_history = http.get("message_history") if isinstance(http.get("message_history"), list) else []
    if message_history:
        total = 0
        for msg in message_history:
            if not isinstance(msg, dict):
                continue
            info = msg.get("info") if isinstance(msg.get("info"), dict) else {}
            tokens = info.get("tokens") if isinstance(info.get("tokens"), dict) else {}
            if not tokens:
                continue
            total += int(tokens.get("input", 0) or 0)
            total += int(tokens.get("output", 0) or 0)
            total += int(tokens.get("reasoning", 0) or 0)
            cache = tokens.get("cache") if isinstance(tokens.get("cache"), dict) else {}
            total += int(cache.get("read", 0) or 0)
            total += int(cache.get("write", 0) or 0)
        if total > 0:
            return total

    derived = metrics.get("derived") if isinstance(metrics.get("derived"), dict) else {}
    usage = derived.get("usage") if isinstance(derived, dict) else {}
    for value in (
        usage.get("total_tokens"),
        ((http.get("message_info") or {}).get("info") or {}).get("tokens", {}).get("total"),
    ):
        if value is not None:
            try:
                return int(value)
            except (TypeError, ValueError):
                pass
    return 0


def _extract_iteration_count(metrics: Dict[str, Any], output_text: str = "") -> int:
    """提取迭代次数。"""
    return _ITERATION_COUNTER.extract_iteration_count(
        metrics,
        output_text=output_text,
        total_tokens=_extract_total_tokens(metrics),
    )


# ── 评分计算 ──────────────────────────────────────────────────


def _score_expected_output(expected_output: str, actual_output: str) -> int:
    """计算期望结果匹配分：精确包含得 100，否则按序列相似度百分比。"""
    expected = " ".join((expected_output or "").split()).strip()
    actual = " ".join((actual_output or "").split()).strip()
    if not expected:
        return 0
    if not actual:
        return 0
    if expected in actual:
        return 100
    ratio = difflib.SequenceMatcher(None, expected, actual).ratio()
    return max(0, min(100, int(round(ratio * 100))))


def _score_code_quality(is_build_success: bool) -> int:
    """编译通过则代码质量分 100，否则 0。"""
    return 100 if is_build_success else 0


def _normalize_score_value(value: Any) -> Optional[int]:
    """将评分值归一化到 0-100 整数，支持 "85/100" 格式；无法解析时返回 None。"""
    if value is None:
        return None
    text = str(value).strip()
    if not text:
        return None
    if "/" in text:
        text = text.split("/", 1)[0].strip()
    try:
        score = float(text)
    except (TypeError, ValueError):
        return None
    return max(0, min(100, int(round(score))))


# ── 最终结果载荷 ──────────────────────────────────────────────


def build_execution_result_payload(execution_id: int,
                                   case_dir: str,
                                   result: Dict[str, Any],
                                   expected_output: str,
                                   execution_time_s: int,
                                   output_code_url: str,
                                   diff_file_url: str,
                                   code_quality_score: Optional[int] = None,
                                   expected_output_score: Optional[int] = None) -> Dict[str, Any]:
    """组装最终结果上报载荷。

    当前执行链已移除约束打分与静态代码打分，两个评分字段固定按 0 上报。
    """
    metrics = load_agent_metrics(case_dir)
    output_text = load_agent_output(case_dir)
    compile_results = result.get("compile_results") or {}

    is_build_success = bool(compile_results.get("compilable"))
    token_consumption = _extract_total_tokens(metrics)
    iteration_count = _extract_iteration_count(metrics, output_text)

    payload = CloudExecutionResultPayload(
        testExecutionId=execution_id,
        data=CloudExecutionResultData(
            isBuildSuccess=is_build_success,
            executionTime=max(0, int(execution_time_s)),
            tokenConsumption=max(0, int(token_consumption)),
            iterationCount=max(0, int(iteration_count)),
            codeQualityScore=0,
            expectedOutputScore=0,
            outputCodeUrl=output_code_url,
            diffFileUrl=diff_file_url,
        ),
    )
    return payload.model_dump(by_alias=True, exclude_none=True)
