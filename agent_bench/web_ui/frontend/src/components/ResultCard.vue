<template>
  <div class="card">
    <div class="card-title">评测结果</div>
    <template v-if="result">
      <div class="summary-grid">
        <div class="summary-item">
          <div class="summary-value">{{ result.summary.total_cases }}</div>
          <div class="summary-label">用例总数</div>
        </div>
        <div class="summary-item">
          <div class="summary-value">{{ result.summary.baseline_avg.toFixed(1) }}</div>
          <div class="summary-label">基线均分</div>
        </div>
        <div class="summary-item">
          <div class="summary-value">{{ result.summary.enhanced_avg.toFixed(1) }}</div>
          <div class="summary-label">增强均分</div>
        </div>
        <div class="summary-item">
          <div class="summary-value" :class="gainClass">
            {{ gainText }}
          </div>
          <div class="summary-label">整体增益</div>
        </div>
      </div>

      <el-tabs :model-value="activeResultTab" @update:model-value="val => emit('update:activeResultTab', val)" class="result-tabs">
        <el-tab-pane label="用例明细" name="cases">
          <el-table :data="result.cases" stripe style="width: 100%" max-height="400">
            <el-table-column prop="case_id" label="用例ID" width="120" />
            <el-table-column prop="title" label="用例名称" min-width="150" />
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
          </el-table>
        </el-tab-pane>
        <el-tab-pane label="维度分析" name="dimensions">
          <el-table :data="dimensionData" stripe style="width: 100%">
            <el-table-column prop="name" label="维度" width="150" />
            <el-table-column prop="baseline_avg" label="基线均分" width="120" sortable>
              <template #default="{ row }">
                {{ row.baseline_avg.toFixed(1) }}
              </template>
            </el-table-column>
            <el-table-column prop="enhanced_avg" label="增强均分" width="120" sortable>
              <template #default="{ row }">
                {{ row.enhanced_avg.toFixed(1) }}
              </template>
            </el-table-column>
            <el-table-column prop="gain" label="增益" sortable>
              <template #default="{ row }">
                <span :class="row.gain >= 0 ? 'gain-positive' : 'gain-negative'">
                  {{ row.gain >= 0 ? '+' : '' }}{{ row.gain.toFixed(1) }}
                </span>
              </template>
            </el-table-column>
          </el-table>
        </el-tab-pane>
        <el-tab-pane label="通过率" name="passrate">
          <div class="summary-grid" style="flex-wrap: wrap;">
            <div class="summary-item">
              <div class="summary-value">{{ result.summary.baseline_pass_rate }}</div>
              <div class="summary-label">基线通过数 (≥60分)</div>
            </div>
            <div class="summary-item">
              <div class="summary-value">{{ result.summary.enhanced_pass_rate }}</div>
              <div class="summary-label">增强通过数 (≥60分)</div>
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
import { computed } from 'vue'

const props = defineProps({
  result: {
    type: Object,
    default: null
  },
  activeResultTab: {
    type: String,
    default: 'cases'
  },
  dimensionData: {
    type: Array,
    default: () => []
  }
})

const emit = defineEmits(['update:activeResultTab'])

const gainClass = computed(() => {
  if (!props.result) return ''
  return props.result.summary.gain >= 0 ? 'gain-positive' : 'gain-negative'
})

const gainText = computed(() => {
  if (!props.result) return '--'
  const gain = props.result.summary.gain
  return (gain >= 0 ? '+' : '') + gain.toFixed(1)
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

.empty-state {
  text-align: center;
  padding: 60px 20px;
  color: #999;
}
</style>