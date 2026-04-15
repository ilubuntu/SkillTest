#!/usr/bin/env python
# -*- coding: utf-8 -*-

from __future__ import annotations

import argparse
import json
import os
import time
import urllib.error
import urllib.request


DEFAULT_SCENARIOS = ["requirement", "bug_fix", "performance"]


def _parse_report_execution_ids(raw: str) -> dict[str, int]:
    mapping: dict[str, int] = {}
    text = str(raw or "").strip()
    if not text:
        return mapping
    for part in text.split(","):
        item = part.strip()
        if not item or "=" not in item:
            continue
        scenario, execution_id = item.split("=", 1)
        scenario = scenario.strip()
        execution_id = execution_id.strip()
        if not scenario or not execution_id:
            continue
        try:
            mapping[scenario] = int(execution_id)
        except ValueError:
            continue
    return mapping


def _post_json(url: str, payload: dict) -> dict:
    data = json.dumps(payload, ensure_ascii=False).encode("utf-8")
    request = urllib.request.Request(
        url,
        data=data,
        headers={"Content-Type": "application/json; charset=utf-8"},
        method="POST",
    )
    with urllib.request.urlopen(request, timeout=30) as response:
        return json.loads(response.read().decode("utf-8"))


def _get_json(url: str) -> dict:
    with urllib.request.urlopen(url, timeout=30) as response:
        return json.loads(response.read().decode("utf-8"))


def _wait_for_execution(base_url: str, execution_id: int, label: str) -> dict:
    last_stage = ""
    last_status = ""
    last_case_id = ""
    while True:
        state = _get_json(f"{base_url}/api/local/status?execution_id={execution_id}")
        stage = str(state.get("local_stage") or "")
        status = str(state.get("local_status") or "")
        case_id = str(state.get("case_id") or "")
        if stage != last_stage or status != last_status or case_id != last_case_id:
            summary = f"[INFO] {label} executionId={execution_id} status={status} stage={stage}"
            if case_id:
                summary += f" caseId={case_id}"
            if state.get("generated_case_dir"):
                summary += f" caseDir={state['generated_case_dir']}"
            print(summary, flush=True)
            last_stage = stage
            last_status = status
            last_case_id = case_id
        if status in {"completed", "failed"}:
            return state
        time.sleep(5)


def _generate_case(base_url: str, scenario: str, source_project_dir: str, agent_id: str) -> dict:
    payload = {
        "input": "",
        "originalProjectDir": source_project_dir,
        "agentId": agent_id,
        "scenario": scenario,
    }
    response = _post_json(f"{base_url}/api/local/generate-case", payload)
    execution_id = int(response["executionId"])
    print(f"[INFO] Submitted generate for {scenario}: executionId={execution_id}", flush=True)
    return _wait_for_execution(base_url, execution_id, f"generate:{scenario}")


def _run_case(
    base_url: str,
    scenario: str,
    case_dir: str,
    agent_id: str,
    report_execution_id: int = 0,
    cloud_base_url: str = "",
    token: str = "",
) -> dict:
    payload = {
        "caseDir": case_dir,
        "agentId": agent_id,
    }
    if report_execution_id > 0:
        payload["reportExecutionId"] = report_execution_id
        if cloud_base_url:
            payload["cloudBaseUrl"] = cloud_base_url
        if token:
            payload["token"] = token
    response = _post_json(f"{base_url}/api/local/run-case", payload)
    execution_id = int(response["executionId"])
    print(f"[INFO] Submitted run for {scenario}: executionId={execution_id}", flush=True)
    return _wait_for_execution(base_url, execution_id, f"run:{scenario}")


def main() -> int:
    parser = argparse.ArgumentParser(description="Generate all catalog cases first, then run them sequentially")
    parser.add_argument("--base-url", default="http://127.0.0.1:8000")
    parser.add_argument("--source-project-dir", default="empty_hos_project")
    parser.add_argument("--generation-agent-id", default="case_generation_agent")
    parser.add_argument("--run-agent-id", default="agent_default")
    parser.add_argument("--scenarios", nargs="*", default=DEFAULT_SCENARIOS)
    parser.add_argument("--cloud-base-url", default=os.getenv("LOCAL_CLOUD_BASE_URL", ""))
    parser.add_argument("--token", default=os.getenv("LOCAL_CLOUD_TOKEN", ""))
    parser.add_argument("--report-execution-ids", default=os.getenv("LOCAL_REPORT_EXECUTION_IDS", ""))
    args = parser.parse_args()

    base_url = args.base_url.rstrip("/")
    report_execution_ids = _parse_report_execution_ids(args.report_execution_ids)
    generated_cases: list[dict] = []
    failures: list[dict] = []

    print("[INFO] Phase 1: generate all cases", flush=True)
    for scenario in args.scenarios:
        try:
            state = _generate_case(base_url, scenario, args.source_project_dir, args.generation_agent_id)
        except urllib.error.HTTPError as exc:
            body = exc.read().decode("utf-8", errors="replace")
            print(f"[ERROR] Failed to submit generate for {scenario}: HTTP {exc.code}", flush=True)
            if body:
                print(body, flush=True)
            failures.append({"phase": "generate", "scenario": scenario, "error": f"HTTP {exc.code}", "body": body})
            continue
        except Exception as exc:
            print(f"[ERROR] Failed while generating {scenario}: {exc}", flush=True)
            failures.append({"phase": "generate", "scenario": scenario, "error": str(exc)})
            continue

        case_dir = str(state.get("case_dir") or "")
        if state.get("local_status") != "completed" or not case_dir:
            failures.append({
                "phase": "generate",
                "scenario": scenario,
                "status": state.get("local_status") or "",
                "error": state.get("error_message") or "case generation failed",
            })
            print(f"[ERROR] Generate {scenario} failed: {state.get('error_message') or 'unknown'}", flush=True)
            continue

        generated_cases.append({
            "scenario": scenario,
            "case_dir": case_dir,
            "case_id": state.get("case_id") or "",
        })
        print(f"[INFO] Generated {scenario}: caseId={state.get('case_id') or ''} caseDir={case_dir}", flush=True)

    if failures:
        print("[ERROR] Generation phase has failures, skip execution phase.", flush=True)
        for item in failures:
            print(f"- {item}", flush=True)
        return 1

    print()
    print("[INFO] Phase 2: run generated cases sequentially", flush=True)
    run_summaries: list[dict] = []
    for item in generated_cases:
        scenario = item["scenario"]
        report_execution_id = int(report_execution_ids.get(scenario) or 0)
        try:
            state = _run_case(
                base_url,
                scenario,
                item["case_dir"],
                args.run_agent_id,
                report_execution_id=report_execution_id,
                cloud_base_url=args.cloud_base_url,
                token=args.token,
            )
        except urllib.error.HTTPError as exc:
            body = exc.read().decode("utf-8", errors="replace")
            print(f"[ERROR] Failed to submit run for {scenario}: HTTP {exc.code}", flush=True)
            if body:
                print(body, flush=True)
            failures.append({"phase": "run", "scenario": scenario, "error": f"HTTP {exc.code}", "body": body})
            continue
        except Exception as exc:
            print(f"[ERROR] Failed while running {scenario}: {exc}", flush=True)
            failures.append({"phase": "run", "scenario": scenario, "error": str(exc)})
            continue

        summary = {
            "scenario": scenario,
            "status": state.get("local_status") or "",
            "stage": state.get("local_stage") or "",
            "case_id": state.get("case_id") or item["case_id"],
            "generated_case_dir": state.get("generated_case_dir") or item["case_dir"],
            "run_dir": state.get("run_dir") or "",
            "error_message": state.get("error_message") or "",
        }
        run_summaries.append(summary)
        if summary["status"] == "completed":
            print(f"[INFO] Scenario {scenario} completed.", flush=True)
        else:
            print(f"[ERROR] Scenario {scenario} failed: {summary['error_message']}", flush=True)
            failures.append({"phase": "run", **summary})

    print()
    print("[INFO] Batch summary:", flush=True)
    for item in run_summaries:
        line = f"- {item['scenario']}: {item['status']} (caseId={item['case_id']}, caseDir={item['generated_case_dir']})"
        if item["error_message"]:
            line += f" error={item['error_message']}"
        print(line, flush=True)

    return 1 if failures else 0


if __name__ == "__main__":
    raise SystemExit(main())
