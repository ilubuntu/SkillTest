# -*- coding: utf-8 -*-
"""本地执行器 FastAPI 入口。"""

import logging
import os
import shutil
import sys
from datetime import datetime

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from agent_bench.executor.cloud_api import router as cloud_api_router
from agent_bench.pipeline.loader import validate_runtime_config
from agent_bench.runner.discovery import check_api_available, ensure_opencode_server


logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(message)s",
)
logging.getLogger("uvicorn.access").disabled = True
logger = logging.getLogger("agent_bench.executor")


def _runtime_root_dir() -> str:
    if getattr(sys, "frozen", False):
        return os.path.dirname(os.path.abspath(sys.executable))
    return os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))


def _prepare_runtime_log_file() -> str:
    root_dir = _runtime_root_dir()
    log_dir = os.path.join(root_dir, "logs")
    os.makedirs(log_dir, exist_ok=True)
    log_path = os.path.join(log_dir, f"agent_bench_{datetime.now().strftime('%Y%m%d_%H%M%S')}.log")
    current_path = os.path.join(log_dir, "current_executor_log")
    with open(current_path, "w", encoding="utf-8") as f:
        f.write(log_path)
    return log_path


def _attach_file_logger(log_path: str):
    root_logger = logging.getLogger()
    for handler in root_logger.handlers:
        if isinstance(handler, logging.FileHandler) and getattr(handler, "baseFilename", "") == log_path:
            return
    file_handler = logging.FileHandler(log_path, encoding="utf-8")
    file_handler.setLevel(logging.INFO)
    file_handler.setFormatter(logging.Formatter("%(asctime)s %(levelname)s %(message)s"))
    root_logger.addHandler(file_handler)


def _check_runtime_dependencies():
    logger.info("检查依赖...")
    if not shutil.which("opencode"):
        raise RuntimeError("缺少依赖: opencode")
    logger.info("依赖检查通过")
    logger.info("检查 Python 依赖...")
    logger.info("Python 依赖检查通过")
    logger.info("检查执行器配置...")
    validate_runtime_config()
    logger.info("执行器配置检查通过")

app = FastAPI(
    title="云测桥接执行器",
    description="本地接收任务、调用 Agent、上报进度和结果。",
    version="1.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(cloud_api_router)


@app.on_event("startup")
async def startup():
    _check_runtime_dependencies()
    logger.info("启动 OpenCode Server (端口 4096)...")
    logger.info("等待 OpenCode Server 启动...")
    api_base = ensure_opencode_server()
    if not check_api_available(api_base):
        raise RuntimeError(f"OpenCode Server 启动失败: {api_base}")
    logger.info("OpenCode Server 启动成功")
    logger.info("启动执行器服务 (端口 8000)...")
    logger.info("执行器服务启动成功")
    logger.info("执行器已就绪，等待任务下发...")
    logger.info("任务入口: http://localhost:8000/api/cloud-api/start")
    runtime_log_path = getattr(app.state, "runtime_log_path", "")
    if runtime_log_path:
        logger.info(f"执行器日志: {runtime_log_path}")


@app.get("/api/health")
async def health():
    return {
        "ok": True,
        "service": "cloud_executor",
    }


@app.get("/")
async def root():
    return {
        "service": "cloud_executor",
        "health": "/api/health",
        "start": "/api/cloud-api/start",
        "status": "/api/cloud-api/status",
    }


if __name__ == "__main__":
    import uvicorn

    runtime_log_path = _prepare_runtime_log_file()
    _attach_file_logger(runtime_log_path)
    app.state.runtime_log_path = runtime_log_path
    uvicorn.run(app, host="0.0.0.0", port=8000, access_log=False, log_level="warning")
