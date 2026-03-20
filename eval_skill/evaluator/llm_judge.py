import subprocess
import json
import re
import sys

TIMEOUT = 60

JUDGE_PROMPT = """你是一个严格的代码评审专家，请评估以下ArkTS代码的修复质量。

## 原始代码（有bug）
```typescript
{input_code}
```

## 参考答案
```typescript
{reference_code}
```

## 待评估代码
```typescript
{output_code}
```

## 评分维度
{rubric_text}

请对每个维度打分（0-100），返回严格的JSON格式，不要包含其他内容：
{{"scores": [{{"name": "维度名", "score": 分数, "reason": "评分理由"}}]}}
"""

DEFAULT_SCORE = 50


def judge(input_code: str, output_code: str, reference_code: str, rubric: list) -> dict:
    if not output_code.strip():
        return {
            "scores": [{"name": r["name"], "score": 0, "reason": "Agent无输出"} for r in rubric]
        }

    rubric_text = "\n".join(
        f"- {r['name']}（权重{r['weight']}%）: {r['criteria']}"
        for r in rubric
    )

    prompt = JUDGE_PROMPT.format(
        input_code=input_code,
        reference_code=reference_code,
        output_code=output_code,
        rubric_text=rubric_text,
    )

    try:
        result = subprocess.run(
            ["claude", "-p", prompt],
            capture_output=True,
            text=True,
            timeout=TIMEOUT,
        )
        return _parse_scores(result.stdout, rubric)
    except (subprocess.TimeoutExpired, FileNotFoundError) as e:
        print(f"  [ERROR] LLM judge failed: {e}", file=sys.stderr)
        return {
            "scores": [{"name": r["name"], "score": DEFAULT_SCORE, "reason": "评分超时"} for r in rubric]
        }


def _parse_scores(raw_output: str, rubric: list) -> dict:
    try:
        match = re.search(r'\{[\s\S]*"scores"[\s\S]*\}', raw_output)
        if match:
            data = json.loads(match.group())
            if "scores" in data:
                return data
    except (json.JSONDecodeError, AttributeError):
        pass

    print(f"  [WARN] Failed to parse judge output, using default scores", file=sys.stderr)
    return {
        "scores": [{"name": r["name"], "score": DEFAULT_SCORE, "reason": "解析失败"} for r in rubric]
    }
