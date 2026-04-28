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

from agent_bench.pipeline.artifacts import agent_meta_dir
from agent_bench.agent_runner.adapter import AgentAdapter
from agent_bench.agent_runner.auto_reply import OpenCodeQuestionAutoReply
from agent_bench.agent_runner.agent_runtime_state import AgentRuntimeState
from agent_bench.agent_runner.communicate import OpenCodeHttpClient, OpenCodeSseClient
from agent_bench.common.default_constants import DEFAULT_TIMEOUT_SECONDS

DEFAULT_API_BASE = "http://localhost:4096"
TIMEOUT = DEFAULT_TIMEOUT_SECONDS
SESSION_CREATE_TIMEOUT_SECONDS = 60
MAX_RAW_SSE_LINE_CHARS = 2000
DELTA_PROGRESS_THROTTLE_SECONDS = 10.0
VALID_SSE_FILTERS = {"full", "medium", "low"}
MEDIUM_PATCH_LIMIT_CHARS = 100
LOW_FULL_EVENT_TYPES = {"message.part.updated", "message.updated", "session.status", "session.idle", "session.updated", "question.asked"}
LOW_RAW_EVENT_TYPES = {"message.part.updated", "session.status", "session.idle", "question.asked"}
LOW_PART_TYPES = {"step-start", "reasoning", "tool", "patch", "text", "step-finish"}


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
                 sse_filter: str = "medium",
                 on_progress=None,
                 artifact_prefix: str = "agent",
                 artifact_base_dir: str = "generate"):
        self.api_base = api_base
        self.agent = agent
        self.model = model
        self.target_skills = [str(item).strip() for item in (target_skills or []) if str(item).strip()]
        self.timeout = timeout
        self.sse_filter = self._normalize_sse_filter(sse_filter)
        self.on_progress = on_progress
        self.artifact_prefix = artifact_prefix or "agent"
        self.artifact_base_dir = artifact_base_dir or "generate"
        self._http_client = OpenCodeHttpClient(self.api_base)
        self._sse_client = OpenCodeSseClient(self.api_base)

        # setup 阶段准备的配置
        self._system_message = ""
        self._tools_config = None
        self._registered_mcps = []  # 记录注册的 MCP server 名称，用于 teardown
        self._last_interaction_metrics = None
        self._last_error_message = ""
        self._prefer_async_sse = True
        self._seen_runtime_events = set()
        self._last_delta_progress_at = 0.0
        self._last_delta_progress_text = ""
        self._last_non_delta_progress_at = 0.0
        self._agent_runtime_state = AgentRuntimeState()
        self._last_local_log_at = time.monotonic()
        self._current_workspace_dir = ""
        self._idle_sessions = set()
        self._question_auto_reply = OpenCodeQuestionAutoReply(
            http_client=self._http_client,
            log_func=self._log,
            activity_func=self._mark_runtime_activity,
        )

    def _log(self, level: str, message: str, tag: str = ""):
        self._last_local_log_at = time.monotonic()
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
    def _clip_text_with_total_limit(value: str, limit: int) -> str:
        text = str(value or "")
        if len(text) <= limit:
            return text
        if limit <= 3:
            return text[: max(limit, 0)]
        return text[: limit - 3] + "..."

    def _compact_medium_sse_payload(self, payload: dict) -> dict:
        try:
            compact = json.loads(json.dumps(payload, ensure_ascii=False))
        except Exception:
            return payload

        compact = self._apply_medium_common_sse_fields(compact)
        data = compact.get("data")
        if isinstance(data, dict):
            data.pop("directory", None)
        compact = self._prune_medium_sse_event_fields(compact)
        self._prune_medium_sse_node(compact)
        return compact

    @staticmethod
    def _apply_medium_common_sse_fields(payload: dict) -> dict:
        if not isinstance(payload, dict):
            return payload
        payload.pop("event", None)
        data = payload.get("data")
        if isinstance(data, dict):
            data.pop("project", None)
        return payload

    @staticmethod
    def _prune_medium_sse_event_fields(payload: dict) -> dict:
        if not isinstance(payload, dict):
            return payload
        data = payload.get("data")
        if not isinstance(data, dict):
            return payload
        nested = data.get("payload")
        if not isinstance(nested, dict):
            return payload
        nested.pop("id", None)
        nested.pop("aggregateID", None)
        nested.pop("aggregateId", None)
        props = nested.get("properties")
        if not isinstance(props, dict):
            props = nested.get("data")
        if isinstance(props, dict):
            props.pop("time", None)
            props.pop("sessionID", None)
            props.pop("sessionId", None)

            part = props.get("part")
            if isinstance(part, dict):
                part.pop("id", None)
                part.pop("messageID", None)
                part.pop("messageId", None)
                part.pop("sessionID", None)
                part.pop("sessionId", None)
                part.pop("time", None)
        return payload

    def _prune_medium_sse_node(self, value):
        if isinstance(value, dict):
            for key in ("sessionID", "sessionId", "messageID", "messageId", "partID", "partId"):
                value.pop(key, None)
            for key, item in list(value.items()):
                if key == "patch":
                    value[key] = self._clip_text_with_total_limit(item, MEDIUM_PATCH_LIMIT_CHARS)
                    continue
                self._prune_medium_sse_node(item)
            return
        if isinstance(value, list):
            for item in value:
                self._prune_medium_sse_node(item)

    def _build_low_sse_payload(self, payload: dict) -> dict:
        if not isinstance(payload, dict):
            return payload
        if str(payload.get("event") or "").strip() == "sse.error":
            return {
                "timestamp": payload.get("timestamp"),
                "event": "sse.error",
                "data": {
                    "error": self._clip_large_text(
                        (payload.get("data") or {}).get("error") if isinstance(payload.get("data"), dict) else "",
                        240,
                    ),
                },
            }

        event_data = self._extract_sse_event_data(payload)
        if not isinstance(event_data, dict):
            return {
                "timestamp": payload.get("timestamp"),
                "data": event_data,
            }

        event_type = str(event_data.get("type") or "").strip()
        simplified = {
            "timestamp": payload.get("timestamp"),
            "data": {
                "payload": {
                    "type": event_type,
                },
            },
        }
        props = event_data.get("properties") if isinstance(event_data.get("properties"), dict) else {}
        simple_props = {}

        if event_type == "message.part.updated":
            part = props.get("part") if isinstance(props.get("part"), dict) else {}
            simple_part = {}
            part_type = str(part.get("type") or "").strip()
            if part_type:
                simple_part["type"] = part_type
            if part.get("tool"):
                simple_part["tool"] = part.get("tool")
            if part.get("reason"):
                simple_part["reason"] = part.get("reason")
            if part.get("text"):
                simple_part["text"] = self._clip_large_text(part.get("text"), 160)
            files = part.get("files")
            if isinstance(files, list) and files:
                simple_part["files"] = [self._short_workspace_path(str(item)) for item in files[:3]]
            state = part.get("state") if isinstance(part.get("state"), dict) else {}
            if state:
                simple_state = {}
                if state.get("status"):
                    simple_state["status"] = state.get("status")
                state_input = state.get("input") if isinstance(state.get("input"), dict) else {}
                if state_input:
                    simple_input = {}
                    if state_input.get("description"):
                        simple_input["description"] = self._clip_large_text(state_input.get("description"), 120)
                    if state_input.get("filePath") or state_input.get("path"):
                        simple_input["path"] = self._short_workspace_path(state_input.get("filePath") or state_input.get("path"))
                    if state_input.get("command") or state_input.get("cmd"):
                        simple_input["cmd"] = self._clip_large_text(state_input.get("command") or state_input.get("cmd"), 120)
                    if simple_input:
                        simple_state["input"] = simple_input
                if simple_state:
                    simple_part["state"] = simple_state
            if simple_part:
                simple_props["part"] = simple_part
        elif event_type == "message.updated":
            for key in ("finish", "error"):
                if props.get(key):
                    simple_props[key] = props.get(key)
        elif event_type == "session.status":
            for key in ("status", "state"):
                if props.get(key):
                    simple_props[key] = props.get(key)
        elif event_type == "session.updated":
            for key in ("title", "status"):
                if props.get(key):
                    simple_props[key] = props.get(key)

        if simple_props:
            simplified["data"]["payload"]["properties"] = simple_props
        return simplified

    def _build_full_sse_payload(self, payload: dict) -> dict:
        if self.sse_filter == "medium":
            return self._compact_medium_sse_payload(payload)
        if self.sse_filter == "low":
            return self._build_low_sse_payload(payload)
        return payload

    def _get_sse_event_type(self, payload: dict) -> str:
        data = self._extract_sse_event_data(payload)
        if not isinstance(data, dict):
            return ""
        return str(data.get("type") or "").strip()

    @staticmethod
    def _normalize_sse_filter(value: Optional[str]) -> str:
        normalized = str(value or "medium").strip().lower()
        if normalized in VALID_SSE_FILTERS:
            return normalized
        return "medium"

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

    def setup(self, runtime_options: dict, on_progress=None):
        """配置运行时能力

        Args:
            runtime_options: 运行时配置
        """
        if on_progress:
            self.on_progress = on_progress

        self._system_message = ""
        self._tools_config = None
        self._registered_mcps = []
        self._last_interaction_metrics = None
        self._last_error_message = ""
        self._seen_runtime_events = set()
        self._idle_sessions = set()
        self._agent_runtime_state.reset()
        self._question_auto_reply.reset()
        self.sse_filter = self._normalize_sse_filter(self.sse_filter)

        if not runtime_options:
            self._log("DEBUG", "无额外运行时配置")
            return

        system_prompt = runtime_options.get("system_prompt", "")
        if system_prompt:
            self._system_message = system_prompt.strip()
            self._log("INFO", f"已配置 System Prompt ({len(self._system_message)} 字符)")

        # 1. MCP Servers → 通过 API 注册
        mcp_servers = runtime_options.get("mcp_servers", [])
        for mcp in mcp_servers:
            self._register_mcp(mcp)

        # 2. Tools 开关
        tools = runtime_options.get("tools")
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

    # ── execute ──────────────────────────────────────────────

    def execute(self, prompt: str, tag: str = "", workspace_dir: Optional[str] = None) -> str:
        """创建 session，发送消息（携带 system/tools 配置），返回响应"""
        try:
            self._current_workspace_dir = str(workspace_dir or "").strip()
            self._last_interaction_metrics = None
            self._last_error_message = ""
            effective_prompt = prompt

            # 1. 创建 session
            self._log("INFO", "准备创建 OpenCode 会话...", tag=tag)
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
                f"发给 OpenCode 的完整请求体:\n{json.dumps(self._build_request_log_payload(message_payload), ensure_ascii=False, indent=2)}",
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
        result_data = self._http_client.send_message(
            session_id=session_id,
            payload=message_payload,
            workspace_dir=workspace_dir,
            timeout=self.timeout,
        )
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
            derived = self._last_interaction_metrics.get("derived") if isinstance(self._last_interaction_metrics, dict) else {}
            message_metrics = derived.get("message") if isinstance(derived, dict) else {}
            if isinstance(message_metrics, dict):
                message_metrics["output_chars"] = len(text)
            self._log("INFO",
                f"收到响应: {len(text)}字符, 耗时={elapsed:.1f}s",
                tag=tag)
            return text
        self._log("WARN",
            f"响应中无 text 部分, parts数={len(parts)}, 耗时={elapsed:.1f}s",
            tag=tag)
        return ""

    def _build_request_log_payload(self, payload: dict, input_text_limit: int = 1000) -> dict:
        """Return a log-safe copy of the OpenCode request payload.

        The actual request is sent unchanged. Only the user input part before
        the extra prompt marker is clipped, so execution requirements remain
        visible in logs.
        """
        try:
            log_payload = json.loads(json.dumps(payload, ensure_ascii=False))
        except Exception:
            return payload
        parts = log_payload.get("parts")
        if not isinstance(parts, list):
            return log_payload
        for part in parts:
            if not isinstance(part, dict):
                continue
            text = part.get("text")
            if not isinstance(text, str):
                continue
            part["text"] = self._clip_logged_input_text(text, input_text_limit)
        return log_payload

    def _clip_logged_input_text(self, text: str, input_text_limit: int = 1000) -> str:
        marker = "\n\n## 额外执行要求\n"
        if marker in text:
            input_text, suffix = text.split(marker, 1)
            if len(input_text) <= input_text_limit:
                return text
            clipped_input = input_text[:input_text_limit] + f"...[input已截断，原始长度={len(input_text)}]"
            return f"{clipped_input}{marker}{suffix}"
        if len(text) <= input_text_limit:
            return text
        return text[:input_text_limit] + f"...[input已截断，原始长度={len(text)}]"

    def _execute_prompt_async_with_sse(self,
                                       session_id: str,
                                       message_payload: dict,
                                       effective_prompt: str,
                                       workspace_dir: Optional[str],
                                       tag: str = "") -> Optional[str]:
        """用 prompt_async 触发任务，并将 SSE 事件原样写入本地文件。"""
        sse_log_path = self._resolve_sse_log_path(workspace_dir)
        progress_log_path = self._resolve_sse_progress_log_path(sse_log_path) if sse_log_path else None
        full_sse_log_path = self._resolve_sse_full_log_path(sse_log_path) if sse_log_path else None
        http_polling_log_path = self._resolve_http_polling_log_path(workspace_dir)
        stop_event = threading.Event()
        connected_event = threading.Event()
        sse_thread = None
        if sse_log_path:
            os.makedirs(os.path.dirname(sse_log_path), exist_ok=True)
            open(sse_log_path, "a", encoding="utf-8").close()
            if progress_log_path:
                open(progress_log_path, "a", encoding="utf-8").close()
            if full_sse_log_path:
                open(full_sse_log_path, "a", encoding="utf-8").close()
            if http_polling_log_path:
                open(http_polling_log_path, "a", encoding="utf-8").close()
            self._agent_runtime_state.reset(session_id)
            self._mark_runtime_activity()
            sse_thread = threading.Thread(
                target=self._capture_sse_events,
                args=(session_id, workspace_dir or "", sse_log_path, stop_event, connected_event, tag),
                daemon=True,
            )
            sse_thread.start()
            connected_event.wait(timeout=5)

        t0 = time.time()
        try:
            self._http_client.prompt_async(
                session_id=session_id,
                payload=message_payload,
                workspace_dir=workspace_dir,
                timeout=300,
            )
            self._log("WARNING", f"任务已发送，等待 Agent 与大模型返回结果；SSE 事件写入: {sse_log_path or '未启用'}", tag=tag)

            payload = self._wait_for_completed_message(
                session_id,
                effective_prompt,
                http_polling_log_path=http_polling_log_path,
                tag=tag,
            )
            if not payload:
                raise TimeoutError("OpenCode prompt_async 未在超时内返回完整消息")

            assistant_messages = self._fetch_assistant_messages(session_id, effective_prompt)
            # 不再把 message history 回填成伪 SSE。
            # 这样可以避免 agent_opencode_sse_full.jsonl / agent_opencode_sse_events.jsonl
            # 被“快照回填”污染，误导排障。
            #
            # if sse_log_path:
            #     self._backfill_sse_logs_from_messages(
            #         all_messages=assistant_messages,
            #         output_path=sse_log_path,
            #         mapped_path=progress_log_path,
            #         full_path=full_sse_log_path,
            #     )
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
                derived = self._last_interaction_metrics.get("derived") if isinstance(self._last_interaction_metrics, dict) else {}
                message_metrics = derived.get("message") if isinstance(derived, dict) else {}
                if isinstance(message_metrics, dict):
                    message_metrics["output_chars"] = len(text)
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

    def _wait_for_completed_message(self,
                                    session_id: str,
                                    prompt_text: str,
                                    http_polling_log_path: Optional[str] = None,
                                    tag: str = "") -> Optional[dict]:
        last_seen = None
        message_poll_interval = 2.0
        child_poll_interval = 10.0
        todo_poll_interval = 60.0
        last_message_poll_at = 0.0
        last_child_poll_at = 0.0
        last_todo_poll_at = 0.0
        same_message_poll_count = 0
        last_message_response_signature = ""
        last_message_heartbeat_log_at = 0.0
        same_child_poll_count = 0
        last_child_response_signature = ""
        last_todo_response_signatures: dict[str, str] = {}
        child_message_signatures: dict[str, str] = {}
        child_session_ids: set[str] = set()
        last_todo_payloads: dict[str, object] = {}
        completed_message_signature = ""
        completed_message_seen_count = 0
        if not self._agent_runtime_state.has_activity():
            self._mark_runtime_activity()
        while True:
            idle_seconds = self._agent_runtime_state.idle_seconds()
            if idle_seconds >= self.timeout:
                break
            now = time.monotonic()
            if now - last_message_poll_at >= message_poll_interval:
                last_message_poll_at = now
                payload, raw_message_data = self._fetch_latest_message_with_raw(
                    session_id,
                    prompt_text,
                )
                message_signature = self._build_http_message_response_signature(raw_message_data, payload, prompt_text)
                message_changed = bool(message_signature and message_signature != last_message_response_signature)
                if message_changed:
                    last_message_response_signature = message_signature
                    same_message_poll_count = 0
                    message_poll_interval = 2.0
                    self._append_http_polling_log(
                        http_polling_log_path,
                        "message",
                        session_id,
                        f"/session/{session_id}/message?limit=1",
                        raw_message_data,
                    )
                elif message_signature:
                    same_message_poll_count += 1
                    if same_message_poll_count >= 3:
                        message_poll_interval = 10.0
                if raw_message_data is not None and not message_changed:
                    if now - self._last_local_log_at >= 60 and now - last_message_heartbeat_log_at >= 60:
                        last_message_heartbeat_log_at = now
                        self._log(
                            "INFO",
                            "【轮询心跳】message 接口请求成功，最新消息暂未变化，任务仍在进行中",
                            tag=tag,
                        )
                if payload:
                    last_seen = payload
                    self._question_auto_reply.handle_message_payload(
                        payload,
                        session_id=session_id,
                        workspace_dir=self._current_workspace_dir or "",
                        tag=tag,
                    )
                    if message_changed:
                        self._mark_message_polling_progress(payload, prompt_text, session_id=session_id)
                        parts = payload.get("parts") if isinstance(payload.get("parts"), list) else []
                        self._emit_runtime_progress_from_parts(parts, tag=tag, source="session")
                    else:
                        parts = payload.get("parts") if isinstance(payload.get("parts"), list) else []
                    has_text = bool(self._extract_best_text(parts, prompt_text))
                    has_step_finish = any(
                        isinstance(part, dict) and str(part.get("type", "")).lower() == "step-finish"
                        for part in parts
                    )
                    info = payload.get("info") if isinstance(payload.get("info"), dict) else {}
                    finish_reason = str(info.get("finish") or "").strip().lower()
                    if has_step_finish and finish_reason not in {"", "tool-calls", "unknown"}:
                        completion_signature = self._build_http_message_response_signature(
                            raw_message_data,
                            payload,
                            prompt_text,
                        )
                        idle_confirmed = session_id in self._idle_sessions
                        latest_todo_payload = last_todo_payloads.get(session_id)
                        has_active_todo = self._todos_indicate_activity(latest_todo_payload) if latest_todo_payload is not None else False
                        if idle_confirmed and has_text:
                            return payload
                        if has_text and not has_active_todo:
                            if completion_signature and completion_signature == completed_message_signature:
                                completed_message_seen_count += 1
                            else:
                                completed_message_signature = completion_signature
                                completed_message_seen_count = 1
                            if completed_message_seen_count >= 2:
                                return payload
                        else:
                            completed_message_signature = ""
                            completed_message_seen_count = 0
                    else:
                        completed_message_signature = ""
                        completed_message_seen_count = 0

            if now - last_child_poll_at >= child_poll_interval:
                last_child_poll_at = now
                next_child_session_ids = self._fetch_child_session_ids(
                    session_id,
                    http_polling_log_path=http_polling_log_path,
                    tag=tag,
                )
                child_response_signature = json.dumps(sorted(next_child_session_ids), ensure_ascii=False)
                child_changed = child_response_signature != last_child_response_signature
                if child_changed:
                    last_child_response_signature = child_response_signature
                    same_child_poll_count = 0
                    child_poll_interval = 10.0
                    self._log(
                        "INFO",
                        f"【session】 OpenCode 子会话列表有变化: {self._summarize_child_sessions(next_child_session_ids)}",
                        tag=tag,
                    )
                else:
                    same_child_poll_count += 1
                    if same_child_poll_count >= 3:
                        child_poll_interval = 60.0
                child_session_ids = next_child_session_ids
                for child_session_id in sorted(child_session_ids):
                    child_payload, child_raw_message_data = self._fetch_latest_message_with_raw(
                        child_session_id,
                        prompt_text,
                    )
                    if child_payload:
                        self._question_auto_reply.handle_message_payload(
                            child_payload,
                            session_id=child_session_id,
                            workspace_dir=self._current_workspace_dir or "",
                            tag=tag,
                        )
                        child_signature = self._build_http_message_response_signature(
                            child_raw_message_data,
                            child_payload,
                            prompt_text,
                        )
                        if child_signature and child_signature != child_message_signatures.get(child_session_id, ""):
                            child_message_signatures[child_session_id] = child_signature
                            self._append_http_polling_log(
                                http_polling_log_path,
                                "message",
                                child_session_id,
                                f"/session/{child_session_id}/message?limit=1",
                                child_raw_message_data,
                            )
                            self._mark_message_polling_progress(child_payload, prompt_text, session_id=child_session_id)
                            child_parts = child_payload.get("parts") if isinstance(child_payload.get("parts"), list) else []
                            self._emit_runtime_progress_from_parts(child_parts, tag=tag, source="child-session")

            if now - last_todo_poll_at >= todo_poll_interval:
                last_todo_poll_at = now
                session_ids = [session_id] + sorted(child_session_ids)
                for target_session_id in session_ids:
                    todo_payload = self._fetch_session_todos(
                        target_session_id,
                        http_polling_log_path=http_polling_log_path,
                        tag=tag,
                    )
                    last_todo_payloads[target_session_id] = todo_payload
                    todo_signature = self._build_todo_response_signature(todo_payload)
                    if todo_signature and todo_signature != last_todo_response_signatures.get(target_session_id, ""):
                        last_todo_response_signatures[target_session_id] = todo_signature
                        self._log(
                            "INFO",
                            f"【TODO列表刷新】{self._summarize_todo_payload(todo_payload)}",
                            tag=tag,
                        )
            time.sleep(1)
        if last_seen:
            self._log("WARN", f"连续{self.timeout}s无 OpenCode SSE 活动，返回最近一次 assistant 消息", tag=tag)
        return last_seen

    def _fetch_child_session_ids(self,
                                 session_id: str,
                                 http_polling_log_path: Optional[str] = None,
                                 tag: str = "") -> set[str]:
        endpoint = f"/session/{session_id}/children"
        try:
            payload = self._http_client.list_children(session_id, timeout=10)
            self._append_http_polling_log(
                http_polling_log_path,
                "children",
                session_id,
                endpoint,
                payload,
            )
            return self._extract_session_ids(payload)
        except Exception as e:
            self._append_http_polling_log(
                http_polling_log_path,
                "children.error",
                session_id,
                endpoint,
                {"error": str(e)},
            )
            self._log("DEBUG", f"读取子 session 失败: {e}", tag=tag)
            return set()

    def _fetch_session_todos(self,
                             session_id: str,
                             http_polling_log_path: Optional[str] = None,
                             tag: str = ""):
        endpoint = f"/session/{session_id}/todo"
        try:
            payload = self._http_client.list_todos(session_id, timeout=10)
            self._append_http_polling_log(
                http_polling_log_path,
                "todo",
                session_id,
                endpoint,
                payload,
            )
            if self._todos_indicate_activity(payload):
                self._mark_runtime_activity(session_id=session_id)
            return payload
        except Exception as e:
            self._append_http_polling_log(
                http_polling_log_path,
                "todo.error",
                session_id,
                endpoint,
                {"error": str(e)},
            )
            self._log("DEBUG", f"读取 session todo 失败: {e}", tag=tag)
            return None

    def _extract_session_ids(self, payload) -> set[str]:
        result = set()

        def walk(value):
            if isinstance(value, dict):
                candidate = value.get("id") or value.get("sessionID") or value.get("sessionId")
                if candidate:
                    result.add(str(candidate))
                for item in value.values():
                    walk(item)
            elif isinstance(value, list):
                for item in value:
                    walk(item)

        walk(payload)
        return result

    def _todos_indicate_activity(self, payload) -> bool:
        active_statuses = {"pending", "in_progress", "in-progress", "running", "active", "doing", "todo"}

        def walk(value):
            if isinstance(value, dict):
                status = str(value.get("status") or value.get("state") or "").strip().lower()
                if status in active_statuses:
                    return True
                for item in value.values():
                    if walk(item):
                        return True
            elif isinstance(value, list):
                for item in value:
                    if walk(item):
                        return True
            return False

        return walk(payload)

    def _resolve_sse_log_path(self, workspace_dir: Optional[str]) -> Optional[str]:
        if not workspace_dir:
            return None
        normalized_dir = workspace_dir.rstrip(os.sep)
        if os.path.isdir(os.path.join(normalized_dir, "workspace")) or os.path.isdir(os.path.join(normalized_dir, "original")):
            case_dir = normalized_dir
        else:
            case_dir = os.path.dirname(normalized_dir)
        target_dir = agent_meta_dir(case_dir)
        os.makedirs(target_dir, exist_ok=True)
        return os.path.join(target_dir, f"{self.artifact_prefix}_opencode_sse_events.jsonl")

    def _resolve_sse_progress_log_path(self, output_path: str) -> str:
        base_dir = os.path.dirname(output_path)
        return os.path.join(base_dir, f"{self.artifact_prefix}_opencode_progress_events.jsonl")

    def _resolve_sse_full_log_path(self, output_path: str) -> str:
        base_dir = os.path.dirname(output_path)
        return os.path.join(base_dir, f"{self.artifact_prefix}_opencode_sse_full.jsonl")

    def _resolve_http_polling_log_path(self, workspace_dir: Optional[str]) -> Optional[str]:
        if self.artifact_base_dir != "generate" or not workspace_dir:
            return None
        normalized_dir = workspace_dir.rstrip(os.sep)
        if os.path.isdir(os.path.join(normalized_dir, "workspace")) or os.path.isdir(os.path.join(normalized_dir, "original")):
            case_dir = normalized_dir
        else:
            case_dir = os.path.dirname(normalized_dir)
        target_dir = agent_meta_dir(case_dir)
        os.makedirs(target_dir, exist_ok=True)
        return os.path.join(target_dir, f"{self.artifact_prefix}_opencode_http_polling.jsonl")

    def _append_http_polling_log(self,
                                 path: Optional[str],
                                 kind: str,
                                 session_id: str,
                                 endpoint: str,
                                 payload):
        if not path:
            return
        row = {
            "timestamp": time.strftime("%Y-%m-%dT%H:%M:%S"),
            "kind": kind,
            "sessionID": session_id,
            "endpoint": endpoint,
            "data": payload,
        }
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, "a", encoding="utf-8") as f:
            f.write(json.dumps(row, ensure_ascii=False) + "\n")

    def _mark_session_idle_from_sse(self, payload: dict, session_id: str):
        data = self._extract_sse_event_data(payload)
        if not isinstance(data, dict) or not session_id:
            return
        event_type = str(data.get("type") or "").strip().lower()
        props = data.get("properties") if isinstance(data.get("properties"), dict) else {}
        if event_type == "session.idle":
            self._idle_sessions.add(session_id)
            return
        if event_type == "session.status":
            status = str(props.get("status") or props.get("state") or "").strip().lower()
            if status == "idle":
                self._idle_sessions.add(session_id)

    def _should_write_full_sse_payload(self, payload: dict) -> bool:
        if self.sse_filter != "low":
            return self.sse_filter in VALID_SSE_FILTERS
        if str(payload.get("event") or "").strip() == "sse.error":
            return True
        event_type = self._get_sse_event_type(payload)
        return event_type in LOW_FULL_EVENT_TYPES

    def _capture_sse_events(self,
                            session_id: str,
                            workspace_dir: str,
                            output_path: str,
                            stop_event: threading.Event,
                            connected_event: threading.Event,
                            tag: str = ""):
        self._log("WARNING", f"开始监听 OpenCode SSE 事件流: {output_path}", tag=tag)
        progress_output_path = self._resolve_sse_progress_log_path(output_path)
        full_output_path = self._resolve_sse_full_log_path(output_path)

        def handle_payload(payload: dict):
            self._question_auto_reply.handle_sse_payload(
                payload,
                session_id=session_id,
                workspace_dir=workspace_dir,
                tag=tag,
            )
            self._mark_session_idle_from_sse(payload, session_id)
            # 每个任务独立启动一条 SSE 监听，但 full 文件只保留当前 session
            # 的完整原始事件，避免混入其他任务的事件后误导超时判断。
            if not self._event_matches_session(payload, session_id):
                return
            if full_output_path and self._should_write_full_sse_payload(payload):
                full_payload = self._build_full_sse_payload(payload)
                os.makedirs(os.path.dirname(full_output_path), exist_ok=True)
                with open(full_output_path, "a", encoding="utf-8") as f:
                    f.write(json.dumps(full_payload, ensure_ascii=False) + "\n")
            self._mark_runtime_activity(session_id=session_id)
            self._append_jsonl(output_path, payload, progress_output_path, None)
            self._emit_runtime_progress_log(payload, tag=tag, source="sse")

        def handle_error(exc: Exception):
            self._append_jsonl(output_path, {
                "timestamp": time.strftime("%Y-%m-%dT%H:%M:%S"),
                "event": "sse.error",
                "data": {"error": str(exc)},
            }, progress_output_path, full_output_path)

        self._sse_client.capture_events(
            stop_event=stop_event,
            connected_event=connected_event,
            parse_payload=self._parse_sse_event_payload,
            handle_payload=handle_payload,
            handle_error=handle_error,
            timeout=10,
            retry_delay=1,
        )

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
        if self.sse_filter == "low":
            return self._build_low_sse_payload(payload)

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
            if self.sse_filter == "medium":
                compact = self._apply_medium_common_sse_fields(compact)
                compact = self._prune_medium_sse_event_fields(compact)
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
            if self.sse_filter == "medium":
                compact = self._apply_medium_common_sse_fields(compact)
                compact = self._prune_medium_sse_event_fields(compact)
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
            if self.sse_filter == "medium":
                simplified = self._apply_medium_common_sse_fields(simplified)
                simplified = self._prune_medium_sse_event_fields(simplified)
            return simplified
        if self.sse_filter == "medium":
            compact = self._apply_medium_common_sse_fields(compact)
            compact = self._prune_medium_sse_event_fields(compact)
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
        if self.sse_filter == "low":
            event_type = self._get_sse_event_type(payload)
            if event_type == "message.part.updated":
                data = self._extract_sse_event_data(payload)
                props = data.get("properties") if isinstance(data, dict) and isinstance(data.get("properties"), dict) else {}
                part = props.get("part") if isinstance(props.get("part"), dict) else {}
                part_type = str(part.get("type") or "").strip()
                return part_type in LOW_PART_TYPES
            return event_type in LOW_RAW_EVENT_TYPES

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

    @staticmethod
    def _summarize_delta_progress_text(text: str, limit: int = 50) -> str:
        normalized = " ".join(str(text or "").strip().split())
        if not normalized:
            return ""
        if len(normalized) <= limit:
            return normalized
        return normalized[:limit] + "..."

    def _event_matches_session(self, payload: dict, session_id: str) -> bool:
        data = self._extract_sse_event_data(payload)
        if not session_id:
            return True
        if isinstance(data, (dict, list)):
            serialized = json.dumps(data, ensure_ascii=False)
            return session_id in serialized
        return session_id in str(data)

    def _append_jsonl(self,
                      path: str,
                      payload: dict,
                      mapped_path: Optional[str] = None,
                      full_path: Optional[str] = None):
        if full_path:
            os.makedirs(os.path.dirname(full_path), exist_ok=True)
            with open(full_path, "a", encoding="utf-8") as f:
                f.write(json.dumps(payload, ensure_ascii=False) + "\n")
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

    def _emit_runtime_progress_from_parts(self, parts: list, tag: str = "", source: str = "session"):
        for part in parts or []:
            payload = self._make_synthetic_sse_payload(part)
            if payload:
                self._emit_runtime_progress_log(payload, tag=tag, source=source)

    def _mark_runtime_activity(self, session_id: str = ""):
        # 只要当前 session 还有真实进展，运行态就应被刷新。
        # 这既包括 SSE 事件，也包括 HTTP message 轮询发现的新进展。
        self._agent_runtime_state.mark_activity(session_id=session_id)

    def _mark_message_polling_progress(self, payload: dict, prompt_text: str, session_id: str = "") -> bool:
        signature = self._build_message_progress_signature(payload, prompt_text)
        return self._agent_runtime_state.mark_message_progress(signature, session_id=session_id)

    @staticmethod
    def _short_session_id(session_id: str) -> str:
        text = str(session_id or "").strip()
        if len(text) <= 16:
            return text
        return text[:16] + "..."

    def _summarize_child_sessions(self, child_session_ids: set[str]) -> str:
        if not child_session_ids:
            return "无子会话"
        ordered = [self._short_session_id(item) for item in sorted(child_session_ids)[:5]]
        suffix = "" if len(child_session_ids) <= 5 else " ..."
        return f"{len(child_session_ids)}个: {', '.join(ordered)}{suffix}"

    def _build_todo_response_signature(self, payload) -> str:
        if payload is None:
            return ""
        try:
            return json.dumps(payload, ensure_ascii=False, sort_keys=True)
        except Exception:
            return str(payload)

    def _summarize_todo_payload(self, payload) -> str:
        if not payload:
            return "无 todo"
        items = []
        if isinstance(payload, list):
            items = payload
        elif isinstance(payload, dict):
            for key in ("items", "todos", "data", "result"):
                value = payload.get(key)
                if isinstance(value, list):
                    items = value
                    break
        summary_parts = []
        for item in items[:5]:
            if not isinstance(item, dict):
                continue
            content = self._clip_large_text(str(item.get("content") or item.get("title") or "").strip(), 36)
            status = str(item.get("status") or item.get("state") or "").strip().lower()
            if content or status:
                summary_parts.append(f"{status or 'unknown'}:{content or '-'}")
        if not summary_parts:
            return self._clip_large_text(str(payload), 80)
        suffix = "" if len(items) <= 5 else " ..."
        return "; ".join(summary_parts) + suffix

    def _build_http_message_response_signature(self, raw_data, payload: Optional[dict], prompt_text: str) -> str:
        candidate = payload if isinstance(payload, dict) else self._coerce_message_payload(raw_data, prompt_text)
        if isinstance(candidate, dict):
            progress_signature = self._build_message_progress_signature(candidate, prompt_text)
            if progress_signature:
                return progress_signature
            info = candidate.get("info") if isinstance(candidate.get("info"), dict) else {}
            parts = candidate.get("parts") if isinstance(candidate.get("parts"), list) else []
            summary = {
                "message_id": self._extract_message_id(candidate) or "",
                "finish": str(info.get("finish") or ""),
                "created": info.get("time", {}).get("created") if isinstance(info.get("time"), dict) else "",
                "completed": info.get("time", {}).get("completed") if isinstance(info.get("time"), dict) else "",
                "part_count": len(parts),
            }
            return json.dumps(summary, ensure_ascii=False, sort_keys=True)
        try:
            return json.dumps(raw_data, ensure_ascii=False, sort_keys=True)
        except Exception:
            return str(raw_data or "")

    def _build_message_progress_signature(self, payload: dict, prompt_text: str) -> str:
        if not isinstance(payload, dict):
            return ""
        parts = payload.get("parts")
        if not isinstance(parts, list) or not parts:
            return ""
        info = payload.get("info") if isinstance(payload.get("info"), dict) else {}
        summary = {
            "message_id": self._extract_message_id(payload) or "",
            "finish": str(info.get("finish") or ""),
            "parts": [],
        }
        prompt_norm = (prompt_text or "").strip()
        for part in parts:
            if not isinstance(part, dict):
                continue
            part_type = str(part.get("type") or "").strip().lower()
            if not part_type:
                continue
            part_summary = {"type": part_type}
            if part_type == "text":
                text = str(part.get("text") or "").strip()
                if text and not (prompt_norm and (text == prompt_norm or text in prompt_norm)):
                    part_summary["text"] = self._clip_large_text(text, 80)
            elif part_type == "reasoning":
                part_summary["text"] = self._clip_large_text(str(part.get("text") or "").strip(), 80)
            elif part_type == "tool":
                part_summary["tool"] = str(part.get("tool") or "").strip()
                state = part.get("state") if isinstance(part.get("state"), dict) else {}
                if state.get("status"):
                    part_summary["status"] = str(state.get("status") or "").strip()
                state_input = state.get("input") if isinstance(state.get("input"), dict) else {}
                if state_input:
                    if state_input.get("filePath") or state_input.get("path"):
                        part_summary["path"] = self._short_workspace_path(state_input.get("filePath") or state_input.get("path"))
                    elif state_input.get("pattern"):
                        part_summary["pattern"] = self._clip_large_text(state_input.get("pattern"), 80)
                    elif state_input.get("command") or state_input.get("cmd"):
                        part_summary["cmd"] = self._clip_large_text(state_input.get("command") or state_input.get("cmd"), 80)
                    elif state_input.get("description"):
                        part_summary["description"] = self._clip_large_text(state_input.get("description"), 80)
            elif part_type == "patch":
                files = part.get("files")
                if isinstance(files, list) and files:
                    part_summary["files"] = [self._short_workspace_path(str(item)) for item in files[:3]]
            elif part_type == "step-finish":
                part_summary["reason"] = str(part.get("reason") or "").strip()
            summary["parts"].append(part_summary)
        if not summary["parts"]:
            return ""
        return json.dumps(summary, ensure_ascii=False, sort_keys=True)

    def _backfill_sse_logs_from_messages(self,
                                        all_messages: list,
                                        output_path: str,
                                        mapped_path: Optional[str] = None,
                                        full_path: Optional[str] = None):
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
                self._append_jsonl(output_path, payload, mapped_path, full_path)
                wrote_any = True
        if wrote_any:
            self._log("INFO", f"[OpenCode] 原始 SSE 缺失，已根据消息历史回填: {output_path}")

    @staticmethod
    def _runtime_progress_source_prefix(source: str) -> str:
        if str(source or "").strip().lower() == "session":
            return "【session】"
        return "【sse】"

    def _emit_runtime_progress_log(self, payload: dict, tag: str = "", source: str = "sse"):
        source_prefix = self._runtime_progress_source_prefix(source)
        raw_data = self._extract_sse_event_data(payload)
        raw_event_type = str(raw_data.get("type") or "").strip() if isinstance(raw_data, dict) else ""
        if raw_event_type == "message.part.delta":
            props = raw_data.get("properties") if isinstance(raw_data.get("properties"), dict) else {}
            delta = str(props.get("delta") or "").strip()
            summary = self._summarize_delta_progress_text(delta, 50)
            now = time.time()
            last_progress_at = max(self._last_non_delta_progress_at, self._last_delta_progress_at)
            if summary and (now - last_progress_at) >= DELTA_PROGRESS_THROTTLE_SECONDS:
                self._last_delta_progress_text = summary
                self._last_delta_progress_at = now
                self._log("INFO", f"{source_prefix} OpenCode 当前模型还在输出Delta：{summary}", tag=tag)
            return

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
            log_message = f"{source_prefix} OpenCode 已收到任务，开始执行"
        elif event_type == "reasoning":
            signature = ("reasoning",) + event_identity
            reasoning_summary = self._clip_large_text(" ".join(str(message or "").strip().split()), 60)
            log_message = (
                f"{source_prefix} OpenCode 模型正在思考: {reasoning_summary}"
                if reasoning_summary
                else f"{source_prefix} OpenCode 模型正在思考"
            )
        elif event_type == "tool_call":
            lowered = message.lower()
            tool_name = lowered.split(" ", 1)[0]
            if tool_name.startswith("task"):
                signature = ("tool_call",) + event_identity
                log_message = f"{source_prefix} OpenCode 启动子任务: {message}" if message else f"{source_prefix} OpenCode 启动子任务"
            elif tool_name.startswith("glob") or tool_name.startswith("read") or tool_name.startswith("bash"):
                signature = ("tool_call",) + event_identity
                log_message = f"{source_prefix} OpenCode 开始检查工程和读取文件: {message}" if message else f"{source_prefix} OpenCode 开始检查工程和读取文件"
            elif tool_name.startswith("edit") or tool_name.startswith("write"):
                signature = ("tool_call",) + event_identity
                log_message = f"{source_prefix} OpenCode 开始修改代码: {message}" if message else f"{source_prefix} OpenCode 开始修改代码"
            else:
                signature = ("tool_call",) + event_identity
                log_message = f"{source_prefix} OpenCode 开始调用工具: {message}"
        elif event_type == "tool_result":
            lowered = message.lower()
            tool_name = lowered.split(" ", 1)[0]
            signature = ("tool_result",) + event_identity
            if tool_name.startswith("task"):
                log_message = f"{source_prefix} OpenCode 子任务完成: {message}" if message else f"{source_prefix} OpenCode 子任务完成"
            elif tool_name.startswith("bash") and any(token in lowered for token in ("hvigor", "assemblehap", "stop-daemon")):
                log_message = f"{source_prefix} OpenCode 编译命令执行完成: {message}"
            elif tool_name.startswith("edit"):
                log_message = f"{source_prefix} OpenCode 代码修改完成: {message}"
            elif tool_name.startswith("read") or tool_name.startswith("glob"):
                log_message = f"{source_prefix} OpenCode 文件检查完成: {message}"
            else:
                log_message = f"{source_prefix} OpenCode 工具执行完成: {message}" if message else f"{source_prefix} OpenCode 工具执行完成"
        elif event_type == "patch":
            signature = ("patch",) + event_identity
            log_message = f"{source_prefix} OpenCode 已生成代码补丁: {message}" if message else f"{source_prefix} OpenCode 已生成代码补丁"
        elif event_type == "text":
            signature = ("text",) + event_identity
            log_message = f"{source_prefix} OpenCode 开始输出结果: {message}" if message else f"{source_prefix} OpenCode 开始输出结果"
        elif event_type == "step_finish":
            if (message or "").strip().lower() == "other":
                return
            signature = ("step_finish",) + event_identity
            log_message = f"{source_prefix} OpenCode 本轮执行结束: {message}" if message else f"{source_prefix} OpenCode 本轮执行结束"

        if not signature or not log_message:
            return
        if signature in self._seen_runtime_events:
            return
        self._seen_runtime_events.add(signature)
        # 只有真正形成了一条新的运行时日志，才认为出现了“非 delta 活动”。
        # 否则轮询 latest message 时回放的重复 reasoning/tool/text 事件，会把
        # _last_non_delta_progress_at 每秒刷新一次，导致 delta 的 10 秒节流窗口永远到不了。
        self._last_non_delta_progress_at = time.time()
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
            data = self._http_client.get_message(session_id, message_id, timeout=10)
            return self._coerce_message_payload(data, "") or data
        except Exception as e:
            self._log("DEBUG", f"读取消息详情失败: {e}")
            return None

    def _fetch_latest_message(self,
                              session_id: str,
                              prompt_text: str,
                              http_polling_log_path: Optional[str] = None) -> Optional[dict]:
        payload, raw_data = self._fetch_latest_message_with_raw(session_id, prompt_text)
        if raw_data is not None:
            self._append_http_polling_log(
                http_polling_log_path,
                "message",
                session_id,
                f"/session/{session_id}/message?limit=1",
                raw_data,
            )
        return payload

    def _fetch_latest_message_with_raw(self,
                                       session_id: str,
                                       prompt_text: str):
        try:
            data = self._http_client.list_messages(session_id, limit=1, timeout=10)
            direct = self._coerce_message_payload(data, prompt_text)
            if direct and self._has_effective_assistant_progress(direct):
                return direct, data
            messages = []
            if isinstance(data, list):
                messages = data
            elif isinstance(data, dict):
                messages = self._extract_message_list(data)
                if not messages:
                    return None, data

            for message in reversed(messages):
                candidate = self._coerce_message_payload(message, prompt_text)
                if candidate and self._has_effective_assistant_progress(candidate):
                    return candidate, data
            return None, data
        except Exception as e:
            self._log("DEBUG", f"回查 session 最新消息失败: {e}")
            return None, None

    def _fetch_assistant_messages(self, session_id: str, prompt_text: str) -> list[dict]:
        try:
            data = self._http_client.list_messages(session_id, timeout=10)
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

        # 求和所有消息的 token（而非只取最后一条消息）
        total_input = 0
        total_output = 0
        total_reasoning = 0
        total_cache_read = 0
        total_cache_write = 0
        for item in history:
            item_info = item.get("info") if isinstance(item.get("info"), dict) else {}
            item_tokens = item_info.get("tokens") if isinstance(item_info.get("tokens"), dict) else {}
            if item_tokens:
                total_input += int(item_tokens.get("input", 0) or 0)
                total_output += int(item_tokens.get("output", 0) or 0)
                total_reasoning += int(item_tokens.get("reasoning", 0) or 0)
                item_cache = item_tokens.get("cache") if isinstance(item_tokens.get("cache"), dict) else {}
                total_cache_read += int(item_cache.get("read", 0) or 0)
                total_cache_write += int(item_cache.get("write", 0) or 0)

        created = self._coerce_int(time_info.get("created"))
        completed = self._coerce_int(time_info.get("completed"))
        model_elapsed_ms = completed - created if created is not None and completed is not None else api_elapsed_ms

        return {
            "version": 2,
            "http": {
                "session_id": session_id,
                "message_id": message_id,
                "provider_id": provider.get("id") or provider.get("providerID") or info.get("providerID") or model.get("providerID") or payload.get("providerID"),
                "model_id": model.get("id") or model.get("modelID") or info.get("modelID") or payload.get("modelID"),
                "response": response,
                "message_info": payload,
                "message_history": history,
            },
            "derived": {
                "source": source,
                "timing": {
                    "api_elapsed_ms": api_elapsed_ms,
                    "model_elapsed_ms": model_elapsed_ms,
                },
                "usage": {
                    "input_tokens": total_input or self._coerce_int(tokens.get("input") or tokens.get("inputTokens") or tokens.get("prompt")),
                    "output_tokens": total_output or self._coerce_int(tokens.get("output") or tokens.get("outputTokens") or tokens.get("completion")),
                    "reasoning_tokens": total_reasoning or self._coerce_int(tokens.get("reasoning") or tokens.get("reasoningTokens")),
                    "cache_read_tokens": total_cache_read or self._coerce_int(self._pick_nested(tokens, ("cache", "read")) or tokens.get("cacheRead") or tokens.get("cache_read")),
                    "cache_write_tokens": total_cache_write or self._coerce_int(self._pick_nested(tokens, ("cache", "write")) or tokens.get("cacheWrite") or tokens.get("cache_write")),
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
            # 首次实例拉起会触发 plugin 加载，10 秒在云测上容易被提前超时。
            session = self._http_client.create_session(timeout=SESSION_CREATE_TIMEOUT_SECONDS)
            return session.get("id") if isinstance(session, dict) else None
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
