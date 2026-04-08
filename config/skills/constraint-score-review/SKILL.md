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

输入有效性与降级原则：

- `original_project_root`、`repaired_project_root`、`constraints` 是关键输入；任一无效、缺失或不可读时，立即停止评分并明确报告缺失项，不要编造分数。
- `repair_patch_file` 允许缺失；若被明确声明为 unavailable，则继续执行，但本次评分降级为“仅基于 `repaired_project_root` 的直接核验”，并在结果中标注“已跳过 patch 一致性校验”。

## 核心规则

- 先明确三类输入的角色：
  - `original_project_root`：基线工程，只用于理解修复前状态、做前后对比，以及在 patch 可用时提供 patch 的映射起点。
  - `repair_patch_file`：修复意图与改动范围的中间证据；patch 可用时，用它约束“修复工程应该长成什么样”，并校验 `repaired_project_root` 是否与之对应。
  - `repaired_project_root`：最终评分对象；所有约束是否满足，最终都要落到这个目录下的真实文件来核验。
- 按 patch 可用性区分两种评分模式：
  - patch 可用：按照“`original_project_root` -> `repair_patch_file` -> `repaired_project_root`”这条证据链评分，既检查约束是否满足，也检查修复工程是否真的是该 patch 对应的结果。
  - patch 不可用：按降级原则直接检查 `repaired_project_root`，原始工程仅作为辅助对比基线，不再构造 patch 推导链路。
- patch 不能单独作为“约束已满足”的证据；即使 patch 写得很完整，也必须以 `repaired_project_root` 中的真实文件为准。
- `case_prompt` 只用于理解修复目标或消解自然语言歧义。
- 如果 `case_prompt` 与 `constraints` 冲突，以 `constraints` 为准。
- 不要自行发明额外约束、隐藏要求或风格偏好。
- 不要仅凭 agent 的总结给分。
- 如果 patch 文件与 `repaired_project_root` 的实际内容不一致，要优先指出“修复工程不是该 patch 正确应用后的结果”，并将相关约束判定为不可信或失败。
- 如果 patch 明确不可用，不得伪造 patch 推导链路。

## 工作流程

### 1. 校验输入

- 确认 `original_project_root` 存在，且看起来是有效工程根目录。
- 优先从结构化输入文本中提取“输入 1”到“输入 5”，不要只依赖自由文本猜测字段。
- 确认 `repair_patch_file` 是以下两种情况之一：
  - 存在且可读，且是可解析的 diff / git patch。
  - 被明确声明为 unavailable，此时按前述降级原则继续评分。
- 确认 `repaired_project_root` 存在且可读。
- 确认 `constraints` 是结构化列表。
- 当用例依赖修复意图理解时，确认 `case_prompt` 非空。

### 2. 建立证据链

- 先读取足够理解修复前状态的原始工程内容，用它建立基线。
- 若 patch 可用：
  - 解析 patch，识别被修改的文件、宣称修复的问题，以及预期影响范围。
  - 检查 patch 是否能合理映射到 `original_project_root`，并据此判断 `repaired_project_root` 是否应被视为该 patch 的落地结果。
- 若 patch 不可用：
  - 明确本次没有 patch 证据链，后续只做“基线对比 + 修复工程实查”的降级评分。

### 3. 检查修复工程并评分

- 对 `repaired_project_root` 下的真实文件逐条评估 constraint。
- 若 patch 可用，同时核对修复工程是否符合 patch 所声明的修改结果；如果 patch 看起来已经修了，但修复工程里仍缺少对应代码模式，要明确指出 patch 与修复工程结果不一致。
- 若规则中提供了 `target_file`，优先检查该目标文件。
- 对于 `original_project/...`、`agent_workspace/...` 这类路径前缀，先归一化为当前项目根目录下的相对路径，再进行检查。
- 当前评分器当前只读取 `check_method.rules`，并按“全部规则都参与完成度计算”的固定语义执行评分。

### 5. 计算分数

使用以下评分模型：

- 优先级权重：`P0=5`、`P1=3`、`P2=1`
- 单条约束权重 = `priority_weight`
- 单条约束满分 `constraint_max_points` = `constraint_weight / sum(all_constraint_weights) * 100`
- 若某条约束包含规则，则约束完成度 `constraint_completion` = `matched_rules / total_rules`
- 若某条约束未配置任何规则，则默认 `constraint_completion = 100%`
- 单条约束实得分 `earned_points` = `constraint_max_points * constraint_completion`
- `overall_score` = 所有约束 `earned_points` 之和，范围为 `0-100`，也是最终唯一需要输出和解释的总体得分
- `passed_constraints` = 最终判定通过的约束对象数组，每项至少包含：
  - `constraint_id`
  - `score`
- 其中 `passed_constraints[*].score` 表示该约束的实际得分 `earned_points`，不是原始完成度百分比
- `unmet_constraint_ids` = 最终判定未通过的约束 id 数组

需要特别注意：

- `passed_constraints` 是对象数组，不是分数；每个对象都要同时给出约束 id 和该约束得分。
- `passed_constraints[*].score` 是该约束按权重折算后的实际得分，不是 `100/0` 形式的布尔分，也不是原始规则命中率。
- `unmet_constraint_ids` 是 id 数组，不是分数。
- `overall_score` 已经综合了约束优先级和规则命中情况，不需要再拆分子分数。
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

- 最终结果优先直接输出一个 JSON 对象，避免再混入旧版 `effectiveness_score`、`quality_score`、`constraints_passed` 字段
- `overall_score`
- `passed_constraints`：以对象数组形式列出通过的约束；每个对象至少包含 `constraint_id` 和 `score`；若没有则输出 `[]`
- `unmet_constraint_ids`：以数组形式列出未通过的约束 id；若全部满足则输出 `[]`

例如：

```json
{
  "overall_score": 44.2,
  "passed_constraints": [
    {
      "constraint_id": "HM-XXX-02",
      "score": 16.7
    }
  ],
  "unmet_constraint_ids": ["HM-XXX-01", "HM-XXX-03"]
}
```

## 异常处理

- 如果目标文件缺失，将相关规则判为失败，并明确指出缺失文件路径。
- 如果 patch 文件为空、不是 diff 格式，或无法从原始工程推导出有效修复结果，停止评分并明确报告。
- 如果输入已明确声明 `repair_patch_file unavailable`，不要因此报错；按前述降级原则继续执行。
- 如果 `constraints` 为空，明确说明无法执行约束评分。
- 如果修复工程无法完整读取，或在 patch 可用时无法确认其是由原始工程应用 patch 后生成，停止评分并报告不可读/不可验证路径。
