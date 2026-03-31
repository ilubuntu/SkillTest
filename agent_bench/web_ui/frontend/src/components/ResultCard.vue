<template>
  <div class="card">
    <div class="card-title">评测结果</div>
    <template v-if="result">
      <div v-if="results.length > 1" class="scenario-selector">
        <el-radio-group v-model="selectedResultIndex" size="default">
          <el-radio-button v-for="(r, idx) in results" :key="idx" :value="idx">
            {{ r.scenario }} ({{ r.profile }})
          </el-radio-button>
        </el-radio-group>
      </div>
      <div class="summary-grid">
        <div class="summary-item">
          <div class="summary-value">{{ currentResult.summary.total_cases }}</div>
          <div class="summary-label">用例总数</div>
        </div>
        <div class="summary-item">
          <div class="summary-value">{{ formatScore(currentResult.summary.side_a_avg) }}</div>
          <div class="summary-label">{{ effectiveLabels.side_a }}均分</div>
        </div>
        <div v-if="showEnhancedSide" class="summary-item">
          <div class="summary-value">{{ formatScore(currentResult.summary.side_b_avg) }}</div>
          <div class="summary-label">{{ effectiveLabels.side_b }}均分</div>
        </div>
        <div v-if="showEnhancedSide" class="summary-item">
          <div class="summary-value" :class="gainClass">
            {{ gainText }}
          </div>
          <div class="summary-label">整体差值</div>
        </div>
      </div>

      <div class="compile-summary-card" v-if="compilePassRateData">
        <div class="compile-summary-title">编译通过率</div>
        <div class="compile-summary-grid">
          <div class="compile-item">
            <div class="compile-label">{{ effectiveLabels.side_a }}</div>
            <el-tooltip 
              :content="sideACompileError || '编译通过'" 
              placement="top" 
              :disabled="!sideACompileError">
              <div class="compile-value" :class="sideACompileError ? 'compile-failed' : 'compile-pass'">
                {{ compilePassRateData.side_a }}
              </div>
            </el-tooltip>
          </div>
          <div v-if="showEnhancedSide" class="compile-item">
            <div class="compile-label">{{ effectiveLabels.side_b }}</div>
            <el-tooltip 
              :content="sideBCompileError || '编译通过'" 
              placement="top" 
              :disabled="!sideBCompileError">
              <div class="compile-value" :class="sideBCompileError ? 'compile-failed' : 'compile-pass'">
                {{ compilePassRateData.side_b }}
              </div>
            </el-tooltip>
          </div>
        </div>
        <div class="compile-note" v-if="compilePassRateData.note">
          {{ compilePassRateData.note }}
        </div>
      </div>

      <el-tabs :model-value="activeResultTab" @update:model-value="val => emit('update:activeResultTab', val)" class="result-tabs">
        <el-tab-pane label="用例明细" name="cases">
          <el-table :data="currentResult.cases" stripe style="width: 100%" max-height="400">
            <el-table-column prop="case_id" label="用例ID" width="120" />
            <el-table-column prop="title" label="用例名称" min-width="150" />
            <el-table-column prop="side_a_total" :label="`${effectiveLabels.side_a}得分`" width="120" sortable>
              <template #default="{ row }">
                {{ formatScore(row.side_a_total) }}
              </template>
            </el-table-column>
            <el-table-column v-if="showEnhancedSide" prop="side_b_total" :label="`${effectiveLabels.side_b}得分`" width="120" sortable>
              <template #default="{ row }">
                {{ formatScore(row.side_b_total) }}
              </template>
            </el-table-column>
            <el-table-column v-if="showEnhancedSide" prop="gain" label="差值" width="100" sortable>
              <template #default="{ row }">
                <span :class="row.gain >= 0 ? 'gain-positive' : 'gain-negative'">
                  {{ signedScore(row.gain) }}
                </span>
              </template>
            </el-table-column>
          </el-table>
        </el-tab-pane>
        <el-tab-pane label="维度分析" name="dimensions">
          <el-table :data="currentDimensionData" stripe style="width: 100%">
            <el-table-column prop="name" label="维度" width="140" />
            <el-table-column :label="`${effectiveLabels.side_a}(LLM)`" width="140" sortable>
              <template #default="{ row }">
                {{ formatScore(row.side_a_llm) }}
              </template>
            </el-table-column>
            <el-table-column :label="`${effectiveLabels.side_a}(本地)`" width="140">
              <template #default="{ row }">
                {{ formatScore(row.side_a_internal) }}
              </template>
            </el-table-column>
            <el-table-column v-if="showEnhancedSide" :label="`${effectiveLabels.side_b}(LLM)`" width="140" sortable>
              <template #default="{ row }">
                {{ formatScore(row.side_b_llm) }}
              </template>
            </el-table-column>
            <el-table-column v-if="showEnhancedSide" :label="`${effectiveLabels.side_b}(本地)`" width="140">
              <template #default="{ row }">
                {{ formatScore(row.side_b_internal) }}
              </template>
            </el-table-column>
            <el-table-column v-if="showEnhancedSide" prop="gain" label="差值(LLM)" sortable>
              <template #default="{ row }">
                <span :class="row.gain >= 0 ? 'gain-positive' : 'gain-negative'">
                  {{ signedScore(row.gain) }}
                </span>
              </template>
            </el-table-column>
          </el-table>
        </el-tab-pane>
        <el-tab-pane label="通过率" name="passrate">
          <div class="summary-grid" style="flex-wrap: wrap;">
            <div class="summary-item">
              <div class="summary-value">{{ currentResult.summary.side_a_pass_rate }}</div>
              <div class="summary-label">{{ effectiveLabels.side_a }}通过数 (≥60分)</div>
            </div>
            <div v-if="showEnhancedSide" class="summary-item">
              <div class="summary-value">{{ currentResult.summary.side_b_pass_rate }}</div>
              <div class="summary-label">{{ effectiveLabels.side_b }}通过数 (≥60分)</div>
            </div>
          </div>
        </el-tab-pane>
      </el-tabs>
    </template>
    <div v-else class="empty-state">
      <div style="color: #999;">暂无评测结果</div>
    </div>
  </div>
</template>

<script setup>
import { computed, ref, watch } from 'vue'

const props = defineProps({
  result: {
    type: Object,
    default: null
  },
  results: {
    type: Array,
    default: () => []
  },
  activeResultTab: {
    type: String,
    default: 'cases'
  },
  comparisonLabels: {
    type: Object,
    default: () => ({})
  },
  activeSides: {
    type: Array,
    default: () => ['side_a', 'side_b']
  }
})

const emit = defineEmits(['update:activeResultTab'])

const selectedResultIndex = ref(0)

const currentResult = computed(() => {
  if (props.results && props.results.length > 0) {
    return props.results[selectedResultIndex.value] || props.results[0]
  }
  return props.result
})

const effectiveLabels = computed(() => ({
  side_a: currentResult.value?.comparison_labels?.side_a || props.comparisonLabels.side_a || 'Agent A',
  side_b: currentResult.value?.comparison_labels?.side_b || props.comparisonLabels.side_b || 'Agent B',
}))

const currentActiveSides = computed(() => (
  currentResult.value?.active_sides?.length ? currentResult.value.active_sides : props.activeSides
))

const showEnhancedSide = computed(() => currentActiveSides.value.includes('side_b'))

const currentDimensionData = computed(() => {
  if (!currentResult.value?.summary?.dimensions) return []
  return Object.entries(currentResult.value.summary.dimensions).map(([dimId, data]) => ({
    dimId,
    name: data.name || dimId,
    side_a_llm: data.side_a_llm_avg ?? data.side_a_avg,
    side_a_internal: data.side_a_internal_avg,
    side_b_llm: data.side_b_llm_avg ?? data.side_b_avg,
    side_b_internal: data.side_b_internal_avg,
    gain: data.gain,
  }))
})

watch(() => props.results, (newResults) => {
  if (newResults && newResults.length > 0) {
    selectedResultIndex.value = 0
  }
})

const gainClass = computed(() => {
  if (!currentResult.value) return ''
  return currentResult.value.summary.gain >= 0 ? 'gain-positive' : 'gain-negative'
})

const gainText = computed(() => {
  if (!currentResult.value) return '--'
  const gain = currentResult.value.summary.gain
  return signedScore(gain)
})

const compilePassRateData = computed(() => {
  if (!currentResult.value?.general) return null
  const g = currentResult.value.general
  if (g.side_a_compile_pass_rate === 'N/A' && (!showEnhancedSide.value || g.side_b_compile_pass_rate === 'N/A')) {
    return null
  }
  return {
    side_a: g.side_a_compile_pass_rate || 'N/A',
    side_b: g.side_b_compile_pass_rate || 'N/A',
    note: g.note || null
  }
})

const formatScore = (value) => (
  typeof value === 'number' && Number.isFinite(value) ? value.toFixed(1) : '-'
)

const signedScore = (value) => {
  if (typeof value !== 'number' || !Number.isFinite(value)) return '-'
  return `${value >= 0 ? '+' : ''}${value.toFixed(1)}`
}

const sideACompileError = computed(() => {
  if (!currentResult.value?.cases?.length) return ''
  const errors = []
  for (const c of currentResult.value.cases) {
    if (c.compile_results?.side_a_compilable === false && c.compile_results?.side_a_error) {
      const shortError = c.compile_results.side_a_error.split('\n').slice(-3).join('\n')
      errors.push(`${c.case_id}: ${shortError}`)
    }
  }
  return errors.join('\n\n')
})

const sideBCompileError = computed(() => {
  if (!currentResult.value?.cases?.length) return ''
  const errors = []
  for (const c of currentResult.value.cases) {
    if (c.compile_results?.side_b_compilable === false && c.compile_results?.side_b_error) {
      const shortError = c.compile_results.side_b_error.split('\n').slice(-3).join('\n')
      errors.push(`${c.case_id}: ${shortError}`)
    }
  }
  return errors.join('\n\n')
})
</script>

<style scoped>
.summary-grid {
  display: flex;
  flex-wrap: wrap;
  gap: 16px;
  margin-bottom: 20px;
}

.summary-item {
  background: linear-gradient(135deg, #667eea22, #764ba222);
  border-radius: 12px;
  padding: 16px;
  text-align: center;
  min-width: 140px;
  flex: 1;
}

.summary-value {
  font-size: 28px;
  font-weight: 700;
  color: #667eea;
}

.summary-label {
  font-size: 13px;
  color: #888;
  margin-top: 4px;
}

.result-tabs {
  margin-top: 16px;
}

.scenario-selector {
  margin-bottom: 16px;
}

.empty-state {
  text-align: center;
  padding: 60px 20px;
  color: #999;
}

.passrate-section {
  margin-bottom: 24px;
}

.passrate-section:last-child {
  margin-bottom: 0;
}

.passrate-title {
  font-size: 14px;
  font-weight: 600;
  color: #555;
  margin-bottom: 12px;
  padding-bottom: 8px;
  border-bottom: 1px solid #f0f0f0;
}

.compile-note {
  margin-top: 12px;
  padding: 10px 14px;
  background: #f8f9fa;
  border-radius: 8px;
  border-left: 3px solid #667eea;
}

.note-text {
  font-size: 12px;
  color: #666;
  font-style: italic;
}

.compile-summary-card {
  background: linear-gradient(135deg, #34a85322, #4285f422);
  border: 1px solid #34a85344;
  border-radius: 12px;
  padding: 16px 20px;
  margin-bottom: 20px;
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
}

.compile-pass {
  color: #34a853;
}

.compile-failed {
  color: #ea4335;
  cursor: pointer;
}

.compile-failed:hover {
  text-decoration: underline;
}
</style>
