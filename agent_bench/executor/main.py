# -*- coding: utf-8 -*-
"""本地执行器 FastAPI 入口。"""

import logging
import os
import sys
from logging.handlers import TimedRotatingFileHandler

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from agent_bench.common.version import APP_VERSION
from agent_bench.executor.routes import router as cloud_api_router
from agent_bench.pipeline.loader import load_logging_config, validate_runtime_config
from agent_bench.pipeline.compile_checker import apply_harmony_toolchain_env
from agent_bench.agent_runner.discovery import check_api_available, ensure_opencode_server
from agent_bench.agent_runner.opencode_env import find_opencode_executable

_LOGGING_CONFIG = load_logging_config()
_LOG_LEVEL_NAME = str(_LOGGING_CONFIG.get("level") or "INFO").upper()
_LOG_LEVEL = getattr(logging, _LOG_LEVEL_NAME, logging.INFO)

logging.basicConfig(
    level=_LOG_LEVEL,
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
    # 进程级总日志固定写入同一个基准文件，并按小时滚动归档。
    log_path = os.path.join(
        log_dir,
        str(_LOGGING_CONFIG.get("executor_log_filename") or "agent_bench.log"),
    )
    current_path = os.path.join(
        log_dir,
        str(_LOGGING_CONFIG.get("current_executor_log_filename") or "current_executor_log"),
    )
    with open(current_path, "w", encoding="utf-8") as file_obj:
        file_obj.write(log_path)
    return log_path


def _attach_file_logger(log_path: str):
    root_logger = logging.getLogger()
    for handler in root_logger.handlers:
        if isinstance(handler, logging.FileHandler) and getattr(handler, "baseFilename", "") == log_path:
            return
    file_handler = TimedRotatingFileHandler(
        log_path,
        when=str(_LOGGING_CONFIG.get("rotation_when") or "H"),
        interval=1,
        backupCount=int(_LOGGING_CONFIG.get("backup_count") or 72),
        encoding="utf-8",
    )
    if str(_LOGGING_CONFIG.get("rotation_when") or "H").upper() == "H":
        file_handler.suffix = "%Y%m%d_%H"
    file_handler.setLevel(_LOG_LEVEL)
    file_handler.setFormatter(logging.Formatter("%(asctime)s %(levelname)s %(message)s"))
    root_logger.addHandler(file_handler)


def _check_runtime_dependencies():
    logger.info("检查依赖...")
    opencode_path = find_opencode_executable()
    if not opencode_path:
        raise RuntimeError("缺少依赖: opencode")
    logger.info(f"检测到 opencode: {opencode_path}")
    validate_runtime_config()
    toolchain = apply_harmony_toolchain_env()
    logger.info(
        "HarmonyOS 工具链检查通过: source=%s, node=%s, hvigor=%s, harmonyos_sdk=%s, java_home=%s",
        toolchain.get("source", ""),
        toolchain.get("node", ""),
        toolchain.get("hvigor", ""),
        toolchain.get("harmonyos_sdk", ""),
        toolchain.get("java_home", ""),
    )
    logger.info("执行器配置检查通过")


app = FastAPI(
    title="云测桥接执行器",
    description="本地接收任务、调用 Agent、上报进度和结果。",
    version=APP_VERSION,
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
        logger.warning(f"OpenCode Server 当前不可用，执行器先启动成功，后续任务执行前会再次检查: {api_base}")
    else:
        logger.info("OpenCode Server 启动成功")
    logger.info("启动执行器服务 (端口 8000)...")
    logger.info("执行器已就绪，等待任务下发...")
    runtime_log_path = getattr(app.state, "runtime_log_path", "")
    if runtime_log_path:
        logger.info(f"执行器日志: {runtime_log_path}")


@app.get("/api/health")
async def health():
    return {
        "ok": True,
        "service": "cloud_executor",
        "version": APP_VERSION,
    }


@app.get("/")
async def root():
    return {
        "service": "cloud_executor",
        "version": APP_VERSION,
        "health": "/api/health",
        "status": "/api/cloud-api/status",
    }


if __name__ == "__main__":
    import uvicorn

    runtime_log_path = _prepare_runtime_log_file()
    _attach_file_logger(runtime_log_path)
    app.state.runtime_log_path = runtime_log_path
    uvicorn.run(app, host="0.0.0.0", port=8000, access_log=False, log_level="warning")
