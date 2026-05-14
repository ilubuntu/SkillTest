# -*- coding: utf-8 -*-
"""OpenCode session 资源清理。

该类只处理任务超时后的 best-effort 清理：通知 OpenCode 取消主 session
和已发现的子 session，避免超时任务继续占用 OpenCode/LLM 侧资源。
"""

from __future__ import annotations

from typing import Callable, Optional

from agent_bench.agent_runner.communicate import OpenCodeHttpClient


class OpenCodeSessionCleaner:
    """超时收口时使用的 OpenCode session 取消器。"""

    def __init__(self,
                 http_client: OpenCodeHttpClient,
                 log_func: Optional[Callable[[str, str], None]] = None):
        self._http_client = http_client
        self._log_func = log_func

    def cleanup_timeout_session(self,
                                session_id: str,
                                workspace_dir: Optional[str] = None,
                                reason: str = "",
                                log_prefix: str = "") -> dict:
        """取消主 session 和其子 session。

        该方法不抛异常，不等待 OpenCode 完全释放资源；调用方原有超时失败流程
        不应被清理失败影响。
        """
        session_id = str(session_id or "").strip()
        if not session_id:
            return {"main": False, "children": [], "errors": ["empty session_id"]}

        result = {"main": False, "children": [], "errors": []}
        reason_text = f"，原因={reason}" if reason else ""
        self._log("INFO", f"{log_prefix}Agent 超时，开始请求 OpenCode 取消会话: session={self._short(session_id)}{reason_text}")

        children = self._list_children(session_id, workspace_dir, result, log_prefix)
        result["main"] = self._abort_one(session_id, workspace_dir, "main", result, log_prefix)
        for child_id in children:
            ok = self._abort_one(child_id, workspace_dir, "subAgent", result, log_prefix)
            result["children"].append({"sessionId": child_id, "aborted": ok})

        self._log(
            "INFO",
            f"{log_prefix}Agent 超时，已请求 OpenCode 取消会话: "
            f"main={result['main']}, children={len(result['children'])}, errors={len(result['errors'])}",
        )
        return result

    def _list_children(self,
                       session_id: str,
                       workspace_dir: Optional[str],
                       result: dict,
                       log_prefix: str) -> list[str]:
        try:
            payload = self._http_client.list_children(session_id, workspace_dir=workspace_dir, timeout=5)
        except Exception as exc:
            result["errors"].append(f"list_children failed: {exc}")
            self._log("WARN", f"{log_prefix}Agent 超时，读取 OpenCode 子会话失败: session={self._short(session_id)}, error={exc}")
            return []
        return sorted(self._extract_session_ids(payload))

    def _abort_one(self,
                   session_id: str,
                   workspace_dir: Optional[str],
                   role: str,
                   result: dict,
                   log_prefix: str) -> bool:
        try:
            self._http_client.abort_session(session_id, workspace_dir=workspace_dir, timeout=5)
            self._log("INFO", f"{log_prefix}Agent 超时，已发送 OpenCode abort: role={role}, session={self._short(session_id)}")
            return True
        except Exception as exc:
            result["errors"].append(f"abort {role} {session_id} failed: {exc}")
            self._log("WARN", f"{log_prefix}Agent 超时，OpenCode abort 失败: role={role}, session={self._short(session_id)}, error={exc}")
            return False

    @staticmethod
    def _extract_session_ids(payload) -> set[str]:
        ids: set[str] = set()

        def visit(value):
            if isinstance(value, dict):
                for key in ("id", "sessionID", "sessionId"):
                    candidate = str(value.get(key) or "").strip()
                    if candidate.startswith("ses_"):
                        ids.add(candidate)
                for item in value.values():
                    visit(item)
                return
            if isinstance(value, list):
                for item in value:
                    visit(item)

        visit(payload)
        return ids

    @staticmethod
    def _short(session_id: str) -> str:
        text = str(session_id or "").strip()
        if len(text) <= 18:
            return text
        return f"{text[:18]}..."

    def _log(self, level: str, message: str):
        if self._log_func:
            self._log_func(level, message)
