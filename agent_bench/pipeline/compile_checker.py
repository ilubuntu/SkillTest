# -*- coding: utf-8 -*-
"""ArkTS 编译验证模块

每次编译将测试用例自带的 original_project 模板复制到独立沙箱目录，支持并行编译。
"""

import os
import json
import shutil
import subprocess
import tempfile
from typing import Dict, Tuple, Any

INDEX_ETS_REL = os.path.join("entry", "src", "main", "ets", "pages", "Index.ets")
META_DIR_NAME = ".agent_bench"
IGNORED_COMPARE_DIRS = {"build", ".hvigor", "node_modules", "oh_modules", META_DIR_NAME}
WINDOWS_RESERVED_NAMES = {
    "con", "prn", "aux", "nul",
    *(f"com{i}" for i in range(1, 10)),
    *(f"lpt{i}" for i in range(1, 10)),
}


def _external_stage_meta_dir(project_root: str) -> str:
    parent = os.path.dirname(project_root)
    stage = os.path.basename(project_root)
    meta_dir = os.path.join(parent, f"{stage}_meta")
    os.makedirs(meta_dir, exist_ok=True)
    return meta_dir


def _external_stage_cache_dir(project_root: str) -> str:
    parent = os.path.dirname(project_root)
    stage = os.path.basename(project_root)
    cache_dir = os.path.join(parent, f"{stage}_cache")
    os.makedirs(cache_dir, exist_ok=True)
    return cache_dir


def _is_reserved_windows_name(name: str) -> bool:
    base_name = os.path.splitext((name or "").strip())[0].lower()
    return base_name in WINDOWS_RESERVED_NAMES


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


def _collect_project_files(root: str) -> Dict[str, str]:
    """收集工程文件快照（相对路径 -> 绝对路径）"""
    file_map: Dict[str, str] = {}
    for current_root, dirs, files in os.walk(root):
        dirs[:] = [d for d in dirs if d not in IGNORED_COMPARE_DIRS and not _is_reserved_windows_name(d)]
        for name in files:
            if name == "oh-package-lock.json5" or _is_reserved_windows_name(name):
                continue
            abs_path = os.path.join(current_root, name)
            try:
                rel_path = os.path.relpath(abs_path, root)
            except ValueError:
                continue
            file_map[rel_path] = abs_path
    return file_map


def _diff_project_files(original_root: str, final_root: str) -> list:
    """比较原始工程和最终工程，返回发生变化的相对路径列表"""
    before_files = _collect_project_files(original_root)
    after_files = _collect_project_files(final_root)
    changed = set()

    for rel_path in sorted(set(before_files) | set(after_files)):
        before_path = before_files.get(rel_path)
        after_path = after_files.get(rel_path)
        if before_path is None or after_path is None:
            changed.add(rel_path)
            continue
        with open(before_path, "rb") as f:
            before_bytes = f.read()
        with open(after_path, "rb") as f:
            after_bytes = f.read()
        if before_bytes != after_bytes:
            changed.add(rel_path)

    return sorted(changed)


def _save_changed_files(project_root: str, changed_files: list):
    """保存最简版 changed_files 产物"""
    meta_dir = _external_stage_meta_dir(project_root)
    with open(os.path.join(meta_dir, "changed_files.json"), "w", encoding="utf-8") as f:
        json.dump({"changed_files": changed_files}, f, ensure_ascii=False, indent=2)


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
                             timeout: int = 300,
                             template_project_path: str = None) -> Dict[str, Any]:
    """直接编译 side 工程目录，并基于 original_project 记录 changed_files。"""
    if not os.path.isdir(project_path):
        return {
            "compilable": False,
            "error": f"待编译工程目录不存在: {project_path}",
            "checked": True,
        }

    is_success, error_msg = _compile_project(project_path, timeout=timeout)
    if template_project_path and os.path.isdir(template_project_path):
        changed_files = _diff_project_files(template_project_path, project_path)
        _save_changed_files(project_path, changed_files)

    if not is_success:
        print(f"[COMPILE ERROR] error_msg={error_msg[:200]}")

    return {
        "compilable": is_success,
        "error": error_msg,
        "checked": True,
    }


def _find_deveco_base() -> str:
    """查找 DevEco Studio 的工具根目录

    优先读取 config.yaml 的 deveco_path，未配置则按平台自动探测。
    """
    import platform
    from agent_bench.pipeline.loader import load_config

    config = load_config()
    deveco_path = config.get("deveco_path")
    system = platform.system()

    if deveco_path:
        deveco_path = deveco_path.rstrip("/\\")
        if system == "Darwin" and not deveco_path.endswith("Contents"):
            candidate = os.path.join(deveco_path, "Contents")
            if os.path.isdir(os.path.join(candidate, "tools")):
                return candidate
        if os.path.isdir(os.path.join(deveco_path, "tools")):
            return deveco_path
        return deveco_path

    if system == "Darwin":
        candidates = [
            "/Applications/DevEco-Studio.app/Contents",
        ]
    else:
        candidates = [
            os.path.join(os.environ.get("LOCALAPPDATA", ""), "Huawei", "DevEco Studio"),
            os.path.join(os.environ.get("ProgramFiles", ""), "Huawei", "DevEco Studio"),
            r"C:\DevEco Studio",
            r"D:\DevEco Studio",
            r"D:\deveco\DevEco Studio",
        ]

    for c in candidates:
        if c and os.path.isdir(os.path.join(c, "tools")):
            return c

    if system == "Darwin":
        return "/Applications/DevEco-Studio.app/Contents"
    return r"C:\Program Files\Huawei\DevEco Studio"


def _find_deveco_paths() -> Dict[str, str]:
    """基于 DevEco Studio 根目录，构造各工具的完整路径"""
    import platform
    system = platform.system()
    deveco_base = _find_deveco_base()

    if system == "Darwin":
        node = os.path.join(deveco_base, "tools", "node", "bin", "node")
        java = os.path.join(deveco_base, "jbr", "Contents", "Home")
    else:
        node = os.path.join(deveco_base, "tools", "node", "node.exe")
        java = os.path.join(deveco_base, "jbr")

    return {
        "node": node,
        "hvigor": os.path.join(deveco_base, "tools", "hvigor", "bin", "hvigorw.js"),
        "java": java,
        "sdk": os.path.join(deveco_base, "sdk"),
    }


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

    env["DEVECO_SDK_HOME"] = paths["sdk"]
    env["HARMONYOS_SDK"] = paths["sdk"]
    env["JAVA_HOME"] = paths["java"]
    env["PATH"] = (
        os.path.join(paths["java"], "bin") + os.pathsep
        + os.path.dirname(paths["node"]) + os.pathsep
        + env.get("PATH", "")
    )
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

    proxy = env.get("HTTPS_PROXY") or env.get("https_proxy") or env.get("HTTP_PROXY") or env.get("http_proxy")
    if proxy:
        env.setdefault("NPM_CONFIG_HTTPS_PROXY", proxy)
        env.setdefault("npm_config_https_proxy", proxy)
        env.setdefault("NPM_CONFIG_PROXY", proxy)
        env.setdefault("npm_config_proxy", proxy)

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
    paths = _find_deveco_paths()
    env = _build_workspace_compile_env(project_path, paths)
    env["AGENT_BENCH_NODE_BIN"] = paths["node"]
    env["AGENT_BENCH_HVIGOR_JS"] = paths["hvigor"]
    env["AGENT_BENCH_JAVA_HOME"] = paths["java"]
    env["AGENT_BENCH_SDK_ROOT"] = paths["sdk"]
    env["AGENT_BENCH_WORKSPACE_DIR"] = project_path
    return env


def _compile_project(project_path: str, timeout: int = 300) -> Tuple[bool, str]:
    """在指定项目目录下执行 hvigor 编译"""
    paths = _find_deveco_paths()

    if not os.path.exists(paths["node"]):
        return False, f"DevEco Studio node 未找到: {paths['node']}"
    if not os.path.exists(paths["hvigor"]):
        return False, f"DevEco Studio hvigorw.js 未找到: {paths['hvigor']}"
    if not os.path.exists(paths["sdk"]):
        return False, f"DevEco Studio SDK 未找到: {paths['sdk']}"

    try:
        env = _build_workspace_compile_env(project_path, paths)

        hvigor_cmd = [
            paths["node"], paths["hvigor"],
            "--mode", "module",
            "-p", "product=default",
            "assembleHap",
            "--analyze=normal",
            "--parallel",
            "--incremental",
            "--no-daemon"
        ]

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


def check_compilable(code: str, timeout: int = 300, case_dir: str = None,
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
        if case_dir:
            changed_files = _diff_project_files(template_path, sandbox)
            _save_changed_files(case_dir, changed_files)

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
