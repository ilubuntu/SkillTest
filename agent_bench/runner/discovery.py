# -*- coding: utf-8 -*-
"""服务发现与自动启动。"""

import json
import os
import socket
import subprocess
import sys
import tempfile
import time
import urllib.error
import urllib.request
from typing import Optional

from agent_bench.opencode_cli import resolve_opencode_command

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
REPO_DIR = os.path.dirname(BASE_DIR)
CODEX_SERVICE_LOG_PATH = os.path.join(tempfile.gettempdir(), "agent_bench_codex_service.log")


def codex_service_log_path() -> str:
    return CODEX_SERVICE_LOG_PATH


def read_codex_service_log_tail(limit: int = 4000) -> str:
    try:
        with open(CODEX_SERVICE_LOG_PATH, "r", encoding="utf-8", errors="replace") as f:
            content = f.read()
        return content[-limit:]
    except Exception:
        return ""


def check_codex_service_available(api_base: str) -> bool:
    """检查 Codex HTTP 服务是否可用。"""
    try:
        req = urllib.request.Request(f"{api_base}/health", method="GET")
        with urllib.request.urlopen(req, timeout=3) as response:
            result = json.loads(response.read().decode("utf-8"))
            return result.get("healthy", False)
    except Exception:
        return False


def find_codex_service_base() -> Optional[str]:
    """查找当前运行中的 Codex HTTP 服务。"""
    for port in ("8001", "8002", "5178"):
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(1)
        try:
            result = sock.connect_ex(("localhost", int(port)))
            sock.close()
            if result == 0:
                api_base = f"http://localhost:{port}"
                if check_codex_service_available(api_base):
                    return api_base
        except Exception:
            pass
    return None


def ensure_codex_service(timeout: int = 30, api_base: str = "http://127.0.0.1:8001") -> str:
    """确保独立 Codex HTTP 服务可用，必要时自动启动。"""
    target_base = (api_base or "http://127.0.0.1:8001").rstrip("/")
    if check_codex_service_available(target_base):
        return target_base

    discovered = find_codex_service_base()
    if discovered:
        return discovered

    port = target_base.rsplit(":", 1)[-1]
    cmd = [sys.executable, "-m", "agent_bench.codex_service.main", "--host", "127.0.0.1", "--port", str(port)]
    creationflags = 0
    for flag_name in ("DETACHED_PROCESS", "CREATE_NEW_PROCESS_GROUP", "CREATE_NO_WINDOW"):
        creationflags |= getattr(subprocess, flag_name, 0)

    child_env = os.environ.copy()
    existing_pythonpath = child_env.get("PYTHONPATH", "")
    pythonpath_parts = [REPO_DIR]
    if existing_pythonpath:
        pythonpath_parts.append(existing_pythonpath)
    child_env["PYTHONPATH"] = os.pathsep.join(pythonpath_parts)

    try:
        with open(CODEX_SERVICE_LOG_PATH, "a", encoding="utf-8") as log_file:
            log_file.write(
                f"\n[{time.strftime('%Y-%m-%d %H:%M:%S')}] starting codex service "
                f"cmd={' '.join(cmd)} cwd={REPO_DIR}\n"
            )

        log_stream = open(CODEX_SERVICE_LOG_PATH, "a", encoding="utf-8")
        proc = subprocess.Popen(
            cmd,
            stdout=log_stream,
            stderr=log_stream,
            stdin=subprocess.DEVNULL,
            cwd=REPO_DIR,
            env=child_env,
            creationflags=creationflags,
            close_fds=True,
        )
        log_stream.close()

        for _ in range(timeout):
            time.sleep(1)
            if check_codex_service_available(target_base):
                return target_base
            if proc.poll() is not None:
                break
    except Exception as e:
        try:
            with open(CODEX_SERVICE_LOG_PATH, "a", encoding="utf-8") as log_file:
                log_file.write(f"[{time.strftime('%Y-%m-%d %H:%M:%S')}] start codex service failed: {e}\n")
        except Exception:
            pass
    return target_base


def check_api_available(api_base: str) -> bool:
    """检查 OpenCode API 是否可用。"""
    try:
        req = urllib.request.Request(f"{api_base}/global/health", method="GET")
        with urllib.request.urlopen(req, timeout=3) as response:
            result = json.loads(response.read().decode("utf-8"))
            return result.get("healthy", False)
    except Exception:
        return False


def find_opencode_port() -> Optional[str]:
    """查找当前运行的 OpenCode server 端口。"""
    common_ports = ["4096", "36903", "3000", "18792", "5000"]

    for port in common_ports:
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(1)
        try:
            result = sock.connect_ex(("localhost", int(port)))
            sock.close()
            if result == 0:
                if check_api_available(f"http://localhost:{port}"):
                    return port
        except Exception:
            pass

    return None


def ensure_opencode_server(timeout: int = 30) -> str:
    """确保 OpenCode API 服务可用，必要时自动启动。"""
    port = find_opencode_port()
    if port:
        return f"http://localhost:{port}"

    target_base = "http://localhost:4096"
    command = resolve_opencode_command() + ["serve", "--port", "4096"]
    try:
        with open(CODEX_SERVICE_LOG_PATH, "a", encoding="utf-8") as log_file:
            log_file.write(
                f"\n[{time.strftime('%Y-%m-%d %H:%M:%S')}] starting opencode server "
                f"cmd={' '.join(command)}\n"
            )

        log_stream = open(CODEX_SERVICE_LOG_PATH, "a", encoding="utf-8")
        proc = subprocess.Popen(
            command,
            stdout=log_stream,
            stderr=log_stream,
            stdin=subprocess.DEVNULL,
            start_new_session=True,
            close_fds=True,
        )
        log_stream.close()

        for _ in range(timeout):
            time.sleep(1)
            if check_api_available(target_base):
                return target_base
            if proc.poll() is not None:
                break
    except FileNotFoundError:
        return target_base
    except Exception as e:
        try:
            with open(CODEX_SERVICE_LOG_PATH, "a", encoding="utf-8") as log_file:
                log_file.write(f"[{time.strftime('%Y-%m-%d %H:%M:%S')}] start opencode server failed: {e}\n")
        except Exception:
            pass

    return target_base
