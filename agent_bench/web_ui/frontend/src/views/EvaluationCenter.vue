<template>
  <div class="page-container">
    <!-- 顶部控制栏 -->
    <div class="card control-bar">
      <div class="control-main">
        <div class="control-row">
          <span class="control-label">场景 / Profile</span>
          <el-cascader
            :model-value="selectedOptions"
            :options="cascaderOptions"
            :props="{ checkStrictly: false, emitPath: true, multiple: true }"
            placeholder="选择评测场景和 Profile"
            class="control-cascader"
            :disabled="isRunning"
            @update:model-value="handleCascaderChange"
            collapse-tags
            collapse-tags-tooltip
            :max-collapse-tags="2"
          />
          <el-checkbox v-model="skipBaseline" :disabled="isRunning" style="margin-left: 16px; white-space: nowrap;">跳过基线</el-checkbox>
        </div>
      </div>
      <div class="control-actions">
        <el-button
          :type="isRunning ? 'danger' : 'primary'"
          size="large"
          :disabled="isRunning ? false : !canStart"
          @click="isRunning ? stopEvaluation() : startEvaluation()"
          :icon="isRunning ? VideoPause : VideoPlay"
        >
          {{ isRunning ? '停止评测' : '启动评测' }}
        </el-button>
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

      <!-- 当前 Profile -->
      <div class="stat-card" v-if="currentProfile || selectedProfile.length">
        <div class="stat-icon-area orange">
          <el-icon :size="22"><Setting /></el-icon>
        </div>
        <div class="stat-info">
          <div class="stat-value profile-name">{{ currentProfile || selectedProfile.join(', ') }}</div>
          <div class="stat-label">Profile</div>
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
            <template v-for="(stage, idx) in cp.stages" :key="stage.name">
              <div class="stage-item" :class="[stage.status, { clickable: stage.status === 'done' && runId }]"
                   @click="stage.status === 'done' && runId ? openStageFiles(cp.case_id, stage.name) : null">
                <div class="stage-dot" :class="stage.status">
                  <el-icon v-if="stage.status === 'done'" :size="10"><Check /></el-icon>
                  <el-icon v-else-if="stage.status === 'running'" :size="10" class="spinning"><Loading /></el-icon>
                  <el-icon v-else-if="stage.status === 'skipped'" :size="10"><Minus /></el-icon>
                  <el-icon v-else-if="stage.status === 'error'" :size="10"><Close /></el-icon>
                  <span v-else class="stage-number">{{ idx + 1 }}</span>
                </div>
                <div class="stage-label">{{ stage.name }}</div>
                <div class="stage-time" v-if="stage.elapsed != null">{{ stage.elapsed }}s</div>
              </div>
              <div class="stage-connector" v-if="idx < cp.stages.length - 1" :class="stage.status === 'done' ? 'done' : ''"></div>
            </template>
          </div>

          <!-- Case 结果 -->
          <div class="case-result" v-if="cp.status === 'done' && cp.gain != null">
            <div class="result-col">
              <span class="result-label">基线</span>
              <span class="result-value">{{ fmtScore(cp.baseline_total) }}</span>
            </div>
            <div class="result-col">
              <span class="result-label">增强</span>
              <span class="result-value enhanced">{{ fmtScore(cp.enhanced_total) }}</span>
            </div>
            <div class="result-col">
              <span class="result-label">增益</span>
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
            <div class="compile-label">基线</div>
            <div class="compile-value">{{ generalResult.general.baseline_compile_pass_rate }}</div>
          </div>
          <div class="compile-item">
            <div class="compile-label">增强</div>
            <div class="compile-value">{{ generalResult.general.enhanced_compile_pass_rate }}</div>
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
            <div class="compile-status" :class="c.compile_results?.baseline_compilable ? 'pass' : 'fail'">
              基线: {{ c.compile_results?.baseline_compilable ? '可编译' : '不可编译' }}
            </div>
            <div class="compile-status" :class="c.compile_results?.enhanced_compilable ? 'pass' : 'fail'">
              增强: {{ c.compile_results?.enhanced_compilable ? '可编译' : '不可编译' }}
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
      :dimension-data="dimensionData"
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
          <span class="log-message">{{ log.message }}</span>
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
                  <el-table-column label="检查结论" width="120">
                    <template #default="{ row }">
                      <span :class="row.passed ? 'rule-conclusion pass' : 'rule-conclusion fail'">{{ getRuleConclusion(row) }}</span>
                    </template>
                  </el-table-column>
                  <el-table-column label="证据" width="160">
                    <template #default="{ row }">
                      <code v-if="row.matched_text" class="matched-code">{{ row.matched_text }}</code>
                      <span v-else style="color: #ccc;">-</span>
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
          <span class="log-message">{{ log.message }}</span>
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
const scenariosData = ref([])     // [{name, case_count}]
const selectedOptions = ref([])
const selectedScenario = ref([])
const selectedProfile = ref([])
const skipBaseline = ref(false)

// ── 状态 ──
const status = ref('idle')
const totalCases = ref(0)         // 来自后端实际值
const doneCases = ref(0)
const currentProfile = ref('')
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
  Array.isArray(selectedScenario.value) && selectedScenario.value.length > 0 && !isRunning.value
)

// 从已选场景预计算用例数（启动前显示）
const expectedTotal = computed(() => {
  if (!selectedScenario.value.length || !scenariosData.value.length) return 0
  const uniqueScenarios = [...new Set(selectedScenario.value)]
  return uniqueScenarios.reduce((sum, name) => {
    const s = scenariosData.value.find(s => s.name === name)
    return sum + (s ? s.case_count : 0)
  }, 0)
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
const dimensionData = computed(() => {
  if (!result.value?.summary?.dimensions) return []
  return Object.entries(result.value.summary.dimensions).map(([dimId, data]) => ({
    dimId,
    name: data.name || dimId,
    baseline_llm: data.baseline_llm_avg ?? data.baseline_avg,
    baseline_internal: data.baseline_internal_avg,
    enhanced_llm: data.enhanced_llm_avg ?? data.enhanced_avg,
    enhanced_internal: data.enhanced_internal_avg,
    gain: data.gain,
  }))
})

const fmtScore = (v) => v != null ? v.toFixed(1) : '-'

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
const ruleSides = [{ key: 'baseline', label: '基线' }, { key: 'enhanced', label: '增强' }]
let currentStageCtx = { caseId: '', stage: '' }

const STAGE_NAME_MAP = {
  '基线运行': 'baseline',
  '增强运行': 'enhanced',
  '规则检查': 'rule_check',
  'LLM评分': 'llm_judge',
}

const openStageFiles = async (caseId, stageName) => {
  const stage = STAGE_NAME_MAP[stageName]
  if (!stage || !runId.value) return

  currentStageCtx = { caseId, stage }
  stageDialogTitle.value = `${caseId} — ${stageName}`
  stageFileLoading.value = true
  stageFileContent.value = null
  ruleCheckData.value = null
  judgeData.value = null
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
        ruleCheckData.value = await enrichRuleCheckData(parsed)
        stageFileContent.value = raw
      } catch {
        stageFileContent.value = raw
      }
    } else if (filename === 'judge.json' && stage === 'llm_judge') {
      try {
        judgeData.value = JSON.parse(raw)
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

const buildRuleMetaIndex = (rulesConfig) => {
  const index = new Map()
  Object.values(rulesConfig || {}).forEach((rules) => {
    if (!Array.isArray(rules)) return
    rules.forEach((rule) => {
      if (!rule?.name) return
      index.set(`${rule.name}::${rule.description || ''}`, rule)
      index.set(rule.name, rule)
    })
  })
  return index
}

const enrichRuleCheckSide = (sideData, ruleMetaIndex) => {
  if (!sideData?.dimensions) return sideData
  const dimensions = {}
  for (const [dimName, dim] of Object.entries(sideData.dimensions)) {
    dimensions[dimName] = {
      ...dim,
      rules: (dim.rules || []).map((rule) => {
        const meta = ruleMetaIndex.get(`${rule.name}::${rule.description || ''}`) || ruleMetaIndex.get(rule.name)
        return {
          ...rule,
          pass_on_match: meta?.pass_on_match,
        }
      }),
    }
  }
  return { ...sideData, dimensions }
}

const enrichRuleCheckData = async (data) => {
  try {
    const { caseId, stage } = currentStageCtx
    const rulesRes = await axios.get(
      `/api/results/${runId.value}/cases/${caseId}/stages/${stage}/rules.json`,
      { transformResponse: [raw => raw] }
    )
    const rulesConfig = JSON.parse(rulesRes.data)
    const ruleMetaIndex = buildRuleMetaIndex(rulesConfig)
    return {
      ...data,
      baseline: enrichRuleCheckSide(data.baseline, ruleMetaIndex),
      enhanced: enrichRuleCheckSide(data.enhanced, ruleMetaIndex),
    }
  } catch {
    return data
  }
}

const getRuleConclusion = (row) => {
  if (row.pass_on_match === false) {
    return row.matched ? '发现违规' : '未发现违规'
  }
  if (row.pass_on_match === true) {
    return row.matched ? '满足要求' : '默认通过'
  }
  return row.passed ? '通过' : '未通过'
}

// ── 数据加载 ──
const loadCascaderOptions = async () => {
  try {
    const [cascRes, scenRes] = await Promise.all([
      axios.get('/api/cascader-options'),
      axios.get('/api/scenarios'),
    ])
    cascaderOptions.value = cascRes.data
    scenariosData.value = scenRes.data
  } catch (e) { console.error(e) }
}

const handleCascaderChange = (value) => {
  selectedOptions.value = value || []
  const scenarios = [], profiles = []
  for (const item of (value || [])) {
    if (Array.isArray(item) && item.length >= 2) {
      scenarios.push(item[0])
      profiles.push(item[1])
    }
  }
  selectedScenario.value = scenarios
  selectedProfile.value = profiles
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
    currentProfile.value = d.current_profile || ''
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
      profiles: selectedProfile.value,
      scenarios: selectedScenario.value,
      skip_baseline: skipBaseline.value,
    })
    status.value = 'running'
    totalCases.value = 0
    doneCases.value = 0
    elapsedSeconds.value = 0
    caseProgresses.value = []
    logs.value = []
    result.value = null
    results.value = []
    generalResult.value = null
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
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.card {
  background: #fff;
  border-radius: 12px;
  padding: 20px;
  box-shadow: 0 2px 12px rgba(0, 0, 0, 0.04);
}

/* ── 控制栏 ── */
.control-bar {
  display: flex;
  align-items: center;
  gap: 16px;
  flex-wrap: wrap;
}
.control-main {
  flex: 1;
  min-width: 0;  /* 关键：允许内容收缩 */
}
.control-row {
  display: flex;
  align-items: center;
  gap: 12px;
  flex-wrap: wrap;
}
.control-label {
  font-weight: 500;
  color: #555;
  font-size: 14px;
  white-space: nowrap;
  flex-shrink: 0;
}
.control-cascader {
  flex: 1;
  min-width: 200px;
  max-width: 480px;
}
.control-actions {
  flex-shrink: 0;
}

/* ── 状态卡片行 ── */
.stats-row {
  display: flex;
  gap: 12px;
  flex-wrap: wrap;
}
.stat-card {
  display: flex;
  align-items: center;
  gap: 12px;
  background: #fff;
  border-radius: 12px;
  padding: 14px 18px;
  flex: 1;
  min-width: 150px;
  box-shadow: 0 2px 12px rgba(0, 0, 0, 0.04);
}
.stat-icon-area {
  width: 44px; height: 44px;
  border-radius: 10px;
  display: flex; align-items: center; justify-content: center;
  background: #f0f2f5; color: #999;
  flex-shrink: 0;
}
.stat-icon-area.purple { background: #f0e8fe; color: #667eea; }
.stat-icon-area.orange { background: #fef3e0; color: #f39c12; }

.stat-value { font-size: 17px; font-weight: 700; color: #1a1a2e; }
.stat-label { font-size: 12px; color: #999; margin-top: 2px; }
.profile-name { font-size: 13px; word-break: break-all; }

/* ── 状态卡片 ── */
.status-card { border-left: 3px solid #ddd; }
.status-card.status-running { border-left-color: #4285f4; }
.status-card.status-completed { border-left-color: #34a853; }
.status-card.status-stopped { border-left-color: #f39c12; }
.status-card.status-error { border-left-color: #ea4335; }

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
  border: 2px solid #4285f4;
  animation: ring-pulse 1.5s ease-in-out infinite;
}
@keyframes ring-pulse {
  0%   { transform: scale(0.85); opacity: 1; }
  70%  { transform: scale(1.15); opacity: 0; }
  100% { transform: scale(0.85); opacity: 0; }
}
.status-icon-inner {
  position: relative; z-index: 1;
  color: #999;
}
.status-card.status-running .status-icon-inner { color: #4285f4; }
.status-card.status-completed .status-icon-inner { color: #34a853; }
.status-card.status-stopped .status-icon-inner { color: #f39c12; }
.status-card.status-error .status-icon-inner { color: #ea4335; }

.status-text { font-size: 17px; font-weight: 700; }
.status-idle .status-text { color: #999; }
.status-running .status-text { color: #4285f4; }
.status-completed .status-text { color: #34a853; }
.status-stopped .status-text { color: #f39c12; }
.status-error .status-text { color: #ea4335; }

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
  stroke: #667eea;
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
  font-size: 12px; font-weight: 700; color: #667eea;
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
.log-level.WARN  { color: #ffb74d; }
.log-level.ERROR { color: #ef5350; }
.log-level.DEBUG { color: #777; }
.log-message { color: #ddd; flex: 1; word-break: break-all; }

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
.rule-conclusion {
  font-size: 12px;
  font-weight: 500;
  line-height: 1.4;
}
.rule-conclusion.pass {
  color: #34a853;
}
.rule-conclusion.fail {
  color: #ea4335;
}
.matched-code {
  font-size: 11px;
  background: #fff3f3;
  color: #ea4335;
  padding: 2px 6px;
  border-radius: 3px;
  word-break: break-all;
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
