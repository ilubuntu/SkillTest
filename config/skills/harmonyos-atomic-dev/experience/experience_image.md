# HarmonyOS ArkUI Image 组件开发实践

## 概述

本文档总结了 HarmonyOS ArkUI `Image` 组件的常见开发场景，包含 5 个可编译通过的实例，覆盖图片来源、缩放裁剪、交互事件、样式渲染、列表图片等核心场景。

---

## 场景 1：图片来源

**文件**: `entry/src/main/ets/image/image-basic.ets`（struct: `ImageBasic`）

| 来源类型 | 代码 | 说明 |
|---------|------|------|
| 资源引用 | `Image($r('app.media.icon'))` | 引用 `resources/base/media/` 下的图片 |
| 网络图片 | `Image('https://...')` | 需声明 `ohos.permission.INTERNET` 权限 |
| 资源引用 2 | `Image($r('app.media.startIcon'))` | 同 $r()，引用不同资源 |
| Base64 | `Image('data:image/png;base64,...')` | 支持 png/jpeg/bmp/webp/heif |

**关键 API**:
- `.alt($r('app.media.icon'))` — 加载占位图
- `.onComplete()` — 加载成功回调
- `.onError()` — 加载失败回调

**注意事项**:
- `$rawfile()` 需要 rawfile 目录存在对应文件，否则编译报错
- 网络图片在模拟器/预览器中可能因网络权限问题加载失败，务必使用 `.alt()` 设置占位图

---

## 场景 2：缩放与裁剪

**文件**: `entry/src/main/ets/image/image-fit.ets`（struct: `ImageFitScale`）

> **命名避坑**: struct 不能命名为 `ImageFit`，会与 ArkUI 内置枚举 `ImageFit` 冲突导致编译失败。

### objectFit 枚举值

| 值 | 效果 | 典型场景 |
|----|------|---------|
| `ImageFit.Cover` | 保持比例裁剪填满 | 头像、封面图 |
| `ImageFit.Contain` | 保持比例完整显示 | 商品图、Logo |
| `ImageFit.Fill` | 拉伸填满 | 背景图（可能变形） |
| `ImageFit.ScaleDown` | 缩小适配 | 大图小容器 |
| `ImageFit.None` | 不缩放 | 原始尺寸展示 |

### 圆角裁剪

```typescript
Image($r('app.media.icon'))
  .clip(true)           // 启用裁剪
  .borderRadius(40)     // 40px = 圆形（width/2）
```

支持四种角分别设置:[task_task_0_10_20260416_115655.log](..%2F..%2F..%2F..%2F..%2FuiDemo%2F0417%2F20260416115655%2F0%2F.opencode_logs%2Ftask_task_0_10_20260416_115655.log)
```typescript
.borderRadius({ topLeft: 20, topRight: 20, bottomLeft: 0, bottomRight: 0 })
```

---

## 场景 3：交互事件

**文件**: `entry/src/main/ets/image/image-event.ets`（struct: `ImageEvent`）

### 加载回调

| 回调 | 触发时机 |
|------|---------|
| `.onComplete()` | 图片加载成功 |
| `.onError()` | 图片加载失败 |

### 手势交互

```typescript
.gesture(
  GestureGroup(GestureMode.Exclusive,
    LongPressGesture().onAction(() => { /* 长按 */ }),
    TapGesture({ count: 2 }).onAction(() => { /* 双击 */ })
  )
)
```

支持的手势: `TapGesture`、`LongPressGesture`、`PanGesture`（拖拽）、`PinchGesture`（捏合）、`RotationGesture`（旋转）

**注意**: 多手势需用 `GestureGroup` 包裹，设置 `GestureMode.Exclusive` 或 `.Parallel`

### 动画缩放

```typescript
Image(url)
  .width(250 * this.imageScale)
  .height(180 * this.imageScale)
  .animation({ duration: 300 })  // 属性变化时自动动画
```

---

## 场景 4：样式与渲染

**文件**: `entry/src/main/ets/image/image-style.ets`（struct: `ImageStyle`）

### 渲染模式

```typescript
Image($r('app.media.icon'))
  .renderMode(ImageRenderMode.Original)  // 原色
  .renderMode(ImageRenderMode.Template)  // 黑白模板（SVG 着色用）
```

**重要**: 枚举类型是 `ImageRenderMode`，不是 `RenderMode`，否则编译报错。

### fillColor 着色

```typescript
Image($r('app.media.icon'))
  .renderMode(ImageRenderMode.Template)  // 必须先设为模板模式
  .fillColor('#FF0000')                   // 着色
```

### 模糊效果

```typescript
Image($r('app.media.startIcon'))
  .blur(this.blurValue)  // 0-50，值越大越模糊
```

### 插值质量

```typescript
.interpolation(ImageInterpolation.None)   // 无插值
.interpolation(ImageInterpolation.Low)    // 低质量
.interpolation(ImageInterpolation.Medium) // 中等（推荐列表使用）
.interpolation(ImageInterpolation.High)   // 高质量（推荐大图使用）
```

---

## 场景 5：列表图片

**文件**: `entry/src/main/ets/image/image-list.ets`（struct: `ImageList`）

### sourceSize 解码优化

```typescript
Image($r('app.media.icon'))
  .width(80)
  .height(80)
  .sourceSize({ width: 160, height: 160 })  // 2x 解码，匹配屏幕密度
```

**原理**: 指定解码目标尺寸，避免解码超大图片浪费内存。

### ArkTS 数组初始化

ArkTS 不支持 `Array.from()` 的泛型推断，需用显式循环:

```typescript
// 错误 — ArkTS 编译失败
@State images: ImageItem[] = Array.from({ length: 15 }, (_, i) => ({ ... }))

// 正确 — 显式类型 + 循环
private buildImageList(): ImageItem[] {
  const list: ImageItem[] = []
  for (let i = 0; i < 15; i++) {
    list.push({ id: i, title: `图片 ${i + 1}` })
  }
  return list
}
```

---

## 编译踩坑记录

| 问题 | 错误信息 | 解决方案 |
|------|---------|---------|
| RenderMode 不存在 | `Property 'Original' does not exist on type 'typeof RenderMode'` | 使用 `ImageRenderMode.Original/Template` |
| struct 命名冲突 | `Property 'Cover' does not exist on type 'typeof ImageFit'` | struct 不能命名为 `ImageFit`，改用 `ImageFitScale` |
| Array.from 泛型推断 | `Type inference in case of generic function calls is limited` | 改用显式 for 循环 + 类型声明 |
| rawfile 不存在 | `No such 'icon.png' resource in current module` | 使用 `$r('app.media.icon')` 或确保 rawfile 目录有文件 |
| undefined 传给 fillColor | 类型不匹配 | 传空字符串 `''` 代替 `undefined` |

---

## 事例代码
- [component/image/image-basic.ets](component/image/image-basic.ets) — Image 图片基础用法
- [component/image/image-fit.ets](component/image/image-fit.ets) — Image 缩放类型 (objectFit)
- [component/image/image-event.ets](component/image/image-event.ets) — Image 事件处理 (onComplete, onError)
- [component/image/image-style.ets](component/image/image-style.ets) — Image 样式设置
- [component/image/image-list.ets](component/image/image-list.ets) — Image 列表加载示例
