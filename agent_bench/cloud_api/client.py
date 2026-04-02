# -*- coding: utf-8 -*-
"""云测 HTTP 客户端。"""

import json
import urllib.error
import urllib.request
from typing import Any, Dict


def _post_json(url: str, payload: Dict[str, Any], timeout: int = 20) -> Dict[str, Any]:
    body = json.dumps(payload, ensure_ascii=False).encode("utf-8")
    request = urllib.request.Request(
        url=url,
        data=body,
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    try:
        with urllib.request.urlopen(request, timeout=timeout) as response:
            response_body = response.read().decode("utf-8", errors="replace")
            return {
                "ok": True,
                "status_code": response.getcode(),
                "body": response_body,
            }
    except urllib.error.HTTPError as exc:
        error_body = exc.read().decode("utf-8", errors="replace")
        return {
            "ok": False,
            "status_code": exc.code,
            "body": error_body,
        }
    except Exception as exc:
        return {
            "ok": False,
            "status_code": None,
            "body": str(exc),
        }


def build_status_report_url(cloud_base_url: str, execution_id: int) -> str:
    return f"{cloud_base_url.rstrip('/')}/api/test-executions/{execution_id}/report"


def build_execution_result_url(cloud_base_url: str) -> str:
    return f"{cloud_base_url.rstrip('/')}/api/execution-results"


def report_status(cloud_base_url: str, execution_id: int, payload: Dict[str, Any]) -> Dict[str, Any]:
    return _post_json(build_status_report_url(cloud_base_url, execution_id), payload)


def upload_execution_result(cloud_base_url: str, payload: Dict[str, Any]) -> Dict[str, Any]:
    return _post_json(build_execution_result_url(cloud_base_url), payload)

