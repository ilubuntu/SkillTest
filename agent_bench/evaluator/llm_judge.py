# -*- coding: utf-8 -*-
"""LLM Judge 评分模块

职责：
- 接收 rubric + 代码对，调用 LLM 按维度打分
- 返回 LLMScoringResult（基线 + 增强各一份）

设计原则：
- 通过 llm_fn: Callable[[str, str], str] 注入 LLM 调用能力
- 不依赖任何具体 Agent 实现（OpenCode / Cursor 等）
- parse 失败时 fallback = DEFAULT_SCORE，不抛异常
"""

import json
import re
from typing import Callable, Dict, List, Optional

from .models import LLMDimensionScore, LLMScoringResult

DEFAULT_SCORE = 50

JUDGE_PROMPT = """你是一个严格的代码评审专家，请对以下ArkTS代码按评分维度打分。

## 原始代码（任务输入）
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

请分别对代码A（基线）和代码B（增强）的每个维度打分（0-100整数），返回严格的JSON，不要包含其他内容：
{{"baseline": [{{"name": "维度名", "score": 分数, "reason": "评分理由"}}], "enhanced": [{{"name": "维度名", "score": 分数, "reason": "评分理由"}}]}}
"""


class LLMJudge:
    """LLM 评分器

    llm_fn 签名：(prompt: str, tag: str) -> str
    """

    def __init__(self, llm_fn: Callable[[str, str], str],
                 on_progress=None):
        self.llm_fn = llm_fn
        self.on_progress = on_progress

    def _log(self, level: str, message: str):
        if self.on_progress:
            self.on_progress("log", {"level": level, "message": message})

    def judge(self,
              input_code: str,
              baseline_code: str,
              enhanced_code: str,
              reference_code: str,
              rubric: List[Dict],
              case_id: str = "",
              case_dir: str = None) -> Dict[str, LLMScoringResult]:
        """对 baseline 和 enhanced 同时评分

        Args:
            input_code: 原始代码（任务输入）
            baseline_code: 基线 Agent 输出
            enhanced_code: 增强 Agent 输出
            reference_code: 参考答案
            rubric: 评分维度列表 [{name, weight, criteria}, ...]
            case_id: 用于日志前缀

        Returns:
            {"baseline": LLMScoringResult, "enhanced": LLMScoringResult}
        """
        tag = f"[{case_id}]" if case_id else ""
        fallback = self._make_fallback(rubric, "Agent无输出", score=0)

        if not baseline_code.strip() and not enhanced_code.strip():
            self._log("WARN", f"{tag} 基线和增强输出均为空，跳过 LLM 评分")
            return {"baseline": fallback, "enhanced": fallback}

        rubric_text = "\n".join(
            f"- {r['name']}（权重{r['weight']}%）：{r['criteria']}"
            for r in rubric
        )
        dim_names = ", ".join(r["name"] for r in rubric)
        self._log("INFO", f"{tag}[评分] 构建评分 Prompt，维度：{dim_names}")

        prompt = JUDGE_PROMPT.format(
            input_code=input_code,
            reference_code=reference_code,
            baseline_code=baseline_code or "// 无输出",
            enhanced_code=enhanced_code or "// 无输出",
            rubric_text=rubric_text,
        )
        self._log("DEBUG", f"{tag}[评分] Prompt 长度={len(prompt)}字符")

        if case_dir:
            import os
            judge_dir = os.path.join(case_dir, "llm_judge")
            os.makedirs(judge_dir, exist_ok=True)
            with open(os.path.join(judge_dir, "prompt.txt"), "w", encoding="utf-8") as f:
                f.write(prompt)

        try:
            raw = self.llm_fn(prompt, f"{tag}[评分] ")
            if not raw:
                self._log("ERROR", f"{tag}[评分] LLM 返回空结果")
                fb = self._make_fallback(rubric, "LLM返回为空")
                return {"baseline": fb, "enhanced": fb}

            raw_scores = _parse_scores(raw, rubric, self.on_progress, tag)
            result = {
                side: _build_result(raw_scores[side], rubric)
                for side in ("baseline", "enhanced")
            }

            for side, label in [("baseline", "基线"), ("enhanced", "增强")]:
                for d in result[side].dimensions:
                    self._log("DEBUG",
                        f"{tag}[评分] {label} [{d.name}] = {d.score} — {d.reason[:60]}")

            return result

        except Exception as e:
            self._log("ERROR", f"{tag}[评分] LLM 评分异常: {e}")
            fb = self._make_fallback(rubric, "评分失败")
            return {"baseline": fb, "enhanced": fb}

    def _make_fallback(self, rubric: List[Dict],
                       reason: str, score: int = DEFAULT_SCORE) -> LLMScoringResult:
        dims = [
            LLMDimensionScore(
                name=r["name"], score=score,
                weight=r.get("weight", 20), reason=reason,
            )
            for r in rubric
        ]
        return LLMScoringResult(dimensions=dims, weighted_avg=float(score))


# ── 内部解析工具 ──────────────────────────────────────────────

def _parse_scores(raw_output: str, rubric: List[Dict],
                  on_progress=None, tag: str = "") -> Dict:
    """解析 LLM 输出的 JSON，失败时返回 fallback"""
    def _log(level, msg):
        if on_progress:
            on_progress("log", {"level": level, "message": msg})

    try:
        m = re.search(r'\{[\s\S]*"baseline"[\s\S]*"enhanced"[\s\S]*\}', raw_output)
        if m:
            data = json.loads(m.group())
            if "baseline" in data and "enhanced" in data:
                _log("DEBUG", f"{tag}[评分] JSON 解析成功")
                return data
    except (json.JSONDecodeError, AttributeError) as e:
        _log("WARN", f"{tag}[评分] JSON 解析失败: {e}")

    _log("WARN", f"{tag}[评分] 无法解析，使用默认分数({DEFAULT_SCORE})")
    if raw_output:
        _log("DEBUG", f"{tag}[评分] 原始输出前200字符: {raw_output[:200]}")

    fallback_dims = [{"name": r["name"], "score": DEFAULT_SCORE, "reason": "解析失败"}
                     for r in rubric]
    return {"baseline": fallback_dims, "enhanced": fallback_dims}


def _build_result(raw_dims: List[Dict], rubric: List[Dict]) -> LLMScoringResult:
    """将解析后的原始 dict 列表转为 LLMScoringResult"""
    rubric_map = {r["name"]: r for r in rubric}
    dims = []
    total_weight = 0.0
    weighted_sum = 0.0

    for item in raw_dims:
        name = item.get("name", "")
        score = float(item.get("score", DEFAULT_SCORE))
        score = max(0.0, min(100.0, score))
        weight = float(rubric_map.get(name, {}).get("weight", 20))
        dims.append(LLMDimensionScore(
            name=name,
            score=score,
            weight=weight,
            reason=item.get("reason", ""),
        ))
        weighted_sum += score * weight
        total_weight += weight

    weighted_avg = (weighted_sum / total_weight) if total_weight > 0 else DEFAULT_SCORE
    return LLMScoringResult(
        dimensions=dims,
        weighted_avg=round(weighted_avg, 2),
    )
