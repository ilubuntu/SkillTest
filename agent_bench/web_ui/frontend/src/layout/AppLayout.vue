<template>
  <el-container class="app-layout">
    <!-- 侧边栏 -->
    <el-aside :width="isCollapsed ? '64px' : '220px'" class="app-aside">
      <div class="logo-area" @click="isCollapsed = !isCollapsed">
        <span class="logo-icon">H</span>
        <span v-if="!isCollapsed" class="logo-text">Agent Bench</span>
      </div>
      <el-menu
        :default-active="currentRoute"
        :collapse="isCollapsed"
        :collapse-transition="false"
        router
        class="side-menu"
      >
        <el-menu-item index="/cases">
          <el-icon><Document /></el-icon>
          <template #title>用例管理</template>
        </el-menu-item>
        <el-menu-item index="/profiles">
          <el-icon><Setting /></el-icon>
          <template #title>Profile 配置</template>
        </el-menu-item>
        <el-menu-item index="/rubrics">
          <el-icon><Aim /></el-icon>
          <template #title>评分标准</template>
        </el-menu-item>
        <el-menu-item index="/evaluation">
          <el-icon><VideoPlay /></el-icon>
          <template #title>评测中心</template>
        </el-menu-item>
        <el-menu-item index="/reports">
          <el-icon><DataAnalysis /></el-icon>
          <template #title>报告展示</template>
        </el-menu-item>
        <div class="menu-divider" v-if="!isCollapsed"></div>
        <el-menu-item index="/about">
          <el-icon><InfoFilled /></el-icon>
          <template #title>关于系统</template>
        </el-menu-item>
      </el-menu>
    </el-aside>

    <!-- 主区域 -->
    <el-container class="main-container">
      <el-header class="app-header">
        <div class="header-left">
          <h2 class="page-title">{{ currentTitle }}</h2>
        </div>
        <div class="header-right">
          <span class="system-name">鸿蒙开发工具评测系统</span>
        </div>
      </el-header>
      <el-main class="app-main">
        <router-view />
      </el-main>
    </el-container>
  </el-container>
</template>

<script setup>
import { ref, computed } from 'vue'
import { useRoute } from 'vue-router'
import {
  Document, Setting, Aim, VideoPlay, DataAnalysis, InfoFilled
} from '@element-plus/icons-vue'

const route = useRoute()
const isCollapsed = ref(false)

const currentRoute = computed(() => route.path)

const titleMap = {
  '/cases': '用例管理',
  '/profiles': 'Profile 配置管理',
  '/rubrics': '评分标准管理',
  '/evaluation': '评测中心',
  '/reports': '报告展示',
  '/about': '关于系统',
}
const currentTitle = computed(() => titleMap[route.path] || '评测系统')
</script>

<style scoped>
.app-layout {
  height: 100vh;
  background: #f0f2f5;
}

.app-aside {
  background: linear-gradient(180deg, #1a1a2e 0%, #16213e 50%, #0f3460 100%);
  transition: width 0.3s;
  overflow: hidden;
}

.logo-area {
  height: 64px;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 10px;
  cursor: pointer;
  border-bottom: 1px solid rgba(255, 255, 255, 0.08);
}

.logo-icon {
  width: 36px;
  height: 36px;
  background: linear-gradient(135deg, #667eea, #764ba2);
  border-radius: 8px;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #fff;
  font-weight: 700;
  font-size: 18px;
  flex-shrink: 0;
}

.logo-text {
  color: #fff;
  font-size: 16px;
  font-weight: 600;
  white-space: nowrap;
}

.side-menu {
  border-right: none;
  background: transparent;
}

.side-menu .el-menu-item {
  color: rgba(255, 255, 255, 0.7);
  height: 50px;
  line-height: 50px;
}

.side-menu .el-menu-item:hover {
  background: rgba(255, 255, 255, 0.08);
  color: #fff;
}

.side-menu .el-menu-item.is-active {
  background: linear-gradient(90deg, rgba(102, 126, 234, 0.3), transparent);
  color: #667eea;
  border-right: 3px solid #667eea;
}

.main-container {
  display: flex;
  flex-direction: column;
}

.app-header {
  height: 64px;
  background: #fff;
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0 24px;
  box-shadow: 0 1px 4px rgba(0, 0, 0, 0.08);
  z-index: 10;
}

.page-title {
  font-size: 20px;
  font-weight: 600;
  color: #1a1a2e;
  margin: 0;
}

.system-name {
  font-size: 13px;
  color: #999;
}

.app-main {
  padding: 20px;
  overflow-y: auto;
  background: #f0f2f5;
}

.menu-divider {
  height: 1px;
  background: rgba(255, 255, 255, 0.08);
  margin: 8px 16px;
}
</style>

<style>
/* 全局覆盖 el-menu 的折叠样式 */
.side-menu.el-menu--collapse .el-menu-item {
  padding: 0 20px !important;
}
</style>
