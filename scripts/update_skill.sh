#!/bin/bash
# ================================================================
# Skill 更新脚本
#
# Phase 1: harmony-code 构建
#   1. git pull origin main
#   2. npm install
#   3. npm run build
#
# Phase 2: hm-service-agent 同步 skills
#   1. git pull origin main（无新代码则停止）
#   2. 删除旧 skills → 复制新 skills
#
# 用法:
#   bash scripts/update_skill.sh
#
# ================================================================

set -e

HARMONY_CODE_DIR="/Users/bb/work/yutouGroup/code/harmony-code"
HM_SERVICE_AGENT_DIR="/Users/bb/work/yutouGroup/code/hm-service-agent"
SKILLS_TARGET_DIR="/Users/bb/work/benchmark/github/config/skills"
SKILLS_TO_SYNC="harmonyos-atomic-dev harmonyos-hvigor harmonyos-prd-design"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

step()  { echo -e "\n${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"; echo -e "${CYAN}  STEP: $1${NC}"; echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"; }
info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

FAILED=0

run_cmd() {
    local desc="$1"
    local cmd="$2"
    local start end elapsed

    info "$desc ..."
    start=$(date +%s)

    if eval "$cmd"; then
        end=$(date +%s)
        elapsed=$((end - start))
        info "$desc 完成 (${elapsed}s)"
    else
        end=$(date +%s)
        elapsed=$((end - start))
        error "$desc 失败 (${elapsed}s)"
        FAILED=1
        return 1
    fi
}

echo ""
echo "=========================================="
echo "  Skill 更新脚本"
echo "  执行时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo "=========================================="

# ═══════════════════════════════════════════════════════════
# Phase 1: harmony-code 构建
# ═══════════════════════════════════════════════════════════

echo ""
echo -e "${CYAN}▶ Phase 1: harmony-code 构建${NC}"

if [ ! -d "$HARMONY_CODE_DIR" ]; then
    error "目录不存在: $HARMONY_CODE_DIR"
    FAILED=1
else
    cd "$HARMONY_CODE_DIR"

    info "重置本地修改 ..."
    git reset --hard HEAD

    step "1/3  git pull origin main"
    run_cmd "harmony-code 拉取最新代码" "git pull origin main"

    step "2/3  npm install"
    run_cmd "harmony-code 安装依赖" "npm install"

    step "3/3  npm run build"
    run_cmd "harmony-code 构建项目" "npm run build"
fi

# ═══════════════════════════════════════════════════════════
# Phase 2: hm-service-agent 同步 skills
# ═══════════════════════════════════════════════════════════

echo ""
echo -e "${CYAN}▶ Phase 2: hm-service-agent 同步 skills${NC}"

if [ ! -d "$HM_SERVICE_AGENT_DIR" ]; then
    error "目录不存在: $HM_SERVICE_AGENT_DIR"
    FAILED=1
else
    cd "$HM_SERVICE_AGENT_DIR"

    info "重置本地修改 ..."
    git reset --hard HEAD

    step "4/5  git pull origin main"
    run_cmd "hm-service-agent 拉取最新代码" "git pull origin main"

    step "5/5  同步 skills"
    for skill in $SKILLS_TO_SYNC; do
        info "删除旧 skill: $skill"
        rm -rf "$SKILLS_TARGET_DIR/$skill"

        info "复制新 skill: $skill"
        cp -r "$HM_SERVICE_AGENT_DIR/skills/$skill" "$SKILLS_TARGET_DIR/$skill"
        info "同步完成: $skill"
    done
fi

# ── 结果汇总 ─────────────────────────────────────────────
echo ""
echo "=========================================="
if [ $FAILED -eq 0 ]; then
    echo -e "  结果: ${GREEN}全部成功${NC}"
else
    echo -e "  结果: ${RED}存在失败步骤，请检查上方输出${NC}"
fi
echo "  时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo "=========================================="
echo ""

exit $FAILED
