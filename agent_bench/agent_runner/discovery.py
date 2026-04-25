# -*- coding: utf-8 -*-
"""服务发现与自动启动。"""

import json
import logging
import os
import platform
import shutil
import socket
import subprocess
import tempfile
import time
import urllib.parse
import urllib.request
from typing import Optional

from agent_bench.agent_runner.opencode_env import resolve_opencode_command

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SERVICE_LOG_PATH = os.path.join(tempfile.gettempdir(), "agent_bench_service.log")
logger = logging.getLogger(__name__)
DEFAULT_OPENCODE_SERVER_URL = "http://127.0.0.1:4096"


def _runtime_root_dir() -> str:
    return os.path.dirname(BASE_DIR)


def _default_opencode_xdg_config_home() -> str:
    return os.path.join(_runtime_root_dir(), ".opencode_runtime", "xdg_config")


def _isolated_opencode_config_path(xdg_config_home: str) -> str:
    return os.path.join(xdg_config_home, "opencode", "opencode.json")


def _normalize_config_path(path: str) -> str:
    return os.path.normpath(os.path.expandvars(os.path.expanduser(str(path or "").strip())))


def _platform_config_key() -> str:
    system = platform.system().lower()
    if system == "darwin":
        return "macos"
    if system == "windows":
        return "windows"
    return "linux"


def _configured_opencode_config_candidate() -> tuple[Optional[str], str]:
    try:
        from agent_bench.pipeline.loader import load_config

        config = load_config() or {}
    except Exception as exc:
        logger.warning("读取 config.yaml 失败，跳过 opencode_config_path 配置: %s", exc)
        return None, ""

    opencode_config = config.get("opencode") if isinstance(config, dict) else {}
    if not isinstance(opencode_config, dict):
        return None, ""

    value = opencode_config.get("opencode_config_path", opencode_config.get("opencode-config-path"))
    if value is None:
        return None, ""

    if isinstance(value, dict):
        platform_key = _platform_config_key()
        raw_path = value.get(platform_key) or value.get("default")
        source = f"config.opencode.opencode_config_path.{platform_key}"
    else:
        raw_path = value
        source = "config.opencode.opencode_config_path"

    if raw_path is None or str(raw_path).strip() == "":
        return None, source
    return _normalize_config_path(str(raw_path)), source


def configured_opencode_server_url() -> str:
    try:
        from agent_bench.pipeline.loader import load_config

        config = load_config() or {}
    except Exception as exc:
        logger.warning("读取 config.yaml 失败，回退默认 OpenCode Server 地址: %s", exc)
        return DEFAULT_OPENCODE_SERVER_URL

    opencode_config = config.get("opencode") if isinstance(config, dict) else {}
    if not isinstance(opencode_config, dict):
        return DEFAULT_OPENCODE_SERVER_URL

    value = opencode_config.get("opencode_server_url")
    if value is None or str(value).strip() == "":
        return DEFAULT_OPENCODE_SERVER_URL
    return str(value).strip().rstrip("/")


def _user_opencode_config_candidates() -> list[tuple[str, str]]:
    home_dir = os.path.expanduser("~")
    appdata_dir = os.environ.get("APPDATA") or os.path.join(home_dir, "AppData", "Roaming")
    return [
        (os.path.join(home_dir, ".opencode", "opencode.json"), "user.home/.opencode"),
        (os.path.join(home_dir, ".config", "opencode", "opencode.json"), "user.home/.config"),
        (os.path.join(appdata_dir, "opencode", "opencode.json"), "windows.APPDATA"),
    ]


def _bootstrap_isolated_opencode_config(xdg_config_home: str) -> Optional[str]:
    """初始化隔离 OpenCode 配置，避免自动启动的 server 缺少 provider。"""
    target_path = _isolated_opencode_config_path(xdg_config_home)
    os.makedirs(os.path.dirname(target_path), exist_ok=True)

    configured_path, configured_source = _configured_opencode_config_candidate()
    if configured_path:
        if os.path.isfile(configured_path):
            shutil.copy2(configured_path, target_path)
            logger.info("OpenCode 配置来源: %s -> %s", configured_path, target_path)
            return target_path
        logger.warning("配置项指定的 OpenCode 配置不存在，继续查找用户目录: source=%s path=%s", configured_source, configured_path)

    checked_paths = []
    for source_path, source_name in _user_opencode_config_candidates():
        source_path = _normalize_config_path(source_path)
        checked_paths.append(source_path)
        if not os.path.isfile(source_path):
            continue
        shutil.copy2(source_path, target_path)
        logger.info("OpenCode 配置来源: %s (%s) -> %s", source_path, source_name, target_path)
        return target_path

    configured_note = f"{configured_path}; " if configured_path else ""
    raise RuntimeError(
        "未找到 OpenCode 配置文件，无法启动 OpenCode server。"
        f"已检查: {configured_note}{'; '.join(checked_paths)}"
    )


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
    target_base = configured_opencode_server_url()
    parsed = urllib.parse.urlparse(target_base)
    host = (parsed.hostname or "").strip().lower()
    port = parsed.port

    if host not in {"127.0.0.1", "localhost", "::1"}:
        return None
    if not port:
        port = 443 if parsed.scheme == "https" else 80

    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.settimeout(1)
    try:
        result = sock.connect_ex((host, int(port)))
        sock.close()
        if result == 0 and check_api_available(target_base):
            return str(port)
    except Exception:
        pass

    return None


def ensure_opencode_server(timeout: int = 30) -> str:
    """确保 OpenCode API 服务可用，必要时自动启动。"""
    target_base = configured_opencode_server_url()
    if check_api_available(target_base):
        return target_base

    parsed = urllib.parse.urlparse(target_base)
    host = (parsed.hostname or "").strip().lower()
    port = parsed.port or (443 if parsed.scheme == "https" else 80)
    if host not in {"127.0.0.1", "localhost", "::1"}:
        return target_base

    command = resolve_opencode_command() + ["serve", "--port", str(port)]
    child_env = os.environ.copy()
    xdg_config_home = _default_opencode_xdg_config_home()
    os.makedirs(xdg_config_home, exist_ok=True)
    isolated_config_path = _bootstrap_isolated_opencode_config(xdg_config_home)
    # 统一由 Python 启动链负责隔离 OpenCode 全局配置，避免依赖外层脚本入口。
    child_env["XDG_CONFIG_HOME"] = xdg_config_home
    try:
        logger.info("自动启动 OpenCode Server: cmd=%s XDG_CONFIG_HOME=%s", " ".join(command), xdg_config_home)
        if isolated_config_path:
            logger.info("已准备隔离 OpenCode 配置: %s", isolated_config_path)
        else:
            logger.warning("未找到可复制的用户 OpenCode 配置，隔离目录缺少 opencode.json")
        with open(SERVICE_LOG_PATH, "a", encoding="utf-8") as log_file:
            log_file.write(
                f"\n[{time.strftime('%Y-%m-%d %H:%M:%S')}] starting opencode server "
                f"cmd={' '.join(command)}"
                f" XDG_CONFIG_HOME={xdg_config_home}"
                f" isolated_config={isolated_config_path or ''}"
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
