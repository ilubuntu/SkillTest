# -*- coding: utf-8 -*-
"""单 agent 报告生成。"""

import json
import os
from datetime import datetime


def _mean_numeric(values: list):
    numeric_values = [v for v in (values or []) if isinstance(v, (int, float))]
    return (sum(numeric_values) / len(numeric_values)) if numeric_values else None


def generate(results: list, scenario: str, profile_name: str, output_dir: str, agent_label: str = "执行Agent"):
    os.makedirs(output_dir, exist_ok=True)
    summary = _build_summary(results)
    by_scenario = _compute_by_scenario(results)

    report_json = {
        "generated_at": datetime.now().isoformat(),
        "profile": profile_name,
        "scenario": scenario,
        "agent_label": agent_label,
        "summary": summary,
        "by_scenario": by_scenario,
        "cases": results,
    }

    json_path = os.path.join(output_dir, "report.json")
    with open(json_path, "w", encoding="utf-8") as f:
        json.dump(report_json, f, ensure_ascii=False, indent=2)

    md_path = os.path.join(output_dir, "report.md")
    with open(md_path, "w", encoding="utf-8") as f:
        f.write(_render_markdown(report_json))

    return json_path, md_path


def _build_summary(results: list) -> dict:
    scores = [r.get("score") for r in results if isinstance(r.get("score"), (int, float))]
    compile_checks = [r.get("compile_results") or {} for r in results]
    compile_values = [item.get("compilable") for item in compile_checks if item.get("compilable") is not None]
    compile_pass = sum(1 for item in compile_values if item)
    return {
        "total_cases": len(results),
        "avg_score": round(_mean_numeric(scores), 1) if scores else None,
        "compile_pass_rate": f"{compile_pass}/{len(compile_values)}" if compile_values else "N/A",
    }


def _compute_by_scenario(results: list) -> dict:
    grouped = {}
    for result in results:
        grouped.setdefault(result.get("scenario", "unknown"), []).append(result)
    by_scenario = {}
    for scenario, cases in grouped.items():
        scores = [case.get("score") for case in cases if isinstance(case.get("score"), (int, float))]
        by_scenario[scenario] = {
            "total_cases": len(cases),
            "avg_score": round(_mean_numeric(scores), 1) if scores else None,
        }
    return by_scenario


def _render_markdown(report: dict) -> str:
    if not report.get("cases"):
        return "# Agent Bench 评测报告\n\n无数据\n"

    lines = [
        "# Agent Bench 评测报告",
        "",
        f"- **生成时间**: {report['generated_at']}",
        f"- **Profile**: {report['profile']}",
        f"- **场景**: {report['scenario']}",
        f"- **执行Agent**: {report.get('agent_label', '执行Agent')}",
        "",
        "## 汇总",
        "",
        f"- 用例数: {report['summary'].get('total_cases', 0)}",
        f"- 平均分: {report['summary'].get('avg_score', 'N/A')}",
        f"- 编译通过率: {report['summary'].get('compile_pass_rate', 'N/A')}",
        "",
        "## 用例明细",
        "",
    ]

    for case in report["cases"]:
        lines.extend([
            f"### {case['case_id']}: {case['title']}",
            "",
            f"- 场景: {case.get('scenario')}",
            f"- 状态: {case.get('status', 'completed')}",
            f"- 分数: {case.get('score', 'N/A')}",
            f"- 工作目录: {case.get('workspace_dir', '')}",
            f"- 元数据目录: {case.get('meta_dir', '')}",
            "",
        ])
    return "\n".join(lines)
