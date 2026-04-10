---
name: harmonyos-gen-code-evaluator
description: >
  评价 HarmonyOS NEXT 生成代码质量的评分 skill。用户让你评审鸿蒙 / HarmonyOS / ArkTS /
  ArkUI 工程代码、原始工程、git diff、增量开发结果或 Bug 修复结果时都应使用。先识别输入是完整工程生成、续写/增量开发还是
  Bug 修复，再读取对应评分参考与规则集，结合 HarmonyOS / ArkTS 规范输出结构化评分报告。
---

# HarmonyOS NEXT 生成代码评分

用于对 HarmonyOS NEXT 大模型生成代码做**工程质量评分**，而不是功能验收。

## 你要完成的事

1. 识别评审对象与任务类型。
2. 按任务类型读取对应评分参考。
3. 结合规则集检查明显违规项。

4. 采用统一固定的评测结果 schema，**生成可上报服务器的 JSON 结果文件**，无需生成其他任何总结性报告。

## 输入识别

优先把用户提供的内容归类成以下对象：

- **原始工程代码**：完整工程目录、模块目录、文件集合。
- **变更型输入**：git diff、patch、若干改动文件。
- **对照输入**：continuation / bug_fix 场景下的参考工程、原始工程或未修改版本。

再将每个对象判定为以下任务类型之一：

- **full_generation**：新生成完整工程、模块或成体系代码。
- **continuation**：在既有工程上继续写代码、接入页面/模块、做增量开发。
- **bug_fix**：围绕某个缺陷做修复，重点看命中度、最小侵入和回归风险。

如果用户没有明确说明任务类型，就根据输入形式和任务描述推断。

## 参考读取规则

只读取当前任务真正需要的参考文件，避免把三套 rubric 混在一起：

- `references/full_generation_rubric.md`
- `references/continuation_rubric.md`
- `references/bug_fix_rubric.md`
- `references/rules_application.md`
- `references/report_result_schema.json`
- `references/rubric.yaml`
- `references/arkts_internal_rules.yaml`

### 读取策略

- 判断为 `full_generation` 时，优先读取 `references/full_generation_rubric.md`，并在需要核对权重、硬门槛、人工复核规则时读取 `references/rubric.yaml`。
- 判断为 `continuation` 时，优先读取 `references/continuation_rubric.md`，并在需要核对权重、硬门槛、人工复核规则时读取 `references/rubric.yaml`。
- 判断为 `bug_fix` 时，优先读取 `references/bug_fix_rubric.md`，并在需要核对权重、硬门槛、人工复核规则时读取 `references/rubric.yaml`。
- 只要涉及 HarmonyOS / ArkTS / ArkUI 规范符合度判断，都要读 `references/rules_application.md`。
- 只要执行规则命中检查、规则违规标记、must / should / forbidden 判定，都要读取 `references/arkts_internal_rules.yaml`。
- 生成最终结果时，读取 `references/report_result_schema.json`，并按固定 schema 组织本次评测 JSON。

## 评分原则

### 1. 评分边界

本 skill 主要评估：

- 工程组织质量
- 代码静态质量
- 架构与职责划分
- 可维护性与可读性
- HarmonyOS NEXT / ArkTS / ArkUI 规范符合度
- 风险控制
- 与既有工程一致性
- 改动精准度与最小侵入性

默认**不把以下内容作为主评分依据**：

- 功能是否真正跑通
- UI 美观度
- 产品设计质量
- 测试验收结果
- 编译通过率

### 2. 规则层接入

规则集不是第二套总分，而是用于修正既有评分项。

处理优先级：

1. HarmonyOS NEXT / ArkTS / ArkUI 平台强约束
2. must rules
3. forbidden patterns
4. should rules

### 3. 明显违规必须标记

如果明显违反规则包中的某条规则：

- 在对应评分项里写出**规则 ID / 规则摘要、影响的评分项**。
- 在报告里单列 **规则违规标记**。
- 如果属于 must rule 或 forbidden pattern，明确说明是否导致降分、风险项或硬门槛候选。
- 不要只写"疑似违规"；必须给证据。

### 4. 硬门槛处理

发现以下问题时，检查是否触发总分上限：

- 高密度静态错误
- 明显不符合 HarmonyOS NEXT / ArkTS 基本规范
- 严重工程风险
- bug_fix 场景中的误修或过修

若触发多个硬门槛，取最低上限，并给出证据。

## 执行步骤

1. 识别输入对象并完成分类。
2. 确定：task_type、target_scope、reference_scope。
3. 读取对应 rubric、YAML 评分定义与规则参考。
4. 提取证据：结构证据、代码证据、风险证据、一致性证据。
5. 逐条读取并应用 `references/arkts_internal_rules.yaml` 中的全部规则，不能只检查命中项；对每一条规则都必须给出审查结论：`满足` / `不满足` / `不涉及`。
6. 先汇总逐条规则审查结果，再据此提炼 must / should / forbidden 命中，写入 `rule_violations`、风险项、人工复核项与评分说明。
7. 逐项评分，输出 score、confidence、rationale、evidence。
8. 计算维度分与总分，必要时应用硬门槛上限。
9. 输出优势项、问题项、风险项、人工复核项。

## 输出要求

最终输出必须是严格遵循 `references/report_result_schema.json` 定义的统一固定 schema；不要为单次任务动态生成 schema 文件。

评审输出时不允许在 schema 中**新增字段**，不能破坏原有字段结构、字段含义与已有顶层字段。

其中，`rule_audit_results` 的要求：

- 覆盖 `references/arkts_internal_rules.yaml` 中全部 `must_rules`、`should_rules`、`forbidden_patterns`。
- 顺序与 YAML 中规则出现顺序一致。
- 每条规则只包含以下 4 个字段，不增加无关信息：
  - `rule_id`
  - `rule_source`
  - `result`：只能是 `满足` / `不满足` / `不涉及`
  - `conclusion`：一句话结论
- `rule_source` 只能取：`must_rule`、`should_rule`、`forbidden_pattern`。
- `conclusion` 必须简洁，只说明本条规则为什么被判为满足 / 不满足 / 不涉及，不要额外塞入长段解释。
- 若某条规则判为 `不满足`，仍需按原有机制同步写入 `rule_violations`；`rule_audit_results` 是逐条审查台账，`rule_violations` 是违规摘要，二者不要互相替代。
- 若当前输入不足以支撑判断，优先写 `不涉及`，并在一句话结论中写明“不涉及原因”。

## 评审时的注意点

- continuation / bug_fix 若缺少参考工程上下文，要降低置信度，并加入人工复核项。
- 要确保`references/arkts_internal_rules.yaml`中每一条规则都被严格审查。
- 尽量减少人工复核项，不要为了凑满问题而过度挑刺。
- 证据不足时明确写 `confidence: low`。
- 不要把外部语言习惯强行盖过 HarmonyOS / ArkTS 平台约束。
- 对 diff 场景，重点看改动精准度、接入一致性、风险和无关改动。
- 对完整工程场景，重点看结构、职责、复用、平台实践和整体接手性。
