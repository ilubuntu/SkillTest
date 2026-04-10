"""Helpers for compact case constraint syntax and shared constraint references."""

from __future__ import annotations

import os
import re
import sys
from typing import Any, Dict, List

import yaml


_RULE_KEY_ALIASES = (
    ("contains", "contains", "snippet"),
    ("not_contains", "not_contains", "snippet"),
    ("regex", "regex_contains", "pattern"),
    ("regex_not", "regex_not_contains", "pattern"),
)

_SCENARIO_TAGS = {
    "bug_fix": "BUGFIX",
    "performance": "PERF",
    "requirement": "REQ",
    "cloud_api": "CLOUD",
}

_constraint_ref_registry_cache: Dict[str, Any] | None = None


def normalize_constraints(case_spec: Dict[str, Any] | None, project_root: str = "") -> List[Dict[str, Any]]:
    if not isinstance(case_spec, dict):
        return []

    explicit_constraints = [
        normalize_constraint_item(item)
        for item in (case_spec.get("constraints") or [])
        if isinstance(item, dict)
    ]
    explicit_names = {
        _as_text(item.get("name"))
        for item in explicit_constraints
        if _as_text(item.get("name"))
    }

    refs = _collect_default_constraint_refs(case_spec, explicit_names)
    refs.extend(_normalize_constraint_refs(case_spec.get("constraint_refs")))

    if not refs:
        return explicit_constraints

    id_context = _build_constraint_id_context(case_spec, explicit_constraints)
    project_context = _build_project_context(project_root)
    resolved_constraints = list(explicit_constraints)
    for ref_name in refs:
        resolved = _resolve_constraint_ref(
            ref_name=ref_name,
            case_spec=case_spec,
            project_context=project_context,
            next_index=id_context["next_index"],
        )
        if not resolved:
            continue
        id_context["next_index"] += 1
        resolved_constraints.append(resolved)

    return resolved_constraints


def normalize_constraint_item(item: Dict[str, Any] | None) -> Dict[str, Any]:
    if not isinstance(item, dict):
        return {}

    normalized = dict(item)
    source = _as_text(item.get("source")) or "case"
    normalized["source"] = source
    normalized["is_public"] = bool(item.get("is_public")) or source == "public_ref"
    normalized["check_method"] = normalize_check_method(item)
    return normalized


def normalize_check_method(source: Dict[str, Any] | None) -> Dict[str, Any]:
    if not isinstance(source, dict):
        return {"rules": []}

    raw = source.get("check_method")
    raw = raw if isinstance(raw, dict) else {}
    raw_rules = raw.get("rules")
    if raw_rules is None:
        raw_rules = source.get("rules") or []

    return {
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
    return normalized


def iter_constraint_target_files(case_spec: Dict[str, Any] | None, project_root: str = "") -> List[str]:
    paths: List[str] = []
    seen = set()
    for item in normalize_constraints(case_spec, project_root=project_root):
        check_method = item.get("check_method") or {}
        for rule in check_method.get("rules") or []:
            path = _as_text((rule or {}).get("target_file"))
            if not path or path in seen:
                continue
            seen.add(path)
            paths.append(path)
    return paths


def _collect_default_constraint_refs(case_spec: Dict[str, Any], explicit_names: set[str]) -> List[str]:
    if case_spec.get("disable_default_constraint_refs"):
        return []

    registry = _load_constraint_ref_registry()
    defaults = registry.get("defaults") if isinstance(registry, dict) else {}
    if not isinstance(defaults, dict):
        return []

    case_meta = case_spec.get("case") if isinstance(case_spec.get("case"), dict) else {}
    scenario = _as_text(case_meta.get("scenario")).lower()
    ref_names: List[str] = []
    for key in ("all", scenario):
        ref_names.extend(_normalize_constraint_refs(defaults.get(key)))

    excluded = {
        item for item in _normalize_constraint_refs(case_spec.get("exclude_constraint_refs"))
    }
    deduped: List[str] = []
    seen = set()
    for ref_name in ref_names:
        if not ref_name or ref_name in seen or ref_name in excluded:
            continue
        template = _lookup_constraint_ref_template(ref_name)
        template_name = _as_text(template.get("name"))
        if template_name and template_name in explicit_names:
            continue
        seen.add(ref_name)
        deduped.append(ref_name)
    return deduped


def _normalize_constraint_refs(raw_refs: Any) -> List[str]:
    if raw_refs is None:
        return []
    if isinstance(raw_refs, str):
        text = _as_text(raw_refs)
        return [text] if text else []
    if not isinstance(raw_refs, list):
        return []

    result: List[str] = []
    for item in raw_refs:
        if isinstance(item, str):
            text = _as_text(item)
        elif isinstance(item, dict):
            text = _as_text(item.get("ref")) or _as_text(item.get("name")) or _as_text(item.get("$ref"))
        else:
            text = ""
        if text:
            result.append(text)
    return result


def _resolve_constraint_ref(ref_name: str,
                            case_spec: Dict[str, Any],
                            project_context: Dict[str, Any],
                            next_index: int) -> Dict[str, Any]:
    template = _lookup_constraint_ref_template(ref_name)
    if not template:
        return {}

    if not _activation_matches(template.get("activation"), project_context):
        return {}

    constraint_id = _build_generated_constraint_id(case_spec, next_index)
    rules = _expand_rule_templates(template.get("rule_templates"), project_context, constraint_id)
    if not rules:
        return {}

    return _build_resolved_constraint(template, constraint_id, rules)


def _activation_matches(activation: Any, project_context: Dict[str, Any]) -> bool:
    if activation is None:
        return True
    if not isinstance(activation, dict):
        return False

    required_groups = _normalize_name_list(activation.get("required_groups"))
    for group_name in required_groups:
        if not _resolve_file_group(group_name, project_context):
            return False

    min_group_sizes = activation.get("min_group_sizes")
    if isinstance(min_group_sizes, dict):
        for group_name, raw_size in min_group_sizes.items():
            try:
                min_size = int(raw_size)
            except (TypeError, ValueError):
                continue
            if len(_resolve_file_group(_as_text(group_name), project_context)) < min_size:
                return False

    any_groups = _normalize_name_list(activation.get("any_groups"))
    if any_groups and not any(_resolve_file_group(group_name, project_context) for group_name in any_groups):
        return False

    absent_groups = _normalize_name_list(activation.get("absent_groups"))
    for group_name in absent_groups:
        if _resolve_file_group(group_name, project_context):
            return False

    return True


def _expand_rule_templates(rule_templates: Any,
                           project_context: Dict[str, Any],
                           constraint_id: str) -> List[Dict[str, Any]]:
    if not isinstance(rule_templates, list):
        return []

    rules: List[Dict[str, Any]] = []
    rule_index = 1
    for template in rule_templates:
        if not isinstance(template, dict):
            continue

        targets = _resolve_rule_targets(template, project_context)
        if not targets:
            continue

        per_target_rules = template.get("per_target_rules")
        if not isinstance(per_target_rules, list) or not per_target_rules:
            per_target_rules = [template]

        for target_file in targets:
            for rule_spec in per_target_rules:
                if not isinstance(rule_spec, dict):
                    continue
                rule = _build_rule_from_template(rule_spec, target_file, constraint_id, rule_index)
                if not rule:
                    continue
                rules.append(rule)
                rule_index += 1

    return rules


def _resolve_rule_targets(template: Dict[str, Any], project_context: Dict[str, Any]) -> List[str]:
    target_file = _as_text(template.get("target_file"))
    if target_file:
        return [target_file]

    explicit_targets = template.get("target_files")
    if isinstance(explicit_targets, list):
        targets = [_as_text(item) for item in explicit_targets if _as_text(item)]
        if targets:
            return _dedupe_paths(targets)

    group_name = _as_text(template.get("target_group"))
    targets = _resolve_file_group(group_name, project_context) if group_name else []
    if targets:
        return targets

    fallback_targets = template.get("fallback_targets")
    if isinstance(fallback_targets, list):
        return _dedupe_paths([_as_text(item) for item in fallback_targets if _as_text(item)])

    return []


def _build_rule_from_template(rule_spec: Dict[str, Any],
                              target_file: str,
                              constraint_id: str,
                              rule_index: int) -> Dict[str, Any]:
    match_type = _as_text(rule_spec.get("match_type")) or "contains"
    snippet = _as_text(rule_spec.get("snippet"))
    pattern = _as_text(rule_spec.get("pattern"))

    rule = {
        "rule_id": f"{constraint_id}-R{rule_index}",
        "target_file": target_file,
        "match_type": match_type,
    }
    if snippet:
        rule["snippet"] = snippet
    if pattern:
        rule["pattern"] = pattern
    return normalize_rule(rule)


def _build_resolved_constraint(template: Dict[str, Any],
                               constraint_id: str,
                               rules: List[Dict[str, Any]]) -> Dict[str, Any]:
    return normalize_constraint_item({
        "id": constraint_id,
        "name": _as_text(template.get("name")),
        "description": _as_text(template.get("description")),
        "category": _as_text(template.get("category")),
        "constraint_ref": _as_text(template.get("ref_name")),
        "source": "public_ref",
        "is_public": True,
        "priority": (_as_text(template.get("priority")) or "P0").upper(),
        "check_method": {"rules": rules},
    })


def _build_project_context(project_root: str) -> Dict[str, Any]:
    return {
        "project_root": _resolve_project_root(project_root),
        "registry": _load_constraint_ref_registry(),
        "target_cache": {},
        "file_cache": {},
    }


def _resolve_file_group(group_name: str, project_context: Dict[str, Any]) -> List[str]:
    normalized_name = _as_text(group_name)
    if not normalized_name:
        return []

    cache = project_context.get("target_cache")
    if isinstance(cache, dict) and normalized_name in cache:
        return cache[normalized_name]

    result = _resolve_builtin_target_group(normalized_name, project_context)
    result = _dedupe_paths(result)
    if isinstance(cache, dict):
        cache[normalized_name] = result
    return result


def _resolve_builtin_target_group(group_name: str, project_context: Dict[str, Any]) -> List[str]:
    if group_name == "page_files":
        return _scan_relative_files(project_context, "entry/src/main/ets/pages", [".ets"])
    if group_name == "model_files":
        return _scan_relative_files(project_context, "entry/src/main/ets/model", [".ets"])
    if group_name == "store_files":
        return _scan_relative_files(project_context, "entry/src/main/ets/store", [".ets"])
    if group_name == "viewmodel_files":
        return _scan_relative_files(project_context, "entry/src/main/ets/viewmodel", [".ets"])
    if group_name == "common_files":
        return _scan_relative_files(project_context, "entry/src/main/ets/common", [".ets"])
    if group_name == "component_candidate_files":
        result: List[str] = []
        for relative_dir in (
            "entry/src/main/ets/components",
            "entry/src/main/ets/component",
            "entry/src/main/ets/widgets",
            "entry/src/main/ets/widget",
        ):
            result.extend(_scan_relative_files(project_context, relative_dir, [".ets"]))
        return result
    if group_name == "component_files":
        return _filter_paths_by_any_regex(
            _resolve_file_group("component_candidate_files", project_context),
            [r"@(?:Component|ComponentV2)\b"],
            project_context,
        )
    if group_name == "layout_code_files":
        return _dedupe_paths(
            _resolve_file_group("page_files", project_context)
            + _resolve_file_group("component_files", project_context)
        )
    if group_name == "state_model_files":
        return _filter_paths_by_any_regex(
            _resolve_file_group("model_files", project_context),
            [r"@"],
            project_context,
        )
    if group_name == "state_candidate_files":
        return _dedupe_paths(
            _resolve_file_group("page_files", project_context)
            + _resolve_file_group("state_model_files", project_context)
        )
    if group_name == "shared_state_files":
        return _dedupe_paths(
            _resolve_file_group("model_files", project_context)
            + _resolve_file_group("store_files", project_context)
            + _resolve_file_group("viewmodel_files", project_context)
            + _resolve_file_group("common_files", project_context)
        )
    if group_name == "interactive_components":
        return _filter_paths_by_any_regex(
            _resolve_file_group("component_files", project_context),
            [r"\b(?:Button|Slider|Checkbox|Toggle|TextInput|Search|Radio|Select|Tabs|ListItem|GridItem)\s*\("],
            project_context,
        )
    if group_name == "metric_usage_files":
        return _filter_paths_by_any_regex(
            _resolve_file_group("layout_code_files", project_context),
            [r"\.(?:padding|paddingTop|paddingBottom|paddingLeft|paddingRight|margin|marginTop|marginBottom|marginLeft|marginRight|width|height|minWidth|minHeight|maxWidth|maxHeight|fontSize|lineHeight|letterSpacing|borderRadius|gap|rowGap|columnGap|size|constraintSize|translate|offset|position)\s*\("],
            project_context,
        )
    if group_name == "primary_page_file":
        candidates = _resolve_file_group("page_files", project_context)
        if not candidates:
            return []
        preferred = next(
            (path for path in candidates if os.path.basename(path).lower() == "index.ets"),
            "",
        )
        return [preferred] if preferred else [candidates[0]]
    if group_name == "secondary_page_files":
        source_paths = _resolve_file_group("page_files", project_context)
        excluded = set(_resolve_file_group("primary_page_file", project_context))
        return [path for path in source_paths if path not in excluded]
    return []


def _filter_paths_by_any_regex(paths: List[str],
                               patterns: List[str],
                               project_context: Dict[str, Any]) -> List[str]:
    if not patterns:
        return []
    result: List[str] = []
    for rel_path in paths:
        content = _read_project_file(project_context, rel_path)
        if any(re.search(pattern, content, re.MULTILINE) for pattern in patterns):
            result.append(rel_path)
    return result


def _scan_relative_files(project_context: Dict[str, Any], relative_dir: str, suffixes: List[str]) -> List[str]:
    project_root = _as_text(project_context.get("project_root"))
    if not project_root:
        return []

    abs_dir = os.path.join(project_root, relative_dir.replace("/", os.sep))
    if not os.path.isdir(abs_dir):
        return []

    normalized_suffixes = [suffix for suffix in suffixes if suffix]
    result: List[str] = []
    for name in sorted(os.listdir(abs_dir)):
        if normalized_suffixes and not any(name.endswith(suffix) for suffix in normalized_suffixes):
            continue
        result.append(f"{relative_dir.rstrip('/')}/{name}".replace("\\", "/"))
    return result


def _dedupe_paths(paths: List[str]) -> List[str]:
    result: List[str] = []
    seen = set()
    for path in paths:
        normalized = _as_text(path).replace("\\", "/")
        if not normalized or normalized in seen:
            continue
        seen.add(normalized)
        result.append(normalized)
    return result


def _build_constraint_id_context(case_spec: Dict[str, Any], constraints: List[Dict[str, Any]]) -> Dict[str, Any]:
    max_index = 0
    base_prefix = ""
    for item in constraints:
        constraint_id = _as_text(item.get("id"))
        match = re.match(r"^(?P<prefix>.+)-(?P<index>\d+)$", constraint_id)
        if not match:
            continue
        base_prefix = base_prefix or match.group("prefix")
        max_index = max(max_index, int(match.group("index")))

    if not base_prefix:
        base_prefix = _derive_constraint_prefix_from_case_spec(case_spec)

    return {
        "base_prefix": base_prefix,
        "next_index": max_index + 1 if max_index > 0 else 1,
    }


def _build_generated_constraint_id(case_spec: Dict[str, Any], next_index: int) -> str:
    context = _build_constraint_id_context(case_spec, [])
    prefix = _as_text(context.get("base_prefix"))
    if not prefix:
        return f"COMMON-CONSTRAINT-{next_index:02d}"
    return f"{prefix}-{next_index:02d}"


def _derive_constraint_prefix_from_case_spec(case_spec: Dict[str, Any]) -> str:
    case_meta = case_spec.get("case") if isinstance(case_spec.get("case"), dict) else {}
    case_id = _as_text(case_meta.get("id"))
    scenario = _as_text(case_meta.get("scenario")).lower()

    match = re.match(r"^(?P<scenario>[a-z_]+)_(?P<number>\d+)$", case_id)
    if match:
        scenario = scenario or match.group("scenario")
        number = match.group("number")
    else:
        number = ""

    scenario_tag = _SCENARIO_TAGS.get(scenario, scenario.replace("_", "").upper() or "CASE")
    if number:
        return f"HM-{scenario_tag}-{number.zfill(3)}"
    if case_id:
        return f"HM-{scenario_tag}-{case_id.replace('_', '-').upper()}"
    return f"HM-{scenario_tag}"


def _lookup_constraint_ref_template(ref_name: str) -> Dict[str, Any]:
    registry = _load_constraint_ref_registry()
    refs = registry.get("refs") if isinstance(registry, dict) else {}
    if not isinstance(refs, dict):
        return {}
    template = refs.get(ref_name)
    if not isinstance(template, dict):
        return {}
    enriched = dict(template)
    enriched.setdefault("ref_name", ref_name)
    return enriched


def _load_constraint_ref_registry() -> Dict[str, Any]:
    global _constraint_ref_registry_cache
    if _constraint_ref_registry_cache is not None:
        return _constraint_ref_registry_cache

    path = _constraint_ref_registry_path()
    if not os.path.isfile(path):
        _constraint_ref_registry_cache = {}
        return _constraint_ref_registry_cache

    data = _load_constraint_ref_registry_file(path)
    _constraint_ref_registry_cache = data if isinstance(data, dict) else {}
    return _constraint_ref_registry_cache


def _load_constraint_ref_registry_file(path: str) -> Dict[str, Any]:
    with open(path, "r", encoding="utf-8") as f:
        data = yaml.safe_load(f) or {}
    if not isinstance(data, dict):
        return {}

    merged = dict(data)
    imports = data.get("imports")
    if isinstance(imports, list):
        base_dir = os.path.dirname(path)
        for item in imports:
            import_name = _as_text(item)
            if not import_name:
                continue
            import_path = os.path.join(base_dir, import_name)
            if not os.path.isfile(import_path):
                continue
            imported = _load_constraint_ref_registry_file(import_path)
            merged = _merge_constraint_registry_dicts(merged, imported)
    return merged


def _merge_constraint_registry_dicts(base: Dict[str, Any], extra: Dict[str, Any]) -> Dict[str, Any]:
    merged = dict(base)
    for key, value in extra.items():
        if key == "imports":
            continue
        current = merged.get(key)
        if isinstance(current, dict) and isinstance(value, dict):
            merged[key] = _merge_constraint_registry_dicts(current, value)
        else:
            merged[key] = value
    return merged


def _constraint_ref_registry_path() -> str:
    return os.path.join(
        _runtime_root_dir(),
        "config",
        "skills",
        "constraint-score-review",
        "references",
        "constraint_refs.yaml",
    )


def _runtime_root_dir() -> str:
    if getattr(sys, "frozen", False):
        return os.path.dirname(os.path.abspath(sys.executable))
    return os.path.dirname(os.path.abspath(os.path.dirname(__file__)))


def _resolve_project_root(project_root: str) -> str:
    root = _as_text(project_root)
    if not root:
        return ""
    if os.path.isabs(root) and os.path.isdir(root):
        return root

    candidates = [
        root,
        os.path.join(_runtime_root_dir(), root),
        os.path.join(_runtime_root_dir(), "agent_bench", root),
    ]
    for candidate in candidates:
        if os.path.isdir(candidate):
            return candidate
    return root


def _read_text(path: str) -> str:
    try:
        with open(path, "r", encoding="utf-8") as f:
            return f.read()
    except Exception:
        return ""


def _read_project_file(project_context: Dict[str, Any], rel_path: str) -> str:
    normalized_path = _as_text(rel_path).replace("\\", "/")
    if not normalized_path:
        return ""

    file_cache = project_context.get("file_cache")
    if isinstance(file_cache, dict) and normalized_path in file_cache:
        return file_cache[normalized_path]

    project_root = _as_text(project_context.get("project_root"))
    abs_path = os.path.join(project_root, normalized_path) if project_root else ""
    content = _read_text(abs_path) if abs_path else ""
    if isinstance(file_cache, dict):
        file_cache[normalized_path] = content
    return content


def _normalize_name_list(value: Any) -> List[str]:
    if value is None:
        return []
    if isinstance(value, str):
        text = _as_text(value)
        return [text] if text else []
    if not isinstance(value, list):
        return []
    return [_as_text(item) for item in value if _as_text(item)]


def _as_text(value: Any) -> str:
    if value is None:
        return ""
    return str(value).strip()
