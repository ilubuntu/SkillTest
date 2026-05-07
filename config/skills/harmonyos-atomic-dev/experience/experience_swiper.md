# Swiper 组件开发经验

## 元服务 API 兼容性清单

### 可用 API（API 7+）

| API | 说明 | 引入版本 |
|-----|------|----------|
| `Swiper() { ... }` | 基础轮播容器 | API 7 |
| `Swiper(controller) { ... }` | 绑定 SwiperController | API 7 |
| `.loop(boolean)` | 循环播放（默认 true） | API 7 |
| `.autoPlay(boolean)` | 自动轮播（默认 false） | API 7 |
| `.interval(number)` | 自动播放间隔 ms（默认 3000） | API 7 |
| `.duration(number)` | 子组件切换动画时长 ms | API 7 |
| `.indicator(boolean)` | 显示/隐藏导航点（默认 true） | API 7 |
| `.vertical(boolean)` | 垂直方向轮播（默认 false） | API 7 |
| `.onChange((index) => void)` | 页面切换回调 | API 7 |
| `.index(number)` | 设置初始显示页索引 | API 7 |
| `new SwiperController()` | 轮播控制器 | API 7 |
| `controller.showNext()` | 切换到后一页 | API 7 |
| `controller.showPrevious()` | 切换到前一页 | API 7 |
| `controller.changeIndex(index)` | 跳转到指定页 | API 7 |

### 可用但需注意版本（API 8+）

| API | 说明 | 引入版本 |
|-----|------|----------|
| `new DotIndicator()` | 自定义圆点指示器样式 | API 8 |
| `.itemWidth / .itemHeight` | 未选中圆点尺寸 | API 8 |
| `.selectedItemWidth / .selectedItemHeight` | 选中圆点尺寸 | API 8 |
| `.color / .selectedColor` | 圆点颜色配置 | API 8 |
| `new DigitIndicator()` | 数字导航点指示器 | API 8 |

### 受限 / 不支持 API

| API | 说明 | 限制原因 |
|-----|------|----------|
| `ArcSwiper` | 弧形轮播组件 | 仅 Wearable 设备，API 18+ |
| `.customContentTransition()` | 自定义切换动画 | API 12+，依赖 SwiperContentTransitionProxy |
| `.displayArrow()` | 导航点箭头 | API 10+，依赖 SwiperArrowStyle |
| `.prevMargin / .nextMargin` | 前后露出 | API 10+，用于卡片式轮播 |
| `.displayCount()` | 每页显示多个子页面 | API 8+ 可用但需注意布局 |
| `.maintainVisibleContentPosition()` | 保持可见内容位置 | API 20+ |
| `SwiperDynamicSyncScene` | 多 Swiper 联动同步 | API 12+ |
| `.onAnimationStart / .onAnimationEnd` | 动画开始/结束回调 | API 12+ |
| `.onGestureSwipe` | 手势滑动回调 | API 12+ |

## 各场景核心调用方式

### 1. 基础轮播（循环 + 自动播放）

```typescript
Swiper() {
  ForEach(colors, (color: string, index: number) => {
    Text(`${index}`).backgroundColor(color)
  }, (color: string, index: number) => `${index}`)
}
.loop(true)
.autoPlay(true)
.interval(3000)
.duration(500)
.indicator(true)
.onChange((index: number) => { /* 处理切换 */ })
```

**要点**：
- `loop` 默认为 true，设为 false 时到首尾页无法继续切换
- `autoPlay` 需配合 `loop(true)` 使用效果最佳；`loop(false)` 时自动播放到最后一页会停止
- `interval` 单位为毫秒，最小建议 500ms，默认 3000ms

### 2. 轮播方向控制

```typescript
Swiper() { /* 子组件 */ }
.vertical(true)  // true=垂直, false=水平（默认）
```

**要点**：
- 垂直模式下指示器自动调整为纵向布局
- 垂直模式下手势为上下滑动

### 3. 导航点指示器

```typescript
// 默认圆点
.indicator(true)

// 自定义圆点样式
.indicator(
  new DotIndicator()
    .itemWidth(8).itemHeight(8)
    .selectedItemWidth(20).selectedItemHeight(8)
    .color('#CCCCCC').selectedColor('#FF6B00')
)

// 隐藏指示器
.indicator(false)
```

**要点**：
- `DotIndicator` 需要 API 8+，使用 `new DotIndicator()` 链式调用
- `selectedItemWidth` 可以大于 `itemWidth` 形成胶囊选中效果
- 需要导入 `import { LengthMetrics } from '@kit.ArkUI'`（使用 LengthMetrics 参数时）

### 4. SwiperController 控制器

```typescript
private swiperController: SwiperController = new SwiperController()

Swiper(this.swiperController) { /* 子组件 */ }

// 切换方法
this.swiperController.showNext()
this.swiperController.showPrevious()
this.swiperController.changeIndex(targetIndex)
```

**要点**：
- 控制器必须通过 `Swiper(controller)` 传入才能生效
- `changeIndex` 跳转到不存在的索引时会自动 clamp 到有效范围
- `loop(false)` 时 `showNext`/`showPrevious` 在边界不生效


## 降级处理策略

| 原始 API | 降级方案 |
|----------|----------|
| ArcSwiper（弧形轮播） | 标准Swiper + `vertical(true)` 模拟竖向效果 |
| customContentTransition（自定义动画） | 内置 `duration + curve` + `animateTo` |
| displayArrow（导航箭头） | 自定义 Button 叠加 + SwiperController 切换 |
| prevMargin/nextMargin（前后露出） | `displayCount` 显示多页 + 自定义宽度 |
| maintainVisibleContentPosition | 数据变更后手动 `changeIndex` 恢复位置 |
| SwiperDynamicSyncScene（多 Swiper 联动） | `onChange` 回调 + 多个 controller 的 `changeIndex` |
