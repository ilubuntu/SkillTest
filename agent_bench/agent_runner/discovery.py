# -*- coding: utf-8 -*-
"""服务发现与自动启动。"""

import json
import os
import socket
import subprocess
import tempfile
import time
import urllib.request
from typing import Optional

from agent_bench.agent_runner.opencode_env import resolve_opencode_command

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SERVICE_LOG_PATH = os.path.join(tempfile.gettempdir(), "agent_bench_service.log")


def _runtime_root_dir() -> str:
    return os.path.dirname(BASE_DIR)


def _default_opencode_xdg_config_home() -> str:
    return os.path.join(_runtime_root_dir(), ".opencode_runtime", "xdg_config")


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
    child_env = os.environ.copy()
    xdg_config_home = _default_opencode_xdg_config_home()
    os.makedirs(xdg_config_home, exist_ok=True)
    # 统一由 Python 启动链负责隔离 OpenCode 全局配置，避免依赖外层脚本入口。
    child_env["XDG_CONFIG_HOME"] = xdg_config_home
    try:
        with open(SERVICE_LOG_PATH, "a", encoding="utf-8") as log_file:
            log_file.write(
                f"\n[{time.strftime('%Y-%m-%d %H:%M:%S')}] starting opencode server "
                f"cmd={' '.join(command)}"
                f" XDG_CONFIG_HOME={xdg_config_home}"
                "\n"
            )

        log_stream = open(SERVICE_LOG_PATH, "a", encoding="utf-8")
        proc = subprocess.Popen(
            command,
            stdout=log_stream,
            stderr=log_stream,
            stdin=subprocess.DEVNULL,
            env=child_env,
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
            with open(SERVICE_LOG_PATH, "a", encoding="utf-8") as log_file:
                log_file.write(f"[{time.strftime('%Y-%m-%d %H:%M:%S')}] start opencode server failed: {e}\n")
        except Exception:
            pass

    return target_base
