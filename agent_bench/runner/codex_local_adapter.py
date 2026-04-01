# -*- coding: utf-8 -*-
"""本地 Codex CLI 适配器。"""

import os
import queue
import re
import signal
import sys
import time
import tempfile
import subprocess
import threading
from typing import Optional

from agent_bench.runner.adapter import AgentAdapter

DEFAULT_CODEX_CLI = "codex"
TIMEOUT = 480


class CodexLocalAdapter(AgentAdapter):
    """通过本地 codex exec 实现的适配器。"""

    def __init__(self,
                 cli_path: str = DEFAULT_CODEX_CLI,
                 model: str = None,
                 timeout: int = TIMEOUT,
                 temperature: float = None,
                 on_progress=None,
                 profile: str = None,
                 env: dict = None):
        self.cli_path = cli_path
        self.model = model
        self.timeout = timeout
        self.temperature = temperature
        self.on_progress = on_progress
        self.profile = profile
        self.env = env or {}

        self._system_message = ""
        self._last_interaction_metrics = None

    def _log(self, level: str, message: str, tag: str = ""):
        if self.on_progress:
            self.on_progress("log", {"level": level, "message": f"{tag}{message}"})
        if level == "ERROR":
            print(f"  [ERROR] {tag}{message}", file=sys.stderr)

    @staticmethod
    def _clip_line(text: str, limit: int = 200) -> str:
        text = text or ""
        return text if len(text) <= limit else text[:limit] + "...<truncated>"

    def setup(self, enhancements: dict, on_progress=None):
        if on_progress:
            self.on_progress = on_progress

        self._last_interaction_metrics = None
        self._system_message = ""

        if not enhancements:
            self._log("DEBUG", "基线模式: 无增强配置")
            return

        system_prompt = (enhancements.get("system_prompt") or "").strip()
        if system_prompt:
            self._system_message = system_prompt
            self._log("INFO", f"已配置 System Prompt ({len(system_prompt)} 字符)")

        for skill in enhancements.get("skills", []) or []:
            name = skill.get("name", "unknown")
            content = (skill.get("content") or "").strip()
            if not content:
                continue
            sep = "\n\n" if self._system_message else ""
            self._system_message += f"{sep}## Skill: {name}\n\n{content}"
            self._log("INFO", f"已配置 Skill: {name} ({len(content)} 字符)")

        if enhancements.get("mcp_servers"):
            self._log("WARN", "CodexLocalAdapter 当前不支持动态 MCP 注册，已忽略 mcp_servers")
        if enhancements.get("tools") is not None:
            self._log("WARN", "CodexLocalAdapter 当前不支持 tools 开关注入，已忽略 tools")

    def execute(self, prompt: str, tag: str = "", workspace_dir: Optional[str] = None) -> str:
        self._last_interaction_metrics = None
        workdir = workspace_dir or os.getcwd()
        effective_prompt = prompt
        if self._system_message:
            effective_prompt = f"{self._system_message}\n\n{effective_prompt}" if effective_prompt else self._system_message
        if workspace_dir:
            effective_prompt = (
                f"## 工作目录\n{workspace_dir}\n\n"
                "请直接在这个目录中修改工程文件完成任务，不要只返回单个代码片段。\n\n"
                f"{effective_prompt}"
            )

        with tempfile.NamedTemporaryFile(prefix="codex_last_", suffix=".txt", delete=False) as tmp:
            output_path = tmp.name

        cmd = [
            self.cli_path,
            "exec",
            "-C", workdir,
            "--skip-git-repo-check",
            "--full-auto",
            "--color", "never",
            "-o", output_path,
        ]
        if self.model:
            cmd.extend(["-m", self.model])
        if self.profile:
            cmd.extend(["-p", self.profile])
        cmd.append("-")

        self._log("INFO",
                  f"发送请求: Prompt={len(effective_prompt.encode('utf-8'))/1024:.1f}KB, "
                  f"{'system' if self._system_message else '无system'}, 无tools, "
                  f"{f'model={self.model}' if self.model else '无model'}, 超时={self.timeout}s",
                  tag=tag)
        self._log("DEBUG", f"Codex 命令: {' '.join(cmd[:-1])} -", tag=tag)

        t0 = time.time()
        line_queue: queue.Queue = queue.Queue()
        stdout_chunks = []
        stderr_chunks = []
        try:
            child_env = os.environ.copy()
            child_env.update({str(k): str(v) for k, v in (self.env or {}).items() if v is not None})
            proc = subprocess.Popen(
                cmd,
                stdin=subprocess.PIPE,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                bufsize=1,
                cwd=workdir,
                env=child_env,
                start_new_session=True,
            )
            self._log("DEBUG", "Codex 进程已启动", tag=tag)
            if proc.stdin:
                proc.stdin.write(effective_prompt)
                proc.stdin.close()
        except FileNotFoundError:
            self._log("ERROR", f"未找到 Codex CLI: {self.cli_path}", tag=tag)
            return ""
        except Exception as e:
            self._log("ERROR", f"启动 Codex 失败: {e}", tag=tag)
            return ""

        threads = [
            threading.Thread(target=self._stream_reader, args=(proc.stdout, "stdout", line_queue), daemon=True),
            threading.Thread(target=self._stream_reader, args=(proc.stderr, "stderr", line_queue), daemon=True),
        ]
        for th in threads:
            th.start()

        last_heartbeat = t0
        last_key_output = "已建立会话，等待模型响应"
        last_key_output_ts = t0
        last_stream_output_ts = t0
        output_file_seen_ts = None
        output_file_size = 0
        proc_exit_ts = None
        while True:
            now = time.time()
            if now - t0 > self.timeout:
                try:
                    os.killpg(proc.pid, signal.SIGKILL)
                except Exception:
                    proc.kill()
                for th in threads:
                    th.join(timeout=0.5)
                self._log("ERROR", f"请求超时 ({self.timeout}s)", tag=tag)
                raise TimeoutError(f"Agent 请求超时 ({self.timeout}s)")

            try:
                source, line = line_queue.get(timeout=1)
                last_stream_output_ts = time.time()
                if source == "stdout":
                    stdout_chunks.append(line)
                else:
                    stderr_chunks.append(line)
                key_output = self._log_cli_line(line, effective_prompt, tag=tag)
                if key_output and not key_output.startswith(("session id:", "provider:", "model:")):
                    last_key_output = key_output
                    last_key_output_ts = time.time()
            except queue.Empty:
                pass

            if output_file_seen_ts is None and os.path.exists(output_path):
                try:
                    stat = os.stat(output_path)
                    output_file_seen_ts = time.time()
                    output_file_size = stat.st_size
                    self._log("DEBUG", f"Codex 输出文件已生成: size={output_file_size} bytes", tag=tag)
                except OSError:
                    pass
            elif os.path.exists(output_path):
                try:
                    output_file_size = os.path.getsize(output_path)
                except OSError:
                    pass

            if proc_exit_ts is None and proc.poll() is not None:
                proc_exit_ts = time.time()
                self._log("DEBUG", f"Codex 主进程已退出: exit={proc.returncode}", tag=tag)

            if proc.poll() is None and now - last_heartbeat >= 10:
                silent_for = int(now - last_key_output_ts)
                stream_silent_for = int(now - last_stream_output_ts)
                output_state = (
                    f"输出文件已生成({output_file_size} bytes)"
                    if output_file_seen_ts is not None else
                    "输出文件未生成"
                )
                proc_state = "主进程仍在运行" if proc_exit_ts is None else f"主进程已退出({int(now - proc_exit_ts)}s)"
                self._log(
                    "DEBUG",
                    f"Codex 仍在执行... {int(now - t0)}s | 最近输出: {last_key_output[:80]} | "
                    f"已 {silent_for}s 无新关键输出 | 已 {stream_silent_for}s 无新stdout/stderr | "
                    f"{output_state} | {proc_state}",
                    tag=tag,
                )
                last_heartbeat = now

            if proc.poll() is not None and line_queue.empty() and all(not th.is_alive() for th in threads):
                break

        for th in threads:
            th.join(timeout=0.5)
        self._log("DEBUG", "Codex 输出流收尾完成", tag=tag)
        elapsed_ms = round((time.time() - t0) * 1000)

        stdout = "".join(stdout_chunks)
        stderr = "".join(stderr_chunks)
        output_text = ""
        if os.path.exists(output_path):
            try:
                with open(output_path, "r", encoding="utf-8") as f:
                    output_text = f.read().strip()
            except Exception as e:
                self._log("WARN", f"读取 Codex 最终输出失败: {e}", tag=tag)
        try:
            os.remove(output_path)
        except OSError:
            pass

        if proc.returncode != 0:
            detail = (stderr or stdout).strip()
            preview = detail[:400].replace("\n", "\\n")
            self._log("ERROR", f"Codex 执行失败: exit={proc.returncode}, detail={preview}", tag=tag)
            self._last_interaction_metrics = self._build_interaction_metrics(
                effective_prompt, output_text, stdout, stderr, elapsed_ms, proc.returncode
            )
            return output_text

        self._last_interaction_metrics = self._build_interaction_metrics(
            effective_prompt, output_text, stdout, stderr, elapsed_ms, proc.returncode
        )
        self._log("INFO", f"收到响应: {len(output_text)}字符, 耗时={elapsed_ms/1000:.1f}s", tag=tag)
        return output_text

    def _stream_reader(self, pipe, source: str, line_queue: queue.Queue):
        if pipe is None:
            return
        try:
            for line in iter(pipe.readline, ""):
                line_queue.put((source, line))
        finally:
            try:
                pipe.close()
            except Exception:
                pass

    def _log_cli_line(self, line: str, prompt_text: str, tag: str = ""):
        text = (line or "").strip()
        if not text:
            return None
        if text == "user":
            return None
        if prompt_text and text in prompt_text:
            return None
        level = "INFO"
        upper_text = text.upper()
        if "ERROR" in upper_text or "PANICKED" in upper_text or "FAIL " in upper_text or text.startswith("fail "):
            level = "ERROR"
        elif "WARNING" in upper_text or "RECONNECTING" in upper_text:
            level = "WARN"
        clipped = self._clip_line(text)
        self._log(level, f"Codex 输出: {clipped}", tag=tag)
        if text.startswith(("session id:", "provider:", "model:")):
            return None
        return clipped

    def _build_interaction_metrics(self, prompt_text: str, output_text: str,
                                   stdout: str, stderr: str,
                                   elapsed_ms: int, exit_code: int) -> dict:
        total_tokens = None
        token_match = re.search(r"tokens used\s*([\d,]+)", stdout, re.IGNORECASE)
        if token_match:
            total_tokens = int(token_match.group(1).replace(",", ""))
        provider_match = re.search(r"provider:\s*(.+)", stdout)
        model_match = re.search(r"model:\s*(.+)", stdout)
        session_match = re.search(r"session id:\s*(.+)", stdout)
        return {
            "version": 1,
            "source": "agent_runner",
            "adapter": "codex_local",
            "session_id": session_match.group(1).strip() if session_match else None,
            "message_id": None,
            "provider_id": provider_match.group(1).strip() if provider_match else "openai",
            "model_id": model_match.group(1).strip() if model_match else self.model,
            "timing": {
                "api_elapsed_ms": elapsed_ms,
                "model_elapsed_ms": elapsed_ms,
            },
            "usage": {
                "input_tokens": None,
                "output_tokens": None,
                "reasoning_tokens": None,
                "cache_read_tokens": None,
                "cache_write_tokens": None,
                "cost": None,
                "total_tokens": total_tokens,
            },
            "message": {
                "input_chars": len(prompt_text or ""),
                "output_chars": len(output_text or ""),
            },
            "tools": {
                "available": None,
                "observed_calls": [],
            },
            "raw": {
                "exit_code": exit_code,
                "stdout_tail": stdout[-4000:] if stdout else "",
                "stderr_tail": stderr[-4000:] if stderr else "",
            },
        }

    def teardown(self):
        self._system_message = ""

    def get_last_interaction_metrics(self):
        return self._last_interaction_metrics
