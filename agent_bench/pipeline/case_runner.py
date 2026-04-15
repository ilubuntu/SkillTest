# -*- coding: utf-8 -*-
"""单 agent 用例执行。"""

import json
import os
import re
import shutil
import subprocess
import time
from typing import Callable

from agent_bench.pipeline.artifacts import (
    agent_meta_dir,
    agent_workspace_dir,
    diff_dir,
    original_project_dir,
    review_dir,
    static_dir,
    load_runner_artifacts,
    save_compile_artifacts,
    save_case_result,
    save_interaction_metrics,
    save_review_agent_artifacts,
    save_runner_artifacts,
)
from agent_bench.pipeline.compile_checker import check_project_compilable, prepare_project_workspace
from agent_bench.pipeline.loader import (
    load_agent_spec,
    resolve_case_original_project,
)
from agent_bench.pipeline.prompts import (
    build_agent_task_prompt,
    build_constraint_review_prompt,
    build_static_review_prompt,
)
from agent_bench.agent_runner import AgentRunner, build_agent_spec

MAX_LOGGED_PROMPT_CHARS = 4000
MAX_LOGGED_OUTPUT_CHARS = 1000
WORKSPACE_GITIGNORE = """build/
.hvigor/
oh_modules/
node_modules/
oh-package-lock.json5
*.log
"""


def _notify(on_progress, event: str, data: dict):
    if on_progress:
        on_progress(event, data)


def _clip_text(text: str, limit: int) -> str:
    text = text or ""
    return text if len(text) <= limit else text[:limit] + "\n...<truncated>"


def _coerce_int(value):
    try:
        if value is None or value == "":
            return None
        return int(value)
    except Exception:
        return None


def _metrics_derived(metrics: dict) -> dict:
    if not isinstance(metrics, dict):
        return {}
    derived = metrics.get("derived")
    return derived if isinstance(derived, dict) else {}


def _metrics_http(metrics: dict) -> dict:
    if not isinstance(metrics, dict):
        return {}
    http = metrics.get("http")
    return http if isinstance(http, dict) else {}


def _metrics_message_parts(metrics: dict) -> list[dict]:
    http = _metrics_http(metrics)
    message_info = http.get("message_info") if isinstance(http, dict) else {}
    parts = message_info.get("parts") if isinstance(message_info, dict) else []
    return parts if isinstance(parts, list) else []


def _format_usage_suffix(metrics: dict) -> str:
    usage = _metrics_derived(metrics).get("usage") if isinstance(metrics, dict) else {}
    if not isinstance(usage, dict):
        return ""
    input_tokens = _coerce_int(usage.get("input_tokens"))
    output_tokens = _coerce_int(usage.get("output_tokens"))
    reasoning_tokens = _coerce_int(usage.get("reasoning_tokens"))
    values = [value for value in (input_tokens, output_tokens, reasoning_tokens) if value is not None]
    if not values:
        return ""
    total_tokens = sum(values)
    segments = [f"tokens={total_tokens}"]
    if input_tokens is not None:
        segments.append(f"in={input_tokens}")
    if output_tokens is not None:
        segments.append(f"out={output_tokens}")
    if reasoning_tokens is not None:
        segments.append(f"reasoning={reasoning_tokens}")
    return ", " + ", ".join(segments)


def _format_completion_message(prefix: str, output_text: str, elapsed: float, metrics: dict) -> str:
    output_chars = len(output_text or "")
    return f"{prefix}, output={output_chars} chars, elapsed={elapsed:.1f}s{_format_usage_suffix(metrics)}"


def _format_constraint_score_message(summary: dict) -> str:
    if not isinstance(summary, dict):
        return "约束规则打分结果: 无"
    overall = summary.get("overall_score")
    passed = summary.get("constraints_passed")
    total = summary.get("constraints_total")
    segments = []
    if overall is not None:
        segments.append(f"overall_score={overall}")
    if passed is not None:
        if total is not None:
            segments.append(f"constraints_passed={passed}/{total}")
        else:
            segments.append(f"constraints_passed={passed}")
    failed_items = summary.get("failed_items")
    if isinstance(failed_items, list) and failed_items:
        first = failed_items[0] if isinstance(failed_items[0], dict) else {}
        first_reason = str(first.get("reason") or "").strip()
        first_id = str(first.get("constraint_id") or "").strip()
        if first_id:
            detail = first_id
            if first_reason:
                detail += f":{_clip_text(first_reason, 40)}"
            segments.append(f"failed={detail}")
    return "约束规则打分结果: " + (", ".join(segments) if segments else "无")


def _format_static_score_message(summary: dict, source: str = "") -> str:
    if not isinstance(summary, dict):
        return "静态代码打分结果: 无"
    quality = summary.get("quality_score")
    overall = summary.get("overall_score")
    segments = []
    if quality is not None:
        segments.append(f"quality_score={quality}")
    if overall is not None and overall != quality:
        segments.append(f"overall_score={overall}")
    main_issues = summary.get("main_issues")
    if isinstance(main_issues, list) and main_issues:
        segments.append(f"issue={_clip_text(str(main_issues[0]), 40)}")
    if source:
        segments.append(f"source={source}")
    return "静态代码打分结果: " + (", ".join(segments) if segments else "无")


def _ensure_review_stage_succeeded(result: dict, stage_label: str):
    status = str((result or {}).get("status") or "").strip().lower()
    if status in {"completed", "success", "skipped"}:
        return
    reason = str((result or {}).get("reason") or "").strip()
    if reason:
        raise RuntimeError(f"{stage_label}失败: {reason}")
    raise RuntimeError(f"{stage_label}失败")


def _load_stage_interaction_metrics(case_dir: str, stage: str) -> dict:
    metrics_path = ""
    legacy_metrics_path = ""
    if stage == "agent":
        metrics_path = os.path.join(agent_meta_dir(case_dir), "agent_interaction_metrics.json")
        legacy_metrics_path = os.path.join(agent_meta_dir(case_dir), "interaction_metrics.json")
    elif stage == "constraint_review":
        metrics_path = os.path.join(review_dir(case_dir), "constraint_review_interaction_metrics.json")
    elif stage == "static_review":
        metrics_path = os.path.join(static_dir(case_dir), "static_review_interaction_metrics.json")
    if not metrics_path or not os.path.exists(metrics_path):
        metrics_path = legacy_metrics_path
    if not metrics_path or not os.path.exists(metrics_path):
        return {}
    try:
        with open(metrics_path, "r", encoding="utf-8") as f:
            return json.load(f) or {}
    except Exception:
        return {}


def _log_compile_self_check_signal(case_id: str,
                                   agent_label: str,
                                   output_text: str,
                                   on_progress,
                                   target_skills: list[str] | None = None):
    normalized_output = (output_text or "").lower()
    expected_skills = [
        str(name or "").strip().lower()
        for name in (target_skills or [])
        if str(name or "").strip()
    ]
    matched = [name for name in expected_skills if name in normalized_output]
    if matched:
        _notify(on_progress, "log", {
            "level": "WARNING",
            "message": f"{agent_label} 模型输出中自报已调用预期 skill: {', '.join(matched)}",
        })
        return
    _notify(on_progress, "log", {
        "level": "WARNING",
        "message": f"{agent_label} 未观察到显式 skill 事件，且模型输出中未包含预期 skill 调用标记",
    })


def _find_generated_hap_files(case_dir: str, stage: str) -> list[str]:
    workspace_dir = agent_workspace_dir(case_dir) if stage == "agent" else ""
    if not workspace_dir or not os.path.isdir(workspace_dir):
        return []
    hap_files = []
    for root, _, files in os.walk(workspace_dir):
        for name in files:
            if name.lower().endswith(".hap"):
                hap_files.append(os.path.join(root, name))
    return hap_files


def _log_skill_call_detection(case_id: str,
                              agent_label: str,
                              case_dir: str,
                              stage: str,
                              output_text: str,
                              on_progress,
                              target_skills: list[str] | None = None):
    metrics = _load_stage_interaction_metrics(case_dir, stage)
    raw_parts = _metrics_message_parts(metrics)
    explicit_skill_matches = []
    compile_command_matches = []
    expected_skills = [
        str(name or "").strip().lower()
        for name in (target_skills or [])
        if str(name or "").strip()
    ]
    for part in raw_parts:
        if not isinstance(part, dict):
            continue
        serialized = json.dumps(part, ensure_ascii=False).lower()
        part_type = str(part.get("type") or "unknown")
        matched_skill = next((name for name in expected_skills if name in serialized), "")
        if part_type in {"tool", "skill"} and matched_skill:
            explicit_skill_matches.append(f"{part_type}:{matched_skill}")
            continue
        if "build-harmony-project" in expected_skills and any(token in serialized for token in ("hvigor", "assemblehap", "--stop-daemon")):
            compile_command_matches.append(part_type)
    if explicit_skill_matches:
        summary = ",".join(str(item) for item in explicit_skill_matches[:3])
        _notify(on_progress, "log", {
            "level": "WARNING",
            "message": f"{agent_label} 在 interaction_metrics 中观察到预期 skill 明确调用痕迹，事件={summary}",
        })
        return
    if compile_command_matches:
        summary = ",".join(str(item) for item in compile_command_matches[:3])
        _notify(on_progress, "log", {
            "level": "WARNING",
            "message": f"{agent_label} 在 interaction_metrics 中观察到 HarmonyOS 编译命令痕迹，事件={summary}",
        })
        return
    hap_files = _find_generated_hap_files(case_dir, stage)
    if hap_files:
        rel_files = [os.path.relpath(path, agent_workspace_dir(case_dir)) for path in hap_files[:2]]
        _notify(on_progress, "log", {
            "level": "WARNING",
            "message": f"{agent_label} 未观察到显式 skill 事件，但检测到真实编译产物: {', '.join(rel_files)}",
        })
        return
    _log_compile_self_check_signal(case_id, agent_label, output_text, on_progress, expected_skills)
def _build_runner_only_result(case: dict, case_dir: str, agent: dict) -> dict:
    post_compile_result = case.get("_post_compile_result") or {}
    pre_compile_result = case.get("_pre_compile_result") or {}
    return {
        "case_id": case["id"],
        "title": case["title"],
        "scenario": case.get("scenario"),
        "status": "completed",
        "agent_elapsed_s": case.get("_agent_elapsed_s"),
        "agent": {
            "id": agent.get("id") or "",
            "name": agent.get("name") or "",
            "model": agent.get("model") or "",
        },
        "workspace_dir": agent_workspace_dir(case_dir),
        "meta_dir": agent_meta_dir(case_dir),
        "original_dir": original_project_dir(case_dir),
        "constraint_dir": review_dir(case_dir),
        "static_dir": static_dir(case_dir),
        "compile_results": {
            "compilable": post_compile_result.get("compilable"),
            "error": post_compile_result.get("error", "") or "",
            "before": pre_compile_result or {},
            "after": post_compile_result or {},
            "regressed": (
                bool(pre_compile_result.get("compilable"))
                and post_compile_result.get("compilable") is False
            ),
        },
        "constraint_review": case.get("_constraint_review_result") or None,
        "static_review": case.get("_static_review_result") or None,
    }


def _initialize_workspace_git(case_dir: str, workspace_dir: str, on_progress):
    patch_root = diff_dir(case_dir)
    os.makedirs(patch_root, exist_ok=True)
    gitignore_path = os.path.join(workspace_dir, ".gitignore")
    with open(gitignore_path, "w", encoding="utf-8") as f:
        f.write(WORKSPACE_GITIGNORE)
    _notify(on_progress, "log", {"level": "INFO", "message": f"已写入工作区 Git 忽略规则: {gitignore_path}"})

    subprocess.run(["git", "init"], cwd=workspace_dir, capture_output=True, text=True, check=False)
    subprocess.run(["git", "config", "user.name", "agent-bench"], cwd=workspace_dir, capture_output=True, text=True, check=False)
    subprocess.run(["git", "config", "user.email", "agent-bench@example.local"], cwd=workspace_dir, capture_output=True, text=True, check=False)
    subprocess.run(["git", "add", "."], cwd=workspace_dir, capture_output=True, text=True, check=False)
    commit_result = subprocess.run(
        ["git", "commit", "-m", "workspace_base"],
        cwd=workspace_dir,
        capture_output=True,
        text=True,
        check=False,
    )
    if commit_result.returncode != 0:
        raise RuntimeError(f"初始化工作区 Git 基线失败: {commit_result.stderr or commit_result.stdout}")
    rev_result = subprocess.run(
        ["git", "rev-parse", "HEAD"],
        cwd=workspace_dir,
        capture_output=True,
        text=True,
        check=False,
    )
    workspace_base_commit = str(rev_result.stdout or "").strip()
    if not workspace_base_commit:
        raise RuntimeError("未能读取 workspace 基线 commit")
    workspace_base_commit_path = os.path.join(patch_root, "commit.txt")
    with open(workspace_base_commit_path, "w", encoding="utf-8") as f:
        f.write(workspace_base_commit + "\n")
    _notify(on_progress, "log", {"level": "INFO", "message": f"工作区 Git 基线已建立: {workspace_base_commit}"})
    return workspace_base_commit


def _generate_review_patch(case_dir: str, workspace_dir: str, workspace_base_commit: str, on_progress):
    patch_root = diff_dir(case_dir)
    os.makedirs(patch_root, exist_ok=True)
    patch_path = os.path.join(patch_root, "changes.patch")
    diff_result = subprocess.run(
        ["git", "diff", "--binary", workspace_base_commit],
        cwd=workspace_dir,
        capture_output=True,
        text=True,
        check=False,
    )
    if diff_result.returncode not in (0, 1):
        raise RuntimeError(f"生成 patch 失败: {diff_result.stderr or diff_result.stdout}")
    with open(patch_path, "w", encoding="utf-8") as f:
        f.write(diff_result.stdout or "")
    _notify(on_progress, "log", {"level": "INFO", "message": f"已生成评审 patch: {patch_path}"})
    return patch_path


def _extract_first_json_object(text: str):
    if not text:
        return None
    decoder = json.JSONDecoder()
    for match in re.finditer(r"\{", text):
        start = match.start()
        try:
            payload, _ = decoder.raw_decode(text[start:])
        except Exception:
            continue
        if isinstance(payload, dict):
            return payload
    return None


def _extract_constraint_review_summary(output_text: str) -> dict:
    text = output_text or ""
    summary = {}

    json_block_matches = re.findall(r"```json\s*(\{[\s\S]*?\})\s*```", text, flags=re.IGNORECASE)
    for block in reversed(json_block_matches):
        try:
            payload = json.loads(block)
        except Exception:
            continue
        extracted = _extract_constraint_review_summary_from_json_payload(payload)
        if extracted:
            return extracted

    try:
        direct_payload = json.loads(text.strip())
    except Exception:
        direct_payload = None
    extracted = _extract_constraint_review_summary_from_json_payload(direct_payload)
    if extracted:
        return extracted

    embedded_payload = _extract_first_json_object(text)
    extracted = _extract_constraint_review_summary_from_json_payload(embedded_payload)
    if extracted:
        return extracted

    field_prefix = r"(?:^|\n)\s*(?:[-*]\s*)?(?:\*{0,2})?"
    field_suffix = r"(?:\*{0,2})?\s*[:：]\s*"
    scalar_patterns = {
        "overall_score": [
            field_prefix + r"overall_score" + field_suffix + r"([0-9]+(?:\.[0-9]+)?)",
            r"internal\s+rule\s+total\s+score\s*[:：]\s*([0-9]+(?:\.[0-9]+)?)",
            r"\|\s*\*{0,2}overall_score\*{0,2}\s*\|\s*([0-9]+(?:\.[0-9]+)?)\s*/\s*100",
        ],
        "effectiveness_score": [
            field_prefix + r"effectiveness_score" + field_suffix + r"([0-9]+(?:\.[0-9]+)?)",
            r"effectiveness\s+score\s*[:：]\s*([0-9]+(?:\.[0-9]+)?)",
            r"\|\s*\*{0,2}effectiveness_score\*{0,2}\s*\|\s*([0-9]+(?:\.[0-9]+)?)\s*/\s*100",
        ],
        "quality_score": [
            field_prefix + r"quality_score" + field_suffix + r"([0-9]+(?:\.[0-9]+)?)",
            r"quality\s+score\s*[:：]\s*([0-9]+(?:\.[0-9]+)?)",
            r"\|\s*\*{0,2}quality_score\*{0,2}\s*\|\s*([0-9]+(?:\.[0-9]+)?)\s*/\s*100",
        ],
    }
    for key, pattern_list in scalar_patterns.items():
        for pattern in pattern_list:
            match = re.search(pattern, text, flags=re.IGNORECASE)
            if match:
                summary[key] = float(match.group(1))
                break
    passed_match = re.search(
        field_prefix + r"(?:constraints_passed|constraints\s+passed)" + field_suffix + r"([0-9]+)\s*/\s*([0-9]+)",
        text,
        flags=re.IGNORECASE,
    )
    if not passed_match:
        passed_match = re.search(
            r"\|\s*\*{0,2}constraints_passed\*{0,2}\s*\|\s*([0-9]+)\s*/\s*([0-9]+)\s*\|",
            text,
            flags=re.IGNORECASE,
        )
    if passed_match:
        summary["constraints_passed"] = int(passed_match.group(1))
        summary["constraints_total"] = int(passed_match.group(2))
    return summary


def _extract_constraint_review_summary_from_json_payload(payload) -> dict:
    if not isinstance(payload, dict) or "overall_score" not in payload:
        return {}
    summary = {}
    if isinstance(payload.get("overall_score"), (int, float)):
        summary["overall_score"] = float(payload["overall_score"])
    if isinstance(payload.get("passed_constraints"), list):
        normalized_passed = []
        for item in payload.get("passed_constraints") or []:
            if not isinstance(item, dict):
                continue
            constraint_id = str(item.get("constraint_id") or "").strip()
            score = item.get("score")
            if not constraint_id:
                continue
            try:
                score_value = float(score)
            except Exception:
                score_value = 0.0
            normalized_passed.append({
                "constraint_id": constraint_id,
                "score": round(score_value, 1),
            })
        summary["passed_constraints"] = normalized_passed
        summary["constraints_passed"] = len(normalized_passed)
    if isinstance(payload.get("unmet_constraint_ids"), list):
        summary["unmet_constraint_ids"] = [
            str(item).strip()
            for item in payload.get("unmet_constraint_ids") or []
            if str(item).strip()
        ]
        if "constraints_passed" in summary:
            summary["constraints_total"] = summary["constraints_passed"] + len(summary["unmet_constraint_ids"])
    if isinstance(payload.get("public_constraint_results"), list):
        normalized_public_results = []
        for item in payload.get("public_constraint_results") or []:
            if not isinstance(item, dict):
                continue
            constraint_id = str(item.get("constraint_id") or "").strip()
            if not constraint_id:
                continue
            try:
                score_value = float(item.get("score"))
            except Exception:
                score_value = 0.0
            normalized_public_results.append({
                "constraint_id": constraint_id,
                "constraint_ref": str(item.get("constraint_ref") or "").strip(),
                "name": str(item.get("name") or "").strip(),
                "score": round(score_value, 1),
                "passed": bool(item.get("passed")),
            })
        summary["public_constraint_results"] = normalized_public_results
    scalar_passed = payload.get("constraints_passed")
    scalar_total = payload.get("constraints_total")
    if isinstance(scalar_passed, (int, float)):
        summary["constraints_passed"] = int(scalar_passed)
    if isinstance(scalar_total, (int, float)):
        summary["constraints_total"] = int(scalar_total)
    for key in ("passed_items", "failed_items"):
        items = payload.get(key)
        if not isinstance(items, list):
            continue
        normalized_items = []
        for item in items[:5]:
            if not isinstance(item, dict):
                continue
            constraint_id = str(item.get("constraint_id") or "").strip()
            reason = str(item.get("reason") or "").strip()
            score = item.get("score")
            normalized = {}
            if constraint_id:
                normalized["constraint_id"] = constraint_id
            if isinstance(score, (int, float)):
                normalized["score"] = float(score)
            if reason:
                normalized["reason"] = reason
            if normalized:
                normalized_items.append(normalized)
        if normalized_items:
            summary[key] = normalized_items
    return summary


def _extract_static_review_summary(output_text: str) -> dict:
    text = output_text or ""

    json_block_matches = re.findall(r"```json\s*(\{[\s\S]*?\})\s*```", text, flags=re.IGNORECASE)
    for block in reversed(json_block_matches):
        try:
            payload = json.loads(block)
        except Exception:
            continue
        extracted = _extract_static_review_summary_from_json_payload(payload)
        if extracted:
            return extracted

    try:
        direct_payload = json.loads(text.strip())
    except Exception:
        direct_payload = None
    extracted = _extract_static_review_summary_from_json_payload(direct_payload)
    if extracted:
        return extracted

    embedded_payload = _extract_first_json_object(text)
    extracted = _extract_static_review_summary_from_json_payload(embedded_payload)
    if extracted:
        return extracted

    total_match = re.search(r"\"?total_score\"?\s*[:：]\s*([0-9]+(?:\.[0-9]+)?)", text, flags=re.IGNORECASE)
    if total_match:
        score = float(total_match.group(1))
        return {"quality_score": score, "overall_score": score}
    markdown_total_match = re.search(
        r"\|\s*\*{0,2}(?:总分|total score)\*{0,2}\s*\|\s*\*{0,2}([0-9]+(?:\.[0-9]+)?)\s*/\s*100\*{0,2}\s*\|",
        text,
        flags=re.IGNORECASE,
    )
    if markdown_total_match:
        score = float(markdown_total_match.group(1))
        return {"quality_score": score, "overall_score": score}

    prose_patterns = [
        r"(?:最终分数|总分)\s*[:：]\s*`?([0-9]+(?:\.[0-9]+)?)\s*/\s*100`?",
        r"(?:最终分数|总分)\s*[:：]\s*`?([0-9]+(?:\.[0-9]+)?)\s*分\s*/\s*100\s*分`?",
        r"(?:最终分数|总分)\s*[:：]\s*([0-9]+(?:\.[0-9]+)?)\s*分",
    ]
    for pattern in prose_patterns:
        match = re.search(pattern, text, flags=re.IGNORECASE)
        if match:
            score = float(match.group(1))
            return {"quality_score": score, "overall_score": score}
    return {}


def _extract_static_review_summary_from_json_payload(payload) -> dict:
    if not isinstance(payload, dict):
        return {}
    summary = {}
    overall = payload.get("overall_score")
    if isinstance(overall, (int, float)):
        summary["overall_score"] = float(overall)
    overall_conclusion = payload.get("overall_conclusion")
    if isinstance(overall_conclusion, dict):
        total_score = overall_conclusion.get("total_score")
        if isinstance(total_score, (int, float)):
            summary["quality_score"] = float(total_score)
            summary.setdefault("overall_score", float(total_score))
    quality = payload.get("quality_score")
    if isinstance(quality, (int, float)):
        summary["quality_score"] = float(quality)
    for key in ("strengths", "main_issues"):
        values = payload.get(key)
        if isinstance(values, list):
            summary[key] = [
                str(item).strip()
                for item in values[:3]
                if str(item).strip()
            ]
    score_details = payload.get("score_details")
    if isinstance(score_details, list):
        normalized_details = []
        for item in score_details[:5]:
            if not isinstance(item, dict):
                continue
            name = str(item.get("item") or "").strip()
            impact = str(item.get("impact") or "").strip()
            reason = str(item.get("reason") or "").strip()
            score_delta = item.get("score_delta")
            normalized = {}
            if name:
                normalized["item"] = name
            if impact in {"+", "-"}:
                normalized["impact"] = impact
            if isinstance(score_delta, (int, float)):
                normalized["score_delta"] = float(score_delta)
            if reason:
                normalized["reason"] = reason
            if normalized:
                normalized_details.append(normalized)
        if normalized_details:
            summary["score_details"] = normalized_details
    return summary


def _extract_static_review_summary_from_file(case_dir: str) -> tuple[dict, str]:
    candidate_paths = [
        os.path.join(case_dir, "bug_fix_score_result.json"),
        os.path.join(static_dir(case_dir), "bug_fix_score_result.json"),
        os.path.join(case_dir, "evaluation_result.json"),
        os.path.join(static_dir(case_dir), "evaluation_result.json"),
        os.path.join(case_dir, "harmonyos_gen_code_evaluation.json"),
        os.path.join(static_dir(case_dir), "harmonyos_gen_code_evaluation.json"),
        os.path.join(case_dir, "harmonyos_gen_code_evaluation_result.json"),
        os.path.join(static_dir(case_dir), "harmonyos_gen_code_evaluation_result.json"),
    ]
    for base_dir in [case_dir, static_dir(case_dir)]:
        if not os.path.isdir(base_dir):
            continue
        for name in sorted(os.listdir(base_dir)):
            if not (name.endswith("_score_result.json") or name.endswith("_evaluation.json") or name.endswith("_evaluation_result.json")):
                continue
            candidate_paths.append(os.path.join(base_dir, name))

    seen = set()
    for score_path in candidate_paths:
        normalized = os.path.abspath(score_path)
        if normalized in seen or not os.path.exists(normalized):
            continue
        seen.add(normalized)
        try:
            with open(normalized, "r", encoding="utf-8") as f:
                payload = json.load(f)
        except Exception:
            continue
        summary = _extract_static_review_summary_from_json_payload(payload)
        if summary:
            return summary, normalized
    return {}, ""


def _write_json_file(path: str, payload: dict):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        json.dump(payload or {}, f, ensure_ascii=False, indent=2)


def _write_constraint_review_result_file(case_dir: str, summary: dict) -> str:
    result_path = os.path.join(review_dir(case_dir), "constraint_review_result.json")
    payload = {
        "overall_score": summary.get("overall_score"),
        "constraints_passed": summary.get("constraints_passed"),
        "constraints_total": summary.get("constraints_total"),
        "passed_items": summary.get("passed_items") or [],
        "failed_items": summary.get("failed_items") or [],
    }
    _write_json_file(result_path, payload)
    return result_path


def _write_static_review_result_file(case_dir: str, summary: dict) -> str:
    result_path = os.path.join(static_dir(case_dir), "harmonyos_evaluation_result.json")
    score = summary.get("quality_score")
    if score is None:
        score = summary.get("overall_score")
    payload = {
        "overall_conclusion": {
            "total_score": score,
        },
        "strengths": summary.get("strengths") or [],
        "main_issues": summary.get("main_issues") or [],
        "score_details": summary.get("score_details") or [],
    }
    _write_json_file(result_path, payload)
    return result_path


def _build_constraint_review_failure_reason(output_text: str,
                                            metrics: dict | None,
                                            last_error_message: str) -> str:
    if last_error_message:
        return str(last_error_message).strip()
    if (output_text or "").strip():
        return ""

    reason = "constraint review agent returned empty output"
    parts = _metrics_message_parts(metrics or {})
    if isinstance(parts, list) and parts:
        last_part = parts[-1] if isinstance(parts[-1], dict) else {}
        part_type = str(last_part.get("type") or "").strip()
        if part_type:
            reason += f"; last_part={part_type}"
        tool_name = str(last_part.get("tool") or "").strip()
        state = last_part.get("state") if isinstance(last_part.get("state"), dict) else {}
        status = str(state.get("status") or "").strip()
        if tool_name:
            reason += f":{tool_name}"
        if status:
            reason += f"({status})"
    return reason


def _prepare_constraint_review_patch_for_workspace(patch_path: str,
                                                   workspace_dir: str,
                                                   on_progress) -> str:
    patch_source = str(patch_path or "").strip()
    if not patch_source or not os.path.isfile(patch_source):
        return ""
    try:
        review_support_dir = os.path.join(workspace_dir, ".agent_bench")
        os.makedirs(review_support_dir, exist_ok=True)
        workspace_patch_path = os.path.join(review_support_dir, "constraint_review_changes.patch")
        shutil.copyfile(patch_source, workspace_patch_path)
        _notify(on_progress, "log", {
            "level": "INFO",
            "message": f"constraint review patch copied into workspace: {workspace_patch_path}",
        })
        return workspace_patch_path
    except Exception as exc:
        _notify(on_progress, "log", {
            "level": "WARNING",
            "message": f"failed to copy constraint review patch into workspace, fallback to original patch path: {exc}",
        })
        return patch_source


def _run_constraint_review_attempt(case: dict,
                                   case_dir: str,
                                   original_dir: str,
                                   workspace_dir: str,
                                   repair_patch_file: str,
                                   on_progress,
                                   agent_timeout: int,
                                   stage_label: str) -> tuple[dict, str]:
    agent_spec = load_agent_spec("constraint_score_agent")
    review_prompt = build_constraint_review_prompt(
        case=case,
        original_project_root=original_dir,
        repaired_project_root=workspace_dir,
        repair_patch_file=repair_patch_file,
        agent_spec=agent_spec,
    )
    runtime = AgentRunner(
        agent_spec=agent_spec,
        runtime_options={},
        on_progress=on_progress,
        fallback_timeout=agent_timeout,
        artifact_prefix="constraint_review",
        artifact_base_dir="constraint",
    )
    output_text = ""
    elapsed = 0.0
    try:
        _notify(on_progress, "log", {
            "level": "INFO",
            "message": f"constraint review attempt: {stage_label}",
        })
        runtime.prepare()
        output_text, elapsed = runtime.execute(
            review_prompt,
            workspace_dir=workspace_dir,
            tag=f"[{agent_spec.display_name}] ",
        )
        last_error_message = runtime.get_last_error_message()
        metrics = runtime.get_last_interaction_metrics()
        save_review_agent_artifacts(
            case_dir,
            "constraint_review",
            output_text,
            task_prompt=review_prompt,
            metrics=metrics,
        )
        _log_skill_call_detection(
            case["id"],
            agent_spec.display_name,
            case_dir,
            "constraint_review",
            output_text,
            on_progress,
            [item.name for item in agent_spec.mounted_skills],
        )
        failure_reason = _build_constraint_review_failure_reason(
            output_text=output_text,
            metrics=metrics,
            last_error_message=last_error_message,
        )
        if failure_reason:
            raise RuntimeError(failure_reason)
        summary = _extract_constraint_review_summary(output_text)
        if not summary:
            raise RuntimeError("constraint review summary extraction failed")
        result = {
            "status": "completed",
            "agent": {
                "id": agent_spec.id,
                "name": agent_spec.display_name,
                "model": agent_spec.model,
            },
            "output_path": os.path.join(review_dir(case_dir), "constraint_review_output.txt"),
            "metrics_path": os.path.join(review_dir(case_dir), "constraint_review_interaction_metrics.json"),
            "summary": summary,
            "_task_prompt": review_prompt,
            "_metrics": metrics,
            "_elapsed": elapsed,
            "_stage_label": stage_label,
        }
        return result, output_text
    finally:
        runtime.teardown()


def _run_constraint_review_agent(case: dict,
                                 case_dir: str,
                                 original_dir: str,
                                 workspace_dir: str,
                                 patch_path: str,
                                 on_progress,
                                 agent_timeout: int):
    case_spec = case.get("case_spec") or {}
    constraints = case_spec.get("constraints") or []
    if not constraints:
        _notify(on_progress, "log", {"level": "INFO", "message": "current case has no constraints, skip constraint review"})
        return {
            "status": "skipped",
            "reason": "no_constraints",
        }

    agent_spec = load_agent_spec("constraint_score_agent")
    if not agent_spec:
        _notify(on_progress, "log", {"level": "ERROR", "message": "missing agent config: constraint_score_agent"})
        return {
            "status": "error",
            "reason": "missing_agent_config",
        }

    workspace_patch_path = _prepare_constraint_review_patch_for_workspace(
        patch_path=patch_path,
        workspace_dir=workspace_dir,
        on_progress=on_progress,
    )
    last_exc = None
    attempt_specs = [
        ("workspace_patch", workspace_patch_path or patch_path or ""),
    ]
    if workspace_patch_path or patch_path:
        attempt_specs.append(("workspace_only_fallback", ""))

    _notify(on_progress, "stage_start", {"case_id": case["id"], "stage": "constraint_review"})
    try:
        for stage_label, repair_patch_file in attempt_specs:
            try:
                result, output_text = _run_constraint_review_attempt(
                    case=case,
                    case_dir=case_dir,
                    original_dir=original_dir,
                    workspace_dir=workspace_dir,
                    repair_patch_file=repair_patch_file,
                    on_progress=on_progress,
                    agent_timeout=agent_timeout,
                    stage_label=stage_label,
                )
                metrics = result.pop("_metrics")
                save_review_agent_artifacts(
                    case_dir,
                    "constraint_review",
                    output_text,
                    task_prompt=result.pop("_task_prompt"),
                    metrics=metrics,
                )
                elapsed = result.pop("_elapsed")
                result.pop("_stage_label", None)
                _notify(on_progress, "log", {
                    "level": "WARNING",
                    "message": _format_completion_message("Agent处理完成", output_text, elapsed, metrics),
                })
                _notify(on_progress, "log", {
                    "level": "INFO",
                    "message": _format_constraint_score_message(result.get("summary") or {}),
                })
                constraint_result_file = _write_constraint_review_result_file(case_dir, result.get("summary") or {})
                _notify(on_progress, "log", {
                    "level": "INFO",
                    "message": f"约束规则打分结果文件已写入: {constraint_result_file}",
                })
                result["result_file"] = constraint_result_file
                if output_text:
                    _notify(on_progress, "log", {
                        "level": "WARNING",
                        "message": f"{agent_spec.display_name} output preview:\n{_clip_text(output_text, MAX_LOGGED_OUTPUT_CHARS)}",
                    })
                _notify(on_progress, "stage_done", {"case_id": case["id"], "stage": "constraint_review", "elapsed": elapsed})
                return result
            except Exception as exc:
                last_exc = exc
                _notify(on_progress, "log", {
                    "level": "WARNING",
                    "message": f"constraint review attempt failed ({stage_label}): {exc}",
                })
                continue

        raise RuntimeError(str(last_exc) if last_exc else "constraint review failed")
    except Exception as exc:
        _notify(on_progress, "log", {"level": "ERROR", "message": f"constraint review failed: {exc}"})
        return {
            "status": "error",
            "reason": str(exc),
            "output_path": os.path.join(review_dir(case_dir), "constraint_review_output.txt"),
            "metrics_path": os.path.join(review_dir(case_dir), "constraint_review_interaction_metrics.json"),
        }


def _run_static_review_agent(case: dict,
                             case_dir: str,
                             original_dir: str,
                             workspace_dir: str,
                             patch_path: str,
                             on_progress,
                             agent_timeout: int):
    agent_spec = load_agent_spec("static_code_score_agent")
    if not agent_spec:
        _notify(on_progress, "log", {"level": "ERROR", "message": "missing agent config: static_code_score_agent"})
        return {
            "status": "error",
            "reason": "missing_agent_config",
        }

    review_prompt = build_static_review_prompt(
        case=case,
        original_project_root=original_dir,
        repaired_project_root=workspace_dir,
        repair_patch_file=patch_path,
        agent_spec=agent_spec,
    )
    runtime = AgentRunner(
        agent_spec=agent_spec,
        runtime_options={},
        on_progress=on_progress,
        fallback_timeout=agent_timeout,
        artifact_prefix="static_review",
        artifact_base_dir="static",
    )
    output_text = ""
    elapsed = 0.0
    _notify(on_progress, "stage_start", {"case_id": case["id"], "stage": "static_review"})
    try:
        runtime.prepare()
        output_text, elapsed = runtime.execute(
            review_prompt,
            workspace_dir=case_dir,
            tag=f"[{agent_spec.display_name}] ",
        )
        last_error_message = runtime.get_last_error_message()
        metrics = runtime.get_last_interaction_metrics()
        save_review_agent_artifacts(
            case_dir,
            "static_review",
            output_text,
            task_prompt=review_prompt,
            metrics=metrics,
        )
        _log_skill_call_detection(
            case["id"],
            agent_spec.display_name,
            case_dir,
            "static_review",
            output_text,
            on_progress,
            [item.name for item in agent_spec.mounted_skills],
        )
        if not output_text and last_error_message:
            raise RuntimeError(last_error_message)
        if not output_text.strip():
            raise RuntimeError("static review produced empty output")
        _notify(on_progress, "log", {
            "level": "WARNING",
            "message": _format_completion_message("Agent处理完成", output_text, elapsed, metrics),
        })
        if output_text:
            _notify(on_progress, "log", {
                "level": "WARNING",
                "message": f"{agent_spec.display_name} output preview:\n{_clip_text(output_text, MAX_LOGGED_OUTPUT_CHARS)}",
            })
        summary = {}
        summary_source = "none"
        summary, summary_file_path = _extract_static_review_summary_from_file(case_dir)
        if summary:
            summary_source = f"json_file:{summary_file_path}"
        if not summary:
            summary = _extract_static_review_summary(output_text)
            if summary:
                summary_source = "model_output"
        if not summary:
            raise RuntimeError("static review summary extraction failed")
        static_result_file = _write_static_review_result_file(case_dir, summary)
        _notify(on_progress, "log", {
            "level": "INFO",
            "message": _format_static_score_message(summary, summary_source),
        })
        _notify(on_progress, "log", {
            "level": "INFO",
            "message": f"{agent_spec.display_name} 分数来源: {summary_source}",
        })
        _notify(on_progress, "log", {
            "level": "INFO",
            "message": f"静态代码打分结果文件已写入: {static_result_file}",
        })
        _notify(on_progress, "stage_done", {"case_id": case["id"], "stage": "static_review", "elapsed": elapsed})
        return {
            "status": "completed",
            "agent": {
                "id": agent_spec.id,
                "name": agent_spec.display_name,
                "model": agent_spec.model,
            },
            "output_path": os.path.join(static_dir(case_dir), "static_review_output.txt"),
            "metrics_path": os.path.join(static_dir(case_dir), "static_review_interaction_metrics.json"),
            "summary": summary,
            "summary_source": summary_source,
            "result_file": static_result_file,
        }
    except Exception as exc:
        _notify(on_progress, "log", {"level": "ERROR", "message": f"static review failed: {exc}"})
        return {
            "status": "error",
            "reason": str(exc),
            "output_path": os.path.join(static_dir(case_dir), "static_review_output.txt"),
            "metrics_path": os.path.join(static_dir(case_dir), "static_review_interaction_metrics.json"),
        }
    finally:
        runtime.teardown()


def _run_compile_check(case: dict,
                       case_dir: str,
                       project_path: str,
                       stage_name: str,
                       stage_label: str,
                       on_progress):
    template_project_path = resolve_case_original_project(case)
    _notify(on_progress, "stage_start", {"case_id": case["id"], "stage": stage_name})
    _notify(on_progress, "log", {
        "level": "INFO",
        "message": f"{stage_label} 已开始，过程可能较长，请稍候...",
    })
    _notify(on_progress, "log", {"level": "WARNING", "message": f"[开始] {stage_label}"})
    t0 = time.time()
    compile_result = check_project_compilable(
        project_path,
        timeout=300,
        template_project_path=template_project_path,
    )
    elapsed = time.time() - t0
    save_compile_artifacts(case_dir, stage_name, compile_result)
    if compile_result.get("compilable"):
        _notify(on_progress, "log", {
            "level": "INFO",
            "message": f"[结束] {stage_label}: 编译通过 ({elapsed:.1f}s)",
        })
    else:
        _notify(on_progress, "log", {
            "level": "ERROR",
            "message": f"[结束] {stage_label}: 编译失败 ({elapsed:.1f}s)",
        })
        error_preview = _clip_text(str(compile_result.get("error") or "").strip(), 1200)
        if error_preview:
            _notify(on_progress, "log", {
                "level": "ERROR",
                "message": f"{stage_label} 错误摘要:\n{error_preview}",
            })
    _notify(on_progress, "stage_done", {"case_id": case["id"], "stage": stage_name, "status": "done", "elapsed": elapsed})
    return compile_result


def run_single_case(case: dict,
                    case_dir: str,
                    stages: list = None,
                    dry_run: bool = False,
                    on_progress: Callable = None,
                    agent_config: dict = None,
                    agent_timeout: int = 180,
                    agent_temperature: float = None) -> dict:
    stages = stages or ["runner"]
    case["_agent_config"] = agent_config or {}
    case_id = case["id"]
    prompt = case["prompt"]
    os.makedirs(case_dir, exist_ok=True)
    _notify(on_progress, "log", {"level": "INFO", "message": f"开始处理用例: {case['title']}"})

    agent = agent_config
    if not agent:
        raise ValueError("缺少 agent 配置")
    agent_spec = build_agent_spec(agent)
    task_prompt = build_agent_task_prompt(case, prompt, on_progress, agent_spec)

    if "runner" in stages:
        output_path = os.path.join(agent_meta_dir(case_dir), "output.txt")
        if os.path.exists(output_path):
            _notify(on_progress, "log", {"level": "INFO", "message": "Runner 产物已存在，跳过 Agent 执行（复用缓存）"})
            output_text = load_runner_artifacts(case_dir)
        else:
            template_project_path = resolve_case_original_project(case)
            if not template_project_path:
                raise FileNotFoundError(f"[{case_id}] 未找到 original_project 模板")
            workspace_dir = agent_workspace_dir(case_dir)
            prepare_project_workspace(template_project_path, workspace_dir)
            workspace_base_commit = _initialize_workspace_git(case_dir, workspace_dir, on_progress)
            pre_compile_result = _run_compile_check(
                case,
                case_dir,
                workspace_dir,
                "pre_compile_check",
                "预编译验证",
                on_progress,
            )
            case["_pre_compile_result"] = pre_compile_result
            runtime = AgentRunner(
                agent_spec=agent_spec,
                runtime_options={},
                on_progress=on_progress,
                fallback_timeout=agent_timeout,
                artifact_prefix="agent",
                artifact_base_dir="generate",
            )
            try:
                _notify(on_progress, "stage_start", {"case_id": case_id, "stage": "Agent处理"})
                runtime.prepare()
                output_text, elapsed = runtime.execute(
                    task_prompt,
                    workspace_dir=workspace_dir,
                    tag=f"[{agent_spec.display_name}] ",
                )
                last_error_message = runtime.get_last_error_message()
                if not output_text and last_error_message:
                    raise RuntimeError(last_error_message)
            finally:
                metrics = runtime.get_last_interaction_metrics()
                save_interaction_metrics(case_dir, "agent", metrics)
                runtime.teardown()
            save_runner_artifacts(case_dir, output_text, task_prompt=task_prompt)
            _notify(on_progress, "log", {
                "level": "WARNING",
                "message": _format_completion_message("Agent处理完成", output_text, elapsed, metrics),
            })
            if output_text:
                _notify(on_progress, "log", {"level": "WARNING", "message": f"{agent_spec.display_name} 输出预览:\n{_clip_text(output_text, MAX_LOGGED_OUTPUT_CHARS)}"})
            case["_agent_elapsed_s"] = int(elapsed)
            _notify(on_progress, "stage_done", {"case_id": case_id, "stage": "Agent处理", "elapsed": elapsed})
            post_compile_result = _run_compile_check(
                case,
                case_dir,
                workspace_dir,
                "post_compile_check",
                "Agent 修改后编译验证",
                on_progress,
            )
            case["_post_compile_result"] = post_compile_result
            patch_path = _generate_review_patch(case_dir, workspace_dir, workspace_base_commit, on_progress)
            _notify(on_progress, "artifacts_ready", {
                "case_id": case_id,
                "workspace_dir": workspace_dir,
                "patch_path": patch_path,
            })
            case["_constraint_review_result"] = _run_constraint_review_agent(
                case=case,
                case_dir=case_dir,
                original_dir=original_project_dir(case_dir),
                workspace_dir=workspace_dir,
                patch_path=patch_path,
                on_progress=on_progress,
                agent_timeout=agent_timeout,
            )
            _ensure_review_stage_succeeded(case["_constraint_review_result"], "约束规则打分")
            case["_static_review_result"] = _run_static_review_agent(
                case=case,
                case_dir=case_dir,
                original_dir=original_project_dir(case_dir),
                workspace_dir=workspace_dir,
                patch_path=patch_path,
                on_progress=on_progress,
                agent_timeout=agent_timeout,
            )
            _ensure_review_stage_succeeded(case["_static_review_result"], "静态代码打分")
            _log_skill_call_detection(
                case_id,
                agent_spec.display_name,
                case_dir,
                "agent",
                output_text,
                on_progress,
                [item.name for item in agent_spec.mounted_skills],
            )

    result = _build_runner_only_result(case, case_dir, agent)
    save_case_result(case_dir, result)
    return result
