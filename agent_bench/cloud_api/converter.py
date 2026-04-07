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
from agent_bench.pipeline.artifacts import agent_meta_dir, agent_workspace_dir


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
    _ = expected_output
    return (input_text or "").strip()


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


def build_case(execution_id: int,
               project_dir: str,
               prompt: str,
               case_spec: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
    return {
        "id": f"cloud_execution_{execution_id}",
        "title": f"Cloud Execution {execution_id}",
        "scenario": "cloud_api",
        "prompt": prompt,
        "case_spec": case_spec or {},
        "original_project_dir": project_dir,
    }


def stage_to_local_status(stage_name: str) -> Optional[str]:
    mapping = {
        "Agent运行": "agent_running",
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
        conversation=conversation,
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


def load_agent_metrics(case_dir: str) -> Dict[str, Any]:
    metrics = _load_json_if_exists(os.path.join(agent_meta_dir(case_dir), "agent_interaction_metrics.json"))
    if metrics:
        return metrics
    return _load_json_if_exists(os.path.join(agent_meta_dir(case_dir), "interaction_metrics.json"))


def load_agent_output(case_dir: str) -> str:
    return _load_text_if_exists(os.path.join(agent_meta_dir(case_dir), "output.txt"))


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


def load_agent_scoring_text(case_dir: str, case: Dict[str, Any], fallback_output: str = "") -> str:
    project_dir = agent_workspace_dir(case_dir)
    changed_files_path = os.path.join(agent_meta_dir(case_dir), "changed_files.json")
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
    for value in (
        usage.get("total_tokens"),
        ((metrics.get("raw") or {}).get("message_info") or {}).get("info", {}).get("tokens", {}).get("total"),
    ):
        if value is not None:
            try:
                return int(value)
            except (TypeError, ValueError):
                pass
    return 0


def _extract_build_skill_execution_count(metrics: Dict[str, Any]) -> int:
    if not isinstance(metrics, dict):
        return 0

    raw = metrics.get("raw") or {}
    parts = []
    if isinstance(raw, dict):
        message_info = raw.get("message_info") or {}
        if isinstance(message_info, dict) and isinstance(message_info.get("parts"), list):
            parts = message_info.get("parts") or []

    seen = set()
    count = 0
    for part in parts:
        if not isinstance(part, dict):
            continue
        part_type = str(part.get("type") or "").strip().lower()
        if part_type not in {"tool", "skill"}:
            continue

        serialized = json.dumps(part, ensure_ascii=False).lower()
        state = part.get("state") if isinstance(part.get("state"), dict) else {}
        status = str(state.get("status") or "").strip().lower()
        output = str(state.get("output") or "")
        metadata = state.get("metadata") if isinstance(state.get("metadata"), dict) else {}
        metadata_output = str(metadata.get("output") or "")
        command_input = state.get("input") if isinstance(state.get("input"), dict) else {}
        command = str(command_input.get("command") or command_input.get("cmd") or "")

        is_build_skill = "build-harmony-project" in serialized
        is_build_command = any(
            token in (serialized + "\n" + command.lower() + "\n" + output.lower() + "\n" + metadata_output.lower())
            for token in ("hvigor", "assemblehap", "--stop-daemon")
        )
        if not is_build_skill and not is_build_command:
            continue

        if status not in {"completed", "running"} and not metadata_output and not output:
            continue

        identity = (
            str(part.get("callID") or "").strip()
            or str(part.get("id") or "").strip()
            or json.dumps(command_input, ensure_ascii=False, sort_keys=True)
        )
        if not identity or identity in seen:
            continue
        seen.add(identity)
        count += 1

    return count


def _extract_iteration_count(metrics: Dict[str, Any], output_text: str = "") -> int:
    if not isinstance(metrics, dict):
        return 1 if (output_text or "").strip() else 0

    build_execution_count = _extract_build_skill_execution_count(metrics)
    if build_execution_count > 0:
        return build_execution_count

    raw = metrics.get("raw") or {}
    parts = []
    if isinstance(raw, dict):
        message_info = raw.get("message_info") or {}
        if isinstance(message_info, dict) and isinstance(message_info.get("parts"), list):
            parts = message_info.get("parts") or []
    step_count = 0
    for part in parts:
        if not isinstance(part, dict):
            continue
        if str(part.get("type") or "").lower() == "step-start":
            step_count += 1
    if step_count > 0:
        return step_count

    observed_calls = (((metrics.get("tools") or {}).get("observed_calls")) or [])
    if isinstance(observed_calls, list) and observed_calls:
        return len(observed_calls) + 1

    if (metrics.get("session_id") or "").strip():
        return 1
    if _extract_total_tokens(metrics) > 0:
        return 1
    return 1 if (output_text or "").strip() else 0


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


def _normalize_score_value(value: Any) -> Optional[int]:
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


def build_execution_result_payload(execution_id: int,
                                   case_dir: str,
                                   result: Dict[str, Any],
                                   expected_output: str,
                                   execution_time_ms: int,
                                   output_code_url: str,
                                   code_quality_score: Optional[int] = None,
                                   expected_output_score: Optional[int] = None) -> Dict[str, Any]:
    metrics = load_agent_metrics(case_dir)
    output_text = load_agent_output(case_dir)
    compile_results = result.get("compile_results") or {}
    constraint_review = result.get("constraint_review") or {}
    constraint_summary = constraint_review.get("summary") or {}

    is_build_success = bool(compile_results.get("compilable"))
    token_consumption = _extract_total_tokens(metrics)
    iteration_count = _extract_iteration_count(metrics, output_text)
    resolved_expected_output_score = expected_output_score
    if resolved_expected_output_score is None:
        resolved_expected_output_score = _normalize_score_value(constraint_summary.get("overall_score"))

    payload = CloudExecutionResultPayload(
        testExecutionId=execution_id,
        data=CloudExecutionResultData(
            isBuildSuccess=is_build_success,
            executionTime=max(0, int(execution_time_ms)),
            tokenConsumption=max(0, int(token_consumption)),
            iterationCount=max(0, int(iteration_count)),
            codeQualityScore=_score_code_quality(is_build_success) if code_quality_score is None else max(0, min(100, int(code_quality_score))),
            expectedOutputScore=_score_expected_output(expected_output, output_text) if resolved_expected_output_score is None else max(0, min(100, int(resolved_expected_output_score))),
            outputCodeUrl=output_code_url,
        ),
    )
    return payload.model_dump(by_alias=True, exclude_none=True)
