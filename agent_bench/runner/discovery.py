# -*- coding: utf-8 -*-
"""OpenCode 服务发现与启动

职责：
- 检查 OpenCode API 是否可用
- 查找当前运行的 OpenCode server 端口
- 必要时自动启动 OpenCode server
"""

import json
import os
import socket
import subprocess
import sys
import time
import urllib.request
import urllib.error
from typing import Optional


def check_api_available(api_base: str) -> bool:
    """检查 OpenCode API 是否可用"""
    try:
        req = urllib.request.Request(f"{api_base}/global/health", method="GET")
        with urllib.request.urlopen(req, timeout=3) as response:
            result = json.loads(response.read().decode("utf-8"))
            return result.get("healthy", False)
    except Exception:
        return False


def find_opencode_port() -> Optional[str]:
    """查找当前运行的 OpenCode server 端口"""
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
    """确保 OpenCode API 服务可用，必要时自动启动

    Returns:
        可用的 API base URL
    """
    import platform

    print("[INFO] Searching for OpenCode server...")
    port = find_opencode_port()
    if port:
        api_base = f"http://localhost:{port}"
        print(f"[INFO] Found OpenCode API at {api_base}")
        return api_base

    print("[INFO] No valid OpenCode server found, "
          "starting new server on port 4096...")

    system = platform.system()
    try:
        if system == "Windows":
            cmd = 'start /b cmd /c "opencode serve --port 4096"'
            os.system(cmd)
        else:
            subprocess.Popen(
                ["nohup", "opencode", "serve", "--port", "4096", "&"],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                stdin=subprocess.DEVNULL
            )

        print(f"[INFO] Server starting, waiting {timeout}s...")
        for i in range(timeout):
            time.sleep(1)
            if check_api_available("http://localhost:4096"):
                print("[INFO] OpenCode server started at http://localhost:4096")
                return "http://localhost:4096"
            print(f"[INFO] Waiting... ({i+1}/{timeout})")

        print("[WARN] Server may not have started, continuing anyway...")

    except FileNotFoundError:
        print("[ERROR] opencode command not found. Please install opencode first.")
        print("[ERROR] Download from: https://opencode.ai")
        sys.exit(1)
    except Exception as e:
        print(f"[WARN] Failed to start opencode server: {e}")

    return "http://localhost:8080"
