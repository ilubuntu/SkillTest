import json
import os
from datetime import datetime


def generate(results: list, skill_name: str, output_dir: str):
    os.makedirs(output_dir, exist_ok=True)

    summary = _compute_summary(results)

    report_json = {
        "generated_at": datetime.now().isoformat(),
        "skill_under_test": skill_name,
        "summary": summary,
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
        for dim_name, scores in r.get("dimension_scores", {}).items():
            if dim_name not in dimensions:
                dimensions[dim_name] = {"baseline": [], "enhanced": []}
            dimensions[dim_name]["baseline"].append(scores["baseline"])
            dimensions[dim_name]["enhanced"].append(scores["enhanced"])

    dim_summary = {}
    for dim_name, vals in dimensions.items():
        b_avg = sum(vals["baseline"]) / len(vals["baseline"])
        e_avg = sum(vals["enhanced"]) / len(vals["enhanced"])
        dim_summary[dim_name] = {
            "baseline_avg": round(b_avg, 1),
            "enhanced_avg": round(e_avg, 1),
            "gain": round(e_avg - b_avg, 1),
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


def _render_markdown(report: dict) -> str:
    s = report["summary"]
    lines = [
        f"# Skill 增益评测报告",
        f"",
        f"- **生成时间**: {report['generated_at']}",
        f"- **被测 Skill**: {report['skill_under_test']}",
        f"",
        f"## 总览",
        f"",
        f"| 指标 | 基线 | 增强 | 增益 |",
        f"|------|------|------|------|",
        f"| 平均得分 | {s['baseline_avg']} | {s['enhanced_avg']} | +{s['gain']} |",
        f"| 通过率 (>=60) | {s['baseline_pass_rate']} | {s['enhanced_pass_rate']} | - |",
        f"",
    ]

    if s.get("dimensions"):
        lines.append("## 各维度对比")
        lines.append("")
        lines.append("| 维度 | 基线均分 | 增强均分 | 增益 |")
        lines.append("|------|---------|---------|------|")
        for dim_name, dim in s["dimensions"].items():
            lines.append(f"| {dim_name} | {dim['baseline_avg']} | {dim['enhanced_avg']} | +{dim['gain']} |")
        lines.append("")

    lines.append("## 用例明细")
    lines.append("")
    for r in report["cases"]:
        gain = r["enhanced_total"] - r["baseline_total"]
        flag = "+" if gain >= 0 else ""
        lines.append(f"### {r['case_id']}: {r['title']}")
        lines.append("")
        lines.append(f"| | 基线 | 增强 | 增益 |")
        lines.append(f"|--|------|------|------|")
        lines.append(f"| 规则得分 | {r['baseline_rule']} | {r['enhanced_rule']} | {flag}{round(r['enhanced_rule'] - r['baseline_rule'], 1)} |")

        for dim_name, scores in r.get("dimension_scores", {}).items():
            d_gain = scores["enhanced"] - scores["baseline"]
            d_flag = "+" if d_gain >= 0 else ""
            lines.append(f"| {dim_name} | {scores['baseline']} | {scores['enhanced']} | {d_flag}{d_gain} |")

        lines.append(f"| **总分** | **{r['baseline_total']}** | **{r['enhanced_total']}** | **{flag}{round(gain, 1)}** |")
        lines.append("")

    return "\n".join(lines)
