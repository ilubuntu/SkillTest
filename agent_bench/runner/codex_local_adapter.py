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
import shutil
import glob
from collections import deque
from typing import Optional
from pathlib import Path

from agent_bench.runner.adapter import AgentAdapter

DEFAULT_CODEX_CLI = "codex"
TIMEOUT = 480


class CodexLocalAdapter(AgentAdapter):
    """通过本地 codex exec 实现的适配器。"""

    _RESOLVED_COMMAND_CACHE = {}
    _NO_PROGRESS_TIMEOUT_SECONDS = 90
    _NO_PROGRESS_GRACE_SECONDS = 150
    _TERMINATE_GRACE_SECONDS = 8
    _MAX_CAPTURED_LINES = 400

    def __init__(self,
                 cli_path: str = DEFAULT_CODEX_CLI,
                 model: str = None,
                 timeout: int = TIMEOUT,
                 temperature: float = None,
                 on_progress=None,
                 profile: str = None,
                 env: dict = None,
                 resume_session_id: str = None,
                 resume_last: bool = False):
        self.cli_path = cli_path
        self.model = model
        self.timeout = timeout
        self.temperature = temperature
        self.on_progress = on_progress
        self.profile = profile
        self.env = env or {}
        self.resume_session_id = str(resume_session_id or "").strip() or None
        self.resume_last = bool(resume_last)

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

    @staticmethod
    def _looks_like_code_error_snippet(text: str) -> bool:
        snippet = (text or "").strip()
        if not snippet:
            return False

        normalized = snippet.lstrip("+- ").strip()
        code_error_patterns = [
            r"\bnew\s+Error\s*\(",
            r"\bthrow\s+new\s+Error\s*\(",
            r"\breject\s*\(\s*new\s+Error\s*\(",
            r"\bPromise\.reject\s*\(\s*new\s+Error\s*\(",
        ]
        return any(re.search(pattern, normalized, re.IGNORECASE) for pattern in code_error_patterns)

    @staticmethod
    def _looks_like_search_result_snippet(text: str) -> bool:
        snippet = (text or "").strip()
        if not snippet:
            return False

        path_hit_patterns = [
            r"^[A-Za-z]:\\.+\.(?:ets|ts|js|json|yaml|yml|md):\d+:",
            r"^[.\\/\w-]+[\\/].+\.(?:ets|ts|js|json|yaml|yml|md):\d+:",
            r"^\d+:\s+.*(?:console\.error|logFormatedErrorAndExit|catch\s*\(|ERROR_[0-9]{2}|\"[A-Z0-9_]*ERROR[A-Z0-9_]*\")",
        ]
        if not any(re.search(pattern, snippet, re.IGNORECASE) for pattern in path_hit_patterns):
            return False

        lowered = snippet.lower()
        return any(token in lowered for token in [
            "error",
            "exception",
            "catch(",
            "catch((",
            "throw ",
            "console.error",
            "verbose stack",
            "message\":",
        ])

    @staticmethod
    def _looks_like_diff_noise(text: str) -> bool:
        snippet = (text or "").strip()
        if not snippet:
            return False

        if snippet.startswith(("diff --git ", "index ", "--- a/", "+++ b/", "@@ ")):
            return True

        if snippet.startswith(("+", "-")) and not snippet.startswith(("+++", "---")):
            return True

        code_like_prefix = (
            "import ", "export ", "const ", "let ", "var ", "function ", "class ",
            "if ", "for ", "while ", "return ", "@", "}", "{", "//",
        )
        if snippet.startswith(("+", "-")):
            normalized = snippet[1:].lstrip()
            return normalized.startswith(code_like_prefix) or normalized.endswith(("{", "}", ");", ");", "()", ":", ",")) or ";" in normalized

        return False

    @staticmethod
    def _is_meaningful_progress_line(text: str) -> bool:
        snippet = (text or "").strip()
        if not snippet:
            return False

        lowered = snippet.lower()
        if lowered in {"exec", "codex"}:
            return True

        markers = [
            "succeeded in",
            "exited ",
            "summary",
            "tests",
            "next steps",
            "assemblehap",
            "hvigor",
            "build success",
            "build failed",
            "编译",
            "构建",
            "收到响应",
        ]
        return any(marker in lowered for marker in markers)

    @staticmethod
    def _extract_blocker_signature(text: str) -> Optional[str]:
        snippet = (text or "").strip()
        if not snippet:
            return None
        lowered = snippet.lower()
        blocker_markers = [
            "sdk component missing",
            "the property of module should be an array",
            "module-srcpath is missing",
            "invalid exports, no system plugins were found in hvigorfile",
            "schema validate failed",
            "configuration error",
            "daemon-sec.json",
        ]
        for marker in blocker_markers:
            if marker in lowered:
                return marker
        return None

    @staticmethod
    def _should_capture_output_line(text: str) -> bool:
        snippet = (text or "").strip()
        if not snippet:
            return False
        if CodexLocalAdapter._looks_like_diff_noise(snippet):
            return False
        if len(snippet) > 800 and not CodexLocalAdapter._is_meaningful_progress_line(snippet):
            return False
        return True

    @staticmethod
    def _decode_line(line) -> str:
        if isinstance(line, bytes):
            return line.decode("utf-8", errors="replace").strip()
        return (line or "").strip()

    def _build_exec_command(self, executable: str, workdir: str, output_path: str,
                            resume_session_id: Optional[str] = None,
                            resume_last: bool = False):
        if resume_session_id or resume_last:
            cmd = [
                executable,
                "-C", workdir,
                "exec",
                "resume",
                "--skip-git-repo-check",
                "--dangerously-bypass-approvals-and-sandbox",
                "--color", "never",
                "-o", output_path,
            ]
            if self.model:
                cmd.extend(["-m", self.model])
            if self.profile:
                cmd.extend(["-p", self.profile])
            if resume_session_id:
                cmd.append(resume_session_id)
            else:
                cmd.append("--last")
            cmd.append("-")
            return cmd

        cmd = [
            executable,
            "exec",
            "-C", workdir,
            "-s", "danger-full-access",
            "--skip-git-repo-check",
            "--color", "never",
            "-o", output_path,
        ]
        if self.model:
            cmd.extend(["-m", self.model])
        if self.profile:
            cmd.extend(["-p", self.profile])
        cmd.append("-")
        return cmd

    def _resolve_command(self) -> Optional[str]:
        cache_key = str(self.cli_path or DEFAULT_CODEX_CLI)
        cached = self._RESOLVED_COMMAND_CACHE.get(cache_key)
        if cached:
            if os.path.isfile(cached) or shutil.which(cached):
                return cached
            self._RESOLVED_COMMAND_CACHE.pop(cache_key, None)

        candidates = []
        if self.cli_path:
            candidates.append(self.cli_path)

        for candidate in candidates:
            resolved = shutil.which(candidate)
            if resolved:
                self._RESOLVED_COMMAND_CACHE[cache_key] = resolved
                return resolved
            if os.path.isfile(candidate):
                self._RESOLVED_COMMAND_CACHE[cache_key] = candidate
                return candidate

        user_home = Path.home()
        fallback_patterns = [
            user_home / ".vscode" / "extensions" / "openai.chatgpt-*" / "bin" / "windows-x86_64" / "codex.exe",
            user_home / ".codex" / "bin" / "codex.exe",
        ]
        for pattern in fallback_patterns:
            matches = sorted(glob.glob(str(pattern)))
            if matches:
                self._RESOLVED_COMMAND_CACHE[cache_key] = matches[-1]
                return matches[-1]

        return None

    @staticmethod
    def _build_workspace_agent_env(workspace_dir: Optional[str]) -> dict:
        workspace = str(workspace_dir or "").strip()
        if not workspace or not os.path.isdir(workspace):
            return {}
        try:
            from agent_bench.pipeline.compile_checker import build_agent_workspace_env
            return build_agent_workspace_env(workspace)
        except Exception:
            return {}

    @staticmethod
    def _build_prepared_env_prompt(workspace_agent_env: dict) -> str:
        if not workspace_agent_env:
            return ""
        node_bin = workspace_agent_env.get("AGENT_BENCH_NODE_BIN", "")
        hvigor_js = workspace_agent_env.get("AGENT_BENCH_HVIGOR_JS", "")
        sdk_root = workspace_agent_env.get("AGENT_BENCH_SDK_ROOT", "")
        java_home = workspace_agent_env.get("AGENT_BENCH_JAVA_HOME", "")
        workspace_dir = workspace_agent_env.get("AGENT_BENCH_WORKSPACE_DIR", "")
        home_dir = workspace_agent_env.get("HOME", "")
        cache_dir = workspace_agent_env.get("NPM_CONFIG_CACHE", "")
        return "\n".join([
            "## Prepared HarmonyOS Environment",
            "- The runner already prepared the DevEco/HarmonyOS toolchain for this workspace.",
            f"- Workspace root for all hvigor commands: {workspace_dir}",
            f"- Reuse these exact paths directly: NodeBin={node_bin}; HvigorJs={hvigor_js}; SdkRoot={sdk_root}; JavaHome={java_home}",
            f"- Reuse the prepared writable cache directories directly: HOME={home_dir}; NPM_CONFIG_CACHE={cache_dir}",
            "- Do not search for DevEco paths again, do not run hvigor from entry/, and do not switch back to C:\\Users\\...\\.hvigor caches.",
            "- For internal self-checks, run hvigor only from the workspace root with the prepared NodeBin and HvigorJs.",
        ])

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

        if enhancements.get("mcp_servers"):
            self._log("WARN", "CodexLocalAdapter 当前不支持动态 MCP 注册，已忽略 mcp_servers")
        if enhancements.get("tools") is not None:
            self._log("WARN", "CodexLocalAdapter 当前不支持 tools 开关注入，已忽略 tools")

    def execute(self, prompt: str, tag: str = "", workspace_dir: Optional[str] = None) -> str:
        self._last_interaction_metrics = None
        workdir = workspace_dir or os.getcwd()
        workspace_agent_env = self._build_workspace_agent_env(workspace_dir)
        effective_prompt = prompt
        if self._system_message:
            effective_prompt = f"{self._system_message}\n\n{effective_prompt}" if effective_prompt else self._system_message
        prepared_env_prompt = self._build_prepared_env_prompt(workspace_agent_env)
        if prepared_env_prompt:
            effective_prompt = f"{prepared_env_prompt}\n\n{effective_prompt}" if effective_prompt else prepared_env_prompt
        if workspace_dir:
            effective_prompt = (
                f"## 工作目录\n{workspace_dir}\n\n"
                "请直接在此目录修改工程文件完成任务。\n\n"
                f"{effective_prompt}"
            )

        with tempfile.NamedTemporaryFile(prefix="codex_last_", suffix=".txt", delete=False) as tmp:
            output_path = tmp.name

        executable = self._resolve_command()
        if not executable:
            self._log("ERROR", f"未找到 Codex CLI: {self.cli_path}", tag=tag)
            return ""

        attempt_specs = []
        if self.resume_session_id:
            attempt_specs.append(("resume", self.resume_session_id, False))
        elif self.resume_last:
            attempt_specs.append(("resume_last", None, True))
        attempt_specs.append(("fresh", None, False))

        last_metrics = None
        attempted_resume = False
        resume_fell_back = False
        if workspace_agent_env:
            self._log(
                "DEBUG",
                "Codex 已复用工作区编译环境: "
                f"sdk={workspace_agent_env.get('AGENT_BENCH_SDK_ROOT', '')}, "
                f"node={workspace_agent_env.get('AGENT_BENCH_NODE_BIN', '')}",
                tag=tag,
            )
        for attempt_mode, resume_session_id, resume_last in attempt_specs:
            if attempt_mode in {"resume", "resume_last"} and attempted_resume:
                continue
            attempted_resume = attempted_resume or attempt_mode in {"resume", "resume_last"}

            mode_label = "resume" if resume_session_id else ("resume_last" if resume_last else "fresh")
            cmd = self._build_exec_command(
                executable,
                workdir,
                output_path,
                resume_session_id=resume_session_id,
                resume_last=resume_last,
            )
            self._log(
                "INFO",
                f"发送请求: mode={mode_label}, Prompt={len(effective_prompt.encode('utf-8'))/1024:.1f}KB, "
                f"{'system' if self._system_message else '无system'}, 无tools, "
                f"{f'model={self.model}' if self.model else '无model'}, 超时={self.timeout}s",
                tag=tag,
            )
            self._log("DEBUG", f"Codex 命令: {' '.join(cmd[:-1])} -", tag=tag)

            t0 = time.time()
            line_queue: queue.Queue = queue.Queue()
            stdout_chunks = deque(maxlen=self._MAX_CAPTURED_LINES)
            stderr_chunks = deque(maxlen=self._MAX_CAPTURED_LINES)
            try:
                child_env = os.environ.copy()
                child_env.update({str(k): str(v) for k, v in workspace_agent_env.items() if v is not None})
                child_env.update({str(k): str(v) for k, v in (self.env or {}).items() if v is not None})
                child_env.setdefault("AGENT_BENCH_ORIGINAL_USERPROFILE", os.environ.get("USERPROFILE", ""))
                child_env.setdefault("AGENT_BENCH_ORIGINAL_LOCALAPPDATA", os.environ.get("LOCALAPPDATA", ""))
                child_env.setdefault("AGENT_BENCH_ORIGINAL_APPDATA", os.environ.get("APPDATA", ""))
                proc = subprocess.Popen(
                    cmd,
                    stdin=subprocess.PIPE,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.PIPE,
                    bufsize=0,
                    cwd=workdir,
                    env=child_env,
                    start_new_session=True,
                )
                self._log("DEBUG", f"Codex 进程已启动 ({mode_label})", tag=tag)
                if proc.stdin:
                    proc.stdin.write(effective_prompt.encode("utf-8"))
                    proc.stdin.close()
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
            last_output_file_growth_ts = t0
            proc_exit_ts = None
            forced_stop_reason = None
            terminate_deadline = None
            repeated_blockers = {}
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
                    text = self._decode_line(line)
                    if source == "stdout":
                        if self._should_capture_output_line(text):
                            stdout_chunks.append(text)
                    else:
                        if self._should_capture_output_line(text):
                            stderr_chunks.append(text)
                    key_output, is_meaningful = self._log_cli_line(text, effective_prompt, tag=tag)
                    blocker_signature = self._extract_blocker_signature(text)
                    if blocker_signature:
                        repeated_blockers[blocker_signature] = repeated_blockers.get(blocker_signature, 0) + 1
                    if key_output and is_meaningful and not key_output.startswith(("session id:", "provider:", "model:")):
                        last_key_output = key_output
                        last_key_output_ts = time.time()
                except queue.Empty:
                    pass

                if output_file_seen_ts is None and os.path.exists(output_path):
                    try:
                        stat = os.stat(output_path)
                        output_file_seen_ts = time.time()
                        output_file_size = stat.st_size
                        last_output_file_growth_ts = output_file_seen_ts
                        self._log("DEBUG", f"Codex 输出文件已生成: size={output_file_size} bytes", tag=tag)
                    except OSError:
                        pass
                elif os.path.exists(output_path):
                    try:
                        latest_size = os.path.getsize(output_path)
                        if latest_size != output_file_size:
                            output_file_size = latest_size
                            last_output_file_growth_ts = time.time()
                        else:
                            output_file_size = latest_size
                    except OSError:
                        pass

                if proc_exit_ts is None and proc.poll() is not None:
                    proc_exit_ts = time.time()
                    self._log("DEBUG", f"Codex 主进程已退出: exit={proc.returncode}", tag=tag)

                no_progress_for = now - last_key_output_ts
                if (
                    proc.poll() is None
                    and forced_stop_reason is None
                    and now - t0 >= self._NO_PROGRESS_GRACE_SECONDS
                    and no_progress_for >= self._NO_PROGRESS_TIMEOUT_SECONDS
                    and now - last_output_file_growth_ts >= 20
                ):
                    forced_stop_reason = (
                        f"Codex 长时间无新有效进展 ({int(no_progress_for)}s)，提前结束本轮执行"
                    )
                    self._log("WARN", forced_stop_reason, tag=tag)
                    try:
                        proc.terminate()
                    except Exception:
                        try:
                            proc.kill()
                        except Exception:
                            pass
                    terminate_deadline = now + self._TERMINATE_GRACE_SECONDS

                repeated_blocker = next(
                    (sig for sig, count in repeated_blockers.items() if count >= 2),
                    None,
                )
                if (
                    proc.poll() is None
                    and forced_stop_reason is None
                    and repeated_blocker
                    and now - t0 >= 60
                ):
                    forced_stop_reason = (
                        f"Codex 重复命中同类阻塞错误 ({repeated_blocker})，提前结束本轮执行"
                    )
                    self._log("WARN", forced_stop_reason, tag=tag)
                    try:
                        proc.terminate()
                    except Exception:
                        try:
                            proc.kill()
                        except Exception:
                            pass
                    terminate_deadline = now + self._TERMINATE_GRACE_SECONDS

                if terminate_deadline and proc.poll() is None and now >= terminate_deadline:
                    self._log("WARN", "Codex 未在宽限时间内退出，已强制结束进程", tag=tag)
                    try:
                        proc.kill()
                    except Exception:
                        pass
                    terminate_deadline = None

                if proc.poll() is None and now - last_heartbeat >= 15:
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
                        f"Codex 仍在执行... {int(now - t0)}s | 最近进展: {last_key_output[:80]} | "
                        f"已 {silent_for}s 无新有效进展 | 已 {stream_silent_for}s 无新stdout/stderr | "
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

            stdout = "\n".join(stdout_chunks)
            stderr = "\n".join(stderr_chunks)
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

            detail_text = (stderr or stdout).strip()
            last_metrics = self._build_interaction_metrics(
                effective_prompt,
                output_text,
                stdout,
                stderr,
                elapsed_ms,
                proc.returncode,
                attempt_mode=attempt_mode,
                resume_requested=attempt_mode in {"resume", "resume_last"},
                resume_last_requested=bool(resume_last),
                resume_session_id=resume_session_id,
                workspace_env_prepared=bool(workspace_agent_env),
            )
            if forced_stop_reason:
                raw = last_metrics.setdefault("raw", {})
                raw["early_stopped"] = True
                raw["early_stop_reason"] = forced_stop_reason

            if proc.returncode == 0:
                self._last_interaction_metrics = last_metrics
                self._log("INFO", f"收到响应: {len(output_text)}字符, 耗时={elapsed_ms/1000:.1f}s", tag=tag)
                return output_text

            if (resume_session_id or resume_last) and not output_text:
                preview = detail_text[:300].replace("\n", "\\n")
                self._log("WARN", f"Codex resume 失败，回退 fresh exec: exit={proc.returncode}, detail={preview}", tag=tag)
                resume_fell_back = True
                continue

            preview = detail_text[:400].replace("\n", "\\n")
            log_level = "WARN" if forced_stop_reason else "ERROR"
            message = f"Codex 执行失败: exit={proc.returncode}, detail={preview}"
            if forced_stop_reason:
                message = f"{forced_stop_reason}; exit={proc.returncode}, detail={preview}"
            self._log(log_level, message, tag=tag)
            if last_metrics is not None and resume_fell_back:
                raw = last_metrics.setdefault("raw", {})
                raw["resume_fallback"] = True
            self._last_interaction_metrics = last_metrics
            return output_text

        if last_metrics is not None and resume_fell_back:
            raw = last_metrics.setdefault("raw", {})
            raw["resume_fallback"] = True
        self._last_interaction_metrics = last_metrics
        return ""

    def _stream_reader(self, pipe, source: str, line_queue: queue.Queue):
        if pipe is None:
            return
        try:
            for line in iter(pipe.readline, b""):
                line_queue.put((source, line))
        finally:
            try:
                pipe.close()
            except Exception:
                pass

    def _log_cli_line(self, line, prompt_text: str, tag: str = ""):
        text = self._decode_line(line)
        if not text:
            return None, False
        if text == "user":
            return None, False
        if prompt_text and text in prompt_text:
            return None, False
        if self._looks_like_diff_noise(text):
            return None, False
        level = "INFO"
        upper_text = text.upper()

        is_tool_router_error = (
            "CODEX_CORE::TOOLS::ROUTER:" in upper_text
            and "EXIT CODE:" in upper_text
        )
        is_tool_exit_line = re.match(r"^exited\s+\d+\s+in\s+\d+ms:", text, re.IGNORECASE) is not None

        has_error_marker = re.search(r"\bERROR\b", upper_text) is not None
        has_panicked_marker = re.search(r"\bPANICKED\b", upper_text) is not None
        has_fail_marker = (
            re.search(r"\bFAIL(?:ED)?\b", upper_text) is not None
            or text.lower().startswith("fail ")
        )
        has_warning_marker = (
            re.search(r"\bWARNING\b", upper_text) is not None
            or "RECONNECTING" in upper_text
        )
        is_code_error_snippet = self._looks_like_code_error_snippet(text)
        is_search_result_snippet = self._looks_like_search_result_snippet(text)

        if is_tool_router_error or is_tool_exit_line:
            level = "WARN"
        elif (has_error_marker or has_panicked_marker or has_fail_marker) and not is_code_error_snippet and not is_search_result_snippet:
            level = "ERROR"
        elif has_warning_marker:
            level = "WARN"
        clipped = self._clip_line(text)
        is_meaningful = self._is_meaningful_progress_line(text)
        if level != "INFO" or is_meaningful:
            self._log(level, f"Codex 输出: {clipped}", tag=tag)
        if text.startswith(("session id:", "provider:", "model:")):
            return None, False
        return clipped, is_meaningful

    def _build_interaction_metrics(self, prompt_text: str, output_text: str,
                                   stdout: str, stderr: str,
                                   elapsed_ms: int, exit_code: int,
                                   attempt_mode: str = "fresh",
                                   resume_requested: bool = False,
                                   resume_last_requested: bool = False,
                                   resume_session_id: Optional[str] = None,
                                   workspace_env_prepared: bool = False) -> dict:
        combined_output = f"{stdout}\n{stderr}"
        total_tokens = None
        token_match = re.search(r"tokens used\s*([\d,]+)", combined_output, re.IGNORECASE)
        if token_match:
            total_tokens = int(token_match.group(1).replace(",", ""))
        provider_match = re.search(r"provider:\s*(.+)", combined_output)
        model_match = re.search(r"model:\s*(.+)", combined_output)
        session_match = re.search(r"session id:\s*(.+)", combined_output)
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
                "attempt_mode": attempt_mode,
                "resume_requested": bool(resume_requested),
                "resume_last_requested": bool(resume_last_requested),
                "resume_session_id": resume_session_id,
                "workspace_env_prepared": bool(workspace_env_prepared),
                "stdout_tail": stdout[-4000:] if stdout else "",
                "stderr_tail": stderr[-4000:] if stderr else "",
            },
        }

    def teardown(self):
        self._system_message = ""

    def get_last_interaction_metrics(self):
        return self._last_interaction_metrics
