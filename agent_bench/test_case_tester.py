# -*- coding: utf-8 -*-
"""单用例本地测试入口。

用途：
1. 复制 case 对应的 original_project 到独立测试目录
2. 对原始工程执行编译检查和 constraint 评分
3. 调用配置的 Agent 在独立工作区内按 case prompt 修复代码
4. 对修复后工程再次执行编译检查和 constraint 评分
5. 将每次测试结果保存到 agent_bench/test_runs/<run_id>/cases/<case_id> 下
"""

from __future__ import annotations

import argparse
import json
import os
import shutil
import sys
from datetime import datetime
from typing import Dict, Optional, Tuple

from agent_bench.evaluator.constraint_scorer import (
    append_constraint_review_report,
    build_constraint_review_report,
    build_constraint_review_skill,
    evaluate_constraints,
    strip_constraint_review_report,
)
from agent_bench.pipeline.compile_checker import (
    check_project_compilable,
    prepare_project_workspace,
)
from agent_bench.pipeline.loader import (
    BASE_DIR,
    build_agent_runtime_enhancements,
    get_all_scenarios,
    load_agent,
    load_agent_defaults,
    load_enhancements,
    load_test_cases,
    merge_enhancements,
    resolve_case_original_project,
)
from agent_bench.runner.factory import create_adapter


TEST_RUNS_DIR = os.path.join(BASE_DIR, "test_runs")
TASK_PROMPT = """{prompt}"""
TASK_PROMPT_MULTI_PAGE = """{prompt}

## 参考补充文件
{additional_pages}
"""


def _resolve_case(case_ref: str) -> Tuple[str, dict]:
    normalized = os.path.normpath(str(case_ref or "").strip())
    if not normalized:
        raise ValueError("请提供测试用例目录或 case_id，例如 bug_fix_001")

    if os.path.isdir(normalized):
        abs_case_dir = os.path.abspath(normalized)
    else:
        abs_case_dir = os.path.abspath(os.path.join(os.getcwd(), normalized))

    if os.path.isdir(abs_case_dir):
        scenario = os.path.basename(os.path.dirname(abs_case_dir))
        case_no = os.path.basename(abs_case_dir)
        if not scenario or not case_no.isdigit():
            raise ValueError(f"无法从目录解析用例: {case_ref}")
        case_id = f"{scenario}_{case_no}"
    else:
        case_id = normalized.replace("\\", "/").strip()
        if "_" not in case_id or not case_id.rsplit("_", 1)[-1].isdigit():
            raise ValueError(f"无法识别用例引用: {case_ref}")

    for scenario_meta in get_all_scenarios():
        scenario_name = scenario_meta.get("name")
        if not scenario_name:
            continue
        cases = load_test_cases(scenario_name)
        for case in cases:
            if case.get("id") == case_id:
                return scenario_name, case

    raise FileNotFoundError(f"未找到测试用例: {case_ref}")


def _build_task_prompt(case: dict) -> str:
    prompt = case.get("prompt", "") or ""
    additional_files = case.get("additional_files", {}) or {}
    sibling_files = additional_files.get("sibling_files", {}) or {}
    pages_files = additional_files.get("pages", {}) or {}
    if sibling_files or pages_files:
        all_additional = {**sibling_files, **pages_files}
        additional_pages_text = "\n\n".join(
            f"=== {filename} ===\n{content}" for filename, content in all_additional.items()
        )
        return TASK_PROMPT_MULTI_PAGE.format(
            prompt=prompt,
            additional_pages=additional_pages_text,
        )
    return TASK_PROMPT.format(prompt=prompt)


def _pick_agent(agent_id: Optional[str]) -> dict:
    if agent_id:
        agent = load_agent(agent_id)
        if not agent:
            raise ValueError(f"未找到 agent: {agent_id}")
        return agent

    preferred_ids = ["codex_local", "agent_default"]
    for candidate in preferred_ids:
        agent = load_agent(candidate)
        if agent:
            return agent

    defaults = load_agent_defaults()
    if defaults:
        return defaults
    raise ValueError("未找到可用的 Agent 配置")


def _case_result_dir(run_id: str, case_id: str) -> str:
    return os.path.join(TEST_RUNS_DIR, run_id, "cases", case_id)


def _to_abs_case_path(path: str) -> str:
    raw = str(path or "").strip()
    if not raw:
        return ""
    return raw if os.path.isabs(raw) else os.path.join(BASE_DIR, raw)


def _resolve_original_project_path(case: dict) -> str:
    direct = _to_abs_case_path(case.get("original_project_dir", ""))
    if direct and os.path.isdir(direct):
        return direct

    fallback = resolve_case_original_project(case)
    fallback = _to_abs_case_path(fallback)
    if fallback and os.path.isdir(fallback):
        return fallback

    return direct or fallback or ""


def _write_text(path: str, content: str) -> None:
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        f.write(content)


def _write_json(path: str, data: dict) -> None:
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)


def _load_json_if_exists(path: str) -> dict:
    if not os.path.isfile(path):
        return {}
    try:
        with open(path, "r", encoding="utf-8") as f:
            data = json.load(f)
        return data if isinstance(data, dict) else {}
    except Exception:
        return {}


def _load_text_if_exists(path: str) -> str:
    if not os.path.isfile(path):
        return ""
    try:
        with open(path, "r", encoding="utf-8") as f:
            return f.read()
    except Exception:
        return ""


def _copy_case_yaml(case: dict, case_result_dir: str) -> None:
    case_dir = case.get("case_dir", "")
    if not case_dir:
        return
    src = os.path.join(BASE_DIR, case_dir, "case.yaml")
    if os.path.isfile(src):
        shutil.copy2(src, os.path.join(case_result_dir, "case.yaml"))


def _score_workspace(case: dict,
                     workspace_dir: str,
                     output_text: str,
                     original_project_root: str = "",
                     repair_patch_file: str = "") -> dict:
    clean_output = strip_constraint_review_report(output_text or "")
    case_spec = case.get("case_spec") or {}
    if not case_spec:
        return {
            "summary": {
                "overall_score": 0.0,
                "effectiveness_score": 0.0,
                "quality_score": 0.0,
            "constraints_total": 0,
            "constraints_passed": 0,
            },
            "items": [],
            "report_text": "",
            "display_output": clean_output,
            "skill": {},
        }

    score_result = evaluate_constraints(case_spec, workspace_dir)
    report_text = build_constraint_review_report(score_result)
    display_output = append_constraint_review_report(clean_output, report_text)
    return {
        **score_result,
        "report_text": report_text,
        "display_output": display_output,
        "skill": build_constraint_review_skill(
            case_spec,
            original_project_root=original_project_root,
            repair_patch_file=repair_patch_file,
            repaired_project_root=workspace_dir,
            case_prompt=case.get("prompt", "") or "",
        ),
    }


def _save_side_artifacts(side_dir: str,
                         workspace_dir: str,
                         compile_result: dict,
                         score_result: dict,
                         output_text: str,
                         task_prompt: Optional[str] = None,
                         agent_meta: Optional[dict] = None) -> None:
    os.makedirs(side_dir, exist_ok=True)
    if task_prompt is not None:
        _write_text(os.path.join(side_dir, "task_prompt.txt"), task_prompt)
    if output_text is not None:
        _write_text(os.path.join(side_dir, "raw_output.txt"), output_text or "")
        _write_text(
            os.path.join(side_dir, "output.txt"),
            score_result.get("display_output", output_text or ""),
        )
    _write_json(os.path.join(side_dir, "compile_result.json"), compile_result)
    _write_json(os.path.join(side_dir, "constraint_review_score.json"), score_result)
    _write_text(
        os.path.join(side_dir, "constraint_review_report.md"),
        score_result.get("report_text", ""),
    )
    skill_content = ((score_result.get("skill") or {}).get("content") or "").strip()
    if skill_content:
        _write_text(os.path.join(side_dir, "constraint_review_skill.md"), skill_content)
    if agent_meta is not None:
        _write_json(os.path.join(side_dir, "agent.json"), agent_meta)
    _write_text(os.path.join(side_dir, "workspace_path.txt"), workspace_dir)


def _run_original(case: dict, case_result_dir: str) -> Tuple[str, dict, dict]:
    original_template = _resolve_original_project_path(case)
    if not original_template or not os.path.isdir(original_template):
        raise FileNotFoundError(f"original_project 不存在: {original_template}")

    workspace_dir = os.path.join(case_result_dir, "original_workspace")
    prepare_project_workspace(original_template, workspace_dir)
    compile_result = check_project_compilable(
        workspace_dir,
        template_project_path=original_template,
    )
    output_text = "Original project snapshot without agent repair."
    score_result = _score_workspace(
        case,
        workspace_dir,
        output_text,
        original_project_root=original_template,
    )
    _save_side_artifacts(
        os.path.join(case_result_dir, "original"),
        workspace_dir,
        compile_result,
        score_result,
        output_text,
    )
    return workspace_dir, compile_result, score_result


def _run_repair(case: dict,
                scenario: str,
                case_result_dir: str,
                agent: dict,
                profile_name: Optional[str]) -> Tuple[str, dict, dict, str]:
    original_template = _resolve_original_project_path(case)
    if not original_template or not os.path.isdir(original_template):
        raise FileNotFoundError(f"original_project 不存在: {original_template}")

    workspace_dir = os.path.join(case_result_dir, "repaired_workspace")
    prepare_project_workspace(original_template, workspace_dir)

    task_prompt = _build_task_prompt(case)
    agent_runtime = build_agent_runtime_enhancements(agent)
    scenario_enhancements = load_enhancements(scenario, profile_name=profile_name)
    merged_enhancements = merge_enhancements(agent_runtime, scenario_enhancements or {})

    timeout = int(agent.get("timeout") or load_agent_defaults().get("timeout") or 480)
    adapter = create_adapter(agent, timeout=timeout, temperature=agent.get("temperature"))

    output_text = ""
    interaction_metrics = None
    try:
        adapter.setup(merged_enhancements)
        output_text = adapter.execute(task_prompt, tag=f"[{case['id']}][repair] ", workspace_dir=workspace_dir)
    finally:
        interaction_metrics = adapter.get_last_interaction_metrics()
        adapter.teardown()

    compile_result = check_project_compilable(
        workspace_dir,
        template_project_path=original_template,
    )
    score_result = _score_workspace(
        case,
        workspace_dir,
        output_text,
        original_project_root=original_template,
    )
    _save_side_artifacts(
        os.path.join(case_result_dir, "repaired"),
        workspace_dir,
        compile_result,
        score_result,
        output_text,
        task_prompt=task_prompt,
        agent_meta={
            "agent_id": agent.get("id") or agent.get("name") or "",
            "model": agent.get("model"),
            "adapter": agent.get("adapter"),
            "profile_name": profile_name,
            "interaction_metrics": interaction_metrics,
        },
    )
    return workspace_dir, compile_result, score_result, output_text


def _build_constraint_delta(original_score: dict, repaired_score: dict) -> list:
    original_items = {
        item.get("id"): item
        for item in (original_score.get("items") or [])
        if isinstance(item, dict) and item.get("id")
    }
    repaired_items = {
        item.get("id"): item
        for item in (repaired_score.get("items") or [])
        if isinstance(item, dict) and item.get("id")
    }

    rows = []
    all_ids = sorted(set(original_items) | set(repaired_items))
    for item_id in all_ids:
        before = original_items.get(item_id, {})
        after = repaired_items.get(item_id, {})
        before_score = float((before.get("score") or 0.0))
        after_score = float((after.get("score") or 0.0))
        rows.append({
            "id": item_id,
            "name": after.get("name") or before.get("name") or "",
            "priority": after.get("priority") or before.get("priority") or "",
            "before_score": round(before_score, 1),
            "after_score": round(after_score, 1),
            "delta": round(after_score - before_score, 1),
            "before_passed": bool(before.get("passed")),
            "after_passed": bool(after.get("passed")),
        })
    return rows


def _build_summary(case: dict,
                   scenario: str,
                   run_id: str,
                   case_result_dir: str,
                   original_compile: dict,
                   original_score: dict,
                   repaired_compile: dict,
                   repaired_score: dict,
                   agent: dict) -> dict:
    before = original_score.get("summary", {}) or {}
    after = repaired_score.get("summary", {}) or {}
    return {
        "run_id": run_id,
        "scenario": scenario,
        "case_id": case.get("id"),
        "title": case.get("title"),
        "case_result_dir": case_result_dir,
        "agent": {
            "id": agent.get("id") or agent.get("name") or "",
            "model": agent.get("model"),
            "adapter": agent.get("adapter"),
        },
        "original": {
            "compilable": bool(original_compile.get("compilable")),
            "compile_error": original_compile.get("error", ""),
            "score_summary": before,
        },
        "repaired": {
            "compilable": bool(repaired_compile.get("compilable")),
            "compile_error": repaired_compile.get("error", ""),
            "score_summary": after,
        },
        "delta": {
            "overall_score": round(float(after.get("overall_score", 0.0)) - float(before.get("overall_score", 0.0)), 1),
            "effectiveness_score": round(float(after.get("effectiveness_score", 0.0)) - float(before.get("effectiveness_score", 0.0)), 1),
            "quality_score": round(float(after.get("quality_score", 0.0)) - float(before.get("quality_score", 0.0)), 1),
            "constraints_passed": int(after.get("constraints_passed", 0) or 0) - int(before.get("constraints_passed", 0) or 0),
            "compile_status_changed": bool(repaired_compile.get("compilable")) != bool(original_compile.get("compilable")),
        },
        "constraint_deltas": _build_constraint_delta(original_score, repaired_score),
    }


def _render_summary_markdown(summary: dict) -> str:
    original = summary.get("original", {}) or {}
    repaired = summary.get("repaired", {}) or {}
    delta = summary.get("delta", {}) or {}

    lines = [
        f"# {summary.get('case_id')} Test Result",
        "",
        f"- Run ID: {summary.get('run_id')}",
        f"- Scenario: {summary.get('scenario')}",
        f"- Title: {summary.get('title')}",
        f"- Agent: {((summary.get('agent') or {}).get('id') or '')} / {((summary.get('agent') or {}).get('model') or '')}",
        "",
        "## Compile",
        "",
        f"- Original: {'PASS' if original.get('compilable') else 'FAIL'}",
        f"- Repaired: {'PASS' if repaired.get('compilable') else 'FAIL'}",
        "",
        "## Score Summary",
        "",
        "| Metric | Original | Repaired | Delta |",
        "| --- | ---: | ---: | ---: |",
        f"| overall_score | {(original.get('score_summary') or {}).get('overall_score', 0)} | {(repaired.get('score_summary') or {}).get('overall_score', 0)} | {delta.get('overall_score', 0)} |",
        f"| effectiveness_score | {(original.get('score_summary') or {}).get('effectiveness_score', 0)} | {(repaired.get('score_summary') or {}).get('effectiveness_score', 0)} | {delta.get('effectiveness_score', 0)} |",
        f"| quality_score | {(original.get('score_summary') or {}).get('quality_score', 0)} | {(repaired.get('score_summary') or {}).get('quality_score', 0)} | {delta.get('quality_score', 0)} |",
        f"| constraints_passed | {(original.get('score_summary') or {}).get('constraints_passed', 0)} | {(repaired.get('score_summary') or {}).get('constraints_passed', 0)} | {delta.get('constraints_passed', 0)} |",
        "",
        "## Constraint Deltas",
        "",
        "| Constraint | Priority | Before | After | Delta | Before Pass | After Pass |",
        "| --- | --- | ---: | ---: | ---: | --- | --- |",
    ]

    for row in summary.get("constraint_deltas", []) or []:
        lines.append(
            f"| {row.get('id')} {row.get('name')} | {row.get('priority')} | "
            f"{row.get('before_score', 0)} | {row.get('after_score', 0)} | {row.get('delta', 0)} | "
            f"{'Y' if row.get('before_passed') else 'N'} | {'Y' if row.get('after_passed') else 'N'} |"
        )

    lines.extend([
        "",
        "## Paths",
        "",
        f"- Result Dir: `{summary.get('case_result_dir')}`",
        f"- Original Artifacts: `{os.path.join(summary.get('case_result_dir') or '', 'original')}`",
        f"- Repaired Artifacts: `{os.path.join(summary.get('case_result_dir') or '', 'repaired')}`",
    ])
    return "\n".join(lines).strip() + "\n"


def _agent_meta_to_summary_agent(agent_meta: dict) -> dict:
    return {
        "id": agent_meta.get("agent_id") or agent_meta.get("id") or "",
        "model": agent_meta.get("model"),
        "adapter": agent_meta.get("adapter"),
    }


def _load_side_raw_output(side_dir: str) -> str:
    raw_output = _load_text_if_exists(os.path.join(side_dir, "raw_output.txt"))
    if raw_output:
        return strip_constraint_review_report(raw_output)
    output_text = _load_text_if_exists(os.path.join(side_dir, "output.txt"))
    return strip_constraint_review_report(output_text)


def _rescore_case_result_dir(case_result_dir: str) -> dict:
    case_id = os.path.basename(case_result_dir)
    scenario, case = _resolve_case(case_id)
    _copy_case_yaml(case, case_result_dir)

    original_side_dir = os.path.join(case_result_dir, "original")
    repaired_side_dir = os.path.join(case_result_dir, "repaired")
    original_workspace_dir = os.path.join(case_result_dir, "original_workspace")
    repaired_workspace_dir = os.path.join(case_result_dir, "repaired_workspace")

    if not os.path.isdir(original_workspace_dir) or not os.path.isdir(repaired_workspace_dir):
        raise FileNotFoundError("缺少 original_workspace 或 repaired_workspace，无法仅基于现有产物重打分")

    original_compile = _load_json_if_exists(os.path.join(original_side_dir, "compile_result.json"))
    repaired_compile = _load_json_if_exists(os.path.join(repaired_side_dir, "compile_result.json"))
    repaired_agent_meta = _load_json_if_exists(os.path.join(repaired_side_dir, "agent.json"))

    original_task_prompt = _load_text_if_exists(os.path.join(original_side_dir, "task_prompt.txt"))
    repaired_task_prompt = _load_text_if_exists(os.path.join(repaired_side_dir, "task_prompt.txt"))
    original_output = _load_side_raw_output(original_side_dir)
    repaired_output = _load_side_raw_output(repaired_side_dir)

    original_template = _resolve_original_project_path(case)
    original_score = _score_workspace(
        case,
        original_workspace_dir,
        original_output,
        original_project_root=original_template,
    )
    repaired_score = _score_workspace(
        case,
        repaired_workspace_dir,
        repaired_output,
        original_project_root=original_template,
    )

    _save_side_artifacts(
        original_side_dir,
        original_workspace_dir,
        original_compile,
        original_score,
        original_output,
        task_prompt=original_task_prompt or None,
    )
    _save_side_artifacts(
        repaired_side_dir,
        repaired_workspace_dir,
        repaired_compile,
        repaired_score,
        repaired_output,
        task_prompt=repaired_task_prompt or None,
        agent_meta=repaired_agent_meta or None,
    )

    summary = _build_summary(
        case,
        scenario,
        os.path.basename(os.path.dirname(os.path.dirname(case_result_dir))),
        case_result_dir,
        original_compile,
        original_score,
        repaired_compile,
        repaired_score,
        _agent_meta_to_summary_agent(repaired_agent_meta),
    )
    _write_json(os.path.join(case_result_dir, "summary.json"), summary)
    _write_text(os.path.join(case_result_dir, "summary.md"), _render_summary_markdown(summary))
    return summary


def rescore_test_runs(run_id: Optional[str] = None) -> dict:
    run_dirs = []
    if run_id:
        target = os.path.join(TEST_RUNS_DIR, run_id)
        if not os.path.isdir(target):
            raise FileNotFoundError(f"未找到 run_id: {run_id}")
        run_dirs.append(target)
    else:
        if not os.path.isdir(TEST_RUNS_DIR):
            raise FileNotFoundError("test_runs 目录不存在")
        run_dirs = [
            os.path.join(TEST_RUNS_DIR, name)
            for name in sorted(os.listdir(TEST_RUNS_DIR))
            if os.path.isdir(os.path.join(TEST_RUNS_DIR, name))
        ]

    rescored = []
    skipped = []
    for run_dir in run_dirs:
        cases_root = os.path.join(run_dir, "cases")
        if not os.path.isdir(cases_root):
            skipped.append({"run_id": os.path.basename(run_dir), "reason": "missing cases dir"})
            continue

        for case_name in sorted(os.listdir(cases_root)):
            case_result_dir = os.path.join(cases_root, case_name)
            if not os.path.isdir(case_result_dir):
                continue
            try:
                summary = _rescore_case_result_dir(case_result_dir)
                rescored.append(summary)
                print(
                    f"[RESCORE] {summary['run_id']} / {summary['case_id']} "
                    f"overall={summary['repaired']['score_summary'].get('overall_score', 0)} "
                    f"constraints={summary['repaired']['score_summary'].get('constraints_passed', 0)}"
                )
            except Exception as exc:
                skipped.append({
                    "run_id": os.path.basename(run_dir),
                    "case_id": case_name,
                    "reason": str(exc),
                })
                print(f"[SKIP] {os.path.basename(run_dir)} / {case_name}: {exc}")

    result = {
        "rescored_count": len(rescored),
        "skipped_count": len(skipped),
        "rescored": rescored,
        "skipped": skipped,
    }
    _write_json(os.path.join(TEST_RUNS_DIR, "rescore_summary.json"), result)
    return result


def run_case_test(case_ref: str,
                  agent_id: Optional[str] = None,
                  profile_name: Optional[str] = None,
                  run_id: Optional[str] = None) -> dict:
    scenario, case = _resolve_case(case_ref)
    agent = _pick_agent(agent_id)

    run_id = run_id or datetime.now().strftime("manual_%Y%m%d_%H%M%S")
    case_result_dir = _case_result_dir(run_id, case["id"])
    os.makedirs(case_result_dir, exist_ok=True)
    _copy_case_yaml(case, case_result_dir)

    print(f"[INFO] Run ID: {run_id}")
    print(f"[INFO] Case: {case['id']} | {case['title']}")
    print(f"[INFO] Result Dir: {case_result_dir}")
    print(f"[INFO] Agent: {agent.get('id') or agent.get('name') or ''} | {agent.get('model') or ''}")

    print("[STEP] 1/2 原始工程编译与约束评分")
    _, original_compile, original_score = _run_original(case, case_result_dir)

    print("[STEP] 2/2 Agent 修复、编译与约束评分")
    _, repaired_compile, repaired_score, _ = _run_repair(
        case,
        scenario,
        case_result_dir,
        agent,
        profile_name=profile_name,
    )

    summary = _build_summary(
        case,
        scenario,
        run_id,
        case_result_dir,
        original_compile,
        original_score,
        repaired_compile,
        repaired_score,
        agent,
    )
    _write_json(os.path.join(case_result_dir, "summary.json"), summary)
    _write_text(os.path.join(case_result_dir, "summary.md"), _render_summary_markdown(summary))

    before = summary["original"]["score_summary"]
    after = summary["repaired"]["score_summary"]
    print("[DONE] 测试完成")
    print(
        "[DONE] Score "
        f"overall {before.get('overall_score', 0)} -> {after.get('overall_score', 0)}, "
        f"constraints {before.get('constraints_passed', 0)} -> {after.get('constraints_passed', 0)}"
    )
    print(f"[DONE] Summary: {os.path.join(case_result_dir, 'summary.md')}")
    return summary


def build_arg_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="执行单条测试用例的原始工程 vs Agent 修复工程对比测试",
    )
    parser.add_argument(
        "case_ref",
        nargs="?",
        help=r"测试用例目录或 case_id，例如 agent_bench\test_cases\bug_fix\001 或 bug_fix_001",
    )
    parser.add_argument(
        "--agent-id",
        default=None,
        help="使用的 agent id，默认优先 codex_local，其次 agent_default",
    )
    parser.add_argument(
        "--profile",
        default=None,
        help="可选：指定场景 enhancement profile 名称",
    )
    parser.add_argument(
        "--run-id",
        default=None,
        help="可选：指定本次测试 run_id，默认按时间生成",
    )
    parser.add_argument(
        "--rescore-run",
        default=None,
        help="基于已有 test_runs/<run_id> 工作区重新按最新约束打分，不重新调用 Agent",
    )
    parser.add_argument(
        "--rescore-all",
        action="store_true",
        help="基于 test_runs 下已有工作区重新按最新约束批量打分，不重新调用 Agent",
    )
    return parser


def main(argv: Optional[list] = None) -> int:
    parser = build_arg_parser()
    args = parser.parse_args(argv)
    try:
        if args.rescore_all or args.rescore_run:
            result = rescore_test_runs(run_id=args.rescore_run)
            print(
                f"[DONE] Rescored={result['rescored_count']}, "
                f"Skipped={result['skipped_count']}, "
                f"Summary={os.path.join(TEST_RUNS_DIR, 'rescore_summary.json')}"
            )
            return 0

        if not args.case_ref:
            parser.error("缺少 case_ref，或者请使用 --rescore-run / --rescore-all")
        run_case_test(
            args.case_ref,
            agent_id=args.agent_id,
            profile_name=args.profile,
            run_id=args.run_id,
        )
        return 0
    except Exception as exc:
        print(f"[ERROR] {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
