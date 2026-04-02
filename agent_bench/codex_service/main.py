# -*- coding: utf-8 -*-
"""独立的 Codex HTTP 服务。"""

import argparse
import json
import os
import threading
import time
from typing import Any, Dict, List, Optional

from fastapi import FastAPI
from fastapi.concurrency import run_in_threadpool
from pydantic import BaseModel

from agent_bench.runner.codex_local_adapter import CodexLocalAdapter


class CodexExecuteRequest(BaseModel):
    prompt: str
    workspace_dir: Optional[str] = None
    enhancements: Dict[str, Any] = {}
    cli_path: str = "codex"
    model: Optional[str] = None
    timeout: int = 480
    temperature: Optional[float] = None
    profile: Optional[str] = None
    env: Dict[str, str] = {}


class CodexExecuteResponse(BaseModel):
    output: str = ""
    interaction_metrics: Optional[Dict[str, Any]] = None
    logs: List[Dict[str, Any]] = []
    error: Optional[str] = None


app = FastAPI(
    title="Codex Remote Service",
    description="独立的 Codex 本地桥接服务",
    version="1.0.0",
)

_SERVICE_STATE = {
    "lock": threading.Lock(),
    "workspace_hits": {},
    "prewarmed_cli": {},
    "session_lookup_cache": {},
}

_SESSION_SCAN_LIMIT = 80


def _workspace_key(config: CodexExecuteRequest) -> str:
    workspace = _normalize_workspace_signature(config.workspace_dir)
    model = (config.model or "").strip().lower()
    cli_path = (config.cli_path or "codex").strip().lower()
    profile = (config.profile or "").strip().lower()
    return f"{workspace}|{cli_path}|{model}|{profile}"


def _normalize_workspace_signature(workspace_dir: Optional[str]) -> str:
    normalized = os.path.normpath(str(workspace_dir or "").strip()).lower()
    if not normalized:
        return ""
    parts = [part for part in normalized.replace("/", "\\").split("\\") if part]
    if "cases" in parts:
        idx = parts.index("cases")
        tail = parts[idx:idx + 3]
        if len(tail) >= 3:
            return "\\".join(tail)
    return normalized


def _iter_recent_session_files(limit: int = _SESSION_SCAN_LIMIT) -> List[str]:
    sessions_root = os.path.join(os.path.expanduser("~"), ".codex", "sessions")
    if not os.path.isdir(sessions_root):
        return []
    session_files: List[str] = []
    for current_root, _, files in os.walk(sessions_root):
        for name in files:
            if name.endswith(".jsonl"):
                session_files.append(os.path.join(current_root, name))
    session_files.sort(key=lambda path: os.path.getmtime(path), reverse=True)
    return session_files[:limit]


def _read_session_meta(session_file: str) -> Dict[str, Any]:
    try:
        with open(session_file, "r", encoding="utf-8", errors="replace") as f:
            first_line = f.readline().strip()
        if not first_line:
            return {}
        data = json.loads(first_line)
        if data.get("type") != "session_meta":
            return {}
        payload = data.get("payload") or {}
        return payload if isinstance(payload, dict) else {}
    except Exception:
        return {}


def _find_latest_session_id_for_workspace(workspace_dir: Optional[str], use_cache: bool = True) -> Optional[str]:
    signature = _normalize_workspace_signature(workspace_dir)
    if not signature:
        return None
    if use_cache:
        with _SERVICE_STATE["lock"]:
            cached = _SERVICE_STATE["session_lookup_cache"].get(signature)
        if cached:
            return cached

    for session_file in _iter_recent_session_files():
        payload = _read_session_meta(session_file)
        if not payload:
            continue
        session_signature = _normalize_workspace_signature(payload.get("cwd"))
        session_id = str(payload.get("id") or "").strip() or None
        if session_signature == signature and session_id:
            with _SERVICE_STATE["lock"]:
                _SERVICE_STATE["session_lookup_cache"][signature] = session_id
            return session_id
    return None


def _mark_workspace_hit(config: CodexExecuteRequest) -> bool:
    key = _workspace_key(config)
    now = time.time()
    with _SERVICE_STATE["lock"]:
        last_hit = _SERVICE_STATE["workspace_hits"].get(key)
        _SERVICE_STATE["workspace_hits"][key] = now
    return last_hit is not None and now - last_hit <= 1800


def _compact_logs(logs: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    compacted = []
    for entry in logs or []:
        if not isinstance(entry, dict):
            continue
        level = str(entry.get("level") or "INFO").upper()
        message = str(entry.get("message") or "").strip()
        if not message:
            continue
        keep = (
            level in {"ERROR", "WARN"}
            or message.startswith("Codex Remote ")
            or "收到响应" in message
            or "发送请求" in message
            or "提前结束本轮执行" in message
            or "resume 失败" in message
        )
        if not keep:
            continue
        compacted.append({
            "level": level,
            "message": message[:240] + ("...<truncated>" if len(message) > 240 else ""),
        })
    if len(compacted) <= 80:
        return compacted
    return compacted[:80]


def _prewarm_cli_resolution(cli_path: str) -> Optional[str]:
    cache_key = (cli_path or "codex").strip() or "codex"
    with _SERVICE_STATE["lock"]:
        if cache_key in _SERVICE_STATE["prewarmed_cli"]:
            return _SERVICE_STATE["prewarmed_cli"][cache_key]

    adapter = CodexLocalAdapter(cli_path=cache_key)
    resolved = adapter._resolve_command()
    with _SERVICE_STATE["lock"]:
        _SERVICE_STATE["prewarmed_cli"][cache_key] = resolved
    return resolved


def _run_codex_execute(config: CodexExecuteRequest) -> CodexExecuteResponse:
    logs = []

    def on_progress(event: str, data: dict):
        if event != "log":
            return
        logs.append({
            "level": data.get("level", "INFO"),
            "message": data.get("message", ""),
        })

    warm_hit = _mark_workspace_hit(config)
    reusable_session_id = _find_latest_session_id_for_workspace(config.workspace_dir)

    adapter = CodexLocalAdapter(
        cli_path=config.cli_path,
        model=config.model,
        timeout=config.timeout,
        temperature=config.temperature,
        on_progress=on_progress,
        profile=config.profile,
        env=config.env,
        resume_session_id=reusable_session_id,
        resume_last=False,
    )

    try:
        resolved_cli = _prewarm_cli_resolution(config.cli_path)
        logs.append({
            "level": "DEBUG",
            "message": "Codex Remote warm-hit: 复用常驻服务状态" if warm_hit else "Codex Remote cold-start: 首次处理该工作区请求",
        })
        if resolved_cli:
            logs.append({
                "level": "DEBUG",
                "message": f"Codex Remote CLI 已预热: {resolved_cli}",
            })
        if reusable_session_id:
            logs.append({
                "level": "DEBUG",
                "message": f"Codex Remote 将尝试复用历史会话: {reusable_session_id}",
            })
        elif warm_hit:
            logs.append({
                "level": "DEBUG",
                "message": "Codex Remote 检测到工作区重复请求，但未找到可复用的历史 session_id",
            })
        adapter.setup(config.enhancements, on_progress=on_progress)
        output = adapter.execute(config.prompt, workspace_dir=config.workspace_dir)
        metrics = adapter.get_last_interaction_metrics()
        if isinstance(metrics, dict) and not metrics.get("session_id"):
            inferred_session_id = _find_latest_session_id_for_workspace(config.workspace_dir, use_cache=False)
            if inferred_session_id:
                metrics["session_id"] = inferred_session_id
        raw_metrics = (metrics or {}).get("raw") or {}
        if raw_metrics.get("resume_fallback"):
            signature = _normalize_workspace_signature(config.workspace_dir)
            with _SERVICE_STATE["lock"]:
                _SERVICE_STATE["session_lookup_cache"].pop(signature, None)
        error = None
        if isinstance(metrics, dict):
            exit_code = raw_metrics.get("exit_code")
            if exit_code not in (None, 0):
                error = f"exit={exit_code}"
            if raw_metrics.get("resume_fallback"):
                logs.append({
                    "level": "WARN",
                    "message": "Codex Remote 已从 resume 自动回退到 fresh exec",
                })
        if not output and logs:
            last_error = next(
                (entry.get("message", "") for entry in reversed(logs) if str(entry.get("level", "")).upper() == "ERROR"),
                "",
            )
            if last_error:
                error = error or last_error
        return CodexExecuteResponse(
            output=output or "",
            interaction_metrics=metrics,
            logs=_compact_logs(logs),
            error=error,
        )
    finally:
        adapter.teardown()


@app.get("/health")
async def health():
    with _SERVICE_STATE["lock"]:
        warmed_workspaces = len(_SERVICE_STATE["workspace_hits"])
        prewarmed_cli = len([item for item in _SERVICE_STATE["prewarmed_cli"].values() if item])
        cached_sessions = len([item for item in _SERVICE_STATE["session_lookup_cache"].values() if item])
    return {
        "healthy": True,
        "service": "codex_remote",
        "warmed_workspaces": warmed_workspaces,
        "prewarmed_cli": prewarmed_cli,
        "cached_sessions": cached_sessions,
    }


@app.post("/api/codex/execute", response_model=CodexExecuteResponse)
async def execute_codex(config: CodexExecuteRequest):
    return await run_in_threadpool(_run_codex_execute, config)


def main():
    parser = argparse.ArgumentParser(description="Start Codex remote service")
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=8001)
    args = parser.parse_args()

    import uvicorn

    uvicorn.run(app, host=args.host, port=args.port, reload=False)


if __name__ == "__main__":
    main()
