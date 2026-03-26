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
    <div class="log-header" style="margin-top: 20px;">
      <span class="card-title" style="margin-bottom: 0; border-bottom: none; padding-bottom: 0;">评测日志</span>
      <div class="log-controls">
        <el-radio-group v-model="logLevel" size="small">
          <el-radio-button value="ALL">全部</el-radio-button>
          <el-radio-button value="INFO">INFO</el-radio-button>
          <el-radio-button value="DEBUG">DEBUG</el-radio-button>
        </el-radio-group>
        <span class="log-count">{{ filteredLogs.length }} / {{ logs.length }}</span>
        <el-button size="small" :icon="FullScreen" circle @click="showFullscreen = true" title="全屏查看日志" />
      </div>
    </div>
    <div class="log-container" ref="logContainerRef" @scroll="onLogScroll">
      <div v-if="logs.length === 0" class="log-empty">
        {{ status === 'idle' ? '评测任务待启动' : '等待日志输出...' }}
      </div>
      <div v-for="(log, idx) in filteredLogs" :key="idx" class="log-entry">
        <span class="log-time">{{ log.timestamp }}</span>
        <span class="log-level" :class="log.level">{{ log.level }}</span>
        <span class="log-message">{{ log.message }}</span>
      </div>
    </div>

    <!-- 全屏日志弹窗 -->
    <el-dialog
      v-model="showFullscreen"
      title="评测日志"
      fullscreen
      :close-on-click-modal="false"
      class="fullscreen-log-dialog"
    >
      <template #header>
        <div class="fullscreen-header">
          <span class="fullscreen-title">评测日志</span>
          <div class="log-controls">
            <el-radio-group v-model="fullscreenLogLevel" size="small">
              <el-radio-button value="ALL">全部</el-radio-button>
              <el-radio-button value="INFO">INFO</el-radio-button>
              <el-radio-button value="DEBUG">DEBUG</el-radio-button>
              <el-radio-button value="WARN">WARN</el-radio-button>
              <el-radio-button value="ERROR">ERROR</el-radio-button>
            </el-radio-group>
            <span class="log-count">{{ fullscreenFilteredLogs.length }} / {{ logs.length }}</span>
            <el-progress
              v-if="status === 'running'"
              :percentage="progress"
              :stroke-width="8"
              style="width: 160px; margin-left: 12px;"
            />
          </div>
        </div>
      </template>
      <div class="fullscreen-log-container" ref="fullscreenLogRef" @scroll="onFullscreenLogScroll">
        <div v-if="logs.length === 0" class="log-empty" style="padding-top: 200px;">
          {{ status === 'idle' ? '评测任务待启动' : '等待日志输出...' }}
        </div>
        <div v-for="(log, idx) in fullscreenFilteredLogs" :key="idx" class="log-entry">
          <span class="log-time">{{ log.timestamp }}</span>
          <span class="log-level" :class="log.level">{{ log.level }}</span>
          <span class="log-message">{{ log.message }}</span>
        </div>
      </div>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, computed, watch, nextTick, onUnmounted } from 'vue'
import { FullScreen } from '@element-plus/icons-vue'

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
const fullscreenLogRef = ref(null)
const lastProgressUpdate = ref(Date.now())
const hintTimer = ref(null)
const showHint = ref(false)
const logLevel = ref('ALL')
const showFullscreen = ref(false)
const fullscreenLogLevel = ref('ALL')
const userScrolling = ref(false)
const userScrollingFullscreen = ref(false)

function isNearBottom(el) {
  return el.scrollHeight - el.scrollTop - el.clientHeight < 40
}

function onLogScroll() {
  if (logContainerRef.value) {
    userScrolling.value = !isNearBottom(logContainerRef.value)
  }
}

function onFullscreenLogScroll() {
  if (fullscreenLogRef.value) {
    userScrollingFullscreen.value = !isNearBottom(fullscreenLogRef.value)
  }
}

const filteredLogs = computed(() => {
  if (logLevel.value === 'ALL') return props.logs
  return props.logs.filter(log => log.level === logLevel.value)
})

const fullscreenFilteredLogs = computed(() => {
  if (fullscreenLogLevel.value === 'ALL') return props.logs
  return props.logs.filter(log => log.level === fullscreenLogLevel.value)
})

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

watch([() => props.logs.length, logLevel], async () => {
  await nextTick()
  if (logContainerRef.value && !userScrolling.value) {
    logContainerRef.value.scrollTop = logContainerRef.value.scrollHeight
  }
})

watch([() => props.logs.length, fullscreenLogLevel], async () => {
  await nextTick()
  if (fullscreenLogRef.value && !userScrollingFullscreen.value) {
    fullscreenLogRef.value.scrollTop = fullscreenLogRef.value.scrollHeight
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

.log-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 12px;
}

.log-controls {
  display: flex;
  align-items: center;
  gap: 12px;
}

.log-count {
  font-size: 12px;
  color: #909399;
}

.log-container {
  background: #1e1e1e;
  border-radius: 8px;
  padding: 16px;
  height: 360px;
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

/* 全屏弹窗样式 */
.fullscreen-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  width: 100%;
  padding-right: 40px;
}

.fullscreen-title {
  font-size: 18px;
  font-weight: 600;
}

.fullscreen-log-container {
  background: #1e1e1e;
  border-radius: 8px;
  padding: 20px;
  height: calc(100vh - 120px);
  overflow-y: auto;
  font-family: 'Consolas', 'Monaco', monospace;
  font-size: 14px;
}
</style>

<style>
/* 全局样式覆盖 el-dialog */
.fullscreen-log-dialog .el-dialog__body {
  padding: 0 20px 20px;
  height: calc(100vh - 60px);
}

.fullscreen-log-dialog .el-dialog__header {
  background: #f5f7fa;
  padding: 16px 20px;
  margin-right: 0;
}
</style>
