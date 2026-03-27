# -*- coding: utf-8 -*-
"""配置查询路由 — profiles, scenarios, cascader options"""

from typing import List, Dict

from fastapi import APIRouter

from agent_bench.pipeline.loader import (
    list_all_profiles, load_profile, load_test_cases,
)
from backend.models import ProfileInfo, ScenarioInfo

router = APIRouter(prefix="/api", tags=["config"])


def _load_profiles() -> List[ProfileInfo]:
    """从 pipeline/loader 加载所有 Profile"""
    results = []
    for name in list_all_profiles():
        data = load_profile(name)
        results.append(ProfileInfo(
            name=data.get("name", name),
            description=data.get("description", ""),
            scenarios=data.get("scenarios", []),
        ))
    return results


def _load_scenarios() -> List[ScenarioInfo]:
    """从 pipeline/loader 加载场景信息"""
    import os
    from agent_bench.pipeline.loader import BASE_DIR

    test_cases_dir = os.path.join(BASE_DIR, "test_cases")
    if not os.path.isdir(test_cases_dir):
        return []

    scenarios = []
    for entry in sorted(os.listdir(test_cases_dir)):
        entry_path = os.path.join(test_cases_dir, entry)
        if os.path.isdir(entry_path):
            cases = load_test_cases(entry)
            scenarios.append(ScenarioInfo(
                name=entry,
                description=f"{entry} 场景",
                case_count=len(cases),
            ))
    return scenarios


def _build_cascader_options(profiles: List[ProfileInfo]) -> List[Dict]:
    """构建前端级联选择器数据：场景 → Profile"""
    scenario_profiles: Dict[str, List[ProfileInfo]] = {}
    for p in profiles:
        for s in p.scenarios:
            scenario_profiles.setdefault(s, []).append(p)

    options = []
    for scenario, ps in sorted(scenario_profiles.items()):
        children = [{"value": p.name, "label": p.name} for p in ps]
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
    _cache["cascader_options"] = _build_cascader_options(_cache["profiles"])


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
