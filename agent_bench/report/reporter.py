# -*- coding: utf-8 -*-
"""报告生成模块

支持新的报告格式：
  - weighted_total: 加权总分（场景评分×80% + 通用评分×20%）
  - scenario_summary: 场景用例评分汇总
  - general_summary: 通用用例评分汇总
  - general: 通用检查（编译/lint 通过率）
  - by_scenario: 按场景汇总
"""

import json
import os
from datetime import datetime


DEFAULT_SCENARIO_WEIGHT = 0.8
DEFAULT_GENERAL_WEIGHT = 0.2


def generate(results: list, scenario: str, profile_name: str, output_dir: str):
    """生成 JSON + Markdown 报告

    Args:
        results: 用例结果列表
        scenario: 场景名称
        profile_name: profile 名称
        output_dir: 输出目录

    Returns:
        (json_path, md_path)
    """
    os.makedirs(output_dir, exist_ok=True)

    scenario_summary = _compute_scenario_summary(results)
    general_summary = _compute_general_summary(results)
    weighted_total = _compute_weighted_total(scenario_summary, general_summary)
    general = _compute_general(results)
    by_scenario = _compute_by_scenario(results)

    report_json = {
        "generated_at": datetime.now().isoformat(),
        "profile": profile_name,
        "scenario": scenario,
        "weighted_total": weighted_total,
        "scenario_summary": scenario_summary,
        "general_summary": general_summary,
        "general": general,
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


def _compute_scenario_summary(results: list) -> dict:
    """计算场景用例汇总（排除通用用例）"""
    scenario_results = [r for r in results if r.get("scenario") != "general"]

    if not scenario_results:
        return {
            "total_cases": 0,
            "baseline_avg": None,
            "enhanced_avg": None,
            "gain": None,
            "baseline_pass_rate": "N/A",
            "enhanced_pass_rate": "N/A",
            "dimensions": {},
        }

    baseline_scores = [r["baseline_total"] for r in scenario_results]
    enhanced_scores = [r["enhanced_total"] for r in scenario_results]

    baseline_avg = sum(baseline_scores) / len(baseline_scores)
    enhanced_avg = sum(enhanced_scores) / len(enhanced_scores)

    pass_threshold = 60
    baseline_pass = sum(1 for s in baseline_scores if s >= pass_threshold)
    enhanced_pass = sum(1 for s in enhanced_scores if s >= pass_threshold)

    dimensions = {}
    for r in scenario_results:
        for dim_id, scores in r.get("dimension_scores", {}).items():
            if dim_id not in dimensions:
                dimensions[dim_id] = {
                    "name": scores.get("name", dim_id),
                    "baseline": {"llm": [], "internal": []},
                    "enhanced": {"llm": [], "internal": []},
                }
            dimensions[dim_id]["baseline"]["llm"].append(scores["baseline"]["llm"])
            dimensions[dim_id]["baseline"]["internal"].append(scores["baseline"]["internal"])
            dimensions[dim_id]["enhanced"]["llm"].append(scores["enhanced"]["llm"])
            dimensions[dim_id]["enhanced"]["internal"].append(scores["enhanced"]["internal"])

    dim_summary = {}
    for dim_id, vals in dimensions.items():
        llm_b_avg = sum(vals["baseline"]["llm"]) / len(vals["baseline"]["llm"])
        llm_e_avg = sum(vals["enhanced"]["llm"]) / len(vals["enhanced"]["llm"])
        internal_b_avg = sum(vals["baseline"]["internal"]) / len(vals["baseline"]["internal"])
        internal_e_avg = sum(vals["enhanced"]["internal"]) / len(vals["enhanced"]["internal"])
        dim_summary[dim_id] = {
            "name": vals["name"],
            "baseline_avg": round(llm_b_avg, 1),
            "enhanced_avg": round(llm_e_avg, 1),
            "baseline_llm_avg": round(llm_b_avg, 1),
            "enhanced_llm_avg": round(llm_e_avg, 1),
            "baseline_internal_avg": round(internal_b_avg, 1),
            "enhanced_internal_avg": round(internal_e_avg, 1),
            "gain": round(llm_e_avg - llm_b_avg, 1),
        }

    return {
        "total_cases": len(scenario_results),
        "baseline_avg": round(baseline_avg, 1),
        "enhanced_avg": round(enhanced_avg, 1),
        "gain": round(enhanced_avg - baseline_avg, 1),
        "baseline_pass_rate": f"{baseline_pass}/{len(scenario_results)}",
        "enhanced_pass_rate": f"{enhanced_pass}/{len(scenario_results)}",
        "dimensions": dim_summary,
    }


def _compute_general_summary(results: list) -> dict:
    """计算通用用例汇总"""
    general_results = [r for r in results if r.get("scenario") == "general"]

    if not general_results:
        return {
            "total_cases": 0,
            "baseline_avg": None,
            "enhanced_avg": None,
            "gain": None,
            "baseline_pass_rate": "N/A",
            "enhanced_pass_rate": "N/A",
        }

    baseline_scores = [r["baseline_total"] for r in general_results]
    enhanced_scores = [r["enhanced_total"] for r in general_results]

    baseline_avg = sum(baseline_scores) / len(baseline_scores)
    enhanced_avg = sum(enhanced_scores) / len(enhanced_scores)

    pass_threshold = 60
    baseline_pass = sum(1 for s in baseline_scores if s >= pass_threshold)
    enhanced_pass = sum(1 for s in enhanced_scores if s >= pass_threshold)

    general_pass_count = sum(1 for r in general_results if r.get("general_pass"))
    general_total = len(general_results)

    return {
        "total_cases": len(general_results),
        "baseline_avg": round(baseline_avg, 1),
        "enhanced_avg": round(enhanced_avg, 1),
        "gain": round(enhanced_avg - baseline_avg, 1),
        "baseline_pass_rate": f"{baseline_pass}/{len(general_results)}",
        "enhanced_pass_rate": f"{enhanced_pass}/{len(general_results)}",
        "general_pass_count": general_pass_count,
        "general_total": general_total,
    }


def _compute_weighted_total(scenario_summary: dict, general_summary: dict,
                            scenario_weight: float = DEFAULT_SCENARIO_WEIGHT,
                            general_weight: float = DEFAULT_GENERAL_WEIGHT) -> dict:
    """计算加权总分：场景评分 × 80% + 通用评分 × 20%"""
    scenario_avg = scenario_summary.get("baseline_avg")
    general_avg = general_summary.get("baseline_avg")

    if scenario_avg is None and general_avg is None:
        return {
            "baseline_weighted": None,
            "enhanced_weighted": None,
            "scenario_weight": scenario_weight,
            "general_weight": general_weight,
            "gain": None,
        }

    if scenario_avg is None:
        baseline_weighted = general_avg
        enhanced_weighted = general_summary.get("enhanced_avg")
    elif general_avg is None:
        baseline_weighted = scenario_avg
        enhanced_weighted = scenario_summary.get("enhanced_avg")
    else:
        baseline_weighted = scenario_avg * scenario_weight + general_avg * general_weight
        enhanced_weighted = (scenario_summary.get("enhanced_avg", 0) * scenario_weight +
                            general_summary.get("enhanced_avg", 0) * general_weight)

    baseline_weighted = round(baseline_weighted, 1) if baseline_weighted else None
    enhanced_weighted = round(enhanced_weighted, 1) if enhanced_weighted else None
    gain = round(enhanced_weighted - baseline_weighted, 1) if (enhanced_weighted and baseline_weighted) else None

    return {
        "baseline_weighted": baseline_weighted,
        "enhanced_weighted": enhanced_weighted,
        "scenario_weight": scenario_weight,
        "general_weight": general_weight,
        "gain": gain,
    }


def _compute_general(results: list) -> dict:
    """计算通用检查结果（编译/lint 通过率）

    从评测结果中提取编译检查数据：
    - baseline_compilable: 基线代码是否可编译
    - enhanced_compilable: 增强代码是否可编译
    - 注意：project_gen 场景不进行编译检查（compilable=None）
    """
    baseline_compilable_count = 0
    baseline_compilable_total = 0
    enhanced_compilable_count = 0
    enhanced_compilable_total = 0

    for r in results:
        compile_results = r.get("compile_results")
        if compile_results:
            if compile_results.get("baseline_compilable") is not None:
                baseline_compilable_total += 1
                if compile_results.get("baseline_compilable"):
                    baseline_compilable_count += 1
            if compile_results.get("enhanced_compilable") is not None:
                enhanced_compilable_total += 1
                if compile_results.get("enhanced_compilable"):
                    enhanced_compilable_count += 1

    if baseline_compilable_total == 0 and enhanced_compilable_total == 0:
        return {
            "baseline_compile_pass_rate": "N/A",
            "enhanced_compile_pass_rate": "N/A",
            "note": "编译检查仅适用于非 project_gen 场景",
        }

    baseline_rate = f"{baseline_compilable_count}/{baseline_compilable_total}" if baseline_compilable_total > 0 else "N/A"
    enhanced_rate = f"{enhanced_compilable_count}/{enhanced_compilable_total}" if enhanced_compilable_total > 0 else "N/A"

    return {
        "baseline_compile_pass_rate": baseline_rate,
        "enhanced_compile_pass_rate": enhanced_rate,
        "baseline_compilable_count": baseline_compilable_count,
        "baseline_compilable_total": baseline_compilable_total,
        "enhanced_compilable_count": enhanced_compilable_count,
        "enhanced_compilable_total": enhanced_compilable_total,
    }


def _compute_by_scenario(results: list) -> dict:
    """按场景分组汇总"""
    scenarios = {}
    for r in results:
        sc = r.get("scenario", "unknown")
        if sc not in scenarios:
            scenarios[sc] = []
        scenarios[sc].append(r)

    by_scenario = {}
    for sc, cases in scenarios.items():
        baseline_scores = [c["baseline_total"] for c in cases]
        enhanced_scores = [c["enhanced_total"] for c in cases]
        b_avg = sum(baseline_scores) / len(baseline_scores)
        e_avg = sum(enhanced_scores) / len(enhanced_scores)

        by_scenario[sc] = {
            "total_cases": len(cases),
            "baseline_avg": round(b_avg, 1),
            "enhanced_avg": round(e_avg, 1),
            "gain": round(e_avg - b_avg, 1),
        }

    return by_scenario


def _render_markdown(report: dict) -> str:
    """渲染 Markdown 格式报告"""
    if not report.get("cases"):
        return "# Agent Bench 评测报告\n\n无数据\n"

    weighted = report.get("weighted_total", {})
    scenario_sum = report.get("scenario_summary", {})
    general_sum = report.get("general_summary", {})

    lines = [
        f"# Agent Bench 评测报告",
        f"",
        f"- **生成时间**: {report['generated_at']}",
        f"- **Profile**: {report['profile']}",
        f"- **场景**: {report['scenario']}",
        f"",
    ]

    # 加权总分
    if weighted.get("baseline_weighted") is not None:
        lines.append("## 加权总分")
        lines.append("")
        lines.append(f"| 指标 | 基线 | 增强 | 增益 |")
        lines.append(f"|------|------|------|------|")
        lines.append(f"| **加权总分** | **{weighted['baseline_weighted']}** | **{weighted['enhanced_weighted']}** | +{weighted['gain']} |")
        lines.append(f"| 场景用例权重 | {weighted['scenario_weight']*100:.0f}% | {weighted['scenario_weight']*100:.0f}% | - |")
        lines.append(f"| 通用用例权重 | {weighted['general_weight']*100:.0f}% | {weighted['general_weight']*100:.0f}% | - |")
        lines.append("")

    # 场景用例汇总
    if scenario_sum.get("total_cases", 0) > 0:
        lines.append("## 场景用例汇总")
        lines.append("")
        lines.append(f"| 指标 | 基线 | 增强 | 增益 |")
        lines.append(f"|------|------|------|------|")
        lines.append(f"| 用例数 | {scenario_sum['total_cases']} | - | - |")
        lines.append(f"| 平均得分 | {scenario_sum['baseline_avg']} | {scenario_sum['enhanced_avg']} | +{scenario_sum['gain']} |")
        lines.append(f"| 通过率 (>=60) | {scenario_sum['baseline_pass_rate']} | {scenario_sum['enhanced_pass_rate']} | - |")
        lines.append("")

    # 通用用例汇总
    if general_sum.get("total_cases", 0) > 0:
        lines.append("## 通用用例汇总")
        lines.append("")
        lines.append(f"| 指标 | 基线 | 增强 | 增益 |")
        lines.append(f"|------|------|------|------|")
        lines.append(f"| 用例数 | {general_sum['total_cases']} | - | - |")
        lines.append(f"| 平均得分 | {general_sum['baseline_avg']} | {general_sum['enhanced_avg']} | +{general_sum['gain']} |")
        lines.append(f"| 通用通过 | {general_sum.get('general_pass_count', 'N/A')}/{general_sum.get('general_total', 'N/A')} | - | - |")
        lines.append("")

    # 通用检查
    general = report.get("general", {})
    if general:
        lines.append("## 通用检查（编译通过率）")
        lines.append("")
        lines.append(f"| 检查项 | 基线 | 增强 |")
        lines.append(f"|--------|------|------|")
        lines.append(f"| 编译通过率 | {general.get('baseline_compile_pass_rate', 'N/A')} | {general.get('enhanced_compile_pass_rate', 'N/A')} |")
        if general.get("note"):
            lines.append(f"\n> {general['note']}")
        lines.append("")

    # 按场景汇总
    by_scenario = report.get("by_scenario", {})
    if by_scenario:
        lines.append("## 按场景汇总")
        lines.append("")
        lines.append("| 场景 | 用例数 | 基线均分 | 增强均分 | 增益 |")
        lines.append("|------|--------|---------|---------|------|")
        for sc, data in by_scenario.items():
            sc_label = "通用用例" if sc == "general" else sc
            lines.append(f"| {sc_label} | {data['total_cases']} | {data['baseline_avg']} "
                         f"| {data['enhanced_avg']} | +{data['gain']} |")
        lines.append("")

    # 各维度对比（仅场景用例）
    if scenario_sum.get("dimensions"):
        lines.append("## 各维度对比（场景用例）")
        lines.append("")
        lines.append("| 维度 | 基线(LLM) | 基线(内部) | 增强(LLM) | 增强(内部) | 增益 |")
        lines.append("|------|-----------|------------|-----------|------------|------|")
        for dim_id, dim in scenario_sum["dimensions"].items():
            name = dim.get("name", dim_id)
            lines.append(f"| {name} | {dim.get('baseline_llm_avg', dim.get('baseline_avg', 0))} "
                         f"| {dim.get('baseline_internal_avg', 'N/A')} "
                         f"| {dim.get('enhanced_llm_avg', dim.get('enhanced_avg', 0))} "
                         f"| {dim.get('enhanced_internal_avg', 'N/A')} "
                         f"| +{dim['gain']} |")
        lines.append("")

    # 用例明细
    lines.append("## 用例明细")
    lines.append("")
    for r in report["cases"]:
        gain = r["enhanced_total"] - r["baseline_total"]
        flag = "+" if gain >= 0 else ""
        scenario_tag = f" [{r.get('scenario', '')}]" if r.get('scenario') else ""
        lines.append(f"### {r['case_id']}: {r['title']}{scenario_tag}")
        lines.append("")
        lines.append(f"| | 基线 | 增强 | 增益 |")
        lines.append(f"|--|------|------|------|")
        lines.append(f"| 内部规则得分 | {r['baseline_rule']} | {r['enhanced_rule']} "
                     f"| {flag}{round(r['enhanced_rule'] - r['baseline_rule'], 1)} |")

        for dim_id, scores in r.get("dimension_scores", {}).items():
            name = scores.get("name", dim_id)
            d_gain = scores["enhanced"]["llm"] - scores["baseline"]["llm"]
            d_flag = "+" if d_gain >= 0 else ""
            lines.append(f"| {name}(LLM) | {scores['baseline']['llm']} "
                         f"| {scores['enhanced']['llm']} | {d_flag}{d_gain:.1f} |")
            lines.append(f"| {name}(内部) | {scores['baseline']['internal']} "
                         f"| {scores['enhanced']['internal']} | - |")

        lines.append(f"| **总分** | **{r['baseline_total']}** "
                     f"| **{r['enhanced_total']}** | **{flag}{round(gain, 1)}** |")
        lines.append("")

    return "\n".join(lines)
