# -*- coding: utf-8 -*-
"""评分聚合器

职责：
- 将内部评分（InternalScoringResult）和 LLM 评分（LLMScoringResult）合并
- 实施互斥原则：某方未覆盖某维度时，该方自动获得该维度满分
- 支持分阶段权重（phase weights）

最终评分公式：
    final = LLM Judge得分(70%) + 内部评分系统得分(30%)

其中：
  - LLM Judge得分 = 按 rubric 权重计算的加权平均分（0-100）
  - 内部评分系统得分 = adjusted_internal_total / 30 * 100（已处理互斥原则）

互斥原则：
  - 内部评分未定义某维度 → 该维度 internal 计为该维度满分
  - LLM 未返回某维度    → 该维度 LLM 计为 100 分

设计原则：
  - 纯函数，无 I/O，无副作用
"""

from typing import Dict, List

from .models import InternalScoringResult, LLMScoringResult

# 默认阶段权重
# LLM Judge: 70%, 内部评分系统: 30%
DEFAULT_WEIGHTS = {"rubric": 0.7, "internal": 0.3}


def compute(
    internal: InternalScoringResult,
    llm: LLMScoringResult,
    all_dimension_names: List[str],
    weights: Dict[str, float] = None,
) -> float:
    """计算单份代码的最终评分

    Args:
        internal: 内部评分结果
        llm: LLM 评分结果
        all_dimension_names: 完整维度列表（来自 rubric）
        weights: 阶段权重 dict，key 为 rubric/internal/code_quality

    Returns:
        最终评分 float，范围 0-100
    """
    weights = weights or DEFAULT_WEIGHTS

    # ── 内部评分调整（互斥原则）──────────────────────────────
    n_dims = len(all_dimension_names) or 5
    base = 30.0 / n_dims

    adjusted_total = 0.0
    for dim in all_dimension_names:
        if dim in internal.dimensions:
            adjusted_total += internal.dimensions[dim].raw_score
        else:
            # 内部未定义该维度 → 该维度得满分
            adjusted_total += base

    internal_pct = min(adjusted_total / 30.0, 1.0) * 100.0

    # ── LLM 评分调整（互斥原则）──────────────────────────────
    llm_by_name = {d.name: d.score for d in llm.dimensions}
    total_weight = 0.0
    weighted_sum = 0.0

    # 以全量维度为基准计算加权平均（缺失维度按满分 100 计入）
    rubric_weights = {d.name: d.weight for d in llm.dimensions}
    for dim in all_dimension_names:
        w = rubric_weights.get(dim, 100.0 / n_dims)   # fallback 权重均分
        s = llm_by_name.get(dim, 100.0)               # 互斥：缺失得满分
        weighted_sum += s * w
        total_weight += w

    llm_avg = (weighted_sum / total_weight) if total_weight > 0 else 100.0

    # ── 合并 ─────────────────────────────────────────────────
    # LLM Judge: 70%, 内部评分系统: 30%
    rubric_w = weights.get("rubric", 0.7)
    internal_w = weights.get("internal", 0.3)

    final = rubric_w * llm_avg + internal_w * internal_pct
    return round(min(max(final, 0.0), 100.0), 2)


def compute(
    internal: InternalScoringResult,
    llm: LLMScoringResult,
    rubric_dimensions,
    weights: Dict[str, float] = None,
) -> float:
    """璁＄畻鍗曚唤浠ｇ爜鐨勬渶缁堣瘎鍒嗭紝鍏煎 rubric 缁村害 dict 鎴栨棫鐗?name 鍒楄〃"""
    weights = weights or DEFAULT_WEIGHTS

    if rubric_dimensions and isinstance(rubric_dimensions[0], dict):
        normalized_dimensions = rubric_dimensions
    else:
        normalized_dimensions = [
            {"dimension_id": dim_name, "name": dim_name}
            for dim_name in (rubric_dimensions or [])
        ]

    n_dims = len(normalized_dimensions) or 5
    base = 30.0 / n_dims

    adjusted_total = 0.0
    for dim in normalized_dimensions:
        internal_key = dim.get("dimension_id") or dim.get("name")
        fallback_key = dim.get("name") or internal_key
        if internal_key in internal.dimensions:
            adjusted_total += internal.dimensions[internal_key].raw_score
        elif fallback_key in internal.dimensions:
            adjusted_total += internal.dimensions[fallback_key].raw_score
        else:
            adjusted_total += base

    internal_pct = min(adjusted_total / 30.0, 1.0) * 100.0

    llm_by_name = {d.name: d.score for d in llm.dimensions}
    rubric_weights = {d.name: d.weight for d in llm.dimensions}
    total_weight = 0.0
    weighted_sum = 0.0

    for dim in normalized_dimensions:
        llm_key = dim.get("name") or dim.get("dimension_id")
        w = rubric_weights.get(llm_key, 100.0 / n_dims)
        s = llm_by_name.get(llm_key, 100.0)
        weighted_sum += s * w
        total_weight += w

    llm_avg = (weighted_sum / total_weight) if total_weight > 0 else 100.0

    rubric_w = weights.get("rubric", 0.7)
    internal_w = weights.get("internal", 0.3)
    final = rubric_w * llm_avg + internal_w * internal_pct
    return round(min(max(final, 0.0), 100.0), 2)
