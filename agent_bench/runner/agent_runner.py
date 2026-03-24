import subprocess
import sys

TIMEOUT = 120

BASELINE_PROMPT = """你是一个ArkTS开发者。请完成以下任务。

## 任务
{description}

## 代码
```typescript
{code}
```

## 要求
- 只输出修复后的完整代码
- 不要解释修复过程
"""

SKILL_ENHANCED_PROMPT = """你是一个ArkTS开发者。请参考以下最佳实践完成任务。

## 最佳实践参考
{skill_content}

## 任务
{description}

## 代码
```typescript
{code}
```

## 要求
- 只输出修复后的完整代码
- 不要解释修复过程
"""


def run_baseline(description: str, code: str, work_dir: str = ".") -> str:
    """基线运行 - 所有评测类型通用，纯 Agent 无增强"""
    prompt = BASELINE_PROMPT.format(description=description, code=code)
    return _run_claude(prompt, work_dir)


def run_enhanced(description: str, code: str, eval_type: str,
                 subject_content: str = None, subject_path: str = None,
                 work_dir: str = ".") -> str:
    """增强运行 - 根据 eval_type 构建不同的调用方式

    Args:
        eval_type: "skill" | "mcp_tool" | "system_prompt"
        subject_content: skill 或 system_prompt 的文本内容
        subject_path: mcp_tool 的配置文件路径
    """
    if eval_type == "skill":
        prompt = SKILL_ENHANCED_PROMPT.format(
            skill_content=subject_content,
            description=description,
            code=code,
        )
        return _run_claude(prompt, work_dir)

    elif eval_type == "mcp_tool":
        # MCP Tool: prompt 与基线相同，通过 --mcp-config 挂载工具
        prompt = BASELINE_PROMPT.format(description=description, code=code)
        return _run_claude(prompt, work_dir, mcp_config=subject_path)

    elif eval_type == "system_prompt":
        # System Prompt: prompt 与基线相同，通过 -s 注入 system prompt
        prompt = BASELINE_PROMPT.format(description=description, code=code)
        return _run_claude(prompt, work_dir, system_prompt=subject_content)

    else:
        raise ValueError(f"Unknown eval_type: {eval_type}")


def _run_claude(prompt: str, work_dir: str,
                mcp_config: str = None, system_prompt: str = None) -> str:
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
        print("  [ERROR] claude command not found, is Claude Code installed?", file=sys.stderr)
        return ""
