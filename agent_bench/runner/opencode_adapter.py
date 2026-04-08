# -*- coding: utf-8 -*-
"""OpenCode Agent 适配器

通过 OpenCode Server HTTP API 实现 AgentAdapter 接口。

增强工具映射：
- system_prompt → message payload 的 system 字段
- skills        → 仅记录声明挂载的 skill 名称
- mcp_servers   → POST /mcp 动态注册
- tools         → message payload 的 tools 字段

OpenCode API 参考：https://opencode.ai/docs/zh-cn/server/
"""

import json
import os
import sys
import threading
import time
import urllib.parse
import urllib.request
import urllib.error
from typing import Optional

from agent_bench.pipeline.artifacts import agent_meta_dir, review_dir, static_dir
from agent_bench.runner.adapter import AgentAdapter

DEFAULT_API_BASE = "http://localhost:4096"
TIMEOUT = 480
MAX_RAW_SSE_LINE_CHARS = 2000


def parse_model(model_str: str) -> dict:
    """解析模型字符串为 API 格式

    Args:
        model_str: 如 "minimax/MiniMax-M2.7" 或 "MiniMax-M2.7"

    Returns:
        {"providerID": "...", "modelID": "..."}
    """
    if "/" in model_str:
        provider, model_id = model_str.split("/", 1)
        return {"providerID": provider, "modelID": model_id}
    return {"modelID": model_str}


class OpenCodeAdapter(AgentAdapter):
    """OpenCode Server 适配器"""

    def __init__(self, api_base: str = DEFAULT_API_BASE,
                 agent: str = None,
                 model: str = None,
                 target_skills: Optional[list[str]] = None,
                 timeout: int = TIMEOUT,
                 temperature: float = None,
                 on_progress=None,
                 artifact_prefix: str = "agent",
                 artifact_base_dir: str = "generate"):
        self.api_base = api_base
        self.agent = agent
        self.model = model
        self.target_skills = [str(item).strip() for item in (target_skills or []) if str(item).strip()]
        self.timeout = timeout
        self.temperature = temperature
        self.on_progress = on_progress
        self.artifact_prefix = artifact_prefix or "agent"
        self.artifact_base_dir = artifact_base_dir or "generate"

        # setup 阶段准备的配置
        self._system_message = ""
        self._tools_config = None
        self._registered_mcps = []  # 记录注册的 MCP server 名称，用于 teardown
        self._last_interaction_metrics = None
        self._last_error_message = ""
        self._prefer_async_sse = True
        self._seen_runtime_events = set()

    def _log(self, level: str, message: str, tag: str = ""):
        if self.on_progress:
            self.on_progress("log", {"level": level, "message": f"{tag}{message}"})
        if level == "ERROR":
            print(f"  [ERROR] {tag}{message}", file=sys.stderr)

    @staticmethod
    def _clip_text_for_log(text: str, limit: int = 120) -> str:
        text = (text or "").strip()
        if len(text) <= limit:
            return text
        return text[:limit] + "..."

    @staticmethod
    def _short_workspace_path(path: str) -> str:
        normalized = str(path or "").replace("\\", "/").strip()
        marker = "/agent_workspace/"
        if marker in normalized:
            return normalized.split(marker, 1)[1]
        return os.path.basename(normalized)

    @staticmethod
    def _session_prompt_url(api_base: str,
                            session_id: str,
                            endpoint: str,
                            workspace_dir: Optional[str] = None) -> str:
        base_url = f"{api_base}/session/{session_id}/{endpoint}"
        if not workspace_dir:
            return base_url
        query = urllib.parse.urlencode({
            "directory": workspace_dir,
        })
        return f"{base_url}?{query}"

    # ── setup ────────────────────────────────────────────────

    def setup(self, enhancements: dict, on_progress=None):
        """配置增强工具

        Args:
            enhancements: 运行时增强配置
        """
        if on_progress:
            self.on_progress = on_progress

        self._system_message = ""
        self._tools_config = None
        self._registered_mcps = []
        self._last_interaction_metrics = None
        self._last_error_message = ""
        self._seen_runtime_events = set()

        if not enhancements:
            self._log("DEBUG", "基线模式: 无增强配置")
            return

        system_prompt = enhancements.get("system_prompt", "")
        if system_prompt:
            self._system_message = system_prompt.strip()
            self._log("INFO", f"已配置 System Prompt ({len(self._system_message)} 字符)")

        # 1. MCP Servers → 通过 API 注册
        mcp_servers = enhancements.get("mcp_servers", [])
        for mcp in mcp_servers:
            self._register_mcp(mcp)

        # 2. Tools 开关
        tools = enhancements.get("tools")
        if tools:
            self._tools_config = tools
            self._log("INFO", f"已配置 Tools: {tools}")

    def _register_mcp(self, mcp: dict):
        """通过 POST /mcp 注册 MCP Server"""
        name = mcp.get("name", "")
        if not name:
            return

        config = {}
        if "command" in mcp:
            config["command"] = mcp["command"]
        if "args" in mcp:
            config["args"] = mcp["args"]
        if "env" in mcp:
            config["env"] = mcp["env"]
        if "url" in mcp:
            config["url"] = mcp["url"]

        try:
            payload = json.dumps({"name": name, "config": config}).encode("utf-8")
            req = urllib.request.Request(
                f"{self.api_base}/mcp",
                data=payload,
                headers={"Content-Type": "application/json"},
                method="POST"
            )
            with urllib.request.urlopen(req, timeout=10) as resp:
                resp.read()
            self._registered_mcps.append(name)
            self._log("INFO", f"已注册 MCP Server: {name}")
        except Exception as e:
            self._log("ERROR", f"注册 MCP Server [{name}] 失败: {e}")

    def _detect_skill_tool_visibility(self) -> Optional[dict]:
        if not self.model or "/" not in self.model:
            return None
        provider_id, model_id = self.model.split("/", 1)
        query = urllib.parse.urlencode({
            "provider": provider_id,
            "model": model_id,
        })
        try:
            req = urllib.request.Request(
                f"{self.api_base}/experimental/tool?{query}",
                method="GET",
            )
            with urllib.request.urlopen(req, timeout=10) as response:
                payload = json.loads(response.read().decode("utf-8"))
        except Exception as exc:
            return {
                "ok": False,
                "error": str(exc),
                "has_skill_tool": False,
                "target_skills": self.target_skills,
                "detected_skills": {},
            }

        entries = payload if isinstance(payload, list) else []
        has_skill_tool = False
        detected_skills = {skill: False for skill in self.target_skills}
        for entry in entries:
            if not isinstance(entry, dict):
                continue
            serialized = json.dumps(entry, ensure_ascii=False).lower()
            name = str(entry.get("name") or entry.get("tool") or "").strip().lower()
            if name == "skill" or "\"name\": \"skill\"" in serialized:
                has_skill_tool = True
            for skill_name in detected_skills:
                if skill_name.lower() in serialized:
                    detected_skills[skill_name] = True
        return {
            "ok": True,
            "has_skill_tool": has_skill_tool,
            "target_skills": self.target_skills,
            "detected_skills": detected_skills,
        }

    # ── execute ──────────────────────────────────────────────

    def execute(self, prompt: str, tag: str = "", workspace_dir: Optional[str] = None) -> str:
        """创建 session，发送消息（携带 system/tools 配置），返回响应"""
        try:
            self._last_interaction_metrics = None
            self._last_error_message = ""
            effective_prompt = prompt

            # 1. 创建 session
            self._log("INFO", "准备创建 OpenCode 会话...", tag=tag)
            visibility = self._detect_skill_tool_visibility()
            if visibility:
                if not visibility.get("ok"):
                    self._log("WARNING", f"OpenCode tool 探测失败: {visibility.get('error')}", tag=tag)
                else:
                    self._log(
                        "INFO",
                        "OpenCode tool 探测结果: "
                        f"skill_tool={'yes' if visibility.get('has_skill_tool') else 'no'}"
                        + (
                            ", " + ", ".join(
                                f"{skill_name.replace('-', '_')}={'yes' if matched else 'no'}"
                                for skill_name, matched in (visibility.get('detected_skills') or {}).items()
                            )
                            if visibility.get("detected_skills")
                            else ""
                        ),
                        tag=tag,
                    )
            t0 = time.time()
            session_id = self._create_session()
            if not session_id:
                self._log("ERROR", "创建 Session 失败", tag=tag)
                return ""
            self._log("INFO",
                f"OpenCode 会话已创建: {session_id[:12]}... ({time.time()-t0:.1f}s)",
                tag=tag)

            # 2. 构建 message payload
            message_payload = {
                "parts": [{"type": "text", "text": effective_prompt}],
            }
            if self.agent:
                message_payload["agent"] = self.agent
            if self.model:
                message_payload["model"] = parse_model(self.model)
            if self._system_message:
                message_payload["system"] = self._system_message
            if self._tools_config:
                message_payload["tools"] = self._tools_config
            if self.temperature is not None:
                message_payload["temperature"] = self.temperature

            data = json.dumps(message_payload).encode("utf-8")
            prompt_kb = len(data) / 1024
            has_system = "system" if self._system_message else "无system"
            has_tools = f"tools={list(self._tools_config.keys()) if isinstance(self._tools_config, dict) else self._tools_config}" if self._tools_config else "无tools"
            has_model = f"model={self.model}" if self.model else "无model"
            has_agent = f"agent={self.agent}" if self.agent else "无agent"
            self._log("INFO",
                f"开始发送任务到 OpenCode: Prompt={prompt_kb:.1f}KB, {has_system}, {has_tools}, {has_agent}, {has_model}, 超时={self.timeout}s",
                tag=tag)
            if workspace_dir:
                self._log("INFO", f"OpenCode HTTP 上下文目录: {workspace_dir}", tag=tag)

            self._log("INFO",
                f"发给 OpenCode 的完整请求体:\n{json.dumps(message_payload, ensure_ascii=False, indent=2)}",
                tag=tag)

            if self._prefer_async_sse:
                text = self._execute_prompt_async_with_sse(
                    session_id=session_id,
                    message_payload=message_payload,
                    effective_prompt=effective_prompt,
                    workspace_dir=workspace_dir,
                    tag=tag,
                )
                if text is not None:
                    return text

            return self._execute_message_sync(
                session_id=session_id,
                message_payload=message_payload,
                effective_prompt=effective_prompt,
                workspace_dir=workspace_dir,
                tag=tag,
            )

        except urllib.error.HTTPError as e:
            self._last_error_message = f"HTTP 错误: {e.code} {e.reason}"
            self._log("ERROR", f"HTTP 错误: {e.code} {e.reason}", tag=tag)
            try:
                error_body = e.read().decode("utf-8")
                self._log("ERROR", f"错误详情: {error_body[:200]}", tag=tag)
            except Exception:
                pass
            return ""
        except urllib.error.URLError as e:
            self._last_error_message = f"无法连接 OpenCode API ({self.api_base}): {e.reason}"
            self._log("ERROR",
                f"无法连接 OpenCode API ({self.api_base}): {e.reason}",
                tag=tag)
            return ""
        except TimeoutError:
            self._last_error_message = f"请求超时 ({self.timeout}s)"
            self._log("ERROR", f"请求超时 ({self.timeout}s)", tag=tag)
            raise TimeoutError(f"Agent 请求超时 ({self.timeout}s)")

    def _execute_message_sync(self,
                              session_id: str,
                              message_payload: dict,
                              effective_prompt: str,
                              workspace_dir: Optional[str] = None,
                              tag: str = "") -> str:
        """保留原有同步 message 调用路径，作为回退方案。"""
        t0 = time.time()
        data = json.dumps(message_payload).encode("utf-8")
        req = urllib.request.Request(
            self._session_prompt_url(self.api_base, session_id, "message", workspace_dir),
            data=data,
            headers={"Content-Type": "application/json"},
            method="POST"
        )
        with urllib.request.urlopen(req, timeout=self.timeout) as response:
            result_data = response.read().decode("utf-8")
            elapsed = time.time() - t0
            result = self._parse_message_response(result_data, session_id, effective_prompt, tag)
            message_id = self._extract_message_id(result)
            message_info = self._fetch_message_info(session_id, message_id) if message_id else None
            payload = message_info or result
            parts = payload.get("parts", []) if isinstance(payload, dict) else []
            self._last_interaction_metrics = self._build_interaction_metrics(
                source="agent_runner",
                session_id=session_id,
                message_id=message_id,
                prompt_text=effective_prompt,
                response=result,
                message_info=message_info,
                api_elapsed_ms=round(elapsed * 1000),
            )
            text = self._extract_best_text(parts, effective_prompt)
            if text:
                self._last_interaction_metrics["message"]["output_chars"] = len(text)
                self._log("INFO",
                    f"收到响应: {len(text)}字符, 耗时={elapsed:.1f}s",
                    tag=tag)
                return text
            self._log("WARN",
                f"响应中无 text 部分, parts数={len(parts)}, 耗时={elapsed:.1f}s",
                tag=tag)
            return ""

    def _execute_prompt_async_with_sse(self,
                                       session_id: str,
                                       message_payload: dict,
                                       effective_prompt: str,
                                       workspace_dir: Optional[str],
                                       tag: str = "") -> Optional[str]:
        """用 prompt_async 触发任务，并将 SSE 事件原样写入本地文件。"""
        sse_log_path = self._resolve_sse_log_path(workspace_dir)
        progress_log_path = self._resolve_sse_progress_log_path(sse_log_path) if sse_log_path else None
        stop_event = threading.Event()
        connected_event = threading.Event()
        sse_thread = None
        if sse_log_path:
            os.makedirs(os.path.dirname(sse_log_path), exist_ok=True)
            open(sse_log_path, "a", encoding="utf-8").close()
            if progress_log_path:
                open(progress_log_path, "a", encoding="utf-8").close()
            sse_thread = threading.Thread(
                target=self._capture_sse_events,
                args=(session_id, sse_log_path, stop_event, connected_event, tag),
                daemon=True,
            )
            sse_thread.start()
            connected_event.wait(timeout=5)

        t0 = time.time()
        try:
            data = json.dumps(message_payload).encode("utf-8")
            req = urllib.request.Request(
                self._session_prompt_url(self.api_base, session_id, "prompt_async", workspace_dir),
                data=data,
                headers={"Content-Type": "application/json"},
                method="POST"
            )
            with urllib.request.urlopen(req, timeout=30) as response:
                response.read()
            self._log("WARNING", f"任务已发送，等待 Agent 与大模型返回结果；SSE 事件写入: {sse_log_path or '未启用'}", tag=tag)

            payload = self._wait_for_completed_message(session_id, effective_prompt, tag=tag)
            if not payload:
                raise TimeoutError("OpenCode prompt_async 未在超时内返回完整消息")

            assistant_messages = self._fetch_assistant_messages(session_id, effective_prompt)
            if sse_log_path:
                self._backfill_sse_logs_from_messages(
                    all_messages=assistant_messages,
                    output_path=sse_log_path,
                    mapped_path=progress_log_path,
                )
            message_id = self._extract_message_id(payload)
            message_info = self._fetch_message_info(session_id, message_id) if message_id else None
            final_payload = message_info or payload
            parts = final_payload.get("parts", []) if isinstance(final_payload, dict) else []
            elapsed = time.time() - t0
            self._last_interaction_metrics = self._build_interaction_metrics(
                source="agent_runner",
                session_id=session_id,
                message_id=message_id,
                prompt_text=effective_prompt,
                response=payload,
                message_info=message_info,
                all_messages=assistant_messages,
                api_elapsed_ms=round(elapsed * 1000),
            )
            text = self._extract_best_text(parts, effective_prompt)
            if text:
                self._last_interaction_metrics["message"]["output_chars"] = len(text)
                self._log("INFO",
                    f"收到响应: {len(text)}字符, 耗时={elapsed:.1f}s (prompt_async+sse)",
                    tag=tag)
                return text
            self._log("WARN",
                f"prompt_async 响应中无 text 部分, parts数={len(parts)}, 耗时={elapsed:.1f}s",
                tag=tag)
            return ""
        except Exception as exc:
            self._log("WARN", f"prompt_async + SSE 失败，回退同步 message：{exc}", tag=tag)
            return None
        finally:
            stop_event.set()
            if sse_thread:
                sse_thread.join(timeout=2)

    def _wait_for_completed_message(self, session_id: str, prompt_text: str, tag: str = "") -> Optional[dict]:
        deadline = time.time() + self.timeout
        last_seen = None
        while time.time() < deadline:
            payload = self._fetch_latest_message(session_id, prompt_text)
            if payload:
                last_seen = payload
                parts = payload.get("parts") if isinstance(payload.get("parts"), list) else []
                self._emit_runtime_progress_from_parts(parts, tag=tag)
                has_text = bool(self._extract_best_text(parts, prompt_text))
                has_step_finish = any(
                    isinstance(part, dict) and str(part.get("type", "")).lower() == "step-finish"
                    for part in parts
                )
                info = payload.get("info") if isinstance(payload.get("info"), dict) else {}
                finish_reason = str(info.get("finish") or "").strip().lower()
                if has_text and has_step_finish and finish_reason not in {"", "tool-calls"}:
                    return payload
            time.sleep(1)
        if last_seen:
            self._log("WARN", "等待完整 step-finish 超时，返回最近一次 assistant 消息", tag=tag)
        return last_seen

    def _resolve_sse_log_path(self, workspace_dir: Optional[str]) -> Optional[str]:
        if not workspace_dir:
            return None
        normalized_dir = workspace_dir.rstrip(os.sep)
        if os.path.isdir(os.path.join(normalized_dir, "workspace")) or os.path.isdir(os.path.join(normalized_dir, "original")):
            case_dir = normalized_dir
        else:
            case_dir = os.path.dirname(normalized_dir)
        if self.artifact_base_dir == "constraint":
            target_dir = review_dir(case_dir)
        elif self.artifact_base_dir == "static":
            target_dir = static_dir(case_dir)
        else:
            target_dir = agent_meta_dir(case_dir)
        os.makedirs(target_dir, exist_ok=True)
        return os.path.join(target_dir, f"{self.artifact_prefix}_opencode_sse_events.jsonl")

    def _resolve_sse_progress_log_path(self, output_path: str) -> str:
        base_dir = os.path.dirname(output_path)
        return os.path.join(base_dir, f"{self.artifact_prefix}_opencode_progress_events.jsonl")

    def _capture_sse_events(self, session_id: str, output_path: str, stop_event: threading.Event, connected_event: threading.Event, tag: str = ""):
        self._log("WARNING", f"开始监听 OpenCode SSE 事件流: {output_path}", tag=tag)
        progress_output_path = self._resolve_sse_progress_log_path(output_path)
        while not stop_event.is_set():
            try:
                connected = False
                last_error = None
                for endpoint in ("/event", "/global/event"):
                    try:
                        req = urllib.request.Request(f"{self.api_base}{endpoint}", method="GET")
                        with urllib.request.urlopen(req, timeout=10) as response:
                            connected = True
                            connected_event.set()
                            event_name = None
                            data_lines = []
                            while not stop_event.is_set():
                                raw_line = response.readline()
                                if not raw_line:
                                    break
                                line = raw_line.decode("utf-8", errors="replace").rstrip("\r\n")
                                if line.startswith("event:"):
                                    event_name = line[6:].strip()
                                elif line.startswith("data:"):
                                    data_lines.append(line[5:].lstrip())
                                elif line == "":
                                    payload = self._parse_sse_event_payload(event_name, data_lines)
                                    if payload is not None and self._event_matches_session(payload, session_id):
                                        self._append_jsonl(output_path, payload, progress_output_path)
                                        self._emit_runtime_progress_log(payload, tag=tag)
                                    event_name = None
                                    data_lines = []
                        if connected:
                            break
                    except Exception as exc:
                        last_error = exc
                        continue
                if not connected and last_error is not None:
                    raise last_error
                time.sleep(0.5)
            except Exception as exc:
                if stop_event.is_set():
                    break
                self._append_jsonl(output_path, {
                    "timestamp": time.strftime("%Y-%m-%dT%H:%M:%S"),
                    "event": "sse.error",
                    "data": {"error": str(exc)},
                }, progress_output_path)
                time.sleep(1)

    def _parse_sse_event_payload(self, event_name: Optional[str], data_lines: list[str]) -> Optional[dict]:
        if not event_name and not data_lines:
            return None
        raw_data = "\n".join(data_lines).strip()
        parsed_data = raw_data
        if raw_data:
            try:
                parsed_data = json.loads(raw_data)
            except Exception:
                parsed_data = raw_data
        return {
            "timestamp": time.strftime("%Y-%m-%dT%H:%M:%S"),
            "event": event_name or "message",
            "data": parsed_data,
        }

    @staticmethod
    def _clip_large_text(value: str, limit: int = 240) -> str:
        text = str(value or "")
        if len(text) <= limit:
            return text
        return text[:limit] + "..."

    def _shrink_raw_sse_payload(self, payload: dict) -> dict:
        try:
            compact = json.loads(json.dumps(payload, ensure_ascii=False))
        except Exception:
            return payload

        data = compact.get("data")
        if isinstance(data, dict):
            data.pop("directory", None)
            nested = data.get("payload")
            if isinstance(nested, dict):
                props = nested.get("properties")
                if isinstance(props, dict):
                    info = props.get("info")
                    if isinstance(info, dict):
                        path_info = info.get("path")
                        if isinstance(path_info, dict):
                            path_info.pop("cwd", None)
                            path_info.pop("root", None)
                        info.pop("directory", None)

                    part = props.get("part")
                    if isinstance(part, dict):
                        state = part.get("state")
                        if isinstance(state, dict):
                            state_input = state.get("input")
                            if isinstance(state_input, dict):
                                for key in ("prompt", "oldString", "newString", "command", "cmd"):
                                    if key in state_input:
                                        state_input[key] = self._clip_large_text(state_input.get(key), 240)
                                for key in ("filePath", "path"):
                                    if key in state_input and state_input.get(key):
                                        state_input[key] = self._short_workspace_path(state_input.get(key))

                            if "output" in state:
                                state["output"] = self._clip_large_text(state.get("output"), 320)

                            metadata = state.get("metadata")
                            if isinstance(metadata, dict):
                                if "diff" in metadata:
                                    metadata["diff"] = self._clip_large_text(metadata.get("diff"), 240)
                                filediff = metadata.get("filediff")
                                if isinstance(filediff, dict):
                                    for key in ("before", "after"):
                                        if key in filediff:
                                            filediff[key] = self._clip_large_text(filediff.get(key), 180)
                                    if "file" in filediff and filediff.get("file"):
                                        filediff["file"] = self._short_workspace_path(filediff.get("file"))

                        if "text" in part:
                            part["text"] = self._clip_large_text(part.get("text"), 320)
                        if "files" in part and isinstance(part.get("files"), list):
                            part["files"] = [self._short_workspace_path(x) for x in part.get("files", [])[:5]]

        serialized = json.dumps(compact, ensure_ascii=False)
        if len(serialized) <= MAX_RAW_SSE_LINE_CHARS:
            return compact

        data = compact.get("data")
        if isinstance(data, dict):
            nested = data.get("payload")
            if isinstance(nested, dict):
                props = nested.get("properties")
                if isinstance(props, dict):
                    part = props.get("part")
                    if isinstance(part, dict):
                        state = part.get("state")
                        if isinstance(state, dict):
                            if "output" in state:
                                state["output"] = self._clip_large_text(state.get("output"), 120)
                            state_input = state.get("input")
                            if isinstance(state_input, dict):
                                for key in ("prompt", "oldString", "newString", "command", "cmd"):
                                    if key in state_input:
                                        state_input[key] = self._clip_large_text(state_input.get(key), 120)
                            metadata = state.get("metadata")
                            if isinstance(metadata, dict):
                                metadata.pop("filediff", None)
                                if "diff" in metadata:
                                    metadata["diff"] = self._clip_large_text(metadata.get("diff"), 120)
                        if "text" in part:
                            part["text"] = self._clip_large_text(part.get("text"), 160)

        serialized = json.dumps(compact, ensure_ascii=False)
        if len(serialized) <= MAX_RAW_SSE_LINE_CHARS:
            return compact

        event_data = self._extract_sse_event_data(compact)
        if isinstance(event_data, dict):
            event_type = str(event_data.get("type") or "").strip()
            props = event_data.get("properties") if isinstance(event_data.get("properties"), dict) else {}
            part = props.get("part") if isinstance(props.get("part"), dict) else {}
            simplified = {
                "timestamp": compact.get("timestamp"),
                "event": compact.get("event"),
                "data": {
                    "payload": {
                        "type": event_type,
                        "properties": {
                            "sessionID": props.get("sessionID"),
                        },
                    },
                },
            }
            simple_props = simplified["data"]["payload"]["properties"]
            if part:
                simple_part = {
                    "type": part.get("type"),
                }
                if part.get("tool"):
                    simple_part["tool"] = part.get("tool")
                state = part.get("state") if isinstance(part.get("state"), dict) else {}
                if state.get("status"):
                    simple_part["status"] = state.get("status")
                if part.get("text"):
                    simple_part["text"] = self._clip_large_text(part.get("text"), 120)
                simple_props["part"] = simple_part
            return simplified
        return compact

    @staticmethod
    def _extract_sse_event_data(payload: dict):
        data = payload.get("data")
        if not isinstance(data, dict):
            return data
        nested_payload = data.get("payload")
        if isinstance(nested_payload, dict):
            return nested_payload
        return data

    def _should_store_raw_sse_payload(self, payload: dict) -> bool:
        data = self._extract_sse_event_data(payload)
        if not isinstance(data, dict):
            return True
        event_type = str(data.get("type") or "").strip()
        if event_type == "message.part.delta":
            return False
        return True

    def _filter_sse_payload(self, payload: dict) -> Optional[dict]:
        data = self._extract_sse_event_data(payload)
        if not isinstance(data, dict):
            return None
        event_type = str(data.get("type") or "").strip()
        if event_type != "message.part.updated":
            return None
        props = data.get("properties") if isinstance(data.get("properties"), dict) else {}
        part = props.get("part") if isinstance(props.get("part"), dict) else {}
        part_type = str(part.get("type") or "").strip()
        if part_type not in {"step-start", "reasoning", "tool", "patch", "text", "step-finish"}:
            return None
        return payload

    def _map_sse_payload(self, payload: dict) -> Optional[dict]:
        filtered = self._filter_sse_payload(payload)
        if not filtered:
            return None
        data = self._extract_sse_event_data(filtered) or {}
        props = data.get("properties") if isinstance(data.get("properties"), dict) else {}
        part = props.get("part") if isinstance(props.get("part"), dict) else {}
        part_type = str(part.get("type") or "").strip()

        mapped = {
            "timestamp": filtered.get("timestamp"),
            "eventType": "",
            "label": "",
            "message": "",
        }
        if part_type == "step-start":
            mapped["eventType"] = "step_start"
            mapped["label"] = "开始新一轮处理"
            mapped["message"] = "开始新一轮处理"
        elif part_type == "reasoning":
            mapped["eventType"] = "reasoning"
            mapped["label"] = "模型分析问题"
            text = str(part.get("text") or "").strip()
            mapped["message"] = (text[:100] + "...") if len(text) > 100 else text
        elif part_type == "tool":
            state = part.get("state") if isinstance(part.get("state"), dict) else {}
            status = str(state.get("status") or "").strip()
            mapped["eventType"] = "tool_result" if status == "completed" else "tool_call"
            mapped["label"] = "工具执行完成" if status == "completed" else "调用工具"
            tool_name = str(part.get("tool") or "").strip()
            state_input = state.get("input") if isinstance(state.get("input"), dict) else {}
            file_path = self._short_workspace_path(state_input.get("filePath") or state_input.get("path") or "")
            if tool_name == "task":
                description = str(state_input.get("description") or "").strip()
                subagent_type = str(state_input.get("subagent_type") or "").strip()
                if description and subagent_type:
                    mapped["message"] = f"{description} (@{subagent_type}) ({status or 'pending'})"
                elif description:
                    mapped["message"] = f"{description} ({status or 'pending'})"
                else:
                    mapped["message"] = f"{tool_name} ({status or 'pending'})"
            elif tool_name == "read" and file_path:
                mapped["message"] = f"read {file_path} ({status or 'pending'})"
            elif tool_name == "glob":
                pattern = str(state_input.get("pattern") or "").strip()
                if pattern:
                    mapped["message"] = f"glob {pattern} ({status or 'pending'})"
                else:
                    mapped["message"] = f"{tool_name} ({status or 'pending'})"
            elif tool_name == "edit" and file_path:
                mapped["message"] = f"edit {file_path} ({status or 'pending'})"
            elif tool_name == "bash":
                raw_cmd = str(state_input.get("command") or state_input.get("cmd") or "").strip()
                cmd_preview = self._clip_text_for_log(raw_cmd, 80)
                mapped["message"] = f"bash {cmd_preview} ({status or 'pending'})" if cmd_preview else f"{tool_name} ({status})"
            elif status:
                mapped["message"] = f"{tool_name} ({status})"
            else:
                mapped["message"] = tool_name
        elif part_type == "patch":
            mapped["eventType"] = "patch"
            mapped["label"] = "生成代码补丁"
            files = part.get("files")
            if isinstance(files, list):
                joined = ", ".join(self._short_workspace_path(str(x)) for x in files[:3])
                mapped["message"] = joined
        elif part_type == "text":
            mapped["eventType"] = "text"
            mapped["label"] = "模型输出结果"
            text = str(part.get("text") or "").strip()
            mapped["message"] = self._clip_text_for_log(text, 160)
        elif part_type == "step-finish":
            mapped["eventType"] = "step_finish"
            mapped["label"] = "本轮处理结束"
            reason = str(part.get("reason") or "").strip()
            mapped["message"] = reason or "stop"
        else:
            return None
        return mapped

    def _event_matches_session(self, payload: dict, session_id: str) -> bool:
        data = self._extract_sse_event_data(payload)
        if not session_id:
            return True
        if isinstance(data, (dict, list)):
            serialized = json.dumps(data, ensure_ascii=False)
            return session_id in serialized
        return session_id in str(data)

    def _append_jsonl(self, path: str, payload: dict, mapped_path: Optional[str] = None):
        if self._should_store_raw_sse_payload(payload):
            os.makedirs(os.path.dirname(path), exist_ok=True)
            raw_payload = self._shrink_raw_sse_payload(payload)
            with open(path, "a", encoding="utf-8") as f:
                f.write(json.dumps(raw_payload, ensure_ascii=False) + "\n")
        mapped = self._map_sse_payload(payload)
        if mapped and mapped_path:
            os.makedirs(os.path.dirname(mapped_path), exist_ok=True)
            with open(mapped_path, "a", encoding="utf-8") as f:
                f.write(json.dumps(mapped, ensure_ascii=False) + "\n")

    @staticmethod
    def _make_synthetic_sse_payload(part: dict) -> Optional[dict]:
        if not isinstance(part, dict):
            return None
        return {
            "timestamp": time.strftime("%Y-%m-%dT%H:%M:%S"),
            "event": "message",
            "data": {
                "payload": {
                    "type": "message.part.updated",
                    "properties": {
                        "part": part,
                    },
                },
            },
        }

    def _emit_runtime_progress_from_parts(self, parts: list, tag: str = ""):
        for part in parts or []:
            payload = self._make_synthetic_sse_payload(part)
            if payload:
                self._emit_runtime_progress_log(payload, tag=tag)

    def _backfill_sse_logs_from_messages(self, all_messages: list, output_path: str, mapped_path: Optional[str] = None):
        try:
            if os.path.exists(output_path) and os.path.getsize(output_path) > 0:
                return
        except Exception:
            return

        wrote_any = False
        for message in all_messages or []:
            if not isinstance(message, dict):
                continue
            parts = message.get("parts")
            if not isinstance(parts, list):
                continue
            for part in parts:
                payload = self._make_synthetic_sse_payload(part)
                if not payload:
                    continue
                self._append_jsonl(output_path, payload, mapped_path)
                wrote_any = True
        if wrote_any:
            self._log("INFO", f"[OpenCode] 原始 SSE 缺失，已根据消息历史回填: {output_path}")

    def _emit_runtime_progress_log(self, payload: dict, tag: str = ""):
        mapped = self._map_sse_payload(payload)
        if not mapped:
            return
        event_type = str(mapped.get("eventType") or "")
        message = str(mapped.get("message") or "").strip()
        event_data = self._extract_sse_event_data(payload)
        props = event_data.get("properties") if isinstance(event_data, dict) and isinstance(event_data.get("properties"), dict) else {}
        part = props.get("part") if isinstance(props.get("part"), dict) else {}
        part_type = str(part.get("type") or "").strip()
        part_tool = str(part.get("tool") or "").strip()
        part_status = ""
        state = part.get("state") if isinstance(part.get("state"), dict) else {}
        if isinstance(state, dict):
            part_status = str(state.get("status") or "").strip()
        event_identity = (
            str(props.get("messageID") or props.get("messageId") or ""),
            str(props.get("partID") or props.get("partId") or ""),
            part_type,
            part_tool,
            part_status,
            message,
        )
        signature = None
        log_message = None
        level = "INFO"

        if event_type == "step_start":
            signature = ("step_start",) + event_identity
            log_message = "OpenCode 已收到任务，开始执行"
        elif event_type == "reasoning":
            signature = ("reasoning",) + event_identity
            log_message = "OpenCode 模型开始思考"
        elif event_type == "tool_call":
            lowered = message.lower()
            tool_name = lowered.split(" ", 1)[0]
            if tool_name.startswith("task"):
                signature = ("tool_call",) + event_identity
                log_message = f"OpenCode 启动子任务: {message}" if message else "OpenCode 启动子任务"
            elif tool_name.startswith("glob") or tool_name.startswith("read") or tool_name.startswith("bash"):
                signature = ("tool_call",) + event_identity
                log_message = f"OpenCode 开始检查工程和读取文件: {message}" if message else "OpenCode 开始检查工程和读取文件"
            elif tool_name.startswith("edit") or tool_name.startswith("write"):
                signature = ("tool_call",) + event_identity
                log_message = f"OpenCode 开始修改代码: {message}" if message else "OpenCode 开始修改代码"
            else:
                signature = ("tool_call",) + event_identity
                log_message = f"OpenCode 开始调用工具: {message}"
        elif event_type == "tool_result":
            lowered = message.lower()
            tool_name = lowered.split(" ", 1)[0]
            signature = ("tool_result",) + event_identity
            if tool_name.startswith("task"):
                log_message = f"OpenCode 子任务完成: {message}" if message else "OpenCode 子任务完成"
            elif tool_name.startswith("bash") and any(token in lowered for token in ("hvigor", "assemblehap", "stop-daemon")):
                log_message = f"OpenCode 编译命令执行完成: {message}"
            elif tool_name.startswith("edit"):
                log_message = f"OpenCode 代码修改完成: {message}"
            elif tool_name.startswith("read") or tool_name.startswith("glob"):
                log_message = f"OpenCode 文件检查完成: {message}"
            else:
                log_message = f"OpenCode 工具执行完成: {message}" if message else "OpenCode 工具执行完成"
        elif event_type == "patch":
            signature = ("patch",) + event_identity
            log_message = f"OpenCode 已生成代码补丁: {message}" if message else "OpenCode 已生成代码补丁"
        elif event_type == "text":
            signature = ("text",) + event_identity
            log_message = f"OpenCode 开始输出结果: {message}" if message else "OpenCode 开始输出结果"
        elif event_type == "step_finish":
            if (message or "").strip().lower() == "other":
                return
            signature = ("step_finish",) + event_identity
            log_message = f"OpenCode 本轮执行结束: {message}" if message else "OpenCode 本轮执行结束"

        if not signature or not log_message:
            return
        if signature in self._seen_runtime_events:
            return
        self._seen_runtime_events.add(signature)
        self._log(level, log_message, tag=tag)

    def _extract_message_id(self, payload: dict) -> Optional[str]:
        if not isinstance(payload, dict):
            return None
        info = payload.get("info") if isinstance(payload.get("info"), dict) else {}
        return payload.get("id") or info.get("id") or payload.get("messageID") or payload.get("messageId")

    def _parse_message_response(self, result_data: str, session_id: str, prompt_text: str, tag: str = "") -> dict:
        body = result_data.strip()
        if body:
            try:
                data = json.loads(body)
                candidate = self._coerce_message_payload(data, prompt_text)
                if candidate:
                    return candidate
                preview = body[:400].replace("\n", "\\n")
                self._log("WARN", f"消息响应不是可信 assistant 结果，类型={type(data).__name__}，body前400字符={preview}，尝试回查 session 最新消息", tag=tag)
            except json.JSONDecodeError as e:
                preview = body[:200].replace("\n", "\\n")
                self._log("WARN", f"消息响应不是 JSON: {e}; body前200字符={preview}", tag=tag)
        else:
            self._log("WARN", "消息响应体为空，尝试回查 session 最新消息", tag=tag)

        latest = self._fetch_latest_message(session_id, prompt_text)
        if latest:
            self._log("DEBUG", "已回查到 session 最新消息", tag=tag)
            return latest
        raise ValueError("OpenCode message 响应为空或非 JSON，且无法回查最新消息")

    def _fetch_message_info(self, session_id: str, message_id: str) -> Optional[dict]:
        try:
            req = urllib.request.Request(
                f"{self.api_base}/session/{session_id}/message/{message_id}",
                method="GET"
            )
            with urllib.request.urlopen(req, timeout=10) as response:
                data = json.loads(response.read().decode("utf-8"))
                return self._coerce_message_payload(data, "") or data
        except Exception as e:
            self._log("DEBUG", f"读取消息详情失败: {e}")
            return None

    def _fetch_latest_message(self, session_id: str, prompt_text: str) -> Optional[dict]:
        try:
            req = urllib.request.Request(
                f"{self.api_base}/session/{session_id}/message",
                method="GET"
            )
            with urllib.request.urlopen(req, timeout=10) as response:
                data = json.loads(response.read().decode("utf-8"))
            direct = self._coerce_message_payload(data, prompt_text)
            if direct and self._has_effective_assistant_progress(direct):
                return direct
            messages = []
            if isinstance(data, list):
                messages = data
            elif isinstance(data, dict):
                messages = self._extract_message_list(data)
                if not messages:
                    return None

            for message in reversed(messages):
                candidate = self._coerce_message_payload(message, prompt_text)
                if candidate and self._has_effective_assistant_progress(candidate):
                    return candidate
            return None
        except Exception as e:
            self._log("DEBUG", f"回查 session 最新消息失败: {e}")
            return None

    def _fetch_assistant_messages(self, session_id: str, prompt_text: str) -> list[dict]:
        try:
            req = urllib.request.Request(
                f"{self.api_base}/session/{session_id}/message",
                method="GET"
            )
            with urllib.request.urlopen(req, timeout=10) as response:
                data = json.loads(response.read().decode("utf-8"))
            messages = []
            if isinstance(data, list):
                messages = data
            elif isinstance(data, dict):
                messages = self._extract_message_list(data)
            result = []
            for message in messages:
                candidate = self._coerce_message_payload(message, prompt_text)
                if candidate and self._has_effective_assistant_progress(candidate):
                    result.append(candidate)
            return result
        except Exception as e:
            self._log("DEBUG", f"读取 session 全量消息失败: {e}")
            return []

    def _coerce_message_payload(self, data, prompt_text: str) -> Optional[dict]:
        for candidate in self._iter_message_candidates(data):
            if self._looks_like_assistant_message(candidate, prompt_text):
                return candidate
        return None

    def _iter_message_candidates(self, data):
        seen = set()
        stack = [data]
        while stack:
            current = stack.pop()
            if not isinstance(current, dict):
                continue
            ident = id(current)
            if ident in seen:
                continue
            seen.add(ident)
            yield current
            for key in ("message", "item", "result", "data", "payload"):
                nested = current.get(key)
                if isinstance(nested, dict):
                    stack.append(nested)
            for key in ("messages", "items", "results"):
                nested_list = current.get(key)
                if isinstance(nested_list, list):
                    for item in nested_list:
                        if isinstance(item, dict):
                            stack.append(item)

    def _extract_message_list(self, data):
        if isinstance(data, list):
            return [item for item in data if isinstance(item, dict)]
        if not isinstance(data, dict):
            return []
        for key in ("messages", "items", "results"):
            nested = data.get(key)
            if isinstance(nested, list):
                return [item for item in nested if isinstance(item, dict)]
        for key in ("data", "payload", "result"):
            nested = data.get(key)
            if isinstance(nested, list):
                return [item for item in nested if isinstance(item, dict)]
            if isinstance(nested, dict):
                extracted = self._extract_message_list(nested)
                if extracted:
                    return extracted
        return []

    def _looks_like_assistant_message(self, payload: dict, prompt_text: str) -> bool:
        if not isinstance(payload, dict):
            return False
        info = payload.get("info") if isinstance(payload.get("info"), dict) else {}
        message_type = str(payload.get("type", "") or info.get("type", "")).lower()
        role = str(payload.get("role", "") or info.get("role", "")).lower()
        if role and role != "assistant":
            return False
        if message_type and message_type not in ("assistant", "message"):
            return False

        parts = payload.get("parts")
        if not isinstance(parts, list) or not parts:
            return False
        meaningful_parts = []
        texts = []
        for part in parts:
            if not isinstance(part, dict):
                continue
            part_type = str(part.get("type") or "").strip().lower()
            if not part_type:
                continue
            meaningful_parts.append(part_type)
            if part_type == "text":
                text = str(part.get("text", "")).strip()
                if text:
                    texts.append(text)

        if not meaningful_parts:
            return False

        if texts:
            merged = "\n".join(texts).strip()
            prompt_norm = (prompt_text or "").strip()
            if merged and prompt_norm and (merged == prompt_norm or merged in prompt_norm):
                return False
        return True

    def _extract_best_text(self, parts: list, prompt_text: str) -> str:
        prompt_norm = (prompt_text or "").strip()
        text_parts = []
        for part in parts or []:
            if not isinstance(part, dict):
                continue
            if str(part.get("type", "")).lower() != "text":
                continue
            text = str(part.get("text", "")).strip()
            if not text:
                continue
            if prompt_norm and (text == prompt_norm or text in prompt_norm):
                continue
            text_parts.append(text)
        if not text_parts:
            return ""
        return text_parts[-1]

    def _has_effective_assistant_progress(self, payload: dict) -> bool:
        if not isinstance(payload, dict):
            return False
        parts = payload.get("parts")
        if not isinstance(parts, list) or not parts:
            return False

        has_non_placeholder_part = False
        has_meaningful_finish = False
        for part in parts:
            if not isinstance(part, dict):
                continue
            part_type = str(part.get("type") or "").strip().lower()
            if not part_type:
                continue
            if part_type not in {"step-start", "step-finish"}:
                has_non_placeholder_part = True
                break
            if part_type == "step-finish":
                reason = str(part.get("reason") or "").strip().lower()
                if reason not in {"", "other"}:
                    has_meaningful_finish = True
        return has_non_placeholder_part or has_meaningful_finish

    def _build_interaction_metrics(self,
                                   source: str,
                                   session_id: str,
                                   message_id: Optional[str],
                                   prompt_text: str,
                                   response: dict,
                                   message_info: Optional[dict],
                                   api_elapsed_ms: int,
                                   all_messages: Optional[list] = None) -> dict:
        payload = message_info or response or {}
        history = [item for item in (all_messages or []) if isinstance(item, dict)]
        if history:
            latest_payload = history[-1]
            latest_info = latest_payload.get("info") if isinstance(latest_payload.get("info"), dict) else {}
            aggregated_parts = []
            for item in history:
                parts_obj = item.get("parts")
                if isinstance(parts_obj, list):
                    aggregated_parts.extend(parts_obj)
            payload = dict(latest_payload)
            payload["parts"] = aggregated_parts
            payload["info"] = dict(latest_info)
        info = payload.get("info") if isinstance(payload.get("info"), dict) else {}
        model = payload.get("model") if isinstance(payload.get("model"), dict) else {}
        provider = payload.get("provider") if isinstance(payload.get("provider"), dict) else {}
        tokens = payload.get("tokens") if isinstance(payload.get("tokens"), dict) else {}
        time_info = payload.get("time") if isinstance(payload.get("time"), dict) else {}
        if not model:
            model = info.get("model") if isinstance(info.get("model"), dict) else {}
        if not provider:
            provider = info.get("provider") if isinstance(info.get("provider"), dict) else {}
        if not tokens:
            tokens = info.get("tokens") if isinstance(info.get("tokens"), dict) else {}
        if not time_info:
            time_info = info.get("time") if isinstance(info.get("time"), dict) else {}
        parts = payload.get("parts") if isinstance(payload.get("parts"), list) else response.get("parts", [])

        created = self._coerce_int(time_info.get("created"))
        completed = self._coerce_int(time_info.get("completed"))
        model_elapsed_ms = completed - created if created is not None and completed is not None else api_elapsed_ms

        return {
            "version": 1,
            "source": source,
            "adapter": "opencode",
            "session_id": session_id,
            "message_id": message_id,
            "provider_id": provider.get("id") or provider.get("providerID") or info.get("providerID") or model.get("providerID") or payload.get("providerID"),
            "model_id": model.get("id") or model.get("modelID") or info.get("modelID") or payload.get("modelID"),
            "timing": {
                "api_elapsed_ms": api_elapsed_ms,
                "model_elapsed_ms": model_elapsed_ms,
            },
            "usage": {
                "input_tokens": self._coerce_int(tokens.get("input") or tokens.get("inputTokens") or tokens.get("prompt")),
                "output_tokens": self._coerce_int(tokens.get("output") or tokens.get("outputTokens") or tokens.get("completion")),
                "reasoning_tokens": self._coerce_int(tokens.get("reasoning") or tokens.get("reasoningTokens")),
                "cache_read_tokens": self._coerce_int(self._pick_nested(tokens, ("cache", "read")) or tokens.get("cacheRead") or tokens.get("cache_read")),
                "cache_write_tokens": self._coerce_int(self._pick_nested(tokens, ("cache", "write")) or tokens.get("cacheWrite") or tokens.get("cache_write")),
                "cost": payload.get("cost", info.get("cost")),
            },
            "message": {
                "input_chars": len(prompt_text or ""),
                "output_chars": 0,
            },
            "tools": {
                "available": self._tools_config,
                "observed_calls": self._extract_observed_tool_calls(parts),
            },
            "raw": {
                "response": response,
                "message_info": payload,
                "message_history": history,
            },
        }

    def _extract_observed_tool_calls(self, parts):
        observed = []
        for part in parts or []:
            if not isinstance(part, dict):
                continue
            part_type = str(part.get("type", "")).lower()
            tool_name = part.get("tool") or part.get("toolName") or part.get("name") or self._pick_nested(part, ("call", "tool")) or self._pick_nested(part, ("call", "name"))
            if tool_name or "tool" in part_type:
                observed.append({
                    "type": part.get("type"),
                    "name": tool_name,
                })
        return observed

    def _pick_nested(self, data, path):
        cur = data
        for key in path:
            if not isinstance(cur, dict):
                return None
            cur = cur.get(key)
        return cur

    def _coerce_int(self, value):
        if value is None:
            return None
        try:
            return int(value)
        except Exception:
            return None

    def _create_session(self) -> Optional[str]:
        """创建新 session，返回 session_id"""
        try:
            req = urllib.request.Request(
                f"{self.api_base}/session",
                data=json.dumps({}).encode("utf-8"),
                headers={"Content-Type": "application/json"},
                method="POST"
            )
            with urllib.request.urlopen(req, timeout=10) as response:
                session = json.loads(response.read().decode("utf-8"))
                return session.get("id")
        except Exception as e:
            self._last_error_message = f"创建 Session 异常: {e}"
            self._log("ERROR", f"创建 Session 异常: {e}")
            return None

    # ── teardown ─────────────────────────────────────────────

    def teardown(self):
        """清理增强配置"""
        # 清理内存状态
        self._system_message = ""
        self._tools_config = None

        # MCP Server 目前 OpenCode API 没有删除接口，
        # 记录日志，后续如果有 DELETE /mcp/:name 再补充
        if self._registered_mcps:
            self._log("DEBUG",
                f"已注册的 MCP Servers: {self._registered_mcps} (全局生效，无法按次清理)")
            self._registered_mcps = []

    def get_last_interaction_metrics(self):
        return self._last_interaction_metrics

    def get_last_error_message(self):
        return self._last_error_message
