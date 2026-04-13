#!/bin/bash
# ================================================================
# Agent Bench 一键部署脚本（macOS）
#
# 用法:
#   ./deploy.sh              启动执行器（默认）
#   ./deploy.sh stop         停止所有服务
#   ./deploy.sh restart      重启执行器（含 OpenCode）
#   ./deploy.sh restart-executor  只重启执行器服务（不动 OpenCode）
#   ./deploy.sh logs         查看执行器流程日志
#   ./deploy.sh status       查看服务状态
#
# 服务列表:
#   - OpenCode Server   端口 4096   Agent 执行引擎
#   - 执行器服务        端口 8000   本地任务接收与状态上报
#
# 依赖:
#   - opencode  (https://opencode.ai)
#   - python3 + pip3
#
# ================================================================

set -e

# ── 配置 ──────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OPENCODE_PORT=4096
BACKEND_PORT=8000
EXECUTOR_DIR="$SCRIPT_DIR/agent_bench/executor"
LOG_DIR="$SCRIPT_DIR/logs"
OPENCODE_LOG="$LOG_DIR/opencode.log"
CURRENT_EXECUTOR_LOG_FILE="$LOG_DIR/current_executor_log"
BACKEND_LOG=""
PYTHON_BIN=""
OPENCODE_HTTP_PROXY=""
OPENCODE_HTTPS_PROXY=""
OPENCODE_ALL_PROXY=""
OPENCODE_NO_PROXY=""


# ── 颜色 ──────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

# ── 依赖检查 ──────────────────────────────────────────────
check_deps() {
    info "检查依赖..."
    local missing=0

    if ! command -v opencode &>/dev/null; then
        error "opencode 未安装，请先安装: https://opencode.ai"
        missing=1
    fi
    if command -v python &>/dev/null; then
        PYTHON_BIN="$(command -v python)"
    elif command -v python3 &>/dev/null; then
        PYTHON_BIN="$(command -v python3)"
    else
        error "python / python3 未安装"
        missing=1
    fi
    if [ $missing -eq 1 ]; then
        error "缺少必要依赖，请先安装后重试"
        exit 1
    fi
    info "依赖检查通过 (Python: $PYTHON_BIN)"
}

ensure_log_dir() {
    mkdir -p "$LOG_DIR"
}

set_executor_log_file() {
    local stamp
    stamp="$(date +"%Y%m%d_%H%M%S")"
    BACKEND_LOG="$LOG_DIR/agent_bench_${stamp}.log"
    printf "%s\n" "$BACKEND_LOG" > "$CURRENT_EXECUTOR_LOG_FILE"
}

resolve_executor_log_file() {
    if [ -n "${BACKEND_LOG:-}" ]; then
        echo "$BACKEND_LOG"
        return
    fi
    if [ -f "$CURRENT_EXECUTOR_LOG_FILE" ]; then
        cat "$CURRENT_EXECUTOR_LOG_FILE"
        return
    fi
    ls -t "$LOG_DIR"/agent_bench_*.log 2>/dev/null | head -1
}

load_opencode_proxy_config() {
    local config_path="$SCRIPT_DIR/config/agents.yaml"
    if [ ! -f "$config_path" ]; then
        return
    fi
    local proxy_values=""
    proxy_values="$("$PYTHON_BIN" - "$config_path" <<'PY'
import sys
try:
    import yaml
except Exception:
    sys.exit(0)

path = sys.argv[1]
try:
    with open(path, "r", encoding="utf-8") as f:
        data = yaml.safe_load(f) or {}
except Exception:
    sys.exit(0)

proxy = {}
agents = data.get("agents") or []
if isinstance(agents, list):
    for agent in agents:
        if not isinstance(agent, dict):
            continue
        candidate = agent.get("opencode_proxy") or {}
        if isinstance(candidate, dict) and candidate:
            proxy = candidate
            break
if not isinstance(proxy, dict):
    sys.exit(0)

for key in ("http_proxy", "https_proxy", "all_proxy", "no_proxy"):
    value = str(proxy.get(key) or "").strip()
    print(f"{key}={value}")
PY
)"
    while IFS='=' read -r key value; do
        case "$key" in
            http_proxy) OPENCODE_HTTP_PROXY="$value" ;;
            https_proxy) OPENCODE_HTTPS_PROXY="$value" ;;
            all_proxy) OPENCODE_ALL_PROXY="$value" ;;
            no_proxy) OPENCODE_NO_PROXY="$value" ;;
        esac
    done <<< "$proxy_values"
}

# ── 清理已有进程 ──────────────────────────────────────────
kill_port() {
    local port=$1
    local pids=""
    if command -v lsof >/dev/null 2>&1; then
        pids="$(lsof -ti :$port 2>/dev/null || true)"
    elif command -v powershell.exe >/dev/null 2>&1; then
        pids="$(powershell.exe -NoProfile -Command "[int]\$port=$port; \$connections = Get-NetTCPConnection -LocalPort \$port -State Listen -ErrorAction SilentlyContinue; if (\$connections) { \$connections | Select-Object -ExpandProperty OwningProcess -Unique }" | tr -d '\r' || true)"
    fi
    if [ -n "$pids" ]; then
        warn "端口 $port 已被占用，正在清理..."
        if command -v powershell.exe >/dev/null 2>&1; then
            for pid in $pids; do
                powershell.exe -NoProfile -Command "Stop-Process -Id $pid -Force -ErrorAction SilentlyContinue" >/dev/null 2>&1 || true
            done
        else
            echo "$pids" | xargs kill -9 2>/dev/null || true
        fi
        sleep 1
    fi
}

# ── 启动 OpenCode Server ─────────────────────────────────
start_opencode() {
    info "启动 OpenCode Server (端口 $OPENCODE_PORT)..."

    # 检查是否已在运行
    if curl -s "http://localhost:$OPENCODE_PORT/global/health" 2>/dev/null | grep -q "healthy"; then
        info "OpenCode Server 已在运行，跳过启动"
        return
    fi

    kill_port $OPENCODE_PORT

    if [ -n "$OPENCODE_HTTP_PROXY" ] || [ -n "$OPENCODE_HTTPS_PROXY" ] || [ -n "$OPENCODE_ALL_PROXY" ]; then
        info "OpenCode Server 启动将使用代理环境"
        info "  http_proxy=${OPENCODE_HTTP_PROXY:-<empty>}"
        info "  https_proxy=${OPENCODE_HTTPS_PROXY:-<empty>}"
        info "  all_proxy=${OPENCODE_ALL_PROXY:-<empty>}"
        info "  NO_PROXY=${OPENCODE_NO_PROXY:-<empty>}"
        env \
            http_proxy="$OPENCODE_HTTP_PROXY" \
            https_proxy="$OPENCODE_HTTPS_PROXY" \
            HTTP_PROXY="$OPENCODE_HTTP_PROXY" \
            HTTPS_PROXY="$OPENCODE_HTTPS_PROXY" \
            all_proxy="$OPENCODE_ALL_PROXY" \
            ALL_PROXY="$OPENCODE_ALL_PROXY" \
            no_proxy="$OPENCODE_NO_PROXY" \
            NO_PROXY="$OPENCODE_NO_PROXY" \
            nohup opencode serve --port $OPENCODE_PORT >>"$OPENCODE_LOG" 2>&1 &
    else
        info "OpenCode Server 启动不使用代理环境"
        nohup opencode serve --port $OPENCODE_PORT >>"$OPENCODE_LOG" 2>&1 &
    fi

    # 等待启动
    info "等待 OpenCode Server 启动..."
    for i in $(seq 1 30); do
        if curl -s "http://localhost:$OPENCODE_PORT/global/health" 2>/dev/null | grep -q "healthy"; then
            info "OpenCode Server 启动成功"
            return
        fi
        sleep 1
    done
    warn "OpenCode Server 可能未完全启动，请稍后检查"
}

# ── 安装 Python 依赖 ─────────────────────────────────────
install_python_deps() {
    info "检查 Python 依赖..."
    local req="$EXECUTOR_DIR/requirements.txt"
    if [ -f "$req" ]; then
        "$PYTHON_BIN" -m pip install --break-system-packages -q -r "$req" 2>/dev/null || \
        "$PYTHON_BIN" -m pip install -q -r "$req" 2>/dev/null || \
        warn "Python 依赖安装失败，请手动安装: $PYTHON_BIN -m pip install -r $req"
    fi
}

# ── 启动执行器服务 ──────────────────────────────────────
start_backend() {
    info "启动执行器服务 (端口 $BACKEND_PORT)..."

    if curl -s "http://localhost:$BACKEND_PORT/api/health" &>/dev/null; then
        if [ -z "${BACKEND_LOG:-}" ]; then
            BACKEND_LOG="$(resolve_executor_log_file)"
        fi
        info "执行器服务已在运行，跳过启动"
        return
    fi

    kill_port $BACKEND_PORT

    if [ -z "${BACKEND_LOG:-}" ]; then
        set_executor_log_file
    fi
    cd "$SCRIPT_DIR"
    nohup "$PYTHON_BIN" -m uvicorn agent_bench.executor.main:app --host 0.0.0.0 --port $BACKEND_PORT --no-access-log --log-level warning >>"$BACKEND_LOG" 2>&1 &

    # 等待启动
    for i in $(seq 1 10); do
        if curl -s "http://localhost:$BACKEND_PORT/api/health" &>/dev/null; then
            info "执行器服务启动成功"
            return
        fi
        sleep 1
    done
    warn "执行器服务可能未完全启动"
}

# ── 启动执行器模式 ───────────────────────────────────────
start_executor() {
    echo ""
    echo "=========================================="
    echo "  Agent Bench 执行器"
    echo "=========================================="
    echo ""
    check_deps
    ensure_log_dir
    install_python_deps
    load_opencode_proxy_config
    start_opencode
    start_backend
    echo ""
    info "执行器已就绪，等待任务下发..."
    info "任务入口: http://localhost:$BACKEND_PORT/api/cloud-api/start"
    info "执行器日志:  $BACKEND_LOG"
    echo ""
    info "进入执行器流程日志视图，日志同时写入本地文件: $BACKEND_LOG"
    info "按 Ctrl+C 将退出日志查看并停止本次启动的所有服务"
    echo ""
    trap 'echo ""; warn "收到退出信号，停止本次启动的所有服务..."; stop_all; exit 0' INT TERM
    follow_executor_logs
}

# ── 停止所有服务 ─────────────────────────────────────────
stop_all() {
    info "停止所有服务..."
    kill_port $OPENCODE_PORT
    kill_port $BACKEND_PORT
    info "所有服务已停止"
}

# ── 查看状态 ─────────────────────────────────────────────
status() {
    echo ""
    echo "========== Agent Bench 服务状态 =========="
    echo ""

    # OpenCode
    if curl -s "http://localhost:$OPENCODE_PORT/global/health" 2>/dev/null | grep -q "healthy"; then
        echo -e "  OpenCode Server  :  ${GREEN}运行中${NC}  http://localhost:$OPENCODE_PORT"
    else
        echo -e "  OpenCode Server  :  ${RED}未运行${NC}"
    fi

    # Executor
    if curl -s "http://localhost:$BACKEND_PORT/api/health" &>/dev/null; then
        echo -e "  执行器服务       :  ${GREEN}运行中${NC}  http://localhost:$BACKEND_PORT"
    else
        echo -e "  执行器服务       :  ${RED}未运行${NC}"
    fi

    echo ""
    echo "=========================================="
}

# ── 查看执行器流程日志 ───────────────────────────────────
follow_executor_logs() {
    ensure_log_dir
    local log_file
    log_file="$(resolve_executor_log_file)"
    if [ -z "$log_file" ]; then
        warn "当前没有可查看的执行器日志"
        return 1
    fi
    touch "$log_file"
    tail -n 80 -f "$log_file" | awk '
        /GET \/api\/health/ { next }
        /GET \/api\/cloud-api\/status/ { next }
        { print }
    '
}

# ── 主流程 ───────────────────────────────────────────────
case "${1:-start}" in
    start)
        start_executor
        ;;
    stop)
        stop_all
        ;;
    restart)
        stop_all
        sleep 2
        exec "$0" start
        ;;
    restart-executor)
        info "重启执行器服务..."
        check_deps
        ensure_log_dir
        BACKEND_LOG="$(resolve_executor_log_file)"
        kill_port $BACKEND_PORT
        sleep 1
        install_python_deps
        start_backend
        status
        ;;
    logs)
        follow_executor_logs
        ;;
    status)
        status
        ;;
    *)
        echo "用法: $0 {start|stop|restart|restart-executor|logs|status}"
        echo ""
        echo "  start        启动执行器（默认），日志写入 logs/ 目录"
        echo "  stop         停止所有服务"
        echo "  restart      重启执行器（含 OpenCode）"
        echo "  restart-executor  只重启执行器服务（不动 OpenCode）"
        echo "  logs         查看执行器流程日志"
        echo "  status       查看服务状态"
        exit 1
        ;;
esac
