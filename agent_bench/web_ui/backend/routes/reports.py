# -*- coding: utf-8 -*-
"""报告查询路由 — 从 results 目录读取历史报告"""

import json
import os
from typing import List

from fastapi import APIRouter

from agent_bench.pipeline.loader import BASE_DIR

router = APIRouter(prefix="/api", tags=["reports"])

RESULTS_DIR = os.path.join(BASE_DIR, "results")


def _load_reports() -> List[dict]:
    """扫描 results 目录，加载所有 report.json"""
    reports = []
    if not os.path.isdir(RESULTS_DIR):
        return reports

    for run_dir in sorted(os.listdir(RESULTS_DIR), reverse=True):
        report_path = os.path.join(RESULTS_DIR, run_dir, "report.json")
        if not os.path.isfile(report_path):
            continue
        try:
            with open(report_path, "r", encoding="utf-8") as f:
                data = json.load(f)
            data["run_id"] = run_dir
            reports.append(data)
        except Exception:
            continue

    return reports


@router.get("/reports")
async def get_reports():
    return _load_reports()


@router.get("/reports/{run_id}")
async def get_report(run_id: str):
    report_path = os.path.join(RESULTS_DIR, run_id, "report.json")
    if not os.path.isfile(report_path):
        return {"error": "报告不存在"}
    with open(report_path, "r", encoding="utf-8") as f:
        data = json.load(f)
    data["run_id"] = run_id
    return data
