# -*- coding: utf-8 -*-
"""评分计算

职责：
- 综合评分计算（规则分 + LLM 维度加权分）
"""


def compute_total(rule_score: float, llm_scores: list, rubric: list,
                  rule_weight: float = 0.3, llm_weight: float = 0.7) -> float:
    """综合评分 = 规则分 × rule_weight + LLM 维度加权分 × llm_weight

    Args:
        rule_score: 规则检查得分
        llm_scores: LLM 评分列表 [{"name": str, "score": float}, ...]
        rubric: 评分维度配置 [{"name": str, "weight": float}, ...]
        rule_weight: 规则分权重（默认 0.3）
        llm_weight: LLM 分权重（默认 0.7）

    Returns:
        综合得分（保留 1 位小数）
    """
    llm_weighted = 0
    total_weight = 0
    for rubric_item in rubric:
        name = rubric_item["name"]
        weight = rubric_item["weight"]
        score = next(
            (s["score"] for s in llm_scores if s["name"] == name), 50
        )
        llm_weighted += score * weight
        total_weight += weight

    llm_avg = llm_weighted / total_weight if total_weight > 0 else 50
    return round(rule_weight * rule_score + llm_weight * llm_avg, 1)
