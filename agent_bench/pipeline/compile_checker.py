# -*- coding: utf-8 -*-
"""ArkTS 编译验证模块

每次编译将 empty_hos_project 模板复制到独立沙箱目录，支持并行编译。
"""

import os
import shutil
import subprocess
import tempfile
from typing import Dict, Tuple, Any

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TEMPLATE_PROJECT_PATH = os.path.join(BASE_DIR, "empty_hos_project")
INDEX_ETS_REL = os.path.join("entry", "src", "main", "ets", "pages", "Index.ets")


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


def _copy_template(dest: str):
    """复制模板工程到目标目录，跳过 build 产物和缓存"""
    def _ignore(directory, files):
        ignored = set()
        dir_name = os.path.basename(directory)
        if dir_name in ('build', '.hvigor', 'node_modules', 'oh_modules'):
            ignored.update(files)
        for f in files:
            if f == 'oh-package-lock.json5':
                ignored.add(f)
        return ignored

    shutil.copytree(TEMPLATE_PROJECT_PATH, dest, ignore=_ignore)


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
        env = os.environ.copy()
        env["DEVECO_SDK_HOME"] = paths["sdk"]
        env["JAVA_HOME"] = paths["java"]
        env["PATH"] = (
            os.path.join(paths["java"], "bin") + os.pathsep
            + os.path.dirname(paths["node"]) + os.pathsep
            + env.get("PATH", "")
        )

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
                     is_general_check: bool = False) -> Dict[str, Any]:
    """检查代码是否可编译

    将模板工程复制到临时沙箱，写入代码后编译，编译完清理沙箱。
    每次调用使用独立副本，支持并行。

    Args:
        code: 要检查的 ArkTS 代码
        timeout: 编译超时时间（秒）
        case_dir: 用例产物目录，用于保存 Index.ets 副本
        is_general_check: True 时直接编译模板（不替换代码）
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
        _copy_template(sandbox)

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
