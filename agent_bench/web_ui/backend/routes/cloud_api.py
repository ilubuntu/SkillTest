# -*- coding: utf-8 -*-
"""云测桥接路由。"""

import os
import shutil
import tempfile

from fastapi import APIRouter, HTTPException, Query, Request
from fastapi.responses import FileResponse

from agent_bench.cloud_api.models import CloudExecutionStartRequest
from agent_bench.cloud_api.service import cloud_execution_manager

router = APIRouter(prefix="/api/cloud-api", tags=["cloud_api"])


@router.post("/start")
async def start_cloud_execution(payload: CloudExecutionStartRequest, request: Request):
    local_base_url = str(request.base_url).rstrip("/")
    success, message = cloud_execution_manager.start(payload, local_base_url)
    if not success:
        raise HTTPException(status_code=400, detail=message)
    return {
        "accepted": True,
        "executionId": payload.executionId,
        "message": message,
    }


@router.get("/status")
async def get_cloud_execution_status(execution_id: int | None = Query(default=None)):
    state = cloud_execution_manager.get_state(execution_id)
    if not state:
        return {
            "status": "idle",
            "executionId": execution_id,
        }
    return state


@router.get("/executions/{execution_id}/output-code")
async def download_output_code(execution_id: int):
    state = cloud_execution_manager.get_state(execution_id)
    if not state:
        raise HTTPException(status_code=404, detail="执行记录不存在")

    case_dir = state.get("case_dir")
    if not case_dir:
        raise HTTPException(status_code=404, detail="执行目录不存在")

    source_dir = os.path.join(case_dir, "side_a")
    if not os.path.isdir(source_dir):
        raise HTTPException(status_code=404, detail="输出代码目录不存在")

    archive_root = os.path.join(tempfile.gettempdir(), f"cloud_execution_{execution_id}_{reporting_side}")
    archive_path = shutil.make_archive(archive_root, "zip", root_dir=source_dir)
    return FileResponse(
        archive_path,
        media_type="application/zip",
        filename=os.path.basename(archive_path),
    )
