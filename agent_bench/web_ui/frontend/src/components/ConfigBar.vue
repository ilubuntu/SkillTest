<template>
  <div class="card">
    <div class="card-title">评测配置</div>
    <div class="skip-baseline-option" style="margin-bottom: 12px;">
      <el-checkbox v-model="skipBaseline">跳过基线运行（仅运行增强配置）</el-checkbox>
    </div>
    <div class="config-bar">
      <div class="config-item">
        <span class="config-label">选择场景及用例</span>
        <el-cascader
          :model-value="selectedOptions"
          :options="cascaderOptions"
          :props="{ checkStrictly: false, emitPath: true, multiple: true }"
          placeholder="请选择场景和用例"
          style="width: 400px;"
          :disabled="isRunning"
          @update:model-value="handleChange"
          collapse-tags
          collapse-tags-tooltip
        />
      </div>
      <div class="action-bar">
        <el-button
          :type="isRunning ? 'danger' : 'primary'"
          size="large"
          :disabled="isRunning ? false : !canStart"
          @click="isRunning ? $emit('stop') : $emit('start')"
        >
          {{ isRunning ? '⏹ 停止评测' : '▶ 启动评测' }}
        </el-button>
        <el-tag :type="statusType" size="large">
          {{ statusText }}
        </el-tag>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue'

defineProps({
  cascaderOptions: {
    type: Array,
    default: () => []
  },
  selectedOptions: {
    type: Array,
    default: () => []
  },
  isRunning: {
    type: Boolean,
    default: false
  },
  canStart: {
    type: Boolean,
    default: false
  },
  statusType: {
    type: String,
    default: 'info'
  },
  statusText: {
    type: String,
    default: '空闲'
  }
})

const emit = defineEmits(['update:selectedOptions', 'start', 'stop'])

const skipBaseline = ref(true)

const handleChange = (value) => {
  emit('update:selectedOptions', value)
}
</script>

<style scoped>
.config-bar {
  display: flex;
  align-items: center;
  gap: 20px;
  flex-wrap: wrap;
}

.config-item {
  display: flex;
  align-items: center;
  gap: 10px;
}

.config-label {
  font-weight: 500;
  color: #555;
  white-space: nowrap;
}

.action-bar {
  display: flex;
  align-items: center;
  gap: 12px;
  margin-left: auto;
}
</style>