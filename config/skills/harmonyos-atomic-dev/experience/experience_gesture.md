# HarmonyOS ArkUI Gesture 手势组件开发实践

## 概述

本文档总结了 HarmonyOS ArkUI 手势系统的完整开发场景，包含 7 个可编译通过的实例，覆盖点击长按、拖拽、捏合旋转、组合手势、手势优先级、滑动触摸、左滑删除卡片等核心场景。

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

## 场景 7：左滑删除卡片

**文件**: `entry/src/main/ets/gesture/gesture-swipe-delete.ets`（struct: `GestureSwipeDelete`）

### 核心思路

使用 Stack 双层布局 + PanGesture 水平拖拽实现左滑删除：
- **底层**：红色删除按钮（固定不动）
- **上层**：卡片内容，通过 `.translate({ x })` 控制偏移露出删除按钮
- **吸附阈值**：滑动超过阈值自动吸附到删除位，否则弹回原位

### PanGesture 水平拖拽

```typescript
PanGesture({ fingers: 1, direction: PanDirection.Horizontal, distance: 5 })
  .onActionStart(() => {
    // 收起其他已展开的卡片
  })
  .onActionUpdate((event: GestureEvent | undefined) => {
    if (event) {
      // 限制偏移范围 [DELETE_THRESHOLD, 0]，不允许右滑
      const offset = Math.min(0, Math.max(-160, event.offsetX))
      // 更新对应卡片的 translate x
    }
  })
  .onActionEnd((event: GestureEvent | undefined) => {
    if (event) {
      // 超过吸附阈值 → 展开删除位，否则弹回
      if (event.offsetX < SNAP_THRESHOLD) {
        offset = DELETE_THRESHOLD  // 吸附到 -120
      } else {
        offset = 0  // 弹回原位
      }
    }
  })
```

### Stack 双层布局

```typescript
Stack({ alignContent: Alignment.End }) {
  // 底层：删除按钮
  Button('删除')
    .backgroundColor('#F44336')
    .onClick(() => { /* 从数组中移除卡片 */ })

  // 上层：卡片内容
  Row() {
    // 图标 + 标题 + 描述
  }
  .translate({ x: offset })  // 关键：通过偏移露出底层按钮
  .gesture(panGesture)       // 绑定拖拽手势
}
```

### 关键参数

| 参数 | 值 | 说明 |
|------|-----|------|
| DELETE_THRESHOLD | -120vp | 删除按钮完全展开的偏移量 |
| SNAP_THRESHOLD | -60vp | 吸附判定阈值，超过即展开 |
| direction | PanDirection.Horizontal | 仅水平方向响应 |
| distance | 5vp | 最小拖动距离 |

### 设计要点

- **互斥交互**：`onActionStart` 时重置所有卡片偏移，确保同时只有一张卡片展开
- **不可变更新**：通过 `[...this.offsetXs]` 创建新数组更新状态
- **ForEach 渲染**：使用卡片 `id` 作为 key，删除后正确触发 UI 更新

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
- [component/gesture/gesture-swipe-delete.ets](component/gesture/gesture-swipe-delete.ets) — 左滑删除卡片