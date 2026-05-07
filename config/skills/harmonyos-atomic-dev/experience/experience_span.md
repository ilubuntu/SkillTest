# Span 组件元服务开发经验

## 概述

Span 是 Text / RichEditor 的内联文本子组件，用于在同一行内展示不同样式的文本段。本文档聚焦 Span 在元服务中的 API 兼容性和使用注意事项。

## 元服务 API 兼容性清单

### 可用 API

| API | 起始版本 | 元服务版本 | 说明 |
|-----|---------|-----------|------|
| `Span(value: string \| Resource)` | API 7 | API 7+ | 创建内联文本，需嵌入 Text 组件中 |
| `.fontColor(value: ResourceColor)` | API 7 | API 7+ | 设置字体颜色 |
| `.fontSize(value: number \| string \| Resource)` | API 7 | API 7+ | 设置字体大小 |
| `.fontStyle(value: FontStyle)` | API 7 | API 7+ | 设置字体风格（Normal/Italic） |
| `.fontWeight(value: number \| FontWeight \| string)` | API 7 | API 7+ | 设置字体粗细 |
| `.fontFamily(value: string \| Resource)` | API 7 | API 7+ | 设置字体族 |
| `.decoration(value: DecorationObject)` | API 7 | API 7+ | 文本装饰线（type/color/style） |
| `.textCase(value: TextCase)` | API 10 | API 10+ | 大小写转换（Normal/UpperCase/LowerCase） |
| `.textBackgroundStyle(value: TextBackgroundStyle)` | API 11 | API 11+ | 文本背景样式（color/radius） |
| `.letterSpacing(value: number \| string)` | API 11 | API 11+ | 字符间距 |
| `.baselineOffset(value: number \| string)` | API 11 | API 11+ | 基线偏移 |
| `.onClick(handler: () => void)` | API 7 | 可用 | 点击事件（Span 无尺寸，仅支持此事件和 onHover） |
| `.onHover(handler: (isHover: boolean) => void)` | API 7 | 可用 | 悬浮事件 |
| `ContainerSpan()` | API 11 | API 12+ | 容器 Span，统一管理子 Span 背景色 |
| `ContainerSpan.textBackgroundStyle()` | API 11 | API 12+ | 设置容器内子组件统一背景样式 |
| `ContainerSpan.attributeModifier()` | API 12 | API 12+ | 动态属性设置 |

### 不可用/受限 API

| API | 起始版本 | 说明 | 替代方案 |
|-----|---------|------|---------|
| `baselineOffset(Optional<LengthMetrics>)` | API 18 | Optional 参数重载 | 使用 `baselineOffset(value: number \| string)` |
| `fontFamily(Optional<string \| Resource>)` | API 18 | Optional 参数重载 | 使用 `fontFamily(value: string \| Resource)` |
| `letterSpacing(Optional<Dimension>)` | API 18 | Optional 参数重载 | 使用 `letterSpacing(value: number \| string)` |
| `CustomSpan` | API 20 | 自定义 Span 测量绘制 | 使用 Span + ContainerSpan 组合 |

## 核心调用方式

### 1. 基础多段 Span

```typescript
Text() {
  Span('红色粗体')
    .fontColor(Color.Red)
    .fontWeight(FontWeight.Bold)
  Span('蓝色斜体')
    .fontColor(Color.Blue)
    .fontStyle(FontStyle.Italic)
}
```

**注意**: Text 与 Span 同时配置文本时，Span 内容会覆盖 Text 内容。

### 2. 文本装饰线

```typescript
Span('删除线')
  .decoration({ type: TextDecorationType.LineThrough, color: Color.Red })
Span('波浪下划线')
  .decoration({ type: TextDecorationType.Underline, color: Color.Blue, style: TextDecorationStyle.WAVY })
```

`decoration` 支持 `type`（LineThrough/Underline/Overline/None）、`color` 和 `style`（SOLID/DOUBLED/DOTTED/DASHED/WAVY）。

### 3. 大小写转换

```typescript
Span('lowercase').textCase(TextCase.UpperCase)  // 显示为 LOWERCASE
```

### 4. ContainerSpan 统一背景

```typescript
Text() {
  ContainerSpan() {
    Span('标签文本').fontColor(Color.White)
  }
  .textBackgroundStyle({ color: '#4CAF50', radius: 8 })
}
```

ContainerSpan 包裹多个 Span/ImageSpan，统一管理背景色和圆角。

### 5. Span 事件

```typescript
Span('点击我')
  .onClick(() => { /* 处理点击 */ })
  .onHover((isHover: boolean) => { /* 处理悬浮 */ })
```

Span 无尺寸信息，仅支持 `onClick` 和 `onHover` 两种事件。

## 编译问题与解决方案

### 问题 1: textBackgroundStyle 类型不匹配

**现象**: `textBackgroundStyle({ color: '#4CAF50', radius: 8 })` 编译告警类型问题。

**解决**: `radius` 参数接受 `number | string | Resource`，直接传 `number` 类型即可，确保不传非法类型。

### 问题 2: Span 内容覆盖 Text 内容

**现象**: 同时设置了 `Text('文本')` 和 `Span('内容')`，只显示 Span 的内容。

**解决**: 这是预期行为。Text 与 Span 同时配置文本时，Span 内容覆盖 Text 内容。如需 Text 原始内容，不要使用子组件 Span。

## 降级处理策略

对于 API 18+ 的 Optional 参数重载版本（baselineOffset/fontFamily/letterSpacing），降级方案明确：

- **统一使用非 Optional 版本**：传具体的 `number`、`string` 或 `Resource` 值
- **undefined 处理**：不需要显式传 undefined，非 Optional 版本本身有默认值
- **CustomSpan（API 20+）**：无法降级，使用 Span + ContainerSpan + textBackgroundStyle 组合实现类似视觉效果