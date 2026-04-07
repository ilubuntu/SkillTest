---
name: constraint-score-review
description: "基于结构化评审输入对 HarmonyOS 修复结果按 case.yaml 的 constraints 进行约束评分。实际输入通常是一段 Markdown 文本，至少包含原始工程目录、patch 文件或 patch 缺失标记、修复后工程目录、用例 prompt、约束规则，并可能附带 Patch Availability / 额外执行要求。适用于修复结果打分、未满足约束分析、原始工程与修复后工程对比，或仅刷新约束评分测试产物而不重新生成修复代码。"
---

# 约束规则评分

使用这个 skill 时，输入优先来自一段结构化文本，常见格式与 `constraint_review_input.txt` 一致，按“输入 1/输入 2/输入 3/输入 4/输入 5”分块提供。评分标准只看当前用例的 `constraints`。其余输入用于理解基线状态、定位改动范围，以及辅助解释修复意图。

## 输入格式

优先按如下 Markdown 结构理解输入：

```md
## 输入 1：原始工程目录
<original_project_root>

## 输入 2：修复后的 patch 文件
<repair_patch_file 或 "(patch unavailable; score directly from repaired_project_root)">

## 输入 3：修复后工程目录
<repaired_project_root>

## 输入 4：用例输入内容
<case_prompt>

## 输入 5：用例约束规则
<constraints JSON / YAML>

## Patch Availability
<可选。用于再次声明 patch 是否可用>

## 额外执行要求
<可选。仅作为执行提醒，不参与评分>
```

其中核心输入语义如下：

1. `original_project_root`
   原始工程的有效根目录路径。
2. `repair_patch_file`
   记录 agent 修改内容的 patch 文件。优先是 unified diff 或 git patch 路径；也允许显式传入缺失标记，例如 `(patch unavailable; score directly from repaired_project_root)`，表示本次无法基于 patch 做一致性校验，只能直接检查修复后工程。
3. `repaired_project_root`
   修复工程有效根目录路径。若 patch 可用，则语义上应是由 `original_project_root` 应用 `repair_patch_file` 后得到；若 patch 不可用，则它是本次唯一可直接评分的修复结果目录。
4. `case_prompt`
   用例输入内容，语义上对应当前 `case.yaml` 中的 prompt。
5. `constraints`
   用例约束规则，语义上对应当前 `case.yaml` 中的 constraints。

允许存在附加区块：

- `Patch Availability`
  当其明确声明 `repair_patch_file unavailable` 时，应视为 patch 缺失场景，并与“输入 2”中的缺失标记交叉校验。
- `额外执行要求`
  只作为流程提醒，不改变评分规则，不应被误判为新的约束。

如果 `original_project_root`、`repaired_project_root`、`constraints` 任一关键输入无效、缺失或不可读，停止评分并明确报告缺失项，不要编造分数。`repair_patch_file` 允许缺失，但必须在结果中明确说明评分降级为“仅基于 repaired_project_root 的直接核验”。

## 核心规则

- 评分对象优先是“原始工程 + diff patch”对应生成的修复工程；若输入明确声明 patch 不可用，则评分对象降级为 `repaired_project_root` 所代表的当前修复结果。
- 原始工程只作为基线证据使用。
- patch 文件既用于帮助理解改了什么，也用于界定修复工程应当呈现出的修改结果与检查范围。
- `case_prompt` 只用于理解修复目标或消解自然语言歧义。
- 如果 `case_prompt` 与 `constraints` 冲突，以 `constraints` 为准。
- 不要自行发明额外约束、隐藏要求或风格偏好。
- 不要仅凭 agent 的总结给分，必须基于 `original_project_root` + `repair_patch_file` 推导得到、并落在 `repaired_project_root` 下的真实文件核验。
- 如果 patch 文件与 `repaired_project_root` 的实际内容不一致，要优先指出“修复工程不是该 patch 正确应用后的结果”，并将相关约束判定为不可信或失败。
- 如果 patch 明确不可用，不得伪造 patch 推导链路；需要在结论中单独标注“已跳过 patch 一致性校验”。

## 工作流程

### 1. 校验输入

- 确认 `original_project_root` 存在，且看起来是有效工程根目录。
- 优先从结构化输入文本中提取“输入 1”到“输入 5”，不要只依赖自由文本猜测字段。
- 确认 `repair_patch_file` 是以下两种情况之一：
  - 存在且可读，且是可解析的 diff / git patch。
  - 被明确声明为 unavailable，此时进入“无 patch 降级评分”流程。
- 确认 `repaired_project_root` 存在且可读；若 patch 可用，则语义上应是由 `original_project_root` 应用 `repair_patch_file` 后得到的工程。
- 确认 `constraints` 是结构化列表。
- 当用例依赖修复意图理解时，确认 `case_prompt` 非空。

### 2. 理解基线状态

- 只读取足够理解修复前状态的原始工程内容。
- 用原始工程解释修复后结果是提升、回退，还是没有变化。
- 在这个 skill 中，不要把原始工程作为最终评分对象；最终评分对象是当前输入所指向的修复工程，优先是“原始工程 + patch”对应结果，patch 缺失时则直接是 `repaired_project_root`。

### 3. 阅读 patch

- 若 `repair_patch_file` 可用：
  - 解析 patch 文件，识别被修改的文件、宣称修复的问题，以及可能遗漏的点。
  - 确认 patch 能否合理映射到 `original_project_root`，并据此判断 `repaired_project_root` 是否真的是该 patch 应用后的结果。
  - patch 不能单独作为“约束已满足”的证据，必须结合 patch 应用后的修复工程内容核验。
  - 如果 patch 看起来已经修了，但修复工程里仍缺少对应代码模式，要明确指出 patch 与修复工程结果不一致。
- 若 `repair_patch_file` 不可用：
  - 明确记录“跳过 patch 阅读与一致性校验”。
  - 后续评分仅基于 `original_project_root` 与 `repaired_project_root` 的对比、以及 `repaired_project_root` 中的真实文件内容。

### 4. 按约束检查修复工程

- 对 `repaired_project_root` 下的真实文件逐条评估 constraint；若 patch 可用，还需同时确认这些文件符合 `original_project_root + repair_patch_file` 的预期结果。
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

- 哪条规则失败了。
- 检查的是哪个文件。
- 实际发现了什么证据，或缺少什么证据。
- 相比原始工程，由 patch 生成的修复工程是否真的有改善。

如果修复工程相对原始工程没有实质提升，要直接说明。

## 输出要求

输出结果应尽量简洁，但至少包含：

- `overall_score`
- `effectiveness_score`
- `quality_score`
- `constraints_passed`
- 未满足的约束
- 评分依据
- 原始工程与修复工程的关键差异；若 patch 可用，再补充 patch 与修复工程的一致性结论
- patch 是否可用；若不可用，需明确说明已跳过 patch 一致性校验

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
- 如果 patch 文件为空、不是 diff 格式，或无法从原始工程推导出有效修复结果，停止评分并明确报告。
- 如果输入已明确声明 `repair_patch_file unavailable`，不要因此报错；改为继续执行，但要在结果中标注该次评分无法验证 patch 到修复工程的映射关系。
- 如果 `constraints` 为空，明确说明无法执行约束评分。
- 如果修复工程无法完整读取，或无法确认其是由原始工程应用 patch 后生成，停止评分并报告不可读/不可验证路径。
