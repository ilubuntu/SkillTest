# -*- coding: utf-8 -*-
"""报告生成模块

支持新的报告格式：
  - general: 通用检查（编译/lint 通过率）— 占位，待实现
  - by_scenario: 按场景汇总
  - 每个用例包含 scenario 字段
"""

import json
import os
from datetime import datetime


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

    summary = _compute_summary(results)
    general = _compute_general(results)
    by_scenario = _compute_by_scenario(results)

    report_json = {
        "generated_at": datetime.now().isoformat(),
        "profile": profile_name,
        "scenario": scenario,
        "summary": summary,
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


def _compute_summary(results: list) -> dict:
    """计算整体汇总"""
    if not results:
        return {}

    baseline_scores = [r["baseline_total"] for r in results]
    enhanced_scores = [r["enhanced_total"] for r in results]

    baseline_avg = sum(baseline_scores) / len(baseline_scores)
    enhanced_avg = sum(enhanced_scores) / len(enhanced_scores)

    pass_threshold = 60
    baseline_pass = sum(1 for s in baseline_scores if s >= pass_threshold)
    enhanced_pass = sum(1 for s in enhanced_scores if s >= pass_threshold)

    dimensions = {}
    for r in results:
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
        "total_cases": len(results),
        "baseline_avg": round(baseline_avg, 1),
        "enhanced_avg": round(enhanced_avg, 1),
        "gain": round(enhanced_avg - baseline_avg, 1),
        "baseline_pass_rate": f"{baseline_pass}/{len(results)}",
        "enhanced_pass_rate": f"{enhanced_pass}/{len(results)}",
        "dimensions": dim_summary,
    }


def _compute_general(results: list) -> dict:
    """计算通用检查结果（编译/lint 通过率）

    TODO: 接入实际的编译和 lint 检查
    """
    # 占位：当前没有编译/lint 数据
    return {
        "compile_pass_rate": "N/A",
        "lint_pass_rate": "N/A",
        "note": "通用检查（编译/lint）尚未接入，待后续实现",
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
    s = report["summary"]
    if not s:
        return "# Agent Bench 评测报告\n\n无数据\n"

    lines = [
        f"# Agent Bench 评测报告",
        f"",
        f"- **生成时间**: {report['generated_at']}",
        f"- **Profile**: {report['profile']}",
        f"- **场景**: {report['scenario']}",
        f"",
        f"## 总览",
        f"",
        f"| 指标 | 基线 | 增强 | 增益 |",
        f"|------|------|------|------|",
        f"| 平均得分 | {s['baseline_avg']} | {s['enhanced_avg']} | +{s['gain']} |",
        f"| 通过率 (>=60) | {s['baseline_pass_rate']} | {s['enhanced_pass_rate']} | - |",
        f"",
    ]

    # 通用检查
    general = report.get("general", {})
    if general:
        lines.append("## 通用检查")
        lines.append("")
        lines.append(f"| 检查项 | 结果 |")
        lines.append(f"|--------|------|")
        lines.append(f"| 编译通过率 | {general.get('compile_pass_rate', 'N/A')} |")
        lines.append(f"| Lint 通过率 | {general.get('lint_pass_rate', 'N/A')} |")
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
            lines.append(f"| {sc} | {data['total_cases']} | {data['baseline_avg']} "
                         f"| {data['enhanced_avg']} | +{data['gain']} |")
        lines.append("")

    # 各维度对比
    if s.get("dimensions"):
        lines.append("## 各维度对比")
        lines.append("")
        lines.append("| 维度 | 基线(LLM) | 基线(内部) | 增强(LLM) | 增强(内部) | 增益 |")
        lines.append("|------|-----------|------------|-----------|------------|------|")
        for dim_id, dim in s["dimensions"].items():
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
