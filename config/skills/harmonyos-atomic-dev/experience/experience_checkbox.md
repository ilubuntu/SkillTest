# Checkbox 组件开发经验

## 元服务 API 兼容性清单

### 可用 API

| API | 元服务版本 | 说明 |
|---|---|---|
| `Checkbox(options?: CheckboxOptions)` | API 11+ | 复选框 |
| `CheckboxOptions.name / group` | API 11+ | 名称和分组 |
| `.select(bool)` | API 11+ | 选中状态，支持 $$ 双向绑定 |
| `.selectedColor / .unselectedColor` | API 11+ | 颜色 |
| `.mark(MarkStyle)` | API 11+ | 勾选样式（strokeColor, size） |
| `.onChange(callback)` | API 11+ | 状态变化回调 |

### 不可用 API

| API | 所需版本 | 说明 |
|---|---|---|
| `indicatorBuilder` | API 12+ | 自定义选中指示器 |
| `.shape(CheckBoxShape)` | API 12+ | 设置形状 |
| `.contentModifier` | API 12+ | 自定义内容区 |

## 编译问题

`MarkStyle` 不含 `width` 属性，仅有 `strokeColor` 和 `size`。

## 降级策略

| 不可用 API | 降级方案 |
|---|---|
| indicatorBuilder (API 12+) | 使用 .mark(MarkStyle) 自定义勾选样式 |
| shape (API 12+) | API 11+ 默认圆形，无法切换 |
