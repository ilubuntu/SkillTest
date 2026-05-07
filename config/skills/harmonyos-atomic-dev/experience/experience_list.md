# List 组件开发经验（元服务）

## 一、API 兼容性清单

### List 组件

| API / 属性 | API 版本 | 元服务可用性 | 说明 |
|---|---|---|---|
| `List(options?)` | 7+ | 11+ | 列表容器，支持 space, initialIndex, scroller 参数 |
| `.listDirection(axis)` | 7+ | 11+ | 设置主轴方向：Vertical(默认) / Horizontal |
| `.lanes(value)` | 9+ | 11+ | 交叉轴列数，支持 number 或 LengthConstrain |
| `.alignListItem(align)` | 9+ | 11+ | 交叉轴对齐：Start(默认) / Center / End |
| `.divider(options)` | 9+ | 11+ | 分隔线：strokeWidth, color, startMargin, endMargin |
| `.scrollBar(barState)` | 7+ | 11+ | 滚动条：Off / Auto(默认) / On |
| `.cachedCount(count)` | 9+ | 11+ | 预加载数量，优化长列表性能 |
| `.sticky(stickyStyle)` | 9+ | 11+ | 吸顶/吸底：None / Header / Footer（可组合） |
| `.multiSelectable(bool)` | 9+ | 11+ | 鼠标框选开关 |
| `.scrollBarColor(color)` | 9+ | 11+ | 滚动条颜色 |
| `.scrollBarWidth(width)` | 9+ | 11+ | 滚动条宽度 |
| `.edgeEffect(effect)` | 9+ | 11+ | 滑动效果：Spring / Fade / None |
| `.chainAnimation(options)` | 13+ | 13+ | 联动动画 |

### ListItem 组件

| API / 属性 | API 版本 | 元服务可用性 | 说明 |
|---|---|---|---|
| `ListItem(options?)` | 10+ | 11+ | 列表项，options.style 设置卡片样式 |
| `.selectable(bool)` | 8+ | 11+ | 是否可框选 |
| `.selected(bool)` | 10+ | 11+ | 选中状态，支持 $$ 双向绑定 |
| `.swipeAction(options)` | 9+ | 11+ | 滑动操作：start/end builder、删除回调 |
| `ListItemStyle.CARD` | 10+ | 11+ | 卡片样式枚举 |
| `.sticky(deprecated)` | 7→9 | - | 已废弃，改用 List.sticky() |
| `.editable(deprecated)` | 7→9 | - | 已废弃，无替代 |

### ListItemGroup 组件

| API / 属性 | API 版本 | 元服务可用性 | 说明 |
|---|---|---|---|
| `ListItemGroup(options?)` | 9+ | 11+ | 分组容器，header/footer 为 CustomBuilder |
| `.divider(options)` | 9+ | 11+ | 组内分隔线 |
| `.childrenMainSize(value)` | 12+ | 12+ | 子组件主轴大小信息，需配合 List.childrenMainSize |
| `ListItemGroupStyle.CARD` | 10+ | 11+ | 分组卡片样式 |

### 高级 API（部分受限）

| API | API 版本 | 元服务可用性 | 说明 |
|---|---|---|---|
| `headerComponent/footerComponent` | 13+ | 13+ | ComponentContent 类型头尾组件 |
| `onOffsetChange` (swipeAction) | 11+ | 12+ | 滑动偏移变化回调 |
| `ListItemSwipeActionManager` | 21+ | 21+ | 编程式展开/收起划出菜单 |
| `SwipeActionItem.builderComponent` | 18+ | 18+ | ComponentContent 类型划出组件 |
| `ListScroller` | 7+ | 11+ | 滚动控制器：scrollToIndex, closeAllSwipeActions 等 |

## 二、场景化调用方式

### 1. 基础列表 + 动态增删

```typescript
List({ space: 10 }) {
  ForEach(this.dataList, (item: string, index?: number) => {
    ListItem() {
      // 子组件（单个根节点）
    }
  }, (item: string, index?: number) => `${item}_${index}`)
}
```

- **space**: 列表项主轴间距，默认 0
- **ForEach key**: 建议组合 index 避免重复项导致 key 冲突
- **ListItem**: 只能包含单个子组件，多元素需用 Row/Column 包裹

### 2. 列表方向与多列

```typescript
List({ space: 8 })
  .listDirection(Axis.Horizontal)  // 水平列表
  .lanes(3)                         // 3列布局
  .alignListItem(ListItemAlign.Center)  // 交叉轴居中
```

- 垂直列表 lanes 控制列数，水平列表 lanes 控制行数
- `LengthConstrain` 可根据宽度自适应列数：`{ minLength: 200, maxLength: 300 }`

### 3. 分隔线

```typescript
.divider({
  strokeWidth: 1,
  color: '#E0E0E0',
  startMargin: 16,
  endMargin: 16
})
```

- 分隔线画在两个 ListItem 之间，首尾不画
- strokeWidth/startMargin/endMargin 不支持百分比
- space < strokeWidth 时，间距使用 strokeWidth

### 4. 滚动控制

```typescript
private scroller: ListScroller = new ListScroller()

List({ space: 8, scroller: this.scroller })
  .scrollBar(BarState.Auto)
  .cachedCount(5)

// 滚动到指定项
this.scroller.scrollToIndex(0)
// 关闭所有滑动菜单
this.scroller.closeAllSwipeActions()
```

- `cachedCount` 与 LazyForEach/Repeat(virtualScroll) 配合效果最佳
- `scrollBar` API 10+ 默认值从 Off 改为 Auto

### 5. 分组 + 吸顶

```typescript
List({ space: 12 }) {
  ListItemGroup({
    header: this.groupHeader('A'),
    footer: this.groupFooter(3),
    space: 0
  }) {
    ForEach(items, (item) => { ListItem() { ... } })
  }
  .divider({ strokeWidth: 0.5, color: '#E0E0E0' })
}
.sticky(StickyStyle.Header)  // header 吸顶
```

- `StickyStyle` 可用 `|` 组合：`StickyStyle.Header | StickyStyle.Footer`
- ListItemGroup 宽度默认充满 List
- ListItemGroup 不支持设置 aspectRatio；垂直列表不支持设置 height

### 6. 滑动操作

```typescript
ListItem() { ... }
.swipeAction({
  start: { builder: () => { this.startAction() } },
  end: {
    builder: () => { this.endAction() },
    actionAreaDistance: 56,
    onAction: () => { /* 长滑删除 */ },
    onEnterActionArea: () => { /* 进入删除区 */ },
    onExitActionArea: () => { /* 离开删除区 */ }
  },
  edgeEffect: SwipeEdgeEffect.Spring
})
```

- `SwipeEdgeEffect.Spring`: 弹性效果，可继续滑动
- `SwipeEdgeEffect.None`: 刚性效果，不能超过划出组件大小
- `actionAreaDistance`: 长距删除阈值，默认 56vp
- start/end builder 中顶层必须是单个组件
- 多列模式下划出组件宽度不应太大

### 7. 卡片样式 + 选中

```typescript
ListItemGroup({ style: ListItemGroupStyle.CARD }) {
  ListItem({ style: ListItemStyle.CARD }) {
    ...
  }
  .selectable(true)
  .selected(isSelected)
}
```

- CARD 样式自动添加圆角和阴影
- `selected` 需在设置多态样式前使用才能生效选中态样式

## 三、编译问题与解决方案

### 问题 1: `Array.from` 泛型推断限制

**错误**: `arkts-no-inferred-generic-params` / `arkts-no-any-unknown`

```
Array.from({ length: this.itemCount }, (_, i) => i)
```

**原因**: ArkTS 限制泛型函数调用的类型推断，`Array.from` 的回调参数 `_` 会被推断为 `any` 类型。

**解决方案**: 改用显式类型的方法生成数组：

```typescript
// 替代方案
private generateItems(): number[] {
  const items: number[] = []
  for (let i = 0; i < this.itemCount; i++) {
    items.push(i)
  }
  return items
}
```

### 问题 2: ForEach key 生成

在动态增删场景中，仅用 `item` 作为 key 可能导致重复。建议组合 index：

```typescript
(item: string, index?: number) => `${item}_${index}`
```

## 四、降级处理策略

| 场景 | 不可用 API | 降级方案 |
|---|---|---|
| 编程式控制划出菜单 | `ListItemSwipeActionManager` (API 21+) | 使用 `ListScroller.closeAllSwipeActions()` 替代 |
| ComponentContent 头尾组件 | `headerComponent/footerComponent` (API 13+) | 使用 `@Builder` 函数的 `header/footer` 参数 |
| ComponentContent 划出组件 | `SwipeActionItem.builderComponent` (API 18+) | 使用 `@Builder` 函数的 `builder` 参数 |
| 子组件主轴大小 | `childrenMainSize` (API 12+) | 不设置，使用默认布局 |

## 五、性能建议

1. **长列表优先使用 LazyForEach 或 Repeat(virtualScroll)** 配合 cachedCount，避免 ForEach 全量创建
2. **cachedCount 设置合理值**：一般 5-10 即可，过大会增加内存开销
3. **ListItem 高度固定时** 可配合 `childrenMainSize` (API 12+) 提升性能
4. **避免在 ListItem 中嵌套过深的组件树**，减少布局计算
