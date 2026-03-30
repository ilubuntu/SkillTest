# -*- coding: utf-8 -*-
"""内部评分系统

职责：
- 加载 config/internal_rules.yaml 中的全局规则
- 对代码文本按维度进行确定性（正则匹配）评分
- 返回 InternalScoringResult

设计原则：
- 纯函数，无 I/O，无副作用
- 不依赖 LLM、不依赖任何 pipeline 模块
- 规则未匹配到内容（match 为空）→ 默认通过
"""

import re
from typing import Dict, List

from .models import RuleResult, DimensionInternalScore, InternalScoringResult

# 规则级别在维度内的权重占比
LEVEL_WEIGHTS: Dict[str, float] = {
    "HIGH":   0.5,
    "MEDIUM": 0.3,
    "LOW":    0.2,
}

# 内部评分系统总分上限
INTERNAL_MAX = 30.0


def score(code: str, rules_config: Dict[str, list],
          file_ext: str = ".ets") -> InternalScoringResult:
    """对一份代码进行内部评分

    Args:
        code: 待评分的代码文本
        rules_config: 已加载的 internal_rules.yaml 内容（dict）
        file_ext: 文件扩展名，用于 file_types 过滤

    Returns:
        InternalScoringResult
    """
    dimensions = [k for k in rules_config if isinstance(rules_config[k], list)]
    n_dims = len(dimensions) or 1
    base_score = INTERNAL_MAX / n_dims   # 每维度基础分，5维度时 = 6.0

    dim_scores: Dict[str, DimensionInternalScore] = {}
    total_raw = 0.0

    for dim_name in dimensions:
        rules = rules_config[dim_name]

        # 按 level 分组
        by_level: Dict[str, list] = {"HIGH": [], "MEDIUM": [], "LOW": []}
        for r in rules:
            lvl = r.get("level", "MEDIUM").upper()
            by_level.setdefault(lvl, []).append(r)

        raw_score = 0.0
        rule_results: List[RuleResult] = []

        active_by_level: Dict[str, list] = {}
        for level, level_rules in by_level.items():
            active = [r for r in level_rules
                      if not r.get("file_types") or file_ext in r["file_types"]]
            if active:
                active_by_level[level] = active

        total_weight = sum(LEVEL_WEIGHTS.get(l, 0.2) for l in active_by_level)

        for level, active_rules in active_by_level.items():
            normalized_weight = LEVEL_WEIGHTS.get(level, 0.2) / total_weight if total_weight > 0 else 0
            level_budget = base_score * normalized_weight
            per_rule = level_budget / len(active_rules)

            for r in active_rules:
                pattern = r.get("pattern", "")
                pass_on_match = r.get("pass_on_match", True)

                matched_text = ""
                try:
                    m = re.search(pattern, code, re.MULTILINE)
                    matched = bool(m)
                    if m:
                        matched_text = m.group()[:100]
                except re.error:
                    matched = False

                if not matched:
                    passed = True
                else:
                    passed = pass_on_match

                earned = per_rule if passed else 0.0
                raw_score += earned

                rule_results.append(RuleResult(
                    name=r["name"],
                    level=level,
                    description=r.get("description", ""),
                    passed=passed,
                    matched=matched,
                    matched_text=matched_text,
                    max_score=round(per_rule, 2),
                    earned_score=round(earned, 2),
                ))

        # 归一化到 0-100
        normalized = (raw_score / base_score * 100.0) if base_score > 0 else 100.0

        dim_scores[dim_name] = DimensionInternalScore(
            dimension=dim_name,
            score=round(min(normalized, 100.0), 2),
            raw_score=round(raw_score, 2),
            max_score=round(base_score, 2),
            rules=rule_results,
        )
        total_raw += raw_score

    return InternalScoringResult(
        dimensions=dim_scores,
        total=round(min(total_raw, INTERNAL_MAX), 2),
    )
