<template>
  <div class="page-container">
    <!-- 历史报告列表 -->
    <div class="card">
      <div class="report-header">
        <h3>评测报告</h3>
        <div class="report-actions">
          <el-select v-model="filterProfile" placeholder="全部 Profile" clearable style="width: 180px;">
            <el-option v-for="p in profileOptions" :key="p" :label="p" :value="p" />
          </el-select>
          <el-button :icon="Refresh" @click="loadReports" :loading="loading">刷新</el-button>
        </div>
      </div>

      <el-empty v-if="!loading && reports.length === 0" description="暂无评测报告，请先在评测中心运行评测" />

      <el-table
        v-else
        :data="filteredReports"
        stripe
        highlight-current-row
        @current-change="selectReport"
        style="width: 100%;"
      >
        <el-table-column prop="run_id" label="Run ID" width="300">
          <template #default="{ row }">
            <span class="run-id">{{ row.run_id }}</span>
          </template>
        </el-table-column>
        <el-table-column prop="profile" label="Profile" width="160" />
        <el-table-column prop="scenario" label="场景" width="120" />
        <el-table-column prop="summary.total_cases" label="用例数" width="80" />
        <el-table-column label="基线 / 增强" width="130">
          <template #default="{ row }">
            {{ fmt(row.summary.baseline_avg) }} / {{ fmt(row.summary.enhanced_avg) }}
          </template>
        </el-table-column>
        <el-table-column prop="summary.gain" label="增益" width="80" sortable>
          <template #default="{ row }">
            <span :class="row.summary.gain >= 0 ? 'gain-positive' : 'gain-negative'">
              {{ row.summary.gain >= 0 ? '+' : '' }}{{ fmt(row.summary.gain) }}
            </span>
          </template>
        </el-table-column>
        <el-table-column prop="generated_at" label="时间" width="180">
          <template #default="{ row }">
            {{ formatTime(row.generated_at) }}
          </template>
        </el-table-column>
        <el-table-column label="操作" width="140">
          <template #default="{ row }">
            <el-button link type="primary" size="small" @click="exportJSON(row)">JSON</el-button>
            <el-button link type="primary" size="small" @click="exportMD(row)">Markdown</el-button>
          </template>
        </el-table-column>
      </el-table>
    </div>

    <!-- 报告详情 -->
    <template v-if="selectedReport">
      <!-- 增益概览 -->
      <div class="card">
        <h3 class="section-title">增益概览 — {{ selectedReport.profile }}</h3>
        <div class="overview-grid">
          <div class="overview-item">
            <div class="overview-value">{{ selectedReport.summary.total_cases }}</div>
            <div class="overview-label">用例总数</div>
          </div>
          <div class="overview-item">
            <div class="overview-value">{{ fmt(selectedReport.summary.baseline_avg) }}</div>
            <div class="overview-label">基线均分</div>
          </div>
          <div class="overview-item">
            <div class="overview-value highlight">{{ fmt(selectedReport.summary.enhanced_avg) }}</div>
            <div class="overview-label">增强均分</div>
          </div>
          <div class="overview-item">
            <div class="overview-value" :class="selectedReport.summary.gain >= 0 ? 'gain-positive' : 'gain-negative'">
              {{ selectedReport.summary.gain >= 0 ? '+' : '' }}{{ fmt(selectedReport.summary.gain) }}
            </div>
            <div class="overview-label">整体增益</div>
          </div>
          <div class="overview-item">
            <div class="overview-value">{{ selectedReport.summary.baseline_pass_rate }}</div>
            <div class="overview-label">基线通过率</div>
          </div>
          <div class="overview-item">
            <div class="overview-value highlight">{{ selectedReport.summary.enhanced_pass_rate }}</div>
            <div class="overview-label">增强通过率</div>
          </div>
        </div>
      </div>

      <!-- 维度分析 -->
      <div class="card" v-if="hasDimensions">
        <h3 class="section-title">维度分析（LLM评分 / 内部评分）</h3>
        <div class="dimension-bars">
          <div
            v-for="(data, dimId) in selectedReport.summary.dimensions"
            :key="dimId"
            class="dim-bar-group"
          >
            <div class="dim-bar-label">{{ data.name || dimensionLabel(dimId) }}</div>
            <div class="dim-bars">
              <div class="dim-bar-row">
                <span class="bar-label">基线LLM</span>
                <div class="bar-track">
                  <div class="bar-fill baseline" :style="{ width: (data.baseline_llm_avg ?? 0) + '%' }"></div>
                </div>
                <span class="bar-value">{{ fmt(data.baseline_llm_avg ?? data.baseline_avg) }}</span>
              </div>
              <div class="dim-bar-row">
                <span class="bar-label">基线内部</span>
                <div class="bar-track">
                  <div class="bar-fill baseline-internal" :style="{ width: (data.baseline_internal_avg ?? 0) + '%' }"></div>
                </div>
                <span class="bar-value">{{ fmt(data.baseline_internal_avg) }}</span>
              </div>
              <div class="dim-bar-row">
                <span class="bar-label">增强LLM</span>
                <div class="bar-track">
                  <div class="bar-fill enhanced" :style="{ width: (data.enhanced_llm_avg ?? 0) + '%' }"></div>
                </div>
                <span class="bar-value">{{ fmt(data.enhanced_llm_avg ?? data.enhanced_avg) }}</span>
              </div>
              <div class="dim-bar-row">
                <span class="bar-label">增强内部</span>
                <div class="bar-track">
                  <div class="bar-fill enhanced-internal" :style="{ width: (data.enhanced_internal_avg ?? 0) + '%' }"></div>
                </div>
                <span class="bar-value">{{ fmt(data.enhanced_internal_avg) }}</span>
              </div>
            </div>
            <div class="dim-gain" :class="data.gain >= 0 ? 'gain-positive' : 'gain-negative'">
              {{ data.gain >= 0 ? '+' : '' }}{{ fmt(data.gain) }}
            </div>
          </div>
        </div>
      </div>

      <!-- 用例明细 -->
      <div class="card">
        <h3 class="section-title">用例明细</h3>
        <el-table :data="selectedReport.cases" stripe style="width: 100%;">
          <el-table-column prop="case_id" label="用例 ID" width="180">
            <template #default="{ row }">
              <span class="case-id">{{ row.case_id }}</span>
            </template>
          </el-table-column>
          <el-table-column prop="title" label="标题" min-width="200" />
          <el-table-column prop="scenario" label="场景" width="120" />
          <el-table-column prop="baseline_rule" label="基线规则分" width="110" sortable>
            <template #default="{ row }">
              {{ fmt(row.baseline_rule) }}
            </template>
          </el-table-column>
          <el-table-column prop="enhanced_rule" label="增强规则分" width="110" sortable>
            <template #default="{ row }">
              {{ fmt(row.enhanced_rule) }}
            </template>
          </el-table-column>
          <el-table-column prop="baseline_total" label="基线总分" width="100" sortable>
            <template #default="{ row }">
              {{ fmt(row.baseline_total) }}
            </template>
          </el-table-column>
          <el-table-column prop="enhanced_total" label="增强总分" width="100" sortable>
            <template #default="{ row }">
              {{ fmt(row.enhanced_total) }}
            </template>
          </el-table-column>
          <el-table-column label="增益" width="100" sortable :sort-by="row => row.enhanced_total - row.baseline_total">
            <template #default="{ row }">
              <span :class="(row.enhanced_total - row.baseline_total) >= 0 ? 'gain-positive' : 'gain-negative'">
                {{ (row.enhanced_total - row.baseline_total) >= 0 ? '+' : '' }}{{ fmt(row.enhanced_total - row.baseline_total) }}
              </span>
            </template>
          </el-table-column>
        </el-table>

        <!-- 用例维度展开 -->
        <div v-if="selectedCase" class="case-dimension-detail">
          <h4>{{ selectedCase.case_id }} 维度得分</h4>
          <div class="case-dim-grid" v-if="selectedCase.dimension_scores">
            <div v-for="(scores, dim) in selectedCase.dimension_scores" :key="dim" class="case-dim-item">
              <div class="case-dim-name">{{ dimensionLabel(dim) }}</div>
              <div class="case-dim-scores">
                <span class="baseline-score">基线: {{ scores.baseline }}</span>
                <span class="enhanced-score">增强: {{ scores.enhanced }}</span>
                <span :class="(scores.enhanced - scores.baseline) >= 0 ? 'gain-positive' : 'gain-negative'">
                  {{ (scores.enhanced - scores.baseline) >= 0 ? '+' : '' }}{{ scores.enhanced - scores.baseline }}
                </span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </template>

    <div v-else-if="reports.length > 0" class="card empty-state">
      <el-empty description="点击上方表格中的报告查看详情" />
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { Refresh } from '@element-plus/icons-vue'
import axios from 'axios'

const reports = ref([])
const filterProfile = ref('')
const selectedReport = ref(null)
const selectedCase = ref(null)
const loading = ref(false)

const fmt = (v) => {
  if (v == null) return '-'
  return typeof v === 'number' ? v.toFixed(1) : v
}

const formatTime = (t) => {
  if (!t) return '-'
  return t.replace('T', ' ').slice(0, 19)
}

const profileOptions = computed(() => {
  const set = new Set(reports.value.map(r => r.profile))
  return Array.from(set).sort()
})

const filteredReports = computed(() => {
  if (!filterProfile.value) return reports.value
  return reports.value.filter(r => r.profile === filterProfile.value)
})

const hasDimensions = computed(() => {
  return selectedReport.value?.summary?.dimensions &&
    Object.keys(selectedReport.value.summary.dimensions).length > 0
})

const dimensionLabel = (name) => ({
  correctness: '正确性',
  completeness: '完整性',
  code_quality: '代码质量',
}[name] || name)

const loadReports = async () => {
  loading.value = true
  try {
    const res = await axios.get('/api/reports')
    reports.value = res.data
  } catch (e) {
    console.error('Failed to load reports:', e)
  } finally {
    loading.value = false
  }
}

const selectReport = (row) => {
  selectedReport.value = row
  selectedCase.value = null
}

const exportJSON = (report) => {
  const blob = new Blob([JSON.stringify(report, null, 2)], { type: 'application/json' })
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = `${report.run_id}.json`
  a.click()
  URL.revokeObjectURL(url)
}

const exportMD = (report) => {
  const md = generateMarkdown(report)
  const blob = new Blob([md], { type: 'text/markdown' })
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = `${report.run_id}.md`
  a.click()
  URL.revokeObjectURL(url)
}

const generateMarkdown = (report) => {
  let md = `# 评测报告: ${report.run_id}\n\n`
  md += `- **Profile**: ${report.profile}\n`
  md += `- **场景**: ${report.scenario}\n`
  md += `- **时间**: ${formatTime(report.generated_at)}\n\n`
  md += `## 概览\n\n`
  md += `| 指标 | 值 |\n|------|----|\n`
  md += `| 用例数 | ${report.summary.total_cases} |\n`
  md += `| 基线均分 | ${fmt(report.summary.baseline_avg)} |\n`
  md += `| 增强均分 | ${fmt(report.summary.enhanced_avg)} |\n`
  md += `| 增益 | ${report.summary.gain >= 0 ? '+' : ''}${fmt(report.summary.gain)} |\n`
  md += `| 基线通过率 | ${report.summary.baseline_pass_rate} |\n`
  md += `| 增强通过率 | ${report.summary.enhanced_pass_rate} |\n\n`

  if (report.summary.dimensions) {
    md += `## 维度分析\n\n`
    md += `| 维度 | 基线LLM | 基线内部 | 增强LLM | 增强内部 | 增益 |\n|------|---------|----------|---------|----------|------|\n`
    for (const [dimId, data] of Object.entries(report.summary.dimensions)) {
      const name = data.name || dimensionLabel(dimId)
      md += `| ${name} | ${fmt(data.baseline_llm_avg ?? data.baseline_avg)} | ${fmt(data.baseline_internal_avg)} | ${fmt(data.enhanced_llm_avg ?? data.enhanced_avg)} | ${fmt(data.enhanced_internal_avg)} | ${data.gain >= 0 ? '+' : ''}${fmt(data.gain)} |\n`
    }
    md += '\n'
  }

  md += `## 用例明细\n\n`
  md += `| 用例 | 标题 | 基线规则 | 增强规则 | 基线总分 | 增强总分 | 增益 |\n`
  md += `|------|------|----------|----------|----------|----------|------|\n`
  for (const c of report.cases) {
    const gain = c.enhanced_total - c.baseline_total
    md += `| ${c.case_id} | ${c.title} | ${fmt(c.baseline_rule)} | ${fmt(c.enhanced_rule)} | ${fmt(c.baseline_total)} | ${fmt(c.enhanced_total)} | ${gain >= 0 ? '+' : ''}${fmt(gain)} |\n`
  }
  return md
}

onMounted(() => {
  loadReports()
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

.report-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 16px;
}

.report-header h3 {
  margin: 0;
  color: #1a1a2e;
}

.report-actions {
  display: flex;
  gap: 10px;
  align-items: center;
}

.run-id {
  font-family: 'Consolas', monospace;
  font-size: 13px;
  color: #667eea;
}

.section-title {
  margin: 0 0 16px;
  color: #1a1a2e;
  font-size: 16px;
}

/* 增益概览 */
.overview-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(140px, 1fr));
  gap: 12px;
}

.overview-item {
  text-align: center;
  padding: 16px;
  background: #f8f9fb;
  border-radius: 10px;
}

.overview-value {
  font-size: 28px;
  font-weight: 700;
  color: #1a1a2e;
}

.overview-value.highlight {
  color: #667eea;
}

.overview-label {
  font-size: 13px;
  color: #999;
  margin-top: 4px;
}

.gain-positive {
  color: #67c23a;
}

.gain-negative {
  color: #f56c6c;
}

/* 维度分析 */
.dimension-bars {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.dim-bar-group {
  display: flex;
  align-items: center;
  gap: 16px;
}

.dim-bar-label {
  width: 80px;
  font-weight: 500;
  font-size: 14px;
  color: #333;
  text-align: right;
  flex-shrink: 0;
}

.dim-bars {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.dim-bar-row {
  display: flex;
  align-items: center;
  gap: 8px;
}

.bar-label {
  width: 32px;
  font-size: 12px;
  color: #999;
  text-align: right;
}

.bar-track {
  flex: 1;
  height: 20px;
  background: #f0f0f0;
  border-radius: 10px;
  overflow: hidden;
}

.bar-fill {
  height: 100%;
  border-radius: 10px;
  transition: width 0.6s ease;
}

.bar-fill.baseline {
  background: linear-gradient(90deg, #bbb, #999);
}

.bar-fill.baseline-internal {
  background: linear-gradient(90deg, #ddd, #bbb);
}

.bar-fill.enhanced {
  background: linear-gradient(90deg, #667eea, #764ba2);
}

.bar-fill.enhanced-internal {
  background: linear-gradient(90deg, #99a3f0, #a78bcf);
}

.bar-value {
  width: 42px;
  font-size: 13px;
  font-weight: 600;
  color: #333;
}

.dim-gain {
  width: 56px;
  text-align: center;
  font-weight: 600;
  font-size: 15px;
}

/* 用例明细 */
.case-id {
  font-family: 'Consolas', monospace;
  color: #667eea;
}

.case-dimension-detail {
  margin-top: 16px;
  padding: 16px;
  background: #f8f9fb;
  border-radius: 10px;
}

.case-dimension-detail h4 {
  margin: 0 0 12px;
  color: #1a1a2e;
}

.case-dim-grid {
  display: flex;
  gap: 16px;
  flex-wrap: wrap;
}

.case-dim-item {
  padding: 12px 16px;
  background: #fff;
  border-radius: 8px;
  min-width: 180px;
}

.case-dim-name {
  font-weight: 500;
  margin-bottom: 6px;
}

.case-dim-scores {
  display: flex;
  gap: 12px;
  font-size: 13px;
}

.baseline-score {
  color: #999;
}

.enhanced-score {
  color: #667eea;
}

.empty-state {
  padding: 40px;
}
</style>
