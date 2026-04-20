# Scroll 组件 HarmonyOS 6.0 开发 Skill

## 概述

Scroll 组件是 OpenHarmony 中的可滚动容器，当子组件的尺寸超出容器尺寸时，可以滚动查看。支持垂直和水平滚动，以及滚动条配置。

## 重要说明

- **基础组件**: Scroll 是 ArkUI 的基础内置组件，无需导入
- **滚动方向**: 通过 scrollable 设置滚动方向
- **滚动条**: 支持自定义滚动条样式
- **滚动到指定位置**: 支持 scroller 滚动控制器

## 模块信息

- **组件名称**: Scroll
- **SDK 版本**: HarmonyOS 6.0 (API 12+)
- **系统能力**: SystemCapability.ArkUI.ArkUI.Full
- **更新日期**: 2026-02-24
- **官方文档**:
  - [Scroll 滚动容器 - 华为开发者](https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V5/ts-container-scroll-V5)

## 一、API 参数

| 属性 | 类型 | 默认值 | 描述 |
|------|------|--------|------|
| `scrollable` | `ScrollDirection` | ScrollDirection.Vertical | 滚动方向 |
| `scrollBar` | `BarState` | BarState.Auto | 滚动条状态 |
| `edgeEffect` | `EdgeEffect` | EdgeEffect.Spring | 滚动边缘效果 |

## 二、使用示例

### 2.1 垂直滚动

```typescript
Scroll() {
  Column() {
    ForEach([1, 2, 3, 4, 5], (item: number) => {
      Text(`Item ${item}`)
        .width('100%')
        .height(60)
        .backgroundColor('#F5F5F5')
        .margin({ bottom: 8 })
    })
  }
}
.width('100%')
.height(300)
```

### 2.2 滚动控制器

```typescript
@ComponentV2
struct ScrollControllerExample {
  scroller: Scroller = new Scroller()

  build() {
    Column() {
      Scroll(this.scroller) {
        // 内容
      }
      .scrollable(ScrollDirection.Vertical)
      .width('100%')
      .height(300)

      Button('滚动到底部')
        .onClick(() => {
          this.scroller.scrollEdge(Edge.Bottom)
        })
    }
  }
}
```

## 三、最佳实践

- 对于大量数据列表，优先使用 List 而非 Scroll + Column
- 使用 NestedScroll 实现嵌套滚动
- 合理设置滚动区域高度，避免用户无法感知到可滚动
