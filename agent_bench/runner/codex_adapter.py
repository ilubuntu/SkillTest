# -*- coding: utf-8 -*-
"""Codex CLI Agent 适配器。

通过本机 `codex exec` 非交互命令执行任务。
"""

import json
import os
import shutil
import subprocess
import sys
import tempfile
import time
import glob
from pathlib import Path
from typing import Optional

from agent_bench.runner.adapter import AgentAdapter

DEFAULT_CODEX_COMMAND = "codex"
TIMEOUT = 480


class CodexAdapter(AgentAdapter):
    """Codex CLI 适配器。"""

    def __init__(self,
                 command: str = DEFAULT_CODEX_COMMAND,
                 model: str = None,
                 timeout: int = TIMEOUT,
                 temperature: float = None,
                 on_progress=None):
        self.command = command
        self.model = model
        self.timeout = timeout
        self.temperature = temperature
        self.on_progress = on_progress

        self._instruction_prefix = ""
        self._last_interaction_metrics = None

    def _log(self, level: str, message: str, tag: str = ""):
        if self.on_progress:
            self.on_progress("log", {"level": level, "message": f"{tag}{message}"})
        if level == "ERROR":
            print(f"  [ERROR] {tag}{message}", file=sys.stderr)

    def setup(self, enhancements: dict, on_progress=None):
        if on_progress:
            self.on_progress = on_progress

        self._instruction_prefix = ""
        self._last_interaction_metrics = None

        if not enhancements:
            self._log("DEBUG", "Codex 基线模式: 无增强配置")
            return

        sections = []

        system_prompt = (enhancements.get("system_prompt") or "").strip()
        if system_prompt:
            sections.append(f"## System Prompt\n{system_prompt}")
            self._log("INFO", f"已配置 Codex System Prompt ({len(system_prompt)} 字符)")

        for skill in enhancements.get("skills", []) or []:
            name = skill.get("name", "unknown")
            content = (skill.get("content") or "").strip()
            if not content:
                self._log("WARN", f"Codex Skill [{name}] 内容为空，已跳过")
                continue
            sections.append(f"## Skill: {name}\n{content}")
            self._log("INFO", f"已配置 Codex Skill: {name} ({len(content)} 字符)")

        mcp_servers = enhancements.get("mcp_servers") or []
        if mcp_servers:
            self._log("WARN", f"CodexAdapter 暂不支持按用例动态注册 MCP，已忽略 {len(mcp_servers)} 个 MCP 配置")

        tools = enhancements.get("tools")
        if tools:
            self._log("WARN", "CodexAdapter 暂不支持按用例覆盖 tools 开关，已忽略 tools 配置")

        self._instruction_prefix = "\n\n".join(sections).strip()

    def execute(self, prompt: str, tag: str = "", workspace_dir: Optional[str] = None) -> str:
        output_path = None
        try:
            self._last_interaction_metrics = None
            executable = self._resolve_command()
            if not executable:
                self._log("ERROR", f"未找到 Codex 可执行文件: {self.command}", tag=tag)
                return ""

            working_dir = workspace_dir or os.getcwd()
            if not os.path.isdir(working_dir):
                self._log("ERROR", f"Codex 工作目录不存在: {working_dir}", tag=tag)
                return ""

            effective_prompt = prompt
            if workspace_dir:
                effective_prompt = (
                    f"## 工作目录\n{workspace_dir}\n\n"
                    "请直接在这个目录中修改工程文件完成任务，不要只返回单个代码片段。\n\n"
                    f"{effective_prompt}"
                )

            if self._instruction_prefix:
                effective_prompt = f"{self._instruction_prefix}\n\n{effective_prompt}"

            with tempfile.NamedTemporaryFile("w+", encoding="utf-8", delete=False, suffix=".txt") as output_file:
                output_path = output_file.name

            command = [
                executable,
                "-a", "never",
                "exec",
                "-s", "danger-full-access",
                "--skip-git-repo-check",
                "--color", "never",
                "--json",
                "-o", output_path,
            ]
            if workspace_dir:
                command.extend(["-C", workspace_dir])
            if self.model:
                command.extend(["-m", self.model])
            command.append("-")

            self._log(
                "INFO",
                f"发送 Codex 请求: prompt={len(effective_prompt)}字符, model={self.model or '默认'}, timeout={self.timeout}s",
                tag=tag,
            )
            self._log("DEBUG", f"Codex 命令: {' '.join(command[:-1])} [stdin prompt]", tag=tag)

            t0 = time.time()
            result = subprocess.run(
                command,
                input=effective_prompt,
                text=True,
                capture_output=True,
                timeout=self.timeout,
                cwd=working_dir,
                encoding="utf-8",
                errors="replace",
            )
            elapsed_ms = round((time.time() - t0) * 1000)

            if result.returncode != 0:
                stderr_preview = (result.stderr or "").strip()[:500]
                self._log("ERROR", f"Codex 命令失败(exit={result.returncode}): {stderr_preview}", tag=tag)
                return ""

            response_text = ""
            if output_path and os.path.exists(output_path):
                with open(output_path, "r", encoding="utf-8") as f:
                    response_text = f.read().strip()

            events = self._parse_jsonl_events(result.stdout)
            self._last_interaction_metrics = self._build_interaction_metrics(
                prompt_text=effective_prompt,
                response_text=response_text,
                events=events,
                api_elapsed_ms=elapsed_ms,
                raw_stdout=result.stdout,
                raw_stderr=result.stderr,
            )

            if response_text:
                self._log("INFO", f"收到 Codex 响应: {len(response_text)}字符, 耗时={elapsed_ms / 1000:.1f}s", tag=tag)
            else:
                self._log("WARN", f"Codex 返回为空, 耗时={elapsed_ms / 1000:.1f}s", tag=tag)
            return response_text

        except subprocess.TimeoutExpired as e:
            self._log("ERROR", f"Codex 请求超时 ({self.timeout}s)", tag=tag)
            raise TimeoutError(f"Agent 请求超时 ({self.timeout}s)") from e
        except Exception as e:
            self._log("ERROR", f"Codex 执行异常: {e}", tag=tag)
            return ""
        finally:
            if output_path:
                try:
                    os.remove(output_path)
                except OSError:
                    pass

    def _resolve_command(self) -> Optional[str]:
        candidates = []
        if self.command:
            candidates.append(self.command)

        for candidate in candidates:
            resolved = shutil.which(candidate)
            if resolved:
                return resolved
            if os.path.isfile(candidate):
                return candidate

        user_home = Path.home()
        fallback_patterns = [
            user_home / ".vscode" / "extensions" / "openai.chatgpt-*" / "bin" / "windows-x86_64" / "codex.exe",
            user_home / ".codex" / "bin" / "codex.exe",
        ]
        for pattern in fallback_patterns:
            matches = sorted(glob.glob(str(pattern)))
            if matches:
                return matches[-1]

        return None

    def teardown(self):
        self._instruction_prefix = ""

    def get_last_interaction_metrics(self):
        return self._last_interaction_metrics

    def _parse_jsonl_events(self, stdout_text: str) -> list:
        events = []
        for line in (stdout_text or "").splitlines():
            line = line.strip()
            if not line or not line.startswith("{"):
                continue
            try:
                data = json.loads(line)
            except json.JSONDecodeError:
                continue
            if isinstance(data, dict):
                events.append(data)
        return events

    def _build_interaction_metrics(self,
                                   prompt_text: str,
                                   response_text: str,
                                   events: list,
                                   api_elapsed_ms: int,
                                   raw_stdout: str,
                                   raw_stderr: str) -> dict:
        thread_id = None
        usage = {}
        for event in events:
            event_type = event.get("type")
            if event_type == "thread.started":
                thread_id = event.get("thread_id")
            elif event_type == "turn.completed":
                usage = event.get("usage", {}) or {}

        return {
            "version": 1,
            "source": "agent_runner",
            "adapter": "codex",
            "session_id": thread_id,
            "message_id": None,
            "provider_id": "openai",
            "model_id": self.model,
            "timing": {
                "api_elapsed_ms": api_elapsed_ms,
                "model_elapsed_ms": api_elapsed_ms,
            },
            "usage": {
                "input_tokens": usage.get("input_tokens"),
                "output_tokens": usage.get("output_tokens"),
                "reasoning_tokens": usage.get("reasoning_tokens"),
                "cache_read_tokens": usage.get("cached_input_tokens"),
                "cache_write_tokens": None,
                "cost": None,
            },
            "message": {
                "input_chars": len(prompt_text or ""),
                "output_chars": len(response_text or ""),
            },
            "tools": {
                "available": None,
                "observed_calls": [],
            },
            "raw": {
                "events": events,
                "stdout": raw_stdout,
                "stderr": raw_stderr,
            },
        }
