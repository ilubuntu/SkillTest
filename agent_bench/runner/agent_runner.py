# -*- coding: utf-8 -*-
"""Agent Runner - 驱动 Agent 执行

支持三种驱动模式：
1. HTTP API 模式（默认）：通过 HTTP API 调用 OpenCode 服务
2. opencode run CLI 模式：通过 opencode run 命令行
3. claude -p fallback 模式：通过 claude -p 命令行（Windows 不兼容时备用）

HTTP API 模式通过 opencode serve 启动的常驻实例控制会话，
复用 MCP Server 连接，避免冷启动开销。
"""

import json
import os
import subprocess
import sys
import urllib.request
import urllib.error

TIMEOUT = 120
DEFAULT_API_BASE = "http://localhost:4096"

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

BASELINE_PROMPT = """你是一个ArkTS开发者。请完成以下任务。

## 任务
{prompt}

## 代码
```typescript
{code}
```

## 要求
- 只输出修复后的完整代码
- 不要解释修复过程
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
- 只输出修复后的完整代码
- 不要解释修复过程
"""


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
    with open(os.path.join(sandbox_dir, "opencode.json"), "w", encoding="utf-8") as f:
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
                skill_dest = os.path.join(skills_dir, os.path.basename(skill["path"]))
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


def run_agent(sandbox_dir: str, prompt: str, model: str = "minimax/MiniMax-M2.7") -> str:
    """在 sandbox 中运行 Agent（优先使用 HTTP API）"""
    if sys.platform == "win32":
        return run_agent_http(prompt, model=model)
    return _run_opencode_cli(prompt, sandbox_dir, model)


def run_baseline(prompt: str, code: str, work_dir: str = ".",
                 model: str = "minimax/MiniMax-M2.7",
                 use_http: bool = True) -> str:
    """基线运行 - 纯 Agent 无增强
    
    Args:
        prompt: 用例的任务描述
        code: 待处理的代码
        work_dir: 工作目录
        model: 使用的模型
        use_http: 是否优先使用 HTTP API
    """
    full_prompt = BASELINE_PROMPT.format(prompt=prompt, code=code)
    if use_http:
        return _run_http_api(full_prompt, model=model)
    return _run_claude(full_prompt, work_dir)


def run_enhanced(prompt: str, code: str, profile: dict,
                 sandbox_dir: str = None,
                 use_http: bool = True) -> str:
    """增强运行 - 根据 profile 构建增强 prompt
    
    Args:
        prompt: 用例的任务描述
        code: 待处理的代码
        profile: Agent profile 配置
        sandbox_dir: sandbox 目录（如果已创建）
        use_http: 是否优先使用 HTTP API（Windows 下默认为 True）
    """
    enhancements = profile.get("enhancements", {})
    skills = enhancements.get("skills", [])
    agent_config = profile.get("agent", {})
    model = agent_config.get("model", "minimax/MiniMax-M2.7")

    # 加载 skill 内容
    skill_content = ""
    for skill in skills:
        skill_path = os.path.join(BASE_DIR, skill["path"])
        if os.path.exists(skill_path):
            with open(skill_path, "r", encoding="utf-8") as f:
                skill_content += f.read() + "\n"

    if skill_content.strip():
        full_prompt = ENHANCED_PROMPT.format(
            skill_content=skill_content.strip(),
            prompt=prompt,
            code=code,
        )
    else:
        # 没有 skill，回退到基线 prompt
        full_prompt = BASELINE_PROMPT.format(prompt=prompt, code=code)

    if use_http or sys.platform == "win32":
        return _run_http_api(full_prompt, model=model)
    
    work_dir = sandbox_dir or "."
    return _run_opencode_cli(full_prompt, work_dir, model)


def _parse_model(model_str: str) -> dict:
    """解析模型字符串为 API 格式"""
    if "/" in model_str:
        provider, model_id = model_str.split("/", 1)
        provider_map = {
            "minimax": "minimax-cn-coding-plan",
        }
        provider_id = provider_map.get(provider, provider)
        return {"providerID": provider_id, "modelID": model_id}
    return {"providerID": "minimax-cn-coding-plan", "modelID": model_str}


def _run_http_api(prompt: str, api_base: str = DEFAULT_API_BASE,
                   model: str = "minimax/MiniMax-M2.7", timeout: int = TIMEOUT) -> str:
    """通过 HTTP API 调用 OpenCode 服务
    
    Args:
        prompt: 用户输入的提示词
        api_base: OpenCode API 服务地址
        model: 使用的模型
        timeout: 超时时间（秒）
    
    Returns:
        Agent 输出的文本内容
    """
    try:
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
                print(f"  [ERROR] Failed to create session", file=sys.stderr)
                return ""
        
        message_payload = {
            "model": _parse_model(model),
            "parts": [{"type": "text", "text": prompt}]
        }
        data = json.dumps(message_payload).encode("utf-8")
        req = urllib.request.Request(
            f"{api_base}/session/{session_id}/message",
            data=data,
            headers={"Content-Type": "application/json"},
            method="POST"
        )
        
        with urllib.request.urlopen(req, timeout=timeout) as response:
            result = json.loads(response.read().decode("utf-8"))
            parts = result.get("parts", [])
            for part in parts:
                if part.get("type") == "text":
                    return part.get("text", "").strip()
            return ""
            
    except urllib.error.HTTPError as e:
        print(f"  [ERROR] HTTP API error: {e.code} - {e.reason}", file=sys.stderr)
        try:
            error_body = e.read().decode("utf-8")
            print(f"  [ERROR] Response: {error_body[:200]}", file=sys.stderr)
        except:
            pass
        return ""
    except urllib.error.URLError as e:
        print(f"  [ERROR] Cannot connect to OpenCode API at {api_base}", file=sys.stderr)
        print(f"  [ERROR] {e.reason}", file=sys.stderr)
        return ""
    except TimeoutError:
        print(f"  [ERROR] HTTP API timed out after {timeout}s", file=sys.stderr)
        return ""


def _run_opencode_cli(prompt: str, work_dir: str, model: str = "minimax/MiniMax-M2.7") -> str:
    """通过 opencode run CLI 调用
    
    Args:
        prompt: 用户输入的提示词
        work_dir: 工作目录
        model: 使用的模型
    
    Returns:
        Agent 输出的文本内容
    """
    cmd = [
        "opencode", "run",
        "--format", "json",
        "--quiet",
        "--model", model,
        prompt
    ]
    
    try:
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=TIMEOUT,
            cwd=work_dir,
        )
        if result.returncode != 0:
            print(f"  [WARN] opencode exit code: {result.returncode}", file=sys.stderr)
            if result.stderr:
                print(f"  [WARN] stderr: {result.stderr[:200]}", file=sys.stderr)
        
        output = result.stdout.strip()
        try:
            parsed = json.loads(output)
            if "content" in parsed:
                return parsed["content"]
            elif "text" in parsed:
                return parsed["text"]
            return output
        except json.JSONDecodeError:
            return output
    except subprocess.TimeoutExpired:
        print(f"  [ERROR] opencode timed out after {TIMEOUT}s", file=sys.stderr)
        return ""
    except FileNotFoundError:
        print("  [ERROR] opencode command not found, is OpenCode installed?",
              file=sys.stderr)
        return ""


def _run_claude(prompt: str, work_dir: str = ".",
                mcp_config: str = None, system_prompt: str = None) -> str:
    """调用 claude -p（fallback 方式，仅 Linux/macOS）
    
    Windows 不支持此方式，会回退到 HTTP API 模式
    """
    if sys.platform == "win32":
        print("  [WARN] claude -p not supported on Windows, using HTTP API fallback")
        return _run_http_api(prompt)
    
    cmd = ["claude", "-p", prompt]
    if mcp_config:
        cmd.extend(["--mcp-config", mcp_config])
    if system_prompt:
        cmd.extend(["-s", system_prompt])

    try:
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=TIMEOUT,
            cwd=work_dir,
        )
        if result.returncode != 0:
            print(f"  [WARN] claude exit code: {result.returncode}", file=sys.stderr)
            if result.stderr:
                print(f"  [WARN] stderr: {result.stderr[:200]}", file=sys.stderr)
        return result.stdout.strip()
    except subprocess.TimeoutExpired:
        print(f"  [ERROR] claude timed out after {TIMEOUT}s", file=sys.stderr)
        return ""
    except FileNotFoundError:
        print("  [ERROR] claude command not found, is Claude Code installed?",
              file=sys.stderr)
        return ""


def run_agent_http(prompt: str, api_base: str = DEFAULT_API_BASE,
                   model: str = "minimax/MiniMax-M2.7") -> str:
    """通过 HTTP API 运行 Agent（主要驱动方式）
    
    优先使用 HTTP API 方式，这是 Windows 兼容的方式
    """
    return _run_http_api(prompt, api_base, model)
