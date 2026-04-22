# -*- coding: utf-8 -*-
"""Agent 运行时内存状态。"""

import threading
import time
from typing import Optional


class AgentRuntimeState:
    """维护当前 session 的运行时内存态，供超时判断使用。"""

    def __init__(self):
        self._lock = threading.Lock()
        self._session_id = ""
        self._last_activity_at = 0.0
        self._last_message_signature = ""

    def reset(self, session_id: str = ""):
        with self._lock:
            self._session_id = str(session_id or "")
            self._last_activity_at = 0.0
            self._last_message_signature = ""

    def mark_activity(self, session_id: str = ""):
        with self._lock:
            if session_id:
                self._session_id = str(session_id)
            self._last_activity_at = time.monotonic()

    def mark_message_progress(self, signature: Optional[str], session_id: str = "") -> bool:
        normalized = str(signature or "").strip()
        if not normalized:
            return False
        with self._lock:
            if session_id:
                self._session_id = str(session_id)
            if normalized == self._last_message_signature:
                return False
            self._last_message_signature = normalized
            self._last_activity_at = time.monotonic()
            return True

    def has_activity(self) -> bool:
        with self._lock:
            return self._last_activity_at > 0

    def idle_seconds(self) -> float:
        with self._lock:
            last_activity_at = self._last_activity_at
        if last_activity_at <= 0:
            return 0.0
        return time.monotonic() - last_activity_at

    def session_id(self) -> str:
        with self._lock:
            return self._session_id
