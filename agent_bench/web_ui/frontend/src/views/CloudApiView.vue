<template>
  <div class="page-container">
    <div class="card">
      <div class="section-head">
        <div>
          <h3>云测任务列表</h3>
          <p>本地接收云测下发任务后，自动准备沙箱、下载工程包、解压并执行。</p>
        </div>
        <div class="actions">
          <el-button @click="refreshTasks">刷新</el-button>
        </div>
      </div>
    </div>

    <div class="layout">
      <div class="card task-list-card">
        <div class="sub-title">收到的任务</div>
        <div v-if="tasks.length === 0" class="empty-text">暂无任务</div>
        <div
          v-for="item in tasks"
          :key="item.execution_id"
          class="task-item"
          :class="{ active: selectedExecutionId === item.execution_id }"
          @click="selectTask(item.execution_id)"
        >
          <div class="task-header">
            <span class="task-id">#{{ item.execution_id }}</span>
            <span class="task-status">{{ item.local_status || 'pending' }}</span>
          </div>
          <div class="task-meta">{{ item.case_title || item.case_id || '-' }}</div>
          <div class="task-meta small">{{ item.created_at || '-' }}</div>
        </div>
      </div>

      <div class="detail-column">
        <div class="status-grid">
          <div class="card stat-card">
            <div class="stat-label">本地状态</div>
            <div class="stat-value">{{ currentTask.local_status || 'idle' }}</div>
          </div>
          <div class="card stat-card">
            <div class="stat-label">当前阶段</div>
            <div class="stat-value">{{ currentTask.local_stage || '-' }}</div>
          </div>
          <div class="card stat-card">
            <div class="stat-label">executionId</div>
            <div class="stat-value">{{ currentTask.execution_id || '-' }}</div>
          </div>
          <div class="card stat-card">
            <div class="stat-label">任务标识</div>
            <div class="stat-value small">{{ currentTask.case_id || '-' }}</div>
          </div>
          <div class="card stat-card">
            <div class="stat-label">工程包地址</div>
            <div class="stat-value small path-text">{{ currentTask.project_source_url || currentTask.test_case?.fileUrl || '-' }}</div>
          </div>
          <div class="card stat-card">
            <div class="stat-label">输出代码</div>
            <div class="stat-value small">
              <a v-if="currentTask.output_code_url" :href="currentTask.output_code_url" target="_blank">下载</a>
              <span v-else>-</span>
            </div>
          </div>
        </div>

        <div class="card" v-if="currentTask.error_message">
          <h3>错误信息</h3>
          <pre class="json-block error-block">{{ currentTask.error_message }}</pre>
        </div>

        <div class="card">
          <h3>会话轨迹</h3>
          <div class="timeline">
            <div v-for="(item, idx) in currentTask.conversation || []" :key="idx" class="timeline-item">
              <span class="timeline-time">{{ item.timestamp }}</span>
              <span class="timeline-type">{{ item.type }}</span>
              <span class="timeline-message">{{ item.message }}</span>
            </div>
          </div>
        </div>

        <div class="payload-grid">
          <div class="card">
            <h3>最近一次状态上报</h3>
            <pre class="json-block">{{ formatJson(currentTask.last_status_payload) }}</pre>
          </div>
          <div class="card">
            <h3>最近一次结果上报</h3>
            <pre class="json-block">{{ formatJson(currentTask.last_result_payload) }}</pre>
          </div>
          <div class="card">
            <h3>状态接口响应</h3>
            <pre class="json-block">{{ formatJson(currentTask.last_status_response) }}</pre>
          </div>
          <div class="card">
            <h3>结果接口响应</h3>
            <pre class="json-block">{{ formatJson(currentTask.last_result_response) }}</pre>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed, onMounted, onUnmounted, ref } from 'vue'
import axios from 'axios'

const tasks = ref([])
const selectedExecutionId = ref(null)
const pollTimer = ref(null)

const currentTask = computed(() => {
  if (!tasks.value.length) return {}
  return tasks.value.find(item => item.execution_id === selectedExecutionId.value) || tasks.value[0] || {}
})

const formatJson = (value) => {
  if (!value) return '—'
  return JSON.stringify(value, null, 2)
}

const refreshTasks = async () => {
  const res = await axios.get('/api/cloud-api/status')
  tasks.value = res.data?.items || []
  if (!selectedExecutionId.value && tasks.value.length > 0) {
    selectedExecutionId.value = tasks.value[0].execution_id
  }
  if (selectedExecutionId.value && !tasks.value.some(item => item.execution_id === selectedExecutionId.value)) {
    selectedExecutionId.value = tasks.value[0]?.execution_id || null
  }
}

const selectTask = (executionId) => {
  selectedExecutionId.value = executionId
}

const ensurePolling = () => {
  if (pollTimer.value) return
  pollTimer.value = setInterval(refreshTasks, 2000)
}

const stopPolling = () => {
  if (!pollTimer.value) return
  clearInterval(pollTimer.value)
  pollTimer.value = null
}

onMounted(async () => {
  await refreshTasks()
  ensurePolling()
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
}

.layout {
  display: grid;
  grid-template-columns: 320px 1fr;
  gap: 16px;
}

.task-list-card {
  min-height: 480px;
}

.sub-title {
  font-size: 16px;
  font-weight: 600;
  margin-bottom: 12px;
}

.task-item {
  border: 1px solid #e5e7eb;
  border-radius: 10px;
  padding: 12px;
  margin-bottom: 10px;
  cursor: pointer;
}

.task-item.active {
  border-color: #409eff;
  background: #f5f9ff;
}

.task-header {
  display: flex;
  justify-content: space-between;
  margin-bottom: 6px;
}

.task-id {
  font-weight: 700;
}

.task-status {
  color: #666;
  font-size: 12px;
}

.task-meta {
  color: #333;
  line-height: 1.5;
}

.task-meta.small {
  color: #888;
  font-size: 12px;
}

.empty-text {
  color: #888;
  font-size: 14px;
}

.detail-column {
  display: flex;
  flex-direction: column;
  gap: 16px;
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
  font-size: 14px;
  line-height: 1.6;
  word-break: break-all;
}

.path-text {
  word-break: break-all;
}

.timeline {
  display: flex;
  flex-direction: column;
  gap: 8px;
  max-height: 320px;
  overflow: auto;
}

.timeline-item {
  display: grid;
  grid-template-columns: 160px 100px 1fr;
  gap: 12px;
  padding: 10px 0;
  border-bottom: 1px solid #f0f0f0;
}

.timeline-time,
.timeline-type {
  color: #666;
  font-size: 12px;
}

.timeline-message {
  word-break: break-word;
}

.json-block {
  margin: 0;
  background: #0f172a;
  color: #e2e8f0;
  padding: 12px;
  border-radius: 8px;
  overflow: auto;
  max-height: 320px;
  font-size: 12px;
}

.error-block {
  background: #3f1d1d;
  color: #ffd6d6;
}
</style>
