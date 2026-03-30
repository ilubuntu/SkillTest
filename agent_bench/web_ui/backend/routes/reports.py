# -*- coding: utf-8 -*-
"""报告查询路由 — 从 results 目录读取历史报告，及用例阶段产物浏览"""

import json
import os
from typing import List

from fastapi import APIRouter
from fastapi.responses import PlainTextResponse

from agent_bench.pipeline.loader import BASE_DIR

router = APIRouter(prefix="/api", tags=["reports"])

RESULTS_DIR = os.path.join(BASE_DIR, "results")


def _normalize_report_payload(data: dict, run_id: str) -> dict:
    """兼容历史报告结构，统一补齐前端展示所需字段。"""
    report = dict(data)
    report["run_id"] = run_id

    if "summary" not in report:
        if "scenario_summary" in report and isinstance(report["scenario_summary"], dict):
            report["summary"] = report["scenario_summary"]
        elif "weighted_total" in report and isinstance(report["weighted_total"], dict):
            report["summary"] = report["weighted_total"]
        else:
            report["summary"] = {}

    report["cases"] = report.get("cases", [])
    return report


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
            reports.append(_normalize_report_payload(data, run_dir))
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
    return _normalize_report_payload(data, run_id)


# ── 用例阶段产物浏览 ────────────────────────────────────────

STAGE_NAMES = ["baseline", "enhanced", "rule_check", "llm_judge"]


@router.get("/results/{run_id}/cases/{case_id}/stages")
async def get_case_stages(run_id: str, case_id: str):
    """返回指定用例各阶段子目录中的文件列表"""
    case_dir = os.path.join(RESULTS_DIR, run_id, "cases", case_id)
    if not os.path.isdir(case_dir):
        return {"error": "用例目录不存在"}

    stages = {}
    for stage in STAGE_NAMES:
        stage_path = os.path.join(case_dir, stage)
        if os.path.isdir(stage_path):
            files = [f for f in os.listdir(stage_path)
                     if os.path.isfile(os.path.join(stage_path, f))]
            stages[stage] = sorted(files)
        else:
            stages[stage] = []

    result_json = os.path.join(case_dir, "result.json")
    has_result = os.path.isfile(result_json)

    return {"case_id": case_id, "stages": stages, "has_result": has_result}


@router.get("/results/{run_id}/cases/{case_id}/stages/{stage}/{filename}")
async def get_stage_file(run_id: str, case_id: str, stage: str, filename: str):
    """读取指定阶段子目录中的文件内容"""
    if stage not in STAGE_NAMES:
        return PlainTextResponse("无效的阶段名", status_code=400)

    safe_filename = os.path.basename(filename)
    file_path = os.path.join(RESULTS_DIR, run_id, "cases", case_id, stage, safe_filename)

    if not os.path.isfile(file_path):
        return PlainTextResponse("文件不存在", status_code=404)

    with open(file_path, "r", encoding="utf-8") as f:
        content = f.read()

    if safe_filename.endswith(".json"):
        return json.loads(content)
    return PlainTextResponse(content)
