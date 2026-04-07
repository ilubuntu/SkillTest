"""Helpers for compact case constraint syntax."""

from __future__ import annotations

from typing import Any, Dict, List


_RULE_KEY_ALIASES = (
    ("contains", "contains", "snippet"),
    ("not_contains", "not_contains", "snippet"),
    ("regex", "regex_contains", "pattern"),
    ("regex_not", "regex_not_contains", "pattern"),
    ("count_at_least", "count_at_least", "snippet"),
    ("regex_count_at_least", "regex_count_at_least", "pattern"),
)


def normalize_constraints(case_spec: Dict[str, Any] | None) -> List[Dict[str, Any]]:
    if not isinstance(case_spec, dict):
        return []
    constraints = case_spec.get("constraints") or []
    return [normalize_constraint_item(item) for item in constraints if isinstance(item, dict)]


def normalize_constraint_item(item: Dict[str, Any] | None) -> Dict[str, Any]:
    if not isinstance(item, dict):
        return {}

    normalized = dict(item)
    normalized["check_method"] = normalize_check_method(item)
    return normalized


def normalize_check_method(source: Dict[str, Any] | None) -> Dict[str, Any]:
    if not isinstance(source, dict):
        return {"type": "custom_rule", "match_mode": "all", "rules": []}

    raw = source.get("check_method")
    raw = raw if isinstance(raw, dict) else {}
    raw_rules = raw.get("rules")
    if raw_rules is None:
        raw_rules = source.get("rules") or []

    return {
        "type": _as_text(raw.get("type")) or _as_text(source.get("type")) or "custom_rule",
        "match_mode": (_as_text(raw.get("match_mode")) or _as_text(source.get("match_mode")) or "all").lower(),
        "rules": [normalize_rule(rule) for rule in raw_rules if isinstance(rule, dict)],
    }


def normalize_rule(rule: Dict[str, Any] | None) -> Dict[str, Any]:
    if not isinstance(rule, dict):
        return {}

    normalized = dict(rule)
    normalized["rule_id"] = _as_text(rule.get("rule_id")) or _as_text(rule.get("id"))
    normalized["target_file"] = _as_text(rule.get("target_file")) or _as_text(rule.get("file"))

    match_type = _as_text(rule.get("match_type"))
    snippet = _as_text(rule.get("snippet"))
    pattern = _as_text(rule.get("pattern"))

    if not match_type:
        for alias_key, alias_match_type, value_key in _RULE_KEY_ALIASES:
            alias_value = _as_text(rule.get(alias_key))
            if not alias_value:
                continue
            match_type = alias_match_type
            if value_key == "snippet" and not snippet:
                snippet = alias_value
            if value_key == "pattern" and not pattern:
                pattern = alias_value
            break

    normalized["match_type"] = match_type or "contains"
    normalized["snippet"] = snippet
    normalized["pattern"] = pattern
    normalized["count"] = _normalize_count(rule.get("count"))
    return normalized


def iter_constraint_target_files(case_spec: Dict[str, Any] | None) -> List[str]:
    paths: List[str] = []
    seen = set()
    for item in normalize_constraints(case_spec):
        check_method = item.get("check_method") or {}
        for rule in check_method.get("rules") or []:
            path = _as_text((rule or {}).get("target_file"))
            if not path or path in seen:
                continue
            seen.add(path)
            paths.append(path)
    return paths


def _normalize_count(value: Any) -> int:
    try:
        return int(value or 1)
    except (TypeError, ValueError):
        return 1


def _as_text(value: Any) -> str:
    if value is None:
        return ""
    return str(value).strip()
