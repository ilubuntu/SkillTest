import { createRouter, createWebHistory } from 'vue-router'

const routes = [
  {
    path: '/',
    redirect: '/evaluation',
  },
  {
    path: '/cases',
    name: 'CaseManagement',
    component: () => import('../views/CaseManagement.vue'),
    meta: { title: '用例管理', icon: 'Document' },
  },
  {
    path: '/profiles',
    name: 'ProfileManagement',
    component: () => import('../views/ProfileManagement.vue'),
    meta: { title: 'Profile 配置', icon: 'Setting' },
  },
  {
    path: '/rubrics',
    name: 'RubricManagement',
    component: () => import('../views/RubricManagement.vue'),
    meta: { title: '评分标准', icon: 'Aim' },
  },
  {
    path: '/evaluation',
    name: 'EvaluationCenter',
    component: () => import('../views/EvaluationCenter.vue'),
    meta: { title: '评测中心', icon: 'VideoPlay' },
  },
  {
    path: '/reports',
    name: 'ReportView',
    component: () => import('../views/ReportView.vue'),
    meta: { title: '报告展示', icon: 'DataAnalysis' },
  },
]

const router = createRouter({
  history: createWebHistory(),
  routes,
})

export default router
