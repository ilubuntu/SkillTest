# -*- coding: utf-8 -*-
"""评分计算

职责：
- 综合评分计算（LLM维度加权分 + 内部评分系统得分）
- 内部评分系统占总分的30%（30分）
"""


def compute_total(llm_scores: list, rubric: list,
                  internal_detail: dict = None,
                  llm_weight: float = 0.7) -> float:
    """综合评分 = LLM Judge得分×70% + 内部评分系统得分×30%
    
    Args:
        llm_scores: LLM评分结果（各维度分数，0-100）
        rubric: 评分标准（维度权重）
        internal_detail: 内部评分系统详细结果（按维度分类）
        llm_weight: LLM Judge权重（默认70%）
    
    Returns:
        综合得分（0-100，保留1位小数）
    """
    llm_weighted = 0
    total_rubric_weight = 0
    for rubric_item in rubric:
        name = rubric_item["name"]
        weight = rubric_item["weight"]
        score = next(
            (s["score"] for s in llm_scores if s["name"] == name), 0
        )
        llm_weighted += score * weight
        total_rubric_weight += weight
    
    llm_score = llm_weighted / total_rubric_weight if total_rubric_weight > 0 else 0
    
    internal_score = calculate_internal_score(internal_detail, rubric)
    
    final_score = llm_weight * llm_score + internal_score
    
    return round(min(max(final_score, 0), 100), 1)


def calculate_internal_score(internal_detail: dict = None, rubric: list = None) -> float:
    """计算内部评分系统得分
    
    内部评分系统占总分的30%（30分）
    维度分数 = 30 / 维度数（维度数与评分标准rubric一致）
    各维度内按规则级别（HIGH50%/MEDIUM30%/LOW20%）分配分数
    """
    if not rubric:
        return 30.0
    
    total_internal_score = 30.0
    
    rubric_dimensions = [item["name"] for item in rubric]
    dimension_count = len(rubric_dimensions)
    
    if dimension_count == 0:
        return total_internal_score
    
    per_dimension_score = total_internal_score / dimension_count
    level_weights = {"HIGH": 0.5, "MEDIUM": 0.3, "LOW": 0.2}
    
    total_score = 0.0
    
    for dim_name in rubric_dimensions:
        dim_key = dim_name
        
        if not internal_detail:
            total_score += per_dimension_score
            continue
        
        if dim_key not in internal_detail:
            total_score += per_dimension_score
            continue
        
        dim_rules = internal_detail[dim_key].get("rules", [])
        if not dim_rules:
            total_score += per_dimension_score
            continue
        
        level_totals = {"HIGH": 0.0, "MEDIUM": 0.0, "LOW": 0.0}
        for rule in dim_rules:
            level = rule.get("level", "MEDIUM")
            if level in level_weights:
                level_totals[level] += level_weights[level]
        
        dim_score = 0.0
        for rule in dim_rules:
            level = rule.get("level", "MEDIUM")
            level_weight = level_weights.get(level, 0.3)
            rule_weight_in_level = level_weight / level_totals[level] if level_totals[level] > 0 else 0
            
            if rule.get("passed", False):
                dim_score += per_dimension_score * rule_weight_in_level
        
        total_score += dim_score
    
    return round(min(max(total_score, 0), 30.0), 1)
