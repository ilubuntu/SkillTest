<template>
  <div class="page-container">
    <div class="card control-shell">
      <div class="control-hero">
        <div class="hero-copy">
          <div class="hero-kicker">Agent Compare Lab</div>
          <h2 class="hero-title">Agent 对比评测</h2>
          <div class="hero-meta">
            <span class="hero-pill">{{ runTargetSummary }}</span>
            <span class="hero-meta-text">{{ selectionSummary }}</span>
          </div>
        </div>
        <div class="control-actions">
          <el-button
            :type="isRunning ? 'danger' : 'primary'"
            size="large"
            class="launch-button"
            :disabled="isRunning ? false : !canStart"
            @click="isRunning ? stopEvaluation() : startEvaluation()"
            :icon="isRunning ? VideoPause : VideoPlay"
          >
            {{ isRunning ? '停止评测' : '启动评测' }}
          </el-button>
        </div>
      </div>

      <div class="control-grid">
        <div class="control-panel">
          <div class="panel-heading">
            <span class="panel-kicker">运行目标</span>
            <span class="panel-note">决定执行单侧验证还是双侧对照</span>
          </div>
          <div class="target-group" :class="{ disabled: isRunning }">
            <button
              type="button"
              class="target-chip"
              :class="{ active: runTarget === 'both' }"
              :disabled="isRunning"
              @click="runTarget = 'both'"
            >
              同时运行
            </button>
            <button
              type="button"
              class="target-chip"
              :class="{ active: runTarget === 'agent_a' }"
              :disabled="isRunning"
              @click="runTarget = 'agent_a'"
            >
              仅 Agent A
            </button>
            <button
              type="button"
              class="target-chip"
              :class="{ active: runTarget === 'agent_b' }"
              :disabled="isRunning"
              @click="runTarget = 'agent_b'"
            >
              仅 Agent B
            </button>
          </div>
        </div>

        <div class="control-panel control-panel-wide">
          <div class="panel-heading">
            <span class="panel-kicker">场景 / 用例</span>
            <span class="panel-note">{{ selectionSummary }}</span>
          </div>
          <el-cascader
            :model-value="selectedOptions"
            :options="cascaderOptions"
            :props="{ checkStrictly: false, emitPath: true, multiple: true }"
            placeholder="选择评测场景和用例"
            class="control-cascader"
            :disabled="isRunning"
            @update:model-value="handleCascaderChange"
            collapse-tags
            collapse-tags-tooltip
            :max-collapse-tags="2"
          />
        </div>

        <div class="agent-panel agent-panel-a" :class="{ muted: runTarget === 'agent_b' }">
          <div class="panel-heading">
            <span class="panel-kicker">Agent A</span>
            <span class="panel-note">
              {{ runTarget === 'agent_b' ? '当前模式下不执行' : (selectedAgentALabel || '左侧执行体') }}
            </span>
          </div>
          <el-select
            v-model="selectedAgentA"
            placeholder="选择 Agent A"
            class="control-select"
            :disabled="isRunning || runTarget === 'agent_b'"
            filterable
          >
            <el-option
              v-for="agent in agentsData"
              :key="agent.id"
              :label="agent.name"
              :value="agent.id"
            />
          </el-select>
        </div>

        <div class="agent-panel agent-panel-b" :class="{ muted: runTarget === 'agent_a' }">
          <div class="panel-heading">
            <span class="panel-kicker">Agent B</span>
            <span class="panel-note">
              {{ runTarget === 'agent_a' ? '当前模式下不执行' : (selectedAgentBLabel || '右侧执行体') }}
            </span>
          </div>
          <el-select
            v-model="selectedAgentB"
            placeholder="选择 Agent B"
            class="control-select"
            :disabled="isRunning || runTarget === 'agent_a'"
            filterable
          >
            <el-option
              v-for="agent in agentsData"
              :key="`b-${agent.id}`"
              :label="agent.name"
              :value="agent.id"
            />
          </el-select>
        </div>
      </div>
    </div>

    <!-- 状态概览 -->
    <div class="stats-row">
      <!-- 评测状态 — 视觉化 -->
      <div class="stat-card status-card" :class="statusClass">
        <div class="status-badge">
          <span class="status-ring" v-if="isRunning"></span>
          <el-icon :size="20" class="status-icon-inner">
            <Loading v-if="isRunning" class="spinning" />
            <CircleCheck v-else-if="status === 'completed'" />
            <WarningFilled v-else-if="status === 'stopped'" />
            <CircleClose v-else-if="status === 'error'" />
            <Clock v-else />
          </el-icon>
        </div>
        <div class="stat-info">
          <div class="stat-value status-text" :class="statusClass">{{ statusText }}</div>
          <div class="stat-label">评测状态</div>
        </div>
      </div>

      <!-- 用例进度 — 用进度环 -->
      <div class="stat-card">
        <div class="progress-ring-wrap">
          <svg class="progress-ring" viewBox="0 0 40 40">
            <circle class="ring-bg" cx="20" cy="20" r="16" />
            <circle
              class="ring-fill"
              cx="20" cy="20" r="16"
              :stroke-dasharray="`${ringProgress} 100`"
            />
          </svg>
          <span class="ring-text">{{ doneCases }}</span>
        </div>
        <div class="stat-info">
          <div class="stat-value">{{ doneCases }} / {{ displayTotal }}</div>
          <div class="stat-label">已完成 / 总用例</div>
        </div>
      </div>

      <!-- 运行时间 -->
      <div class="stat-card">
        <div class="stat-icon-area purple">
          <el-icon :size="22"><Timer /></el-icon>
        </div>
        <div class="stat-info">
          <div class="stat-value">{{ elapsedTime }}</div>
          <div class="stat-label">运行时间</div>
        </div>
      </div>

      <div class="stat-card" v-if="selectedAgentALabel">
        <div class="stat-icon-area orange">
          <el-icon :size="22"><Setting /></el-icon>
        </div>
        <div class="stat-info">
          <div class="stat-value profile-name">{{ selectedAgentALabel }}</div>
          <div class="stat-label">Agent A</div>
        </div>
      </div>

      <div class="stat-card" v-if="showEnhancedSide && selectedAgentBLabel">
        <div class="stat-icon-area orange">
          <el-icon :size="22"><Setting /></el-icon>
        </div>
        <div class="stat-info">
          <div class="stat-value profile-name">{{ selectedAgentBLabel }}</div>
          <div class="stat-label">Agent B</div>
        </div>
      </div>
    </div>

    <!-- Case 进度面板 -->
    <div class="card" v-if="caseProgresses.length > 0 || isRunning">
      <div class="card-header">
        <span class="card-title-sm">用例进度</span>
        <span class="case-counter">{{ doneCases }} / {{ displayTotal }} 完成</span>
      </div>
      <div class="case-list">
        <div
          v-for="cp in caseProgresses"
          :key="cp.case_id"
          class="case-row"
          :class="cp.status"
        >
          <!-- Case 基本信息 -->
          <div class="case-info">
            <div class="case-id-row">
              <span class="case-status-dot" :class="cp.status"></span>
              <span class="case-id">{{ cp.case_id }}</span>
              <el-tag v-if="cp.scenario" size="small" type="info" class="scenario-tag">{{ cp.scenario }}</el-tag>
            </div>
            <div class="case-title">{{ cp.title }}</div>
          </div>

          <!-- 阶段流水线 -->
          <div class="stage-pipeline">
            <template v-for="(stage, idx) in visibleStages(cp.stages)" :key="stage.name">
              <div class="stage-item" :class="[stage.status, { clickable: stage.status === 'done' && runId }]"
                   @click="stage.status === 'done' && runId ? openStageFiles(cp.case_id, stage.name) : null">
                <div class="stage-dot" :class="stage.status">
                  <el-icon v-if="stage.status === 'done'" :size="10"><Check /></el-icon>
                  <el-icon v-else-if="stage.status === 'running'" :size="10" class="spinning"><Loading /></el-icon>
                  <el-icon v-else-if="stage.status === 'skipped'" :size="10"><Minus /></el-icon>
                  <el-icon v-else-if="stage.status === 'error'" :size="10"><Close /></el-icon>
                  <span v-else class="stage-number">{{ idx + 1 }}</span>
                </div>
                <div class="stage-label">{{ displayStageLabel(stage.name) }}</div>
                <div class="stage-time" v-if="stage.elapsed != null">{{ stage.elapsed }}s</div>
              </div>
              <div class="stage-connector" v-if="idx < visibleStages(cp.stages).length - 1" :class="stage.status === 'done' ? 'done' : ''"></div>
            </template>
          </div>

          <!-- Case 结果 -->
          <div class="case-result" v-if="cp.status === 'done'">
            <div class="result-col">
              <span class="result-label">{{ effectiveComparisonLabels.side_a }}</span>
              <span class="result-value">{{ fmtScore(cp.side_a_total) }}</span>
            </div>
            <div class="result-col" v-if="showEnhancedSide && cp.side_b_total != null">
              <span class="result-label">{{ effectiveComparisonLabels.side_b }}</span>
              <span class="result-value enhanced">{{ fmtScore(cp.side_b_total) }}</span>
            </div>
            <div class="result-col" v-if="showEnhancedSide && cp.gain != null">
              <span class="result-label">差值</span>
              <span class="result-value" :class="cp.gain >= 0 ? 'positive' : 'negative'">
                {{ cp.gain >= 0 ? '+' : '' }}{{ fmtScore(cp.gain) }}
              </span>
            </div>
          </div>
          <div class="case-result" v-else-if="cp.status === 'error'">
            <span class="error-text">{{ cp.error || '执行失败' }}</span>
          </div>
          <div class="case-result running-hint" v-else-if="cp.status === 'running'">
            <span class="running-dot"></span><span class="running-dot"></span><span class="running-dot"></span>
          </div>
        </div>

        <div v-if="isRunning && caseProgresses.length === 0" class="case-row pending">
          <div class="case-title" style="color: #999; font-size: 13px;">等待用例加载...</div>
        </div>
      </div>
    </div>

    <!-- 通用用例结果 -->
    <div class="card" v-if="generalResult">
      <div class="card-title">通用用例评测结果</div>
      <div class="compile-summary-card" v-if="generalResult.general">
        <div class="compile-summary-title">编译通过率</div>
        <div class="compile-summary-grid">
          <div class="compile-item">
            <div class="compile-label">{{ generalComparisonLabels.side_a }}</div>
            <div class="compile-value">{{ generalResult.general.side_a_compile_pass_rate }}</div>
          </div>
          <div class="compile-item" v-if="showEnhancedSide">
            <div class="compile-label">{{ generalComparisonLabels.side_b }}</div>
            <div class="compile-value">{{ generalResult.general.side_b_compile_pass_rate }}</div>
          </div>
        </div>
        <div class="compile-note" v-if="generalResult.general.note">
          {{ generalResult.general.note }}
        </div>
      </div>
      <div class="case-list" v-if="generalResult.cases?.length > 0">
        <div class="case-row done" v-for="c in generalResult.cases" :key="c.case_id">
          <div class="case-info">
            <div class="case-id-row">
              <span class="case-status-dot done"></span>
              <span class="case-id">{{ c.case_id }}</span>
            </div>
            <div class="case-title">{{ c.title }}</div>
          </div>
          <div class="case-result">
            <div class="compile-status" :class="c.compile_results?.side_a_compilable ? 'pass' : 'fail'">
              {{ generalComparisonLabels.side_a }}: {{ c.compile_results?.side_a_compilable ? '可编译' : '不可编译' }}
            </div>
            <div v-if="showEnhancedSide" class="compile-status" :class="c.compile_results?.side_b_compilable ? 'pass' : 'fail'">
              {{ generalComparisonLabels.side_b }}: {{ c.compile_results?.side_b_compilable ? '可编译' : '不可编译' }}
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- 评测结果 -->
    <ResultCard
      v-if="result || results.length > 0"
      :result="result"
      :results="results"
      :active-result-tab="activeResultTab"
      :comparison-labels="effectiveComparisonLabels"
      :active-sides="activeSides"
      @update:active-result-tab="val => activeResultTab = val"
    />

    <!-- 日志面板 -->
    <div class="card">
      <div class="log-header">
        <span class="card-title-sm">运行日志</span>
        <div class="log-controls">
          <el-radio-group v-model="logLevel" size="small">
            <el-radio-button value="ALL">全部</el-radio-button>
            <el-radio-button value="INFO">INFO</el-radio-button>
            <el-radio-button value="DEBUG">DEBUG</el-radio-button>
            <el-radio-button value="ERROR">ERROR</el-radio-button>
          </el-radio-group>
          <span class="log-count">{{ filteredLogs.length }} / {{ logs.length }}</span>
          <el-button size="small" circle @click="showFullscreen = true">
            <el-icon><FullScreen /></el-icon>
          </el-button>
        </div>
      </div>
      <div class="log-container" ref="logContainerRef" @scroll="onLogScroll">
        <div v-if="logs.length === 0" class="log-empty">
          {{ status === 'idle' ? '选择场景后点击"启动评测"' : '等待日志输出...' }}
        </div>
        <div v-for="(log, idx) in filteredLogs" :key="idx" class="log-entry">
          <span class="log-time">{{ log.timestamp }}</span>
          <span class="log-level" :class="log.level">{{ log.level }}</span>
          <div class="log-content">
            <span class="log-message">{{ [log.message, log.detail].filter(Boolean).join('\n') }}</span>
          </div>
        </div>
      </div>
    </div>

    <!-- 全屏日志弹窗 -->
    <!-- 阶段产物弹窗 -->
    <el-dialog v-model="showStageFiles" width="860px" :title="stageDialogTitle" class="stage-dialog">
      <div v-if="stageFileLoading" style="text-align: center; padding: 40px;">
        <el-icon class="spinning" :size="24"><Loading /></el-icon>
        <div style="margin-top: 8px; color: #999;">加载中...</div>
      </div>
      <div v-else-if="stageFileContent !== null" class="stage-file-viewer">
        <div class="stage-file-tabs">
          <span
            v-for="f in stageFiles"
            :key="f"
            class="stage-file-tab"
            :class="{ active: f === activeStageFile }"
            @click="loadStageFile(f)"
          >{{ f }}</span>
        </div>

        <!-- 规则检查表格渲染 -->
        <template v-if="ruleCheckData">
          <div v-for="item in ruleSides" :key="item.key" class="rule-side">
            <div class="rule-side-header">
              <span class="rule-side-label">{{ item.label }}</span>
              <span class="rule-side-score">{{ ruleCheckData[item.key]?.total?.toFixed(1) ?? '-' }} / 30</span>
            </div>
            <template v-if="ruleCheckData[item.key]?.dimensions">
              <div v-for="(dim, dimName) in ruleCheckData[item.key].dimensions" :key="dimName" class="rule-dim">
                <div class="rule-dim-header">
                  {{ dimName }}
                  <span class="rule-dim-score">{{ dim.raw_score }} / {{ dim.max_score }}</span>
                </div>
                <el-table :data="dim.rules" size="small" stripe style="width: 100%;">
                  <el-table-column label="结果" width="60" align="center">
                    <template #default="{ row }">
                      <span :class="row.passed ? 'rule-pass' : 'rule-fail'">{{ row.passed ? '✓' : '✗' }}</span>
                    </template>
                  </el-table-column>
                  <el-table-column prop="name" label="规则" width="160" />
                  <el-table-column prop="level" label="级别" width="80">
                    <template #default="{ row }">
                      <el-tag :type="{ HIGH: 'danger', MEDIUM: 'warning', LOW: 'info' }[row.level]" size="small">
                        {{ row.level }}
                      </el-tag>
                    </template>
                  </el-table-column>
                  <el-table-column prop="description" label="说明" min-width="180" />
                  <el-table-column label="满分" width="70" align="center">
                    <template #default="{ row }">{{ row.max_score }}</template>
                  </el-table-column>
                  <el-table-column label="得分" width="70" align="center">
                    <template #default="{ row }">
                      <span :style="{ color: row.earned_score < row.max_score ? '#f56c6c' : '#67c23a', fontWeight: 600 }">
                        {{ row.earned_score }}
                      </span>
                    </template>
                  </el-table-column>
                  <el-table-column label="匹配" width="160">
                    <template #default="{ row }">
                      <code v-if="row.matched_text" class="matched-code">{{ row.matched_text }}</code>
                      <span v-else-if="!row.matched" style="color: #ccc;">未匹配</span>
                    </template>
                  </el-table-column>
                </el-table>
              </div>
            </template>
          </div>
        </template>

        <!-- LLM评分表格渲染 -->
        <template v-else-if="judgeData">
          <div v-for="item in ruleSides" :key="item.key" class="rule-side">
            <div class="rule-side-header">
              <span class="rule-side-label">{{ item.label }}</span>
              <span v-if="judgeData[item.key]" class="rule-side-score">
                均分 {{ (judgeData[item.key].reduce((s, d) => s + d.score, 0) / judgeData[item.key].length).toFixed(1) }}
              </span>
            </div>
            <el-table v-if="judgeData[item.key]" :data="judgeData[item.key]" size="small" stripe style="width: 100%;">
              <el-table-column prop="name" label="维度" width="120" />
              <el-table-column label="得分" width="80" align="center">
                <template #default="{ row }">
                  <span :style="{ color: row.score >= 80 ? '#67c23a' : row.score >= 60 ? '#e6a23c' : '#f56c6c', fontWeight: 600 }">
                    {{ row.score }}
                  </span>
                </template>
              </el-table-column>
              <el-table-column prop="reason" label="评分理由" min-width="300" show-overflow-tooltip />
            </el-table>
          </div>
        </template>

        <!-- 交互指标 -->
        <template v-else-if="interactionMetrics">
          <div class="metrics-panel">
            <div class="metrics-header">
              <div class="metrics-title">交互指标</div>
              <el-tag size="small" type="info">{{ interactionMetrics.adapter || '-' }}</el-tag>
            </div>

            <div class="metrics-grid">
              <div class="metrics-card">
                <div class="metrics-card-title">会话</div>
                <div class="metrics-kv"><span>来源</span><strong>{{ interactionMetrics.source || '-' }}</strong></div>
                <div class="metrics-kv"><span>Session</span><code>{{ interactionMetrics.session_id || '-' }}</code></div>
                <div class="metrics-kv"><span>Message</span><code>{{ interactionMetrics.message_id || '-' }}</code></div>
                <div class="metrics-kv"><span>Provider</span><strong>{{ interactionMetrics.provider_id || '-' }}</strong></div>
                <div class="metrics-kv"><span>Model</span><strong>{{ interactionMetrics.model_id || '-' }}</strong></div>
              </div>

              <div class="metrics-card">
                <div class="metrics-card-title">耗时</div>
                <div class="metrics-kv"><span>API 总耗时</span><strong>{{ fmtMs(interactionMetrics.timing?.api_elapsed_ms) }}</strong></div>
                <div class="metrics-kv"><span>模型耗时</span><strong>{{ fmtMs(interactionMetrics.timing?.model_elapsed_ms) }}</strong></div>
                <div class="metrics-kv"><span>输入字符</span><strong>{{ interactionMetrics.message?.input_chars ?? '-' }}</strong></div>
                <div class="metrics-kv"><span>输出字符</span><strong>{{ interactionMetrics.message?.output_chars ?? '-' }}</strong></div>
              </div>

              <div class="metrics-card">
                <div class="metrics-card-title">Token / Cost</div>
                <div class="metrics-kv"><span>输入 Token</span><strong>{{ interactionMetrics.usage?.input_tokens ?? '-' }}</strong></div>
                <div class="metrics-kv"><span>输出 Token</span><strong>{{ interactionMetrics.usage?.output_tokens ?? '-' }}</strong></div>
                <div class="metrics-kv"><span>思维 Token</span><strong>{{ interactionMetrics.usage?.reasoning_tokens ?? '-' }}</strong></div>
                <div class="metrics-kv"><span>Cache Read</span><strong>{{ interactionMetrics.usage?.cache_read_tokens ?? '-' }}</strong></div>
                <div class="metrics-kv"><span>Cache Write</span><strong>{{ interactionMetrics.usage?.cache_write_tokens ?? '-' }}</strong></div>
                <div class="metrics-kv"><span>Cost</span><strong>{{ interactionMetrics.usage?.cost ?? '-' }}</strong></div>
              </div>
            </div>

            <div v-if="interactionMetrics.tools?.observed_calls?.length" class="metrics-card">
              <div class="metrics-card-title">观测到的工具调用</div>
              <el-table :data="interactionMetrics.tools.observed_calls" size="small" stripe style="width: 100%;">
                <el-table-column prop="type" label="类型" width="180" />
                <el-table-column prop="name" label="名称" min-width="180" />
              </el-table>
            </div>

            <details class="metrics-raw">
              <summary>原始 JSON</summary>
              <pre class="stage-file-content">{{ JSON.stringify(interactionMetrics, null, 2) }}</pre>
            </details>
          </div>
        </template>

        <!-- 通用文件内容 -->
        <pre v-else class="stage-file-content">{{ stageFileContent }}</pre>
      </div>
      <div v-else style="text-align: center; padding: 40px; color: #999;">
        该阶段暂无产物文件
      </div>
    </el-dialog>

    <el-dialog v-model="showFullscreen" fullscreen :close-on-click-modal="false" class="fullscreen-log-dialog">
      <template #header>
        <div class="fullscreen-header">
          <span class="fullscreen-title">运行日志</span>
          <div class="log-controls">
            <el-radio-group v-model="fullscreenLogLevel" size="small">
              <el-radio-button value="ALL">全部</el-radio-button>
              <el-radio-button value="INFO">INFO</el-radio-button>
              <el-radio-button value="DEBUG">DEBUG</el-radio-button>
              <el-radio-button value="WARN">WARN</el-radio-button>
              <el-radio-button value="ERROR">ERROR</el-radio-button>
            </el-radio-group>
            <span class="log-count">{{ fullscreenFilteredLogs.length }} / {{ logs.length }}</span>
          </div>
        </div>
      </template>
      <div class="fullscreen-log-container" ref="fullscreenLogRef">
        <div v-for="(log, idx) in fullscreenFilteredLogs" :key="idx" class="log-entry">
          <span class="log-time">{{ log.timestamp }}</span>
          <span class="log-level" :class="log.level">{{ log.level }}</span>
          <div class="log-content">
            <span class="log-message">{{ [log.message, log.detail].filter(Boolean).join('\n') }}</span>
          </div>
        </div>
      </div>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted, watch, nextTick } from 'vue'
import axios from 'axios'
import {
  VideoPlay, VideoPause, CircleCheck, Timer, Setting,
  Check, Loading, Minus, Close, FullScreen, Clock, WarningFilled, CircleClose,
} from '@element-plus/icons-vue'
import ResultCard from '../components/ResultCard.vue'

// ── 配置 ──
const cascaderOptions = ref([])
const agentsData = ref([])
const selectedOptions = ref([])
const selectedScenario = ref([])
const selectedCaseIds = ref([])
const runTarget = ref('both')
const selectedAgentA = ref('')
const selectedAgentB = ref('')
const comparisonLabels = ref({})
const activeSides = ref(['side_a', 'side_b'])

// ── 状态 ──
const status = ref('idle')
const totalCases = ref(0)         // 来自后端实际值
const doneCases = ref(0)
const caseProgresses = ref([])
const logs = ref([])
const result = ref(null)
const results = ref([])
const generalResult = ref(null)
const activeResultTab = ref('cases')
const pollInterval = ref(null)
const elapsedSeconds = ref(0)

// ── 日志 ──
const logLevel = ref('ALL')
const fullscreenLogLevel = ref('ALL')
const showFullscreen = ref(false)
const logContainerRef = ref(null)
const fullscreenLogRef = ref(null)
const userScrolling = ref(false)

const isRunning = computed(() => status.value === 'running')
const canStart = computed(() =>
  Array.isArray(selectedCaseIds.value) &&
  (
    (runTarget.value === 'both' && !!selectedAgentA.value && !!selectedAgentB.value) ||
    (runTarget.value === 'agent_a' && !!selectedAgentA.value) ||
    (runTarget.value === 'agent_b' && !!selectedAgentB.value)
  ) &&
  selectedCaseIds.value.length > 0 &&
  !isRunning.value
)
const runTargetSummary = computed(() => ({
  both: '双侧并行对照',
  agent_a: '仅验证 Agent A',
  agent_b: '仅验证 Agent B',
}[runTarget.value] || '待选择'))
const selectionSummary = computed(() => {
  if (!selectedCaseIds.value.length) return '尚未选择用例'
  return `${selectedScenario.value.length} 个场景 · ${selectedCaseIds.value.length} 个用例`
})

// 从已选用例预计算数量（启动前显示）
const expectedTotal = computed(() => {
  return selectedCaseIds.value.length
})

// 显示用例数：运行中/完成后用后端实际值，否则用预计值
const displayTotal = computed(() =>
  (isRunning.value || totalCases.value > 0) ? totalCases.value : expectedTotal.value
)

// 进度环 (0–100 映射到 0–100 的 stroke-dasharray 路径长度)
const ringProgress = computed(() => {
  const total = displayTotal.value
  if (!total) return 0
  return Math.round((doneCases.value / total) * 100)
})

const statusText = computed(() => ({
  idle: '空闲', running: '运行中', completed: '已完成', stopped: '已停止', error: '错误'
}[status.value] || status.value))

const statusClass = computed(() => ({
  idle: 'status-idle', running: 'status-running',
  completed: 'status-completed', stopped: 'status-stopped', error: 'status-error'
}[status.value] || 'status-idle'))

const elapsedTime = computed(() => {
  const s = elapsedSeconds.value
  if (s < 60) return `${s}s`
  return `${Math.floor(s / 60)}m ${s % 60}s`
})

const filteredLogs = computed(() =>
  logLevel.value === 'ALL' ? logs.value : logs.value.filter(l => l.level === logLevel.value)
)
const fullscreenFilteredLogs = computed(() =>
  fullscreenLogLevel.value === 'ALL' ? logs.value : logs.value.filter(l => l.level === fullscreenLogLevel.value)
)
const getAgentNameById = (id) => agentsData.value.find(agent => agent.id === id)?.name || id || ''

const previewComparisonLabels = computed(() => {
  if (runTarget.value === 'agent_b') {
    return {
      side_a: getAgentNameById(selectedAgentB.value) || 'Agent B',
      side_b: '',
    }
  }
  return {
    side_a: getAgentNameById(selectedAgentA.value) || 'Agent A',
    side_b: runTarget.value === 'both' ? (getAgentNameById(selectedAgentB.value) || 'Agent B') : '',
  }
})

const effectiveComparisonLabels = computed(() => ({
  side_a: comparisonLabels.value.side_a || previewComparisonLabels.value.side_a || 'Agent A',
  side_b: comparisonLabels.value.side_b || previewComparisonLabels.value.side_b || '',
}))

const selectedAgentALabel = computed(() => (
  runTarget.value !== 'agent_b' && selectedAgentA.value ? effectiveComparisonLabels.value.side_a : ''
))
const selectedAgentBLabel = computed(() => (
  runTarget.value !== 'agent_a' && selectedAgentB.value
    ? (runTarget.value === 'agent_b' ? previewComparisonLabels.value.side_a : effectiveComparisonLabels.value.side_b)
    : ''
))
const generalComparisonLabels = computed(() => generalResult.value?.comparison_labels || effectiveComparisonLabels.value)
const effectiveActiveSides = computed(() => (
  status.value === 'idle'
    ? (runTarget.value === 'both' ? ['side_a', 'side_b'] : ['side_a'])
    : activeSides.value
))
const showEnhancedSide = computed(() => effectiveActiveSides.value.includes('side_b'))

const fmtScore = (v) => v != null ? v.toFixed(1) : '-'
const fmtMs = (v) => v != null ? `${v} ms` : '-'

// ── 阶段产物浏览 ──
const runId = ref(null)
const showStageFiles = ref(false)
const stageDialogTitle = ref('')
const stageFileLoading = ref(false)
const stageFiles = ref([])
const stageFileContent = ref(null)
const activeStageFile = ref('')
const ruleCheckData = ref(null)
const judgeData = ref(null)
const interactionMetrics = ref(null)
const ruleSides = computed(() => [
  { key: 'side_a', label: effectiveComparisonLabels.value.side_a },
  ...(showEnhancedSide.value ? [{ key: 'side_b', label: effectiveComparisonLabels.value.side_b }] : []),
])
let currentStageCtx = { caseId: '', stage: '' }

const STAGE_NAME_MAP = {
  'A侧运行': 'side_a',
  'B侧运行': 'side_b',
  '规则检查': 'rule_check',
  'LLM评分': 'llm_judge',
}

const displayStageLabel = (stageName) => {
  if (stageName === 'A侧运行') return `${effectiveComparisonLabels.value.side_a}运行`
  if (stageName === 'B侧运行') return `${effectiveComparisonLabels.value.side_b}运行`
  return stageName
}

const visibleStages = (stages = []) => (
  showEnhancedSide.value ? stages : stages.filter(stage => stage.name !== 'B侧运行')
)

const openStageFiles = async (caseId, stageName) => {
  const stage = STAGE_NAME_MAP[stageName]
  if (!stage || !runId.value) return

  currentStageCtx = { caseId, stage }
  stageDialogTitle.value = `${caseId} — ${stageName}`
  stageFileLoading.value = true
  stageFileContent.value = null
  ruleCheckData.value = null
  judgeData.value = null
  interactionMetrics.value = null
  stageFiles.value = []
  activeStageFile.value = ''
  showStageFiles.value = true

  try {
    const res = await axios.get(`/api/results/${runId.value}/cases/${caseId}/stages`)
    const files = res.data.stages?.[stage] || []
    stageFiles.value = files
    if (files.length > 0) {
      await loadStageFile(files[0])
    } else {
      stageFileLoading.value = false
    }
  } catch (e) {
    console.error(e)
    stageFileLoading.value = false
  }
}

const loadStageFile = async (filename) => {
  activeStageFile.value = filename
  stageFileLoading.value = true
  ruleCheckData.value = null
  judgeData.value = null
  interactionMetrics.value = null
  try {
    const { caseId, stage } = currentStageCtx
    const res = await axios.get(
      `/api/results/${runId.value}/cases/${caseId}/stages/${stage}/${filename}`,
      { transformResponse: [data => data] }
    )
    const raw = res.data
    if (filename === 'internal_score.json' && stage === 'rule_check') {
      try {
        const parsed = JSON.parse(raw)
        ruleCheckData.value = {
          side_a: parsed.side_a || parsed.baseline || null,
          side_b: parsed.side_b || parsed.enhanced || null,
        }
        stageFileContent.value = raw
      } catch {
        stageFileContent.value = raw
      }
    } else if (filename === 'judge.json' && stage === 'llm_judge') {
      try {
        const parsed = JSON.parse(raw)
        judgeData.value = {
          side_a: parsed.side_a || parsed.baseline || null,
          side_b: parsed.side_b || parsed.enhanced || null,
        }
        stageFileContent.value = raw
      } catch {
        stageFileContent.value = raw
      }
    } else if (filename === 'interaction_metrics.json') {
      try {
        interactionMetrics.value = JSON.parse(raw)
        stageFileContent.value = raw
      } catch {
        stageFileContent.value = raw
      }
    } else {
      stageFileContent.value = typeof raw === 'string' ? raw : JSON.stringify(raw, null, 2)
    }
  } catch (e) {
    stageFileContent.value = '加载失败'
  }
  stageFileLoading.value = false
}

// ── 数据加载 ──
const loadCascaderOptions = async () => {
  try {
    const [cascRes, agentsRes] = await Promise.all([
      axios.get('/api/cascader-options'),
      axios.get('/api/agents'),
    ])
    cascaderOptions.value = cascRes.data
    agentsData.value = agentsRes.data || []
    if (!selectedAgentA.value && agentsData.value.length > 0) {
      selectedAgentA.value = agentsData.value[0].id
    }
    if (!selectedAgentB.value && agentsData.value.length > 1) {
      selectedAgentB.value = agentsData.value[1].id
    } else if (!selectedAgentB.value && agentsData.value.length > 0) {
      selectedAgentB.value = agentsData.value[0].id
    }
  } catch (e) { console.error(e) }
}

const handleCascaderChange = (value) => {
  selectedOptions.value = value || []
  const scenarios = []
  const caseIds = []
  for (const item of (value || [])) {
    if (Array.isArray(item) && item.length >= 2) {
      scenarios.push(item[0])
      caseIds.push(item[1])
    }
  }
  selectedScenario.value = [...new Set(scenarios)]
  selectedCaseIds.value = [...new Set(caseIds)]
}

const fetchStatus = async () => {
  try {
    const res = await axios.get('/api/evaluation/status')
    const d = res.data
    status.value = d.status
    if (d.run_id) runId.value = d.run_id
    totalCases.value = d.total_cases || 0
    doneCases.value = d.done_cases || 0
    elapsedSeconds.value = d.elapsed_time || 0
    comparisonLabels.value = d.comparison_labels || {}
    activeSides.value = d.active_sides?.length ? d.active_sides : (runTarget.value === 'both' ? ['side_a', 'side_b'] : ['side_a'])
    if (d.case_progresses) caseProgresses.value = d.case_progresses
    if (d.logs?.length > logs.value.length) logs.value = d.logs
    if (d.result) result.value = d.result
    if (d.results?.length > 0) results.value = d.results
    if (d.general_result) generalResult.value = d.general_result
    if (['completed', 'stopped', 'error'].includes(d.status)) {
      clearInterval(pollInterval.value)
      pollInterval.value = null
    }
  } catch (e) { console.error(e) }
}

const startEvaluation = async () => {
  try {
    await axios.post('/api/evaluation/start', {
      mode: 'agent_compare',
      run_target: runTarget.value,
      profiles: [],
      scenarios: selectedScenario.value,
      case_ids: selectedCaseIds.value,
      agent_a: {
        agent_id: selectedAgentA.value,
        label: effectiveComparisonLabels.value.side_a,
      },
      agent_b: {
        agent_id: selectedAgentB.value,
        label: effectiveComparisonLabels.value.side_b,
      },
      skip_baseline: false,
      only_run_baseline: false,
    })
    status.value = 'running'
    runId.value = null
    totalCases.value = 0
    doneCases.value = 0
    elapsedSeconds.value = 0
    caseProgresses.value = []
    logs.value = []
    result.value = null
    results.value = []
    generalResult.value = null
    comparisonLabels.value = {
      side_a: effectiveComparisonLabels.value.side_a,
      side_b: effectiveComparisonLabels.value.side_b,
    }
    activeSides.value = runTarget.value === 'both' ? ['side_a', 'side_b'] : ['side_a']
    pollInterval.value = setInterval(fetchStatus, 1000)
  } catch (e) { console.error(e) }
}

const stopEvaluation = async () => {
  try {
    await axios.post('/api/evaluation/stop')
    clearInterval(pollInterval.value)
  } catch (e) { console.error(e) }
}

// 日志自动滚动
function isNearBottom(el) {
  return el.scrollHeight - el.scrollTop - el.clientHeight < 40
}
function onLogScroll() {
  if (logContainerRef.value) userScrolling.value = !isNearBottom(logContainerRef.value)
}
watch([() => logs.value.length, logLevel], async () => {
  await nextTick()
  if (logContainerRef.value && !userScrolling.value)
    logContainerRef.value.scrollTop = logContainerRef.value.scrollHeight
})
watch([() => logs.value.length, fullscreenLogLevel], async () => {
  await nextTick()
  if (fullscreenLogRef.value)
    fullscreenLogRef.value.scrollTop = fullscreenLogRef.value.scrollHeight
})

onMounted(async () => {
  await loadCascaderOptions()
  await fetchStatus()
  if (status.value === 'running') {
    pollInterval.value = setInterval(fetchStatus, 1000)
  }
})
onUnmounted(() => {
  clearInterval(pollInterval.value)
})
</script>

<style scoped>
.page-container {
  --surface: #fffdf8;
  --surface-strong: #fff7ec;
  --surface-muted: #f7f1e7;
  --border-soft: rgba(116, 83, 42, 0.14);
  --ink: #1f1b16;
  --ink-soft: #6f6558;
  --accent: #c96d28;
  --accent-deep: #9f4d16;
  --accent-cool: #1d7a72;
  --success: #1f8a52;
  --danger: #c43f33;
  display: flex;
  flex-direction: column;
  gap: 18px;
}

.card {
  background: var(--surface);
  border-radius: 20px;
  padding: 20px;
  border: 1px solid var(--border-soft);
  box-shadow: 0 18px 40px rgba(70, 40, 10, 0.07);
}

/* ── 控制台 ── */
.control-shell {
  background:
    radial-gradient(circle at top left, rgba(255, 215, 160, 0.34), transparent 34%),
    radial-gradient(circle at top right, rgba(29, 122, 114, 0.12), transparent 28%),
    linear-gradient(180deg, #fffdf9 0%, #fff8ef 100%);
}
.control-hero {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  gap: 18px;
  margin-bottom: 18px;
}
.hero-copy {
  min-width: 0;
}
.hero-kicker {
  display: inline-flex;
  align-items: center;
  padding: 6px 10px;
  border-radius: 999px;
  background: rgba(201, 109, 40, 0.12);
  color: var(--accent-deep);
  font-size: 12px;
  font-weight: 700;
  letter-spacing: 0.08em;
  text-transform: uppercase;
}
.hero-title {
  margin: 12px 0 10px;
  font-size: 30px;
  line-height: 1.15;
  font-weight: 700;
  color: var(--ink);
}
.hero-meta {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 10px;
}
.hero-pill {
  padding: 8px 12px;
  border-radius: 999px;
  background: #1f1b16;
  color: #fff7ee;
  font-size: 13px;
  font-weight: 600;
}
.hero-meta-text {
  color: var(--ink-soft);
  font-size: 14px;
}
.launch-button {
  min-width: 160px;
  min-height: 48px;
  border-radius: 14px;
  font-weight: 700;
}
.control-grid {
  display: grid;
  grid-template-columns: minmax(220px, 1fr) minmax(320px, 1.4fr) repeat(2, minmax(220px, 1fr));
  gap: 14px;
}
.control-panel,
.agent-panel {
  display: flex;
  flex-direction: column;
  gap: 12px;
  min-width: 0;
  padding: 16px;
  border-radius: 18px;
  background: rgba(255, 255, 255, 0.72);
  border: 1px solid rgba(116, 83, 42, 0.12);
}
.control-panel-wide {
  min-width: 0;
}
.agent-panel-a {
  background: linear-gradient(180deg, rgba(29, 122, 114, 0.08), rgba(255, 255, 255, 0.85));
}
.agent-panel-b {
  background: linear-gradient(180deg, rgba(201, 109, 40, 0.08), rgba(255, 255, 255, 0.85));
}
.agent-panel.muted {
  opacity: 0.58;
}
.panel-heading {
  display: flex;
  flex-direction: column;
  gap: 4px;
}
.panel-kicker {
  color: var(--ink);
  font-size: 14px;
  font-weight: 700;
}
.panel-note {
  color: var(--ink-soft);
  font-size: 12px;
  line-height: 1.5;
}
.control-cascader {
  width: 100%;
}
.control-select {
  width: 100%;
}

/* ── 状态卡片行 ── */
.stats-row {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(210px, 1fr));
  gap: 14px;
}
.stat-card {
  display: flex;
  align-items: center;
  gap: 12px;
  background: var(--surface);
  border-radius: 18px;
  border: 1px solid var(--border-soft);
  padding: 16px 18px;
  min-width: 0;
  box-shadow: 0 12px 28px rgba(70, 40, 10, 0.05);
}
.stat-icon-area {
  width: 44px; height: 44px;
  border-radius: 14px;
  display: flex; align-items: center; justify-content: center;
  background: var(--surface-muted);
  color: var(--ink-soft);
  flex-shrink: 0;
}
.stat-icon-area.purple { background: rgba(29, 122, 114, 0.12); color: var(--accent-cool); }
.stat-icon-area.orange { background: rgba(201, 109, 40, 0.12); color: var(--accent-deep); }

.stat-value { font-size: 17px; font-weight: 700; color: var(--ink); }
.stat-label { font-size: 12px; color: var(--ink-soft); margin-top: 2px; }
.profile-name { font-size: 13px; word-break: break-all; }

/* ── 状态卡片 ── */
.status-card { border-left: 4px solid #d9d2c6; }
.status-card.status-running { border-left-color: var(--accent-cool); }
.status-card.status-completed { border-left-color: var(--success); }
.status-card.status-stopped { border-left-color: var(--accent); }
.status-card.status-error { border-left-color: var(--danger); }

.status-badge {
  position: relative;
  width: 44px; height: 44px;
  display: flex; align-items: center; justify-content: center;
  flex-shrink: 0;
}
.status-ring {
  position: absolute;
  inset: 0;
  border-radius: 50%;
  border: 2px solid var(--accent-cool);
  animation: ring-pulse 1.5s ease-in-out infinite;
}
@keyframes ring-pulse {
  0%   { transform: scale(0.85); opacity: 1; }
  70%  { transform: scale(1.15); opacity: 0; }
  100% { transform: scale(0.85); opacity: 0; }
}
.status-icon-inner {
  position: relative; z-index: 1;
  color: var(--ink-soft);
}
.status-card.status-running .status-icon-inner { color: var(--accent-cool); }
.status-card.status-completed .status-icon-inner { color: var(--success); }
.status-card.status-stopped .status-icon-inner { color: var(--accent); }
.status-card.status-error .status-icon-inner { color: var(--danger); }

.status-text { font-size: 17px; font-weight: 700; }
.status-idle .status-text { color: var(--ink-soft); }
.status-running .status-text { color: var(--accent-cool); }
.status-completed .status-text { color: var(--success); }
.status-stopped .status-text { color: var(--accent); }
.status-error .status-text { color: var(--danger); }

/* ── 进度环 ── */
.progress-ring-wrap {
  position: relative;
  width: 44px; height: 44px;
  flex-shrink: 0;
}
.progress-ring {
  width: 44px; height: 44px;
  transform: rotate(-90deg);
}
.ring-bg {
  fill: none;
  stroke: #f0f0f0;
  stroke-width: 4;
}
.ring-fill {
  fill: none;
  stroke: var(--accent);
  stroke-width: 4;
  stroke-linecap: round;
  stroke-dasharray: 0 100;
  transition: stroke-dasharray 0.5s ease;
  /* 周长 ≈ 100.5，用 100 近似 */
  pathLength: 100;
}
.ring-text {
  position: absolute;
  inset: 0;
  display: flex; align-items: center; justify-content: center;
  font-size: 12px; font-weight: 700; color: var(--accent-deep);
}

/* ── Case 进度面板 ── */
.card-header {
  display: flex; justify-content: space-between; align-items: center;
  margin-bottom: 12px;
  padding-bottom: 8px;
  border-bottom: 1px solid #f0f0f0;
}
.card-title-sm {
  font-size: 15px; font-weight: 600; color: #1a1a2e;
}
.case-counter { font-size: 13px; color: #667eea; font-weight: 600; }

.case-list { display: flex; flex-direction: column; gap: 6px; }

.case-row {
  display: flex; align-items: center; gap: 12px;
  padding: 8px 12px;
  border-radius: 8px;
  background: #fafbfc;
  border: 1px solid #f0f0f0;
}
.case-row.running { background: #f0f5ff; border-color: #d0dfff; }
.case-row.done    { background: #f6fef6; border-color: #d4efd4; }
.case-row.error   { background: #fff5f5; border-color: #fdd; }

.case-info { min-width: 200px; flex-shrink: 0; }
.case-id-row {
  display: flex; align-items: center; gap: 6px; margin-bottom: 2px;
}
.case-status-dot {
  width: 7px; height: 7px; border-radius: 50%; background: #ddd; flex-shrink: 0;
}
.case-status-dot.running { background: #4285f4; animation: blink 1.2s infinite; }
.case-status-dot.done    { background: #34a853; }
.case-status-dot.error   { background: #ea4335; }
@keyframes blink { 0%,100% { opacity:1; } 50% { opacity:.3; } }

.case-id   { font-family: 'Consolas', monospace; font-weight: 600; font-size: 12px; color: #1a1a2e; }
.case-title { font-size: 11px; color: #888; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; max-width: 150px; }
.scenario-tag { font-size: 10px; padding: 0 3px; height: 16px; line-height: 16px; }

/* ── 阶段流水线（横排） ── */
.stage-pipeline {
  display: flex; align-items: center; gap: 0;
  flex-shrink: 0;
}
.stage-item {
  display: flex; flex-direction: column; align-items: center; gap: 3px;
  min-width: 52px;
}
.stage-dot {
  width: 22px; height: 22px; border-radius: 50%;
  display: flex; align-items: center; justify-content: center;
  border: 2px solid #ddd; background: #fff; color: #ccc;
}
.stage-dot.done    { border-color: #34a853; background: #34a853; color: #fff; }
.stage-dot.running { border-color: #4285f4; background: #4285f4; color: #fff; }
.stage-dot.skipped { border-color: #bbb; background: #f5f5f5; color: #aaa; }
.stage-dot.error   { border-color: #ea4335; background: #ea4335; color: #fff; }
.stage-number { font-size: 10px; font-weight: 600; }

.stage-label { font-size: 10px; color: #bbb; white-space: nowrap; }
.stage-item.done .stage-label    { color: #34a853; }
.stage-item.running .stage-label { color: #4285f4; font-weight: 600; }

.stage-time { font-size: 10px; color: #ccc; }

.stage-connector {
  flex: 0 0 12px; height: 2px; background: #e8e8e8; margin-bottom: 14px;
}
.stage-connector.done { background: #34a853; }

/* ── Case 结果 ── */
.case-result { display: flex; align-items: center; gap: 8px; margin-left: auto; flex-shrink: 0; }
.result-col { display: flex; flex-direction: column; align-items: center; min-width: 50px; }
.result-label { font-size: 10px; color: #999; margin-bottom: 2px; }
.result-value { font-size: 14px; font-weight: 600; }
.result-value.baseline { color: #999; }
.result-value.enhanced { color: #667eea; }
.result-value.positive { color: #34a853; }
.result-value.negative { color: #ea4335; }
.result-gain.positive { color: #34a853; }
.result-gain.negative { color: #ea4335; }
.error-text   { color: #ea4335; font-size: 12px; }

.running-hint { display: flex; gap: 4px; align-items: center; }
.running-dot {
  width: 5px; height: 5px; border-radius: 50%; background: #4285f4;
  animation: bounce 1.2s infinite;
}
.running-dot:nth-child(2) { animation-delay: 0.2s; }
.running-dot:nth-child(3) { animation-delay: 0.4s; }
@keyframes bounce { 0%,80%,100%{transform:scale(0.6);} 40%{transform:scale(1);} }

/* ── 日志 ── */
.log-header {
  display: flex; justify-content: space-between; align-items: center; margin-bottom: 10px;
}
.log-controls { display: flex; align-items: center; gap: 10px; }
.log-count { font-size: 12px; color: #909399; }
.log-container {
  background: #1e1e1e; border-radius: 8px; padding: 14px;
  height: 260px; overflow-y: auto;
  font-family: 'Consolas', 'Monaco', monospace; font-size: 12px;
}
.log-empty { color: #555; text-align: center; padding-top: 70px; }
.log-entry { padding: 2px 0; display: flex; gap: 10px; }
.log-time  { color: #777; flex-shrink: 0; }
.log-level { width: 46px; flex-shrink: 0; }
.log-level.INFO  { color: #4fc3f7; }
.log-level.WARNING,
.log-level.WARN  { color: #ffb74d; }
.log-level.ERROR { color: #ef5350; }
.log-level.DEBUG { color: #777; }
.log-content { flex: 1; min-width: 0; }
.log-message {
  color: #ddd;
  display: block;
  white-space: pre-wrap;
  word-break: break-word;
}

/* 全屏日志 */
.fullscreen-header {
  display: flex; justify-content: space-between; align-items: center;
  width: 100%; padding-right: 40px;
}
.fullscreen-title { font-size: 17px; font-weight: 600; }
.fullscreen-log-container {
  background: #1e1e1e; border-radius: 8px; padding: 20px;
  height: calc(100vh - 120px); overflow-y: auto;
  font-family: 'Consolas', 'Monaco', monospace; font-size: 13px;
}

.spinning { animation: spin 1s linear infinite; }
@keyframes spin { from{transform:rotate(0deg);} to{transform:rotate(360deg);} }

/* 通用用例结果 */
.compile-summary-card {
  background: linear-gradient(135deg, #34a85322, #4285f422);
  border: 1px solid #34a85344;
  border-radius: 12px;
  padding: 16px 20px;
  margin-bottom: 16px;
}

.compile-summary-title {
  font-size: 14px;
  font-weight: 600;
  color: #34a853;
  margin-bottom: 12px;
}

.compile-summary-grid {
  display: flex;
  gap: 32px;
}

.compile-item {
  display: flex;
  align-items: center;
  gap: 10px;
}

.compile-label {
  font-size: 13px;
  color: #666;
}

.compile-value {
  font-size: 20px;
  font-weight: 700;
  color: #34a853;
}

.compile-note {
  margin-top: 12px;
  padding: 10px 14px;
  background: #f8f9fa;
  border-radius: 8px;
  border-left: 3px solid #667eea;
  font-size: 12px;
  color: #666;
}

.compile-status {
  font-size: 12px;
  padding: 4px 8px;
  border-radius: 4px;
  margin: 2px;
}
.compile-status.pass {
  background: #34a85322;
  color: #34a853;
}
.compile-status.fail {
  background: #ea433522;
  color: #ea4335;
}

/* ── 可点击阶段 ── */
.stage-item.clickable {
  cursor: pointer;
}
.stage-item.clickable:hover .stage-dot {
  box-shadow: 0 0 0 3px rgba(52, 168, 83, 0.25);
}
.stage-item.clickable:hover .stage-label {
  text-decoration: underline;
}

/* ── 阶段产物弹窗 ── */
.stage-file-viewer {
  display: flex;
  flex-direction: column;
  gap: 12px;
}
.stage-file-tabs {
  display: flex;
  gap: 6px;
  flex-wrap: wrap;
}
.stage-file-tab {
  padding: 4px 12px;
  border-radius: 4px;
  font-size: 12px;
  background: #f0f2f5;
  color: #555;
  cursor: pointer;
  transition: all 0.2s;
}
.stage-file-tab:hover {
  background: #e0e4ea;
}
.stage-file-tab.active {
  background: #667eea;
  color: #fff;
}
.stage-file-content {
  background: #1e1e1e;
  color: #ddd;
  border-radius: 8px;
  padding: 16px;
  font-family: 'Consolas', 'Monaco', monospace;
  font-size: 12px;
  max-height: 500px;
  overflow: auto;
  white-space: pre-wrap;
  word-break: break-all;
  margin: 0;
}

/* ── 规则检查表格 ── */
.rule-side {
  margin-bottom: 20px;
}
.rule-side-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 8px 12px;
  background: #f0f2f5;
  border-radius: 6px;
  margin-bottom: 10px;
}
.rule-side-label {
  font-weight: 600;
  font-size: 14px;
  color: #1a1a2e;
}

.metrics-panel {
  display: flex;
  flex-direction: column;
  gap: 14px;
}

.metrics-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.metrics-title {
  font-size: 15px;
  font-weight: 700;
  color: var(--ink);
}

.metrics-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
  gap: 12px;
}

.metrics-card {
  border: 1px solid rgba(116, 83, 42, 0.14);
  border-radius: 14px;
  background: #fffdfa;
  padding: 14px;
}

.metrics-card-title {
  font-size: 13px;
  font-weight: 700;
  color: var(--accent-deep);
  margin-bottom: 10px;
}

.metrics-kv {
  display: flex;
  justify-content: space-between;
  gap: 12px;
  font-size: 12px;
  line-height: 1.6;
  color: var(--ink-soft);
}

.metrics-kv strong,
.metrics-kv code {
  color: var(--ink);
  font-weight: 600;
  text-align: right;
  word-break: break-all;
}

.metrics-raw {
  border: 1px solid rgba(116, 83, 42, 0.12);
  border-radius: 12px;
  background: #fffdfa;
  padding: 10px 12px;
}

.metrics-raw summary {
  cursor: pointer;
  font-size: 12px;
  font-weight: 600;
  color: var(--ink-soft);
  user-select: none;
}
.rule-side-score {
  font-weight: 700;
  font-size: 14px;
  color: #667eea;
}
.rule-dim {
  margin-bottom: 14px;
}
.rule-dim-header {
  font-size: 13px;
  font-weight: 600;
  color: #555;
  margin-bottom: 6px;
  display: flex;
  justify-content: space-between;
  align-items: center;
}
.rule-dim-score {
  font-size: 12px;
  color: #999;
  font-weight: 400;
}
.rule-pass {
  color: #34a853;
  font-weight: 700;
  font-size: 16px;
}
.rule-fail {
  color: #ea4335;
  font-weight: 700;
  font-size: 16px;
}
.matched-code {
  font-size: 11px;
  background: #fff3f3;
  color: #ea4335;
  padding: 2px 6px;
  border-radius: 3px;
  word-break: break-all;
}

.target-group {
  display: flex;
  flex-wrap: wrap;
  gap: 10px;
  width: 100%;
}

.target-group.disabled {
  opacity: 0.72;
}

.target-chip {
  flex: 1 1 156px;
  min-height: 56px;
  padding: 0 20px;
  border: 1px solid rgba(116, 83, 42, 0.14);
  border-radius: 16px;
  background: #fffdf9;
  color: var(--ink-soft);
  font-size: 15px;
  font-weight: 700;
  line-height: 1.2;
  white-space: nowrap;
  cursor: pointer;
  transition: all 0.2s ease;
}

.target-chip:hover:not(:disabled) {
  border-color: rgba(201, 109, 40, 0.42);
  color: var(--accent-deep);
  transform: translateY(-1px);
}

.target-chip.active {
  background: linear-gradient(135deg, var(--accent) 0%, #d9883b 100%);
  border-color: transparent;
  color: #fff;
  box-shadow: 0 12px 20px rgba(201, 109, 40, 0.24);
}

.target-chip:disabled {
  cursor: not-allowed;
}

:deep(.control-cascader .el-input__wrapper),
:deep(.control-select .el-input__wrapper) {
  min-height: 44px;
  border-radius: 12px;
  background: rgba(255, 255, 255, 0.9);
  box-shadow: 0 0 0 1px rgba(116, 83, 42, 0.1) inset;
}

:deep(.control-cascader .el-input__wrapper.is-focus),
:deep(.control-select .el-input__wrapper.is-focus) {
  box-shadow: 0 0 0 1px rgba(201, 109, 40, 0.38) inset;
}

@media (max-width: 1280px) {
  .control-grid {
    grid-template-columns: repeat(2, minmax(260px, 1fr));
  }
}

@media (max-width: 900px) {
  .card {
    padding: 18px;
    border-radius: 18px;
  }

  .control-hero {
    flex-direction: column;
  }

  .hero-title {
    font-size: 24px;
  }

  .control-grid {
    grid-template-columns: 1fr;
  }

  .target-chip {
    flex-basis: 100%;
    min-height: 50px;
    font-size: 14px;
  }

  .case-row {
    flex-direction: column;
    align-items: flex-start;
  }

  .case-info,
  .stage-pipeline,
  .case-result {
    width: 100%;
  }

  .case-result {
    margin-left: 0;
    justify-content: flex-start;
    flex-wrap: wrap;
  }
}
</style>

<style>
.fullscreen-log-dialog .el-dialog__body {
  padding: 0 20px 20px;
  height: calc(100vh - 60px);
}
.fullscreen-log-dialog .el-dialog__header {
  background: #f5f7fa; padding: 14px 20px; margin-right: 0;
}
</style>
