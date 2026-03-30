# -*- coding: utf-8 -*-
"""评测控制路由 — start, stop, status, SSE logs"""

from fastapi import APIRouter, HTTPException
from sse_starlette.sse import EventSourceResponse

from backend.models import EvaluationConfig, EvaluationStatus, EvaluationProgress
from backend.evaluator import evaluator_manager

router = APIRouter(prefix="/api/evaluation", tags=["evaluation"])


@router.post("/start")
async def start_evaluation(config: EvaluationConfig):
    if evaluator_manager.get_progress().status == EvaluationStatus.RUNNING:
        raise HTTPException(status_code=400, detail="评测正在进行中")

    success, message = evaluator_manager.start_evaluation(
        config.profiles,
        config.scenarios,
        skip_baseline=config.skip_baseline,
        only_run_baseline=config.only_run_baseline,
    )
    if not success:
        raise HTTPException(status_code=400, detail=message)

    return {"status": "started", "message": message}


@router.post("/stop")
async def stop_evaluation():
    success, message = evaluator_manager.stop_evaluation()
    if not success:
        raise HTTPException(status_code=400, detail=message)

    return {"status": "stopped", "message": message}


@router.get("/status", response_model=EvaluationProgress)
async def get_status():
    return evaluator_manager.get_progress()


@router.get("/logs")
async def stream_logs():
    async def event_generator():
        log_queue = evaluator_manager.get_log_queue()
        while True:
            try:
                log = log_queue.get(timeout=30)
                yield {"event": "log", "data": log.model_dump_json()}
            except Exception:
                yield {"event": "ping", "data": ""}

    return EventSourceResponse(event_generator())
