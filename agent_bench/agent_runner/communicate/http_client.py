# -*- coding: utf-8 -*-
"""OpenCode HTTP API 客户端。"""

import json
import urllib.error
import urllib.parse
import urllib.request
from typing import Optional


class OpenCodeHttpClient:
    """封装 OpenCode Server HTTP 接口。"""

    def __init__(self, api_base: str):
        self.api_base = str(api_base or "").rstrip("/")

    def _session_url(self,
                     session_id: str,
                     endpoint: str,
                     workspace_dir: Optional[str] = None) -> str:
        base_url = f"{self.api_base}/session/{session_id}/{endpoint}"
        if not workspace_dir:
            return base_url
        query = urllib.parse.urlencode({"directory": workspace_dir})
        return f"{base_url}?{query}"

    def create_session(self, timeout: int = 60) -> dict:
        req = urllib.request.Request(
            f"{self.api_base}/session",
            data=json.dumps({}).encode("utf-8"),
            headers={"Content-Type": "application/json"},
            method="POST",
        )
        with urllib.request.urlopen(req, timeout=timeout) as response:
            return json.loads(response.read().decode("utf-8"))

    def prompt_async(self,
                     session_id: str,
                     payload: dict,
                     workspace_dir: Optional[str] = None,
                     timeout: int = 300):
        data = json.dumps(payload).encode("utf-8")
        req = urllib.request.Request(
            self._session_url(session_id, "prompt_async", workspace_dir),
            data=data,
            headers={"Content-Type": "application/json"},
            method="POST",
        )
        with urllib.request.urlopen(req, timeout=timeout) as response:
            return response.read()

    def send_message(self,
                     session_id: str,
                     payload: dict,
                     workspace_dir: Optional[str] = None,
                     timeout: int = 300) -> str:
        data = json.dumps(payload).encode("utf-8")
        req = urllib.request.Request(
            self._session_url(session_id, "message", workspace_dir),
            data=data,
            headers={"Content-Type": "application/json"},
            method="POST",
        )
        with urllib.request.urlopen(req, timeout=timeout) as response:
            return response.read().decode("utf-8")

    def list_messages(self,
                      session_id: str,
                      limit: Optional[int] = None,
                      timeout: int = 10):
        url = f"{self.api_base}/session/{session_id}/message"
        if limit is not None:
            url = f"{url}?{urllib.parse.urlencode({'limit': int(limit)})}"
        req = urllib.request.Request(url, method="GET")
        with urllib.request.urlopen(req, timeout=timeout) as response:
            return json.loads(response.read().decode("utf-8"))

    def get_message(self, session_id: str, message_id: str, timeout: int = 10):
        req = urllib.request.Request(
            f"{self.api_base}/session/{session_id}/message/{message_id}",
            method="GET",
        )
        with urllib.request.urlopen(req, timeout=timeout) as response:
            return json.loads(response.read().decode("utf-8"))

    def list_children(self,
                      session_id: str,
                      workspace_dir: Optional[str] = None,
                      timeout: int = 10):
        req = urllib.request.Request(
            self._session_url(session_id, "children", workspace_dir),
            method="GET",
        )
        with urllib.request.urlopen(req, timeout=timeout) as response:
            return json.loads(response.read().decode("utf-8"))

    def abort_session(self,
                      session_id: str,
                      workspace_dir: Optional[str] = None,
                      timeout: int = 5):
        req = urllib.request.Request(
            self._session_url(session_id, "abort", workspace_dir),
            method="POST",
        )
        with urllib.request.urlopen(req, timeout=timeout) as response:
            body = response.read().decode("utf-8")
            try:
                return json.loads(body) if body else True
            except Exception:
                return body or True

    def list_todos(self, session_id: str, timeout: int = 10):
        req = urllib.request.Request(
            f"{self.api_base}/session/{session_id}/todo",
            method="GET",
        )
        with urllib.request.urlopen(req, timeout=timeout) as response:
            return json.loads(response.read().decode("utf-8"))

    def list_questions(self,
                       workspace_dir: Optional[str] = None,
                       timeout: int = 10):
        url = f"{self.api_base}/question"
        headers = {}
        if workspace_dir:
            query = urllib.parse.urlencode({"directory": workspace_dir})
            url = f"{url}?{query}"
            headers["x-opencode-directory"] = str(workspace_dir)
        req = urllib.request.Request(url, headers=headers, method="GET")
        with urllib.request.urlopen(req, timeout=timeout) as response:
            return json.loads(response.read().decode("utf-8"))

    def reply_question(self,
                       request_id: str,
                       answers: list[list[str]],
                       workspace_dir: Optional[str] = None,
                       timeout: int = 30):
        payload = {"answers": list(answers or [])}
        url = f"{self.api_base}/question/{urllib.parse.quote(str(request_id or ''))}/reply"
        headers = {"Content-Type": "application/json"}
        if workspace_dir:
            query = urllib.parse.urlencode({"directory": workspace_dir})
            url = f"{url}?{query}"
            headers["x-opencode-directory"] = str(workspace_dir)
        req = urllib.request.Request(
            url,
            data=json.dumps(payload).encode("utf-8"),
            headers=headers,
            method="POST",
        )
        try:
            with urllib.request.urlopen(req, timeout=timeout) as response:
                body = response.read().decode("utf-8")
                try:
                    parsed = json.loads(body) if body else {}
                except Exception:
                    parsed = {"raw": body}
                return {
                    "ok": True,
                    "status_code": getattr(response, "status", 200),
                    "body": parsed,
                }
        except urllib.error.HTTPError as exc:
            body = ""
            try:
                body = exc.read().decode("utf-8")
            except Exception:
                body = ""
            try:
                parsed = json.loads(body) if body else {}
            except Exception:
                parsed = {"raw": body}
            return {
                "ok": False,
                "status_code": int(getattr(exc, "code", 0) or 0),
                "body": parsed,
            }
