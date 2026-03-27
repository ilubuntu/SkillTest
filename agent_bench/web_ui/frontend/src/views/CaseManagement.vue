<template>
  <div class="page-container">
    <!-- 工具栏 -->
    <div class="toolbar card">
      <div class="toolbar-left">
        <el-select v-model="filterScenario" placeholder="全部场景" clearable style="width: 160px;">
          <el-option
            v-for="s in scenarios"
            :key="s.name"
            :label="s.label"
            :value="s.name"
          >
            <span class="scenario-dot" :style="{ background: s.color }"></span>
            {{ s.label }} ({{ s.count }})
          </el-option>
        </el-select>
        <el-select v-model="filterDifficulty" placeholder="全部难度" clearable style="width: 120px;">
          <el-option label="简单" value="easy" />
          <el-option label="中等" value="medium" />
          <el-option label="困难" value="hard" />
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
        <el-button type="primary" :icon="Plus" @click="showCreateDialog = true">
          新建用例
        </el-button>
        <el-button :icon="Upload">批量导入</el-button>
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
      <el-table :data="filteredCases" stripe style="width: 100%;" max-height="520">
        <el-table-column prop="id" label="用例 ID" width="160">
          <template #default="{ row }">
            <span class="case-id-link" @click="openCaseDetail(row)">{{ row.id }}</span>
          </template>
        </el-table-column>
        <el-table-column prop="title" label="标题" min-width="200" />
        <el-table-column prop="scenario" label="场景" width="120">
          <template #default="{ row }">
            <el-tag size="small" :color="getScenarioColor(row.scenario)" effect="dark" style="border: none;">
              {{ getScenarioLabel(row.scenario) }}
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
        <el-table-column prop="status" label="状态" width="80">
          <template #default="{ row }">
            <el-tag :type="row.status === 'active' ? 'success' : 'info'" size="small">
              {{ row.status === 'active' ? '启用' : '草稿' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="updated" label="更新时间" width="120" />
        <el-table-column label="操作" width="150" fixed="right">
          <template #default="{ row }">
            <el-button link type="primary" size="small" @click="openCaseDetail(row)">查看</el-button>
            <el-button link type="primary" size="small">编辑</el-button>
            <el-button link type="danger" size="small">删除</el-button>
          </template>
        </el-table-column>
      </el-table>
    </div>

    <!-- 用例详情抽屉 -->
    <el-drawer v-model="showDetail" :title="detailCase?.id" size="700px" direction="rtl">
      <template v-if="detailCase">
        <el-descriptions :column="2" border>
          <el-descriptions-item label="标题" :span="2">{{ detailCase.title }}</el-descriptions-item>
          <el-descriptions-item label="场景">{{ detailCase.scenario }}</el-descriptions-item>
          <el-descriptions-item label="难度">{{ difficultyLabel(detailCase.difficulty) }}</el-descriptions-item>
          <el-descriptions-item label="状态">
            <el-tag :type="detailCase.status === 'active' ? 'success' : 'info'" size="small">
              {{ detailCase.status === 'active' ? '启用' : '草稿' }}
            </el-tag>
          </el-descriptions-item>
          <el-descriptions-item label="更新时间">{{ detailCase.updated }}</el-descriptions-item>
        </el-descriptions>

        <h4 style="margin: 20px 0 10px;">Prompt</h4>
        <div class="code-block">{{ detailCase.prompt }}</div>

        <h4 style="margin: 20px 0 10px;">输入代码</h4>
        <div class="code-block">{{ detailCase.input_code || '（无）' }}</div>

        <h4 style="margin: 20px 0 10px;">参考代码</h4>
        <div class="code-block">{{ detailCase.reference_code || '（无）' }}</div>

        <h4 style="margin: 20px 0 10px;">评分权重</h4>
        <el-descriptions :column="3" border size="small">
          <el-descriptions-item
            v-for="(weight, dim) in detailCase.rubric"
            :key="dim"
            :label="dim"
          >
            {{ weight }}%
          </el-descriptions-item>
        </el-descriptions>

        <h4 style="margin: 20px 0 10px;">规则匹配</h4>
        <div style="margin-bottom: 8px;">
          <strong>必须包含：</strong>
          <el-tag v-for="r in detailCase.rules.must_contain" :key="r" size="small" type="success" class="tag-item">
            {{ r }}
          </el-tag>
          <span v-if="!detailCase.rules.must_contain?.length" style="color: #999;">无</span>
        </div>
        <div>
          <strong>不能包含：</strong>
          <el-tag v-for="r in detailCase.rules.must_not_contain" :key="r" size="small" type="danger" class="tag-item">
            {{ r }}
          </el-tag>
          <span v-if="!detailCase.rules.must_not_contain?.length" style="color: #999;">无</span>
        </div>
      </template>
    </el-drawer>

    <!-- 新建用例弹窗 -->
    <el-dialog v-model="showCreateDialog" title="新建测试用例" width="700px">
      <el-form label-width="100px">
        <el-form-item label="用例 ID">
          <el-input placeholder="如 bug_fix_004" />
        </el-form-item>
        <el-form-item label="标题">
          <el-input placeholder="简要描述测试目标" />
        </el-form-item>
        <el-form-item label="场景">
          <el-select placeholder="选择场景" style="width: 100%;">
            <el-option v-for="s in scenarios" :key="s.name" :label="s.label" :value="s.name" />
          </el-select>
        </el-form-item>
        <el-form-item label="难度">
          <el-radio-group>
            <el-radio value="easy">简单</el-radio>
            <el-radio value="medium">中等</el-radio>
            <el-radio value="hard">困难</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item label="Prompt">
          <el-input type="textarea" :rows="4" placeholder="Agent 接收到的提示词" />
        </el-form-item>
        <el-form-item label="输入代码">
          <el-input type="textarea" :rows="4" placeholder="需要修改的原始代码（可选）" />
        </el-form-item>
        <el-form-item label="参考代码">
          <el-input type="textarea" :rows="4" placeholder="期望的参考实现" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="showCreateDialog = false">取消</el-button>
        <el-button type="primary" @click="showCreateDialog = false">保存</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import { Search, Plus, Upload } from '@element-plus/icons-vue'
import { mockCases, mockScenarios } from '../mock/data'

const scenarios = ref(mockScenarios)
const cases = ref(mockCases)
const filterScenario = ref('')
const filterDifficulty = ref('')
const searchText = ref('')
const showDetail = ref(false)
const detailCase = ref(null)
const showCreateDialog = ref(false)

const filteredCases = computed(() => {
  return cases.value.filter(c => {
    if (filterScenario.value && c.scenario !== filterScenario.value) return false
    if (filterDifficulty.value && c.difficulty !== filterDifficulty.value) return false
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

const getScenarioLabel = (name) => {
  const s = scenarios.value.find(s => s.name === name)
  return s ? s.label : name
}

const difficultyType = (d) => ({ easy: 'success', medium: 'warning', hard: 'danger' }[d] || 'info')
const difficultyLabel = (d) => ({ easy: '简单', medium: '中等', hard: '困难' }[d] || d)

const openCaseDetail = (row) => {
  detailCase.value = row
  showDetail.value = true
}
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
  min-width: 130px;
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
  max-height: 200px;
  overflow-y: auto;
}
</style>
