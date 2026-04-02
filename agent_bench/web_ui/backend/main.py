# -*- coding: utf-8 -*-
"""Web UI FastAPI 入口

职责：应用创建、中间件、静态文件、路由注册。
不包含任何业务逻辑。
"""

import os
import sys
from pathlib import Path
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse
from fastapi.staticfiles import StaticFiles

# 统一设置 sys.path — 仅此一处
_BASE_DIR = Path(__file__).parent.parent.parent          # agent_bench/
_REPO_DIR = _BASE_DIR.parent                             # agent_bench 的父目录
sys.path.insert(0, str(Path(__file__).parent.parent))    # web_ui/  (backend 包)
sys.path.insert(0, str(_BASE_DIR))                       # agent_bench/
sys.path.insert(0, str(_REPO_DIR))                       # repo root

from backend.routes.config import router as config_router, init_cache
from backend.routes.evaluation import router as evaluation_router
from backend.routes.reports import router as reports_router
from backend.routes.cases import router as cases_router
from backend.routes.profiles import router as profiles_router
from backend.routes.agents import router as agents_router
from backend.routes.cloud_api import router as cloud_api_router


@asynccontextmanager
async def lifespan(app: FastAPI):
    init_cache()
    yield


app = FastAPI(
    title="鸿蒙开发工具评测系统",
    description="评测HarmonyOS开发工具的Skill、MCP和System Prompt能力",
    version="1.0.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── 路由 ──────────────────────────────────────────────────────
app.include_router(config_router)
app.include_router(evaluation_router)
app.include_router(reports_router)
app.include_router(cases_router)
app.include_router(profiles_router)
app.include_router(agents_router)
app.include_router(cloud_api_router)

# ── 静态文件（前端 dist） ─────────────────────────────────────
_dist_dir = Path(__file__).parent.parent / "frontend" / "dist"
if _dist_dir.exists():
    @app.get("/")
    async def root():
        return FileResponse(str(_dist_dir / "index.html"))

    app.mount("/assets", StaticFiles(directory=str(_dist_dir / "assets")), name="assets")


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
