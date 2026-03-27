<template>
  <div class="page-container">
    <!-- 工具栏 -->
    <div class="toolbar card">
      <div class="toolbar-left">
        <el-select v-model="filterScenario" placeholder="全部场景" clearable style="width: 160px;">
          <el-option label="通用" value="通用" />
          <el-option label="bug_fix" value="bug_fix" />
          <el-option label="project_gen" value="project_gen" />
          <el-option label="performance" value="performance" />
        </el-select>
      </div>
      <div class="toolbar-right">
        <el-button type="primary" :icon="Plus" @click="showCreateDialog = true">新建评分模板</el-button>
      </div>
    </div>

    <!-- 评分模板列表 -->
    <div class="rubric-grid">
      <div
        v-for="rubric in filteredRubrics"
        :key="rubric.id"
        class="rubric-card card"
      >
        <div class="rubric-header">
          <div>
            <div class="rubric-name">{{ rubric.name }}</div>
            <el-tag size="small" type="info">{{ rubric.scenario }}</el-tag>
          </div>
          <el-dropdown>
            <el-icon class="more-icon"><MoreFilled /></el-icon>
            <template #dropdown>
              <el-dropdown-menu>
                <el-dropdown-item>编辑</el-dropdown-item>
                <el-dropdown-item>复制</el-dropdown-item>
                <el-dropdown-item divided style="color: #f56c6c;">删除</el-dropdown-item>
              </el-dropdown-menu>
            </template>
          </el-dropdown>
        </div>

        <!-- 评分维度 -->
        <h4 class="section-title">评分维度</h4>
        <div class="dimension-list">
          <div v-for="dim in rubric.dimensions" :key="dim.name" class="dimension-item">
            <div class="dim-header">
              <span class="dim-name">{{ dim.label }}</span>
              <span class="dim-weight">{{ dim.weight }}%</span>
            </div>
            <el-progress
              :percentage="dim.weight"
              :stroke-width="6"
              :show-text="false"
              :color="getWeightColor(dim.weight)"
            />
            <div class="dim-desc">{{ dim.description }}</div>
          </div>
        </div>

        <!-- 规则匹配 -->
        <h4 class="section-title">规则检查</h4>
        <div class="rule-list">
          <div v-for="(rule, key) in rubric.rules" :key="key" class="rule-item">
            <div class="rule-header">
              <el-icon :class="{ 'rule-enabled': rule.enabled, 'rule-disabled': !rule.enabled }">
                <component :is="rule.enabled ? 'CircleCheck' : 'CircleClose'" />
              </el-icon>
              <span class="rule-name">{{ ruleLabel(key) }}</span>
              <el-tag :type="rule.enabled ? 'success' : 'info'" size="small">
                {{ rule.enabled ? '启用' : '未启用' }}
              </el-tag>
            </div>
            <div class="rule-desc">{{ rule.description }}</div>
          </div>
        </div>

        <div class="rubric-footer">
          <span class="update-time">更新于 {{ rubric.updated }}</span>
        </div>
      </div>
    </div>

    <!-- 评分体系说明 -->
    <div class="card scoring-guide">
      <h3 style="margin-bottom: 16px;">评分体系说明</h3>
      <div class="guide-diagram">
        <div class="guide-box rubric-box">
          <div class="guide-box-title">评分标准 (Rubric)</div>
          <div class="guide-box-desc">维度 / 权重 / 评判标准</div>
        </div>
        <div class="guide-arrow">+</div>
        <div class="guide-box rule-box">
          <div class="guide-box-title">内部打分系统</div>
          <div class="guide-box-desc">规则匹配 / 编译检查</div>
        </div>
        <div class="guide-arrow">=</div>
        <div class="guide-box judge-box">
          <div class="guide-box-title">LLM Judge</div>
          <div class="guide-box-desc">综合评分 (0-10)</div>
        </div>
      </div>
      <div class="guide-notes">
        <div class="guide-note">
          <strong>评分标准</strong>定义如何评判，通过本页面管理维度、权重和评判描述。
        </div>
        <div class="guide-note">
          <strong>内部打分系统</strong>执行自动化确定性检查，结果作为 LLM Judge 的参考输入。
        </div>
        <div class="guide-note">
          <strong>LLM Judge</strong>接收评分标准 + 内部打分结果 + Agent输出代码，按维度评分。使用独立模型，避免"自己给自己打分"。
        </div>
      </div>
    </div>

    <!-- 新建模板弹窗 -->
    <el-dialog v-model="showCreateDialog" title="新建评分模板" width="700px">
      <el-form label-width="100px">
        <el-form-item label="模板名称">
          <el-input placeholder="如 Bug修复评分模板" />
        </el-form-item>
        <el-form-item label="适用场景">
          <el-select placeholder="选择场景" style="width: 100%;">
            <el-option label="通用" value="通用" />
            <el-option label="bug_fix" value="bug_fix" />
            <el-option label="project_gen" value="project_gen" />
            <el-option label="performance" value="performance" />
            <el-option label="compilable" value="compilable" />
          </el-select>
        </el-form-item>
        <el-divider content-position="left">评分维度</el-divider>
        <div class="dim-edit-list">
          <div v-for="(dim, idx) in newDimensions" :key="idx" class="dim-edit-row">
            <el-input v-model="dim.label" placeholder="维度名称" style="width: 120px;" />
            <el-input-number v-model="dim.weight" :min="0" :max="100" style="width: 120px;" />
            <span>%</span>
            <el-input v-model="dim.description" placeholder="评判描述" />
            <el-button :icon="Delete" circle size="small" type="danger" @click="newDimensions.splice(idx, 1)" />
          </div>
        </div>
        <el-button :icon="Plus" size="small" style="margin-top: 8px;" @click="addDimension">
          添加维度
        </el-button>
        <div class="weight-total" :class="{ error: weightTotal !== 100 }">
          权重合计: {{ weightTotal }}% {{ weightTotal !== 100 ? '(需等于100%)' : '' }}
        </div>
      </el-form>
      <template #footer>
        <el-button @click="showCreateDialog = false">取消</el-button>
        <el-button type="primary" @click="showCreateDialog = false" :disabled="weightTotal !== 100">保存</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import {
  Plus, MoreFilled, CircleCheck, CircleClose, Delete
} from '@element-plus/icons-vue'
import { mockRubrics } from '../mock/data'

const rubrics = ref(mockRubrics)
const filterScenario = ref('')
const showCreateDialog = ref(false)

const newDimensions = ref([
  { label: '正确性', weight: 40, description: '代码是否正确解决了问题' },
  { label: '完整性', weight: 30, description: '是否覆盖了边界情况' },
  { label: '代码质量', weight: 30, description: '是否遵循最佳实践' },
])

const weightTotal = computed(() => newDimensions.value.reduce((sum, d) => sum + d.weight, 0))

const addDimension = () => {
  newDimensions.value.push({ label: '', weight: 0, description: '' })
}

const filteredRubrics = computed(() => {
  if (!filterScenario.value) return rubrics.value
  return rubrics.value.filter(r => r.scenario === filterScenario.value)
})

const getWeightColor = (w) => {
  if (w >= 40) return '#667eea'
  if (w >= 30) return '#764ba2'
  return '#a78bfa'
}

const ruleLabel = (key) => ({
  must_contain: '必须包含',
  must_not_contain: '不能包含',
  compilation_check: '编译检查',
}[key] || key)
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
}

.toolbar-left, .toolbar-right {
  display: flex;
  align-items: center;
  gap: 10px;
}

.rubric-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(380px, 1fr));
  gap: 16px;
}

.rubric-card {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.rubric-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
}

.rubric-name {
  font-size: 16px;
  font-weight: 600;
  color: #1a1a2e;
  margin-bottom: 4px;
}

.more-icon {
  cursor: pointer;
  color: #999;
  font-size: 18px;
}

.section-title {
  font-size: 14px;
  color: #666;
  margin: 16px 0 8px;
  font-weight: 500;
}

.dimension-list {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.dimension-item {
  padding: 10px 12px;
  background: #f8f9fb;
  border-radius: 8px;
}

.dim-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 6px;
}

.dim-name {
  font-weight: 500;
  font-size: 14px;
}

.dim-weight {
  font-weight: 700;
  color: #667eea;
  font-size: 15px;
}

.dim-desc {
  font-size: 12px;
  color: #999;
  margin-top: 6px;
}

.rule-list {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.rule-item {
  padding: 8px 12px;
  background: #f8f9fb;
  border-radius: 8px;
}

.rule-header {
  display: flex;
  align-items: center;
  gap: 8px;
}

.rule-enabled {
  color: #67c23a;
}

.rule-disabled {
  color: #ccc;
}

.rule-name {
  font-size: 14px;
  font-weight: 500;
}

.rule-desc {
  font-size: 12px;
  color: #999;
  margin-top: 4px;
  margin-left: 24px;
}

.rubric-footer {
  padding-top: 12px;
  border-top: 1px solid #f0f0f0;
  margin-top: 8px;
}

.update-time {
  font-size: 12px;
  color: #999;
}

/* 评分体系说明 */
.scoring-guide h3 {
  color: #1a1a2e;
}

.guide-diagram {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 16px;
  margin: 20px 0;
  flex-wrap: wrap;
}

.guide-box {
  padding: 20px 24px;
  border-radius: 12px;
  text-align: center;
  min-width: 180px;
}

.guide-box-title {
  font-weight: 600;
  font-size: 15px;
  margin-bottom: 4px;
}

.guide-box-desc {
  font-size: 12px;
  opacity: 0.8;
}

.rubric-box {
  background: linear-gradient(135deg, #667eea20, #667eea40);
  color: #3b5998;
}

.rule-box {
  background: linear-gradient(135deg, #2ecc7120, #2ecc7140);
  color: #27ae60;
}

.judge-box {
  background: linear-gradient(135deg, #f39c1220, #f39c1240);
  color: #e67e22;
}

.guide-arrow {
  font-size: 24px;
  font-weight: 700;
  color: #ccc;
}

.guide-notes {
  display: flex;
  flex-direction: column;
  gap: 8px;
  margin-top: 16px;
}

.guide-note {
  font-size: 13px;
  color: #666;
  line-height: 1.6;
  padding-left: 12px;
  border-left: 3px solid #667eea;
}

/* 新建弹窗 */
.dim-edit-list {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.dim-edit-row {
  display: flex;
  align-items: center;
  gap: 8px;
}

.weight-total {
  margin-top: 12px;
  font-size: 14px;
  font-weight: 500;
  color: #67c23a;
}

.weight-total.error {
  color: #f56c6c;
}
</style>
