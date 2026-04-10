# -*- coding: utf-8 -*-
"""Deterministic constraint scorer for case.yaml constraints."""

import json
import os
import re
from typing import Tuple

from agent_bench.constraint_schema import normalize_constraint_item, normalize_constraints


SKILL_NAME = "constraint-score-review"
REPORT_MARKER = "## Constraint Review Report"
SKILL_FILE_PATH = os.path.abspath(
    os.path.join(os.path.dirname(__file__), "..", "..", "config", "skills", SKILL_NAME, "SKILL.md")
)

PRIORITY_WEIGHTS = {
    "P0": 5.0,
    "P1": 3.0,
    "P2": 1.0,
}
TOTAL_CONSTRAINT_POINTS = 100.0


def build_constraint_review_skill(case_spec: dict,
                                  original_project_root: str = "",
                                  repair_patch_file: str = "",
                                  repaired_project_root: str = "",
                                  case_prompt: str = "") -> dict:
    """Build runtime skill content from the static skill file plus case context."""
    case_meta = case_spec.get("case", {}) if isinstance(case_spec, dict) else {}
    constraints = normalize_constraints(case_spec, project_root=repaired_project_root or original_project_root)
    skill_content = _read_text(SKILL_FILE_PATH).strip()
    if not skill_content:
        skill_content = (
            f"---\nname: {SKILL_NAME}\ndescription: Constraint scoring skill.\n---\n\n"
            "# Constraint Score Review"
        )

    context_lines = [
        "## Current Runtime Context",
        "",
        f"- case_id: {_fmt(case_meta.get('id')) or 'unknown'}",
        f"- case_title: {_fmt(case_meta.get('title')) or 'unknown'}",
        f"- original_project_root: {_fmt(original_project_root) or '(not provided)'}",
        f"- repair_patch_file: {_fmt(repair_patch_file) or '(not provided)'}",
        f"- repaired_project_root: {_fmt(repaired_project_root) or '(not provided)'}",
        f"- case_prompt: {_fmt(case_prompt) or '(not provided)'}",
        "",
        "## Constraint Summary",
    ]
    if not constraints:
        context_lines.append("- No constraints defined.")
    else:
        for item in constraints:
            priority = (_fmt(item.get("priority")) or "P1").upper()
            name = _fmt(item.get("name")) or "unnamed constraint"
            context_lines.append(f"- [{priority}] {name}")

    return {
        "name": SKILL_NAME,
        "path": SKILL_FILE_PATH if os.path.isfile(SKILL_FILE_PATH) else None,
        "content": f"{skill_content}\n\n---\n\n" + "\n".join(context_lines).strip(),
    }


def evaluate_constraints(case_spec: dict, project_root: str) -> dict:
    """Evaluate repaired code against constraints."""
    constraints = normalize_constraints(case_spec, project_root=project_root)
    item_results = []
    weighted_total = 0.0
    weighted_score_total = 0.0

    p0_weighted_total = 0.0
    p0_weighted_score_total = 0.0
    quality_weighted_total = 0.0
    quality_weighted_score_total = 0.0
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

    total_points = TOTAL_CONSTRAINT_POINTS if item_results else 0.0
    for item in item_results:
        max_points = _safe_weighted_avg(item["weight"] * total_points, weighted_total)
        earned_points = max_points * (item["score"] / 100.0)
        item["max_points"] = round(max_points, 1)
        item["earned_points"] = round(earned_points, 1)
        _attach_rule_scores(item)

    overall_score = _safe_weighted_avg(weighted_score_total, weighted_total)

    passed_constraints = []
    public_constraint_results = []
    unmet_constraint_ids = []
    for item in item_results:
        if item.get("is_public"):
            public_constraint_results.append({
                "constraint_id": item.get("id") or "",
                "constraint_ref": item.get("constraint_ref") or "",
                "name": item.get("name") or "",
                "score": round(float(item.get("earned_points", 0.0) or 0.0), 1),
                "passed": bool(item.get("passed")),
            })
        if item["passed"]:
            passed_constraints.append({
                "constraint_id": item.get("id") or "",
                "score": round(float(item.get("earned_points", 0.0) or 0.0), 1),
            })
        else:
            unmet_constraint_ids.append(item.get("id") or "")

    return {
        "skill_name": SKILL_NAME,
        "project_root": project_root,
        "summary": {
            "overall_score": round(overall_score, 1),
            "total_points": round(total_points, 1),
            "earned_points": round(sum(item.get("earned_points", 0.0) for item in item_results), 1),
            "constraints_total": len(item_results),
            "passed_constraints": passed_constraints,
            "public_constraint_results": public_constraint_results,
            "unmet_constraint_ids": unmet_constraint_ids,
        },
        "items": item_results,
    }


def build_constraint_review_report(score_result: dict) -> str:
    """Build a short report appended to output.txt."""
    summary = score_result.get("summary", {})
    payload = {
        "overall_score": round(float(summary.get("overall_score", 0.0) or 0.0), 1),
        "passed_constraints": list(summary.get("passed_constraints") or []),
        "public_constraint_results": list(summary.get("public_constraint_results") or []),
        "unmet_constraint_ids": list(summary.get("unmet_constraint_ids") or []),
    }
    lines = [REPORT_MARKER, "", "```json", json.dumps(payload, ensure_ascii=False, indent=2), "```"]
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

    prefix = text[:marker_pos].rstrip()
    if prefix.endswith("---"):
        prefix = prefix[:-3].rstrip()
    return prefix


def _evaluate_constraint_item(item: dict, project_root: str) -> dict:
    item = normalize_constraint_item(item)
    check_method = item.get("check_method") if isinstance(item, dict) else {}
    priority = (_fmt(item.get("priority")) or "P1").upper()
    priority_weight = PRIORITY_WEIGHTS.get(priority, PRIORITY_WEIGHTS["P1"])
    weight = priority_weight

    rules = check_method.get("rules") if isinstance(check_method, dict) else []
    rule_results = [_evaluate_rule(rule, project_root) for rule in (rules or [])]
    matched_rules = sum(1 for rule in rule_results if rule["passed"])
    total_rules = len(rule_results)

    if total_rules == 0:
        score = 100.0
        passed = True
    else:
        score = round((matched_rules / total_rules) * 100.0, 1)
        passed = matched_rules == total_rules

    return {
        "id": _fmt(item.get("id")),
        "name": _fmt(item.get("name")),
        "description": _fmt(item.get("description")),
        "source": _fmt(item.get("source")) or "case",
        "constraint_ref": _fmt(item.get("constraint_ref")),
        "is_public": bool(item.get("is_public")),
        "priority": priority,
        "priority_weight": priority_weight,
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
    abs_path = os.path.join(project_root, target_file) if target_file else ""
    file_exists = bool(abs_path) and os.path.isfile(abs_path)
    content = _read_text(abs_path) if file_exists else ""

    passed, detail = _match_rule(
        match_type,
        content,
        snippet=snippet,
        pattern=pattern,
    )
    if not file_exists:
        passed = False
        detail = f"target file not found: {target_file}"

    return {
        "rule_id": _fmt(rule.get("rule_id")),
        "target_file": target_file,
        "match_type": match_type,
        "snippet": snippet or pattern,
        "passed": passed,
        "detail": detail,
        "score": 100.0 if passed else 0.0,
        "max_points": 0.0,
        "earned_points": 0.0,
    }


def _match_rule(match_type: str,
                content: str,
                snippet: str = "",
                pattern: str = "") -> Tuple[bool, str]:
    if match_type == "contains":
        found = bool(snippet) and snippet in content
        return found, "snippet found" if found else "snippet not found"

    if match_type == "not_contains":
        found = bool(snippet) and snippet in content
        return (not found), "snippet absent" if not found else "snippet unexpectedly found"

    if match_type == "regex_contains":
        matched = bool(pattern) and re.search(pattern, content, re.MULTILINE) is not None
        return matched, "regex matched" if matched else "regex not matched"

    if match_type == "regex_not_contains":
        matched = bool(pattern) and re.search(pattern, content, re.MULTILINE) is not None
        return (not matched), "regex absent" if not matched else "regex unexpectedly matched"

    return False, f"unsupported match_type: {match_type}"


def _attach_rule_scores(item: dict) -> None:
    rules = item.get("rules", []) or []
    total_rules = len(rules)
    if total_rules <= 0:
        return

    constraint_max_points = float(item.get("max_points", 0.0) or 0.0)
    per_rule_max_points = round(constraint_max_points / total_rules, 2) if total_rules else 0.0

    for rule in rules:
        rule["max_points"] = per_rule_max_points
        rule["earned_points"] = per_rule_max_points if rule.get("passed") else 0.0


def _normalize_target_file(target_file: str) -> str:
    path = (target_file or "").replace("\\", "/").strip()
    prefixes = ("original_project/", "agent_workspace/")
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
