# Flex 组件 HarmonyOS 6.0 开发 Skill

## 概述

Flex 组件是 OpenHarmony 中的弹性布局容器，支持横向和纵向排列，提供灵活的对齐和空间分配。它是 Flex 布局的核心实现，适用于各种复杂的响应式布局场景。

## 重要说明

- **基础组件**: Flex 是 ArkUI 的基础内置组件，无需导入
- **布局方向**: 通过 direction 设置横向或纵向
- **弹性布局**: 支持权重分配和空间均分
- **wrap 属性**: 支持自动换行

## 模块信息

- **组件名称**: Flex
- **SDK 版本**: HarmonyOS 6.0 (API 12+)
- **系统能力**: SystemCapability.ArkUI.ArkUI.Full
- **更新日期**: 2026-02-24
- **官方文档**:
  - [Flex 弹性布局 - 华为开发者](https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V5/ts-container-flex-V5)

## 一、API 参数

| 属性 | 类型 | 默认值 | 描述 |
|------|------|--------|------|
| `direction` | `FlexDirection` | FlexDirection.Row | 子组件排列方向 |
| `wrap` | `FlexWrap` | FlexWrap.NoWrap | 是否换行 |
| `justifyContent` | `FlexAlign` | FlexAlign.Start | 主轴对齐 |
| `alignItems` | `ItemAlign` | ItemAlign.Start | 交叉轴对齐 |
| `alignContent` | `FlexAlign` | FlexAlign.Start | 多行交叉轴对齐 |

## 二、使用示例

### 2.1 横向弹性布局

```typescript
Flex({ direction: FlexDirection.Row }) {
  Text('Item 1')
  Text('Item 2')
  Text('Item 3')
}
.width('100%')
.justifyContent(FlexAlign.SpaceBetween)
```

### 2.2 权重分配

```typescript
Flex({ direction: FlexDirection.Row }) {
  Text('Flex 1')
    .layoutWeight(1)
  Text('Flex 2')
    .layoutWeight(2)
}
.width('100%')
```

### 2.3 换行布局

```typescript
Flex({
  direction: FlexDirection.Row,
  wrap: FlexWrap.Wrap
}) {
  ForEach([1, 2, 3, 4, 5, 6], (item: number) => {
    Text(`Item ${item}`)
      .padding(8)
      .margin({ right: 8, bottom: 8 })
      .backgroundColor('#E3F2FD')
      .borderRadius(4)
  })
}
.width('100%')
```

## 三、最佳实践

使用 Flex 替代 Column 和 Row 的场景：
- 需要动态改变布局方向
- 需要使用 wrap 换行功能
- 复杂的权重分配场景
