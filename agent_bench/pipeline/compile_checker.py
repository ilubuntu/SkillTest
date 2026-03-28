# -*- coding: utf-8 -*-
"""ArkTS 编译验证模块

职责：
- 将生成的代码写入 empty_hos_project 的 Index.ets
- 执行 hvigorw 编译命令验证代码可编译性
- 返回编译结果（成功/失败、错误信息）
"""

import os
import subprocess
import shutil
from typing import Dict, Optional, Tuple, Any

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
EMPTY_HOS_PROJECT_PATH = os.path.join(BASE_DIR, "empty_hos_project")
INDEX_ETS_PATH = os.path.join(EMPTY_HOS_PROJECT_PATH, "entry", "src", "main", "ets", "pages", "Index.ets")

INDEX_ETS_TEMPLATE = """@Entry
@Component
struct Index {
  build() {

  }
}
"""


def write_index_ets(code: str) -> bool:
    """将代码写入 empty_hos_project/entry/src/main/ets/pages/Index.ets

    Args:
        code: 要写入的 ArkTS 代码

    Returns:
        是否写入成功
    """
    try:
        cleaned_code = _clean_markdown_code_blocks(code)
        with open(INDEX_ETS_PATH, "w", encoding="utf-8") as f:
            f.write(cleaned_code)
        return True
    except Exception as e:
        return False


def _clean_markdown_code_blocks(code: str) -> str:
    """删除 markdown 代码块标记，提取代码内容

    移除 ```typescript, ``` 等 markdown 代码块标记，
    只保留代码块内的内容，删除块外的解释文字。
    如果没有代码块标记，返回原始代码。

    Args:
        code: 原始代码

    Returns:
        清理后的代码
    """
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
                continue
            else:
                in_code_block = False
                continue
        if in_code_block:
            cleaned_lines.append(line)

    if not has_code_block:
        return code.strip()
    return '\n'.join(cleaned_lines).strip()


def compile_arkts_project(timeout: int = 300) -> Tuple[bool, str]:
    """执行 hvigor 编译命令验证代码可编译性

    使用 DevEco Studio 内置的 node + hvigorw.js 进行编译

    Args:
        timeout: 编译超时时间（秒）

    Returns:
        (is_success, error_message)
        - is_success: 编译是否成功
        - error_message: 错误信息（如果编译失败）
    """
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
        env["PATH"] = os.path.join(paths["java"], "bin") + os.pathsep + os.path.dirname(paths["node"]) + os.pathsep + env.get("PATH", "")

        hvigor_cmd = [
            paths["node"], paths["hvigor"],
            "--mode", "module",
            "-p", "product=default",
            "assembleHap",
            "--analyze=normal",
            "--parallel",
            "--incremental"
        ]

        result = subprocess.run(
            hvigor_cmd,
            cwd=EMPTY_HOS_PROJECT_PATH,
            capture_output=True,
            text=True,
            timeout=timeout,
            encoding="utf-8",
            errors="replace",
            env=env,
        )

        if result.returncode == 0:
            return True, ""
        else:
            stdout = result.stdout or ""
            stderr = result.stderr or ""
            full_output = stdout + "\n[STDERR]\n" + stderr if stderr else stdout
            error_msg = full_output if full_output.strip() else "编译失败"
            return False, error_msg

    except subprocess.TimeoutExpired:
        return False, f"编译超时（{timeout}秒）"
    except FileNotFoundError:
        return False, f"命令未找到: {paths['node']}"
    except Exception as e:
        return False, f"编译异常: {str(e)}"


def _find_deveco_paths() -> Dict[str, str]:
    """查找 DevEco Studio 相关路径

    Returns:
        {
            "node": str,       # node.exe 路径
            "hvigor": str,     # hvigorw.js 路径
            "java": str,       # JAVA_HOME 路径
            "sdk": str,        # DEVECO_SDK_HOME 路径
        }
    """
    deveco_base = r"D:\deveco\DevEco Studio"
    
    return {
        "node": os.path.join(deveco_base, "tools", "node", "node.exe"),
        "hvigor": os.path.join(deveco_base, "tools", "hvigor", "bin", "hvigorw.js"),
        "java": os.path.join(deveco_base, "jbr"),
        "sdk": os.path.join(deveco_base, "sdk"),
    }


def _extract_compile_error(output: str) -> str:
    """从编译输出中提取关键错误信息

    Args:
        output: 编译命令的完整输出

    Returns:
        提取的错误信息（最多返回最后20行）
    """
    if not output:
        return "未知错误"

    lines = output.strip().split("\n")
    error_lines = [line for line in lines if "error" in line.lower() or "failed" in line.lower()]

    if error_lines:
        return "\n".join(error_lines[-20:])
    return "\n".join(lines[-20:]) if lines else "未知错误"


def check_compilable(code: str, timeout: int = 300, case_dir: str = None, is_general_check: bool = False) -> Dict[str, Any]:
    """检查代码是否可编译

    完整流程（普通场景）：
    1. 备份原始 Index.ets
    2. 将代码写入 Index.ets
    3. 保存替换后的 Index.ets 到 case_dir（如果提供）
    4. 执行编译
    5. 恢复原始 Index.ets
    6. 返回编译结果

    完整流程（general 场景 is_general_check=True）：
    1. 直接编译 empty_hos_project（不替换代码）
    2. 返回编译结果

    Args:
        code: 要检查的 ArkTS 代码
        timeout: 编译超时时间（秒）
        case_dir: 用例产物目录，用于保存替换后的 Index.ets
        is_general_check: 是否为通用用例检查（直接编译，不替换代码）

    Returns:
        {
            "compilable": bool,      # 是否可编译
            "error": str,             # 错误信息（如果不可编译）
            "checked": bool,          # 是否执行了检查
        }
    """
    if is_general_check:
        is_success, error_msg = compile_arkts_project(timeout=timeout)
        if not is_success:
            print(f"[COMPILE ERROR] error_msg={error_msg}")
        return {
            "compilable": is_success,
            "error": error_msg,
            "checked": True,
        }

    try:
        with open(INDEX_ETS_PATH, "r", encoding="utf-8") as f:
            original_code = f.read()

        if not write_index_ets(code):
            return {
                "compilable": False,
                "error": "无法写入 Index.ets",
                "checked": True,
            }

        if case_dir:
            index_ets_copy = os.path.join(case_dir, "Index.ets")
            os.makedirs(case_dir, exist_ok=True)
            with open(index_ets_copy, "w", encoding="utf-8") as f:
                f.write(code)

        is_success, error_msg = compile_arkts_project(timeout=timeout)
        
        if not is_success:
            print(f"[COMPILE ERROR] error_msg={error_msg}")
        
        return {
            "compilable": is_success,
            "error": error_msg,
            "checked": True,
        }
    finally:
        with open(INDEX_ETS_PATH, "w", encoding="utf-8") as f:
            f.write(INDEX_ETS_TEMPLATE)