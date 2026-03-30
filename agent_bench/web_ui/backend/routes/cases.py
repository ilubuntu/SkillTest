# -*- coding: utf-8 -*-
"""用例查询路由 — 从 test_cases.yaml 加载真实用例数据"""

import os
from typing import List

from fastapi import APIRouter

from agent_bench.pipeline.loader import (
    BASE_DIR, load_test_cases_registry, load_file,
)

router = APIRouter(prefix="/api", tags=["cases"])

SCENARIO_COLORS = {
    "Bug Fix": "#e74c3c",
    "Code Compile": "#2ecc71",
    "Performance": "#f39c12",
    "Project Gen": "#3498db",
    "General": "#95a5a6",
    "Multimodal": "#e67e22",
    "Code Refactor": "#9b59b6",
    "Requirement": "#34495e",
    "Test Gen": "#1abc9c",
}


def _load_all_cases() -> tuple:
    """从 test_cases.yaml 加载所有用例，返回 (cases, scenarios)"""
    registry = load_test_cases_registry()
    all_cases = []
    scenarios = []

    for s in registry.get("scenarios", []):
        scenario_name = s.get("name", s.get("id", ""))
        raw_cases = s.get("cases", [])

        scenarios.append({
            "name": scenario_name,
            "label": scenario_name,
            "count": len(raw_cases),
            "color": SCENARIO_COLORS.get(scenario_name, "#999"),
            "difficulty": s.get("difficulty", "medium"),
            "tags": s.get("tags", []),
        })

        for c in raw_cases:
            case_id = c.get("case_id", c.get("id", ""))
            input_file = c.get("input_file", "")
            expected_file = c.get("expected_file", "")

            input_code = ""
            if input_file:
                try:
                    input_code = load_file(input_file)
                except Exception:
                    input_code = f"(文件不存在: {input_file})"

            reference_code = ""
            if expected_file:
                try:
                    reference_code = load_file(expected_file)
                except Exception:
                    reference_code = f"(文件不存在: {expected_file})"

            all_cases.append({
                "id": case_id,
                "title": c.get("title", ""),
                "scenario": scenario_name,
                "category": c.get("category", ""),
                "difficulty": s.get("difficulty", "medium"),
                "tags": s.get("tags", []),
                "prompt": c.get("prompt", ""),
                "input_code": input_code,
                "input_file": input_file,
                "reference_code": reference_code,
                "expected_file": expected_file,
            })

    return all_cases, scenarios


@router.get("/cases")
async def get_cases():
    cases, _ = _load_all_cases()
    return cases


@router.get("/cases/scenarios")
async def get_case_scenarios():
    _, scenarios = _load_all_cases()
    return scenarios


@router.get("/cases/{case_id}")
async def get_case_detail(case_id: str):
    cases, _ = _load_all_cases()
    for c in cases:
        if c["id"] == case_id:
            return c
    return {"error": "用例不存在"}
