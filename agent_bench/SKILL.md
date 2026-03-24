---
name: skill-eval
description: >
  鸿蒙 ArkTS Skill 增益评测系统。用于测量业务 Skill、MCP Tool、System Prompt
  对 Agent 代码质量的提升效果。
  当用户想要测试某个增强手段是否有效、运行基线与增强的 A/B 对比、生成增益报告时触发此 Skill。
  触发关键词："评测"、"测评"、"增益"、"基线对比"、"skill benchmark"、
  "这个 skill 有没有用"、"skill 效果怎么样"、"跑一下评测"。
---

# Skill 评测系统

量化各种增强手段（Skill、MCP Tool、System Prompt）对 Agent 鸿蒙 ArkTS 编程能力的实际提升效果。

## 为什么需要这个系统

团队编写了各种增强手段来提升 Agent 的 ArkTS 编码能力，包括：
- **Skill** — 领域知识/最佳实践，以文本形式注入 prompt
- **MCP Tool** — 外部工具能力（编译检查、lint、API 查询等），通过 MCP Server 挂载
- **System Prompt** — Agent 的行为定义/人设，通过 -s 参数注入

没有客观测量就无法判断这些手段到底是有帮助、没效果、还是反而有害。
这个评测系统对同一个任务分别跑"无增强"和"有增强"两次，对两份输出打分，
生成增益报告——用数据说话。

## 支持的评测类型

| 评测类型 | 基线运行 | 增强运行 | 差异点 |
|---------|---------|---------|-------|
| **skill** | `claude -p "任务"` | `claude -p "Skill内容 + 任务"` | prompt 里加不加 Skill 文本 |
| **mcp_tool** | `claude -p "任务"` | `claude -p "任务" --mcp-config xxx.json` | 挂不挂 MCP Server |
| **system_prompt** | `claude -p "任务"` | `claude -p "任务" -s "system prompt"` | 有没有 system prompt |

## 工作原理

对每个测试用例，系统启动两个独立的 `claude -p` 进程（无共享上下文），然后对两份输出分别评分：

```
测试用例
  ├─ 基线运行（Agent 单独执行，无增强）       → 输出 A
  ├─ 增强运行（Agent + 被测对象）             → 输出 B
  │
  ├─ 规则检查（must_contain / must_not_contain）  → 确定性评分
  ├─ LLM 评委（正确性 / 完整性 / 代码质量）      → LLM 评分
  │
  └─ 增益 = 增强得分 − 基线得分
```

单个用例最终得分 = 30% 规则分 + 70% LLM 分。

## 运行评测

```bash
cd eval_skill

# 正式运行 - 调用 Agent 执行所有用例（每个用例约 1 分钟）
python3 run_eval.py

# 干跑模式 - 验证流程，不调用 Agent
python3 run_eval.py --dry-run

# 指定测试套件
python3 run_eval.py --suite bug_fix

# 只运行指定评测类型的用例
python3 run_eval.py --suite bug_fix --eval-type skill
python3 run_eval.py --suite bug_fix --eval-type mcp_tool
python3 run_eval.py --suite bug_fix --eval-type system_prompt
```

报告输出在 `report/output/` 目录下：
- `report.md` — 可读的表格报告，包含逐用例和逐维度对比
- `report.json` — 机器可读的完整结果数据

## 如何解读报告

报告分三部分：

1. **总览** — 基线 vs 增强的平均得分、通过率、整体增益
2. **维度对比** — 正确性/完整性/代码质量三个维度的均分对比
3. **用例明细** — 每个用例的具体得分和增益，负增益标记为退化

增益为正说明增强手段有效。增益接近零说明对该场景没有价值。增益为负说明让输出变差了，需要修改。

## 评分细节

### 规则评分（权重 30%）

按测试用例定义的关键词做确定性检查：

- `must_contain` — 输出中必须包含的代码模式（如 `LazyForEach`、`clearInterval`）
- `must_not_contain` — 输出中不应出现的错误模式（如 `ForEach(this.items`）

得分 = 通过规则数 / 总规则数 × 100。同样的输入永远产生同样的分数。

### LLM 评委评分（权重 70%）

通过单独的 `claude -p` 调用，让 LLM 充当代码评审专家，按三个维度对输出打分：

| 维度 | 权重 | 评估内容 |
|------|------|---------|
| 正确性 (correctness) | 40% | 代码是否真正解决了问题 |
| 完整性 (completeness) | 30% | 是否覆盖了边界情况和异常处理 |
| 代码质量 (code_quality) | 30% | 是否符合 ArkTS 最佳实践 |

评委能看到：原始有 bug 的代码、参考答案、以及待评估的输出。返回带评分理由的结构化 JSON。

## 添加测试用例

每个测试用例由一个 JSON 定义文件 + 关联代码文件组成：

```
test_cases/bug_fix/
├── 001.json                  # 用例定义
└── cases/001/
    ├── input.ets             # 有 bug 的代码（交给 Agent）
    └── expected.ets          # 参考修复（评委参考用）
```

**JSON 格式：**

```json
{
  "id": "bug_fix_001",
  "eval_type": "skill",
  "subject": "bug_fix",
  "skill_type": "bug_fix",
  "title": "用例标题",
  "input": {
    "description": "交给 Agent 的任务描述",
    "code_file": "cases/001/input.ets"
  },
  "expected": {
    "must_contain": ["关键词1", "关键词2"],
    "must_not_contain": ["错误模式"],
    "reference_file": "cases/001/expected.ets",
    "rubric": [
      {"name": "correctness",  "weight": 40, "criteria": "评分标准描述"},
      {"name": "completeness", "weight": 30, "criteria": "评分标准描述"},
      {"name": "code_quality", "weight": 30, "criteria": "评分标准描述"}
    ]
  }
}
```

**关键字段说明：**

| 字段 | 说明 | 可选值 |
|------|------|-------|
| `eval_type` | 评测类型 | `skill`、`mcp_tool`、`system_prompt` |
| `subject` | 被测对象名称 | 对应 `skills/{name}.md`、`mcp_configs/{name}.json`、`prompts/{name}.md` |

## 添加被测对象

### Skill

将 Skill 的 markdown 文件放到 `skills/{name}.md`。

### MCP Tool

将 Claude Code 格式的 MCP 配置放到 `mcp_configs/{name}.json`：

```json
{
  "mcpServers": {
    "tool-name": {
      "command": "node",
      "args": ["/path/to/server.js"],
      "env": {}
    }
  }
}
```

### System Prompt

将 system prompt 文本放到 `prompts/{name}.md`。

## 上下文隔离

每次 `claude -p` 调用都是独立的操作系统进程，没有共享的对话历史。
基线和增强的唯一区别是有没有被测对象（Skill 文本 / MCP 工具 / System Prompt）。
这保证了对比的公平性——同样的任务、同样的代码、同样的模型，只有增强手段不同。

## 目录结构