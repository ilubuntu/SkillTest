# -*- coding: utf-8 -*-
"""基于 case constraints 的确定性约束评分器。"""

import os
import re
from typing import Dict, List, Tuple


SKILL_NAME = "constraint-score-review"
REPORT_MARKER = "## Constraint Review Report"

PRIORITY_WEIGHTS = {
    "P0": 5.0,
    "P1": 3.0,
    "P2": 1.0,
}
TYPE_WEIGHTS = {
    "custom_rule": 1.0,
    "scenario_assert": 1.2,
}
TOTAL_CONSTRAINT_POINTS = 100.0


def build_constraint_review_skill(case_spec: dict) -> dict:
    """根据当前 case constraints 渲染一份 skill 内容。"""
    case_meta = case_spec.get("case", {}) if isinstance(case_spec, dict) else {}
    constraints = case_spec.get("constraints", []) or []
    compact_lines = [
        "---",
        f"name: {SKILL_NAME}",
        "description: Keep current case constraints satisfied.",
        "---",
        "",
        f"- Case: {_fmt(case_meta.get('id')) or 'unknown'} | {_fmt(case_meta.get('title')) or 'unknown'}",
        "- 优先满足 P0，再处理 P1/P2。",
        "- 只关注当前 case 相关文件和行为。",
        "",
        "## Constraints",
    ]
    if not constraints:
        compact_lines.append("- No constraints defined.")
    else:
        for item in constraints:
            priority = (_fmt(item.get("priority")) or "P1").upper()
            name = _fmt(item.get("name")) or "unnamed constraint"
            compact_lines.append(f"- [{priority}] {name}")
    return {
        "name": SKILL_NAME,
        "path": None,
        "content": "\n".join(compact_lines).strip(),
    }
    lines = [
        "---",
        f"name: {SKILL_NAME}",
        "description: Evaluate repaired code against current case constraints and produce weighted validity and quality scores.",
        "---",
        "",
        "# Constraint Review Skill",
        "",
        "## Scope",
        f"- Case ID: {_fmt(case_meta.get('id')) or 'unknown'}",
        f"- Case Title: {_fmt(case_meta.get('title')) or 'unknown'}",
        "",
        "## Scoring Model",
        f"- Constraint total points: {TOTAL_CONSTRAINT_POINTS:.0f}",
        "- Priority weights: P0=5, P1=3, P2=1",
        "- Type weights: custom_rule=1.0, scenario_assert=1.2",
        "- Constraint weight = priority weight × type weight",
        "- Constraint max points = constraint weight / all weights × 100",
        "- Constraint earned points = max points × rule match rate",
        "- Overall score: sum of all constraint earned points",
        "- Effectiveness score: normalized score over P0 constraints only",
        "- Quality score: normalized score over P1/P2 constraints only",
        "",
        "## Constraints",
    ]

    if not constraints:
        lines.append("- No constraints defined.")
    for item in constraints:
        lines.extend(_render_constraint_skill_lines(item))

    return {
        "name": SKILL_NAME,
        "path": None,
        "content": "\n".join(lines).strip(),
    }


def evaluate_constraints(case_spec: dict, project_root: str) -> dict:
    """对修复后的工程按 constraints 执行确定性规则评分。"""

    constraints = case_spec.get("constraints", []) or []
    item_results = []
    weighted_total = 0.0
    weighted_score_total = 0.0

    p0_weighted_total = 0.0
    p0_weighted_score_total = 0.0
    quality_weighted_total = 0.0
    quality_weighted_score_total = 0.0
    category_buckets: Dict[str, Dict[str, float]] = {}

    for item in constraints:
        item_result = _evaluate_constraint_item(item, project_root)
        item_results.append(item_result)

        weight = item_result["weight"]
        score = item_result["score"]
        weighted_total += weight
        weighted_score_total += weight * score

        priority = item_result["priority"]
        if priority == "P0":
            p0_weighted_total += weight
            p0_weighted_score_total += weight * score
        else:
            quality_weighted_total += weight
            quality_weighted_score_total += weight * score

        category = item_result["category"] or "未分类"
        bucket = category_buckets.setdefault(category, {"weight": 0.0, "score": 0.0})
        bucket["weight"] += weight
        bucket["score"] += weight * score

    total_points = TOTAL_CONSTRAINT_POINTS if item_results else 0.0
    for item in item_results:
        max_points = _safe_weighted_avg(item["weight"] * total_points, weighted_total)
        earned_points = max_points * (item["score"] / 100.0)
        item["max_points"] = round(max_points, 1)
        item["earned_points"] = round(earned_points, 1)
        _attach_rule_scores(item)

    overall_score = _safe_weighted_avg(weighted_score_total, weighted_total)
    effectiveness_score = _safe_weighted_avg(p0_weighted_score_total, p0_weighted_total, default=overall_score)
    quality_score = _safe_weighted_avg(quality_weighted_score_total, quality_weighted_total, default=overall_score)
    passed_constraints = sum(1 for item in item_results if item["passed"])

    category_scores = {}
    for category, bucket in category_buckets.items():
        category_scores[category] = round(_safe_weighted_avg(bucket["score"], bucket["weight"]), 1)

    return {
        "skill_name": SKILL_NAME,
        "project_root": project_root,
        "summary": {
            "overall_score": round(overall_score, 1),
            "effectiveness_score": round(effectiveness_score, 1),
            "quality_score": round(quality_score, 1),
            "total_points": round(total_points, 1),
            "earned_points": round(sum(item.get("earned_points", 0.0) for item in item_results), 1),
            "constraints_total": len(item_results),
            "constraints_passed": passed_constraints,
        },
        "category_scores": category_scores,
        "items": item_results,
    }


def build_constraint_review_report(score_result: dict) -> str:
    """构造可追加到 output.txt 的约束评分报告。"""
    summary = score_result.get("summary", {})

    lines = [
        REPORT_MARKER,
        "",
        f"- Skill: {score_result.get('skill_name') or SKILL_NAME}",
        f"- Internal Rule Total Score: {summary.get('overall_score', 0):.1f}/100",
    ]

    return "\n".join(lines).strip()


def append_constraint_review_report(output_text: str, report_text: str) -> str:
    raw_output = strip_constraint_review_report(output_text)
    if not report_text:
        return raw_output
    raw_output = raw_output.rstrip()
    if not raw_output:
        return report_text
    return f"{raw_output}\n\n---\n\n{report_text}"


def strip_constraint_review_report(output_text: str) -> str:
    text = output_text or ""
    marker_pos = text.find(REPORT_MARKER)
    if marker_pos < 0:
        return text

    prefix = text[:marker_pos]
    prefix = prefix.rstrip()
    if prefix.endswith("---"):
        prefix = prefix[:-3].rstrip()
    return prefix


def _evaluate_constraint_item(item: dict, project_root: str) -> dict:
    check_method = item.get("check_method") if isinstance(item, dict) else {}
    method_type = _fmt(check_method.get("type")) or "custom_rule"
    match_mode = (_fmt(check_method.get("match_mode")) or "all").lower()
    priority = (_fmt(item.get("priority")) or "P1").upper()
    category = _fmt(item.get("category"))
    priority_weight = PRIORITY_WEIGHTS.get(priority, PRIORITY_WEIGHTS["P1"])
    type_weight = TYPE_WEIGHTS.get(method_type, TYPE_WEIGHTS["custom_rule"])
    weight = priority_weight * type_weight

    rules = check_method.get("rules") if isinstance(check_method, dict) else []
    rule_results = [_evaluate_rule(rule, project_root) for rule in (rules or [])]
    matched_rules = sum(1 for rule in rule_results if rule["passed"])
    total_rules = len(rule_results)
    if total_rules == 0:
        score = 100.0
        passed = True
    elif match_mode == "any":
        passed = matched_rules > 0
        score = 100.0 if passed else 0.0
    else:
        score = round((matched_rules / total_rules) * 100.0, 1)
        passed = matched_rules == total_rules

    return {
        "id": _fmt(item.get("id")),
        "name": _fmt(item.get("name")),
        "description": _fmt(item.get("description")),
        "category": category,
        "priority": priority,
        "check_type": method_type,
        "match_mode": match_mode,
        "priority_weight": priority_weight,
        "type_weight": type_weight,
        "weight": weight,
        "score": score,
        "passed": passed,
        "matched_rules": matched_rules,
        "total_rules": total_rules,
        "rules": rule_results,
        "detail": "",
    }


def _evaluate_rule(rule: dict, project_root: str) -> dict:
    target_file = _normalize_target_file(_fmt(rule.get("target_file")))
    match_type = _fmt(rule.get("match_type")) or "contains"
    snippet = _fmt(rule.get("snippet"))
    pattern = _fmt(rule.get("pattern"))
    expected_count = int(rule.get("count") or 1)
    abs_path = os.path.join(project_root, target_file) if target_file else ""
    file_exists = bool(abs_path) and os.path.isfile(abs_path)
    content = _read_text(abs_path) if file_exists else ""

    passed, detail = _match_rule(match_type, content, snippet=snippet, pattern=pattern, expected_count=expected_count)
    if not file_exists:
        passed = False
        detail = f"target file not found: {target_file}"

    return {
        "rule_id": _fmt(rule.get("rule_id")),
        "target_file": target_file,
        "match_type": match_type,
        "snippet": snippet or pattern,
        "count": expected_count if match_type in ("count_at_least", "regex_count_at_least") else None,
        "passed": passed,
        "detail": detail,
        "score": 100.0 if passed else 0.0,
        "max_points": 0.0,
        "earned_points": 0.0,
    }


def _match_rule(match_type: str, content: str, snippet: str = "", pattern: str = "", expected_count: int = 1) -> Tuple[bool, str]:
    if match_type == "contains":
        found = bool(snippet) and snippet in content
        return found, "snippet found" if found else "snippet not found"

    if match_type == "not_contains":
        found = bool(snippet) and snippet in content
        return (not found), "snippet absent" if not found else "snippet unexpectedly found"

    if match_type == "count_at_least":
        actual_count = content.count(snippet) if snippet else 0
        return actual_count >= expected_count, f"actual_count={actual_count}, expected_count>={expected_count}"

    if match_type == "regex_contains":
        matched = bool(pattern) and re.search(pattern, content, re.MULTILINE) is not None
        return matched, "regex matched" if matched else "regex not matched"

    if match_type == "regex_not_contains":
        matched = bool(pattern) and re.search(pattern, content, re.MULTILINE) is not None
        return (not matched), "regex absent" if not matched else "regex unexpectedly matched"

    if match_type == "regex_count_at_least":
        actual_count = len(re.findall(pattern, content, re.MULTILINE)) if pattern else 0
        return actual_count >= expected_count, f"actual_count={actual_count}, expected_count>={expected_count}"

    return False, f"unsupported match_type: {match_type}"


def _render_constraint_skill_lines(item: dict) -> List[str]:
    item_id = _fmt(item.get("id"))
    name = _fmt(item.get("name"))
    category = _fmt(item.get("category"))
    priority = (_fmt(item.get("priority")) or "P1").upper()
    description = _fmt(item.get("description"))
    check_method = item.get("check_method") if isinstance(item, dict) else {}
    method_type = _fmt(check_method.get("type")) or "custom_rule"
    match_mode = _fmt(check_method.get("match_mode")) or "all"

    lines = [
        f"### [{item_id}][{priority}][{category or '未分类'}] {name or item_id or 'Unnamed Constraint'}",
    ]
    if description:
        lines.append(f"- Description: {description}")
    lines.append(
        f"- Weight: priority={PRIORITY_WEIGHTS.get(priority, PRIORITY_WEIGHTS['P1'])}, "
        f"type={TYPE_WEIGHTS.get(method_type, TYPE_WEIGHTS['custom_rule'])}"
    )
    lines.append("- Points: allocated from the fixed 100 total points in proportion to weight")
    lines.append(f"- Check Method: {method_type} (match_mode={match_mode})")

    for rule in (check_method.get("rules") or []):
        if not isinstance(rule, dict):
            continue
        rule_id = _fmt(rule.get("rule_id"))
        target_file = _normalize_target_file(_fmt(rule.get("target_file")))
        match_type = _fmt(rule.get("match_type"))
        snippet = _fmt(rule.get("snippet")) or _fmt(rule.get("pattern"))
        count = rule.get("count")
        lines.append(f"- Rule: {rule_id} | {target_file} | {match_type}")
        if count is not None:
            lines.append(f"  - count: {count}")
        if snippet:
            lines.append(f"  - snippet: {snippet}")

    lines.append("")
    return lines


def _attach_rule_scores(item: dict) -> None:
    rules = item.get("rules", []) or []
    total_rules = len(rules)
    if total_rules <= 0:
        return

    constraint_max_points = float(item.get("max_points", 0.0) or 0.0)
    constraint_earned_points = float(item.get("earned_points", 0.0) or 0.0)
    match_mode = item.get("match_mode") or "all"
    per_rule_max_points = round(constraint_max_points / total_rules, 2) if total_rules else 0.0

    if match_mode == "any":
        passed_rules = [rule for rule in rules if rule.get("passed")]
        per_passed_earned_points = (
            round(constraint_earned_points / len(passed_rules), 2) if passed_rules else 0.0
        )
        for rule in rules:
            rule["max_points"] = per_rule_max_points
            rule["earned_points"] = per_passed_earned_points if rule.get("passed") else 0.0
        return

    for rule in rules:
        rule["max_points"] = per_rule_max_points
        rule["earned_points"] = per_rule_max_points if rule.get("passed") else 0.0




def _normalize_target_file(target_file: str) -> str:
    path = (target_file or "").replace("\\", "/").strip()
    prefixes = ("original_project/", "baseline/", "enhanced/")
    for prefix in prefixes:
        if path.startswith(prefix):
            path = path[len(prefix):]
            break
    return path


def _read_text(path: str) -> str:
    try:
        with open(path, "r", encoding="utf-8") as f:
            return f.read()
    except Exception:
        return ""


def _safe_weighted_avg(score_total: float, weight_total: float, default: float = 0.0) -> float:
    if weight_total <= 0:
        return default
    return score_total / weight_total


def _fmt(value) -> str:
    if value is None:
        return ""
    return str(value).strip()
