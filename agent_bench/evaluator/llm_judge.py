# -*- coding: utf-8 -*-
"""LLM Judge 评分模块

职责：
- 接收 rubric + 代码对，调用 LLM 按维度打分
- 返回 LLMScoringResult（基线 + 增强各一份）

设计原则：
- 通过 llm_fn: Callable[[str, str], str] 注入 LLM 调用能力
- 不依赖任何具体 Agent 实现（OpenCode / Cursor 等）
- LLM 调用失败、超时、解析失败均直接抛错，由流水线标记阶段失败
"""

import json
import os
import re
import ast
from typing import Callable, Dict, List, Optional

import yaml

from .models import LLMDimensionScore, LLMScoringResult

JUDGE_PROMPT = """你是一个严格的代码评审专家，请对以下ArkTS代码按评分维度打分。

## 任务说明
{task_context}

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

BASELINE_ONLY_JUDGE_PROMPT = """你是一个严格的代码评审专家，请对以下ArkTS代码按评分维度打分。

## 任务说明
{task_context}

## 代码A（基线输出）
```typescript
{baseline_code}
```

## 评分维度
{rubric_text}

请只对代码A（基线）的每个维度打分（0-100整数），返回严格的JSON，不要包含其他内容：
{{"baseline": [{{"name": "维度名", "score": 分数, "reason": "评分理由"}}]}}
"""


class LLMJudge:
    """LLM 评分器

    llm_fn 签名：(prompt: str, tag: str) -> str
    """

    def __init__(self, llm_fn: Callable[[str, str], str],
                 on_progress=None,
                 metrics_fn: Optional[Callable[[], Optional[dict]]] = None):
        self.llm_fn = llm_fn
        self.on_progress = on_progress
        self.metrics_fn = metrics_fn

    def _log(self, level: str, message: str):
        if self.on_progress:
            self.on_progress("log", {"level": level, "message": message})

    def judge(self,
              task_context: str,
              baseline_code: str,
              enhanced_code: str,
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
        if not baseline_code.strip() and not enhanced_code.strip():
            raise ValueError(f"{tag} 基线和增强输出均为空，无法执行 LLM 评分")

        rubric_text = "\n".join(
            f"- {r['name']}（权重{r['weight']}%）：{r['criteria']}"
            for r in rubric
        )
        dim_names = ", ".join(r["name"] for r in rubric)
        self._log("INFO", f"{tag}[评分] 构建评分 Prompt，维度：{dim_names}")

        prompt = JUDGE_PROMPT.format(
            task_context=task_context,
            baseline_code=baseline_code or "// 无输出",
            enhanced_code=enhanced_code or "// 无输出",
            rubric_text=rubric_text,
        )
        self._log("DEBUG", f"{tag}[评分] Prompt 长度={len(prompt)}字符")

        if case_dir:
            judge_dir = os.path.join(case_dir, "llm_judge")
            os.makedirs(judge_dir, exist_ok=True)
            with open(os.path.join(judge_dir, "prompt.txt"), "w", encoding="utf-8") as f:
                f.write(prompt)

        try:
            raw = self.llm_fn(prompt, f"{tag}[评分] ")
            self._save_metrics(case_dir)
            self._save_raw_output(case_dir, raw)
            if not raw:
                self._log("ERROR", f"{tag}[评分] LLM 返回空结果")
                raise RuntimeError(f"{tag}[评分] LLM 返回空结果")

            raw_scores = _parse_scores(raw, self.on_progress, tag)
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
            raise

    def judge_baseline(self,
                       task_context: str,
                       baseline_code: str,
                       rubric: List[Dict],
                       case_id: str = "",
                       case_dir: str = None) -> LLMScoringResult:
        """仅对 baseline 进行评分"""
        tag = f"[{case_id}]" if case_id else ""
        if not baseline_code.strip():
            raise ValueError(f"{tag} 基线输出为空，无法执行 LLM 评分")

        rubric_text = "\n".join(
            f"- {r['name']}（权重{r['weight']}%）：{r['criteria']}"
            for r in rubric
        )
        dim_names = ", ".join(r["name"] for r in rubric)
        self._log("INFO", f"{tag}[评分] 构建基线评分 Prompt，维度：{dim_names}")

        prompt = BASELINE_ONLY_JUDGE_PROMPT.format(
            task_context=task_context,
            baseline_code=baseline_code or "// 无输出",
            rubric_text=rubric_text,
        )
        self._log("DEBUG", f"{tag}[评分] Prompt 长度={len(prompt)}字符")

        if case_dir:
            judge_dir = os.path.join(case_dir, "llm_judge")
            os.makedirs(judge_dir, exist_ok=True)
            with open(os.path.join(judge_dir, "prompt.txt"), "w", encoding="utf-8") as f:
                f.write(prompt)

        try:
            raw = self.llm_fn(prompt, f"{tag}[评分] ")
            self._save_metrics(case_dir)
            self._save_raw_output(case_dir, raw)
            if not raw:
                self._log("ERROR", f"{tag}[评分] LLM 返回空结果")
                raise RuntimeError(f"{tag}[评分] LLM 返回空结果")

            raw_scores = _parse_baseline_scores(raw, self.on_progress, tag)
            result = _build_result(raw_scores["baseline"], rubric)

            for d in result.dimensions:
                self._log("DEBUG",
                    f"{tag}[评分] 基线 [{d.name}] = {d.score} — {d.reason[:60]}")

            return result

        except Exception as e:
            self._log("ERROR", f"{tag}[评分] LLM 评分异常: {e}")
            raise

    def _save_metrics(self, case_dir: str):
        if not case_dir or not self.metrics_fn:
            return
        metrics = self.metrics_fn()
        if not metrics:
            return
        judge_dir = os.path.join(case_dir, "llm_judge")
        os.makedirs(judge_dir, exist_ok=True)
        data = dict(metrics)
        data["source"] = "llm_judge"
        with open(os.path.join(judge_dir, "interaction_metrics.json"), "w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, indent=2)

    def _save_raw_output(self, case_dir: str, raw_output: str):
        if not case_dir:
            return
        judge_dir = os.path.join(case_dir, "llm_judge")
        os.makedirs(judge_dir, exist_ok=True)
        with open(os.path.join(judge_dir, "raw_output.txt"), "w", encoding="utf-8") as f:
            f.write(raw_output or "")


# ── 内部解析工具 ──────────────────────────────────────────────

def _parse_scores(raw_output: str,
                  on_progress=None, tag: str = "") -> Dict:
    """解析 LLM 输出的 JSON，失败时抛错"""
    def _log(level, msg):
        if on_progress:
            on_progress("log", {"level": level, "message": msg})

    try:
        m = re.search(r'\{[\s\S]*"baseline"[\s\S]*"enhanced"[\s\S]*\}', raw_output)
        if m:
            data = _load_loose_json(m.group())
            if "baseline" in data and "enhanced" in data:
                _log("DEBUG", f"{tag}[评分] JSON 解析成功")
                return data
    except (json.JSONDecodeError, AttributeError) as e:
        _log("ERROR", f"{tag}[评分] JSON 解析失败: {e}")
        raise ValueError(f"{tag}[评分] JSON 解析失败: {e}") from e
    except Exception as e:
        _log("ERROR", f"{tag}[评分] JSON 解析失败: {e}")
        raise ValueError(f"{tag}[评分] JSON 解析失败: {e}") from e

    if raw_output:
        fenced = _extract_first_object(raw_output)
        if fenced:
            try:
                data = _load_loose_json(fenced)
                if "baseline" in data and "enhanced" in data:
                    _log("DEBUG", f"{tag}[评分] 宽松 JSON 解析成功")
                    return data
            except Exception as e:
                _log("ERROR", f"{tag}[评分] 宽松 JSON 解析失败: {e}")
        _log("DEBUG", f"{tag}[评分] 原始输出前200字符: {raw_output[:200]}")
    raise ValueError(f"{tag}[评分] 无法解析评分结果 JSON")


def _parse_baseline_scores(raw_output: str,
                           on_progress=None, tag: str = "") -> Dict:
    """解析仅 baseline 的评分 JSON，失败时抛错"""
    def _log(level, msg):
        if on_progress:
            on_progress("log", {"level": level, "message": msg})

    try:
        m = re.search(r'\{[\s\S]*"baseline"[\s\S]*\}', raw_output)
        if m:
            data = _load_loose_json(m.group())
            if "baseline" in data:
                _log("DEBUG", f"{tag}[评分] Baseline JSON 解析成功")
                return data
    except (json.JSONDecodeError, AttributeError) as e:
        _log("ERROR", f"{tag}[评分] Baseline JSON 解析失败: {e}")
        raise ValueError(f"{tag}[评分] Baseline JSON 解析失败: {e}") from e
    except Exception as e:
        _log("ERROR", f"{tag}[评分] Baseline JSON 解析失败: {e}")
        raise ValueError(f"{tag}[评分] Baseline JSON 解析失败: {e}") from e

    if raw_output:
        fenced = _extract_first_object(raw_output)
        if fenced:
            try:
                data = _load_loose_json(fenced)
                if "baseline" in data:
                    _log("DEBUG", f"{tag}[评分] Baseline 宽松 JSON 解析成功")
                    return data
            except Exception as e:
                _log("ERROR", f"{tag}[评分] Baseline 宽松 JSON 解析失败: {e}")
        _log("DEBUG", f"{tag}[评分] 原始输出前200字符: {raw_output[:200]}")
    raise ValueError(f"{tag}[评分] 无法解析 baseline 评分结果 JSON")


def _extract_first_object(raw_output: str) -> str:
    m = re.search(r"\{[\s\S]*\}", raw_output)
    return m.group() if m else ""


def _load_loose_json(text: str):
    cleaned = text.strip()
    cleaned = re.sub(r"^```(?:json|javascript|js|typescript|ts)?\s*", "", cleaned, flags=re.IGNORECASE)
    cleaned = re.sub(r"\s*```$", "", cleaned)

    try:
        return json.loads(cleaned)
    except Exception:
        pass

    try:
        data = ast.literal_eval(cleaned)
        if isinstance(data, dict):
            return data
    except Exception:
        pass

    data = yaml.safe_load(cleaned)
    if isinstance(data, dict):
        return data
    raise ValueError("返回内容不是可解析的对象")


def _build_result(raw_dims: List[Dict], rubric: List[Dict]) -> LLMScoringResult:
    """将解析后的原始 dict 列表转为 LLMScoringResult"""
    default_score = 50.0
    rubric_map = {r["name"]: r for r in rubric}
    dims = []
    total_weight = 0.0
    weighted_sum = 0.0

    for item in raw_dims:
        name = item.get("name", "")
        score = float(item.get("score", default_score))
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

    weighted_avg = (weighted_sum / total_weight) if total_weight > 0 else default_score
    return LLMScoringResult(
        dimensions=dims,
        weighted_avg=round(weighted_avg, 2),
    )
