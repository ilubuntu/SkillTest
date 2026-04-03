# -*- coding: utf-8 -*-
"""云测协议与本地执行结果的转换。"""

import difflib
import json
import os
from typing import Any, Dict, List, Optional

from agent_bench.cloud_api.models import (
    CloudExecutionResultData,
    CloudExecutionResultPayload,
    CloudStatusReportPayload,
    RemoteExecutionStatus,
)
from agent_bench.pipeline.artifacts import stage_meta_dir


CLOUD_SCORE_RUBRIC = [
    {
        "name": "代码质量",
        "weight": 50,
        "criteria": "重点评估代码结构、静态正确性、可读性、可维护性，以及是否符合 ArkTS/HarmonyOS 工程实践。",
    },
    {
        "name": "期望结果符合度",
        "weight": 50,
        "criteria": "重点评估是否完成任务输入与期望结果，功能修复是否直接命中当前问题，最终效果是否清晰可信。",
    },
]


def build_prompt(input_text: str, expected_output: str) -> str:
    prompt = (input_text or "").strip()
    expected = (expected_output or "").strip()
    if expected:
        if prompt:
            prompt += "\n\n"
        prompt += f"期望结果：{expected}"
    return prompt


def is_placeholder_text(value: str) -> bool:
    normalized = (value or "").strip()
    if not normalized:
        return True
    placeholders = {
        "输入内容",
        "输出内容",
        "期望结果",
        "任务输入",
        "expectedoutput",
        "input",
        "output",
    }
    lowered = normalized.lower().replace(" ", "")
    return normalized in placeholders or lowered in placeholders


def build_case(execution_id: int, project_dir: str, prompt: str) -> Dict[str, Any]:
    return {
        "id": f"cloud_execution_{execution_id}",
        "title": f"Cloud Execution {execution_id}",
        "scenario": "cloud_api",
        "prompt": prompt,
        "case_spec": {},
        "original_project_dir": project_dir,
    }


def stage_to_local_status(stage_name: str) -> Optional[str]:
    mapping = {
        "A侧运行": "agent_running",
        "A侧编译": "agent_compile_checking",
    }
    return mapping.get(stage_name)


def map_internal_status_to_remote(local_status: str) -> RemoteExecutionStatus:
    normalized = (local_status or "").lower()
    if normalized == "running":
        return RemoteExecutionStatus.RUNNING
    if normalized == "completed":
        return RemoteExecutionStatus.COMPLETED
    if normalized == "failed":
        return RemoteExecutionStatus.FAILED
    return RemoteExecutionStatus.PENDING


def build_status_payload(remote_status: RemoteExecutionStatus,
                         error_message: Optional[str],
                         conversation: list = None) -> Dict[str, Any]:
    payload = CloudStatusReportPayload(
        status=remote_status,
        errorMessage=error_message,
        conversation=None,
    )
    return payload.model_dump(by_alias=True, exclude_none=True)


def _load_json_if_exists(path: str) -> Dict[str, Any]:
    if not os.path.exists(path):
        return {}
    try:
        with open(path, "r", encoding="utf-8") as f:
            return json.load(f) or {}
    except Exception:
        return {}


def _load_text_if_exists(path: str) -> str:
    if not os.path.exists(path):
        return ""
    try:
        with open(path, "r", encoding="utf-8") as f:
            return f.read()
    except Exception:
        return ""


def load_side_metrics(case_dir: str, side: str) -> Dict[str, Any]:
    return _load_json_if_exists(os.path.join(stage_meta_dir(case_dir, side), "interaction_metrics.json"))


def load_side_output(case_dir: str, side: str) -> str:
    return _load_text_if_exists(os.path.join(stage_meta_dir(case_dir, side), "output.txt"))


def _extract_constraint_target_files(case: Dict[str, Any]) -> List[str]:
    case_spec = case.get("case_spec") or {}
    constraints = case_spec.get("constraints") or []
    paths: List[str] = []
    seen = set()
    for item in constraints:
        if not isinstance(item, dict):
            continue
        check_method = item.get("check_method") or {}
        rules = check_method.get("rules") or []
        for rule in rules:
            if not isinstance(rule, dict):
                continue
            path = (rule.get("target_file") or "").strip()
            if not path or path in seen:
                continue
            seen.add(path)
            paths.append(path)
    return paths


def load_side_scoring_text(case_dir: str, side: str, case: Dict[str, Any], fallback_output: str = "") -> str:
    project_dir = os.path.join(case_dir, side)
    changed_files_path = os.path.join(stage_meta_dir(case_dir, side), "changed_files.json")
    changed_files = _load_json_if_exists(changed_files_path).get("changed_files", []) or []

    paths: List[str] = []
    seen = set()
    for rel_path in list(changed_files) + _extract_constraint_target_files(case):
        normalized = (rel_path or "").strip()
        if not normalized or normalized in seen:
            continue
        seen.add(normalized)
        paths.append(normalized)

    chunks: List[str] = []
    for rel_path in paths:
        abs_path = os.path.join(project_dir, rel_path)
        if not os.path.isfile(abs_path):
            continue
        content = _load_text_if_exists(abs_path)
        if not content:
            continue
        chunks.append(f"// FILE: {rel_path}\n{content}")

    if chunks:
        return "\n\n".join(chunks)
    return fallback_output or ""


def _extract_total_tokens(metrics: Dict[str, Any]) -> int:
    usage = metrics.get("usage") or {}
    for candidate in (
        usage.get("total_tokens"),
        ((metrics.get("raw") or {}).get("message_info") or {}).get("info", {}).get("tokens", {}).get("total"),
    ):
        if candidate is not None:
            try:
                return int(candidate)
            except (TypeError, ValueError):
                pass
    return 0


def _score_expected_output(expected_output: str, actual_output: str) -> int:
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
    return 100 if is_build_success else 0


def build_execution_result_payload(execution_id: int,
                                   case_dir: str,
                                   result: Dict[str, Any],
                                   expected_output: str,
                                   execution_time_ms: int,
                                   output_code_url: str,
                                   code_quality_score: Optional[int] = None,
                                   expected_output_score: Optional[int] = None) -> Dict[str, Any]:
    side = "side_a"
    metrics = load_side_metrics(case_dir, side)
    output_text = load_side_output(case_dir, side)
    compile_results = result.get("compile_results") or {}

    is_build_success = bool(compile_results.get("side_a_compilable"))
    token_consumption = _extract_total_tokens(metrics)

    payload = CloudExecutionResultPayload(
        testExecutionId=execution_id,
        data=CloudExecutionResultData(
            isBuildSuccess=is_build_success,
            executionTime=max(0, int(execution_time_ms)),
            tokenConsumption=max(0, int(token_consumption)),
            iterationCount=0,
            codeQualityScore=_score_code_quality(is_build_success) if code_quality_score is None else max(0, min(100, int(code_quality_score))),
            expectedOutputScore=_score_expected_output(expected_output, output_text) if expected_output_score is None else max(0, min(100, int(expected_output_score))),
            outputCodeUrl=output_code_url,
        ),
    )
    return payload.model_dump(by_alias=True, exclude_none=True)
