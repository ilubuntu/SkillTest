# -*- coding: utf-8 -*-
"""评分聚合器。

职责：
- 将内部评分（InternalScoringResult）和 LLM 评分（LLMScoringResult）合并
- 实施互斥原则：某方未覆盖某维度时，该方自动获得该维度满分
- 支持分阶段权重（phase weights）
"""

from typing import Dict, List

from .models import InternalScoringResult, LLMScoringResult

DEFAULT_WEIGHTS = {"rubric": 0.7, "internal": 0.3}


def _normalize_dimensions(rubric_dimensions) -> List[dict]:
    """兼容 rubric dict 列表和旧 name 列表。"""
    normalized = []
    for item in rubric_dimensions or []:
        if isinstance(item, dict):
            normalized.append({
                "dimension_id": item.get("dimension_id") or item.get("name"),
                "name": item.get("name") or item.get("dimension_id"),
            })
        else:
            normalized.append({
                "dimension_id": item,
                "name": item,
            })
    return normalized


def compute(
    internal: InternalScoringResult,
    llm: LLMScoringResult,
    rubric_dimensions,
    weights: Dict[str, float] = None,
) -> float:
    """计算单份代码的最终评分，范围 0-100。"""
    weights = weights or DEFAULT_WEIGHTS
    normalized_dimensions = _normalize_dimensions(rubric_dimensions)

    n_dims = len(normalized_dimensions) or 5
    base = 30.0 / n_dims

    adjusted_total = 0.0
    for dim in normalized_dimensions:
        internal_key = dim.get("dimension_id")
        fallback_key = dim.get("name")
        if internal_key in internal.dimensions:
            adjusted_total += internal.dimensions[internal_key].raw_score
        elif fallback_key in internal.dimensions:
            adjusted_total += internal.dimensions[fallback_key].raw_score
        else:
            adjusted_total += base

    internal_pct = min(adjusted_total / 30.0, 1.0) * 100.0

    llm_by_name = {d.name: d.score for d in llm.dimensions}
    llm_weights = {d.name: d.weight for d in llm.dimensions}
    total_weight = 0.0
    weighted_sum = 0.0

    for dim in normalized_dimensions:
        llm_key = dim.get("name") or dim.get("dimension_id")
        weight = llm_weights.get(llm_key, 100.0 / n_dims)
        score = llm_by_name.get(llm_key, 100.0)
        weighted_sum += score * weight
        total_weight += weight

    llm_avg = (weighted_sum / total_weight) if total_weight > 0 else 100.0

    rubric_weight = weights.get("rubric", 0.7)
    internal_weight = weights.get("internal", 0.3)
    final = rubric_weight * llm_avg + internal_weight * internal_pct
    return round(min(max(final, 0.0), 100.0), 2)
