# -*- coding: utf-8 -*-
"""通过独立 HTTP 服务调用 Codex 的适配器。"""

import json
import sys
import urllib.error
import urllib.request
from typing import Optional

from agent_bench.runner.adapter import AgentAdapter
from agent_bench.runner.discovery import ensure_codex_service, read_codex_service_log_tail

DEFAULT_API_BASE = "http://127.0.0.1:8001"
TIMEOUT = 480


class CodexHttpAdapter(AgentAdapter):
    """通过独立 Codex HTTP 服务执行任务。"""

    def __init__(self,
                 api_base: str = DEFAULT_API_BASE,
                 cli_path: str = "codex",
                 model: str = None,
                 timeout: int = TIMEOUT,
                 temperature: float = None,
                 on_progress=None,
                 profile: str = None,
                 env: dict = None):
        self.api_base = (api_base or DEFAULT_API_BASE).rstrip("/")
        self.cli_path = cli_path
        self.model = model
        self.timeout = timeout
        self.temperature = temperature
        self.on_progress = on_progress
        self.profile = profile
        self.env = env or {}

        self._enhancements = {}
        self._last_interaction_metrics = None

    def _log(self, level: str, message: str, tag: str = ""):
        if self.on_progress:
            self.on_progress("log", {"level": level, "message": f"{tag}{message}"})
        if level == "ERROR":
            print(f"  [ERROR] {tag}{message}", file=sys.stderr)

    def setup(self, enhancements: dict, on_progress=None):
        if on_progress:
            self.on_progress = on_progress
        self._last_interaction_metrics = None
        self._enhancements = dict(enhancements or {})

    def execute(self, prompt: str, tag: str = "", workspace_dir: Optional[str] = None) -> str:
        self._last_interaction_metrics = None
        self.api_base = ensure_codex_service(api_base=self.api_base)
        payload = {
            "prompt": prompt,
            "workspace_dir": workspace_dir,
            "enhancements": self._enhancements,
            "cli_path": self.cli_path,
            "model": self.model,
            "timeout": self.timeout,
            "temperature": self.temperature,
            "profile": self.profile,
            "env": self.env,
        }

        request_data = json.dumps(payload).encode("utf-8")
        self._log(
            "INFO",
            f"发送 Codex Remote 请求: api={self.api_base}, prompt={len(request_data)/1024:.1f}KB, "
            f"{f'model={self.model}' if self.model else '无model'}, 超时={self.timeout}s",
            tag=tag,
        )

        try:
            req = urllib.request.Request(
                f"{self.api_base}/api/codex/execute",
                data=request_data,
                headers={"Content-Type": "application/json"},
                method="POST",
            )
            with urllib.request.urlopen(req, timeout=self.timeout + 30) as resp:
                body = json.loads(resp.read().decode("utf-8"))
        except urllib.error.HTTPError as e:
            detail = ""
            try:
                detail = e.read().decode("utf-8", errors="replace")
            except Exception:
                pass
            self._log("ERROR", f"Codex Remote 请求失败: {e.code} {e.reason} {detail[:300]}", tag=tag)
            return ""
        except urllib.error.URLError as e:
            log_tail = read_codex_service_log_tail(1200).strip()
            detail = f" | codex_service_log={log_tail}" if log_tail else ""
            self._log("ERROR", f"无法连接 Codex Remote 服务 ({self.api_base}): {e.reason}{detail}", tag=tag)
            return ""
        except TimeoutError:
            self._log("ERROR", f"Codex Remote 请求超时 ({self.timeout}s)", tag=tag)
            raise TimeoutError(f"Agent 请求超时 ({self.timeout}s)")
        except Exception as e:
            self._log("ERROR", f"Codex Remote 调用异常: {e}", tag=tag)
            return ""

        for entry in body.get("logs", []) or []:
            if not isinstance(entry, dict):
                continue
            level = str(entry.get("level") or "INFO").upper()
            message = str(entry.get("message") or "").strip()
            if message:
                self._log(level, message, tag=tag)

        self._last_interaction_metrics = body.get("interaction_metrics")
        raw_metrics = (self._last_interaction_metrics or {}).get("raw") or {}
        if raw_metrics:
            self._log(
                "DEBUG",
                "Codex Remote 指标: "
                f"attempt={raw_metrics.get('attempt_mode')}, "
                f"resume={raw_metrics.get('resume_requested')}, "
                f"workspace_env={raw_metrics.get('workspace_env_prepared')}, "
                f"session={self._last_interaction_metrics.get('session_id')}",
                tag=tag,
            )
        output = body.get("output") or ""
        if body.get("error"):
            self._log("ERROR", f"Codex Remote 执行失败: {body['error']}", tag=tag)
        elif output:
            self._log("INFO", f"收到响应: {len(output)}字符", tag=tag)
        else:
            self._log("WARN", "Codex Remote 返回为空", tag=tag)
        return output

    def teardown(self):
        self._enhancements = {}

    def get_last_interaction_metrics(self):
        return self._last_interaction_metrics
