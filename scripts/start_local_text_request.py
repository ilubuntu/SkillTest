import json
import os
import sys
import urllib.error
import urllib.request


def main() -> int:
    if len(sys.argv) < 2:
        print("[ERROR] Missing request URL", file=sys.stderr)
        return 1

    url = sys.argv[1]
    payload = {
        "input": os.getenv("LOCAL_TEXT_INPUT", ""),
        "expectedOutput": os.getenv("LOCAL_EXPECTED_OUTPUT", ""),
        "originalProjectDir": os.getenv("LOCAL_PROJECT_DIR", ""),
        "agentId": os.getenv("LOCAL_AGENT_ID", ""),
        "title": os.getenv("LOCAL_TASK_TITLE", ""),
        "scenario": os.getenv("LOCAL_TASK_SCENARIO", ""),
        "reportExecutionId": os.getenv("LOCAL_REPORT_EXECUTION_ID", ""),
        "cloudBaseUrl": os.getenv("LOCAL_CLOUD_BASE_URL", ""),
        "token": os.getenv("LOCAL_CLOUD_TOKEN", ""),
    }
    payload = {
        key: value
        for key, value in payload.items()
        if key == "input" or str(value).strip()
    }

    data = json.dumps(payload, ensure_ascii=False).encode("utf-8")
    request = urllib.request.Request(
        url,
        data=data,
        headers={"Content-Type": "application/json; charset=utf-8"},
        method="POST",
    )

    try:
        with urllib.request.urlopen(request, timeout=30) as response:
            body = response.read().decode("utf-8")
    except urllib.error.HTTPError as exc:
        body = exc.read().decode("utf-8", errors="replace")
        print(f"[ERROR] Request failed: HTTP {exc.code}", file=sys.stderr)
        if body:
            print(body, file=sys.stderr)
        return 1
    except Exception as exc:
        print(f"[ERROR] Request failed: {exc}", file=sys.stderr)
        return 1

    try:
        payload = json.loads(body)
    except Exception:
        print("[ERROR] Invalid JSON response", file=sys.stderr)
        if body:
            print(body, file=sys.stderr)
        return 1

    execution_id = payload.get("executionId", "")
    status_url = payload.get("statusUrl", "")
    print(f"[INFO] Local execution accepted: {execution_id}")
    if status_url:
        print(f"[INFO] Status URL: {status_url}")
    if execution_id:
        print(
            f"[INFO] Generate events: "
            f"{url.rsplit('/api/local/start-text', 1)[0]}/api/local/executions/{execution_id}/generate/events"
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
