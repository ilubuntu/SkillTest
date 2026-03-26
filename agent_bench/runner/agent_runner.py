# -*- coding: utf-8 -*-
"""Agent Runner - Agent 通信层

职责：
- 与 Agent（OpenCode）的所有通信（HTTP API / CLI）
- 模型字符串解析
- Prompt 模板管理（baseline / enhanced）
- OpenCode 服务发现与启动
- Sandbox 创建

本模块是唯一与外部 Agent 服务交互的地方，
cli.py 和 evaluator 通过本模块的公开接口调用 Agent。
"""

import json
import os
import socket
import subprocess
import sys
import time
import urllib.request
import urllib.error
from typing import Optional

TIMEOUT = 180
DEFAULT_API_BASE = "http://localhost:4096"

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# ── Prompt 模板 ──────────────────────────────────────────────

BASELINE_PROMPT = """你是一个ArkTS开发者。请完成以下任务。

## 任务
{prompt}

## 代码
```typescript
{code}
```

## 要求
- 只输出完整的代码
- 不要解释过程
"""

ENHANCED_PROMPT = """你是一个ArkTS开发者。请参考以下最佳实践完成任务。

## 最佳实践参考
{skill_content}

## 任务
{prompt}

## 代码
```typescript
{code}
```

## 要求
- 只输出完整的代码
- 不要解释过程
"""


# ── 模型解析（全局唯一） ─────────────────────────────────────

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


# ── HTTP API 调用（底层，供 AgentRunner 和 LLMJudge 共用） ───

def call_http_api(prompt: str, api_base: str = DEFAULT_API_BASE,
                  model: str = None,
                  timeout: int = TIMEOUT,
                  on_progress: "Callable" = None,
                  tag: str = "") -> str:
    """通过 HTTP API 调用 OpenCode 服务

    这是底层通信函数，AgentRunner 和 LLMJudge 都通过此函数与 LLM 交互。

    Args:
        prompt: 用户输入的提示词
        api_base: OpenCode API 服务地址
        model: 使用的模型（None 则使用 OpenCode 默认配置）
        timeout: 超时时间（秒）
        on_progress: 进度回调 (event, data)
        tag: 日志前缀标识

    Returns:
        LLM 输出的文本内容，失败返回空字符串
    """
    def _log(level, msg):
        if on_progress:
            on_progress("log", {"level": level, "message": f"{tag}{msg}"})
        if level == "ERROR":
            print(f"  [ERROR] {tag}{msg}", file=sys.stderr)

    try:
        # 创建 session
        _log("DEBUG", f"创建 Session ({api_base})...")
        t0 = time.time()
        create_req = urllib.request.Request(
            f"{api_base}/session",
            data=json.dumps({}).encode("utf-8"),
            headers={"Content-Type": "application/json"},
            method="POST"
        )
        with urllib.request.urlopen(create_req, timeout=10) as response:
            session = json.loads(response.read().decode("utf-8"))
            session_id = session.get("id")
            if not session_id:
                _log("ERROR", "创建 Session 失败: 无 session_id")
                return ""
        _log("DEBUG", f"Session 已创建: {session_id[:12]}... ({time.time()-t0:.1f}s)")

        # 发送消息
        message_payload = {
            "parts": [{"type": "text", "text": prompt}]
        }
        if model:
            message_payload["model"] = parse_model(model)
        data = json.dumps(message_payload).encode("utf-8")

        prompt_kb = len(data) / 1024
        _log("INFO", f"发送请求: Prompt={prompt_kb:.1f}KB, 超时={timeout}s")

        t0 = time.time()
        req = urllib.request.Request(
            f"{api_base}/session/{session_id}/message",
            data=data,
            headers={"Content-Type": "application/json"},
            method="POST"
        )

        with urllib.request.urlopen(req, timeout=timeout) as response:
            result_data = response.read().decode("utf-8")
            elapsed = time.time() - t0
            result = json.loads(result_data)
            parts = result.get("parts", [])
            for part in parts:
                if part.get("type") == "text":
                    text = part.get("text", "").strip()
                    _log("INFO", f"收到响应: {len(text)}字符, 耗时={elapsed:.1f}s")
                    return text
            _log("WARN", f"响应中无 text 部分, parts数={len(parts)}, 耗时={elapsed:.1f}s")
            return ""

    except urllib.error.HTTPError as e:
        _log("ERROR", f"HTTP 错误: {e.code} {e.reason}")
        try:
            error_body = e.read().decode("utf-8")
            _log("ERROR", f"错误详情: {error_body[:200]}")
        except Exception:
            pass
        return ""
    except urllib.error.URLError as e:
        _log("ERROR", f"无法连接 OpenCode API ({api_base}): {e.reason}")
        return ""
    except TimeoutError:
        _log("ERROR", f"请求超时 ({timeout}s)")
        return ""


# ── AgentRunner 类 ───────────────────────────────────────────

class AgentRunner:
    """Agent 运行器

    提供 baseline / enhanced 两种运行方式，
    内部统一通过 call_http_api() 与 OpenCode 通信。
    """

    def __init__(self, api_base: str = DEFAULT_API_BASE,
                 model: str = None, on_progress=None):
        self.api_base = api_base
        self.model = model
        self.on_progress = on_progress

    def run_baseline(self, prompt: str, code: str, case_id: str = "") -> str:
        """基线运行 - 纯 Agent 无增强"""
        tag = f"[{case_id}][基线] " if case_id else "[基线] "
        full_prompt = BASELINE_PROMPT.format(prompt=prompt, code=code)
        return call_http_api(full_prompt, self.api_base, self.model,
                             on_progress=self.on_progress, tag=tag)

    def run_enhanced(self, prompt: str, code: str, skill_content: str,
                     case_id: str = "") -> str:
        """增强运行 - 注入 Skill 最佳实践"""
        tag = f"[{case_id}][增强] " if case_id else "[增强] "
        full_prompt = ENHANCED_PROMPT.format(
            skill_content=skill_content, prompt=prompt, code=code
        )
        return call_http_api(full_prompt, self.api_base, self.model,
                             on_progress=self.on_progress, tag=tag)


# ── 服务发现与启动 ───────────────────────────────────────────

def check_api_available(api_base: str) -> bool:
    """检查 OpenCode API 是否可用"""
    try:
        req = urllib.request.Request(f"{api_base}/global/health", method="GET")
        with urllib.request.urlopen(req, timeout=3) as response:
            result = json.loads(response.read().decode("utf-8"))
            return result.get("healthy", False)
    except Exception:
        return False


def find_opencode_port() -> Optional[str]:
    """查找当前运行的 OpenCode server 端口"""
    common_ports = ["4096", "36903", "8080", "3000", "18792", "8000", "5000"]

    for port in common_ports:
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(1)
        try:
            result = sock.connect_ex(("localhost", int(port)))
            sock.close()
            if result == 0:
                if check_api_available(f"http://localhost:{port}"):
                    return port
        except Exception:
            pass

    return None


def ensure_opencode_server(timeout: int = 30) -> str:
    """确保 OpenCode API 服务可用，必要时自动启动

    Returns:
        可用的 API base URL
    """
    import platform

    print("[INFO] Searching for OpenCode server...")
    port = find_opencode_port()
    if port:
        api_base = f"http://localhost:{port}"
        print(f"[INFO] Found OpenCode API at {api_base}")
        return api_base

    print("[INFO] No valid OpenCode server found, "
          "starting new server on port 4096...")

    system = platform.system()
    try:
        if system == "Windows":
            cmd = 'start /b cmd /c "opencode serve --port 4096"'
            os.system(cmd)
        else:
            subprocess.Popen(
                ["nohup", "opencode", "serve", "--port", "4096", "&"],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                stdin=subprocess.DEVNULL
            )

        print(f"[INFO] Server starting, waiting {timeout}s...")
        for i in range(timeout):
            time.sleep(1)
            if check_api_available("http://localhost:4096"):
                print("[INFO] OpenCode server started at http://localhost:4096")
                return "http://localhost:4096"
            print(f"[INFO] Waiting... ({i+1}/{timeout})")

        print("[WARN] Server may not have started, continuing anyway...")

    except FileNotFoundError:
        print("[ERROR] opencode command not found. Please install opencode first.")
        print("[ERROR] Download from: https://opencode.ai")
        sys.exit(1)
    except Exception as e:
        print(f"[WARN] Failed to start opencode server: {e}")

    return "http://localhost:8080"


# ── Sandbox 创建 ─────────────────────────────────────────────

def create_sandbox(run_id: str, case_id: str, profile: dict) -> str:
    """创建 sandbox 目录，写入 opencode.json、skill 文件、AGENTS.md

    Args:
        run_id: 运行 ID
        case_id: 用例 ID
        profile: Agent profile 配置

    Returns:
        sandbox 目录的绝对路径
    """
    sandbox_dir = os.path.join(BASE_DIR, "results", run_id, "sandboxes", case_id)
    os.makedirs(sandbox_dir, exist_ok=True)

    # 生成 opencode.json
    agent_config = profile.get("agent", {})
    opencode_config = {
        "model": agent_config.get("model", "anthropic/claude-sonnet-4-6"),
        "timeout": agent_config.get("timeout", 120),
    }
    with open(os.path.join(sandbox_dir, "opencode.json"), "w",
              encoding="utf-8") as f:
        json.dump(opencode_config, f, ensure_ascii=False, indent=2)

    # 复制 skill 文件到 sandbox
    enhancements = profile.get("enhancements", {})
    skills = enhancements.get("skills", [])
    if skills:
        skills_dir = os.path.join(sandbox_dir, "skills")
        os.makedirs(skills_dir, exist_ok=True)
        for skill in skills:
            skill_src = os.path.join(BASE_DIR, skill["path"])
            if os.path.exists(skill_src):
                skill_dest = os.path.join(
                    skills_dir, os.path.basename(skill["path"])
                )
                with open(skill_src, "r", encoding="utf-8") as src:
                    with open(skill_dest, "w", encoding="utf-8") as dst:
                        dst.write(src.read())

    # 生成 AGENTS.md
    system_prompt = enhancements.get("system_prompt", "")
    if system_prompt:
        agents_md_path = os.path.join(sandbox_dir, "AGENTS.md")
        with open(agents_md_path, "w", encoding="utf-8") as f:
            f.write(f"# Agent Instructions\n\n{system_prompt.strip()}\n")

    return sandbox_dir
