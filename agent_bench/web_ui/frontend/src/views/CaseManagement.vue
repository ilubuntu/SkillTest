<template>
  <div class="page-container">
    <!-- 工具栏 -->
    <div class="toolbar card">
      <div class="toolbar-left">
        <el-select v-model="filterScenario" placeholder="全部场景" clearable style="width: 180px;">
          <el-option
            v-for="s in scenarios"
            :key="s.name"
            :label="`${s.label} (${s.count})`"
            :value="s.name"
          >
            <span class="scenario-dot" :style="{ background: s.color }"></span>
            {{ s.label }} ({{ s.count }})
          </el-option>
        </el-select>
        <el-input
          v-model="searchText"
          placeholder="搜索用例 ID 或标题"
          :prefix-icon="Search"
          clearable
          style="width: 260px;"
        />
      </div>
      <div class="toolbar-right">
        <span class="case-total">共 {{ filteredCases.length }} 个用例</span>
      </div>
    </div>

    <!-- 场景概览卡片 -->
    <div class="scenario-overview">
      <div
        v-for="s in scenarios"
        :key="s.name"
        class="scenario-card"
        :class="{ active: filterScenario === s.name }"
        @click="filterScenario = filterScenario === s.name ? '' : s.name"
      >
        <div class="scenario-card-header">
          <span class="scenario-dot-lg" :style="{ background: s.color }"></span>
          <span class="scenario-card-name">{{ s.label }}</span>
        </div>
        <div class="scenario-card-count">{{ s.count }}</div>
        <div class="scenario-card-label">用例数</div>
      </div>
    </div>

    <!-- 用例表格 -->
    <div class="card">
      <el-table :data="filteredCases" stripe style="width: 100%;" max-height="520" v-loading="loading">
        <el-table-column prop="id" label="用例 ID" width="170">
          <template #default="{ row }">
            <span class="case-id-link" @click="openCaseDetail(row)">{{ row.id }}</span>
          </template>
        </el-table-column>
        <el-table-column prop="title" label="标题" min-width="240" />
        <el-table-column prop="scenario" label="场景" width="140">
          <template #default="{ row }">
            <el-tag size="small" :color="getScenarioColor(row.scenario)" effect="dark" style="border: none;">
              {{ row.scenario }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="difficulty" label="难度" width="80">
          <template #default="{ row }">
            <el-tag :type="difficultyType(row.difficulty)" size="small">
              {{ difficultyLabel(row.difficulty) }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="tags" label="标签" width="200">
          <template #default="{ row }">
            <el-tag v-for="tag in row.tags" :key="tag" size="small" class="tag-item">
              {{ tag }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="80" fixed="right">
          <template #default="{ row }">
            <el-button link type="primary" size="small" @click="openCaseDetail(row)">查看</el-button>
          </template>
        </el-table-column>
      </el-table>
    </div>

    <!-- 用例详情抽屉 -->
    <el-drawer v-model="showDetail" :title="detailCase?.id" size="700px" direction="rtl">
      <template v-if="detailCase">
        <el-descriptions :column="2" border>
          <el-descriptions-item label="标题" :span="2">{{ detailCase.title }}</el-descriptions-item>
          <el-descriptions-item label="场景">
            <el-tag size="small" :color="getScenarioColor(detailCase.scenario)" effect="dark" style="border: none;">
              {{ detailCase.scenario }}
            </el-tag>
          </el-descriptions-item>
          <el-descriptions-item label="难度">
            <el-tag :type="difficultyType(detailCase.difficulty)" size="small">
              {{ difficultyLabel(detailCase.difficulty) }}
            </el-tag>
          </el-descriptions-item>
          <el-descriptions-item label="类别">{{ detailCase.category || '-' }}</el-descriptions-item>
          <el-descriptions-item label="标签">
            <el-tag v-for="tag in detailCase.tags" :key="tag" size="small" class="tag-item">{{ tag }}</el-tag>
          </el-descriptions-item>
        </el-descriptions>

        <h4 style="margin: 20px 0 10px;">Prompt</h4>
        <div class="code-block">{{ detailCase.prompt || '（无）' }}</div>
      </template>
    </el-drawer>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { Search } from '@element-plus/icons-vue'
import axios from 'axios'

const scenarios = ref([])
const cases = ref([])
const filterScenario = ref('')
const searchText = ref('')
const showDetail = ref(false)
const detailCase = ref(null)
const loading = ref(false)

const filteredCases = computed(() => {
  return cases.value.filter(c => {
    if (filterScenario.value && c.scenario !== filterScenario.value) return false
    if (searchText.value) {
      const q = searchText.value.toLowerCase()
      if (!c.id.toLowerCase().includes(q) && !c.title.toLowerCase().includes(q)) return false
    }
    return true
  })
})

const getScenarioColor = (name) => {
  const s = scenarios.value.find(s => s.name === name)
  return s ? s.color : '#999'
}

const difficultyType = (d) => ({ easy: 'success', medium: 'warning', hard: 'danger' }[d] || 'info')
const difficultyLabel = (d) => ({ easy: '简单', medium: '中等', hard: '困难' }[d] || d)

const openCaseDetail = (row) => {
  detailCase.value = row
  showDetail.value = true
}

const loadData = async () => {
  loading.value = true
  try {
    const [casesRes, scenariosRes] = await Promise.all([
      axios.get('/api/cases'),
      axios.get('/api/cases/scenarios'),
    ])
    cases.value = casesRes.data
    scenarios.value = scenariosRes.data
  } catch (e) {
    console.error('加载用例数据失败:', e)
  }
  loading.value = false
}

onMounted(loadData)
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

.toolbar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  flex-wrap: wrap;
  gap: 12px;
}

.toolbar-left, .toolbar-right {
  display: flex;
  align-items: center;
  gap: 10px;
}

.case-total {
  font-size: 13px;
  color: #999;
}

.scenario-overview {
  display: flex;
  gap: 12px;
  overflow-x: auto;
  padding-bottom: 4px;
}

.scenario-card {
  background: #fff;
  border-radius: 12px;
  padding: 16px 20px;
  min-width: 120px;
  cursor: pointer;
  box-shadow: 0 2px 12px rgba(0, 0, 0, 0.04);
  border: 2px solid transparent;
  transition: all 0.2s;
  text-align: center;
}

.scenario-card:hover {
  border-color: #667eea;
  transform: translateY(-2px);
}

.scenario-card.active {
  border-color: #667eea;
  background: linear-gradient(135deg, #667eea08, #764ba208);
}

.scenario-card-header {
  display: flex;
  align-items: center;
  gap: 8px;
  justify-content: center;
  margin-bottom: 8px;
}

.scenario-dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  display: inline-block;
}

.scenario-dot-lg {
  width: 10px;
  height: 10px;
  border-radius: 50%;
  display: inline-block;
}

.scenario-card-name {
  font-size: 13px;
  color: #666;
}

.scenario-card-count {
  font-size: 28px;
  font-weight: 700;
  color: #1a1a2e;
}

.scenario-card-label {
  font-size: 12px;
  color: #999;
}

.case-id-link {
  color: #667eea;
  cursor: pointer;
  font-family: 'Consolas', monospace;
}

.case-id-link:hover {
  text-decoration: underline;
}

.tag-item {
  margin-right: 4px;
  margin-bottom: 2px;
}

.code-block {
  background: #1e1e1e;
  color: #e0e0e0;
  border-radius: 8px;
  padding: 16px;
  font-family: 'Consolas', 'Monaco', monospace;
  font-size: 13px;
  white-space: pre-wrap;
  max-height: 300px;
  overflow-y: auto;
}

.file-path {
  font-size: 11px;
  color: #999;
  font-weight: 400;
  margin-left: 8px;
  font-family: 'Consolas', monospace;
}
</style>
