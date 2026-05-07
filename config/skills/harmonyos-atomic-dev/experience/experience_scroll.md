# Scroll 组件开发经验（元服务）

## 一、API 兼容性清单

### Scroll 组件

| API / 属性 | API 版本 | 元服务可用性 | 说明 |
|---|---|---|---|
| `Scroll(scroller?: Scroller)` | 7+ | 11+ | 滚动容器，支持单个子组件 |
| `.scrollable(ScrollDirection)` | 7+ | 11+ | 滚动方向：Vertical(默认) / Horizontal / None |
| `.scrollBar(BarState)` | 7+ | 11+ | 滚动条：Off / Auto(默认) / On |
| `.scrollBarColor(color)` | 7+ | 11+ | 滚动条颜色，默认 '#66182431' |
| `.scrollBarWidth(value)` | 7+ | 11+ | 滚动条宽度，默认 4vp，不支持百分比 |
| `.edgeEffect(effect, options?)` | 7+ | 11+ | 边缘效果：Spring / Fade / None(默认) |
| `.enableScrollInteraction(bool)` | 10+ | 11+ | 是否支持滚动手势 |
| `.nestedScroll(options)` | 10+ | 11+ | 嵌套滚动模式配置 |
| `.friction(value)` | 10+ | 11+ | 摩擦系数，默认 0.75（非可穿戴） |
| `.scrollSnap(options)` | 10+ | 11+ | 限位滚动模式 |
| `.onScrollFrameBegin(callback)` | 9+ | 11+ | 每帧滚动前回调，可控制实际滚动量 |
| `.onScrollEdge(callback)` | 7+ | 11+ | 滚动到边缘回调 |
| `.onScrollStart(callback)` | 9+ | 11+ | 滚动开始回调 |
| `.onScrollStop(callback)` | 9+ | 11+ | 滚动停止回调 |
| `.enablePaging(bool)` | 11+ | 12+ | 翻页模式，与 scrollSnap 同时设置时 scrollSnap 优先 |
| `.initialOffset(options)` | 12+ | 12+ | 初始偏移量，仅在首次布局时生效 |
| `.onWillScroll(callback)` | 12+ | 12+ | 滚动前回调，可返回 OffsetResult 拦截 |
| `.onDidScroll(callback)` | 12+ | 12+ | 滚动时回调，返回偏移量和滚动状态 |
| `.scrollBarColor(color)` (Resource) | 22+ | 22+ | 扩展支持 Resource 类型颜色 |
| `.scrollable(ScrollDirection.FREE)` | 20+ | 20+ | 自由滚动（双向），仅支持部分能力 |
| `.maxZoomScale(scale)` | 20+ | 20+ | 最大缩放比例，默认 1 |
| `.minZoomScale(scale)` | 20+ | 20+ | 最小缩放比例，默认 1 |
| `.zoomScale(scale)` | 20+ | 20+ | 当前缩放比例 |
| `.enableBouncesZoom(bool)` | 20+ | 20+ | 过缩放回弹效果，默认 true |
| `.onDidZoom(callback)` | 20+ | 20+ | 缩放完成回调 |
| `.onZoomStart(callback)` | 20+ | 20+ | 缩放开始回调 |
| `.onZoomStop(callback)` | 20+ | 20+ | 缩放停止回调 |

### Scroller 控制器

| API | API 版本 | 元服务可用性 | 说明 |
|---|---|---|---|
| `new Scroller()` | 7+ | 11+ | 构造函数 |
| `.scrollTo(options)` | 7+ | 11+ | 滑动到指定位置，支持 animation 参数 |
| `.scrollEdge(edge, options?)` | 7+ | 11+ | 滚动到边缘，Scroll 默认有动画 |
| `.scrollPage(options)` | 9+ | 11+ | 翻页，options: { next, animation? } |
| `.scrollBy(dx, dy)` | 9+ | 11+ | 相对滑动距离 |
| `.currentOffset()` | 7+ | 11+ | 获取当前偏移 → { xOffset, yOffset } |
| `.isAtEnd()` | 10+ | 11+ | 是否滚动到底部 |
| `.fling(velocity)` | 12+ | 12+ | 惯性滚动，正数向顶，负数向底 |
| `.getItemRect(index)` | 11+ | 12+ | 获取子组件位置和大小 |
| `.contentSize()` | 22+ | 22+ | 获取内容总大小 |

### ScrollBar 组件

| API / 属性 | API 版本 | 元服务可用性 | 说明 |
|---|---|---|---|
| `ScrollBar(options)` | 8+ | 11+ | 独立滚动条组件 |
| options.scroller | 8+ | 11+ | 绑定 Scroller 控制器（一对一绑定） |
| options.direction | 8+ | 11+ | ScrollBarDirection: Vertical / Horizontal |
| options.state | 8+ | 11+ | BarState: Off / Auto / On |
| `.enableNestedScroll(bool)` | 14+ | 14+ | 嵌套滚动模式 |
| `.scrollBarColor(color)` | 20+ | 20+ | 无子节点时的滚动条颜色 |

### 已废弃 API

| API | 版本范围 | 替代方案 |
|---|---|---|
| `.onScroll(callback)` | 7~12 | `.onWillScroll()` 或 `.onDidScroll()` |
| `.onScrollEnd(callback)` | 7~9 | `.onScrollStop()` |
| `ScrollDirection.Free` (小写) | 7~9 | `ScrollDirection.FREE` (API 20+) |
| `scroller.scrollPage({ next, direction? })` 旧签名 | 7~9 | `scroller.scrollPage({ next, animation? })` |

## 二、场景化调用方式

### 1. 基础垂直滚动 + Scroller 控制

```typescript
private scroller: Scroller = new Scroller()

Scroll(this.scroller) {
  Column() {
    ForEach(items, (item) => { Text(...) })
  }
}
.scrollable(ScrollDirection.Vertical)
.scrollBar(BarState.On)
.scrollBarColor(Color.Gray)
.scrollBarWidth(4)
.edgeEffect(EdgeEffect.Spring)

// 控制
this.scroller.scrollTo({ xOffset: 0, yOffset: 500, animation: true })
this.scroller.scrollEdge(Edge.Top)
this.scroller.scrollPage({ next: true })
this.scroller.scrollBy(0, 200)
const offset = this.scroller.currentOffset() // { xOffset, yOffset }
const atEnd = this.scroller.isAtEnd()
```

- **animation 参数**: boolean 启用默认弹簧动效，或 `ScrollAnimationOptions` 自定义
- **scrollTo 速度 > 200vp/s 时**，区域内组件不响应点击事件
- **Scroller 绑定时机**: `aboutToAppear` 中不可调用（组件未创建），`onAppear` 回调中可以调用

### 2. 滚动方向

```typescript
Scroll()
  .scrollable(ScrollDirection.Vertical)   // 纵向（默认）
  .scrollable(ScrollDirection.Horizontal) // 横向
  .scrollable(ScrollDirection.None)       // 禁止滚动
```

- **修改 scrollable 值会重置滚动偏移量**
- 横向滚动子组件用 `Row`，纵向用 `Column`
- `ScrollDirection.FREE`(API 20+) 自由滚动仅支持部分属性/事件/方法

### 3. ScrollBar 独立滚动条

```typescript
private scroller: Scroller = new Scroller()

Stack({ alignContent: Alignment.End }) {
  Scroll(this.scroller) {
    Column() { /* 内容 */ }
      .margin({ right: 20 })
  }
  .scrollBar(BarState.Off)

  ScrollBar({
    scroller: this.scroller,
    direction: ScrollBarDirection.Vertical,
    state: BarState.Auto
  }) {
    // 自定义滑块子组件
    Text().width(16).height(80).borderRadius(8).backgroundColor('#C0C0C0')
  }
  .width(16)
  .backgroundColor('#F5F5F5')
}
```

- ScrollBar 与可滚动组件通过 scroller **一对一绑定**
- 只有方向相同时才能联动
- API 12+ 无子节点时支持默认样式
- ScrollBar 的 opacity 属性不生效（内部通过 BarState 控制）

### 4. 边缘效果 + 摩擦系数

```typescript
Scroll()
  .edgeEffect(EdgeEffect.Spring)   // 弹簧回弹（推荐）
  .edgeEffect(EdgeEffect.Fade)     // 边缘渐隐
  .edgeEffect(EdgeEffect.None)     // 无效果（默认）
  .friction(0.7)                    // 摩擦系数，默认 0.75
```

- `EdgeEffect.Spring`: 弹簧效果，滚动超出边界后回弹
- `EdgeEffect.Fade`: 边缘渐隐效果
- `friction` 范围 (0, +∞)，≤ 0 按默认值处理。值越小惯性越大
- `edgeEffect` 第二个参数 `options.alwaysEnabled` 控制内容不满时是否仍有效果

### 5. 限位滚动（scrollSnap）

```typescript
Scroll()
  .scrollSnap({
    snapAlign: ScrollSnapAlign.START,
    snapPagination: 400,        // 每页 400vp
    enableSnapToStart: true,
    enableSnapToEnd: true
  })
```

- **snapAlign**: START / CENTER / END / NONE（默认 NONE）
- **snapPagination**: `Dimension`(等间距) 或 `Array<Dimension>`(自定义分页点，需单调递增)
- **enableSnapToStart/enableSnapToEnd**: 仅 Array 模式生效，控制首尾是否自由滑动
- 同时设置 `enablePaging` 和 `scrollSnap` 时，**scrollSnap 优先**
- 限位动画期间 `onWillScroll` 上报的来源类型为 `ScrollSource.FLING`

### 6. 嵌套滚动

```typescript
// 方式一：nestedScroll 属性（推荐）
Scroll() {
  Column() {
    Text('Header')
    List({ scroller: listScroller }) {
      // ...
    }
    .nestedScroll({
      scrollForward: NestedScrollMode.PARENT_FIRST,
      scrollBackward: NestedScrollMode.SELF_FIRST
    })
  }
}
.edgeEffect(EdgeEffect.Spring)

// 方式二：onScrollFrameBegin + scrollBy（精细控制）
Scroll() {
  List()
    .edgeEffect(EdgeEffect.None)
    .onScrollFrameBegin((offset) => {
      if (shouldParentScroll) {
        parentScroller.scrollBy(0, offset)
        return { offsetRemain: 0 }
      }
      return { offsetRemain: offset }
    })
}
```

- **nestedScroll 模式**: SELF_ONLY / SELF_FIRST / PARENT_FIRST / PARALLEL
- **推荐组合**: scrollForward=PARENT_FIRST + scrollBackward=SELF_FIRST（先滚外层向下，先滚内层向上）
- 方式二需要设置子组件 `edgeEffect(EdgeEffect.None)`，否则抛滑会触发回弹动画导致嵌套失效

### 7. 滚动事件

```typescript
Scroll()
  .onScrollStart(() => { /* 滚动开始 */ })
  .onScrollStop(() => { /* 滚动停止 */ })
  .onScrollEdge((side: Edge) => {
    // side: Edge.Top / Bottom / Start / End
  })
  .onScrollFrameBegin((offset: number, state: ScrollState) => {
    // offset: 即将发生的滚动量 (vp)
    // state: Idle / Scroll / Fling
    return { offsetRemain: offset } // 可修改实际滚动量
  })
```

- **onScrollFrameBegin**: 仅用户交互/惯性/fling 触发时回调，scrollTo/scrollEdge 不触发
- 返回 `{ offsetRemain: 新值 }` 可拦截/修改滚动量，`offsetRemain` 支持负值
- **高频回调**: 避免在回调中执行耗时操作
- `ScrollState`: Idle(0) / Scroll(1) / Fling(2)

## 三、编译问题与解决方案

### 问题 1: `@Local direction` 与 CustomComponent 基类属性冲突

**错误**: `Property 'direction' in type 'ScrollDirectionDemo' is not assignable to the same property in base type 'CustomComponent'`

```
@Local direction: ScrollDirection = ScrollDirection.Vertical
```

**原因**: `direction` 是 `CommonAttribute` 的通用属性名（`.direction(Direction)`），ArkTS 编译器将其识别为 CustomComponent 的属性覆盖。

**解决方案**: 避免使用与通用属性同名的状态变量，改用其他名称：

```typescript
// 错误
@Local direction: ScrollDirection = ScrollDirection.Vertical

// 正确
@Local scrollDir: ScrollDirection = ScrollDirection.Vertical
```

### 问题 2: Stack 组件不支持 alignItems

**错误**: `Property 'alignItems' does not exist on type 'StackAttribute'`

```
Stack({ alignContent: Alignment.End }).alignItems(HorizontalAlign.Center)
```

**原因**: Stack 组件使用 `alignContent` 而非 `alignItems` 进行子组件对齐，Stack 没有 `alignItems` 属性。

**解决方案**: 移除 `alignItems` 调用，Stack 通过构造参数 `alignContent` 控制对齐：

```typescript
Stack({ alignContent: Alignment.End }) {
  // 子组件
}
// 不要 .alignItems(...)
```

## 四、降级处理策略

| 场景 | 不可用 API | 降级方案 |
|---|---|---|
| 自由滚动（双向） | `ScrollDirection.FREE` (API 20+) | 嵌套 Scroll（外层纵向 + 内层横向）模拟双向滚动 |
| 图片缩放 | `maxZoomScale/minZoomScale/zoomScale` (API 20+) | PinchGesture + scale 属性自行实现 |
| 缩放事件 | `onDidZoom/onZoomStart/onZoomStop` (API 20+) | PinchGesture 的 onStart/onUpdate/onEnd 替代 |
| 内容总大小 | `Scroller.contentSize()` (API 22+) | `onAreaChange` 获取组件尺寸估算 |
| 废弃滚动事件 | `onScroll` (API 7~12) | 使用 `onWillScroll`(API 12+) 或 `onScrollFrameBegin`(API 11+) |
| 废弃停止事件 | `onScrollEnd` (API 7~9) | 使用 `onScrollStop` |

## 五、注意事项

1. **Scroll 只支持单个子组件**：多内容需用 Column/Row 包裹
2. **子组件最大尺寸**: API 20 及之前为 1000000px，API 21+ 为 16777216px
3. **嵌套 List 时需指定 List 宽高**：否则默认全部加载，影响性能
4. **clip 默认 true**: 内容超出 Scroll 边界会被裁切
5. **layoutWeight**: Scroll 高度超出屏幕时，使用 layoutWeight 让其适应剩余空间
6. **手势冲突**: Scroll 内部已绑定滚动手势，增加自定义手势需参考手势拦截增强
