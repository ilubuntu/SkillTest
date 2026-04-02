---
name: constraint-score-review
description: 基于 case.yaml 中的 constraints，使用带权重的确定性规则评估修复后的 HarmonyOS 用例工作区，并将评分摘要追加到 runner 的 output.txt。
---

# 约束评分审查

## 用途

使用当前用例 `constraints` 作为修复后评分的唯一依据。  
评分由 bench 在 agent 完成代码修改后执行，而不是只依赖 agent 自己的修复总结。

## 先看结论

- `constraints` 自动评分总分固定按 `100 分` 计算
- 每条 constraint 先根据 `priority` 和 `check_method.type` 算出权重
- bench 再按权重把这 100 分切分给每条 constraint
- 每条 constraint 命中规则越完整，拿到的分越多
- 所有 constraint 的实得分相加，就是最终 `overall_score`

也就是说：

- 权重不直接等于分数
- 权重只决定“这条约束在 100 分里占多少”

## 评分模型

### 1. 权重

- 优先级权重：`P0=5`、`P1=3`、`P2=1`
- 类型权重：
  - `custom_rule=1.0`
  - `scenario_assert=1.2`

单条 constraint 的原始权重计算方式：

```text
constraint_weight = priority_weight × type_weight
```

### 2. 分值分配

先把所有 constraint 的原始权重加起来，再把总分 `100` 按比例分配给每一条 constraint：

```text
constraint_max_points = constraint_weight / sum(all_constraint_weights) × 100
```

### 3. 单条约束得分

每条 constraint 内部再根据规则命中率计算完成度：

```text
constraint_completion = matched_rules / total_rules
constraint_earned_points = constraint_max_points × constraint_completion
```

如果某条 constraint 有 4 条规则，命中 3 条，那么它的完成度就是：

```text
3 / 4 = 75%
```

### 4. 汇总得分

- `overall_score = 所有 constraint 的 earned_points 之和`
- `effectiveness_score = 只看 P0 constraint 后重新归一到 100 分`
- `quality_score = 只看 P1/P2 constraint 后重新归一到 100 分`

## 例子

假设当前用例只有 2 条约束：

```yaml
constraints:
  - id: HM-004-001
    priority: P0
    check_method:
      type: custom_rule
      rules: [r1, r2]

  - id: HM-004-002
    priority: P1
    check_method:
      type: scenario_assert
      rules: [r1, r2, r3]
```

先算原始权重：

- `HM-004-001 = P0(5) × custom_rule(1.0) = 5.0`
- `HM-004-002 = P1(3) × scenario_assert(1.2) = 3.6`

总权重：

```text
5.0 + 3.6 = 8.6
```

把总分 100 分按比例切开：

- `HM-004-001 max_points = 5.0 / 8.6 × 100 ≈ 58.1`
- `HM-004-002 max_points = 3.6 / 8.6 × 100 ≈ 41.9`

两条加起来就是：

```text
58.1 + 41.9 = 100.0
```

再假设规则命中结果如下：

- `HM-004-001` 命中 `2/2`，完成度 `100%`
- `HM-004-002` 命中 `2/3`，完成度 `66.7%`

则实得分为：

- `HM-004-001 earned_points = 58.1 × 100% = 58.1`
- `HM-004-002 earned_points = 41.9 × 66.7% ≈ 27.9`

最终总分：

```text
overall_score = 58.1 + 27.9 = 86.0 / 100
```

这个例子里可以直观看到：

- `P0` 约束占分更大
- `scenario_assert` 会比 `custom_rule` 分到更高的分值占比
- 即使 constraint 条目变多，总分口径也始终固定为 `100`

## 规则模型

每条 constraint 应定义以下字段：

- `id`
- `name`
- `description`
- `category`
- `priority`
- `check_method`

`check_method` 应使用结构化、可机器匹配的格式，例如：

```yaml
check_method:
  type: custom_rule
  match_mode: all
  rules:
    - rule_id: RULE-001
      target_file: entry/src/main/ets/pages/Index.ets
      match_type: contains
      snippet: "const EVENT_NAME = 'displayModeChange'"
```

当前自动评分支持的 `check_method.type`：

- `custom_rule`
- `scenario_assert`

当前支持的 `match_type`：

- `contains`
- `not_contains`
- `count_at_least`
- `regex_contains`
- `regex_not_contains`
- `regex_count_at_least`

当前支持的 `match_mode`：

- `all`
  该 constraint 下所有规则都需要满足，得分按命中比例计算
- `any`
  该 constraint 下只要命中任意一条规则就算该 constraint 通过，适合表达“多种合法实现任选一种”

## 输出结果

bench 会在 runner 的 `output.txt` 末尾追加一段 `Constraint Review Report`。

报告中会展示：

- 总分 `overall_score/100`
- 有效性分 `effectiveness_score/100`
- 质量分 `quality_score/100`
- 每条 constraint 的：
  - `max_points`
  - `earned_points`
  - `matched_rules/total_rules`
  - 每条规则的命中结果

为避免影响后续 evaluator 对原始 agent 输出的使用，原始输出会额外保存在
`raw_output.txt` 中。

## 运行时说明

运行时，bench 会基于当前 case 的 `constraints` 动态渲染一份针对该用例的 skill，
并与 runner 产物一起保存为 `constraint_review_skill.md`。
