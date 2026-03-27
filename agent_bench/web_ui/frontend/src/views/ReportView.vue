<template>
  <div class="page-container">
    <!-- 历史报告列表 -->
    <div class="card">
      <div class="report-header">
        <h3>评测报告</h3>
        <div class="report-actions">
          <el-select v-model="filterProfile" placeholder="全部 Profile" clearable style="width: 180px;">
            <el-option label="bug_fix_enhanced" value="bug_fix_enhanced" />
            <el-option label="project_gen" value="project_gen" />
            <el-option label="performance" value="performance" />
            <el-option label="compilable" value="compilable" />
          </el-select>
        </div>
      </div>

      <el-table
        :data="filteredReports"
        stripe
        highlight-current-row
        @current-change="selectReport"
        style="width: 100%;"
      >
        <el-table-column prop="run_id" label="Run ID" width="280">
          <template #default="{ row }">
            <span class="run-id">{{ row.run_id }}</span>
          </template>
        </el-table-column>
        <el-table-column prop="profile" label="Profile" width="160" />
        <el-table-column prop="scenario" label="场景" width="120" />
        <el-table-column prop="summary.total_cases" label="用例数" width="80" />
        <el-table-column label="基线/增强" width="120">
          <template #default="{ row }">
            {{ row.summary.baseline_avg.toFixed(1) }} / {{ row.summary.enhanced_avg.toFixed(1) }}
          </template>
        </el-table-column>
        <el-table-column prop="summary.gain" label="增益" width="80" sortable>
          <template #default="{ row }">
            <span :class="row.summary.gain >= 0 ? 'gain-positive' : 'gain-negative'">
              {{ row.summary.gain >= 0 ? '+' : '' }}{{ row.summary.gain.toFixed(1) }}
            </span>
          </template>
        </el-table-column>
        <el-table-column prop="created" label="时间" width="180" />
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
        <h3 class="section-title">增益概览</h3>
        <div class="overview-grid">
          <div class="overview-item">
            <div class="overview-value">{{ selectedReport.summary.total_cases }}</div>
            <div class="overview-label">用例总数</div>
          </div>
          <div class="overview-item">
            <div class="overview-value">{{ selectedReport.summary.baseline_avg.toFixed(1) }}</div>
            <div class="overview-label">基线均分</div>
          </div>
          <div class="overview-item">
            <div class="overview-value highlight">{{ selectedReport.summary.enhanced_avg.toFixed(1) }}</div>
            <div class="overview-label">增强均分</div>
          </div>
          <div class="overview-item">
            <div class="overview-value" :class="selectedReport.summary.gain >= 0 ? 'gain-positive' : 'gain-negative'">
              {{ selectedReport.summary.gain >= 0 ? '+' : '' }}{{ selectedReport.summary.gain.toFixed(1) }}
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
      <div class="card">
        <h3 class="section-title">维度分析</h3>
        <div class="dimension-bars">
          <div
            v-for="(data, name) in selectedReport.summary.dimensions"
            :key="name"
            class="dim-bar-group"
          >
            <div class="dim-bar-label">{{ dimensionLabel(name) }}</div>
            <div class="dim-bars">
              <div class="dim-bar-row">
                <span class="bar-label">基线</span>
                <div class="bar-track">
                  <div class="bar-fill baseline" :style="{ width: (data.baseline_avg * 10) + '%' }"></div>
                </div>
                <span class="bar-value">{{ data.baseline_avg.toFixed(1) }}</span>
              </div>
              <div class="dim-bar-row">
                <span class="bar-label">增强</span>
                <div class="bar-track">
                  <div class="bar-fill enhanced" :style="{ width: (data.enhanced_avg * 10) + '%' }"></div>
                </div>
                <span class="bar-value">{{ data.enhanced_avg.toFixed(1) }}</span>
              </div>
            </div>
            <div class="dim-gain" :class="data.gain >= 0 ? 'gain-positive' : 'gain-negative'">
              {{ data.gain >= 0 ? '+' : '' }}{{ data.gain.toFixed(1) }}
            </div>
          </div>
        </div>
      </div>

      <!-- 趋势对比（多次评测） -->
      <div class="card">
        <h3 class="section-title">趋势对比</h3>
        <div class="trend-chart">
          <div class="trend-y-axis">
            <span v-for="v in [10, 8, 6, 4, 2, 0]" :key="v">{{ v }}</span>
          </div>
          <div class="trend-bars-area">
            <div v-for="point in trendData" :key="point.date" class="trend-bar-group">
              <div class="trend-bar-pair">
                <div class="trend-bar baseline" :style="{ height: (point.baseline * 10) + '%' }">
                  <span class="trend-bar-value">{{ point.baseline }}</span>
                </div>
                <div class="trend-bar enhanced" :style="{ height: (point.enhanced * 10) + '%' }">
                  <span class="trend-bar-value">{{ point.enhanced }}</span>
                </div>
              </div>
              <div class="trend-date">{{ point.date }}</div>
            </div>
          </div>
        </div>
        <div class="trend-legend">
          <span class="legend-item"><span class="legend-dot baseline"></span> 基线</span>
          <span class="legend-item"><span class="legend-dot enhanced"></span> 增强</span>
        </div>
      </div>

      <!-- 用例明细 -->
      <div class="card">
        <h3 class="section-title">用例明细</h3>
        <el-table :data="selectedReport.cases" stripe style="width: 100%;">
          <el-table-column prop="case_id" label="用例 ID" width="160">
            <template #default="{ row }">
              <span class="case-id">{{ row.case_id }}</span>
            </template>
          </el-table-column>
          <el-table-column prop="title" label="标题" min-width="200" />
          <el-table-column prop="baseline_total" label="基线得分" width="100" sortable>
            <template #default="{ row }">
              {{ row.baseline_total.toFixed(1) }}
            </template>
          </el-table-column>
          <el-table-column prop="enhanced_total" label="增强得分" width="100" sortable>
            <template #default="{ row }">
              {{ row.enhanced_total.toFixed(1) }}
            </template>
          </el-table-column>
          <el-table-column prop="gain" label="增益" width="100" sortable>
            <template #default="{ row }">
              <span :class="row.gain >= 0 ? 'gain-positive' : 'gain-negative'">
                {{ row.gain >= 0 ? '+' : '' }}{{ row.gain.toFixed(1) }}
              </span>
            </template>
          </el-table-column>
          <el-table-column prop="regression" label="回退" width="80">
            <template #default="{ row }">
              <el-tag :type="row.regression ? 'danger' : 'success'" size="small">
                {{ row.regression ? '是' : '否' }}
              </el-tag>
            </template>
          </el-table-column>
        </el-table>
      </div>
    </template>

    <div v-else class="card empty-state">
      <el-empty description="点击上方表格中的报告查看详情" />
    </div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import { mockReports, mockTrendData } from '../mock/data'

const reports = ref(mockReports)
const filterProfile = ref('')
const selectedReport = ref(null)
const trendData = ref(mockTrendData)

const filteredReports = computed(() => {
  if (!filterProfile.value) return reports.value
  return reports.value.filter(r => r.profile === filterProfile.value)
})

const selectReport = (row) => {
  selectedReport.value = row
}

const dimensionLabel = (name) => ({
  correctness: '正确性',
  completeness: '完整性',
  code_quality: '代码质量',
}[name] || name)

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
  md += `- Profile: ${report.profile}\n`
  md += `- 场景: ${report.scenario}\n`
  md += `- 时间: ${report.created}\n\n`
  md += `## 概览\n\n`
  md += `| 指标 | 值 |\n|------|----|\n`
  md += `| 用例数 | ${report.summary.total_cases} |\n`
  md += `| 基线均分 | ${report.summary.baseline_avg.toFixed(1)} |\n`
  md += `| 增强均分 | ${report.summary.enhanced_avg.toFixed(1)} |\n`
  md += `| 增益 | ${report.summary.gain >= 0 ? '+' : ''}${report.summary.gain.toFixed(1)} |\n\n`
  md += `## 用例明细\n\n`
  md += `| 用例 | 基线 | 增强 | 增益 |\n|------|------|------|------|\n`
  for (const c of report.cases) {
    md += `| ${c.case_id} | ${c.baseline_total.toFixed(1)} | ${c.enhanced_total.toFixed(1)} | ${c.gain >= 0 ? '+' : ''}${c.gain.toFixed(1)} |\n`
  }
  return md
}
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

.bar-fill.enhanced {
  background: linear-gradient(90deg, #667eea, #764ba2);
}

.bar-value {
  width: 36px;
  font-size: 13px;
  font-weight: 600;
  color: #333;
}

.dim-gain {
  width: 50px;
  text-align: center;
  font-weight: 600;
  font-size: 15px;
}

/* 趋势图 */
.trend-chart {
  display: flex;
  gap: 8px;
  height: 240px;
  padding: 10px 0;
}

.trend-y-axis {
  display: flex;
  flex-direction: column;
  justify-content: space-between;
  font-size: 12px;
  color: #999;
  width: 24px;
  text-align: right;
  padding: 4px 0;
}

.trend-bars-area {
  flex: 1;
  display: flex;
  justify-content: space-around;
  align-items: flex-end;
  border-left: 1px solid #eee;
  border-bottom: 1px solid #eee;
  padding: 0 16px;
}

.trend-bar-group {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 6px;
  flex: 1;
}

.trend-bar-pair {
  display: flex;
  gap: 4px;
  align-items: flex-end;
  height: 200px;
}

.trend-bar {
  width: 24px;
  border-radius: 4px 4px 0 0;
  display: flex;
  align-items: flex-start;
  justify-content: center;
  padding-top: 4px;
  min-height: 20px;
  transition: height 0.6s ease;
}

.trend-bar.baseline {
  background: linear-gradient(180deg, #bbb, #ddd);
}

.trend-bar.enhanced {
  background: linear-gradient(180deg, #667eea, #a78bfa);
}

.trend-bar-value {
  font-size: 10px;
  color: #fff;
  font-weight: 600;
}

.trend-date {
  font-size: 12px;
  color: #999;
}

.trend-legend {
  display: flex;
  justify-content: center;
  gap: 24px;
  margin-top: 12px;
}

.legend-item {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 13px;
  color: #666;
}

.legend-dot {
  width: 12px;
  height: 12px;
  border-radius: 3px;
}

.legend-dot.baseline {
  background: #bbb;
}

.legend-dot.enhanced {
  background: #667eea;
}

.case-id {
  font-family: 'Consolas', monospace;
  color: #667eea;
}

.empty-state {
  padding: 40px;
}
</style>
