# -*- coding: utf-8 -*-
"""报告生成模块。"""

import json
import os
from datetime import datetime


DEFAULT_SCENARIO_WEIGHT = 0.8
DEFAULT_GENERAL_WEIGHT = 0.2


def generate(results: list, scenario: str, profile_name: str, output_dir: str,
             comparison_labels: dict = None, active_sides: list = None):
    os.makedirs(output_dir, exist_ok=True)
    active_sides = active_sides or ["side_a", "side_b"]

    scenario_summary = _compute_scenario_summary(results, active_sides=active_sides)
    general_summary = _compute_general_summary(results, active_sides=active_sides)
    weighted_total = _compute_weighted_total(scenario_summary, general_summary, active_sides=active_sides)
    general = _compute_general(results, active_sides=active_sides)
    by_scenario = _compute_by_scenario(results, active_sides=active_sides)
    summary = _build_summary(scenario_summary, general_summary, active_sides=active_sides)
    comparison_labels = comparison_labels or {
        "side_a": "Agent A",
        "side_b": "Agent B",
    }

    report_json = {
        "generated_at": datetime.now().isoformat(),
        "profile": profile_name,
        "scenario": scenario,
        "summary": summary,
        "weighted_total": weighted_total,
        "scenario_summary": scenario_summary,
        "general_summary": general_summary,
        "general": general,
        "by_scenario": by_scenario,
        "cases": results,
        "comparison_labels": comparison_labels,
        "active_sides": active_sides,
    }

    json_path = os.path.join(output_dir, "report.json")
    with open(json_path, "w", encoding="utf-8") as f:
        json.dump(report_json, f, ensure_ascii=False, indent=2)

    md_path = os.path.join(output_dir, "report.md")
    with open(md_path, "w", encoding="utf-8") as f:
        f.write(_render_markdown(report_json))

    return json_path, md_path


def _build_summary(scenario_summary: dict, general_summary: dict, active_sides: list = None) -> dict:
    include_side_b = "side_b" in (active_sides or ["side_a", "side_b"])
    if scenario_summary.get("total_cases", 0) > 0:
        return scenario_summary
    if general_summary.get("total_cases", 0) > 0:
        return {**general_summary, "dimensions": {}}
    return {
        "total_cases": 0,
        "side_a_avg": 0,
        "side_b_avg": 0 if include_side_b else None,
        "gain": 0 if include_side_b else None,
        "side_a_pass_rate": "0/0",
        "side_b_pass_rate": "0/0" if include_side_b else "N/A",
        "dimensions": {},
    }


def _compute_scenario_summary(results: list, active_sides: list = None) -> dict:
    include_side_b = "side_b" in (active_sides or ["side_a", "side_b"])
    scenario_results = [r for r in results if r.get("scenario") != "general"]
    if not scenario_results:
        return {
            "total_cases": 0,
            "side_a_avg": None,
            "side_b_avg": None if include_side_b else None,
            "gain": None,
            "side_a_pass_rate": "N/A",
            "side_b_pass_rate": "N/A",
            "dimensions": {},
        }

    side_a_scores = [r["side_a_total"] for r in scenario_results]
    side_a_avg = sum(side_a_scores) / len(side_a_scores)
    side_b_scores = [r["side_b_total"] for r in scenario_results if r.get("side_b_total") is not None] if include_side_b else []
    side_b_avg = (sum(side_b_scores) / len(side_b_scores)) if side_b_scores else None

    pass_threshold = 60
    side_a_pass = sum(1 for s in side_a_scores if s >= pass_threshold)
    side_b_pass = sum(1 for s in side_b_scores if s >= pass_threshold) if side_b_scores else 0

    dimensions = {}
    for result in scenario_results:
        for dim_id, scores in result.get("dimension_scores", {}).items():
            bucket = dimensions.setdefault(dim_id, {
                "name": scores.get("name", dim_id),
                "side_a": {"llm": [], "internal": []},
            })
            bucket["side_a"]["llm"].append(scores["side_a"]["llm"])
            bucket["side_a"]["internal"].append(scores["side_a"]["internal"])
            if include_side_b and scores.get("side_b"):
                bucket.setdefault("side_b", {"llm": [], "internal": []})
                bucket["side_b"]["llm"].append(scores["side_b"]["llm"])
                bucket["side_b"]["internal"].append(scores["side_b"]["internal"])

    dim_summary = {}
    for dim_id, vals in dimensions.items():
        side_a_llm_avg = sum(vals["side_a"]["llm"]) / len(vals["side_a"]["llm"])
        side_a_internal_avg = sum(vals["side_a"]["internal"]) / len(vals["side_a"]["internal"])
        dim_summary[dim_id] = {
            "name": vals["name"],
            "side_a_avg": round(side_a_llm_avg, 1),
            "side_a_llm_avg": round(side_a_llm_avg, 1),
            "side_a_internal_avg": round(side_a_internal_avg, 1),
        }
        if include_side_b and vals.get("side_b", {}).get("llm"):
            side_b_llm_avg = sum(vals["side_b"]["llm"]) / len(vals["side_b"]["llm"])
            side_b_internal_avg = sum(vals["side_b"]["internal"]) / len(vals["side_b"]["internal"])
            dim_summary[dim_id]["side_b_avg"] = round(side_b_llm_avg, 1)
            dim_summary[dim_id]["side_b_llm_avg"] = round(side_b_llm_avg, 1)
            dim_summary[dim_id]["side_b_internal_avg"] = round(side_b_internal_avg, 1)
            dim_summary[dim_id]["gain"] = round(side_b_llm_avg - side_a_llm_avg, 1)
        else:
            dim_summary[dim_id]["side_b_avg"] = None
            dim_summary[dim_id]["side_b_llm_avg"] = None
            dim_summary[dim_id]["side_b_internal_avg"] = None
            dim_summary[dim_id]["gain"] = None

    return {
        "total_cases": len(scenario_results),
        "side_a_avg": round(side_a_avg, 1),
        "side_b_avg": round(side_b_avg, 1) if side_b_avg is not None else None,
        "gain": round(side_b_avg - side_a_avg, 1) if side_b_avg is not None else None,
        "side_a_pass_rate": f"{side_a_pass}/{len(scenario_results)}",
        "side_b_pass_rate": f"{side_b_pass}/{len(scenario_results)}" if side_b_scores else "N/A",
        "dimensions": dim_summary,
    }


def _compute_general_summary(results: list, active_sides: list = None) -> dict:
    include_side_b = "side_b" in (active_sides or ["side_a", "side_b"])
    general_results = [r for r in results if r.get("scenario") == "general"]
    if not general_results:
        return {
            "total_cases": 0,
            "side_a_avg": None,
            "side_b_avg": None,
            "gain": None,
            "side_a_pass_rate": "N/A",
            "side_b_pass_rate": "N/A",
        }

    side_a_scores = [r["side_a_total"] for r in general_results]
    side_a_avg = sum(side_a_scores) / len(side_a_scores)
    side_b_scores = [r["side_b_total"] for r in general_results if r.get("side_b_total") is not None] if include_side_b else []
    side_b_avg = (sum(side_b_scores) / len(side_b_scores)) if side_b_scores else None

    pass_threshold = 60
    side_a_pass = sum(1 for s in side_a_scores if s >= pass_threshold)
    side_b_pass = sum(1 for s in side_b_scores if s >= pass_threshold) if side_b_scores else 0

    return {
        "total_cases": len(general_results),
        "side_a_avg": round(side_a_avg, 1),
        "side_b_avg": round(side_b_avg, 1) if side_b_avg is not None else None,
        "gain": round(side_b_avg - side_a_avg, 1) if side_b_avg is not None else None,
        "side_a_pass_rate": f"{side_a_pass}/{len(general_results)}",
        "side_b_pass_rate": f"{side_b_pass}/{len(general_results)}" if side_b_scores else "N/A",
        "general_pass_count": sum(1 for r in general_results if r.get("general_pass")),
        "general_total": len(general_results),
    }


def _compute_weighted_total(scenario_summary: dict, general_summary: dict,
                            scenario_weight: float = DEFAULT_SCENARIO_WEIGHT,
                            general_weight: float = DEFAULT_GENERAL_WEIGHT,
                            active_sides: list = None) -> dict:
    include_side_b = "side_b" in (active_sides or ["side_a", "side_b"])
    scenario_avg = scenario_summary.get("side_a_avg")
    general_avg = general_summary.get("side_a_avg")

    if scenario_avg is None and general_avg is None:
        return {
            "side_a_weighted": None,
            "side_b_weighted": None,
            "scenario_weight": scenario_weight,
            "general_weight": general_weight,
            "gain": None,
        }

    if scenario_avg is None:
        side_a_weighted = general_avg
        side_b_weighted = general_summary.get("side_b_avg")
    elif general_avg is None:
        side_a_weighted = scenario_avg
        side_b_weighted = scenario_summary.get("side_b_avg")
    else:
        side_a_weighted = scenario_avg * scenario_weight + general_avg * general_weight
        side_b_weighted = None if not include_side_b else (
            (scenario_summary.get("side_b_avg") or 0) * scenario_weight
            + (general_summary.get("side_b_avg") or 0) * general_weight
        )

    side_a_weighted = round(side_a_weighted, 1) if side_a_weighted is not None else None
    side_b_weighted = round(side_b_weighted, 1) if side_b_weighted is not None else None
    gain = round(side_b_weighted - side_a_weighted, 1) if (
        side_a_weighted is not None and side_b_weighted is not None
    ) else None

    return {
        "side_a_weighted": side_a_weighted,
        "side_b_weighted": side_b_weighted,
        "scenario_weight": scenario_weight,
        "general_weight": general_weight,
        "gain": gain,
    }


def _compute_general(results: list, active_sides: list = None) -> dict:
    include_side_b = "side_b" in (active_sides or ["side_a", "side_b"])
    side_a_count = side_a_total = side_b_count = side_b_total = 0
    for result in results:
        compile_results = result.get("compile_results") or {}
        if compile_results.get("side_a_compilable") is not None:
            side_a_total += 1
            if compile_results.get("side_a_compilable"):
                side_a_count += 1
        if include_side_b and compile_results.get("side_b_compilable") is not None:
            side_b_total += 1
            if compile_results.get("side_b_compilable"):
                side_b_count += 1

    if side_a_total == 0 and side_b_total == 0:
        return {
            "side_a_compile_pass_rate": "N/A",
            "side_b_compile_pass_rate": "N/A",
            "note": "编译检查仅适用于非 project_gen 场景",
        }

    return {
        "side_a_compile_pass_rate": f"{side_a_count}/{side_a_total}" if side_a_total > 0 else "N/A",
        "side_b_compile_pass_rate": f"{side_b_count}/{side_b_total}" if side_b_total > 0 else "N/A",
        "side_a_compilable_count": side_a_count,
        "side_a_compilable_total": side_a_total,
        "side_b_compilable_count": side_b_count,
        "side_b_compilable_total": side_b_total,
    }


def _compute_by_scenario(results: list, active_sides: list = None) -> dict:
    include_side_b = "side_b" in (active_sides or ["side_a", "side_b"])
    grouped = {}
    for result in results:
        grouped.setdefault(result.get("scenario", "unknown"), []).append(result)

    by_scenario = {}
    for scenario, cases in grouped.items():
        side_a_scores = [case["side_a_total"] for case in cases]
        side_a_avg = sum(side_a_scores) / len(side_a_scores)
        side_b_scores = [case["side_b_total"] for case in cases if case.get("side_b_total") is not None] if include_side_b else []
        side_b_avg = (sum(side_b_scores) / len(side_b_scores)) if side_b_scores else None
        by_scenario[scenario] = {
            "total_cases": len(cases),
            "side_a_avg": round(side_a_avg, 1),
            "side_b_avg": round(side_b_avg, 1) if side_b_avg is not None else None,
            "gain": round(side_b_avg - side_a_avg, 1) if side_b_avg is not None else None,
        }
    return by_scenario


def _render_markdown(report: dict) -> str:
    if not report.get("cases"):
        return "# Agent Bench 评测报告\n\n无数据\n"

    labels = report.get("comparison_labels", {}) or {}
    side_a_label = labels.get("side_a", "Agent A")
    side_b_label = labels.get("side_b", "Agent B")
    active_sides = report.get("active_sides") or ["side_a", "side_b"]
    show_side_b = "side_b" in active_sides
    weighted = report.get("weighted_total", {})
    scenario_sum = report.get("scenario_summary", {})
    general_sum = report.get("general_summary", {})

    lines = [
        "# Agent Bench 评测报告",
        "",
        f"- **生成时间**: {report['generated_at']}",
        f"- **Profile**: {report['profile']}",
        f"- **场景**: {report['scenario']}",
        "",
    ]

    if weighted.get("side_a_weighted") is not None:
        if show_side_b and weighted.get("side_b_weighted") is not None and weighted.get("gain") is not None:
            lines.extend([
                "## 加权总分",
                "",
                f"| 指标 | {side_a_label} | {side_b_label} | 差值 |",
                "|------|------|------|------|",
                f"| **加权总分** | **{weighted['side_a_weighted']}** | **{weighted['side_b_weighted']}** | {weighted['gain']:+.1f} |",
                "",
            ])
        else:
            lines.extend([
                "## 加权总分",
                "",
                f"| 指标 | {side_a_label} |",
                "|------|------|",
                f"| **加权总分** | **{weighted['side_a_weighted']}** |",
                "",
            ])

    if scenario_sum.get("total_cases", 0) > 0:
        if show_side_b and scenario_sum.get("side_b_avg") is not None and scenario_sum.get("gain") is not None:
            lines.extend([
                "## 场景用例汇总",
                "",
                f"| 指标 | {side_a_label} | {side_b_label} | 差值 |",
                "|------|------|------|------|",
                f"| 用例数 | {scenario_sum['total_cases']} | - | - |",
                f"| 平均得分 | {scenario_sum['side_a_avg']} | {scenario_sum['side_b_avg']} | {scenario_sum['gain']:+.1f} |",
                f"| 通过率 (>=60) | {scenario_sum['side_a_pass_rate']} | {scenario_sum['side_b_pass_rate']} | - |",
                "",
            ])
        else:
            lines.extend([
                "## 场景用例汇总",
                "",
                f"| 指标 | {side_a_label} |",
                "|------|------|",
                f"| 用例数 | {scenario_sum['total_cases']} |",
                f"| 平均得分 | {scenario_sum['side_a_avg']} |",
                f"| 通过率 (>=60) | {scenario_sum['side_a_pass_rate']} |",
                "",
            ])

    if general_sum.get("total_cases", 0) > 0:
        if show_side_b and general_sum.get("side_b_avg") is not None and general_sum.get("gain") is not None:
            lines.extend([
                "## 通用用例汇总",
                "",
                f"| 指标 | {side_a_label} | {side_b_label} | 差值 |",
                "|------|------|------|------|",
                f"| 用例数 | {general_sum['total_cases']} | - | - |",
                f"| 平均得分 | {general_sum['side_a_avg']} | {general_sum['side_b_avg']} | {general_sum['gain']:+.1f} |",
                "",
            ])
        else:
            lines.extend([
                "## 通用用例汇总",
                "",
                f"| 指标 | {side_a_label} |",
                "|------|------|",
                f"| 用例数 | {general_sum['total_cases']} |",
                f"| 平均得分 | {general_sum['side_a_avg']} |",
                "",
            ])

    general = report.get("general", {})
    if general:
        if show_side_b:
            lines.extend([
                "## 通用检查（编译通过率）",
                "",
                f"| 检查项 | {side_a_label} | {side_b_label} |",
                "|--------|------|------|",
                f"| 编译通过率 | {general.get('side_a_compile_pass_rate', 'N/A')} | {general.get('side_b_compile_pass_rate', 'N/A')} |",
                "",
            ])
        else:
            lines.extend([
                "## 通用检查（编译通过率）",
                "",
                f"| 检查项 | {side_a_label} |",
                "|--------|------|",
                f"| 编译通过率 | {general.get('side_a_compile_pass_rate', 'N/A')} |",
                "",
            ])

    lines.append("## 用例明细\n")
    for case in report["cases"]:
        if show_side_b and case.get("side_b_total") is not None and case.get("side_b_rule") is not None:
            gain = case["side_b_total"] - case["side_a_total"]
            lines.extend([
                f"### {case['case_id']}: {case['title']}",
                "",
                f"| | {side_a_label} | {side_b_label} | 差值 |",
                "|--|------|------|------|",
                f"| 本地规则得分 | {case['side_a_rule']} | {case['side_b_rule']} | {case['side_b_rule'] - case['side_a_rule']:+.1f} |",
                f"| **总分** | **{case['side_a_total']}** | **{case['side_b_total']}** | **{gain:+.1f}** |",
                "",
            ])
        else:
            lines.extend([
                f"### {case['case_id']}: {case['title']}",
                "",
                f"| | {side_a_label} |",
                "|--|------|",
                f"| 本地规则得分 | {case['side_a_rule']} |",
                f"| **总分** | **{case['side_a_total']}** |",
                "",
            ])
    return "\n".join(lines)
