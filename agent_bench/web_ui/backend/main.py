import os
import sys
import yaml
import json
from pathlib import Path
from typing import List, Dict
from contextlib import asynccontextmanager

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse, HTMLResponse
from fastapi.staticfiles import StaticFiles
from sse_starlette.sse import EventSourceResponse

BASE_DIR = Path(__file__).parent.parent.parent
sys.path.insert(0, str(Path(__file__).parent.parent))
sys.path.insert(0, str(BASE_DIR))

from backend.models import (
    ProfileInfo, ScenarioInfo, EvaluationConfig,
    EvaluationStatus, EvaluationProgress, CascaderOption
)
from backend.evaluator import evaluator_manager


def load_profiles() -> List[ProfileInfo]:
    profiles_dir = BASE_DIR / "profiles"
    profiles = []
    
    for f in profiles_dir.glob("*.yaml"):
        try:
            with open(f, "r", encoding="utf-8") as fp:
                data = yaml.safe_load(fp)
                profiles.append(ProfileInfo(
                    name=data.get("name", f.stem),
                    description=data.get("description", ""),
                    scenarios=data.get("scenarios", [])
                ))
        except Exception:
            continue
    
    return profiles


def load_scenarios() -> List[ScenarioInfo]:
    test_cases_dir = BASE_DIR / "test_cases"
    scenarios = []
    
    scenario_descriptions = {
        "project_gen": "工程生成场景：测试Agent生成完整HarmonyOS项目的能力",
        "compilable": "可编译场景：测试Agent生成无编译错误代码的能力",
        "performance": "性能优化场景：测试Agent优化List和Swiper组件性能的能力",
        "bug_fix": "Bug修复场景：测试Agent修复代码bug的能力",
        "refactor": "重构场景：测试Agent重构代码的能力",
        "test_gen": "测试生成场景：测试Agent生成单元测试的能力",
        "requirement": "需求分析场景：测试Agent理解需求的能力",
    }
    
    for scenario_dir in test_cases_dir.iterdir():
        if scenario_dir.is_dir():
            case_count = len(list(scenario_dir.glob("*.yaml"))) + len(list(scenario_dir.glob("*.yml")))
            scenarios.append(ScenarioInfo(
                name=scenario_dir.name,
                description=scenario_descriptions.get(scenario_dir.name, f"{scenario_dir.name}场景"),
                case_count=case_count
            ))
    
    return scenarios


def build_cascader_options(profiles: List[ProfileInfo]) -> List[Dict]:
    scenario_profile_map: Dict[str, List[ProfileInfo]] = {}
    
    for profile in profiles:
        for scenario_name in profile.scenarios:
            if scenario_name not in scenario_profile_map:
                scenario_profile_map[scenario_name] = []
            scenario_profile_map[scenario_name].append(profile)
    
    options = []
    for scenario_name, profiles_list in sorted(scenario_profile_map.items()):
        children = [
            {
                "value": p.name,
                "label": p.name
            }
            for p in profiles_list
        ]
        if children:
            options.append({
                "value": scenario_name,
                "label": scenario_name,
                "children": children
            })
    
    return options


@asynccontextmanager
async def lifespan(app: FastAPI):
    app.state.profiles = load_profiles()
    app.state.scenarios = load_scenarios()
    app.state.cascader_options = build_cascader_options(app.state.profiles)
    yield


app = FastAPI(
    title="鸿蒙开发工具评测系统",
    description="评测HarmonyOS开发工具的Skill、MCP和System Prompt能力",
    version="1.0.0",
    lifespan=lifespan
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/api/profiles", response_model=List[ProfileInfo])
async def get_profiles():
    return app.state.profiles


@app.get("/api/scenarios", response_model=List[ScenarioInfo])
async def get_scenarios():
    return app.state.scenarios


@app.get("/api/cascader-options")
async def get_cascader_options():
    return app.state.cascader_options


@app.post("/api/evaluation/start")
async def start_evaluation(config: EvaluationConfig):
    if evaluator_manager.get_progress().status == EvaluationStatus.RUNNING:
        raise HTTPException(status_code=400, detail="评测正在进行中")
    
    success, message = evaluator_manager.start_evaluation(
        config.profiles,
        config.scenarios
    )
    
    if not success:
        raise HTTPException(status_code=400, detail=message)
    
    return {"status": "started", "message": message}


@app.post("/api/evaluation/stop")
async def stop_evaluation():
    success, message = evaluator_manager.stop_evaluation()
    
    if not success:
        raise HTTPException(status_code=400, detail=message)
    
    return {"status": "stopped", "message": message}


@app.get("/api/evaluation/status", response_model=EvaluationProgress)
async def get_status():
    return evaluator_manager.get_progress()


@app.get("/api/evaluation/logs")
async def stream_logs():
    async def event_generator():
        log_queue = evaluator_manager.get_log_queue()
        while True:
            try:
                log = log_queue.get(timeout=30)
                yield {
                    "event": "log",
                    "data": log.model_dump_json()
                }
            except:
                yield {
                    "event": "ping",
                    "data": ""
                }
    
    return EventSourceResponse(event_generator())


dist_dir = Path(__file__).parent.parent / "frontend" / "dist"
if dist_dir.exists():
    @app.get("/")
    async def root():
        return FileResponse(str(dist_dir / "index.html"))
    
    app.mount("/assets", StaticFiles(directory=str(dist_dir / "assets")), name="assets")
else:
    frontend_dir = Path(__file__).parent.parent / "frontend"
    if frontend_dir.exists():
        @app.get("/")
        async def root():
            return FileResponse(str(frontend_dir / "index.html"))


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=5177)
