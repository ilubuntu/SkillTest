# -*- coding: utf-8 -*-
"""OpenCode CLI 路径与配置目录解析。"""

from __future__ import annotations

import os
import platform
import shutil
import subprocess
from typing import Iterable, Optional


def _iter_existing_paths(paths: Iterable[str]) -> Iterable[str]:
    seen = set()
    for raw_path in paths:
        normalized = str(raw_path or "").strip()
        if not normalized:
            continue
        path = os.path.normpath(normalized)
        if path in seen:
            continue
        seen.add(path)
        if os.path.exists(path):
            yield path


def _common_opencode_candidates() -> list[str]:
    home_dir = os.path.expanduser("~")
    appdata_dir = os.environ.get("APPDATA") or os.path.join(home_dir, "AppData", "Roaming")
    local_bin_dir = os.path.join(home_dir, ".local", "bin")
    candidates = [
        os.environ.get("AGENT_BENCH_OPENCODE_PATH", ""),
        os.environ.get("OPENCODE_PATH", ""),
        os.path.join(appdata_dir, "npm", "opencode.cmd"),
        os.path.join(appdata_dir, "npm", "opencode.exe"),
        os.path.join(appdata_dir, "npm", "opencode.bat"),
        os.path.join(appdata_dir, "npm", "opencode.ps1"),
        os.path.join(local_bin_dir, "opencode"),
        os.path.join(local_bin_dir, "opencode.cmd"),
    ]
    return [path for path in _iter_existing_paths(candidates)]


def _which_candidates() -> list[str]:
    names = ["opencode"]
    if platform.system() == "Windows":
        names = ["opencode.cmd", "opencode.exe", "opencode.bat", "opencode.ps1", "opencode"]
    resolved = []
    for name in names:
        candidate = shutil.which(name)
        if candidate:
            resolved.append(candidate)
    return [path for path in _iter_existing_paths(resolved)]


def find_opencode_executable() -> Optional[str]:
    for candidate in _common_opencode_candidates() + _which_candidates():
        return candidate
    return None


def resolve_opencode_command() -> list[str]:
    executable = find_opencode_executable()
    if not executable:
        return ["opencode"]
    if executable.lower().endswith(".ps1"):
        return ["powershell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", executable]
    return [executable]


def run_opencode_command(*args: str, timeout: int = 10) -> tuple[bool, str, str]:
    try:
        command = resolve_opencode_command() + list(args)
        result = subprocess.run(
            command,
            capture_output=True,
            text=True,
            encoding="utf-8",
            errors="replace",
            timeout=timeout,
            check=False,
        )
        if result.returncode != 0:
            return False, result.stdout or "", (result.stderr or result.stdout or "").strip()
        return True, result.stdout or "", ""
    except Exception as exc:
        return False, "", str(exc)


def default_opencode_config_root() -> str:
    xdg_config = os.environ.get("XDG_CONFIG_HOME")
    if xdg_config:
        return os.path.normpath(os.path.join(xdg_config, "opencode"))

    home_config = os.path.join(os.path.expanduser("~"), ".config", "opencode")
    if platform.system() == "Windows":
        appdata = os.environ.get("APPDATA") or os.path.expanduser("~\\AppData\\Roaming")
        appdata_config = os.path.join(appdata, "opencode")
        if os.path.isdir(home_config):
            return os.path.normpath(home_config)
        if os.path.isdir(appdata_config):
            return os.path.normpath(appdata_config)
        return os.path.normpath(home_config)

    return os.path.normpath(home_config)


def resolve_opencode_config_root() -> str:
    ok, stdout, _ = run_opencode_command("debug", "paths")
    if ok:
        for raw_line in stdout.splitlines():
            line = raw_line.strip()
            if not line:
                continue
            parts = line.split(None, 1)
            if len(parts) == 2 and parts[0].strip().lower() == "config" and parts[1].strip():
                return os.path.normpath(parts[1].strip())
    return default_opencode_config_root()
