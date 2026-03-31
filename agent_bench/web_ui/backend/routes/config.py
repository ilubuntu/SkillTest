# -*- coding: utf-8 -*-
"""配置查询路由 — profiles, scenarios, cascader options"""

from typing import List, Dict

from fastapi import APIRouter

from agent_bench.pipeline.loader import (
    list_all_profiles, load_profile, load_test_cases,
    load_test_cases_registry, resolve_scenario_id_to_name,
)
from backend.models import ProfileInfo, ScenarioInfo

router = APIRouter(prefix="/api", tags=["config"])


def _load_profiles() -> List[ProfileInfo]:
    """从 pipeline/loader 加载所有 Profile"""
    results = []
    for name in list_all_profiles():
        data = load_profile(name)
        # 将 scenario_ids 转换为场景名称
        scenario_ids = data.get("scenario_ids", [])
        scenario_names = []
        for sid in scenario_ids:
            sname = resolve_scenario_id_to_name(sid)
            if sname:
                scenario_names.append(sname)
        results.append(ProfileInfo(
            id=data.get("id", ""),
            name=data.get("name", name),
            description=data.get("description", ""),
            scenarios=scenario_names,
        ))
    return results


def _load_scenarios() -> List[ScenarioInfo]:
    """从 test_cases.yaml registry 加载场景信息"""
    registry = load_test_cases_registry()
    scenarios = []

    for s in registry.get("scenarios", []):
        scenario_name = s.get("name", s.get("id", ""))
        # 通过场景名获取用例数
        cases = load_test_cases(scenario_name)
        scenarios.append(ScenarioInfo(
            name=scenario_name,
            description=s.get("description", f"{scenario_name} 场景"),
            case_count=len(cases),
        ))

    return scenarios


def _build_cascader_options() -> List[Dict]:
    """构建前端级联选择器数据：场景 → 用例"""
    registry = load_test_cases_registry()
    options = []
    for scenario_entry in registry.get("scenarios", []):
        scenario = scenario_entry.get("name", scenario_entry.get("id", ""))
        cases = load_test_cases(scenario)
        children = [
            {
                "value": c.get("id", ""),
                "label": f"{c.get('id', '')} - {c.get('title', '')}",
            }
            for c in cases
            if c.get("id")
        ]
        if children:
            options.append({
                "value": scenario,
                "label": scenario,
                "children": children,
            })
    return options


# ── 缓存（lifespan 时初始化） ────────────────────────────────
_cache = {
    "profiles": [],
    "scenarios": [],
    "cascader_options": [],
}


def init_cache():
    """应用启动时调用，加载配置数据"""
    _cache["profiles"] = _load_profiles()
    _cache["scenarios"] = _load_scenarios()
    _cache["cascader_options"] = _build_cascader_options()


# ── 路由 ──────────────────────────────────────────────────────

@router.get("/profiles", response_model=List[ProfileInfo])
async def get_profiles():
    return _cache["profiles"]


@router.get("/scenarios", response_model=List[ScenarioInfo])
async def get_scenarios():
    return _cache["scenarios"]


@router.get("/cascader-options")
async def get_cascader_options():
    return _cache["cascader_options"]
