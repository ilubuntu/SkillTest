# -*- coding: utf-8 -*-
"""Constraint adapter for modern hybrid review.

Prepares hybrid constraints (AST + LLM) for the modern review flow.
Supports:
  - Modern format: rules -> target + ast + llm
  - Public constraints from constraint_refs.yaml
"""

from __future__ import annotations

import os
from copy import deepcopy
from typing import Any, Dict, List

import yaml


BASE_DIR = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
CONSTRAINT_REFS_DIR = os.path.join(BASE_DIR, "config", "skills", "constraint-score-review", "references")
CONSTRAINT_REFS_PATH = os.path.join(CONSTRAINT_REFS_DIR, "constraint_refs.yaml")

_public_constraints_cache: Dict[str, Any] = {}


def _load_public_constraints_config() -> Dict[str, Any]:
    """加载公共约束配置文件。"""
    if _public_constraints_cache:
        return _public_constraints_cache
    
    if not os.path.exists(CONSTRAINT_REFS_PATH):
        return {}
    
    with open(CONSTRAINT_REFS_PATH, "r", encoding="utf-8") as f:
        config = yaml.safe_load(f) or {}
    
    _public_constraints_cache["config"] = config
    
    imports = config.get("imports", [])
    all_refs: Dict[str, Any] = {}
    
    for import_file in imports:
        import_path = os.path.join(CONSTRAINT_REFS_DIR, import_file)
        if not os.path.exists(import_path):
            continue
        with open(import_path, "r", encoding="utf-8") as f:
            ref_data = yaml.safe_load(f) or {}
        refs = ref_data.get("refs", {})
        all_refs.update(refs)
    
    _public_constraints_cache["refs"] = all_refs
    return _public_constraints_cache


def get_public_constraints_for_scenario(scenario: str) -> List[Dict[str, Any]]:
    """根据场景获取公共约束列表。"""
    cache = _load_public_constraints_config()
    config = cache.get("config", {})
    all_refs = cache.get("refs", {})
    
    defaults = config.get("defaults", {})
    public_constraint_names = defaults.get(scenario) or []
    
    public_constraints: List[Dict[str, Any]] = []
    for name in public_constraint_names:
        ref_def = all_refs.get(name)
        if not ref_def:
            continue
        constraint = deepcopy(ref_def)
        constraint["id"] = f"HM-PUBLIC-{name}"
        constraint["is_public"] = True
        public_constraints.append(constraint)
    
    return public_constraints


def merge_constraints_with_public(case_constraints: List[Any], scenario: str) -> List[Any]:
    """合并 case 约束和公共约束。"""
    public_constraints = get_public_constraints_for_scenario(scenario)
    merged = list(case_constraints or [])
    merged.extend(public_constraints)
    return merged


def sanitize_constraints_for_semantic_review(constraints: List[Any]) -> List[Any]:
    """清理约束规则，转换为 LLM 可理解的格式。
    
    所有约束统一保留 rules 格式（与 case.yaml 一致），
    不再转换为 check_rules 格式。不输出 is_public 字段。
    """
    sanitized: List[Any] = []
    
    for item in constraints or []:
        if not isinstance(item, dict):
            continue
        
        clean_item = {
            "id": item.get("id", ""),
            "name": item.get("name", ""),
            "description": item.get("description", ""),
            "priority": item.get("priority", "P1"),
        }
        
        rules = item.get("rules", [])
        if rules and isinstance(rules, list):
            clean_item["rules"] = rules
        elif item.get("check_rules"):
            check_rules = item.get("check_rules")
            if isinstance(check_rules, list):
                clean_item["check_rules"] = check_rules
                clean_item["target_files"] = [r.get("target_file", "") for r in check_rules if isinstance(r, dict)]
        
        sanitized.append(clean_item)
    
    return sanitized


def sanitize_all_constraints_for_review(case_constraints: List[Any], scenario: str) -> List[Any]:
    """合并并清理所有约束（case约束 + 公共约束）。"""
    merged_constraints = merge_constraints_with_public(case_constraints, scenario)
    return sanitize_constraints_for_semantic_review(merged_constraints)


