---
name: constraint-score-review
description: "根据输入的原始工程和产物工程，结合 patch 文件，按照约束规则对产物工程进行评分。"
---

# 约束评分

这个 skill 的唯一目标是：

- 根据原始工程、产物工程、patch 文件和约束规则，对产物工程进行约束评分。

评分对象始终是产物工程。

- 原始工程用于建立基线。
- patch 文件用于理解修改意图与核验修改链路。
- 约束规则用于定义评分标准。

不要把 patch 本身当成最终结果，不要只看 agent 的文字总结，不要自行发明约束规则。

## 核心原则

### 评分对象

- 最终评分对象只能是产物工程。
- 所有约束是否满足，都必须回到产物工程中的真实文件进行核验。

### 原始工程的作用

- 原始工程用于理解修复前状态。
- 原始工程用于判断产物工程是否真的产生改进。
- 如果 patch 可用，原始工程还是 patch 对比和验证的起点。

### patch 的作用

- patch 是中间证据，不是最终评分对象。
- patch 用于帮助理解改动范围、改动意图和预期结果。
- 如果 patch 与产物工程实际内容不一致，优先指出这一点。
- 即使 patch 看起来"写对了"，只要产物工程中没有真实落地，就不能判定约束满足。

### 约束规则的作用

- 约束规则是唯一评分标准。
- 所有评分结论都必须能回溯到具体约束和具体代码证据。
- 若任务描述与约束规则冲突，以约束规则为准。

## 输入理解

使用这个 skill 时，至少需要识别出四类信息：

- 原始工程
- 产物工程
- patch 文件
- 约束规则

如果还有任务描述、场景信息、补充说明，这些内容只用于辅助理解任务背景，不直接替代约束规则。

只要能从输入中稳定识别出这四类核心信息，就可以执行评分；不要求固定字段名，也不要求固定 Markdown 结构。

## 场景判断

在评分前，先判断当前任务属于哪个场景，用于决定默认公共约束是否应参与评分。

优先使用显式场景信息；若没有显式场景，再根据任务目标和工程形态推断。

常见场景包括：

- `project_gen`
  - 从零生成工程、补齐完整工程结构、创建新的多页面工程。
- `requirement`
  - 在已有工程上新增功能、实现需求、扩展页面能力。
- `bug_fix`
  - 在已有工程上修复缺陷、异常、回归或错误行为。
- `performance`
  - 在已有工程上进行性能优化、刷新优化、渲染优化。

判断原则：

- 只要任务核心是"在现有工程上修改"，通常就不是 `project_gen`。
- 不能把所有多页面任务都判成工程新建。
- 当显式场景与自然语言描述冲突时，以显式场景为准。

## 公共约束原则

- 公共约束不是默认对所有任务一刀切生效。
- 是否启用某条公共约束，取决于当前任务场景。
- 每条公共约束都应有明确的适用场景说明。
- case 显式写入的约束，优先级高于公共约束默认策略。

例如：

- `Navigation` 一类规则更适合 `project_gen` 场景。
- 对 `bug_fix`、`requirement`、`performance` 这类已有工程增量修改任务，不应默认因为沿用旧路由方式就直接扣公共约束分，除非 case 明确要求。

## 约束规则格式

当前约束规则统一使用 AST + LLM 检查规则格式。

### 约束格式结构

每条约束由基础信息和检查规则组成：

```yaml
constraints:
  - id: HM-BUG_FIX-001
    name: 列表渲染需要使用稳定key
    description: ForEach 渲染列表时必须使用稳定且唯一的 key 生成函数，避免因 key 不稳定导致列表刷新异常或状态错位。
    priority: P1
    rules:
      - target: "**/pages/*.ets"
        ast:
          - type: call
            name: ForEach
          - type: property_access
            name: id
        llm: "ForEach 的 key 参数是否使用稳定标识（如 item.id 或 item.id.toString()），而非数组索引 index"
```

**基础字段说明：**

| 字段 | 必填 | 说明 |
|------|------|------|
| `id` | 是 | 约束唯一标识，格式建议 `HM-{场景}-{序号}`，如 `HM-BUG_FIX-001` |
| `name` | 是 | 约束名称，简洁描述约束目标 |
| `description` | 否 | 约束详细描述，用于辅助理解约束意图 |
| `priority` | 是 | 优先级：P0/P1/P2 |
| `rules` | 是 | 检查规则列表，至少包含一条规则 |

**检查规则字段说明：**

| 字段 | 必填 | 说明 |
|------|------|------|
| `target` | 是 | 目标文件 glob pattern，如 `**/pages/*.ets` |
| `ast` | 否 | AST 检查规则列表，用于自动化静态检查 |
| `llm` | 否 | LLM 检查提示，用于语义层面的检查 |

### AST 规则类型

AST 规则用于自动化静态检查，每条规则包含 `type` 和 `name`：

| type | 说明 | 示例 |
|------|------|------|
| `decorator` | 存在指定装饰器 | `{type: decorator, name: ComponentV2}` |
| `no_decorator` | 不存在指定装饰器 | `{type: no_decorator, name: State}` |
| `call` | 存在指定函数调用 | `{type: call, name: ForEach}` |
| `no_call` | 不存在指定函数调用 | `{type: no_call, name: router.push}` |
| `property` | 存在指定属性 | `{type: property, name: navPathStack}` |
| `property_access` | 存在指定属性访问 | `{type: property_access, name: id}` |
| `variable` | 存在指定变量声明 | `{type: variable, name: navPathStack}` |
| `import` | 存在指定导入 | `{type: import, name: model}` |
| `no_import` | 不存在指定导入 | `{type: no_import, name: router}` |
| `class` | 存在指定类定义 | `{type: class, name: RestaurantModel}` |
| `method` | 存在指定方法定义 | `{type: method, name: getFilteredRestaurants}` |
| `no_literal_number` | 不使用数字字面量作为样式属性值 | `{type: no_literal_number}` |
| `navigation` | 存在导航跳转 | `{type: navigation, target: DetailPage}` |
| `navigation_with_params` | 存在带参数的导航跳转 | `{type: navigation_with_params}` |

AST 规则特点：

- 多条 AST 规则默认为 AND 关系，需全部满足
- `no_*` 类型规则表示"不存在"，用于禁止某种模式
- AST 规则在产物工程的目标文件中执行静态检查

### LLM 检查提示

LLM 规则用于语义层面的检查，无法通过 AST 自动验证的内容：

- 业务逻辑正确性（如"筛选前后餐厅卡片展示和状态必须保持一致"）
- 数据流完整性（如"保存成功后必须将商品变更结果回传首页"）
- 交互行为正确性（如"点击收藏按钮后图标状态必须立即切换"）

LLM 检查特点：

- LLM 提示是对 AST 规则的补充，不替代 AST 规则
- LLM 检查需在产物工程中定位相关代码进行核验
- LLM 检查结论需引用真实代码位置作为证据

### 规则组合示例

单条约束可包含多条检查规则，覆盖不同目标文件：

```yaml
constraints:
  - id: HM-PUBLIC-harmony_v2_state_management
    name: 页面状态管理必须统一使用 V2 装饰器
    description: 页面组件和状态模型必须统一使用 V2 装饰器体系
    priority: P0
    is_public: true
    rules:
      - target: "**/pages/*.ets"
        ast:
          - type: decorator
            name: ComponentV2
          - type: no_decorator
            name: State
          - type: no_decorator
            name: Link
      - target: "**/model/*.ets"
        ast:
          - type: decorator
            name: ObservedV2
          - type: decorator
            name: Trace
```

### 公共约束管理

公共约束定义在 `constraint_refs.yaml` 及其引用文件中：

- `constraint_refs.yaml` 定义场景默认启用哪些公共约束
- 各 `constraint_refs.*.yaml` 文件定义具体公共约束内容

公共约束加载流程：

1. 根据 `defaults.{scenario}` 确定当前场景应启用的公共约束名称列表
2. 从 refs 中查找对应公共约束定义
3. 为公共约束添加 `id: HM-PUBLIC-{name}` 和 `is_public: true`
4. 合并到 case 约束列表

## 执行流程

### 1. 建立基线

- 阅读原始工程，理解修复前或改造前状态。
- 识别与约束相关的关键文件、关键模块和关键行为。

### 2. 理解修改意图

- 阅读 patch，理解本次修改声称解决了什么问题。
- 识别 patch 影响了哪些文件、哪些逻辑、哪些代码路径。
- 如果 patch 缺失，则明确说明本次无法基于 patch 建立完整修改链路。

### 3. 解析约束规则

- 对每条约束解析 `rules` 中的检查规则。
- 提取 AST 规则转换为可执行的检查项。
- 保留 LLM 提示用于语义层面核验。

### 4. 执行 AST 检查

- 在产物工程的目标文件中执行 AST 检查。
- 记录每条 AST 规则是否命中。
- 若目标文件不存在，或目标文件中未命中所有 AST 规则，必须执行回退搜索：
  1. 在 patch 涉及的所有文件中搜索是否命中 AST 规则；
  2. 若 patch 不可用，则在产物工程中与目标文件同模块（同目录或同 src 目录下）的 .ets 文件中搜索；
  3. 若回退搜索命中，视为 AST 规则满足，并在 reason 中注明实际命中的文件路径；
  4. 若回退搜索仍未命中，才记录为未命中。
- 此回退机制的核心原因是：修复过程可能对代码做了组件抽取、文件拆分、重命名等重构，导致原始 target 指定的文件不再是最终实现位置，但约束要求的行为确实存在于产物工程中。

### 5. 执行 LLM 检查

- 在产物工程中定位相关代码。
- 根据 LLM 提示核验语义层面的约束是否满足。
- 引用真实代码位置作为证据。
- 若约束规则指定了具体 target 文件，但 LLM 检查在该文件中未找到相关代码，应在 patch 涉及的文件或同模块 .ets 文件中继续搜索，避免因组件抽取、文件拆分等原因误判为不满足。

### 6. 做前后对比

- 对比原始工程与产物工程，判断本次修改是否真的解决问题。
- 若产物工程相较原始工程没有实质提升，要明确指出。
- 若 patch 声称已修改，但产物工程中看不到对应结果，也要明确指出。

### 7. 输出评分结论

对每条约束至少说明：

- 检查了哪些目标文件
- AST 规则命中情况
- LLM 检查结论及代码证据
- 相比原始工程是否真的改进

## 评分模型

使用固定权重模型：

- `P0 = 5`
- `P1 = 3`
- `P2 = 1`

计算方式：

- 单条约束权重 = 该约束的优先级权重
- 单条约束满分 = `constraint_weight / sum(all_constraint_weights) * 100`
- 若约束包含 AST 规则：AST 完成度 = `matched_ast_rules / total_ast_rules`
- 若约束包含 LLM 规则：LLM 完成度由检查结论决定（满足=1.0，部分满足=0.5，不满足=0）
- 若仅有 AST 规则：约束完成度 = AST 完成度
- 若仅有 LLM 规则：约束完成度 = LLM 完成度
- 若同时有 AST 和 LLM 规则：约束完成度 = AST 完成度 * 0.5 + LLM 完成度 * 0.5
- 单条约束得分 = `constraint_max_points * completion`
- 最终总分 `overall_score` = 所有约束得分之和

补充约定：

- 某条约束即使未完全满足，也可能因为部分规则命中获得部分分数。
- 公共约束与非公共约束的输出必须分开列出。
- "得分"指该约束最终 `score > 0`。

## 输出要求

输出结果优先使用 JSON，对外只保留评分结果本身。

至少输出：

- `overall_score`
- `constraints_passed`
- `constraints_total`
- `passed_items`
- `failed_items`

推荐输出结构：

```json
{
  "overall_score": 88,
  "constraints_passed": 3,
  "constraints_total": 4,
  "passed_items": [
    {
      "constraint_id": "HM-BUG_FIX-001",
      "score": 25,
      "reason": "ForEach使用restaurant.id.toString()作为稳定key生成函数，命中index.ets:110代码证据"
    }
  ],
  "failed_items": [
    {
      "constraint_id": "HM-BUG_FIX-002",
      "score": 0,
      "reason": "@ObjectLink与getFilteredRestaurants()产生的新对象引用不兼容，未满足状态一致性要求"
    }
  ]
}
```

输出约定：

- `overall_score`：最终总分，0 到 100 的数字
- `constraints_passed`：得分约束数量（score > 0）
- `constraints_total`：参与评分的约束总数
- `passed_items`：得分约束详情，最多 5 条；每项包含 `constraint_id`、`score`、`reason`
- `failed_items`：未得分约束详情，最多 5 条；每项包含 `constraint_id`、`score`、`reason`
- `reason` 必须引用真实代码位置或具体检查结论，单句短说明

## 异常处理

- 原始工程缺失或不可读：停止评分，并明确说明无法建立基线。
- 产物工程缺失或不可读：停止评分，并明确说明无法执行最终核验。
- 约束规则缺失或为空：停止评分，并明确说明无法执行约束评分。
- patch 缺失：允许继续评分，但要明确说明本次缺少修改链路校验。
- patch 与产物工程不一致：优先指出"patch 声称的修改没有在产物工程中真实落地"。
- 目标文件不存在：记录 AST 规则未命中，允许继续评分。