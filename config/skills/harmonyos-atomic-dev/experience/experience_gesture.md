# HarmonyOS ArkUI Gesture 手势组件开发实践

> 基于 app-wiki 查询 + 实际编译验证 | 2026-04-16

## 概述

本文档总结了 HarmonyOS ArkUI 手势系统的完整开发场景，包含 6 个可编译通过的实例，覆盖点击长按、拖拽、捏合旋转、组合手势、手势优先级、滑动触摸等核心场景。

---

## 手势体系总览

| 类别 | 手势 | 说明 |
|------|------|------|
| **单一手势** | TapGesture、LongPressGesture、PanGesture、PinchGesture、RotationGesture、SwipeGesture | 识别单一手势动作 |
| **组合手势** | GestureGroup | 将多个手势组合，支持 Sequence/Parallel/Exclusive 模式 |
| **手势事件** | GestureEvent 回调 | 获取手指位置、速度、缩放比例、旋转角度等 |

### 手势绑定方法

| 方法 | 优先级 | 用途 |
|------|--------|------|
| `.gesture()` | 子组件优先 | 默认绑定 |
| `.priorityGesture()` | 父组件优先 | 覆盖子组件手势 |
| `.parallelGesture()` | 父子并行 | 同时响应 |

---

## 场景 1：点击与长按

**文件**: `entry/src/main/ets/gesture/gesture-tap.ets`（struct: `GestureTap`）

### TapGesture

```typescript
// 单击
TapGesture({ count: 1 })
  .onAction(() => { /* 点击回调 */ })

// 双击
TapGesture({ count: 2 })
  .onAction(() => { /* 双击回调 */ })
```

### LongPressGesture

```typescript
LongPressGesture({ fingers: 1, repeat: true, duration: 500 })
  .onAction((event: GestureEvent | undefined) => {
    if (event && event.repeat) { /* 持续回调 */ }
  })
  .onActionEnd(() => { /* 手指抬起 */ })
```

- `fingers` — 触发所需最少手指数（默认 1）
- `repeat` — 是否持续回调（默认 false）
- `duration` — 最短长按时间（ms，默认 500）

---

## 场景 2：拖拽

**文件**: `entry/src/main/ets/gesture/gesture-pan.ets`（struct: `GesturePan`）

### PanGesture

```typescript
PanGesture({ fingers: 1, direction: PanDirection.All, distance: 5 })
  .onActionStart(() => { /* 开始 */ })
  .onActionUpdate((event: GestureEvent | undefined) => {
    if (event) {
      // event.offsetX / event.offsetY 获取偏移量
    }
  })
  .onActionEnd((event: GestureEvent | undefined) => { /* 结束 */ })
```

- `direction` — `PanDirection.All` / `Horizontal` / `Vertical` / `Left` / `Right` / `Up` / `Down`
- `distance` — 最小拖动距离阈值（默认 5vp）

**拖拽位置记录技巧**: 使用 `positionX/Y` 记录基础位置，每次 `onActionEnd` 累加偏移量，配合 `.translate({ x, y })` 实现自由拖拽。

---

## 场景 3：捏合与旋转

**文件**: `entry/src/main/ets/gesture/gesture-pinch.ets`（struct: `GesturePinch`）

### PinchGesture

```typescript
PinchGesture({ fingers: 2 })
  .onActionUpdate((event: GestureEvent | undefined) => {
    if (event) {
      // event.scale — 缩放倍数
      // event.pinchCenterX / pinchCenterY — 捏合中心
    }
  })
```

### RotationGesture

```typescript
RotationGesture({ fingers: 2 })
  .onActionUpdate((event: GestureEvent | undefined) => {
    if (event) {
      // event.angle — 旋转角度
    }
  })
```

**并行组合**: 捏合和旋转通常需要同时支持，使用 `GestureGroup(GestureMode.Parallel, ...)` 组合。

**缩放/旋转记录**: 与拖拽类似，使用 `pinchScale` / `rotateAngle` 记录基础值，`onActionEnd` 时累加。

---

## 场景 4：组合手势

**文件**: `entry/src/main/ets/gesture/gesture-group.ets`（struct: `GestureGroupDemo`）

### GestureMode 三种模式

| 模式 | 行为 | 典型场景 |
|------|------|---------|
| `GestureMode.Sequence` | 串行，按顺序识别 | 长按 → 拖拽 |
| `GestureMode.Parallel` | 并行，所有手势同时识别 | 单击 + 双击共存 |
| `GestureMode.Exclusive` | 互斥，最先完成的胜出 | 单击 vs 双击 |

**重要**: 枚举是 `GestureMode.Sequence`，不是 `Serial`。

### 串行示例：长按后拖拽

```typescript
GestureGroup(GestureMode.Sequence,
  LongPressGesture({ duration: 500 })
    .onAction(() => { /* 长按成功 */ }),
  PanGesture()
    .onActionUpdate((event) => { /* 拖拽中 */ })
)
```

---

## 场景 5：手势优先级

**文件**: `entry/src/main/ets/gesture/gesture-priority.ets`（struct: `GesturePriority`）

### 父子组件手势竞争

```typescript
// 默认：子优先
Column() {
  Text('子').gesture(TapGesture().onAction(() => { /* 子响应 */ }))
}.gesture(TapGesture().onAction(() => { /* 父响应（被子吞掉）*/ }))

// 父优先
Column() {
  Text('子').gesture(TapGesture().onAction(() => {}))
}.priorityGesture(TapGesture().onAction(() => { /* 父优先 */ }))

// 并行
Column() {
  Text('子').gesture(TapGesture().onAction(() => { /* 子也响应 */ }))
}.parallelGesture(TapGesture().onAction(() => { /* 父也响应 */ }))
```

---

## 场景 6：滑动与触摸

**文件**: `entry/src/main/ets/gesture/gesture-swipe.ets`（struct: `GestureSwipe`）

### SwipeGesture

```typescript
SwipeGesture({ fingers: 1, direction: SwipeDirection.All, speed: 50 })
  .onAction((event: GestureEvent | undefined) => {
    if (event) {
      // event.speed — 滑动速度
      // event.angle — 滑动角度
    }
  })
```

### onTouch 原始触摸

```typescript
.onTouch((event: TouchEvent) => {
  if (event.type === TouchType.Down) { /* 按下 */ }
  if (event.type === TouchType.Move) { /* 移动 */ }
  if (event.type === TouchType.Up)   { /* 抬起 */ }
  // event.changedTouches[0].x / y — 触摸坐标
})
```

---

## 编译踩坑记录

| 问题 | 错误信息 | 解决方案 |
|------|---------|---------|
| GestureMode.Serial 不存在 | `Property 'Serial' does not exist on type 'typeof GestureMode'` | 使用 `GestureMode.Sequence` |
| Column 上使用 fontSize | `Property 'fontSize' does not exist on type 'ColumnAttribute'` | `fontSize` 只能用于 Text 组件，需在每个 Text 上单独设置 |
| GestureEvent 可能为空 | 类型安全 | 回调参数使用 `GestureEvent \| undefined`，先判空再使用 |

---

## 事例代码
- [component/gesture/gesture-tap.ets](component/gesture/gesture-tap.ets) — TapGesture 点击手势
- [component/gesture/gesture-pan.ets](component/gesture/gesture-pan.ets) — PanGesture 拖动手势
- [component/gesture/gesture-pinch.ets](component/gesture/gesture-pinch.ets) — PinchGesture 捏合手势
- [component/gesture/gesture-swipe.ets](component/gesture/gesture-swipe.ets) — SwipeGesture 滑动手势
- [component/gesture/gesture-group.ets](component/gesture/gesture-group.ets) — GestureGroup 手势组合