# -*- coding: utf-8 -*-
"""ArkTS 编译验证模块

每次编译将测试用例自带的 original_project 模板复制到独立沙箱目录，支持并行编译。
"""

import os
import json
import argparse
import platform
import re
import shutil
import subprocess
import tempfile
import threading
from contextlib import contextmanager
from typing import Dict, Tuple, Any

from agent_bench.common.default_constants import DEFAULT_TIMEOUT_SECONDS

INDEX_ETS_REL = os.path.join("entry", "src", "main", "ets", "pages", "Index.ets")
META_DIR_NAME = ".agent_bench"
IGNORED_COMPARE_DIRS = {"build", ".hvigor", "node_modules", "oh_modules", ".opencode", META_DIR_NAME}
WINDOWS_RESERVED_NAMES = {
    "con", "prn", "aux", "nul",
    *(f"com{i}" for i in range(1, 10)),
    *(f"lpt{i}" for i in range(1, 10)),
}
TOOLCHAIN_ENV_NODE = "AGENT_BENCH_NODE_BIN"
TOOLCHAIN_ENV_HVIGOR = "AGENT_BENCH_HVIGOR_JS"
TOOLCHAIN_ENV_JAVA = "AGENT_BENCH_JAVA_HOME"
TOOLCHAIN_ENV_SDK = "AGENT_BENCH_HARMONYOS_SDK"
TOOLCHAIN_ENV_SDK_LEGACY = "AGENT_BENCH_SDK_ROOT"
DEFAULT_HVIGOR_TASKS = ["assembleHap"]
_HVIGOR_SEMAPHORE_LOCK = threading.Lock()
_HVIGOR_SEMAPHORE: threading.BoundedSemaphore | None = None
_HVIGOR_SEMAPHORE_LIMIT: int | None = None


def _external_stage_cache_dir(project_root: str) -> str:
    parent = os.path.dirname(project_root)
    stage = os.path.basename(project_root)
    cache_dir = os.path.join(parent, f"{stage}_cache")
    os.makedirs(cache_dir, exist_ok=True)
    return cache_dir


def _cleanup_external_stage_cache_dir(project_root: str):
    cache_dir = os.path.join(os.path.dirname(project_root), f"{os.path.basename(project_root)}_cache")
    if os.path.exists(cache_dir):
        shutil.rmtree(cache_dir, ignore_errors=True)


def _load_hvigor_max_concurrency() -> int:
    from agent_bench.pipeline.loader import load_config
    config = load_config() or {}
    task_manager = config.get("task_manager") if isinstance(config, dict) else {}
    if not isinstance(task_manager, dict):
        return 3
    try:
        return max(1, int(task_manager.get("hvigor_max_concurrency") or 3))
    except Exception:
        return 3


def _get_hvigor_compile_semaphore() -> threading.BoundedSemaphore:
    global _HVIGOR_SEMAPHORE, _HVIGOR_SEMAPHORE_LIMIT
    limit = _load_hvigor_max_concurrency()
    with _HVIGOR_SEMAPHORE_LOCK:
        if _HVIGOR_SEMAPHORE is None or _HVIGOR_SEMAPHORE_LIMIT != limit:
            _HVIGOR_SEMAPHORE = threading.BoundedSemaphore(limit)
            _HVIGOR_SEMAPHORE_LIMIT = limit
        return _HVIGOR_SEMAPHORE


@contextmanager
def _hvigor_compile_slot():
    semaphore = _get_hvigor_compile_semaphore()
    semaphore.acquire()
    try:
        yield
    finally:
        semaphore.release()


def _is_reserved_windows_name(name: str) -> bool:
    base_name = os.path.splitext((name or "").strip())[0].lower()
    return base_name in WINDOWS_RESERVED_NAMES


def _strip_json5_comments(text: str) -> str:
    """去掉 JSON5 注释，保留字符串内容，便于做轻量配置解析。"""
    result = []
    index = 0
    in_string = False
    quote_char = ""
    escaped = False
    while index < len(text):
        char = text[index]
        next_char = text[index + 1] if index + 1 < len(text) else ""
        if in_string:
            result.append(char)
            if escaped:
                escaped = False
            elif char == "\\":
                escaped = True
            elif char == quote_char:
                in_string = False
            index += 1
            continue
        if char in {'"', "'"}:
            in_string = True
            quote_char = char
            result.append(char)
            index += 1
            continue
        if char == "/" and next_char == "/":
            index += 2
            while index < len(text) and text[index] not in "\r\n":
                index += 1
            continue
        if char == "/" and next_char == "*":
            index += 2
            while index + 1 < len(text) and not (text[index] == "*" and text[index + 1] == "/"):
                index += 1
            index += 2
            continue
        result.append(char)
        index += 1
    return "".join(result)


def _skip_ws(text: str, index: int) -> int:
    while index < len(text) and text[index].isspace():
        index += 1
    return index


def _find_matching(text: str, start: int, open_char: str, close_char: str) -> int:
    depth = 0
    in_string = False
    quote_char = ""
    escaped = False
    for index in range(start, len(text)):
        char = text[index]
        if in_string:
            if escaped:
                escaped = False
            elif char == "\\":
                escaped = True
            elif char == quote_char:
                in_string = False
            continue
        if char in {'"', "'"}:
            in_string = True
            quote_char = char
            continue
        if char == open_char:
            depth += 1
        elif char == close_char:
            depth -= 1
            if depth == 0:
                return index
    return -1


def _find_key_container_range(text: str, key: str, open_char: str, close_char: str) -> tuple[int, int] | None:
    pattern = re.compile(rf'["\']{re.escape(key)}["\']\s*:')
    for match in pattern.finditer(text):
        value_start = _skip_ws(text, match.end())
        if value_start >= len(text) or text[value_start] != open_char:
            continue
        value_end = _find_matching(text, value_start, open_char, close_char)
        if value_end >= 0:
            return value_start, value_end
    return None


def _split_top_level_objects(array_text: str) -> list[str]:
    objects = []
    index = 0
    while index < len(array_text):
        if array_text[index] != "{":
            index += 1
            continue
        end = _find_matching(array_text, index, "{", "}")
        if end < 0:
            break
        objects.append(array_text[index: end + 1])
        index = end + 1
    return objects


def _extract_string_value(text: str, key: str) -> str:
    pattern = re.compile(rf'["\']{re.escape(key)}["\']\s*:\s*(["\'])(.*?)\1', re.S)
    match = pattern.search(text)
    return str(match.group(2)).strip() if match else ""


def _detect_module_target(module_text: str) -> str:
    targets_range = _find_key_container_range(module_text, "targets", "[", "]")
    if not targets_range:
        return "default"
    targets_text = module_text[targets_range[0]: targets_range[1] + 1]
    first_name = _extract_string_value(targets_text, "name")
    return first_name or "default"


def _read_module_type(project_path: str, src_path: str) -> str:
    module_json_path = os.path.join(project_path, src_path, "src", "main", "module.json5")
    if not os.path.isfile(module_json_path):
        return ""
    try:
        with open(module_json_path, "r", encoding="utf-8") as f:
            module_text = _strip_json5_comments(f.read())
        return _extract_string_value(module_text, "type").lower()
    except Exception:
        return ""


def _resolve_hvigor_build_plan(project_path: str) -> tuple[list[str], list[str]]:
    """根据模块类型生成 `-p module=...` 和 hvigor task 列表。"""
    build_profile_path = os.path.join(project_path, "build-profile.json5")
    if not os.path.isfile(build_profile_path):
        return [], list(DEFAULT_HVIGOR_TASKS)
    try:
        with open(build_profile_path, "r", encoding="utf-8") as f:
            text = _strip_json5_comments(f.read())
    except Exception:
        return [], list(DEFAULT_HVIGOR_TASKS)

    modules_range = _find_key_container_range(text, "modules", "[", "]")
    if not modules_range:
        return [], list(DEFAULT_HVIGOR_TASKS)

    module_selectors = []
    tasks = []
    array_text = text[modules_range[0] + 1: modules_range[1]]
    for module_text in _split_top_level_objects(array_text):
        name = _extract_string_value(module_text, "name")
        src_path = _extract_string_value(module_text, "srcPath")
        if not name or not src_path:
            continue
        target = _detect_module_target(module_text)
        module_selectors.append(f"{name}@{target}")

        module_type = _read_module_type(project_path, src_path)
        if module_type in {"entry", "feature"} and "assembleHap" not in tasks:
            tasks.append("assembleHap")
        elif module_type == "har" and "assembleHar" not in tasks:
            tasks.append("assembleHar")
        elif module_type == "shared" and "assembleHsp" not in tasks:
            tasks.append("assembleHsp")

    return module_selectors, tasks or list(DEFAULT_HVIGOR_TASKS)


def _clean_markdown_code_blocks(code: str) -> str:
    """提取 markdown 代码块内的代码，无代码块则原样返回"""
    lines = code.split('\n')
    cleaned_lines = []
    in_code_block = False
    has_code_block = False

    for line in lines:
        stripped = line.strip()
        if stripped.startswith('```'):
            if not in_code_block:
                in_code_block = True
                has_code_block = True
            else:
                in_code_block = False
            continue
        if in_code_block:
            cleaned_lines.append(line)

    if not has_code_block:
        return code.strip()
    return '\n'.join(cleaned_lines).strip()


def _copy_template(src: str, dest: str):
    """复制模板工程到目标目录，跳过 build 产物和缓存"""
    def _ignore(directory, files):
        ignored = set()
        dir_name = os.path.basename(directory)
        if dir_name in ('build', '.hvigor', 'node_modules', 'oh_modules'):
            ignored.update(files)
        for f in files:
            if f == 'oh-package-lock.json5' or _is_reserved_windows_name(f):
                ignored.add(f)
        return ignored

    shutil.copytree(src, dest, ignore=_ignore)


def prepare_project_workspace(template_project_path: str, workspace_dir: str):
    """将 original_project 复制到指定 side 目录。"""
    if not template_project_path:
        raise ValueError("未提供测试用例 original_project 模板路径")
    if not os.path.isdir(template_project_path):
        raise FileNotFoundError(f"测试用例 original_project 模板不存在: {template_project_path}")

    if os.path.exists(workspace_dir):
        shutil.rmtree(workspace_dir)
    _copy_template(template_project_path, workspace_dir)


def check_project_compilable(project_path: str,
                             timeout: int = DEFAULT_TIMEOUT_SECONDS,
                             template_project_path: str = None) -> Dict[str, Any]:
    """直接编译 side 工程目录。"""
    if not os.path.isdir(project_path):
        return {
            "compilable": False,
            "error": f"待编译工程目录不存在: {project_path}",
            "checked": True,
        }

    is_success, error_msg = _compile_project(project_path, timeout=timeout)

    if not is_success:
        print(f"[COMPILE ERROR] error_msg={error_msg[:200]}")

    return {
        "compilable": is_success,
        "error": error_msg,
        "checked": True,
    }


def _load_harmony_toolchain_config() -> dict:
    from agent_bench.pipeline.loader import load_config
    config = load_config() or {}
    return config.get("harmony_toolchain") or {}


def _platform_key() -> tuple[str, str]:
    system = platform.system()
    if system == "Darwin":
        return system, "macos"
    if system == "Linux":
        return system, "linux"
    if system == "Windows":
        return system, "windows"
    raise RuntimeError(f"暂不支持的平台: {system}")


def _normalize_path(path: str) -> str:
    raw = str(path or "").strip()
    if not raw:
        return ""
    return os.path.normpath(os.path.expandvars(os.path.expanduser(raw)))


def _java_executable_path(java_home: str) -> str:
    _, platform_name = _platform_key()
    executable = "java.exe" if platform_name == "windows" else "java"
    return os.path.join(java_home, "bin", executable)


def _toolchain_record(node: str, hvigor: str, harmonyos_sdk: str, java_home: str, source: str) -> Dict[str, str]:
    return {
        "node": _normalize_path(node),
        "hvigor": _normalize_path(hvigor),
        "harmonyos_sdk": _normalize_path(harmonyos_sdk),
        "java_home": _normalize_path(java_home),
        "source": source,
    }


def _resolve_ohpm_path(toolchain: Dict[str, str]) -> str:
    """根据当前工具链位置推导 ohpm 可执行路径。"""
    node_path = _normalize_path(toolchain.get("node", ""))
    hvigor_path = _normalize_path(toolchain.get("hvigor", ""))
    _, platform_name = _platform_key()

    candidates: list[str] = []
    if platform_name == "macos":
        # .../Contents/tools/node/bin/node -> .../Contents/tools/ohpm/bin/ohpm
        contents_root = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(node_path))))
        candidates.extend([
            os.path.join(contents_root, "tools", "ohpm", "bin", "ohpm"),
            os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(hvigor_path))), "ohpm", "bin", "ohpm"),
        ])
    elif platform_name == "linux":
        base = os.path.dirname(os.path.dirname(os.path.dirname(hvigor_path)))
        candidates.extend([
            os.path.join(base, "ohpm", "bin", "ohpm"),
            os.path.join(base, "tool", "ohpm", "bin", "ohpm"),
            os.path.join(base, "tools", "ohpm", "bin", "ohpm"),
        ])
    else:
        base = os.path.dirname(os.path.dirname(os.path.dirname(hvigor_path)))
        candidates.extend([
            os.path.join(base, "ohpm", "bin", "ohpm.bat"),
            os.path.join(base, "ohpm", "bin", "ohpm.cmd"),
            os.path.join(base, "tools", "ohpm", "bin", "ohpm.bat"),
            os.path.join(base, "tools", "ohpm", "bin", "ohpm.cmd"),
        ])

    seen = set()
    for candidate in candidates:
        normalized = _normalize_path(candidate)
        if normalized and normalized not in seen:
            seen.add(normalized)
            if os.path.isfile(normalized):
                return normalized
    return ""


def _validate_toolchain_record(record: Dict[str, str]) -> list[str]:
    problems = []
    if not os.path.isfile(record.get("node", "")):
        problems.append(f"node 不存在: {record.get('node', '')}")
    if not os.path.isfile(record.get("hvigor", "")):
        problems.append(f"hvigor 不存在: {record.get('hvigor', '')}")
    if not os.path.isdir(record.get("harmonyos_sdk", "")):
        problems.append(f"harmonyos_sdk 不存在: {record.get('harmonyos_sdk', '')}")
    java_home = record.get("java_home", "")
    if not os.path.isdir(java_home):
        problems.append(f"java_home 不存在: {java_home}")
    elif not os.path.isfile(_java_executable_path(java_home)):
        problems.append(f"java 可执行文件不存在: {_java_executable_path(java_home)}")
    return problems


def _configured_toolchain_candidates() -> list[Dict[str, str]]:
    _, platform_name = _platform_key()
    toolchain_config = _load_harmony_toolchain_config()
    section = toolchain_config.get(platform_name) or {}
    if not isinstance(section, dict):
        return []
    required_values = [
        section.get("node"),
        section.get("hvigor"),
        section.get("harmonyos_sdk"),
        section.get("java_home"),
    ]
    if not any(str(item or "").strip() for item in required_values):
        return []
    return [
        _toolchain_record(
            section.get("node", ""),
            section.get("hvigor", ""),
            section.get("harmonyos_sdk", ""),
            section.get("java_home", ""),
            f"config:{platform_name}",
        )
    ]


def _auto_detect_toolchain_candidates() -> list[Dict[str, str]]:
    _, platform_name = _platform_key()
    candidates: list[Dict[str, str]] = []

    if platform_name == "macos":
        base_candidates = [
            "/Applications/DevEco-Studio.app/Contents",
            "/Applications/DevEco-Studio.app",
        ]
        for base in base_candidates:
            base = _normalize_path(base)
            if base.endswith(".app"):
                base = os.path.join(base, "Contents")
            candidates.append(_toolchain_record(
                os.path.join(base, "tools", "node", "bin", "node"),
                os.path.join(base, "tools", "hvigor", "bin", "hvigorw.js"),
                os.path.join(base, "sdk"),
                os.path.join(base, "jbr", "Contents", "Home"),
                f"auto:{base}",
            ))
        return candidates

    if platform_name == "linux":
        base_candidates = [
            "/home/work/hmsdk/command-line-tools",
            "/usr/local/hmsdk/command-line-tools",
        ]
        java_candidates = []
        for item in [
            os.environ.get("JAVA_HOME", ""),
            "/usr/lib/jvm/java-11-openjdk-amd64",
            "/usr/lib/jvm/java-17-openjdk-amd64",
        ]:
            value = _normalize_path(item)
            if value and value not in java_candidates:
                java_candidates.append(value)
        node_rel_candidates = [
            os.path.join("tool", "node", "bin", "node"),
            os.path.join("tools", "node", "bin", "node"),
        ]
        hvigor_rel_candidates = [
            os.path.join("hvigor", "bin", "hvigorw.js"),
            os.path.join("tools", "hvigor", "bin", "hvigorw.js"),
        ]
        for base in base_candidates:
            base = _normalize_path(base)
            for node_rel in node_rel_candidates:
                for hvigor_rel in hvigor_rel_candidates:
                    for java_home in java_candidates:
                        candidates.append(_toolchain_record(
                            os.path.join(base, node_rel),
                            os.path.join(base, hvigor_rel),
                            os.path.join(base, "sdk"),
                            java_home,
                            f"auto:{base}",
                        ))
        return candidates

    base_candidates = [
        os.path.join(os.environ.get("LOCALAPPDATA", ""), "Huawei", "DevEco Studio"),
        os.path.join(os.environ.get("ProgramFiles", ""), "Huawei", "DevEco Studio"),
        r"C:\Program Files\Huawei\DevEco Studio",
        r"C:\DevEco Studio",
        r"D:\DevEco Studio",
        r"D:\deveco\DevEco Studio",
    ]
    for base in base_candidates:
        base = _normalize_path(base)
        if not base:
            continue
        candidates.append(_toolchain_record(
            os.path.join(base, "tools", "node", "node.exe"),
            os.path.join(base, "tools", "hvigor", "bin", "hvigorw.js"),
            os.path.join(base, "sdk"),
            os.path.join(base, "jbr"),
            f"auto:{base}",
        ))
    return candidates


def resolve_harmony_toolchain() -> Dict[str, str]:
    """
    解析当前平台的 HarmonyOS 工具链。

    优先使用 config.yaml 中当前平台的显式配置；若配置不完整或不存在，且 auto_detect=true，
    则按平台默认目录自动探测。启动阶段如果仍然找不到完整工具链，应直接失败，不允许服务继续启动。
    """
    toolchain_config = _load_harmony_toolchain_config()
    auto_detect = bool(toolchain_config.get("auto_detect", True))
    checked_candidates = []

    for candidate in _configured_toolchain_candidates():
        problems = _validate_toolchain_record(candidate)
        if not problems:
            return candidate
        checked_candidates.append((candidate.get("source", "config"), problems))

    if auto_detect:
        for candidate in _auto_detect_toolchain_candidates():
            problems = _validate_toolchain_record(candidate)
            if not problems:
                return candidate
            checked_candidates.append((candidate.get("source", "auto"), problems))

    details = []
    for source, problems in checked_candidates[:8]:
        details.append(f"{source}: " + "；".join(problems))
    detail_text = "\n".join(details) if details else "未找到任何可用候选路径。"
    hint = "已尝试自动探测。" if auto_detect else "已禁用自动探测。"
    raise RuntimeError(f"HarmonyOS 工具链检查失败。{hint}\n{detail_text}")


def build_harmony_toolchain_env(toolchain: Dict[str, str] | None = None) -> Dict[str, str]:
    toolchain = toolchain or resolve_harmony_toolchain()
    return {
        TOOLCHAIN_ENV_NODE: toolchain["node"],
        TOOLCHAIN_ENV_HVIGOR: toolchain["hvigor"],
        TOOLCHAIN_ENV_JAVA: toolchain["java_home"],
        TOOLCHAIN_ENV_SDK: toolchain["harmonyos_sdk"],
        TOOLCHAIN_ENV_SDK_LEGACY: toolchain["harmonyos_sdk"],
    }


def apply_harmony_toolchain_env(toolchain: Dict[str, str] | None = None) -> Dict[str, str]:
    toolchain = toolchain or resolve_harmony_toolchain()
    for key, value in build_harmony_toolchain_env(toolchain).items():
        os.environ[key] = value
    return toolchain


def _build_workspace_compile_env(project_path: str, paths: Dict[str, str]) -> Dict[str, str]:
    """构造在工作区内隔离缓存目录的编译环境。"""
    env = os.environ.copy()
    meta_root = _external_stage_cache_dir(project_path)
    home_root = os.path.join(meta_root, "hvigor-home")
    local_appdata_root = os.path.join(home_root, "AppData", "Local")
    temp_root = os.path.join(meta_root, "tmp")
    npm_cache_root = os.path.join(local_appdata_root, "npm-cache")
    corepack_home = os.path.join(local_appdata_root, "corepack")

    os.makedirs(home_root, exist_ok=True)
    os.makedirs(local_appdata_root, exist_ok=True)
    os.makedirs(temp_root, exist_ok=True)
    os.makedirs(npm_cache_root, exist_ok=True)
    os.makedirs(corepack_home, exist_ok=True)

    env["DEVECO_SDK_HOME"] = paths["harmonyos_sdk"]
    env["HARMONYOS_SDK"] = paths["harmonyos_sdk"]
    env["JAVA_HOME"] = paths["java_home"]
    env["PATH"] = (
        os.path.join(paths["java_home"], "bin") + os.pathsep
        + os.path.dirname(paths["node"]) + os.pathsep
        + env.get("PATH", "")
    )
    env.update(build_harmony_toolchain_env(paths))
    env["HOME"] = home_root
    env["USERPROFILE"] = home_root
    env["LOCALAPPDATA"] = local_appdata_root
    env["TEMP"] = temp_root
    env["TMP"] = temp_root
    env["NPM_CONFIG_CACHE"] = npm_cache_root
    env["npm_config_cache"] = npm_cache_root
    env["COREPACK_HOME"] = corepack_home
    env["NPM_CONFIG_OFFLINE"] = "false"
    env["npm_config_offline"] = "false"
    env["NPM_CONFIG_PREFER_OFFLINE"] = "false"
    env["npm_config_prefer_offline"] = "false"
    env.pop("NODE_HOME", None)
    env.pop("HVIGOR_APP_HOME", None)
    for key in (
        "http_proxy", "https_proxy", "all_proxy", "no_proxy",
        "HTTP_PROXY", "HTTPS_PROXY", "ALL_PROXY", "NO_PROXY",
        "NPM_CONFIG_PROXY", "NPM_CONFIG_HTTPS_PROXY",
        "npm_config_proxy", "npm_config_https_proxy",
    ):
        env.pop(key, None)

    original_userprofile = os.environ.get("USERPROFILE") or ""
    if original_userprofile:
        user_npmrc = os.path.join(original_userprofile, ".npmrc")
        if os.path.isfile(user_npmrc):
            env["NPM_CONFIG_USERCONFIG"] = user_npmrc
            env["npm_config_userconfig"] = user_npmrc

    drive, tail = os.path.splitdrive(home_root)
    if drive:
        env["HOMEDRIVE"] = drive
        env["HOMEPATH"] = tail or "\\"

    return env


def build_agent_workspace_env(project_path: str) -> Dict[str, str]:
    """构造给 agent 进程复用的 HarmonyOS/DevEco 工作区环境。"""
    paths = resolve_harmony_toolchain()
    env = _build_workspace_compile_env(project_path, paths)
    env["AGENT_BENCH_WORKSPACE_DIR"] = project_path
    return env


def _compile_project(project_path: str, timeout: int = DEFAULT_TIMEOUT_SECONDS) -> Tuple[bool, str]:
    """在指定项目目录下执行 hvigor 编译"""
    paths = resolve_harmony_toolchain()

    if not os.path.exists(paths["node"]):
        return False, f"DevEco Studio node 未找到: {paths['node']}"
    if not os.path.exists(paths["hvigor"]):
        return False, f"DevEco Studio hvigorw.js 未找到: {paths['hvigor']}"
    if not os.path.exists(paths["harmonyos_sdk"]):
        return False, f"DevEco Studio SDK 未找到: {paths['harmonyos_sdk']}"

    try:
        # HarmonyOS 编译链路内存和 I/O 压力很高，多个 execution 并行时需要单独限流。
        with _hvigor_compile_slot():
            env = _build_workspace_compile_env(project_path, paths)
            ohpm_path = _resolve_ohpm_path(paths)
            if not ohpm_path:
                return False, "DevEco Studio ohpm 未找到"

            ohpm_cmd = [ohpm_path, "install", "--all"]
            ohpm_result = subprocess.run(
                ohpm_cmd,
                cwd=project_path,
                capture_output=True,
                text=True,
                timeout=min(timeout, 300),
                encoding="utf-8",
                errors="replace",
                env=env,
            )
            if ohpm_result.returncode != 0:
                ohpm_stdout = ohpm_result.stdout or ""
                ohpm_stderr = ohpm_result.stderr or ""
                ohpm_output = ohpm_stdout + "\n[STDERR]\n" + ohpm_stderr if ohpm_stderr else ohpm_stdout
                return False, f"[OHPM INSTALL FAILED]\n{ohpm_output}".strip()

            module_selectors, hvigor_tasks = _resolve_hvigor_build_plan(project_path)
            hvigor_cmd = [
                paths["node"], paths["hvigor"],
                "--mode", "module",
                "-p", "product=default",
            ]
            if module_selectors:
                hvigor_cmd.extend(["-p", "module=" + ",".join(module_selectors)])
            hvigor_cmd.extend([
                *hvigor_tasks,
                "--analyze=normal",
                "--parallel",
                "--incremental",
                "--no-daemon"
            ])

            result = subprocess.run(
                hvigor_cmd,
                cwd=project_path,
                capture_output=True,
                text=True,
                timeout=timeout,
                encoding="utf-8",
                errors="replace",
                env=env,
            )

            if result.returncode == 0:
                return True, ""

            stdout = result.stdout or ""
            stderr = result.stderr or ""
            full_output = stdout + "\n[STDERR]\n" + stderr if stderr else stdout
            return False, full_output if full_output.strip() else "编译失败"

    except subprocess.TimeoutExpired:
        return False, f"编译超时（{timeout}秒）"
    except FileNotFoundError:
        return False, f"命令未找到: {paths['node']}"
    except Exception as e:
        return False, f"编译异常: {str(e)}"
    finally:
        # `workspace_cache/` 只承载本轮编译进程的 HOME/TMP/npm/corepack 隔离目录，
        # 编译结束后就没有保留价值了。
        _cleanup_external_stage_cache_dir(project_path)


def check_compilable(code: str, timeout: int = DEFAULT_TIMEOUT_SECONDS, case_dir: str = None,
                     is_general_check: bool = False,
                     template_project_path: str = None) -> Dict[str, Any]:
    """检查代码是否可编译

    将模板工程复制到临时沙箱，写入代码后编译，编译完清理沙箱。
    每次调用使用独立副本，支持并行。

    Args:
        code: 要检查的 ArkTS 代码
        timeout: 编译超时时间（秒）
        case_dir: 用例产物目录，用于保存 Index.ets 副本
        is_general_check: True 时直接编译模板（不替换代码）
        template_project_path: 当前用例的 original_project 路径
    """
    # 沙箱放在 case_dir/compile_sandbox 下便于调试，无 case_dir 时用临时目录
    if case_dir:
        os.makedirs(case_dir, exist_ok=True)
        sandbox = os.path.join(case_dir, "compile_sandbox")
        tmp_parent = None
    else:
        tmp_parent = tempfile.mkdtemp(prefix="hos_compile_")
        sandbox = os.path.join(tmp_parent, "project")

    try:
        if os.path.exists(sandbox):
            shutil.rmtree(sandbox)
        if not template_project_path:
            return {
                "compilable": False,
                "error": "未提供测试用例 original_project 模板路径",
                "checked": True,
            }
        if not os.path.isdir(template_project_path):
            return {
                "compilable": False,
                "error": f"测试用例 original_project 模板不存在: {template_project_path}",
                "checked": True,
            }

        template_path = template_project_path
        _copy_template(template_path, sandbox)

        if not is_general_check:
            cleaned_code = _clean_markdown_code_blocks(code)
            index_path = os.path.join(sandbox, INDEX_ETS_REL)
            with open(index_path, "w", encoding="utf-8") as f:
                f.write(cleaned_code)

        is_success, error_msg = _compile_project(sandbox, timeout=timeout)

        if not is_success:
            print(f"[COMPILE ERROR] error_msg={error_msg[:200]}")

        return {
            "compilable": is_success,
            "error": error_msg,
            "checked": True,
        }
    finally:
        if tmp_parent:
            shutil.rmtree(tmp_parent, ignore_errors=True)


def _main():
    parser = argparse.ArgumentParser(description="HarmonyOS 工具链检测")
    parser.add_argument("--print-env", action="store_true", help="输出启动 OpenCode/执行器所需的环境变量")
    args = parser.parse_args()

    toolchain = resolve_harmony_toolchain()
    if args.print_env:
        for key, value in build_harmony_toolchain_env(toolchain).items():
            print(f"{key}={value}")
        return
    print(json.dumps(toolchain, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    _main()
