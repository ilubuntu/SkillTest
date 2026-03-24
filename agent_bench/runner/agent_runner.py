# -*- coding: utf-8 -*-
"""Agent Runner - 驱动 Agent 执行

支持 sandbox 模式（opencode run）和 fallback 模式（claude -p）。
当前 MVP 使用 claude -p fallback，后续切换到 opencode run。
"""

import json
import os
import subprocess
import sys

# TODO: 切换到 opencode run 作为默认 Agent 驱动方式
#   opencode run 支持 sandbox 隔离、opencode.json 配置、AGENTS.md 注入
#   当前使用 claude -p 作为 fallback

TIMEOUT = 120

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


def run_agent(sandbox_dir: str, prompt: str) -> str:
    """在 sandbox 中运行 Agent

    TODO: 切换到 opencode run
        cmd = ["opencode", "run", "--format", "json", "--quiet", prompt]
        subprocess.run(cmd, cwd=sandbox_dir, ...)

    当前 fallback 到 claude -p
    """
    return _run_claude(prompt, sandbox_dir)


def run_baseline(prompt: str, code: str, work_dir: str = ".") -> str:
    """基线运行 - 纯 Agent 无增强"""
    full_prompt = BASELINE_PROMPT.format(prompt=prompt, code=code)
    return _run_claude(full_prompt, work_dir)


def run_enhanced(prompt: str, code: str, profile: dict,
                 sandbox_dir: str = None) -> str:
    """增强运行 - 根据 profile 构建增强 prompt

    Args:
        prompt: 用例的任务描述
        code: 待处理的代码
        profile: Agent profile 配置
        sandbox_dir: sandbox 目录（如果已创建）
    """
    enhancements = profile.get("enhancements", {})
    skills = enhancements.get("skills", [])

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

    work_dir = sandbox_dir or "."

    # TODO: 切换到 opencode run
    #   return run_agent(work_dir, full_prompt)
    return _run_claude(full_prompt, work_dir)


def _run_claude(prompt: str, work_dir: str,
                mcp_config: str = None, system_prompt: str = None) -> str:
    """调用 claude -p（fallback 方式）

    TODO: 将此方法替换为 opencode run 调用
    """
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
