<template>
  <div class="app-container">
    <Header />
    <ConfigBar
      :cascader-options="cascaderOptions"
      :selected-options="selectedOptions"
      :is-running="isRunning"
      :can-start="canStart"
      :status-type="statusType"
      :status-text="statusText"
      @update:selected-options="handleCascaderChange"
      @start="startEvaluation"
      @stop="stopEvaluation"
    />
    <ProgressCard
      :progress="progress"
      :status="status"
      :logs="logs"
      :log-container="logContainer"
    />
    <ResultCard
      :result="result"
      :active-result-tab="activeResultTab"
      :dimension-data="dimensionData"
      @update:active-result-tab="val => activeResultTab = val"
    />
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'
import axios from 'axios'
import Header from './components/Header.vue'
import ConfigBar from './components/ConfigBar.vue'
import ProgressCard from './components/ProgressCard.vue'
import ResultCard from './components/ResultCard.vue'

const cascaderOptions = ref([])
const selectedOptions = ref([])
const selectedScenario = ref('')
const selectedProfile = ref('')

const status = ref('idle')
const progress = ref(0)
const logs = ref([])
const result = ref(null)
const logContainer = ref(null)
const activeResultTab = ref('cases')
const pollInterval = ref(null)

const isRunning = computed(() => status.value === 'running')

const canStart = computed(() => {
  return (selectedProfile.value || selectedScenario.value) && !isRunning.value
})

const statusType = computed(() => {
  const types = {
    'idle': 'info',
    'running': 'primary',
    'completed': 'success',
    'stopped': 'warning',
    'error': 'danger'
  }
  return types[status.value] || ''
})

const statusText = computed(() => {
  const texts = {
    'idle': '空闲',
    'running': '运行中',
    'completed': '已完成',
    'stopped': '已停止',
    'error': '错误'
  }
  return texts[status.value] || status.value
})

const dimensionData = computed(() => {
  if (!result.value || !result.value.summary?.dimensions) return []
  return Object.entries(result.value.summary.dimensions).map(([name, data]) => ({
    name,
    baseline_avg: data.baseline_avg,
    enhanced_avg: data.enhanced_avg,
    gain: data.gain
  }))
})

const loadCascaderOptions = async () => {
  try {
    const res = await axios.get('/api/cascader-options')
    cascaderOptions.value = res.data
    if (res.data.length > 0 && res.data[0].children?.length > 0) {
      selectedOptions.value = [res.data[0].value, res.data[0].children[0].value]
      handleCascaderChange(selectedOptions.value)
    }
  } catch (e) {
    console.error('Failed to load cascader options:', e)
  }
}

const handleCascaderChange = (value) => {
  if (value && Array.isArray(value) && value.length >= 2) {
    selectedScenario.value = value[0]
    selectedProfile.value = value[1]
  } else if (value) {
    selectedScenario.value = Array.isArray(value) ? value[0] : value
    selectedProfile.value = ''
  }
}

const fetchStatus = async () => {
  try {
    const res = await axios.get('/api/evaluation/status')
    const data = res.data

    status.value = data.status
    progress.value = data.progress

    if (data.logs?.length > logs.value.length) {
      logs.value = data.logs
    }

    if (data.result) {
      result.value = data.result
    }

    if (['completed', 'stopped', 'error'].includes(status.value)) {
      clearInterval(pollInterval.value)
      pollInterval.value = null
    }
  } catch (e) {
    console.error('Failed to fetch status:', e)
  }
}

const startEvaluation = async () => {
  try {
    await axios.post('/api/evaluation/start', {
      profiles: selectedProfile.value ? [selectedProfile.value] : [],
      scenarios: selectedScenario.value ? [selectedScenario.value] : [],
      skip_baseline: true
    })

    status.value = 'running'
    logs.value = []
    result.value = null

    pollInterval.value = setInterval(fetchStatus, 1000)
  } catch (e) {
    ElMessage.error(e.response?.data?.detail || '启动失败')
  }
}

const stopEvaluation = async () => {
  try {
    await axios.post('/api/evaluation/stop')
    clearInterval(pollInterval.value)
    pollInterval.value = null
  } catch (e) {
    ElMessage.error(e.response?.data?.detail || '停止失败')
  }
}

onMounted(async () => {
  await loadCascaderOptions()
  await fetchStatus()
})

onUnmounted(() => {
  if (pollInterval.value) {
    clearInterval(pollInterval.value)
  }
})
</script>

<style>
* {
  box-sizing: border-box;
  margin: 0;
  padding: 0;
}

body {
  font-family: 'HarmonyOS Sans', 'PingFang SC', 'Microsoft YaHei', sans-serif;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  min-height: 100vh;
  padding: 20px;
}

.app-container {
  max-width: 1400px;
  margin: 0 auto;
}

.card {
  background: rgba(255, 255, 255, 0.95);
  border-radius: 16px;
  padding: 24px;
  box-shadow: 0 8px 32px rgba(0, 0, 0, 0.1);
  margin-bottom: 20px;
}

.card-title {
  font-size: 18px;
  font-weight: 600;
  color: #333;
  margin-bottom: 20px;
  padding-bottom: 12px;
  border-bottom: 2px solid #f0f0f0;
}

.gain-positive {
  color: #67c23a;
}

.gain-negative {
  color: #ef5350;
}
</style>