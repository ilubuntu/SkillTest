#!/bin/bash
# ================================================================
# Agent Bench 一键部署脚本（macOS）
#
# 用法:
#   ./deploy.sh              启动所有服务（默认），已运行的跳过
#   ./deploy.sh stop         停止所有服务
#   ./deploy.sh restart      重启所有服务（含 OpenCode）
#   ./deploy.sh restart-web  只重启 FastAPI + Vue（不动 OpenCode）
#   ./deploy.sh status       查看服务状态
#
# 服务列表:
#   - OpenCode Server   端口 4096   Agent 执行引擎
#   - FastAPI 后端      端口 8000   评测 API 服务
#   - Vue 前端          端口 5177   Web UI 界面
#
# 依赖:
#   - opencode  (https://opencode.ai)
#   - python3 + pip3
#   - node + npm
#
# 启动后浏览器打开: http://localhost:5177
# ================================================================

set -e

# ── 配置 ──────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OPENCODE_PORT=4096
BACKEND_PORT=8000
FRONTEND_PORT=5177

BACKEND_DIR="$SCRIPT_DIR/agent_bench/web_ui"
FRONTEND_DIR="$SCRIPT_DIR/agent_bench/web_ui/frontend"


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
    if ! command -v python3 &>/dev/null; then
        error "python3 未安装"
        missing=1
    fi
    if ! command -v node &>/dev/null; then
        error "node 未安装"
        missing=1
    fi
    if ! command -v npm &>/dev/null; then
        error "npm 未安装"
        missing=1
    fi

    if [ $missing -eq 1 ]; then
        error "缺少必要依赖，请先安装后重试"
        exit 1
    fi
    info "依赖检查通过"
}

# ── 清理已有进程 ──────────────────────────────────────────
kill_port() {
    local port=$1
    local pids=$(lsof -ti :$port 2>/dev/null)
    if [ -n "$pids" ]; then
        warn "端口 $port 已被占用，正在清理..."
        echo "$pids" | xargs kill -9 2>/dev/null || true
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

    opencode serve --port $OPENCODE_PORT &

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
    local req="$BACKEND_DIR/backend/requirements.txt"
    if [ -f "$req" ]; then
        pip3 install --break-system-packages -q -r "$req" 2>/dev/null || \
        pip3 install -q -r "$req" 2>/dev/null || \
        warn "Python 依赖安装失败，请手动安装: pip3 install -r $req"
    fi
}

# ── 启动 FastAPI 后端 ────────────────────────────────────
start_backend() {
    info "启动 FastAPI 后端 (端口 $BACKEND_PORT)..."

    if curl -s "http://localhost:$BACKEND_PORT/api/health" &>/dev/null; then
        info "FastAPI 后端已在运行，跳过启动"
        return
    fi

    kill_port $BACKEND_PORT

    cd "$BACKEND_DIR"
    python3 -m uvicorn backend.main:app --host 0.0.0.0 --port $BACKEND_PORT &

    # 等待启动
    for i in $(seq 1 10); do
        if curl -s "http://localhost:$BACKEND_PORT/api/health" &>/dev/null; then
            info "FastAPI 后端启动成功"
            return
        fi
        sleep 1
    done
    warn "FastAPI 后端可能未完全启动"
}

# ── 安装前端依赖 ─────────────────────────────────────────
install_frontend_deps() {
    if [ ! -d "$FRONTEND_DIR/node_modules" ]; then
        info "安装前端依赖..."
        cd "$FRONTEND_DIR"
        npm install --silent 2>/dev/null || warn "前端依赖安装失败，请手动执行: cd $FRONTEND_DIR && npm install"
    fi
}

# ── 启动 Vue 前端 ────────────────────────────────────────
start_frontend() {
    info "启动 Vue 前端 (端口 $FRONTEND_PORT)..."

    if lsof -ti :$FRONTEND_PORT &>/dev/null; then
        info "Vue 前端已在运行，跳过启动"
        return
    fi

    cd "$FRONTEND_DIR"
    npm run dev &

    # 等待启动
    for i in $(seq 1 10); do
        if curl -s "http://localhost:$FRONTEND_PORT" &>/dev/null; then
            info "Vue 前端启动成功"
            return
        fi
        sleep 1
    done
    warn "Vue 前端可能未完全启动"
}

# ── 停止所有服务 ─────────────────────────────────────────
stop_all() {
    info "停止所有服务..."
    kill_port $OPENCODE_PORT
    kill_port $BACKEND_PORT
    kill_port $FRONTEND_PORT
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

    # Backend
    if curl -s "http://localhost:$BACKEND_PORT/api/health" &>/dev/null; then
        echo -e "  FastAPI 后端     :  ${GREEN}运行中${NC}  http://localhost:$BACKEND_PORT"
    else
        echo -e "  FastAPI 后端     :  ${RED}未运行${NC}"
    fi

    # Frontend
    if lsof -ti :$FRONTEND_PORT &>/dev/null; then
        echo -e "  Vue 前端         :  ${GREEN}运行中${NC}  http://localhost:$FRONTEND_PORT"
    else
        echo -e "  Vue 前端         :  ${RED}未运行${NC}"
    fi

    echo ""
    echo "=========================================="
}

# ── 主流程 ───────────────────────────────────────────────
case "${1:-start}" in
    start)
        echo ""
        echo "=========================================="
        echo "  Agent Bench 一键部署"
        echo "=========================================="
        echo ""
        check_deps
        start_opencode
        install_python_deps
        start_backend
        install_frontend_deps
        start_frontend
        status
        echo ""
        info "部署完成! 浏览器打开: http://localhost:$FRONTEND_PORT"
        echo ""
        # 保持前台运行，Ctrl+C 退出时自动清理
        info "按 Ctrl+C 停止所有服务"
        trap stop_all EXIT INT TERM
        wait
        ;;
    stop)
        stop_all
        ;;
    restart)
        stop_all
        sleep 2
        exec "$0" start
        ;;
    restart-web)
        info "重启 Web 服务（FastAPI + Vue）..."
        kill_port $BACKEND_PORT
        kill_port $FRONTEND_PORT
        sleep 1
        install_python_deps
        start_backend
        install_frontend_deps
        start_frontend
        status
        ;;
    status)
        status
        ;;
    *)
        echo "用法: $0 {start|stop|restart|restart-web|status}"
        echo ""
        echo "  start        启动所有服务（默认），日志直接输出到控制台，Ctrl+C 停止"
        echo "  stop         停止所有服务"
        echo "  restart      重启所有服务（含 OpenCode）"
        echo "  restart-web  只重启 FastAPI 后端 + Vue 前端（不动 OpenCode）"
        echo "  status       查看服务状态"
        exit 1
        ;;
esac
