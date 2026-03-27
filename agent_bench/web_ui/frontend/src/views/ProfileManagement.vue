<template>
  <div class="page-container">
    <!-- 工具栏 -->
    <div class="toolbar card">
      <div class="toolbar-left">
        <el-input v-model="searchText" placeholder="搜索 Profile" :prefix-icon="Search" clearable style="width: 240px;" />
        <el-checkbox v-model="showBaseline">显示基线配置</el-checkbox>
      </div>
      <div class="toolbar-right">
        <el-button type="primary" :icon="Plus" @click="showCreateDialog = true">新建 Profile</el-button>
        <el-button :icon="Connection">对比模式</el-button>
      </div>
    </div>

    <!-- Profile 卡片网格 -->
    <div class="profile-grid">
      <div
        v-for="profile in filteredProfiles"
        :key="profile.name"
        class="profile-card card"
        :class="{ baseline: profile.is_baseline }"
      >
        <div class="profile-card-header">
          <div class="profile-name">
            {{ profile.name }}
            <el-tag v-if="profile.is_baseline" type="info" size="small" class="baseline-tag">基线</el-tag>
          </div>
          <el-dropdown>
            <el-icon class="more-icon"><MoreFilled /></el-icon>
            <template #dropdown>
              <el-dropdown-menu>
                <el-dropdown-item>编辑</el-dropdown-item>
                <el-dropdown-item>复制</el-dropdown-item>
                <el-dropdown-item>对比</el-dropdown-item>
                <el-dropdown-item divided style="color: #f56c6c;">删除</el-dropdown-item>
              </el-dropdown-menu>
            </template>
          </el-dropdown>
        </div>

        <div class="profile-desc">{{ profile.description }}</div>

        <div class="profile-scenarios">
          <el-tag
            v-for="s in profile.scenarios"
            :key="s"
            size="small"
            type="primary"
            effect="plain"
            class="scenario-tag"
          >
            {{ s }}
          </el-tag>
          <span v-if="!profile.scenarios.length" class="no-scenario">无关联场景</span>
        </div>

        <!-- 增强配置摘要 -->
        <div class="enhancement-summary">
          <div class="enhance-item" :class="{ active: profile.enhancements?.skills?.length }">
            <el-icon><Document /></el-icon>
            <span>Skill</span>
            <span class="enhance-count">{{ profile.enhancements?.skills?.length || 0 }}</span>
          </div>
          <div class="enhance-item" :class="{ active: profile.enhancements?.system_prompt }">
            <el-icon><ChatDotRound /></el-icon>
            <span>System Prompt</span>
            <el-icon v-if="profile.enhancements?.system_prompt" class="check-icon"><Check /></el-icon>
          </div>
          <div class="enhance-item" :class="{ active: profile.enhancements?.mcp_servers?.length }">
            <el-icon><Connection /></el-icon>
            <span>MCP Server</span>
            <span class="enhance-count">{{ profile.enhancements?.mcp_servers?.length || 0 }}</span>
          </div>
          <div class="enhance-item" :class="{ active: profile.enhancements?.tools }">
            <el-icon><SetUp /></el-icon>
            <span>Tools</span>
            <el-icon v-if="profile.enhancements?.tools" class="check-icon"><Check /></el-icon>
          </div>
        </div>

        <div class="profile-footer">
          <span class="update-time">更新于 {{ profile.updated }}</span>
          <el-button type="primary" link size="small" @click="openDetail(profile)">
            查看详情
          </el-button>
        </div>
      </div>
    </div>

    <!-- Profile 详情抽屉 -->
    <el-drawer v-model="showDetail" :title="detailProfile?.name" size="600px">
      <template v-if="detailProfile">
        <el-descriptions :column="1" border>
          <el-descriptions-item label="名称">{{ detailProfile.name }}</el-descriptions-item>
          <el-descriptions-item label="描述">{{ detailProfile.description }}</el-descriptions-item>
          <el-descriptions-item label="基线标记">
            <el-tag :type="detailProfile.is_baseline ? 'warning' : 'info'" size="small">
              {{ detailProfile.is_baseline ? '是' : '否' }}
            </el-tag>
          </el-descriptions-item>
          <el-descriptions-item label="关联场景">
            <el-tag v-for="s in detailProfile.scenarios" :key="s" size="small" class="tag-item">{{ s }}</el-tag>
            <span v-if="!detailProfile.scenarios.length" style="color: #999;">无</span>
          </el-descriptions-item>
        </el-descriptions>

        <h4 style="margin: 24px 0 12px;">增强配置</h4>

        <el-collapse>
          <el-collapse-item title="Skills" name="skills">
            <div v-if="detailProfile.enhancements?.skills?.length">
              <div v-for="skill in detailProfile.enhancements.skills" :key="skill.name" class="skill-item">
                <el-icon><Document /></el-icon>
                <div>
                  <div class="skill-name">{{ skill.name }}</div>
                  <div class="skill-path">{{ skill.path }}</div>
                </div>
              </div>
            </div>
            <div v-else style="color: #999;">未配置 Skill</div>
          </el-collapse-item>

          <el-collapse-item title="System Prompt" name="system_prompt">
            <div v-if="detailProfile.enhancements?.system_prompt" class="code-block">
              {{ detailProfile.enhancements.system_prompt }}
            </div>
            <div v-else style="color: #999;">未配置 System Prompt</div>
          </el-collapse-item>

          <el-collapse-item title="MCP Servers" name="mcp">
            <div v-if="detailProfile.enhancements?.mcp_servers?.length">
              <el-descriptions
                v-for="mcp in detailProfile.enhancements.mcp_servers"
                :key="mcp.name"
                :column="1"
                border
                size="small"
                style="margin-bottom: 8px;"
              >
                <el-descriptions-item label="名称">{{ mcp.name }}</el-descriptions-item>
                <el-descriptions-item label="命令">{{ mcp.command }} {{ (mcp.args || []).join(' ') }}</el-descriptions-item>
              </el-descriptions>
            </div>
            <div v-else style="color: #999;">未配置 MCP Server</div>
          </el-collapse-item>

          <el-collapse-item title="Tools" name="tools">
            <div v-if="detailProfile.enhancements?.tools">
              <pre style="margin: 0; font-size: 13px;">{{ JSON.stringify(detailProfile.enhancements.tools, null, 2) }}</pre>
            </div>
            <div v-else style="color: #999;">未配置 Tools</div>
          </el-collapse-item>
        </el-collapse>
      </template>
    </el-drawer>

    <!-- 新建 Profile 弹窗 -->
    <el-dialog v-model="showCreateDialog" title="新建 Profile" width="700px">
      <el-form label-width="120px">
        <el-form-item label="Profile 名称">
          <el-input placeholder="如 bug_fix_enhanced" />
        </el-form-item>
        <el-form-item label="描述">
          <el-input type="textarea" :rows="2" placeholder="Profile 用途说明" />
        </el-form-item>
        <el-form-item label="关联场景">
          <el-select multiple placeholder="选择场景" style="width: 100%;">
            <el-option v-for="s in mockScenarios" :key="s.name" :label="s.label" :value="s.name" />
          </el-select>
        </el-form-item>
        <el-form-item label="标记为基线">
          <el-switch />
        </el-form-item>
        <el-divider content-position="left">增强配置</el-divider>
        <el-form-item label="Skill 文件">
          <el-upload action="#" :auto-upload="false">
            <el-button type="primary">选择 Skill 文件</el-button>
          </el-upload>
        </el-form-item>
        <el-form-item label="System Prompt">
          <el-input type="textarea" :rows="4" placeholder="Agent 系统提示词" />
        </el-form-item>
        <el-form-item label="MCP Server">
          <el-button :icon="Plus" size="small">添加 MCP Server</el-button>
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
import {
  Search, Plus, Connection, MoreFilled,
  Document, ChatDotRound, SetUp, Check
} from '@element-plus/icons-vue'
import { mockProfiles, mockScenarios } from '../mock/data'

const profiles = ref(mockProfiles)
const searchText = ref('')
const showBaseline = ref(true)
const showDetail = ref(false)
const detailProfile = ref(null)
const showCreateDialog = ref(false)

const filteredProfiles = computed(() => {
  return profiles.value.filter(p => {
    if (!showBaseline.value && p.is_baseline) return false
    if (searchText.value) {
      const q = searchText.value.toLowerCase()
      if (!p.name.toLowerCase().includes(q) && !p.description.toLowerCase().includes(q)) return false
    }
    return true
  })
})

const openDetail = (profile) => {
  detailProfile.value = profile
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

.profile-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(340px, 1fr));
  gap: 16px;
}

.profile-card {
  display: flex;
  flex-direction: column;
  gap: 12px;
  transition: transform 0.2s, box-shadow 0.2s;
}

.profile-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.08);
}

.profile-card.baseline {
  border: 1px dashed #dcdfe6;
}

.profile-card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.profile-name {
  font-size: 16px;
  font-weight: 600;
  color: #1a1a2e;
  display: flex;
  align-items: center;
  gap: 8px;
}

.baseline-tag {
  font-weight: 400;
}

.more-icon {
  cursor: pointer;
  color: #999;
  font-size: 18px;
}

.profile-desc {
  font-size: 13px;
  color: #666;
  line-height: 1.5;
}

.profile-scenarios {
  display: flex;
  gap: 6px;
  flex-wrap: wrap;
}

.scenario-tag {
  font-size: 12px;
}

.no-scenario {
  font-size: 12px;
  color: #ccc;
}

.enhancement-summary {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 8px;
  padding: 12px;
  background: #f8f9fb;
  border-radius: 8px;
}

.enhance-item {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 13px;
  color: #ccc;
  padding: 4px 0;
}

.enhance-item.active {
  color: #333;
}

.enhance-count {
  margin-left: auto;
  font-weight: 600;
  color: #667eea;
}

.check-icon {
  margin-left: auto;
  color: #67c23a;
}

.profile-footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding-top: 8px;
  border-top: 1px solid #f0f0f0;
}

.update-time {
  font-size: 12px;
  color: #999;
}

.tag-item {
  margin-right: 4px;
}

.skill-item {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 8px;
  border-radius: 6px;
  background: #f8f9fb;
  margin-bottom: 6px;
}

.skill-name {
  font-weight: 500;
  font-size: 14px;
}

.skill-path {
  font-size: 12px;
  color: #999;
  font-family: 'Consolas', monospace;
}

.code-block {
  background: #1e1e1e;
  color: #e0e0e0;
  border-radius: 8px;
  padding: 16px;
  font-family: 'Consolas', monospace;
  font-size: 13px;
  white-space: pre-wrap;
  max-height: 200px;
  overflow-y: auto;
}
</style>
