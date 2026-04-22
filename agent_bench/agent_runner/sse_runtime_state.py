# -*- coding: utf-8 -*-
"""SSE 运行时内存状态。"""

import threading
import time


class SseRuntimeState:
    """维护当前 session 的 SSE 内存态，供超时判断使用。"""

    def __init__(self):
        self._lock = threading.Lock()
        self._session_id = ""
        self._last_activity_at = 0.0

    def reset(self, session_id: str = ""):
        with self._lock:
            self._session_id = str(session_id or "")
            self._last_activity_at = 0.0

    def mark_activity(self, session_id: str = ""):
        with self._lock:
            if session_id:
                self._session_id = str(session_id)
            self._last_activity_at = time.monotonic()

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
