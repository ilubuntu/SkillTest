# -*- coding: utf-8 -*-
"""本地执行器 FastAPI 入口。"""

import logging

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from agent_bench.executor.cloud_api import router as cloud_api_router


logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(message)s",
)
logging.getLogger("uvicorn.access").disabled = True

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

    uvicorn.run(app, host="0.0.0.0", port=8000)
