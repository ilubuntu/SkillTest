# -*- coding: utf-8 -*-
"""LLM-as-Judge 评分模块

通过 pipeline 注入的 llm_fn 调用 LLM，
一次调用同时对 baseline 和 enhanced 输出进行对比评分。

本模块不依赖 runner 层，LLM 调用能力由上层注入。
"""

import json
import re
import sys
from typing import Callable, Optional

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

    通过注入的 llm_fn 与 LLM 通信，
    一次调用同时对比评分 baseline 和 enhanced 输出。
    """

    def __init__(self, llm_fn: Callable[[str, str], str],
                 on_progress=None):
        """
        Args:
            llm_fn: LLM 调用函数，签名 (prompt: str, tag: str) -> str
            on_progress: 进度回调
        """
        self.llm_fn = llm_fn
        self.on_progress = on_progress

    def _log(self, level, message):
        if self.on_progress:
            self.on_progress("log", {"level": level, "message": message})

    def judge(self, input_code: str, baseline_code: str,
              enhanced_code: str, reference_code: str,
              rubric: list, case_id: str = "") -> dict:
        """对 baseline 和 enhanced 输出进行对比评分

        Args:
            input_code: 原始有 bug 的代码
            baseline_code: Agent 基线输出
            enhanced_code: Agent 增强输出
            reference_code: 参考答案代码
            rubric: 评分维度列表
            case_id: 用例 ID（用于日志前缀）

        Returns:
            {
              "baseline": [{"name": str, "score": int, "reason": str}, ...],
              "enhanced": [{"name": str, "score": int, "reason": str}, ...]
            }
        """
        tag = f"[{case_id}]" if case_id else ""
        default_empty = [
            {"name": r["name"], "score": 0, "reason": "Agent无输出"}
            for r in rubric
        ]

        # 两个都为空
        if not baseline_code.strip() and not enhanced_code.strip():
            self._log("WARN", f"{tag} 基线和增强输出均为空，跳过 LLM 评分")
            return {"baseline": default_empty, "enhanced": default_empty}

        rubric_text = "\n".join(
            f"- {r['name']}（权重{r['weight']}%）: {r['criteria']}"
            for r in rubric
        )
        dim_names = ", ".join(r["name"] for r in rubric)
        self._log("INFO", f"{tag}[评分] 构建评分 Prompt, 维度: {dim_names}")

        prompt = JUDGE_PROMPT.format(
            input_code=input_code,
            reference_code=reference_code,
            baseline_code=baseline_code or "// 无输出",
            enhanced_code=enhanced_code or "// 无输出",
            rubric_text=rubric_text,
        )

        self._log("DEBUG", f"{tag}[评分] Prompt 长度={len(prompt)}字符, "
                   f"输入代码={len(input_code)}字符, "
                   f"基线输出={len(baseline_code)}字符, "
                   f"增强输出={len(enhanced_code)}字符")

        try:
            api_tag = f"{tag}[评分] "
            result = self.llm_fn(prompt, api_tag)
            if not result:
                self._log("ERROR", f"{tag}[评分] LLM 返回空结果")
                default_fallback = [
                    {"name": r["name"], "score": DEFAULT_SCORE,
                     "reason": "返回为空"}
                    for r in rubric
                ]
                return {"baseline": default_fallback, "enhanced": default_fallback}

            scores = _parse_scores(result, rubric, self.on_progress, tag)

            # 输出每个维度的评分理由
            for side, label in [("baseline", "基线"), ("enhanced", "增强")]:
                for s in scores.get(side, []):
                    self._log("DEBUG", f"{tag}[评分] {label} [{s['name']}] "
                              f"= {s['score']} — {s.get('reason', '')[:60]}")

            return scores
        except Exception as e:
            self._log("ERROR", f"{tag}[评分] LLM 评分异常: {e}")
            default_fallback = [
                {"name": r["name"], "score": DEFAULT_SCORE,
                 "reason": "评分失败"}
                for r in rubric
            ]
            return {"baseline": default_fallback, "enhanced": default_fallback}


def _parse_scores(raw_output: str, rubric: list,
                  on_progress=None, tag: str = "") -> dict:
    """解析 LLM 输出的 JSON 评分"""
    def _log(level, msg):
        if on_progress:
            on_progress("log", {"level": level, "message": msg})

    try:
        match = re.search(r'\{[\s\S]*"baseline"[\s\S]*"enhanced"[\s\S]*\}',
                          raw_output)
        if match:
            data = json.loads(match.group())
            if "baseline" in data and "enhanced" in data:
                _log("DEBUG", f"{tag}[评分] JSON 解析成功, "
                     f"baseline={len(data['baseline'])}项, "
                     f"enhanced={len(data['enhanced'])}项")
                return data
    except (json.JSONDecodeError, AttributeError) as e:
        _log("WARN", f"{tag}[评分] JSON 解析失败: {e}")

    _log("WARN", f"{tag}[评分] 无法解析评分结果，使用默认分数({DEFAULT_SCORE})")
    if raw_output:
        _log("DEBUG", f"{tag}[评分] 原始输出(前200字符): {raw_output[:200]}")
    default = [
        {"name": r["name"], "score": DEFAULT_SCORE, "reason": "解析失败"}
        for r in rubric
    ]
    return {"baseline": default, "enhanced": default}
