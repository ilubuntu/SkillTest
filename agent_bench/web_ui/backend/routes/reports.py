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

    summary = report.get("summary", {}) or {}
    if "side_a_avg" not in summary and "baseline_avg" in summary:
        summary["side_a_avg"] = summary.get("baseline_avg")
        summary["side_b_avg"] = summary.get("enhanced_avg")
        summary["side_a_pass_rate"] = summary.get("baseline_pass_rate", "N/A")
        summary["side_b_pass_rate"] = summary.get("enhanced_pass_rate", "N/A")
        dimensions = summary.get("dimensions", {}) or {}
        for _, dim in dimensions.items():
            dim["side_a_avg"] = dim.get("side_a_avg", dim.get("baseline_avg"))
            dim["side_b_avg"] = dim.get("side_b_avg", dim.get("enhanced_avg"))
            dim["side_a_llm_avg"] = dim.get("side_a_llm_avg", dim.get("baseline_llm_avg"))
            dim["side_b_llm_avg"] = dim.get("side_b_llm_avg", dim.get("enhanced_llm_avg"))
            dim["side_a_internal_avg"] = dim.get("side_a_internal_avg", dim.get("baseline_internal_avg"))
            dim["side_b_internal_avg"] = dim.get("side_b_internal_avg", dim.get("enhanced_internal_avg"))
        report["summary"] = summary

    report["cases"] = report.get("cases", [])
    for case in report["cases"]:
        if "side_a_total" not in case and "baseline_total" in case:
            case["side_a_rule"] = case.get("baseline_rule", 0)
            case["side_b_rule"] = case.get("enhanced_rule", 0)
            case["side_a_total"] = case.get("baseline_total", 0)
            case["side_b_total"] = case.get("enhanced_total", 0)
            case["gain"] = case.get("gain", case.get("side_b_total", 0) - case.get("side_a_total", 0))
            for _, dim in (case.get("dimension_scores", {}) or {}).items():
                dim["side_a"] = dim.get("side_a", dim.get("baseline", {}))
                dim["side_b"] = dim.get("side_b", dim.get("enhanced", {}))

    raw_labels = report.get("comparison_labels") or {}
    report["comparison_labels"] = {
        "side_a": raw_labels.get("side_a") or raw_labels.get("baseline") or "基线",
        "side_b": raw_labels.get("side_b") or raw_labels.get("enhanced") or "增强",
    }
    raw_active_sides = report.get("active_sides") or ["side_a", "side_b"]
    report["active_sides"] = ["side_a" if side in ("baseline", "side_a") else "side_b" for side in raw_active_sides]
    if not report["active_sides"]:
        report["active_sides"] = ["side_a", "side_b"]

    if "general" in report and isinstance(report["general"], dict):
        general = report["general"]
        general["side_a_compile_pass_rate"] = general.get("side_a_compile_pass_rate", general.get("baseline_compile_pass_rate", "N/A"))
        general["side_b_compile_pass_rate"] = general.get("side_b_compile_pass_rate", general.get("enhanced_compile_pass_rate", "N/A"))
        report["general"] = general
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

STAGE_NAMES = ["side_a", "side_b", "side_a_compile", "side_b_compile", "rule_check", "llm_judge"]


@router.get("/results/{run_id}/cases/{case_id}/stages")
async def get_case_stages(run_id: str, case_id: str):
    """返回指定用例各阶段子目录中的文件列表"""
    case_dir = os.path.join(RESULTS_DIR, run_id, "cases", case_id)
    if not os.path.isdir(case_dir):
        return {"error": "用例目录不存在"}

    stages = {}
    for stage in STAGE_NAMES:
        stage_path = os.path.join(case_dir, stage)
        meta_dir = os.path.join(stage_path, ".agent_bench")
        if os.path.isdir(stage_path):
            list_root = meta_dir if os.path.isdir(meta_dir) else stage_path
            files = [f for f in os.listdir(list_root)
                     if os.path.isfile(os.path.join(list_root, f))]
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
    stage_root = os.path.join(RESULTS_DIR, run_id, "cases", case_id, stage)
    meta_file_path = os.path.join(stage_root, ".agent_bench", safe_filename)
    file_path = meta_file_path if os.path.isfile(meta_file_path) else os.path.join(stage_root, safe_filename)

    if not os.path.isfile(file_path):
        return PlainTextResponse("文件不存在", status_code=404)

    with open(file_path, "r", encoding="utf-8") as f:
        content = f.read()

    if safe_filename.endswith(".json"):
        return json.loads(content)
    return PlainTextResponse(content)
