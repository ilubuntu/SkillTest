# ScrollBar 组件开发经验

## 元服务 API 兼容性清单

| API | 起始版本 | 元服务支持 | 说明 |
|-----|---------|-----------|------|
| `ScrollBar(value: ScrollBarOptions)` | API 8 | API 11+ | 构造函数 |
| `ScrollBarOptions.scroller` | API 8 | API 11+ | Scroller 控制器绑定 |
| `ScrollBarOptions.direction` | API 8 | API 11+ | ScrollBarDirection 枚举 |
| `ScrollBarOptions.state` | API 8 | API 11+ | BarState 枚举 |
| 无子节点默认样式 | API 12 | API 12+ | 不设子节点时显示默认滚动条 |
| `enableNestedScroll(enabled)` | API 14 | API 14+ | 嵌套滚动开关 |
| `scrollBarColor(color)` | API 20 | API 20+ | 滑块颜色（版本过高，不建议使用） |
| `ArcScrollBar` | API 18 | API 18+ | 仅 Wearable 设备 |

### 枚举值

- **ScrollBarDirection**: `Vertical(0)` / `Horizontal(1)`
- **BarState**: `Off` / `Auto` / `On`

## 核心调用方式

### 1. 基本用法 — 与 Scroll 配合

```typescript
private scroller: Scroller = new Scroller()

Stack({ alignContent: Alignment.End }) {
  Scroll(this.scroller) {
    // 内容
  }
  .scrollBar(BarState.Off)  // 关闭内置滚动条

  ScrollBar({
    scroller: this.scroller,
    direction: ScrollBarDirection.Vertical,
    state: BarState.Auto
  }) {
    Text()  // 自定义滑块
      .width(16).height(80)
      .borderRadius(8)
      .backgroundColor('#C0C0C0')
  }
  .width(16)
}
```

关键点：
- ScrollBar 与可滚动组件通过同一 Scroller 实例绑定
- Scroll 需 `.scrollBar(BarState.Off)` 关闭内置滚动条
- ScrollBar 方向必须与可滚动组件方向一致才能联动
- 仅支持一对一绑定

### 2. 无子节点默认样式

从 API 12 开始，ScrollBar 不设子节点时会显示默认样式的滚动条：

```typescript
ScrollBar({
  scroller: this.scroller,
  direction: ScrollBarDirection.Vertical,
  state: BarState.Auto
})
```

### 3. 水平 ScrollBar

```typescript
Scroll(this.hScroller) {
  Row({ space: 8 }) { /* 水平内容 */ }
}
.scrollable(ScrollDirection.Horizontal)

ScrollBar({
  scroller: this.hScroller,
  direction: ScrollBarDirection.Horizontal,
  state: BarState.On
})
.height(8)
.width('90%')
```

关键点：
- 水平方向 ScrollBar 的 width 为主轴（内容方向），height 为交叉轴
- 需要显式设置 ScrollBar 的宽度/高度

### 4. 嵌套滚动 (enableNestedScroll)

```typescript
ScrollBar({
  scroller: this.listScroller,
  direction: ScrollBarDirection.Vertical,
  state: BarState.Auto
})
.enableNestedScroll(true)
```

嵌套滚动时 ScrollBar 偏移传递顺序：ScrollBar → 内层滚动组件 → 外层父滚动组件

注意事项：
- WaterFlow 的 SLIDING_WINDOW 模式不支持嵌套滚动
- PARALLEL 模式需在 `onScrollFrameBegin` 中自行处理父子组件滚动顺序

## 编译问题与解决方案

### 1. struct 命名与框架枚举冲突

**问题**: struct 命名为 `ScrollBarDirection` 与框架枚举 `ScrollBarDirection` 冲突，编译报错 `Property 'Vertical' does not exist on type 'typeof ScrollBarDirection'`。

**解决**: 将 struct 重命名为 `ScrollBarDirectionCtrl`，避免与框架枚举同名。

**教训**: HarmonyOS 框架枚举类型（如 ScrollBarDirection、BarState、Edge 等）不应被自定义 struct 同名覆盖。

### 2. Edge.Right 不存在

**问题**: 水平滚动调用 `scroller.scrollEdge(Edge.Right)` 报错。

**解决**: 使用 `Edge.End` 替代。Edge 枚举值为 `Top` / `Bottom` / `Start` / `End`，没有 `Left` / `Right`。

## 重要注意事项

1. **主轴大小**: ScrollBar 主轴方向不设大小时使用父组件 maxSize，若父组件存在可滚动组件可能导致无穷大，建议始终显式设置。
2. **opacity 不生效**: ScrollBar 内部通过 BarState 自动调整 opacity 控制显隐，手动设置 `.opacity()` 会被覆盖。
3. **scrollBarColor 替代方案**: API 20+ 才支持，当前开发建议通过 ScrollBar 子节点自定义滑块颜色。
4. **ArcScrollBar**: 仅 Wearable 设备可用（系统能力 Circle），PhonePC/Tablet 设备使用标准 ScrollBar。
