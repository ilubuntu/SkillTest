<template>
  <div class="page-container">
    <!-- 评测配置 -->
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
    <!-- 评测进度 -->
    <ProgressCard
      :progress="progress"
      :status="status"
      :logs="logs"
    />
    <!-- 评测结果 -->
    <ResultCard
      :result="result"
      :results="results"
      :active-result-tab="activeResultTab"
      :dimension-data="dimensionData"
      @update:active-result-tab="val => activeResultTab = val"
    />
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'
import axios from 'axios'
import ConfigBar from '../components/ConfigBar.vue'
import ProgressCard from '../components/ProgressCard.vue'
import ResultCard from '../components/ResultCard.vue'

const cascaderOptions = ref([])
const selectedOptions = ref([])
const selectedScenario = ref('')
const selectedProfile = ref('')

const status = ref('idle')
const progress = ref(0)
const logs = ref([])
const result = ref(null)
const results = ref([])
const activeResultTab = ref('cases')
const pollInterval = ref(null)

const isRunning = computed(() => status.value === 'running')

const canStart = computed(() => {
  const hasScenarios = Array.isArray(selectedScenario.value) && selectedScenario.value.length > 0
  const hasProfiles = Array.isArray(selectedProfile.value) && selectedProfile.value.length > 0
  return (hasScenarios || hasProfiles) && !isRunning.value
})

const statusType = computed(() => {
  const types = { idle: 'info', running: 'primary', completed: 'success', stopped: 'warning', error: 'danger' }
  return types[status.value] || ''
})

const statusText = computed(() => {
  const texts = { idle: '空闲', running: '运行中', completed: '已完成', stopped: '已停止', error: '错误' }
  return texts[status.value] || status.value
})

const dimensionData = computed(() => {
  if (!result.value || !result.value.summary?.dimensions) return []
  return Object.entries(result.value.summary.dimensions).map(([name, data]) => ({
    name,
    baseline_avg: data.baseline_avg,
    enhanced_avg: data.enhanced_avg,
    gain: data.gain,
  }))
})

const loadCascaderOptions = async () => {
  try {
    const res = await axios.get('/api/cascader-options')
    cascaderOptions.value = res.data
  } catch (e) {
    console.error('Failed to load cascader options:', e)
  }
}

const handleCascaderChange = (value) => {
  if (!value || !Array.isArray(value)) {
    selectedScenario.value = []
    selectedProfile.value = []
    return
  }
  const scenarios = []
  const profiles = []
  for (const item of value) {
    if (Array.isArray(item) && item.length >= 2) {
      scenarios.push(item[0])
      profiles.push(item[1])
    } else if (typeof item === 'string') {
      scenarios.push(item)
    }
  }
  selectedScenario.value = scenarios
  selectedProfile.value = profiles
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
    if (data.result) result.value = data.result
    if (data.results?.length > 0) results.value = data.results
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
    const profiles = Array.isArray(selectedProfile.value) ? selectedProfile.value : []
    const scenarios = Array.isArray(selectedScenario.value) ? selectedScenario.value : []
    await axios.post('/api/evaluation/start', {
      profiles, scenarios, skip_baseline: true,
    })
    status.value = 'running'
    logs.value = []
    result.value = null
    results.value = []
    pollInterval.value = setInterval(fetchStatus, 1000)
  } catch (e) {
    console.error('Start failed:', e)
  }
}

const stopEvaluation = async () => {
  try {
    await axios.post('/api/evaluation/stop')
    clearInterval(pollInterval.value)
    pollInterval.value = null
  } catch (e) {
    console.error('Stop failed:', e)
  }
}

onMounted(async () => {
  await loadCascaderOptions()
  await fetchStatus()
})

onUnmounted(() => {
  if (pollInterval.value) clearInterval(pollInterval.value)
})
</script>

<style scoped>
.page-container {
  display: flex;
  flex-direction: column;
  gap: 16px;
}
</style>
