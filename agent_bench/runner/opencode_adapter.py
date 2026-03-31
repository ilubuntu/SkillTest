# -*- coding: utf-8 -*-
"""OpenCode Agent 适配器

通过 OpenCode Server HTTP API 实现 AgentAdapter 接口。

增强工具映射：
- system_prompt → message payload 的 system 字段
- skills        → skill 内容拼入 system 字段（作为参考指令）
- mcp_servers   → POST /mcp 动态注册
- tools         → message payload 的 tools 字段

OpenCode API 参考：https://opencode.ai/docs/zh-cn/server/
"""

import json
import sys
import time
import urllib.request
import urllib.error
from typing import Optional

from agent_bench.runner.adapter import AgentAdapter

DEFAULT_API_BASE = "http://localhost:4096"
TIMEOUT = 480


def parse_model(model_str: str) -> dict:
    """解析模型字符串为 API 格式

    Args:
        model_str: 如 "minimax/MiniMax-M2.7" 或 "MiniMax-M2.7"

    Returns:
        {"providerID": "...", "modelID": "..."}
    """
    if "/" in model_str:
        provider, model_id = model_str.split("/", 1)
        provider_map = {
            "minimax": "minimax-cn-coding-plan",
        }
        provider_id = provider_map.get(provider, provider)
        return {"providerID": provider_id, "modelID": model_id}
    return {"providerID": "minimax-cn-coding-plan", "modelID": model_str}


class OpenCodeAdapter(AgentAdapter):
    """OpenCode Server 适配器"""

    def __init__(self, api_base: str = DEFAULT_API_BASE,
                 model: str = None,
                 timeout: int = TIMEOUT,
                 temperature: float = None,
                 on_progress=None):
        self.api_base = api_base
        self.model = model
        self.timeout = timeout
        self.temperature = temperature
        self.on_progress = on_progress

        # setup 阶段准备的配置
        self._system_message = ""
        self._tools_config = None
        self._registered_mcps = []  # 记录注册的 MCP server 名称，用于 teardown

    def _log(self, level: str, message: str, tag: str = ""):
        if self.on_progress:
            self.on_progress("log", {"level": level, "message": f"{tag}{message}"})
        if level == "ERROR":
            print(f"  [ERROR] {tag}{message}", file=sys.stderr)

    # ── setup ────────────────────────────────────────────────

    def setup(self, enhancements: dict, on_progress=None):
        """配置增强工具

        Args:
            enhancements: Profile 的 enhancements 字段（含 skill content）
        """
        if on_progress:
            self.on_progress = on_progress

        self._system_message = ""
        self._tools_config = None
        self._registered_mcps = []

        if not enhancements:
            self._log("DEBUG", "基线模式: 无增强配置")
            return

        # 1. System Prompt
        system_prompt = enhancements.get("system_prompt", "")
        if system_prompt:
            self._system_message = system_prompt.strip()
            self._log("INFO", f"已配置 System Prompt ({len(self._system_message)} 字符)")

        # 2. Skills → 拼入 system message
        skills = enhancements.get("skills", [])
        for skill in skills:
            name = skill.get("name", "unknown")
            content = skill.get("content", "")
            if content:
                separator = "\n\n" if self._system_message else ""
                self._system_message += f"{separator}## Skill: {name}\n\n{content}"
                self._log("INFO", f"已配置 Skill: {name} ({len(content)} 字符)")
            else:
                self._log("WARN", f"Skill [{name}] 内容为空，跳过")

        # 3. MCP Servers → 通过 API 注册
        mcp_servers = enhancements.get("mcp_servers", [])
        for mcp in mcp_servers:
            self._register_mcp(mcp)

        # 4. Tools 开关
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

    # ── execute ──────────────────────────────────────────────

    def execute(self, prompt: str, tag: str = "") -> str:
        """创建 session，发送消息（携带 system/tools 配置），返回响应"""
        try:
            # 1. 创建 session
            self._log("DEBUG", "创建 Session...", tag=tag)
            t0 = time.time()
            session_id = self._create_session()
            if not session_id:
                self._log("ERROR", "创建 Session 失败", tag=tag)
                return ""
            self._log("DEBUG",
                f"Session 已创建: {session_id[:12]}... ({time.time()-t0:.1f}s)",
                tag=tag)

            # 2. 构建 message payload
            message_payload = {
                "parts": [{"type": "text", "text": prompt}],
            }
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
            self._log("INFO",
                f"发送请求: Prompt={prompt_kb:.1f}KB, {has_system}, {has_tools}, {has_model}, 超时={self.timeout}s",
                tag=tag)

            # payload 详情日志
            payload_summary = {
                "parts_count": len(message_payload.get("parts", [])),
                "prompt_length": len(prompt),
                "has_system": bool(self._system_message),
                "system_length": len(self._system_message) if self._system_message else 0,
                "system_preview": self._system_message[:200] + "..." if self._system_message and len(self._system_message) > 200 else self._system_message,
                "has_tools": bool(self._tools_config),
                "tools": self._tools_config,
                "has_model": bool(self.model),
                "model": message_payload.get("model"),
            }
            self._log("DEBUG",
                f"Message Payload 详情: {json.dumps(payload_summary, ensure_ascii=False, indent=2)}",
                tag=tag)

            # 3. 发送消息
            t0 = time.time()
            req = urllib.request.Request(
                f"{self.api_base}/session/{session_id}/message",
                data=data,
                headers={"Content-Type": "application/json"},
                method="POST"
            )
            with urllib.request.urlopen(req, timeout=self.timeout) as response:
                result_data = response.read().decode("utf-8")
                elapsed = time.time() - t0
                result = json.loads(result_data)
                parts = result.get("parts", [])
                for part in parts:
                    if part.get("type") == "text":
                        text = part.get("text", "").strip()
                        self._log("INFO",
                            f"收到响应: {len(text)}字符, 耗时={elapsed:.1f}s",
                            tag=tag)
                        return text
                self._log("WARN",
                    f"响应中无 text 部分, parts数={len(parts)}, 耗时={elapsed:.1f}s",
                    tag=tag)
                return ""

        except urllib.error.HTTPError as e:
            self._log("ERROR", f"HTTP 错误: {e.code} {e.reason}", tag=tag)
            try:
                error_body = e.read().decode("utf-8")
                self._log("ERROR", f"错误详情: {error_body[:200]}", tag=tag)
            except Exception:
                pass
            return ""
        except urllib.error.URLError as e:
            self._log("ERROR",
                f"无法连接 OpenCode API ({self.api_base}): {e.reason}",
                tag=tag)
            return ""
        except TimeoutError:
            self._log("ERROR", f"请求超时 ({self.timeout}s)", tag=tag)
            raise TimeoutError(f"Agent 请求超时 ({self.timeout}s)")

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
