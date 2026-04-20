# Row 组件 HarmonyOS 6.0 开发 Skill

## 概述

Row 组件是 OpenHarmony 中最基础和常用的容器组件之一，用于水平方向（从左到右）排列子组件。它支持灵活的对齐方式、间距设置和权重分配，是构建水平布局的核心组件。

## 重要说明

- **基础组件**: Row 是 ArkUI 的基础内置组件，无需导入
- **布局方向**: 水平方向，子组件从左到右排列
- **默认行为**: 子组件高度默认撑满父容器，宽度根据内容自适应
- **常用属性**: alignItems、justifyContent、space

## 模块信息

- **组件名称**: Row
- **SDK 版本**: HarmonyOS 6.0 (API 12+)
- **系统能力**: SystemCapability.ArkUI.ArkUI.Full
- **更新日期**: 2026-02-24
- **官方文档**:
  - [Row 沿容器 - 华为开发者](https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V5/ts-container-row-V5)

## 经验总结
1. row 不支持 gap 属性，改为在每个子组件（Column）上添加 `margin` 属性来设置左右间距：
```typescript
.margin({ left: StyleConstants.SPACE_2, right: StyleConstants.SPACE_2 })
```

## 一、组件基础

### 1.1 导入方式

```typescript
// Row 是内置组件，无需导入
// 直接使用即可
Row() {
  Text('Item 1')
  Text('Item 2')
  Text('Item 3')
}
```

### 1.2 基础用法

```typescript
// 简单的水平布局
Row() {
  Text('Item 1')
  Text('Item 2')
  Text('Item 3')
}

// 设置间距
Row({ space: 16 }) {
  Text('Item 1')
  Text('Item 2')
  Text('Item 3')
}

// 设置宽度和高度
Row() {
  Text('Item 1')
  Text('Item 2')
}
.width('100%')
.height(60)
```

## 二、API 参数

### 2.1 构造参数

| 参数 | 类型 | 必填 | 默认值 | 描述 |
|------|------|------|--------|------|
| options | `RowOptions` | 否 | - | 行配置，包含 space 等 |

### 2.2 布局属性

| 属性 | 类型 | 默认值 | 描述 |
|------|------|--------|------|
| `space` | `string \| number \| Resource` | 0 | 横向排列元素的间距 |
| `alignItems` | `VerticalAlign` | VerticalAlign.Center | 子组件在垂直方向上的对齐方式 |
| `justifyContent` | `FlexAlign` | FlexAlign.Start | 子组件在水平方向上的对齐方式 |

### 2.3 对齐方式

#### alignItems (垂直对齐)

| 值 | 描述 |
|------|------|
| `VerticalAlign.Top` | 子组件顶部对齐 |
| `VerticalAlign.Center` | 子组件居中对齐（默认） |
| `VerticalAlign.Bottom` | 子组件底部对齐 |

#### justifyContent (水平对齐)

| 值 | 描述 |
|------|------|
| `FlexAlign.Start` | 子组件左侧对齐（默认） |
| `FlexAlign.Center` | 子组件居中对齐 |
| `FlexAlign.End` | 子组件右侧对齐 |
| `FlexAlign.SpaceBetween` | 子组件之间平均分配空间 |
| `FlexAlign.SpaceAround` | 子组件周围平均分配空间 |
| `FlexAlign.SpaceEvenly` | 子组件均匀分配空间 |

## 三、使用示例

### 3.1 基础水平布局

```typescript
Row({ space: 12 }) {
  Text('头像')
    .width(40)
    .height(40)

  Text('用户名')
    .fontSize(16)

  Text('时间')
    .fontSize(14)
    .fontColor('#999999')
}
.width('100%')
.padding(16)
```

### 3.2 对齐方式示例

```typescript
// 垂直居中对齐（默认）
Row({ space: 16 }) {
  Text('Item 1')
    .height(60)
  Text('Item 2')
    .height(80)
  Text('Item 3')
    .height(100)
}
.alignItems(VerticalAlign.Center)

// 水平居中对齐
Row({ space: 16 }) {
  Text('Left')
  Text('Center')
  Text('Right')
}
.width('100%')
.justifyContent(FlexAlign.Center)
```

### 3.3 权重分配

```typescript
Row() {
  Text('Left')
    .width(60)

  Text('Center')
    .layoutWeight(1)  // 占据剩余空间

  Text('Right')
    .width(80)
}
.width('100%')
```

### 3.4 两端对齐

```typescript
Row() {
  Text('左侧文本')
  Text('右侧文本')
}
.width('100%')
.justifyContent(FlexAlign.SpaceBetween)
```

## 四、最佳实践

### 4.1 使用 space 设置间距

```typescript
// ✅ 推荐：使用 space 属性
Row({ space: 12 }) {
  Text('Item 1')
  Text('Item 2')
  Text('Item 3')
}

// ❌ 避免：手动设置 margin
Row() {
  Text('Item 1').margin({ right: 12 })
  Text('Item 2').margin({ right: 12 })
  Text('Item 3')
}
```

### 4.2 明确设置宽度

```typescript
// ✅ 推荐：明确设置宽度
Row({ space: 16 }) {
  Text('Content')
}
.width('100%')

// ⚠️ 注意：不设置宽度可能只占用内容宽度
Row({ space: 16 }) {
  Text('Content')
}
```

### 4.3 使用 layoutWeight 实现弹性布局

```typescript
// ✅ 推荐：使用 layoutWeight
Row() {
  Text('固定宽度')
    .width(100)

  Text('弹性宽度')
    .layoutWeight(1)
}
.width('100%')
```

## 五、常见问题

### Q1: Row 的子组件为什么不显示？

**解决方案**:
```typescript
// 确保 Row 有明确的宽度或包含在有限容器中
Row({ space: 16 }) {
  Text('Item 1')
  Text('Item 2')
}
.width('100%')  // 设置宽度
```

### Q2: 如何实现等间距布局？

**解决方案**:
```typescript
// 使用 space 属性
Row({ space: 16 }) {
  Text('Item 1')
  Text('Item 2')
  Text('Item 3')
}
```

### Q3: 如何让某个子组件占据剩余空间？

**解决方案**:
```typescript
Row() {
  Text('Fixed')
    .width(60)

  Text('Flexible')
    .layoutWeight(1)  // 占据剩余空间
}
.width('100%')
```

## 六、版本兼容性

| API 版本 | 支持状态 | 备注 |
|----------|----------|------|
| API 9+ | ✅ | 完全支持 |
| API 11+ | ✅ | 增加了更多对齐选项 |
| API 18+ | ✅ | 增加了 space 资源类型支持 |

## 七、参考资料

- [Row 沿容器 - 华为开发者官方文档](https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V5/ts-container-row-V5)
- [通用属性 - 华为开发者](https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V5/ts-universal-attributes-size-V5)
