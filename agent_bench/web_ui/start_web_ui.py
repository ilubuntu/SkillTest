#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""鸿蒙开发工具评测系统 Web UI 启动脚本"""

import sys
import os
import subprocess
from pathlib import Path

SCRIPT_DIR = Path(__file__).parent
AGENT_BENCH_DIR = SCRIPT_DIR.parent
BACKEND_DIR = SCRIPT_DIR / "backend"
FRONTEND_DIR = SCRIPT_DIR / "frontend"
DIST_DIR = FRONTEND_DIR / "dist"

def build_frontend():
    if not DIST_DIR.exists():
        print("[INFO] 正在构建前端...")
        import shutil
        npm_cmd = shutil.which("npm")
        if not npm_cmd:
            print("[ERROR] 未找到 npm 命令，请先安装 Node.js")
            return False

        result = subprocess.run(
            [npm_cmd, "install"],
            cwd=str(FRONTEND_DIR),
            capture_output=True,
            text=True
        )
        if result.returncode != 0:
            print(f"[WARN] npm install 失败: {result.stderr}")
            return False

        result = subprocess.run(
            [npm_cmd, "run", "build"],
            cwd=str(FRONTEND_DIR),
            capture_output=True,
            text=True
        )
        if result.returncode != 0:
            print(f"[ERROR] 前端构建失败: {result.stderr}")
            return False
        print("[INFO] 前端构建完成")
    return True

def main():
    os.chdir(AGENT_BENCH_DIR)

    print("=" * 50)
    print("  鸿蒙开发工具评测系统 Web UI")
    print("=" * 50)
    print(f"[INFO] 工作目录: {AGENT_BENCH_DIR}")

    try:
        import fastapi
        import uvicorn
        import sse_starlette
    except ImportError:
        print("[ERROR] 缺少依赖库，正在安装...")
        os.system(f"{sys.executable} -m pip install -r \"{BACKEND_DIR / 'requirements.txt'}\"")

    if not build_frontend():
        print("[ERROR] 前端构建失败，无法启动服务")
        return

    print("[INFO] 启动 Web UI 服务...")
    print("[INFO] 访问地址: http://localhost:5177")
    print("[INFO] 按 Ctrl+C 停止服务")
    print("=" * 50)

    sys.path.insert(0, str(AGENT_BENCH_DIR))
    sys.path.insert(0, str(BACKEND_DIR))

    from main import app

    uvicorn.run(app, host="0.0.0.0", port=5177, reload=False)

if __name__ == "__main__":
    main()