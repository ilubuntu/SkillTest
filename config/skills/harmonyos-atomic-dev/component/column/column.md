# Column 组件 HarmonyOS 6.0 开发 指导

## 概述

Column 组件是 OpenHarmony 中最基础和常用的容器组件之一，用于垂直方向（从上到下）排列子组件。它支持灵活的对齐方式、间距设置和权重分配，是构建垂直布局的核心组件。

## 重要说明

- **基础组件**: Column 是 ArkUI 的基础内置组件，无需导入
- **布局方向**: 垂直方向，子组件从上到下排列
- **默认行为**: 子组件宽度默认撑满父容器，高度根据内容自适应
- **常用属性**: alignItems、justifyContent、space

## 模块信息

- **组件名称**: Column
- **SDK 版本**: HarmonyOS 6.0 (API 12+)
- **系统能力**: SystemCapability.ArkUI.ArkUI.Full
- **更新日期**: 2026-02-24
- **官方文档**:
  - [Column 沿容器 - 华为开发者](https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V5/ts-container-column-V5)

## 一、组件基础

### 1.1 导入方式

```typescript
// Column 是内置组件，无需导入
// 直接使用即可
Column() {
  Text('Item 1')
  Text('Item 2')
  Text('Item 3')
}
```

### 1.2 基础用法

```typescript
// 简单的垂直布局
Column() {
  Text('Header')
  Text('Content')
  Text('Footer')
}

// 设置间距
Column({ space: 16 }) {
  Text('Item 1')
  Text('Item 2')
  Text('Item 3')
}

// 设置宽度和高度
Column() {
  Text('Item 1')
  Text('Item 2')
}
.width('100%')
.height(200)
```

## 二、API 参数

### 2.1 构造参数

| 参数 | 类型 | 必填 | 默认值 | 描述 |
|------|------|------|--------|------|
| options | `ColumnOptions` | 否 | - | 列配置，包含 space 等 |

### 2.2 布局属性

| 属性 | 类型 | 默认值 | 描述 |
|------|------|--------|------|
| `space` | `string \| number \| Resource` | 0 | 纵向排列元素的间距 |
| `alignItems` | `HorizontalAlign` | HorizontalAlign.Center | 子组件在水平方向上的对齐方式 |
| `justifyContent` | `FlexAlign` | FlexAlign.Start | 子组件在垂直方向上的对齐方式 |

### 2.3 对齐方式

#### alignItems (水平对齐)

| 值 | 描述 |
|------|------|
| `HorizontalAlign.Start` | 子组件左对齐 |
| `HorizontalAlign.Center` | 子组件居中对齐（默认） |
| `HorizontalAlign.End` | 子组件右对齐 |

#### justifyContent (垂直对齐)

| 值 | 描述 |
|------|------|
| `FlexAlign.Start` | 子组件顶部对齐（默认） |
| `FlexAlign.Center` | 子组件居中对齐 |
| `FlexAlign.End` | 子组件底部对齐 |
| `FlexAlign.SpaceBetween` | 子组件之间平均分配空间 |
| `FlexAlign.SpaceAround` | 子组件周围平均分配空间 |
| `FlexAlign.SpaceEvenly` | 子组件均匀分配空间 |

## 三、使用示例

### 3.1 基础垂直布局

```typescript
Column({ space: 12 }) {
  Text('标题')
    .fontSize(20)
    .fontWeight(FontWeight.Bold)

  Text('内容文本')
    .fontSize(16)
    .fontColor('#666666')

  Button('确定')
    .width('100%')
}
.width('100%')
.padding(16)
```

### 3.2 对齐方式示例

```typescript
// 水平居中对齐（默认）
Column({ space: 16 }) {
  Text('Left')
    .width(100)
  Text('Center')
    .width(100)
  Text('Right')
    .width(100)
}
.alignItems(HorizontalAlign.Center)

// 垂直居中对齐
Column({ space: 16 }) {
  Text('Top')
  Text('Center')
  Text('Bottom')
}
.width('100%')
.height(200)
.justifyContent(FlexAlign.Center)
```

### 3.3 权重分配

```typescript
Column() {
  Text('Header')
    .height(60)

  Text('Content')
    .layoutWeight(1)  // 占据剩余空间

  Text('Footer')
    .height(40)
}
.width('100%')
.height('100%')
```

### 3.4 嵌套布局

```typescript
Column({ space: 16 }) {
  // 顶部区域
  Row() {
    Text('返回')
      .fontSize(16)
    Text('标题')
      .fontSize(20)
      .layoutWeight(1)
    Text('菜单')
      .fontSize(16)
  }
  .width('100%')

  // 内容区域
  Column() {
    Text('内容')
  }
  .layoutWeight(1)

  // 底部按钮
  Button('确定')
    .width('100%')
}
.width('100%')
.height('100%')
```

## 四、最佳实践

### 4.1 使用 space 设置间距

```typescript
// ✅ 推荐：使用 space 属性
Column({ space: 12 }) {
  Text('Item 1')
  Text('Item 2')
  Text('Item 3')
}

// ❌ 避免：手动设置 margin
Column() {
  Text('Item 1').margin({ bottom: 12 })
  Text('Item 2').margin({ bottom: 12 })
  Text('Item 3')
}
```

### 4.2 明确设置宽度

```typescript
// ✅ 推荐：明确设置宽度
Column({ space: 16 }) {
  Text('Content')
}
.width('100%')

// ⚠️ 注意：不设置宽度可能导致布局问题
Column({ space: 16 }) {
  Text('Content')
}
```

### 4.3 使用 justifyContent 进行垂直对齐

```typescript
// ✅ 推荐：使用 justifyContent
Column({ space: 16 }) {
  Text('Item 1')
  Text('Item 2')
  Text('Item 3')
}
.justifyContent(FlexAlign.Center)

// ❌ 避免：使用 padding 来实现居中
Column({ space: 16 }) {
  Text('Item 1')
  Text('Item 2')
  Text('Item 3')
}
.padding({ top: 100, bottom: 100 })
```

## 五、常见问题

### Q1: Column 的子组件为什么不显示？

**解决方案**:
```typescript
// 确保 Column 有明确的高度或包含在有限容器中
Column({ space: 16 }) {
  Text('Item 1')
  Text('Item 2')
}
.width('100%')
.height('100%')  // 设置高度
```

### Q2: 如何实现等间距布局？

**解决方案**:
```typescript
// 使用 space 属性
Column({ space: 16 }) {
  Text('Item 1')
  Text('Item 2')
  Text('Item 3')
}
```

### Q3: 如何让某个子组件占据剩余空间？

**解决方案**:
```typescript
Column() {
  Text('Fixed Height')
    .height(60)

  Text('Flexible')
    .layoutWeight(1)  // 占据剩余空间
}
.width('100%')
.height(300)
```

## 六、版本兼容性

| API 版本 | 支持状态 | 备注 |
|----------|----------|------|
| API 9+ | ✅ | 完全支持 |
| API 11+ | ✅ | 增加了更多对齐选项 |
| API 18+ | ✅ | 增加了 space 资源类型支持 |

## 七、参考资料

- [Column 沿容器 - 华为开发者官方文档](https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V5/ts-container-column-V5)
- [通用属性 - 华为开发者](https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V5/ts-universal-attributes-size-V5)
