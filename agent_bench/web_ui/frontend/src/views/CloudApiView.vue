<template>
  <div class="page-container">
    <div class="card">
      <div class="section-head">
        <div>
          <h3>云测调试入口</h3>
          <p>手工填写云测任务参数，本地接收后直接执行，并按云测协议上报状态和结果。</p>
        </div>
        <div class="actions">
          <el-button @click="refreshStatus">刷新状态</el-button>
          <el-button type="primary" :loading="submitting" @click="startExecution">启动执行</el-button>
        </div>
      </div>

      <el-form label-width="120px" class="form-grid">
        <el-form-item label="云测地址">
          <el-input v-model="form.cloudBaseUrl" placeholder="留空则写本地文件，不发云端" />
        </el-form-item>
        <el-form-item label="executionId">
          <el-input-number v-model="form.executionId" :min="1" :step="1" controls-position="right" style="width: 220px;" />
        </el-form-item>
        <el-form-item label="执行 Agent">
          <el-select v-model="form.agentId" placeholder="选择一个 agent" style="width: 320px;">
            <el-option v-for="agent in agents" :key="agent.id" :label="`${agent.name} (${agent.adapter})`" :value="agent.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="工程包地址">
          <el-input v-model="form.fileUrl" placeholder="zip 地址或本地路径" />
        </el-form-item>
        <el-form-item label="任务输入" class="span-2">
          <el-input v-model="form.input" type="textarea" :rows="4" placeholder="云测下发给 agent 的输入" />
        </el-form-item>
        <el-form-item label="期望结果" class="span-2">
          <el-input v-model="form.expectedOutput" type="textarea" :rows="3" placeholder="用于 expectedOutputScore 的参考结果" />
        </el-form-item>
      </el-form>
    </div>

    <div class="status-grid">
      <div class="card stat-card">
        <div class="stat-label">本地状态</div>
        <div class="stat-value">{{ statusData.local_status || statusData.status || 'idle' }}</div>
      </div>
      <div class="card stat-card">
        <div class="stat-label">当前阶段</div>
        <div class="stat-value">{{ statusData.local_stage || '-' }}</div>
      </div>
      <div class="card stat-card">
        <div class="stat-label">executionId</div>
        <div class="stat-value">{{ statusData.execution_id || form.executionId || '-' }}</div>
      </div>
      <div class="card stat-card">
        <div class="stat-label">输出代码</div>
        <div class="stat-value small">
          <a v-if="statusData.output_code_url" :href="statusData.output_code_url" target="_blank">下载</a>
          <span v-else>-</span>
        </div>
      </div>
      <div class="card stat-card">
        <div class="stat-label">状态文件</div>
        <div class="stat-value small path-text">{{ statusData.last_status_file || '-' }}</div>
      </div>
      <div class="card stat-card">
        <div class="stat-label">结果文件</div>
        <div class="stat-value small path-text">{{ statusData.last_result_file || '-' }}</div>
      </div>
    </div>

    <div class="card" v-if="statusData.error_message">
      <h3>错误信息</h3>
      <pre class="json-block error-block">{{ statusData.error_message }}</pre>
    </div>

    <div class="card">
      <h3>会话轨迹</h3>
      <div class="timeline">
        <div v-for="(item, idx) in statusData.conversation || []" :key="idx" class="timeline-item">
          <span class="timeline-time">{{ item.timestamp }}</span>
          <span class="timeline-type">{{ item.type }}</span>
          <span class="timeline-message">{{ item.message }}</span>
        </div>
      </div>
    </div>

    <div class="payload-grid">
      <div class="card">
        <h3>最近一次状态上报</h3>
        <pre class="json-block">{{ formatJson(statusData.last_status_payload) }}</pre>
      </div>
      <div class="card">
        <h3>最近一次结果上报</h3>
        <pre class="json-block">{{ formatJson(statusData.last_result_payload) }}</pre>
      </div>
      <div class="card">
        <h3>状态接口响应</h3>
        <pre class="json-block">{{ formatJson(statusData.last_status_response) }}</pre>
      </div>
      <div class="card">
        <h3>结果接口响应</h3>
        <pre class="json-block">{{ formatJson(statusData.last_result_response) }}</pre>
      </div>
    </div>
  </div>
</template>

<script setup>
import { onMounted, onUnmounted, reactive, ref, watch } from 'vue'
import axios from 'axios'
import { ElMessage } from 'element-plus'

const STORAGE_KEY = 'cloud-api-view'
const DEFAULT_CASE_FILE_URL = 'agent_bench/test_cases/bug_fix/001/original_project'
const DEFAULT_CASE_ID = 'bug_fix_001'
const isPlaceholderText = (value) => {
  const normalized = (value || '').trim()
  if (!normalized) return true
  const placeholders = new Set(['输入内容', '输出内容', '期望结果', '任务输入', 'expectedoutput', 'input', 'output'])
  return placeholders.has(normalized) || placeholders.has(normalized.toLowerCase().replaceAll(' ', ''))
}

const agents = ref([])
const statusData = ref({})
const submitting = ref(false)
const pollTimer = ref(null)

const form = reactive({
  cloudBaseUrl: '',
  executionId: 1,
  agentId: '',
  fileUrl: DEFAULT_CASE_FILE_URL,
  input: '',
  expectedOutput: '',
})

const formatJson = (value) => {
  if (!value) return '—'
  return JSON.stringify(value, null, 2)
}

const persistForm = () => {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(form))
}

const restoreForm = () => {
  try {
    const raw = localStorage.getItem(STORAGE_KEY)
    if (!raw) return
    const data = JSON.parse(raw)
    Object.assign(form, data || {})
  } catch {
    // ignore
  }
  if (!form.fileUrl) form.fileUrl = DEFAULT_CASE_FILE_URL
}

const loadDefaultCase = async () => {
  const res = await axios.get(`/api/cases/${DEFAULT_CASE_ID}`)
  const data = res.data || {}
  if (isPlaceholderText(form.input)) form.input = data.prompt || ''
  if (isPlaceholderText(form.expectedOutput)) form.expectedOutput = data.output_requirements || ''
}

const loadAgents = async () => {
  const res = await axios.get('/api/agents')
  agents.value = res.data || []
  const agentExists = agents.value.some(agent => agent.id === form.agentId)
  if ((!form.agentId || !agentExists) && agents.value.length > 0) {
    form.agentId = agents.value[0].id
  }
}

const refreshStatus = async () => {
  const params = {}
  if (form.executionId) params.execution_id = form.executionId
  const res = await axios.get('/api/cloud-api/status', { params })
  statusData.value = res.data || {}
  const localStatus = statusData.value.local_status || statusData.value.status
  if (['pending', 'running'].includes(localStatus)) {
    ensurePolling()
  } else {
    stopPolling()
  }
}

const startExecution = async () => {
  const missingFields = []
  if (!form.executionId) missingFields.push('executionId')
  if (!form.agentId) missingFields.push('执行 Agent')
  if (!form.fileUrl?.trim()) missingFields.push('工程包地址')
  if (missingFields.length > 0) {
    ElMessage.error(`请先填写: ${missingFields.join('、')}`)
    return
  }
  submitting.value = true
  try {
    await axios.post('/api/cloud-api/start', {
      cloudBaseUrl: (form.cloudBaseUrl || '').trim(),
      executionId: Number(form.executionId),
      agentId: form.agentId,
      testCase: {
        input: form.input || '',
        expectedOutput: form.expectedOutput || '',
        fileUrl: form.fileUrl,
      },
    })
    ElMessage.success('任务已提交到本地执行器')
    await refreshStatus()
  } catch (error) {
    ElMessage.error(error?.response?.data?.detail || '启动失败')
  } finally {
    submitting.value = false
  }
}

const ensurePolling = () => {
  if (pollTimer.value) return
  pollTimer.value = setInterval(refreshStatus, 2000)
}

const stopPolling = () => {
  if (!pollTimer.value) return
  clearInterval(pollTimer.value)
  pollTimer.value = null
}

watch(form, persistForm, { deep: true })

onMounted(async () => {
  restoreForm()
  await loadAgents()
  await loadDefaultCase()
  await refreshStatus()
})

onUnmounted(() => {
  stopPolling()
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
  box-shadow: 0 2px 12px rgba(0, 0, 0, 0.05);
}

.section-head {
  display: flex;
  justify-content: space-between;
  gap: 16px;
  margin-bottom: 16px;
}

.section-head h3 {
  margin: 0 0 8px;
}

.section-head p {
  margin: 0;
  color: #666;
}

.actions {
  display: flex;
  gap: 8px;
  align-items: flex-start;
}

.form-grid {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 8px 20px;
}

.span-2 {
  grid-column: 1 / -1;
}

.status-grid,
.payload-grid {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 16px;
}

.stat-card {
  min-height: 110px;
}

.stat-label {
  font-size: 13px;
  color: #888;
  margin-bottom: 10px;
}

.stat-value {
  font-size: 26px;
  font-weight: 700;
  color: #1f1f1f;
}

.stat-value.small {
  font-size: 18px;
}

.path-text {
  font-size: 12px;
  line-height: 1.5;
  word-break: break-all;
}

.timeline {
  display: flex;
  flex-direction: column;
  gap: 10px;
  max-height: 320px;
  overflow-y: auto;
}

.timeline-item {
  display: grid;
  grid-template-columns: 170px 100px 1fr;
  gap: 10px;
  font-size: 13px;
  padding-bottom: 10px;
  border-bottom: 1px dashed #eee;
}

.timeline-time {
  color: #888;
}

.timeline-type {
  color: #3152b3;
  font-weight: 600;
}

.timeline-message {
  color: #222;
  white-space: pre-wrap;
  word-break: break-word;
}

.json-block {
  margin: 0;
  white-space: pre-wrap;
  word-break: break-word;
  font-size: 12px;
  line-height: 1.5;
  background: #0f172a;
  color: #e2e8f0;
  padding: 14px;
  border-radius: 10px;
  min-height: 120px;
}

.error-block {
  background: #2a1010;
  color: #ffd5d5;
}

@media (max-width: 1100px) {
  .form-grid,
  .status-grid,
  .payload-grid {
    grid-template-columns: 1fr;
  }

  .section-head {
    flex-direction: column;
  }

  .timeline-item {
    grid-template-columns: 1fr;
  }
}
</style>
