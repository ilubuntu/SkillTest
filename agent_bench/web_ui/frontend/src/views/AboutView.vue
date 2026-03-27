<template>
  <div class="about-page">

    <!-- Hero -->
    <div class="hero-section">
      <div class="hero-badge">v1.0 · HarmonyOS ArkTS</div>
      <h1 class="hero-title">Agent Bench</h1>
      <p class="hero-subtitle">鸿蒙开发工具评测系统 — 量化 AI Agent 增强配置的真实增益</p>
    </div>

    <!-- 背景 + 定位 -->
    <div class="section-row">
      <el-card class="info-card" shadow="never">
        <template #header>
          <div class="card-header">
            <el-icon class="card-icon bg-blue"><Promotion /></el-icon>
            <span>项目背景</span>
          </div>
        </template>
        <p class="card-text">
          团队正在为鸿蒙（HarmonyOS）ArkTS 开发编写一系列<strong>增强配置</strong>（Skill、MCP Tool、System Prompt 等），
          用于挂载到 AI 编程 Agent（如 OpenCode）上，提升 Agent 的鸿蒙 ArkTS 编程能力。
        </p>
        <div class="question-box">
          <el-icon><QuestionFilled /></el-icon>
          <span>核心问题：如何<strong>客观量化</strong>这些增强配置的增益价值？</span>
        </div>
        <div class="answer-box">
          <el-icon><CircleCheckFilled /></el-icon>
          <span>解决方案：构建 <strong>Agent Bench</strong>，通过标准化测试用例，对比 Agent 加载增强配置前后的代码输出质量，生成增益报告。</span>
        </div>
      </el-card>

      <el-card class="info-card" shadow="never">
        <template #header>
          <div class="card-header">
            <el-icon class="card-icon bg-purple"><Aim /></el-icon>
            <span>系统定位</span>
          </div>
        </template>
        <ul class="position-list">
          <li>
            <el-tag type="primary" size="small">双入口</el-tag>
            <span>Web 可视化界面 + CLI 命令行，两种模式共享同一套 Pipeline Engine</span>
          </li>
          <li>
            <el-tag type="success" size="small">评测对象</el-tag>
            <span>Agent 内部工具（Skill / MCP Tool / System Prompt 及其组合），<strong>不是 Agent 本身</strong></span>
          </li>
          <li>
            <el-tag type="warning" size="small">Agent 无关</el-tag>
            <span>通过抽象的 AgentAdapter 接口与 Agent 交互，不与任何特定 Agent 强绑定</span>
          </li>
          <li>
            <el-tag type="info" size="small">黑盒执行</el-tag>
            <span>Agent 被视为黑盒引擎：配置增强工具、发任务、收结果，不介入内部执行</span>
          </li>
          <li>
            <el-tag size="small">首版参考</el-tag>
            <span>以 OpenCode 为参考实现，所有设计面向 Agent 无关的抽象层，后续可接入 Cursor、Claude Code 等</span>
          </li>
        </ul>
      </el-card>
    </div>

    <!-- 总体架构 -->
    <el-card class="arch-card" shadow="never">
      <template #header>
        <div class="card-header">
          <el-icon class="card-icon bg-teal"><Connection /></el-icon>
          <span>总体架构</span>
          <span class="arch-subtitle">前后端分离 + 三阶段流水线，阶段内并行、阶段间串行</span>
        </div>
      </template>

      <div class="arch-diagram">
        <!-- 第一层：Web UI -->
        <div class="arch-layer layer-webui">
          <div class="layer-label">Web UI</div>
          <div class="layer-modules">
            <div class="arch-module mod-blue">
              <el-icon><Document /></el-icon>
              <span>用例管理</span>
            </div>
            <div class="arch-module mod-blue">
              <el-icon><Setting /></el-icon>
              <span>Profile 配置</span>
            </div>
            <div class="arch-module mod-blue">
              <el-icon><Aim /></el-icon>
              <span>评分标准</span>
            </div>
            <div class="arch-module mod-blue">
              <el-icon><VideoPlay /></el-icon>
              <span>评测中心</span>
            </div>
            <div class="arch-module mod-blue">
              <el-icon><DataAnalysis /></el-icon>
              <span>报告展示</span>
            </div>
          </div>
        </div>

        <div class="arch-connector">
          <div class="conn-line"></div>
          <div class="conn-label">REST API + SSE</div>
          <div class="conn-arrow">↓</div>
        </div>

        <!-- 第二层：Backend -->
        <div class="arch-layer layer-backend">
          <div class="layer-label">Backend (FastAPI)</div>
          <div class="layer-content backend-content">
            <div class="backend-api">
              <div class="api-label">API Layer</div>
              <div class="api-items">
                <span>用例</span><span>Profile</span><span>评分标准</span><span>评测控制</span><span>报告查询</span>
              </div>
            </div>
            <div class="backend-pipeline">
              <div class="pipeline-label">Pipeline Engine（异步任务引擎）</div>
              <div class="pipeline-stages">
                <div class="pipe-stage">
                  <div class="stage-icon">▶</div>
                  <div class="stage-name">Runner</div>
                  <div class="stage-desc">并行跑用例</div>
                </div>
                <div class="pipe-arrow">→</div>
                <div class="pipe-stage">
                  <div class="stage-icon">⚖</div>
                  <div class="stage-name">Evaluator</div>
                  <div class="stage-desc">规则 + LLM 评分</div>
                </div>
                <div class="pipe-arrow">→</div>
                <div class="pipe-stage">
                  <div class="stage-icon">📊</div>
                  <div class="stage-name">Reporter</div>
                  <div class="stage-desc">汇总增益报告</div>
                </div>
              </div>
            </div>
            <div class="backend-storage">
              <div class="storage-label">Storage Layer</div>
              <div class="storage-items">
                <div class="storage-item">
                  <span class="si-icon">📁</span>
                  <span>profiles/ — Profile 配置 (YAML)</span>
                </div>
                <div class="storage-item">
                  <span class="si-icon">📁</span>
                  <span>test_cases/ — 测试用例 (YAML + 代码)</span>
                </div>
                <div class="storage-item">
                  <span class="si-icon">📁</span>
                  <span>results/ — 评测结果 (JSON / Markdown)</span>
                </div>
                <div class="storage-item">
                  <span class="si-icon">🗂</span>
                  <span>sandbox/{run_id}/{case_id}/ — 沙箱隔离目录</span>
                </div>
              </div>
            </div>
          </div>
        </div>

        <div class="arch-connector">
          <div class="conn-line"></div>
          <div class="conn-label">AgentAdapter（抽象接口，Agent 无关）</div>
          <div class="conn-arrow">↓</div>
        </div>

        <!-- 第三层：Agent -->
        <div class="arch-layer layer-agent">
          <div class="layer-label">Agent 层（可替换）</div>
          <div class="agent-row">
            <div class="agent-item active">
              <span class="agent-badge">当前</span>
              OpenCode
            </div>
            <div class="agent-item future">Cursor</div>
            <div class="agent-item future">Claude Code</div>
            <div class="agent-item future">其他 Agent …</div>
          </div>
          <div class="agent-flow">
            <span class="af-step">setup(enhancements)</span>
            <span class="af-arrow">→</span>
            <span class="af-step">execute(prompt)</span>
            <span class="af-arrow">→</span>
            <span class="af-step">teardown()</span>
          </div>
        </div>

        <div class="arch-connector">
          <div class="conn-line"></div>
          <div class="conn-label">双向通信</div>
          <div class="conn-arrow">↓</div>
        </div>

        <!-- 第四层：LLM -->
        <div class="arch-layer layer-llm">
          <div class="layer-label">LLM API 层</div>
          <div class="llm-caps">
            <span>推理</span>
            <span>·</span>
            <span>生成代码</span>
            <span>·</span>
            <span>工具决策</span>
          </div>
        </div>
      </div>
    </el-card>

    <!-- 设计原则 + 测试场景 -->
    <div class="section-row bottom-row">
      <el-card class="principles-card" shadow="never">
        <template #header>
          <div class="card-header">
            <el-icon class="card-icon bg-orange"><Star /></el-icon>
            <span>核心设计原则</span>
          </div>
        </template>
        <div class="principles-grid">
          <div class="principle-item" v-for="p in principles" :key="p.title">
            <div class="principle-num">{{ p.num }}</div>
            <div class="principle-body">
              <div class="principle-title">{{ p.title }}</div>
              <div class="principle-desc">{{ p.desc }}</div>
            </div>
          </div>
        </div>
      </el-card>

      <el-card class="scenarios-card" shadow="never">
        <template #header>
          <div class="card-header">
            <el-icon class="card-icon bg-green"><Grid /></el-icon>
            <span>测试场景体系</span>
          </div>
        </template>
        <div class="scenario-list">
          <div class="scenario-item" v-for="s in testScenarios" :key="s.name">
            <span class="scenario-dot" :style="{ background: s.color }"></span>
            <div class="scenario-info">
              <span class="scenario-name">{{ s.name }}</span>
              <span class="scenario-desc">{{ s.desc }}</span>
            </div>
          </div>
        </div>
        <div class="scenario-note">
          <el-icon><InfoFilled /></el-icon>
          <span>每个 Profile 按能力归属到一个或多个场景，基线 vs 增强对比产生增益分数</span>
        </div>
      </el-card>
    </div>

  </div>
</template>

<script setup>
import {
  Promotion, QuestionFilled, CircleCheckFilled, Aim, Connection,
  Document, Setting, VideoPlay, DataAnalysis, Star, Grid, InfoFilled
} from '@element-plus/icons-vue'

const principles = [
  { num: '01', title: '前后端分离', desc: 'Web UI 和 CLI 共享同一套 Pipeline Engine，两种入口能力对等' },
  { num: '02', title: 'Agent 黑盒', desc: '评测系统不介入 Agent 内部执行，只管输入/输出' },
  { num: '03', title: '配置驱动', desc: '通过 Profile 定义增强工具组合，Runner 通过 AgentAdapter.setup() 注入配置' },
  { num: '04', title: '阶段解耦', desc: 'Runner / Evaluator / Reporter 三阶段可独立运行，失败后可单独重跑' },
  { num: '05', title: '结果持久化', desc: '每一步中间结果落盘，支持断点续跑，结果不依赖内存状态' },
  { num: '06', title: 'Judge 独立', desc: 'LLM 评分可使用独立模型，与被测 Agent 的 LLM 分离，保证评分客观' },
]

const testScenarios = [
  { name: '工程生成', desc: '从零生成项目/模块骨架，如 ArkTS List 页面工程', color: '#667eea' },
  { name: '需求开发', desc: '根据需求描述实现功能代码，如下拉刷新列表', color: '#43c6ac' },
  { name: 'Bug 修复', desc: '修复已有代码中的缺陷，如滑动崩溃、@State 误用', color: '#f093fb' },
  { name: '代码重构', desc: '不改功能，优化代码结构，如提取公共组件', color: '#4facfe' },
  { name: '性能优化', desc: '不改功能，提升运行性能，如 ForEach→LazyForEach', color: '#ffd89b' },
  { name: '多模态', desc: '基于图片/设计稿生成代码，UI 图转 ArkTS 组件', color: '#a18cd1' },
  { name: 'UT 生成', desc: '为已有代码生成单元测试，覆盖边界场景', color: '#84fab0' },
]
</script>

<style scoped>
.about-page {
  max-width: 1200px;
  margin: 0 auto;
  display: flex;
  flex-direction: column;
  gap: 20px;
}

/* Hero */
.hero-section {
  background: linear-gradient(135deg, #1a1a2e 0%, #16213e 50%, #0f3460 100%);
  border-radius: 12px;
  padding: 40px 48px;
  text-align: center;
  color: #fff;
}
.hero-badge {
  display: inline-block;
  background: rgba(102, 126, 234, 0.4);
  border: 1px solid rgba(102, 126, 234, 0.6);
  border-radius: 20px;
  padding: 4px 14px;
  font-size: 12px;
  color: #a5b4fc;
  margin-bottom: 16px;
  letter-spacing: 1px;
}
.hero-title {
  font-size: 40px;
  font-weight: 700;
  margin: 0 0 12px;
  background: linear-gradient(135deg, #667eea, #a5b4fc);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
}
.hero-subtitle {
  font-size: 15px;
  color: rgba(255, 255, 255, 0.65);
  margin: 0;
  line-height: 1.6;
}

/* Layout */
.section-row {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 20px;
}
.bottom-row {
  grid-template-columns: 1fr 1fr;
}

/* Cards */
.info-card, .arch-card, .principles-card, .scenarios-card {
  border: 1px solid #ebeef5;
  border-radius: 10px;
}
.card-header {
  display: flex;
  align-items: center;
  gap: 10px;
  font-size: 15px;
  font-weight: 600;
  color: #1a1a2e;
}
.card-icon {
  width: 30px;
  height: 30px;
  border-radius: 8px;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #fff;
  font-size: 15px;
  flex-shrink: 0;
}
.bg-blue   { background: linear-gradient(135deg, #4facfe, #00f2fe); }
.bg-purple { background: linear-gradient(135deg, #667eea, #764ba2); }
.bg-teal   { background: linear-gradient(135deg, #43c6ac, #191654); }
.bg-orange { background: linear-gradient(135deg, #f093fb, #f5576c); }
.bg-green  { background: linear-gradient(135deg, #43e97b, #38f9d7); }

.arch-subtitle {
  font-size: 12px;
  color: #999;
  font-weight: 400;
  margin-left: 4px;
}

/* Background card */
.card-text {
  color: #555;
  line-height: 1.7;
  margin-bottom: 16px;
}
.question-box, .answer-box {
  display: flex;
  align-items: flex-start;
  gap: 8px;
  padding: 10px 14px;
  border-radius: 8px;
  font-size: 13px;
  line-height: 1.6;
  margin-bottom: 8px;
}
.question-box {
  background: #fff7e6;
  color: #b45309;
  border: 1px solid #fde68a;
}
.answer-box {
  background: #f0fdf4;
  color: #166534;
  border: 1px solid #bbf7d0;
}

/* Positioning card */
.position-list {
  list-style: none;
  padding: 0;
  margin: 0;
  display: flex;
  flex-direction: column;
  gap: 12px;
}
.position-list li {
  display: flex;
  align-items: flex-start;
  gap: 10px;
  font-size: 13px;
  color: #555;
  line-height: 1.5;
}
.position-list .el-tag {
  flex-shrink: 0;
  margin-top: 1px;
}

/* Architecture diagram */
.arch-diagram {
  display: flex;
  flex-direction: column;
  align-items: stretch;
  gap: 0;
}
.arch-layer {
  border-radius: 10px;
  padding: 16px 20px;
  position: relative;
}
.layer-label {
  font-size: 11px;
  font-weight: 600;
  letter-spacing: 1px;
  text-transform: uppercase;
  margin-bottom: 12px;
  opacity: 0.7;
}
.layer-webui {
  background: linear-gradient(135deg, #e0e7ff 0%, #f0f4ff 100%);
  border: 1px solid #c7d2fe;
}
.layer-webui .layer-label { color: #4338ca; }
.layer-modules {
  display: flex;
  gap: 10px;
  flex-wrap: wrap;
}
.arch-module {
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 6px 14px;
  border-radius: 20px;
  font-size: 13px;
  font-weight: 500;
}
.mod-blue {
  background: #fff;
  color: #4338ca;
  border: 1px solid #c7d2fe;
}

.arch-connector {
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 6px 0;
  gap: 2px;
}
.conn-line {
  width: 2px;
  height: 8px;
  background: #c9d0e8;
}
.conn-label {
  font-size: 11px;
  color: #888;
  background: #f8f9fb;
  border: 1px solid #e0e4f0;
  border-radius: 10px;
  padding: 2px 10px;
}
.conn-arrow {
  font-size: 14px;
  color: #aab;
  line-height: 1;
}

.layer-backend {
  background: linear-gradient(135deg, #f0fdf4 0%, #f8fff9 100%);
  border: 1px solid #bbf7d0;
}
.layer-backend .layer-label { color: #166534; }
.backend-content {
  display: flex;
  flex-direction: column;
  gap: 12px;
}
.backend-api {
  background: rgba(255,255,255,0.7);
  border: 1px solid #d1fae5;
  border-radius: 8px;
  padding: 10px 14px;
}
.api-label {
  font-size: 11px;
  font-weight: 600;
  color: #059669;
  margin-bottom: 8px;
}
.api-items {
  display: flex;
  gap: 8px;
  flex-wrap: wrap;
}
.api-items span {
  background: #ecfdf5;
  border: 1px solid #a7f3d0;
  border-radius: 12px;
  padding: 2px 10px;
  font-size: 12px;
  color: #065f46;
}
.backend-pipeline {
  background: rgba(255,255,255,0.7);
  border: 1px solid #d1fae5;
  border-radius: 8px;
  padding: 10px 14px;
}
.pipeline-label {
  font-size: 11px;
  font-weight: 600;
  color: #059669;
  margin-bottom: 10px;
}
.pipeline-stages {
  display: flex;
  align-items: center;
  gap: 12px;
}
.pipe-stage {
  flex: 1;
  text-align: center;
  background: #fff;
  border: 1px solid #a7f3d0;
  border-radius: 8px;
  padding: 10px 8px;
}
.stage-icon {
  font-size: 18px;
  margin-bottom: 4px;
}
.stage-name {
  font-size: 13px;
  font-weight: 600;
  color: #065f46;
}
.stage-desc {
  font-size: 11px;
  color: #6b7280;
  margin-top: 2px;
}
.pipe-arrow {
  font-size: 18px;
  color: #34d399;
  flex-shrink: 0;
}
.backend-storage {
  background: rgba(255,255,255,0.7);
  border: 1px solid #d1fae5;
  border-radius: 8px;
  padding: 10px 14px;
}
.storage-label {
  font-size: 11px;
  font-weight: 600;
  color: #059669;
  margin-bottom: 8px;
}
.storage-items {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 6px;
}
.storage-item {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 12px;
  color: #374151;
}
.si-icon { font-size: 14px; }

.layer-agent {
  background: linear-gradient(135deg, #fffbeb 0%, #fffdf5 100%);
  border: 1px solid #fde68a;
}
.layer-agent .layer-label { color: #92400e; }
.agent-row {
  display: flex;
  gap: 10px;
  margin-bottom: 12px;
  flex-wrap: wrap;
}
.agent-item {
  padding: 6px 16px;
  border-radius: 20px;
  font-size: 13px;
  font-weight: 500;
  position: relative;
}
.agent-item.active {
  background: #fef3c7;
  border: 1.5px solid #f59e0b;
  color: #92400e;
}
.agent-item.future {
  background: #fff;
  border: 1px dashed #fcd34d;
  color: #b45309;
}
.agent-badge {
  position: absolute;
  top: -8px;
  left: 50%;
  transform: translateX(-50%);
  background: #f59e0b;
  color: #fff;
  font-size: 10px;
  padding: 1px 6px;
  border-radius: 8px;
  white-space: nowrap;
}
.agent-flow {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 12px;
}
.af-step {
  background: #fff;
  border: 1px solid #fde68a;
  border-radius: 6px;
  padding: 4px 10px;
  color: #92400e;
  font-family: monospace;
}
.af-arrow { color: #f59e0b; font-size: 14px; }

.layer-llm {
  background: linear-gradient(135deg, #fdf2f8 0%, #fff 100%);
  border: 1px solid #f0abfc;
}
.layer-llm .layer-label { color: #7e22ce; }
.llm-caps {
  display: flex;
  align-items: center;
  gap: 12px;
  font-size: 14px;
  color: #7e22ce;
  font-weight: 500;
}

/* Principles */
.principles-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 12px;
}
.principle-item {
  display: flex;
  gap: 12px;
  padding: 12px;
  background: #f8f9ff;
  border-radius: 8px;
  border: 1px solid #e8ecff;
}
.principle-num {
  font-size: 20px;
  font-weight: 800;
  color: #e0e4ff;
  line-height: 1;
  flex-shrink: 0;
  width: 28px;
}
.principle-title {
  font-size: 13px;
  font-weight: 600;
  color: #1a1a2e;
  margin-bottom: 4px;
}
.principle-desc {
  font-size: 12px;
  color: #6b7280;
  line-height: 1.5;
}

/* Scenarios */
.scenario-list {
  display: flex;
  flex-direction: column;
  gap: 10px;
  margin-bottom: 14px;
}
.scenario-item {
  display: flex;
  align-items: flex-start;
  gap: 10px;
}
.scenario-dot {
  width: 10px;
  height: 10px;
  border-radius: 50%;
  flex-shrink: 0;
  margin-top: 4px;
}
.scenario-info {
  display: flex;
  flex-direction: column;
  gap: 2px;
}
.scenario-name {
  font-size: 13px;
  font-weight: 600;
  color: #1a1a2e;
}
.scenario-desc {
  font-size: 12px;
  color: #6b7280;
  line-height: 1.4;
}
.scenario-note {
  display: flex;
  align-items: flex-start;
  gap: 6px;
  padding: 8px 12px;
  background: #f0f4ff;
  border-radius: 8px;
  font-size: 12px;
  color: #4338ca;
  line-height: 1.5;
}
</style>
