# -*- coding: utf-8 -*-
"""评分数据模型

本模块只定义纯数据结构，不含任何业务逻辑。
"""

from dataclasses import dataclass, field
from typing import Dict, List, Optional


@dataclass
class RuleResult:
    """单条规则的执行结果"""
    name: str
    level: str          # HIGH | MEDIUM | LOW
    description: str
    passed: bool
    matched: bool       # 是否匹配到 pattern
    matched_text: str = ""  # 匹配到的代码片段
    max_score: float = 0.0  # 该规则满分
    earned_score: float = 0.0  # 该规则实际得分


@dataclass
class DimensionInternalScore:
    """内部评分系统中单个维度的得分"""
    dimension: str
    score: float        # 归一化分 0-100
    raw_score: float    # 原始得分（0 ~ max_score）
    max_score: float    # 该维度基础分 = 30 / 维度数
    rules: List[RuleResult] = field(default_factory=list)


@dataclass
class InternalScoringResult:
    """内部评分系统对一份代码的完整评分结果"""
    dimensions: Dict[str, DimensionInternalScore]
    total: float        # 各维度 raw_score 之和，上限 30


@dataclass
class LLMDimensionScore:
    """LLM Judge 对单个维度的评分"""
    name: str
    score: float        # 0-100
    weight: float       # 维度权重（来自 rubric）
    reason: str


@dataclass
class LLMScoringResult:
    """LLM Judge 对一份代码的完整评分结果"""
    dimensions: List[LLMDimensionScore]
    weighted_avg: float  # 按 rubric 权重计算的加权平均分 0-100


@dataclass
class CaseScoringResult:
    """单个用例的最终评分（包含内部 + LLM 两路）"""
    internal: InternalScoringResult
    llm: LLMScoringResult
    final_score: float   # 0-100
    passed: bool
