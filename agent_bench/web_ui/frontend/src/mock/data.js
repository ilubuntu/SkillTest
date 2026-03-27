/**
 * Mock 数据 — 前端页面开发用，后端接口就绪后替换为真实 API
 */

// ── 测试用例 ──────────────────────────────────────────────────
export const mockCases = [
  {
    id: 'bug_fix_001',
    title: '修复 List 组件滚动卡顿',
    scenario: 'bug_fix',
    difficulty: 'medium',
    tags: ['ArkTS', 'List', 'Performance'],
    status: 'active',
    updated: '2026-03-25',
    prompt: '以下代码存在 List 组件滚动卡顿问题，请修复...',
    input_code: '@Entry\n@Component\nstruct BuggyList {\n  build() {\n    List() {\n      ForEach(this.data, (item) => {\n        ListItem() { Text(item) }\n      })\n    }\n  }\n}',
    reference_code: '@Entry\n@Component\nstruct FixedList {\n  build() {\n    List() {\n      LazyForEach(this.dataSource, (item) => {\n        ListItem() { Text(item) }\n      })\n    }\n  }\n}',
    rubric: { correctness: 40, completeness: 30, code_quality: 30 },
    rules: {
      must_contain: ['LazyForEach', 'IDataSource'],
      must_not_contain: ['ForEach(this.data']
    }
  },
  {
    id: 'bug_fix_002',
    title: '修复状态管理内存泄漏',
    scenario: 'bug_fix',
    difficulty: 'hard',
    tags: ['ArkTS', 'State', 'Memory'],
    status: 'active',
    updated: '2026-03-24',
    prompt: '以下组件存在状态管理导致的内存泄漏...',
    input_code: '// ... bug code ...',
    reference_code: '// ... fixed code ...',
    rubric: { correctness: 50, completeness: 25, code_quality: 25 },
    rules: { must_contain: ['aboutToDisappear'], must_not_contain: [] }
  },
  {
    id: 'bug_fix_003',
    title: '修复 Navigation 路由跳转异常',
    scenario: 'bug_fix',
    difficulty: 'easy',
    tags: ['ArkTS', 'Navigation', 'Router'],
    status: 'active',
    updated: '2026-03-23',
    prompt: 'Navigation 组件路由跳转时参数丢失...',
    input_code: '// ... bug code ...',
    reference_code: '// ... fixed code ...',
    rubric: { correctness: 40, completeness: 30, code_quality: 30 },
    rules: { must_contain: ['NavPathStack'], must_not_contain: [] }
  },
  {
    id: 'project_gen_001',
    title: '生成待办事项应用',
    scenario: 'project_gen',
    difficulty: 'medium',
    tags: ['ArkTS', 'Project', 'Todo'],
    status: 'active',
    updated: '2026-03-22',
    prompt: '生成一个完整的待办事项 HarmonyOS 应用...',
    input_code: '',
    reference_code: '// ... reference project ...',
    rubric: { correctness: 30, completeness: 40, code_quality: 30 },
    rules: { must_contain: ['@Entry', '@Component', 'build()'], must_not_contain: [] }
  },
  {
    id: 'project_gen_002',
    title: '生成天气查询应用',
    scenario: 'project_gen',
    difficulty: 'hard',
    tags: ['ArkTS', 'Project', 'Network'],
    status: 'draft',
    updated: '2026-03-21',
    prompt: '生成天气查询应用，需要调用天气 API...',
    input_code: '',
    reference_code: '// ... reference project ...',
    rubric: { correctness: 30, completeness: 40, code_quality: 30 },
    rules: { must_contain: ['http', '@ohos.net'], must_not_contain: [] }
  },
  {
    id: 'compilable_001',
    title: 'ArkTS 基础组件编译',
    scenario: 'compilable',
    difficulty: 'easy',
    tags: ['ArkTS', 'Compile'],
    status: 'active',
    updated: '2026-03-20',
    prompt: '生成一个可编译通过的 ArkTS 页面组件...',
    input_code: '',
    reference_code: '// ...',
    rubric: { correctness: 50, completeness: 30, code_quality: 20 },
    rules: { must_contain: ['@Entry', '@Component'], must_not_contain: ['any'] }
  },
  {
    id: 'performance_001',
    title: 'List 长列表性能优化',
    scenario: 'performance',
    difficulty: 'hard',
    tags: ['ArkTS', 'Performance', 'List'],
    status: 'active',
    updated: '2026-03-19',
    prompt: '优化以下长列表的渲染性能...',
    input_code: '// ... slow list code ...',
    reference_code: '// ... optimized code ...',
    rubric: { correctness: 30, completeness: 30, code_quality: 40 },
    rules: { must_contain: ['LazyForEach', 'cachedCount'], must_not_contain: [] }
  },
  {
    id: 'performance_002',
    title: 'Swiper 组件性能优化',
    scenario: 'performance',
    difficulty: 'medium',
    tags: ['ArkTS', 'Performance', 'Swiper'],
    status: 'active',
    updated: '2026-03-18',
    prompt: '优化 Swiper 组件的滑动流畅度...',
    input_code: '// ... slow swiper ...',
    reference_code: '// ... optimized swiper ...',
    rubric: { correctness: 30, completeness: 30, code_quality: 40 },
    rules: { must_contain: ['cachedCount'], must_not_contain: [] }
  },
]

// ── 场景列表 ──────────────────────────────────────────────────
export const mockScenarios = [
  { name: 'bug_fix', label: 'Bug 修复', count: 3, color: '#e74c3c' },
  { name: 'project_gen', label: '工程生成', count: 2, color: '#3498db' },
  { name: 'compilable', label: '可编译', count: 2, color: '#2ecc71' },
  { name: 'performance', label: '性能优化', count: 2, color: '#f39c12' },
  { name: 'refactor', label: '重构', count: 0, color: '#9b59b6' },
  { name: 'test_gen', label: '测试生成', count: 0, color: '#1abc9c' },
  { name: 'requirement', label: '需求分析', count: 0, color: '#34495e' },
]

// ── Profile 配置 ──────────────────────────────────────────────
export const mockProfiles = [
  {
    name: 'baseline',
    description: '裸Agent，无任何增强配置',
    scenarios: [],
    is_baseline: true,
    enhancements: {},
    updated: '2026-03-20',
  },
  {
    name: 'bug_fix_enhanced',
    description: 'Bug修复增强配置：Skill + 定制化最佳实践',
    scenarios: ['bug_fix'],
    is_baseline: false,
    enhancements: {
      skills: [{ name: 'harmonyos_bug_fix', path: 'skills/harmonyos_bug_fix.md' }],
      system_prompt: '你是一位鸿蒙开发专家，擅长 ArkTS Bug 修复...',
      mcp_servers: [],
      tools: null,
    },
    updated: '2026-03-25',
  },
  {
    name: 'project_gen',
    description: '工程生成Skill：确保生成完整可运行的HarmonyOS项目',
    scenarios: ['project_gen'],
    is_baseline: false,
    enhancements: {
      skills: [{ name: 'harmonyos_project_gen', path: 'skills/harmonyos_project_gen.md' }],
      system_prompt: '',
      mcp_servers: [],
      tools: null,
    },
    updated: '2026-03-24',
  },
  {
    name: 'compilable',
    description: '可编译Skill：确保Agent生成的代码能通过ArkTS编译器检查',
    scenarios: ['compilable'],
    is_baseline: false,
    enhancements: {
      skills: [{ name: 'harmonyos_compilable', path: 'skills/harmonyos_compilable.md' }],
      system_prompt: '',
      mcp_servers: [{ name: 'arkts-lint', command: 'npx', args: ['arkts-lint-server'] }],
      tools: null,
    },
    updated: '2026-03-23',
  },
  {
    name: 'performance',
    description: '性能优化Skill：优化List和Swiper组件性能',
    scenarios: ['performance'],
    is_baseline: false,
    enhancements: {
      skills: [{ name: 'harmonyos_performance', path: 'skills/harmonyos_performance.md' }],
      system_prompt: '你是一位鸿蒙性能优化专家...',
      mcp_servers: [],
      tools: { profiler: true },
    },
    updated: '2026-03-22',
  },
]

// ── 评分标准 ──────────────────────────────────────────────────
export const mockRubrics = [
  {
    id: 'default',
    name: '默认评分模板',
    scenario: '通用',
    dimensions: [
      { name: 'correctness', label: '正确性', weight: 40, description: '代码是否正确解决了问题' },
      { name: 'completeness', label: '完整性', weight: 30, description: '是否覆盖了边界情况和异常处理' },
      { name: 'code_quality', label: '代码质量', weight: 30, description: '是否遵循 ArkTS 最佳实践，可读性' },
    ],
    rules: {
      must_contain: { enabled: true, description: '必须包含关键代码片段' },
      must_not_contain: { enabled: true, description: '不能包含反模式' },
      compilation_check: { enabled: false, description: '编译检查（未来版本）' },
    },
    updated: '2026-03-25',
  },
  {
    id: 'bug_fix',
    name: 'Bug修复评分模板',
    scenario: 'bug_fix',
    dimensions: [
      { name: 'correctness', label: '正确性', weight: 50, description: '是否正确修复了 Bug' },
      { name: 'completeness', label: '完整性', weight: 25, description: '是否处理了相关的边界情况' },
      { name: 'code_quality', label: '代码质量', weight: 25, description: '修复是否优雅，不引入新问题' },
    ],
    rules: {
      must_contain: { enabled: true, description: '必须包含修复关键代码' },
      must_not_contain: { enabled: true, description: '不能包含已知的错误模式' },
      compilation_check: { enabled: false, description: '编译检查（未来版本）' },
    },
    updated: '2026-03-24',
  },
  {
    id: 'project_gen',
    name: '工程生成评分模板',
    scenario: 'project_gen',
    dimensions: [
      { name: 'correctness', label: '正确性', weight: 30, description: '生成的项目结构是否正确' },
      { name: 'completeness', label: '完整性', weight: 40, description: '项目文件是否完整，可直接运行' },
      { name: 'code_quality', label: '代码质量', weight: 30, description: '代码风格和规范性' },
    ],
    rules: {
      must_contain: { enabled: true, description: '必须包含项目必要文件' },
      must_not_contain: { enabled: true, description: '不能包含非法导入' },
      compilation_check: { enabled: false, description: '编译检查（未来版本）' },
    },
    updated: '2026-03-23',
  },
  {
    id: 'performance',
    name: '性能优化评分模板',
    scenario: 'performance',
    dimensions: [
      { name: 'correctness', label: '正确性', weight: 30, description: '优化后功能是否正确' },
      { name: 'completeness', label: '完整性', weight: 30, description: '是否覆盖了所有性能瓶颈' },
      { name: 'code_quality', label: '代码质量', weight: 40, description: '是否使用了最佳性能实践' },
    ],
    rules: {
      must_contain: { enabled: true, description: '必须使用性能优化 API' },
      must_not_contain: { enabled: true, description: '不能使用性能反模式' },
      compilation_check: { enabled: false, description: '编译检查（未来版本）' },
    },
    updated: '2026-03-22',
  },
]

// ── 历史报告 ──────────────────────────────────────────────────
export const mockReports = [
  {
    run_id: '20260326_153000_bug_fix_enhanced',
    profile: 'bug_fix_enhanced',
    scenario: 'bug_fix',
    created: '2026-03-26 15:30:00',
    status: 'completed',
    summary: {
      total_cases: 3,
      baseline_avg: 4.8,
      enhanced_avg: 7.6,
      gain: 2.8,
      baseline_pass_rate: '1/3',
      enhanced_pass_rate: '3/3',
      dimensions: {
        correctness: { baseline_avg: 4.5, enhanced_avg: 8.0, gain: 3.5 },
        completeness: { baseline_avg: 5.0, enhanced_avg: 7.2, gain: 2.2 },
        code_quality: { baseline_avg: 5.0, enhanced_avg: 7.5, gain: 2.5 },
      },
    },
    cases: [
      { case_id: 'bug_fix_001', title: '修复 List 组件滚动卡顿', baseline_total: 4.0, enhanced_total: 8.5, gain: 4.5, regression: false },
      { case_id: 'bug_fix_002', title: '修复状态管理内存泄漏', baseline_total: 5.5, enhanced_total: 7.0, gain: 1.5, regression: false },
      { case_id: 'bug_fix_003', title: '修复 Navigation 路由跳转异常', baseline_total: 5.0, enhanced_total: 7.2, gain: 2.2, regression: false },
    ],
  },
  {
    run_id: '20260325_100000_project_gen',
    profile: 'project_gen',
    scenario: 'project_gen',
    created: '2026-03-25 10:00:00',
    status: 'completed',
    summary: {
      total_cases: 2,
      baseline_avg: 3.5,
      enhanced_avg: 7.0,
      gain: 3.5,
      baseline_pass_rate: '0/2',
      enhanced_pass_rate: '2/2',
      dimensions: {
        correctness: { baseline_avg: 3.0, enhanced_avg: 7.0, gain: 4.0 },
        completeness: { baseline_avg: 3.5, enhanced_avg: 7.5, gain: 4.0 },
        code_quality: { baseline_avg: 4.0, enhanced_avg: 6.5, gain: 2.5 },
      },
    },
    cases: [
      { case_id: 'project_gen_001', title: '生成待办事项应用', baseline_total: 4.0, enhanced_total: 7.5, gain: 3.5, regression: false },
      { case_id: 'project_gen_002', title: '生成天气查询应用', baseline_total: 3.0, enhanced_total: 6.5, gain: 3.5, regression: false },
    ],
  },
  {
    run_id: '20260324_140000_performance',
    profile: 'performance',
    scenario: 'performance',
    created: '2026-03-24 14:00:00',
    status: 'completed',
    summary: {
      total_cases: 2,
      baseline_avg: 5.0,
      enhanced_avg: 8.0,
      gain: 3.0,
      baseline_pass_rate: '1/2',
      enhanced_pass_rate: '2/2',
      dimensions: {
        correctness: { baseline_avg: 5.5, enhanced_avg: 8.0, gain: 2.5 },
        completeness: { baseline_avg: 4.5, enhanced_avg: 7.5, gain: 3.0 },
        code_quality: { baseline_avg: 5.0, enhanced_avg: 8.5, gain: 3.5 },
      },
    },
    cases: [
      { case_id: 'performance_001', title: 'List 长列表性能优化', baseline_total: 4.5, enhanced_total: 8.5, gain: 4.0, regression: false },
      { case_id: 'performance_002', title: 'Swiper 组件性能优化', baseline_total: 5.5, enhanced_total: 7.5, gain: 2.0, regression: false },
    ],
  },
  {
    run_id: '20260323_090000_compilable',
    profile: 'compilable',
    scenario: 'compilable',
    created: '2026-03-23 09:00:00',
    status: 'completed',
    summary: {
      total_cases: 2,
      baseline_avg: 6.0,
      enhanced_avg: 8.5,
      gain: 2.5,
      baseline_pass_rate: '1/2',
      enhanced_pass_rate: '2/2',
      dimensions: {
        correctness: { baseline_avg: 6.0, enhanced_avg: 9.0, gain: 3.0 },
        completeness: { baseline_avg: 6.0, enhanced_avg: 8.0, gain: 2.0 },
        code_quality: { baseline_avg: 6.0, enhanced_avg: 8.5, gain: 2.5 },
      },
    },
    cases: [
      { case_id: 'compilable_001', title: 'ArkTS 基础组件编译', baseline_total: 6.5, enhanced_total: 9.0, gain: 2.5, regression: false },
      { case_id: 'compilable_002', title: 'ArkTS 网络模块编译', baseline_total: 5.5, enhanced_total: 8.0, gain: 2.5, regression: false },
    ],
  },
]

// ── 趋势数据（多次评测历史） ──────────────────────────────────
export const mockTrendData = [
  { date: '03-20', baseline: 3.2, enhanced: 5.5 },
  { date: '03-21', baseline: 3.5, enhanced: 6.0 },
  { date: '03-22', baseline: 3.8, enhanced: 6.8 },
  { date: '03-23', baseline: 4.0, enhanced: 7.2 },
  { date: '03-24', baseline: 4.2, enhanced: 7.5 },
  { date: '03-25', baseline: 4.5, enhanced: 7.8 },
  { date: '03-26', baseline: 4.8, enhanced: 8.0 },
]
