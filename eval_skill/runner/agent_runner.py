import subprocess
import sys

TIMEOUT = 120

BASELINE_PROMPT = """你是一个ArkTS开发者。请修复以下代码中的bug。

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

ENHANCED_PROMPT = """你是一个ArkTS开发者。请参考以下最佳实践修复代码中的bug。

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
    prompt = BASELINE_PROMPT.format(description=description, code=code)
    return _run_claude(prompt, work_dir)


def run_enhanced(description: str, code: str, skill_content: str, work_dir: str = ".") -> str:
    prompt = ENHANCED_PROMPT.format(
        skill_content=skill_content,
        description=description,
        code=code,
    )
    return _run_claude(prompt, work_dir)


def _run_claude(prompt: str, work_dir: str) -> str:
    try:
        result = subprocess.run(
            ["claude", "-p", prompt],
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
