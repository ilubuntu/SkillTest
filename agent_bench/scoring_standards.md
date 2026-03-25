# Skill 评测评分标准

## 概述

本文件定义了三种 Skill 的评分标准，用于量化评估 Skill 对 Agent 能力的增强效果。

## 评分体系

| 维度 | 权重 | 说明 |
|------|------|------|
| 正确性 (correctness) | 40% | 代码是否正确解决问题 |
| 完整性 (completeness) | 30% | 是否覆盖所有需求和边界情况 |
| 代码质量 (code_quality) | 30% | 是否符合 ArkTS 最佳实践 |

## 综合评分计算

```
综合评分 = 规则分 × 0.3 + LLM加权均分 × 0.7
```

- **规则分**: 根据 `must_contain` 和 `must_not_contain` 匹配情况计算 (0-100)
- **LLM加权均分**: 各维度得分的加权平均

---

## 1. 工程生成 Skill (project_gen)

### 评分标准

| 维度 | 权重 | 评分标准 |
|------|------|---------|
| correctness | 40% | 是否正确生成完整的项目目录结构，包含所有必要配置文件 |
| completeness | 30% | 是否包含所有必需的页面组件、路由配置、资源文件 |
| code_quality | 30% | 代码是否符合 ArkTS 规范，目录结构是否规范 |

### 关键检查点

**必须包含 (must_contain):**
- `@Entry` - 页面入口装饰器
- `@Component` - 组件装饰器
- `pages/` - 页面目录结构
- `module.json5` 或 `module.json` - 模块配置

**禁止包含 (must_not_contain):**
- `TODO` - 未完成的标记
- `FIXME` - 待修复标记
- 语法错误
- 缺少必要的导入语句

### 评分阈值

| 等级 | 分数范围 | 说明 |
|------|---------|------|
| 优秀 | 85-100 | 完整生成项目结构，代码规范 |
| 良好 | 70-84 | 基本正确，缺少部分非关键内容 |
| 及格 | 60-69 | 核心功能正确，但有明显缺陷 |
| 不及格 | <60 | 核心功能缺失或错误 |

---

## 2. 可编译 Skill (compilable)

### 评分标准

| 维度 | 权重 | 评分标准 |
|------|------|---------|
| correctness | 40% | 语法是否正确，类型声明是否完整 |
| completeness | 30% | 功能实现是否完整，错误处理是否到位 |
| code_quality | 30% | 是否遵循 ArkTS 类型系统要求，避免常见编译错误 |

### 关键检查点

**必须包含 (must_contain):**
- 明确的类型声明 (不能使用 `any`)
- 正确的装饰器使用
- `@State`、`@Link` 等状态管理装饰器

**禁止包含 (must_not_contain):**
- `any` - 禁止使用 any 类型
- `var ` - 禁止使用 var 声明
- 未处理的空值情况
- 错误的资源引用

### 评分阈值

| 等级 | 分数范围 | 说明 |
|------|---------|------|
| 优秀 | 85-100 | 无编译警告，代码规范 |
| 良好 | 70-84 | 有轻微警告，不影响编译 |
| 及格 | 60-69 | 能通过编译，但有较多警告 |
| 不及格 | <60 | 无法通过编译 |

---

## 3. 性能优化 Skill (performance)

### 评分标准

| 维度 | 权重 | 评分标准 |
|------|------|---------|
| correctness | 40% | 是否正确使用 LazyForEach/cachedCount 等性能优化技术 |
| completeness | 30% | 是否完整实现了 IDataSource 接口，优化是否全面 |
| code_quality | 30% | 代码是否遵循性能优化最佳实践 |

### 关键检查点

**必须包含 (must_contain):**
- `LazyForEach` - 必须使用懒加载ForEach
- `cachedCount` - 必须设置缓存数量
- `IDataSource` - 列表必须实现数据源接口

**禁止包含 (must_not_contain):**
- `ForEach` - 禁止在 List/Grid 中使用普通 ForEach
- `TODO` - 未完成的优化
- 大数组直接传递

### 评分阈值

| 等级 | 分数范围 | 说明 |
|------|---------|------|
| 优秀 | 85-100 | 完整使用懒加载技术，缓存设置合理 |
| 良好 | 70-84 | 基本使用懒加载，缓存设置可优化 |
| 及格 | 60-69 | 部分使用懒加载，有改进空间 |
| 不及格 | <60 | 未使用懒加载或实现错误 |

---

## 评分流程

### 1. 规则匹配 (Rule Check)
```
规则分 = (匹配通过数 / 总规则数) × 100
```

### 2. LLM 评分 (LLM Judge)
```
LLM均分 = Σ(维度分数 × 维度权重) / Σ权重
```

### 3. 综合评分
```
综合分 = 规则分 × 0.3 + LLM均分 × 0.7
```

---

## 输出格式

评分结果以 JSON 格式输出：

```json
{
  "case_id": "project_gen_001",
  "scenario": "project_gen",
  "baseline_total": 45.5,
  "enhanced_total": 78.3,
  "gain": 32.8,
  "dimension_scores": {
    "correctness": {
      "baseline": 40,
      "enhanced": 80
    },
    "completeness": {
      "baseline": 50,
      "enhanced": 75
    },
    "code_quality": {
      "baseline": 45,
      "enhanced": 80
    }
  },
  "baseline_rule": 60.0,
  "enhanced_rule": 90.0
}
```

---

## 评分标准版本

- 版本: 1.0
- 更新日期: 2026-03-25
- 适用范围: Skill 评测系统 v1.0
