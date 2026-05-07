# Refresh 组件元服务开发经验

## 一、API 兼容性清单

### API 11+ 可用（元服务基础能力）

| API | 类型 | 说明 |
|-----|------|------|
| `Refresh({ refreshing })` | 接口 | 创建下拉刷新容器，refreshing 支持 `$$` 双向绑定 |
| `refreshing` | 参数 | boolean，控制刷新状态，必须使用 `$$` 双向绑定 |
| `builder` | 参数 | CustomBuilder，自定义刷新区域显示内容 |
| `onStateChange` | 事件 | 回调参数 `RefreshStatus`，状态变更时触发 |
| `onRefreshing` | 事件 | 进入刷新状态时触发（无参数回调） |
| `RefreshStatus` | 枚举 | Inactive=0, Drag=1, OverDrag=2, Refresh=3, Done=4 |

### API 12+ 可用（元服务增强能力）

| API | 类型 | 说明 |
|-----|------|------|
| `promptText` | 参数 | ResourceStr，刷新区域底部显示自定义文本 |
| `refreshingContent` | 参数 | ComponentContent，自定义刷新区域（推荐替代 builder） |
| `refreshOffset(value)` | 属性 | 触发刷新的下拉偏移量，默认 64vp（有 promptText 时为 96vp） |
| `pullToRefresh(value)` | 属性 | boolean，下拉超过 offset 时是否触发刷新，默认 true |
| `pullDownRatio(ratio)` | 属性 | 下拉跟手系数 0~1，0=不跟手，1=等比，undefined=动态系数 |
| `onOffsetChange` | 事件 | 回调参数 number，实时返回下拉距离 (vp) |

### API 20+ 可用

| API | 类型 | 说明 |
|-----|------|------|
| `maxPullDownDistance(distance)` | 属性 | 设置最大下拉距离 (vp) |

### 已废弃（API 11 废弃）

| API | 说明 | 替代方案 |
|-----|------|---------|
| `offset` | 下拉起点距离顶部 | 无替代，已废弃 |
| `friction` | 下拉摩擦系数 0~100 | 使用 `pullDownRatio`（API 12+，范围 0~1） |

## 二、各场景核心调用方式

### 2.1 基础下拉刷新

```typescript
Refresh({ refreshing: $$this.isRefreshing }) {
  List() { /* 子组件 */ }
}
.onStateChange((state: RefreshStatus) => { /* 状态变更 */ })
.onRefreshing(() => {
  // 刷新逻辑
  setTimeout(() => { this.isRefreshing = false }, 2000)
})
```

关键点：`refreshing` 必须用 `$$` 双向绑定，在 `onRefreshing` 回调中设置 `false` 结束刷新。

### 2.2 自定义刷新区域 (builder)

```typescript
@Builder
customRefreshComponent() {
  Stack() {
    Row() {
      LoadingProgress().height(32)
      Text('刷新中...').fontSize(16)
    }
  }
  .constraintSize({ minHeight: 32 })  // 防止高度塌陷
  .width('100%')
}

Refresh({ refreshing: $$this.isRefreshing, builder: this.customRefreshComponent() }) { ... }
```

关键点：
- 必须设置 `constraintSize({ minHeight })` 防止组件高度跟随刷新区域变为 0
- API 12+ 建议使用 `refreshingContent` 替代 `builder`，避免销毁重建导致动画中断

### 2.3 刷新区域文本提示 (promptText)

```typescript
Refresh({ refreshing: $$this.isRefreshing, promptText: '下拉即可刷新' }) { ... }
  .pullToRefresh(true)
  .refreshOffset(96)  // 设置 promptText 后默认变为 96vp
```

关键点：使用 `builder`/`refreshingContent` 时 `promptText` 不显示。

### 2.4 下拉跟手系数控制

```typescript
Refresh({ refreshing: $$this.isRefreshing }) { ... }
  .pullDownRatio(0.5)      // 0=不跟手, 1=等比跟手
  .pullToRefresh(true)     // 超过 offset 是否触发刷新
  .refreshOffset(64)       // 触发刷新的偏移量 (vp)
```

### 2.5 动态最大下拉距离（模拟 maxPullDownDistance）

API 12~19 中可通过 `onOffsetChange` + 动态 `pullDownRatio` 模拟：

```typescript
.onOffsetChange((offset: number) => {
  this.ratio = 1 - Math.pow(offset / this.maxPullDistance, 3)
})
.pullDownRatio(this.ratio)
```

### 2.6 refreshingContent 自定义（API 12+）

使用 `ComponentContent` 替代 `builder`，避免动画中断：

```typescript
import { ComponentContent } from '@kit.ArkUI'

// 定义参数类
class Params { refreshStatus: RefreshStatus = RefreshStatus.Inactive }

// 全局 @Builder function（非组件方法）
@Builder function customContent(params: Params) { /* 自定义 UI */ }

// 在 aboutToAppear 中创建
this.contentNode = new ComponentContent(
  this.getUIContext(),
  wrapBuilder(customContent),
  this.params
)

// 使用
Refresh({ refreshing: $$this.isRefreshing, refreshingContent: this.contentNode }) { ... }
```

关键点：`refreshingContent` 需要全局 `@Builder function`（非组件方法），通过 `ComponentContent` 包装，状态更新通过 `contentNode.update(params)` 实现。

## 三、RefreshStatus 状态机

```
Inactive (0) ──下拉──> Drag (1)
Drag (1) ──超过 offset──> OverDrag (2)
Drag (1) ──松手──> Inactive (0)
OverDrag (2) ──松手──> Refresh (3)
OverDrag (2) ──上滑低于 offset──> Drag (1)
Refresh (3) ──refreshing=false──> Done (4)
Done (4) ──动画完成──> Inactive (0)
```

## 四、编译问题与解决方案

### 4.1 refreshing 双向绑定

**问题**：直接赋值 `refreshing: this.isRefreshing` 不会自动更新。

**解决**：必须使用 `$$this.isRefreshing` 双向绑定语法，Refresh 组件内部会自动修改该值。

## 五、降级处理策略

| 场景 | API 12+ 方案 | API 11 降级方案 |
|------|-------------|----------------|
| 下拉跟手控制 | `pullDownRatio` | 无直接替代，接受默认行为 |
| 触发偏移量 | `refreshOffset` | 无直接替代，使用默认 64vp |
| 最大下拉距离 | `maxPullDownDistance`(API 20) 或动态 ratio(API 12) | 无法限制 |
| 自定义刷新内容 | `refreshingContent`(ComponentContent) | `builder`(CustomBuilder) |
| 刷新文本提示 | `promptText` | 使用 builder 自定义包含文本的组件 |
| 偏移量追踪 | `onOffsetChange` | 仅通过 `onStateChange` 间接判断 |

## 六、注意事项

1. **子组件限制**：Refresh 仅支持单个子组件，通常是 List、Grid、Scroll 等可滚动容器
2. **Swiper 联动**：API 12+ 支持与垂直滚动 Swiper 联动，但 Swiper `loop=true` 时无法联动
3. **不满一屏**：子组件内容不满一屏时需设置 List 的 `edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })` 才能触发刷新
4. **鼠标操作**：组件无法通过鼠标按下拖动进行下拉刷新
5. **手势冲突**：Refresh 内部已绑定手势，自定义手势需参考手势拦截增强处理
6. **SwipeRefresher**：`@kit.ArkUI` 提供的 SwipeRefresher 组件（API 11+ 元服务可用）是另一种下拉刷新方案，接口更简单
