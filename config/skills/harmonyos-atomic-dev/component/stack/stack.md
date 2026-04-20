# Stack 组件 HarmonyOS 6.0 开发 Skill

## 概述

Stack 组件是 OpenHarmony 中的层叠布局容器，子组件按照添加顺序层叠显示。后添加的子组件会覆盖在前面的子组件上。适用于实现覆盖层、悬浮按钮、叠加效果等场景。

## 重要说明

- **基础组件**: Stack 是 ArkUI 的基础内置组件，无需导入
- **布局方式**: 层叠布局，子组件按添加顺序堆叠
- **对齐方式**: 支持 alignContent 设置所有子组件的整体对齐
- **常用场景**: 悬浮按钮、图片叠加、标签页、进度指示器

## 模块信息

- **组件名称**: Stack
- **SDK 版本**: HarmonyOS 6.0 (API 12+)
- **系统能力**: SystemCapability.ArkUI.ArkUI.Full
- **更新日期**: 2026-02-24
- **官方文档**:
  - [Stack 层叠布局 - 华为开发者](https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V5/ts-container-stack-V5)

## 一、组件基础

### 1.1 导入方式

```typescript
// Stack 是内置组件，无需导入
Stack() {
  Text('Bottom')
  Text('Middle')
  Text('Top')
}
.width(200)
.height(200)
```

### 1.2 基础用法

```typescript
// 基础层叠
Stack() {
  Text('底层内容')
    .width('100%')
    .height('100%')

  Text('中间层')
    .width(200)
    .height(100)

  Text('顶层')
    .width(100)
    .height(60)
}
.width(300)
.height(300)
```

## 二、API 参数

### 2.1 构造参数

| 参数 | 类型 | 必填 | 默认值 | 描述 |
|------|------|------|--------|------|
| options | `StackOptions` | 否 | - | Stack 配置，包含 alignContent |

### 2.2 对齐属性

| 属性 | 类型 | 默认值 | 描述 |
|------|------|--------|------|
| `alignContent` | `Alignment` | Alignment.Center | 所有子组件的整体对齐方式 |

### 2.3 Alignment 对齐选项

| 值 | 描述 |
|------|------|
| `Alignment.TopStart` | 左上对齐 |
| `Alignment.Top` | 居中上对齐 |
| `Alignment.TopEnd` | 右上对齐 |
| `Alignment.Start` | 左侧居中对齐 |
| `Alignment.Center` | 居中对齐（默认） |
| `Alignment.End` | 右侧居中对齐 |
| `Alignment.BottomStart` | 左下对齐 |
| `Alignment.Bottom` | 居中下对齐 |
| `Alignment.BottomEnd` | 右下对齐 |

## 三、使用示例

### 3.1 基础层叠示例

```typescript
Stack() {
  // 底层 - 背景图片
  Image($r('app.media.background'))
    .width('100%')
    .height('100%')
    .objectFit(ImageFit.Cover)

  // 中间层 - 半透明遮罩
  Column() {
    Text('标题')
      .fontSize(24)
      .fontColor(Color.White)
    Text('副标题')
      .fontSize(16)
      .fontColor(Color.White)
  }
  .width('100%')
  .height('100%')
  .justifyContent(FlexAlign.Center)
  .backgroundColor('rgba(0, 0, 0, 0.3)')

  // 顶层 - 关闭按钮
  Button('X')
    .width(40)
    .height(40)
    .position({ x: 10, y: 10 })
}
.width('100%')
.height(200)
```

### 3.2 对齐方式示例

```typescript
// 居中对齐
Stack({ alignContent: Alignment.Center }) {
  Text('Left')
    .width(100)
    .height(100)
    .backgroundColor('#E3F2FD')
  Text('Center')
    .width(80)
    .height(80)
    .backgroundColor('#E8F5E9')
}
.width(200)
.height(200)

// 底部对齐
Stack({ alignContent: Alignment.Bottom }) {
  Text('Item 1')
    .width(120)
    .height(60)
    .backgroundColor('#007DFF')
  Text('Item 2')
    .width(120)
    .height(60)
    .backgroundColor('#28A745')
}
.width('200')
.height(200)
```

### 3.3 图片叠加示例

```typescript
Stack() {
  // 背景图片
  Image($r('app.media.bg_image'))
    .width('100%')
    .height('100%')
    .objectFit(ImageFit.Cover)

  // 渐变遮罩
  Column() {
    Text('图片标题')
      .fontSize(20)
      .fontWeight(FontWeight.Bold)
      .fontColor(Color.White)
    Text('图片描述文字')
      .fontSize(14)
      .fontColor(Color.White)
  }
  .width('100%')
  .height('100%')
  .padding(20)
  .alignItems(HorizontalAlign.Start)
  .backgroundColor('linear-gradient(to bottom, rgba(0,0,0,0.6), transparent)')
}
.width(300)
.height(200)
```

### 3.4 悬浮按钮示例

```typescript
Stack() {
  // 主内容
  Column() {
    Text('主内容区域')
      .fontSize(18)
    // ... 其他内容
  }
  .width('100%')
  .height(400)
  .backgroundColor('#F5F5F5')

  // 悬浮按钮
  Button('+')
    .width(56)
    .height(56)
    .fontSize(24)
    .fontWeight(FontWeight.Bold)
    .fontColor(Color.White)
    .backgroundColor('#007DFF')
    .borderRadius(28)
    .position({ x: 250, y: 320 })
    .shadow({ radius: 10, color: 'rgba(0,0,0,0.3)' })
    .onClick(() => {
      console.info('点击悬浮按钮')
    })
}
.width('100%')
```

## 四、最佳实践

### 4.1 明确设置 Stack 尺寸

```typescript
// ✅ 推荐：明确设置宽度和高度
Stack() {
  // 子组件
}
.width(300)
.height(200)

// ❌ 避免：不设置尺寸可能导致显示异常
Stack() {
  // 子组件
}
```

### 4.2 使用 position 定位子组件

```typescript
// ✅ 推荐：使用 position 精确定位
Stack() {
  Text('Fixed Position')
    .position({ x: 10, y: 20 })

  Text('Relative Position')
}
.width(300)
.height(200)
```

### 4.3 层叠顺序管理

```typescript
// 注意：后添加的组件会显示在前面
Stack() {
  Text('第一层 - 最底层')
    .width('100%')
    .height('100%')

  Text('第二层 - 中间层')
    .width(80%)
    .height(80%)

  Text('第三层 - 最顶层')
    .width(60)
    .height(60%)
}
.width(200)
.height(200)
```

## 五、常见问题

### Q1: Stack 的子组件为什么都重叠在一起？

**解决方案**:
```typescript
// 使用 alignContent 设置对齐
Stack({ alignContent: Alignment.TopStart }) {
  Text('Item 1')
  Text('Item 2')
  Text('Item 3')
}
.width(200)
.height(200)
```

### Q2: 如何让某个子组件显示在最前面？

**解决方案**:
```typescript
// 最后添加的组件会显示在最前面
Stack() {
  Text('Background')
  Text('Middle')
  Text('Foreground')  // 这个显示在最前面
}
```

### Q3: 如何实现绝对定位？

**解决方案**:
```typescript
Stack() {
  Text('Reference')
    .width(100)
    .height(100)

  Text('Absolute')
    .position({ x: 50, y: 50 })
    .width(80)
    .height(60)
}
.width(200)
.height(200)
```

## 六、版本兼容性

| API 版本 | 支持状态 | 备注 |
|----------|----------|------|
| API 9+ | ✅ | 完全支持 |
| API 11+ | ✅ | 增强了对齐选项 |
| API 18+ | ✅ | 优化了 alignContent 属性 |

## 七、参考资料

- [Stack 层叠布局 - 华为开发者官方文档](https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V5/ts-container-stack-V5)
- [Position 定位 - 华为开发者](https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V5/ts-universal-attributes-position-V5)
