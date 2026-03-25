# -*- coding: utf-8 -*-
"""LLM-as-Judge 评分模块

通过 runner.agent_runner.call_http_api 调用 LLM，
一次调用同时对 baseline 和 enhanced 输出进行对比评分。
"""

import json
import re
import sys

from agent_bench.runner.agent_runner import call_http_api, DEFAULT_API_BASE

JUDGE_PROMPT = """你是一个严格的代码评审专家，请对比评估以下两份ArkTS代码的修复质量。

## 原始代码（有bug）
```typescript
{input_code}
```

## 参考答案
```typescript
{reference_code}
```

## 代码A（基线输出）
```typescript
{baseline_code}
```

## 代码B（增强输出）
```typescript
{enhanced_code}
```

## 评分维度
{rubric_text}

请分别对代码A和代码B的每个维度打分（0-100），返回严格的JSON格式，不要包含其他内容：
{{"baseline": [{{"name": "维度名", "score": 分数, "reason": "评分理由"}}], "enhanced": [{{"name": "维度名", "score": 分数, "reason": "评分理由"}}]}}
"""

DEFAULT_SCORE = 50


class LLMJudge:
    """LLM 评分器

    复用 runner.agent_runner.call_http_api 与 LLM 通信，
    一次调用同时对比评分 baseline 和 enhanced 输出。
    """

    def __init__(self, api_base: str = DEFAULT_API_BASE,
                 model: str = None):
        self.api_base = api_base
        self.model = model

    def judge(self, input_code: str, baseline_code: str,
              enhanced_code: str, reference_code: str,
              rubric: list) -> dict:
        """对 baseline 和 enhanced 输出进行对比评分

        Args:
            input_code: 原始有 bug 的代码
            baseline_code: Agent 基线输出
            enhanced_code: Agent 增强输出
            reference_code: 参考答案代码
            rubric: 评分维度列表

        Returns:
            {
              "baseline": [{"name": str, "score": int, "reason": str}, ...],
              "enhanced": [{"name": str, "score": int, "reason": str}, ...]
            }
        """
        default_empty = [
            {"name": r["name"], "score": 0, "reason": "Agent无输出"}
            for r in rubric
        ]

        # 两个都为空
        if not baseline_code.strip() and not enhanced_code.strip():
            return {"baseline": default_empty, "enhanced": default_empty}

        rubric_text = "\n".join(
            f"- {r['name']}（权重{r['weight']}%）: {r['criteria']}"
            for r in rubric
        )

        prompt = JUDGE_PROMPT.format(
            input_code=input_code,
            reference_code=reference_code,
            baseline_code=baseline_code or "// 无输出",
            enhanced_code=enhanced_code or "// 无输出",
            rubric_text=rubric_text,
        )

        try:
            result = call_http_api(
                prompt, self.api_base, self.model, timeout=60
            )
            return _parse_scores(result, rubric)
        except Exception as e:
            print(f"  [ERROR] LLM judge failed: {e}", file=sys.stderr)
            default_fallback = [
                {"name": r["name"], "score": DEFAULT_SCORE,
                 "reason": "评分失败"}
                for r in rubric
            ]
            return {"baseline": default_fallback, "enhanced": default_fallback}


def _parse_scores(raw_output: str, rubric: list) -> dict:
    """解析 LLM 输出的 JSON 评分"""
    try:
        match = re.search(r'\{[\s\S]*"baseline"[\s\S]*"enhanced"[\s\S]*\}',
                          raw_output)
        if match:
            data = json.loads(match.group())
            if "baseline" in data and "enhanced" in data:
                return data
    except (json.JSONDecodeError, AttributeError):
        pass

    print("  [WARN] Failed to parse judge output, using default scores",
          file=sys.stderr)
    default = [
        {"name": r["name"], "score": DEFAULT_SCORE, "reason": "解析失败"}
        for r in rubric
    ]
    return {"baseline": default, "enhanced": default}
