# -*- coding: utf-8 -*-
"""Agent/LLM 交互流程长期快照。

`results/` 是任务运行产物目录，可能按磁盘空间策略清理。云测详情页需要
长期可读的交互流程，因此这里只把转换后的展示快照另存到 `agent_traces/`，
OpenCode HTTP 源文件仍保留在 `results/` 的 metrics 目录中。
"""

from __future__ import annotations

import json
import os
import re
import sys
from typing import Any, Dict, Iterable, Optional

from agent_bench.pipeline.artifacts import load_interaction_metrics


INTERACTION_TEXT_LIMIT = 500
ANSI_ESCAPE_RE = re.compile(r"\x1b\[[0-9;]*[A-Za-z]")


def _runtime_base_dir() -> str:
    if getattr(sys, "frozen", False):
        return os.path.dirname(os.path.abspath(sys.executable))
    return os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))


def agent_traces_root() -> str:
    """长期保存 Agent/LLM 交互流程的根目录。"""
    return os.path.join(_runtime_base_dir(), "agent_traces")


def _snapshot_path(execution_id: int | str) -> str:
    return os.path.join(agent_traces_root(), f"execution_{execution_id}_interaction.json")


def _write_json(path: str, payload: Any):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        json.dump(payload, f, ensure_ascii=False, indent=2)


def _read_json(path: str) -> Any:
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)


def _strip_ansi(value: Any) -> Any:
    if isinstance(value, str):
        return ANSI_ESCAPE_RE.sub("", value)
    if isinstance(value, list):
        return [_strip_ansi(item) for item in value]
    if isinstance(value, dict):
        return {key: _strip_ansi(item) for key, item in value.items()}
    return value


def _clip_input(value: Any) -> Any:
    """保留 input 结构，但限制其中的长字符串，避免 write.content 等字段过大。"""
    if isinstance(value, str):
        return _clip(value, INTERACTION_TEXT_LIMIT)
    if isinstance(value, list):
        return [_clip_input(item) for item in value]
    if isinstance(value, dict):
        return {key: _clip_input(item) for key, item in value.items()}
    return value


def _clip(value: Any, limit: int) -> str:
    text = _strip_ansi("" if value is None else str(value))
    if len(text) <= limit:
        return text
    return text[:limit] + f"...[已截断，原始长度={len(text)}]"


def _coerce_int(value: Any) -> Optional[int]:
    try:
        if value is None or value == "":
            return None
        return int(value)
    except Exception:
        return None


def _duration_ms(start: Any, end: Any) -> Optional[int]:
    start_ms = _coerce_int(start)
    end_ms = _coerce_int(end)
    if start_ms is None or end_ms is None:
        return None
    return max(0, end_ms - start_ms)


def _tokens(info: Dict[str, Any]) -> Dict[str, int]:
    raw = info.get("tokens") if isinstance(info.get("tokens"), dict) else {}
    cache = raw.get("cache") if isinstance(raw.get("cache"), dict) else {}
    input_tokens = int(raw.get("input", 0) or 0)
    output_tokens = int(raw.get("output", 0) or 0)
    reasoning_tokens = int(raw.get("reasoning", 0) or 0)
    cache_read = int(cache.get("read", 0) or 0)
    cache_write = int(cache.get("write", 0) or 0)
    total = raw.get("total")
    if total is None:
        total = input_tokens + output_tokens + reasoning_tokens + cache_read + cache_write
    return {
        "input": input_tokens,
        "output": output_tokens,
        "reasoning": reasoning_tokens,
        "cacheRead": cache_read,
        "cacheWrite": cache_write,
        "total": int(total or 0),
    }


def _part_time(part: Dict[str, Any]) -> Dict[str, Any]:
    state = part.get("state") if isinstance(part.get("state"), dict) else {}
    time_info = state.get("time") if isinstance(state.get("time"), dict) else part.get("time")
    return time_info if isinstance(time_info, dict) else {}


def _tool_from_part(part: Dict[str, Any]) -> Optional[Dict[str, Any]]:
    part_type = part.get("type")
    if part_type not in {"tool", "patch"}:
        return None

    state = part.get("state") if isinstance(part.get("state"), dict) else {}
    time_info = _part_time(part)
    tool_name = part.get("tool") or ("patch" if part_type == "patch" else "unknown")
    output = state.get("output")
    if output is None:
        metadata = state.get("metadata") if isinstance(state.get("metadata"), dict) else {}
        output = metadata.get("output") or metadata.get("preview")
    if output is None and part_type == "patch":
        output = part.get("patch") or part.get("text") or part

    tool = {
        "tool": str(tool_name or "unknown"),
        "status": str(state.get("status") or part.get("status") or "completed"),
        "input": _clip_input(state.get("input") if isinstance(state.get("input"), dict) else {}),
        "outputPreview": _clip(output, INTERACTION_TEXT_LIMIT),
    }
    duration = _duration_ms(time_info.get("start"), time_info.get("end"))
    if duration is not None:
        tool["durationMs"] = duration
    return tool


def _message_parts(message: Dict[str, Any]) -> list[Dict[str, Any]]:
    parts = message.get("parts")
    return [item for item in parts if isinstance(item, dict)] if isinstance(parts, list) else []


def _message_info(message: Dict[str, Any]) -> Dict[str, Any]:
    info = message.get("info")
    return info if isinstance(info, dict) else {}


def _assistant_messages(messages: Iterable[Dict[str, Any]]) -> list[Dict[str, Any]]:
    result = []
    for message in messages:
        if not isinstance(message, dict):
            continue
        info = _message_info(message)
        if str(info.get("role") or "").lower() == "assistant":
            result.append(message)
    return result


def _steps_from_messages(messages: Iterable[Dict[str, Any]]) -> list[Dict[str, Any]]:
    steps = []
    for message in _assistant_messages(messages):
        info = _message_info(message)
        time_info = info.get("time") if isinstance(info.get("time"), dict) else {}
        parts = _message_parts(message)
        texts = [str(part.get("text") or "") for part in parts if part.get("type") == "text" and part.get("text")]
        reasoning = [str(part.get("text") or "") for part in parts if part.get("type") == "reasoning" and part.get("text")]
        tools = [tool for tool in (_tool_from_part(part) for part in parts) if tool]
        start_time = _coerce_int(time_info.get("created"))
        end_time = _coerce_int(time_info.get("completed"))
        text = _clip("\n".join(texts), INTERACTION_TEXT_LIMIT)
        step = {
            "index": len(steps),
            "startTime": start_time,
            "endTime": end_time,
            "durationMs": _duration_ms(start_time, end_time),
            "cost": info.get("cost", 0) or 0,
            "textLength": len(text),
            "text": text,
            "reasoning": _clip("\n".join(reasoning), INTERACTION_TEXT_LIMIT),
            "tokens": _tokens(info),
            "tools": tools,
        }
        steps.append({key: value for key, value in step.items() if value is not None})
    return steps


def _sum_usage(steps: list[Dict[str, Any]]) -> Dict[str, int]:
    totals = {
        "input_tokens": 0,
        "output_tokens": 0,
        "reasoning_tokens": 0,
        "cache_read_tokens": 0,
        "cache_write_tokens": 0,
        "cost": 0,
    }
    for step in steps:
        tokens = step.get("tokens") if isinstance(step.get("tokens"), dict) else {}
        totals["input_tokens"] += int(tokens.get("input", 0) or 0)
        totals["output_tokens"] += int(tokens.get("output", 0) or 0)
        totals["reasoning_tokens"] += int(tokens.get("reasoning", 0) or 0)
        totals["cache_read_tokens"] += int(tokens.get("cacheRead", 0) or 0)
        totals["cache_write_tokens"] += int(tokens.get("cacheWrite", 0) or 0)
        totals["cost"] += step.get("cost", 0) or 0
    return totals


def _tool_summary(steps: list[Dict[str, Any]]) -> Dict[str, Dict[str, int]]:
    summary: Dict[str, Dict[str, int]] = {}
    for step in steps:
        for tool in step.get("tools") or []:
            if not isinstance(tool, dict):
                continue
            name = str(tool.get("tool") or "unknown")
            item = summary.setdefault(name, {"count": 0, "totalDurationMs": 0})
            item["count"] += 1
            item["totalDurationMs"] += int(tool.get("durationMs", 0) or 0)
    return summary


def _timeline_bounds(steps: list[Dict[str, Any]]) -> tuple[Optional[int], Optional[int], Optional[int]]:
    starts = [step.get("startTime") for step in steps if step.get("startTime") is not None]
    ends = [step.get("endTime") for step in steps if step.get("endTime") is not None]
    start_time = min(starts) if starts else None
    end_time = max(ends) if ends else None
    return start_time, end_time, _duration_ms(start_time, end_time)


def _summary(steps: list[Dict[str, Any]], sub_agents: Optional[list[Dict[str, Any]]] = None) -> Dict[str, Any]:
    sub_agents = sub_agents or []
    return {
        "stepCount": len(steps),
        "toolCallCount": sum(len(step.get("tools") or []) for step in steps),
        "subAgentCount": len(sub_agents),
        "subAgentStepCount": sum(len(item.get("steps") or []) for item in sub_agents),
        "subAgentToolCallCount": sum(
            len(step.get("tools") or [])
            for item in sub_agents
            for step in (item.get("steps") or [])
        ),
        "textLength": sum(int(step.get("textLength", 0) or 0) for step in steps),
        "durationMs": _timeline_bounds(steps)[2],
        "usage": _sum_usage(steps),
    }


def _first_assistant_info(messages: list[Dict[str, Any]]) -> Dict[str, Any]:
    for message in _assistant_messages(messages):
        info = _message_info(message)
        if info:
            return info
    return {}


def _model_name(info: Dict[str, Any]) -> Optional[str]:
    provider = info.get("providerID")
    model = info.get("modelID")
    if provider and model:
        return f"{provider}/{model}"
    return model or provider


def _working_directory(info: Dict[str, Any], case_dir: str) -> str:
    path_info = info.get("path") if isinstance(info.get("path"), dict) else {}
    cwd = str(path_info.get("cwd") or "").strip()
    if cwd:
        return cwd
    return os.path.join(case_dir, "workspace") if case_dir else ""


def _sub_agents(metrics: Dict[str, Any]) -> list[Dict[str, Any]]:
    http = metrics.get("http") if isinstance(metrics.get("http"), dict) else {}
    histories = http.get("subagent_message_history")
    if not isinstance(histories, list):
        return []
    result = []
    for item in histories:
        if not isinstance(item, dict):
            continue
        messages = item.get("message_history") if isinstance(item.get("message_history"), list) else []
        steps = _steps_from_messages(messages)
        start_time, end_time, duration = _timeline_bounds(steps)
        sub_agent = {
            "name": item.get("subagent_type") or item.get("title") or item.get("session_id") or "subAgent",
            "title": item.get("title") or "",
            "sessionId": item.get("session_id") or "",
            "status": "completed" if steps else "unknown",
            "startTime": start_time,
            "endTime": end_time,
            "durationMs": duration,
            "steps": steps,
            "toolSummary": _tool_summary(steps),
            "summary": _summary(steps),
        }
        result.append({key: value for key, value in sub_agent.items() if value not in (None, "")})
    return result


def build_agent_interaction_snapshot(execution_id: int | str,
                                     case_dir: str,
                                     status: str = "completed",
                                     agent: Optional[str] = None) -> Dict[str, Any]:
    metrics = load_interaction_metrics(case_dir, "agent")
    http = metrics.get("http") if isinstance(metrics.get("http"), dict) else {}
    messages = http.get("message_history") if isinstance(http.get("message_history"), list) else []
    steps = _steps_from_messages(messages)
    sub_agents = _sub_agents(metrics)
    first_info = _first_assistant_info(messages)
    start_time, end_time, duration = _timeline_bounds(steps)
    payload = {
        "executionId": int(execution_id),
        "agent": agent or first_info.get("agent") or first_info.get("mode") or "",
        "model": _model_name(first_info),
        "status": status,
        "workingDirectory": _working_directory(first_info, case_dir),
        "startTime": start_time,
        "endTime": end_time,
        "durationMs": duration,
        "steps": steps,
        "subAgents": sub_agents,
        "toolSummary": _tool_summary(steps),
        "summary": _summary(steps, sub_agents),
    }
    return {key: value for key, value in payload.items() if value is not None}


def persist_agent_interaction_trace(execution_id: int | str,
                                    case_dir: str,
                                    status: str = "completed",
                                    agent: Optional[str] = None) -> str:
    """把云测展示用的最终快照写入长期目录，返回快照路径。"""
    snapshot = build_agent_interaction_snapshot(execution_id, case_dir, status=status, agent=agent)
    path = _snapshot_path(execution_id)
    _write_json(path, snapshot)
    return path


def load_agent_interaction_trace(execution_id: int | str,
                                 case_dir: Optional[str] = None,
                                 status: str = "completed",
                                 agent: Optional[str] = None) -> Optional[Dict[str, Any]]:
    """读取长期快照；不存在时可用 case_dir 从 results 临时生成并保存。"""
    path = _snapshot_path(execution_id)
    if os.path.exists(path):
        payload = _read_json(path)
        return payload if isinstance(payload, dict) else None
    if case_dir and os.path.isdir(case_dir):
        try:
            persist_agent_interaction_trace(execution_id, case_dir, status=status, agent=agent)
        except Exception:
            return None
        if os.path.exists(path):
            payload = _read_json(path)
            return payload if isinstance(payload, dict) else None
    return None
