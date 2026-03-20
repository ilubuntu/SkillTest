# Skill 测评系统 — 需求设计文档

## 1. 项目背景

团队正在为鸿蒙（HarmonyOS）ArkTS 开发编写一系列 **增强 Skill**（如 bug 修复 Skill、单元测试生成 Skill 等），用于挂载到 AI 编程 Agent（如 OpenCode 等闭源/开源编程工具）上，提升 Agent 的鸿蒙 ArkTS 编程能力。

**核心问题**：如何客观量化这些 Skill 的增益价值？

**解决方案**：构建一个 **评测系统**，通过标准化测试用例，对比 Agent 挂载 Skill 前后的代码输出质量，生成增益报告。

## 2. 系统定位

- **评测系统本身也以 Skill 形式实现**，即「评测 Skill」用于测试「业务 Skill」
- 首版本聚焦最小可行闭环，后续迭代扩展
- 评测对象是各类鸿蒙 ArkTS Skill，不是 Agent 本身

## 3. 架构概览

系统分三层（详见 `skill_mcp_test_architecture_v10.svg`）：

```
┌─────────────────────────────────────────────────────────┐
│ 评测系统层                                                │
│  测试用例集 → Test Runner → Evaluator → 测试报告          │
│                              ↑                           │
│                           评分标准                        │
└────────────────────┬──────────────┬──────────────────────┘
                     │ task prompt  │ 最终输出
┌────────────────────▼──────────────┴──────────────────────┐
│ Agent 层                                                  │
│  Skill A/B → 规划·调度 → 工具层 (MCP Server / 本地工具)    │
└─────────────────────────┬───────────────────────────────┘
                          │ 双向通信
┌─────────────────────────▼───────────────────────────────┐
│ LLM API 层                                               │
│  推理 · 生成代码 · 工具决策                                │
└─────────────────────────────────────────────────────────┘
```

## 4. 被测 Skill 类型

| Skill 类型 | 说明 | 示例场景 |
|-----------|------|---------|
| bug_fix | 修复 ArkTS 代码缺陷 | List 组件滑动崩溃、状态管理错误 |
| ut_gen | 生成单元测试用例 | 为组件/工具函数生成测试代码 |
| 后续扩展 | 代码重构、性能优化、API 迁移等 | — |

## 5. Agent 驱动方案

评测系统需要自动化驱动 Agent 执行测试用例。Agent 采用 OpenCode，需要保证：
- Agent 完整运行能力（调用工具、编译、循环修复等，与 TUI 中手动操作一致）
- 每个用例的上下文相互隔离

### 5.1 上下文一致性策略

| 层面 | 隔离方式 |
|------|---------|
| 对话历史 | 每个用例创建全新 session，无历史污染 |
| 文件系统 | 每个用例使用独立的项目目录（从模板复制） |
| 模型参数 | 固定 model 版本、temperature 等参数 |
| 随机性消除 | 每个用例跑 3 次取平均分 |

### 5.2 驱动方式选型

有两种方式驱动 OpenCode 执行任务：

**方案 A：`opencode run`（CLI 非交互模式）— 首版本推荐**

```bash
cd sandbox_001
opencode run "修复以下ArkTS代码..." -q -f json
```

- 每次调用是独立进程，天然隔离上下文
- `-q` 静默模式适合脚本自动化，`-f json` 输出结构化结果
- 缺点：每次冷启动，MCP Server 需要重新初始化

**方案 B：OpenCode SDK 编程控制 — 后续推荐**

通过 `opencode serve` 启动常驻实例，用 SDK 编程控制：

```javascript
import { createOpencode } from "@opencode-ai/sdk"
const { client } = await createOpencode()

// 每个用例创建新 session = 干净上下文
const session = await client.session.create({})
const result = await client.session.prompt({
  path: { id: session.id },
  body: { parts: [{ type: "text", text: "修复以下ArkTS代码..." }] }
})
```

- `opencode serve` 启动的是**完整的 OpenCode 实例**，Agent 在内部走完整的工具调用循环（规划 → 写代码 → 编译 → 修复 → 再编译），与 TUI 中手动操作能力完全一致
- SDK 只是控制会话的入口（创建会话、发消息、拿结果），不是替代 Agent 执行，相当于用代码替代手动在终端里打字，背后跑的是同一个东西
- 唯一区别是没有 TUI 界面，但可通过 `-f json` 拿完整执行日志，或 `event.subscribe()` 实时订阅事件流
- 优势：常驻进程复用 MCP Server 连接，避免冷启动开销

**两种方案对比：**

| | `opencode run` | SDK + serve |
|--|----------------|-------------|
| 上下文隔离 | 天然（独立进程） | 天然（独立 session） |
| 自动化难度 | 低，shell 脚本即可 | 中，需写 JS/TS 代码 |
| 性能 | 每次冷启动 | 常驻复用，启动快 |
| Agent 能力 | 完整（工具调用、循环修复） | 完整（与 TUI 一致） |

> OpenCode SDK 文档：https://opencode.ai/docs/sdk/
> OpenCode CLI 文档：https://opencode.ai/docs/cli/
> OpenCode Server 文档：https://opencode.ai/docs/server/

## 6. 评测流程

### 6.1 核心流程

```
对于每个测试用例:
  1. 基线运行：Agent 不挂载目标 Skill，执行任务 → 输出 A
  2. 增强运行：Agent 挂载目标 Skill，执行任务 → 输出 B
  3. 分别评分：对 A 和 B 按评分标准打分
  4. 计算增益：增强得分 - 基线得分 = Skill 增益

汇总所有用例 → 生成增益报告
```

### 6.2 评分维度

| 维度 | 权重(建议) | 说明 |
|------|-----------|------|
| 正确性 | 40% | 代码是否解决了问题 |
| 完整性 | 30% | 是否覆盖边界情况、异常处理 |
| 代码质量 | 30% | 是否符合 ArkTS 最佳实践、可读性 |

### 6.3 评分方式

- **规则匹配**（确定性）：关键代码片段 must_contain / must_not_contain
- **LLM-as-Judge**（灵活性）：基于 rubric 让 LLM 按维度打分
- **编译检查**（可选，后续版本）：调用本地工具验证编译通过

## 7. 测试用例格式

每个用例由一个 YAML 描述文件 + 关联代码文件组成：

```yaml
id: bug_fix_001
skill_type: bug_fix
title: "ArkTS List组件滑动崩溃修复"
input:
  description: "以下ArkTS代码在List组件快速滑动时会崩溃，请修复"
  code_file: cases/bug_fix_001/input.ets
expected:
  must_contain:
    - "cachedCount"
  must_not_contain:
    - "forEach"
  compile_check: false
  reference_file: cases/bug_fix_001/expected.ets
  rubric:
    - name: correctness
      weight: 40
      criteria: "是否修复了滑动崩溃问题"
    - name: completeness
      weight: 30
      criteria: "是否处理了边界情况"
    - name: code_quality
      weight: 30
      criteria: "代码是否符合ArkTS最佳实践"
```

## 8. 报告输出

评测报告应包含：

- **总览**：用例总数、通过率（基线 vs 增强）、整体增益百分比
- **逐用例明细**：每个用例的基线得分、增强得分、增益值
- **维度均分对比**：正确性/完整性/代码质量 各维度的前后对比
- **异常标记**：增益为负的用例需特别标注（Skill 可能引入退化）
- **输出格式**：JSON（机器可读）+ Markdown（人可读）

## 9. 目录结构

```
测评系统/
├── REQUIREMENTS.md                    # 本文档
├── skill_mcp_test_architecture_v10.svg # 架构图
├── eval_skill/
│   ├── skill.md                       # 评测 Skill 的 prompt 定义
│   ├── test_cases/
│   │   ├── bug_fix/
│   │   │   ├── 001.yaml
│   │   │   └── cases/001/
│   │   │       ├── input.ets
│   │   │       └── expected.ets
│   │   └── ut_gen/
│   │       ├── 001.yaml
│   │       └── cases/001/
│   │           ├── input.ets
│   │           └── expected_test.ets
│   ├── evaluator/
│   │   ├── rule_checker.py            # 规则评分
│   │   ├── llm_judge.py              # LLM-as-Judge 评分
│   │   └── compile_checker.py         # 编译检查（后续版本）
│   ├── runner/
│   │   └── agent_runner.py            # 驱动 Agent 执行任务
│   └── report/
│       └── reporter.py               # 生成报告
```

## 10. 首版本范围（MVP）

首版本只做到最小闭环：

- [ ] 手动准备 5-10 个测试用例（聚焦 1 种 Skill 类型，如 bug_fix）
- [ ] 评分：规则匹配 + LLM-as-Judge（暂不做编译检查）
- [ ] 支持基线 vs 增强 对比运行
- [ ] 输出 JSON + Markdown 格式的增益报告
- [ ] 整个评测系统以单个 Skill 形式交付，可被 Agent 直接调用

## 11. 后续迭代方向

- 接入编译检查（调用 ArkTS 编译工具链）
- 扩展更多 Skill 类型的测试用例
- 支持多 Agent 横向对比（同一用例跑不同 Agent）
- 支持 MCP Server 工具调用能力的评测
- 自动化批量运行 + CI 集成
- 可视化仪表盘
* 1. 1. 