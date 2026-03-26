<template>
  <div class="card">
    <div class="card-title">评测进度</div>
    <div class="progress-section">
      <el-progress
        :percentage="progress"
        :stroke-width="12"
        :show-text="true"
        :status="progressStatus"
      />
      <div v-if="showProgressHint" class="progress-hint">
        {{ progressHintText }}
      </div>
    </div>
    <div class="card-title" style="margin-top: 20px;">评测日志</div>
    <div class="log-container" ref="logContainerRef">
      <div v-if="logs.length === 0" class="log-empty">
        {{ status === 'idle' ? '评测任务待启动' : '等待日志输出...' }}
      </div>
      <div v-for="(log, idx) in logs" :key="idx" class="log-entry">
        <span class="log-time">{{ log.timestamp }}</span>
        <span class="log-level" :class="log.level">{{ log.level }}</span>
        <span class="log-message">{{ log.message }}</span>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, watch, nextTick, onUnmounted } from 'vue'

const props = defineProps({
  progress: {
    type: Number,
    default: 0
  },
  status: {
    type: String,
    default: 'idle'
  },
  logs: {
    type: Array,
    default: () => []
  },
  logContainer: {
    type: Object,
    default: null
  }
})

const logContainerRef = ref(null)
const lastProgressUpdate = ref(Date.now())
const hintTimer = ref(null)
const showHint = ref(false)

const progressStatus = computed(() => {
  if (props.status === 'completed') return 'success'
  if (props.status === 'error') return 'exception'
  if (props.status === 'stopped') return 'warning'
  return null
})

const showProgressHint = computed(() => {
  return props.status === 'running' && showHint.value
})

const progressHintText = computed(() => {
  return '努力评测中，请稍后...'
})

watch(() => props.progress, (newVal, oldVal) => {
  if (newVal !== oldVal) {
    lastProgressUpdate.value = Date.now()
  }
})

watch(() => props.status, (newVal) => {
  if (newVal === 'running') {
    hintTimer.value = setInterval(() => {
      const elapsed = Date.now() - lastProgressUpdate.value
      if (elapsed > 8000 && props.status === 'running') {
        showHint.value = true
      }
    }, 2000)
  } else {
    showHint.value = false
    if (hintTimer.value) {
      clearInterval(hintTimer.value)
      hintTimer.value = null
    }
  }
})

watch(() => props.logs.length, async () => {
  await nextTick()
  if (logContainerRef.value) {
    logContainerRef.value.scrollTop = logContainerRef.value.scrollHeight
  }
})

onUnmounted(() => {
  if (hintTimer.value) {
    clearInterval(hintTimer.value)
  }
})
</script>

<style scoped>
.progress-section {
  margin-bottom: 16px;
}

.progress-hint {
  text-align: center;
  color: #909399;
  font-size: 13px;
  margin-top: 8px;
  animation: pulse 2s infinite;
}

@keyframes pulse {
  0%, 100% { opacity: 1; }
  50% { opacity: 0.6; }
}

.log-container {
  background: #1e1e1e;
  border-radius: 8px;
  padding: 16px;
  height: 250px;
  overflow-y: auto;
  font-family: 'Consolas', 'Monaco', monospace;
  font-size: 13px;
}

.log-empty {
  color: #666;
  text-align: center;
  padding-top: 80px;
}

.log-entry {
  padding: 4px 0;
  display: flex;
  gap: 12px;
}

.log-time {
  color: #888;
}

.log-level {
  width: 50px;
}

.log-level.INFO {
  color: #4fc3f7;
}

.log-level.WARN {
  color: #ffb74d;
}

.log-level.ERROR {
  color: #ef5350;
}

.log-level.DEBUG {
  color: #9e9e9e;
}

.log-message {
  color: #e0e0e0;
  flex: 1;
  word-break: break-all;
}
</style>