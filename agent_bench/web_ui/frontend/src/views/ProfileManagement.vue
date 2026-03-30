<template>
  <div class="page-container">
    <!-- 工具栏 -->
    <div class="toolbar card">
      <div class="toolbar-left">
        <el-input v-model="searchText" placeholder="搜索 Profile" :prefix-icon="Search" clearable style="width: 240px;" />
      </div>
      <div class="toolbar-right">
        <span class="profile-total">共 {{ filteredProfiles.length }} 个 Profile</span>
      </div>
    </div>

    <!-- Profile 卡片网格 -->
    <div class="profile-grid" v-loading="loading">
      <div
        v-for="profile in filteredProfiles"
        :key="profile.name"
        class="profile-card card"
        :class="{ baseline: !profile.enhancement_ids.length }"
      >
        <div class="profile-card-header">
          <div class="profile-name">
            {{ profile.name }}
            <el-tag v-if="!profile.enhancement_ids.length" type="info" size="small" class="baseline-tag">基线</el-tag>
          </div>
          <span class="profile-id">{{ profile.id }}</span>
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
          <div class="enhance-item" :class="{ active: profile.skills.length }">
            <el-icon><Document /></el-icon>
            <span>Skill</span>
            <span class="enhance-count">{{ profile.skills.length }}</span>
          </div>
          <div class="enhance-item" :class="{ active: profile.system_prompts.length }">
            <el-icon><ChatDotRound /></el-icon>
            <span>System Prompt</span>
            <span class="enhance-count">{{ profile.system_prompts.length }}</span>
          </div>
          <div class="enhance-item" :class="{ active: profile.mcp_servers.length }">
            <el-icon><Connection /></el-icon>
            <span>MCP Server</span>
            <span class="enhance-count">{{ profile.mcp_servers.length }}</span>
          </div>
        </div>

        <div class="profile-footer">
          <span class="profile-file">{{ profile.file }}</span>
          <el-button type="primary" link size="small" @click="openDetail(profile)">
            查看详情
          </el-button>
        </div>
      </div>
    </div>

    <!-- Profile 详情抽屉 -->
    <el-drawer v-model="showDetail" :title="detailProfile?.name" size="650px">
      <template v-if="detailProfile">
        <el-descriptions :column="1" border>
          <el-descriptions-item label="ID">{{ detailProfile.id }}</el-descriptions-item>
          <el-descriptions-item label="名称">{{ detailProfile.name }}</el-descriptions-item>
          <el-descriptions-item label="描述">{{ detailProfile.description }}</el-descriptions-item>
          <el-descriptions-item label="配置文件">
            <span class="mono">{{ detailProfile.file }}</span>
          </el-descriptions-item>
          <el-descriptions-item label="关联场景">
            <el-tag v-for="s in detailProfile.scenarios" :key="s" size="small" class="tag-item">{{ s }}</el-tag>
            <span v-if="!detailProfile.scenarios.length" style="color: #999;">无</span>
          </el-descriptions-item>
          <el-descriptions-item label="Enhancement IDs">
            <el-tag v-for="eid in detailProfile.enhancement_ids" :key="eid" size="small" type="info" class="tag-item">
              {{ eid }}
            </el-tag>
            <span v-if="!detailProfile.enhancement_ids.length" style="color: #999;">无</span>
          </el-descriptions-item>
        </el-descriptions>

        <h4 style="margin: 24px 0 12px;">增强配置详情</h4>

        <el-collapse v-model="activeCollapse">
          <!-- Skills -->
          <el-collapse-item title="Skills" name="skills">
            <template #title>
              <span>Skills</span>
              <el-tag size="small" type="info" style="margin-left: 8px;">{{ detailProfile.skills.length }}</el-tag>
            </template>
            <div v-if="detailProfile.skills.length">
              <div v-for="skill in detailProfile.skills" :key="skill.id" class="enhance-detail-item">
                <div class="enhance-detail-header">
                  <el-icon><Document /></el-icon>
                  <div>
                    <div class="enhance-detail-name">{{ skill.name }}</div>
                    <div class="enhance-detail-desc">{{ skill.description }}</div>
                    <div class="enhance-detail-path">{{ skill.path }}</div>
                  </div>
                </div>
                <div v-if="skill.content" class="code-block">{{ skill.content }}</div>
              </div>
            </div>
            <div v-else class="empty-hint">未配置 Skill</div>
          </el-collapse-item>

          <!-- System Prompts -->
          <el-collapse-item title="System Prompt" name="system_prompt">
            <template #title>
              <span>System Prompt</span>
              <el-tag size="small" type="info" style="margin-left: 8px;">{{ detailProfile.system_prompts.length }}</el-tag>
            </template>
            <div v-if="detailProfile.system_prompts.length">
              <div v-for="sp in detailProfile.system_prompts" :key="sp.id" class="enhance-detail-item">
                <div class="enhance-detail-header">
                  <el-icon><ChatDotRound /></el-icon>
                  <div>
                    <div class="enhance-detail-name">{{ sp.name }}</div>
                    <div class="enhance-detail-desc">{{ sp.description }}</div>
                    <div class="enhance-detail-path">{{ sp.path }}</div>
                  </div>
                </div>
                <div v-if="sp.content" class="code-block">{{ sp.content }}</div>
              </div>
            </div>
            <div v-else class="empty-hint">未配置 System Prompt</div>
          </el-collapse-item>

          <!-- MCP Servers -->
          <el-collapse-item title="MCP Servers" name="mcp">
            <template #title>
              <span>MCP Servers</span>
              <el-tag size="small" type="info" style="margin-left: 8px;">{{ detailProfile.mcp_servers.length }}</el-tag>
            </template>
            <div v-if="detailProfile.mcp_servers.length">
              <el-descriptions
                v-for="mcp in detailProfile.mcp_servers"
                :key="mcp.id"
                :column="1"
                border
                size="small"
                style="margin-bottom: 8px;"
              >
                <el-descriptions-item label="名称">{{ mcp.name }}</el-descriptions-item>
                <el-descriptions-item label="命令">{{ mcp.command }} {{ (mcp.args || []).join(' ') }}</el-descriptions-item>
              </el-descriptions>
            </div>
            <div v-else class="empty-hint">未配置 MCP Server</div>
          </el-collapse-item>
        </el-collapse>
      </template>
    </el-drawer>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { Search, Document, ChatDotRound, Connection } from '@element-plus/icons-vue'
import axios from 'axios'

const profiles = ref([])
const searchText = ref('')
const showDetail = ref(false)
const detailProfile = ref(null)
const loading = ref(false)
const activeCollapse = ref(['skills', 'system_prompt'])

const filteredProfiles = computed(() => {
  return profiles.value.filter(p => {
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

const loadData = async () => {
  loading.value = true
  try {
    const res = await axios.get('/api/profiles/detail')
    profiles.value = res.data
  } catch (e) {
    console.error('加载 Profile 数据失败:', e)
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

.profile-total {
  font-size: 13px;
  color: #999;
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

.profile-id {
  font-size: 11px;
  color: #bbb;
  font-family: 'Consolas', monospace;
}

.baseline-tag {
  font-weight: 400;
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
  grid-template-columns: 1fr 1fr 1fr;
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

.profile-footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding-top: 8px;
  border-top: 1px solid #f0f0f0;
}

.profile-file {
  font-size: 11px;
  color: #bbb;
  font-family: 'Consolas', monospace;
}

.tag-item {
  margin-right: 4px;
}

.mono {
  font-family: 'Consolas', monospace;
  font-size: 13px;
}

.enhance-detail-item {
  margin-bottom: 16px;
}

.enhance-detail-header {
  display: flex;
  align-items: flex-start;
  gap: 10px;
  margin-bottom: 8px;
}

.enhance-detail-name {
  font-weight: 600;
  font-size: 14px;
  color: #1a1a2e;
}

.enhance-detail-desc {
  font-size: 12px;
  color: #666;
  margin-top: 2px;
}

.enhance-detail-path {
  font-size: 11px;
  color: #999;
  font-family: 'Consolas', monospace;
  margin-top: 2px;
}

.code-block {
  background: #1e1e1e;
  color: #e0e0e0;
  border-radius: 8px;
  padding: 16px;
  font-family: 'Consolas', 'Monaco', monospace;
  font-size: 12px;
  white-space: pre-wrap;
  max-height: 300px;
  overflow-y: auto;
}

.empty-hint {
  color: #999;
  font-size: 13px;
}
</style>
