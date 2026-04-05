#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

VENV_DIR="$ROOT_DIR/.pack_venv"
PYI="$VENV_DIR/bin/pyinstaller"
export PYINSTALLER_CONFIG_DIR="$ROOT_DIR/.pyinstaller"

if [ ! -x "$PYI" ]; then
  echo "PyInstaller 未安装，请先创建 .pack_venv 并安装 PyInstaller" >&2
  exit 1
fi

rm -rf "$ROOT_DIR/build/executor_macos" "$ROOT_DIR/dist/agent-bench-executor" "$PYINSTALLER_CONFIG_DIR"

"$PYI" \
  --clean \
  --noconfirm \
  --name agent-bench-executor \
  --distpath "$ROOT_DIR/dist" \
  --workpath "$ROOT_DIR/build/executor_macos" \
  --paths "$ROOT_DIR" \
  --console \
  --add-data "$ROOT_DIR/agent_bench/enhancements:agent_bench/enhancements" \
  --add-data "$ROOT_DIR/agent_bench/profiles:agent_bench/profiles" \
  --add-data "$ROOT_DIR/agent_bench/evaluator:agent_bench/evaluator" \
  "$ROOT_DIR/agent_bench/executor/main.py"

cp -R "$ROOT_DIR/config" "$ROOT_DIR/dist/agent-bench-executor/config"

echo
echo "打包完成:"
echo "  $ROOT_DIR/dist/agent-bench-executor/"
