---
name: constraint-score-review
description: "基于五项输入对 HarmonyOS 修复结果按 case.yaml 的 constraints 进行约束评分：原始工程路径、agent 产出的 patch 文件、修复后工程路径、用例 prompt、以及约束规则。适用于修复结果打分、未满足约束分析、原始工程与修复后工程对比，或仅刷新约束评分测试产物而不重新生成修复代码。"
---

# 约束规则评分

使用这个 skill 时，评分对象是修复后的工程，评分标准只看当前用例的 `constraints`。其余输入用于理解基线状态、定位改动范围，以及辅助解释修复意图。

## 必要输入

可用时应尽量同时提供以下 5 项输入：

1. `original_project_root`
   原始工程的有效根目录路径。
2. `repair_patch_file`
   记录 agent 修改内容的 patch 文件。优先使用 unified diff 或 git patch 格式。
3. `repaired_project_root`
   修复后工程的有效根目录路径。
4. `case_prompt`
   用例输入内容，语义上对应当前 `case.yaml` 中的 prompt。
5. `constraints`
   用例约束规则，语义上对应当前 `case.yaml` 中的 constraints。

如果任一关键路径无效、缺失或不可读，停止评分并明确报告缺失项，不要编造分数。

## 核心规则

- 评分对象是修复后工程，不是 patch 文本。
- 原始工程只作为基线证据使用。
- patch 文件只用于帮助理解改了什么，以及哪些文件值得重点检查。
- `case_prompt` 只用于理解修复目标或消解自然语言歧义。
- 如果 `case_prompt` 与 `constraints` 冲突，以 `constraints` 为准。
- 不要自行发明额外约束、隐藏要求或风格偏好。
- 不要仅凭 agent 的总结给分，必须基于 `repaired_project_root` 下的真实文件核验。
- 如果 patch 文件与修复后工程内容不一致，以修复后工程为评分依据，并在结论中说明该不一致。

## 工作流程

### 1. 校验输入

- 确认 `original_project_root` 存在，且看起来是有效工程根目录。
- 确认 `repaired_project_root` 存在且可读。
- 确认 `repair_patch_file` 存在且可读。
- 确认 `constraints` 是结构化列表。
- 当用例依赖修复意图理解时，确认 `case_prompt` 非空。

### 2. 理解基线状态

- 只读取足够理解修复前状态的原始工程内容。
- 用原始工程解释修复后结果是提升、回退，还是没有变化。
- 在这个 skill 中，不要把原始工程作为最终评分对象。

### 3. 阅读 patch

- 解析 patch 文件，识别被修改的文件、宣称修复的问题，以及可能遗漏的点。
- patch 只能作为排查线索，不能直接作为“约束已满足”的证据。
- 如果 patch 看起来已经修了，但修复后工程里仍缺少对应代码模式，要明确指出。

### 4. 按约束检查修复后工程

- 对 `repaired_project_root` 下的真实文件逐条评估 constraint。
- 若规则中提供了 `target_file`，优先检查该目标文件。
- 对于 `original_project/...`、`agent_workspace/...` 这类路径前缀，先归一化为当前项目根目录下的相对路径，再进行检查。
- 当前评分器支持以下规则类型与匹配模式：
  - `check_method.type`: `custom_rule`、`scenario_assert`
  - `match_mode`: `all`、`any`
  - `match_type`: `contains`、`not_contains`、`count_at_least`、`regex_contains`、`regex_not_contains`、`regex_count_at_least`

### 5. 计算分数

使用以下评分模型：

- 优先级权重：`P0=5`、`P1=3`、`P2=1`
- 类型权重：`custom_rule=1.0`、`scenario_assert=1.2`
- 单条约束权重 = `priority_weight * type_weight`
- 单条约束满分 = `constraint_weight / sum(all_constraint_weights) * 100`
- 当 `match_mode=all` 时，约束完成度 = `matched_rules / total_rules`
- 当 `match_mode=any` 时：
  - 任意一条规则命中，则完成度为 `100%`
  - 一条都未命中，则完成度为 `0%`
- 单条约束实得分 = `constraint_max_points * constraint_completion`
- `overall_score` = 所有约束实得分之和
- `effectiveness_score` = 仅基于 `P0` 约束重新归一后的分数
- `quality_score` = 仅基于 `P1` 和 `P2` 约束重新归一后的分数
- `constraints_passed` = 最终判定通过的约束条数

需要特别注意：

- `constraints_passed` 是条数，不是分数。
- `overall_score` 不等于 `effectiveness_score` 和 `quality_score` 的平均值。
- 某条约束即使未完全通过，也可能因为部分规则命中而获得部分分数。

### 6. 解释评分结果

对于每条未通过或部分命中的约束，要说明：

- 哪条规则失败了
- 检查的是哪个文件
- 实际发现了什么证据，或缺少什么证据
- 相比原始工程，修复后工程是否真的有改善

如果修复后工程相对原始工程没有实质提升，要直接说明。

## 输出要求

输出结果应尽量简洁，但至少包含：

- `overall_score`
- `effectiveness_score`
- `quality_score`
- `constraints_passed`
- 未满足的约束
- 评分依据
- 原始工程与修复后工程的关键差异

如果要生成报告段落，优先使用如下结构：

```md
## Constraint Review Report

- overall_score: 44.2/100
- effectiveness_score: 42.0/100
- quality_score: 100.0/100
- constraints_passed: 1/6

### Unmet Constraints
- HM-XXX-01: failed because ...

### Evidence
- entry/src/main/ets/pages/Index.ets: ...

### Original vs Repaired
- improved / unchanged / regressed: ...
```

## 异常处理

- 如果目标文件缺失，将相关规则判为失败，并明确指出缺失文件路径。
- 如果 patch 文件为空，继续基于修复后工程评分，但要说明没有可用的 patch 证据。
- 如果 `constraints` 为空，明确说明无法执行约束评分。
- 如果修复后工程无法完整读取，停止评分并报告不可读路径。
