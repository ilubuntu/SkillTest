# -*- coding: utf-8 -*-
"""云测 HTTP 客户端。

封装与云测平台的 HTTP 通信，包括进度上报、最终结果上报和 Agent 日志上传。
所有请求通过 urllib 发送，不依赖第三方 HTTP 库。
"""

import json
import mimetypes
import os
import uuid
import urllib.error
import urllib.request
from typing import Any, Dict, Optional


def _post_json(url: str, payload: Dict[str, Any], timeout: int = 20, token: Optional[str] = None) -> Dict[str, Any]:
    """发送 JSON POST 请求，统一返回 {ok, status_code, body} 结构。"""
    body = json.dumps(payload, ensure_ascii=False).encode("utf-8")
    headers = {"Content-Type": "application/json"}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    request = urllib.request.Request(
        url=url,
        data=body,
        headers=headers,
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


def _post_multipart_file(url: str,
                         field_name: str,
                         file_path: str,
                         timeout: int = 60,
                         token: Optional[str] = None) -> Dict[str, Any]:
    """发送 multipart/form-data 文件上传请求，统一返回 {ok, status_code, body} 结构。"""
    boundary = f"----agent-bench-{uuid.uuid4().hex}"
    filename = os.path.basename(file_path)
    content_type = mimetypes.guess_type(filename)[0] or "application/octet-stream"

    with open(file_path, "rb") as f:
        file_content = f.read()

    body_parts = [
        f"--{boundary}\r\n".encode("utf-8"),
        (
            f'Content-Disposition: form-data; name="{field_name}"; filename="{filename}"\r\n'
            f"Content-Type: {content_type}\r\n\r\n"
        ).encode("utf-8"),
        file_content,
        b"\r\n",
        f"--{boundary}--\r\n".encode("utf-8"),
    ]
    body = b"".join(body_parts)
    headers = {
        "Content-Type": f"multipart/form-data; boundary={boundary}",
        "Content-Length": str(len(body)),
    }
    if token:
        headers["Authorization"] = f"Bearer {token}"

    request = urllib.request.Request(
        url=url,
        data=body,
        headers=headers,
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
    """构造进度上报 URL：POST /api/test-executions/{id}/report"""
    return f"{cloud_base_url.rstrip('/')}/api/test-executions/{execution_id}/report"


def build_execution_result_url(cloud_base_url: str) -> str:
    """构造最终结果上报 URL：POST /api/execution-results"""
    return f"{cloud_base_url.rstrip('/')}/api/execution-results"


def build_agent_log_url(cloud_base_url: str, execution_id: int) -> str:
    """构造 Agent/LLM 交互日志上传 URL：POST /api/test-executions/{id}/agent-log"""
    return f"{cloud_base_url.rstrip('/')}/api/test-executions/{execution_id}/agent-log"


def report_status(cloud_base_url: str, execution_id: int, payload: Dict[str, Any], token: Optional[str] = None) -> Dict[str, Any]:
    """上报任务进度。"""
    return _post_json(build_status_report_url(cloud_base_url, execution_id), payload, token=token)


def upload_execution_result(cloud_base_url: str, payload: Dict[str, Any], token: Optional[str] = None) -> Dict[str, Any]:
    """上报最终执行结果。"""
    return _post_json(build_execution_result_url(cloud_base_url), payload, token=token)


def upload_agent_log(cloud_base_url: str, execution_id: int, file_path: str, token: Optional[str] = None) -> Dict[str, Any]:
    """上传 Agent/LLM 交互日志文件。"""
    return _post_multipart_file(
        build_agent_log_url(cloud_base_url, execution_id),
        field_name="file",
        file_path=file_path,
        token=token,
    )
