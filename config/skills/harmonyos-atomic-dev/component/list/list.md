# List 组件 HarmonyOS 6.0 开发 Skill

## 概述

List 组件是 OpenHarmony 中的列表容器，专门用于显示大量数据项。它支持虚拟滚动（LazyForEach），只渲染可见区域的数据项，提供优秀的性能表现。

## 重要说明

- **基础组件**: List 是 ArkUI 的基础内置组件，无需导入
- **虚拟滚动**: 使用 LazyForEach 实现高性能列表
- **列表项**: 需要配合 ListItem 组件使用
- **性能**: 适合大量数据场景（100+ 项）

## 模块信息

- **组件名称**: List
- **SDK 版本**: HarmonyOS 6.0 (API 12+)
- **系统能力**: SystemCapability.ArkUI.ArkUI.Full
- **更新日期**: 2026-02-24
- **官方文档**:
  - [List 列表 - 华为开发者](https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V5/ts-container-list-V5)

## 一、API 参数

| 属性 | 类型 | 默认值 | 描述 |
|------|------|--------|------|
| `space` | `number \| string \| Resource` | 0 | 列表项间距 |
| `initialIndex` | `number` | 0 | 初始显示项索引 |
| `listDirection` | `ListDirection` | ListDirection.Vertical | 列表方向 |
| `edgeEffect` | `EdgeEffect` | EdgeEffect.Spring | 滚动边缘效果 |
| `lanes` | `number` | 1 | 列表列数 |

## 二、使用示例

### 2.1 基础列表

```typescript
List({ space: 12 }) {
  ForEach([1, 2, 3, 4, 5], (item: string) => {
    ListItem() {
      Text(`Item ${item}`)
        .width('100%')
        .height(60)
        .backgroundColor('#F5F5F5')
        .padding(16)
    }
  })
}
.width('100%')
.height(300)
```

### 2.2 虚拟滚动（高性能）

```typescript
@ComponentV2
struct VirtualListExample {
  @Local dataSource: string[] = []

  aboutToAppear() {
    // 初始化数据
    for (let i = 0; i < 1000; i++) {
      this.dataSource.push(`Item ${i}`)
    }
  }

  build() {
    List({ space: 12 }) {
      LazyForEach(this.dataSource, (item: string, index: number) => {
        ListItem() {
          Text(`${item} - Index: ${index}`)
            .width('100%')
            .height(60)
            .padding(16)
            .backgroundColor('#F5F5F5')
        }
      })
    }
    .width('100%')
    .height('100%')
  }
}
```

### 2.3 分组列表

```typescript
List({ space: 12 }) {
  ForEach(['Group 1', 'Group 2', 'Group 3'], (group: string) => {
    ListItemGroup({ space: 8 }) {
      ForEach([1, 2, 3], (item: number) => {
        ListItem() {
          Text(`${group} - Item ${item}`)
            .width('100%')
            .height(50)
            .padding(12)
            .backgroundColor('#E3F2FD')
        }
      })
    }
  })
}
.width('100%')
.height(300)
```

## 三、最佳实践

- 对于大数据量（>100 项）必须使用 LazyForEach
- 避免在 ListItem 中使用复杂的嵌套结构
- 使用 divider 替代 ListItem 之间的 margin
