# Panel 可滑动面板 — 开发经验

## 一、元服务 API 兼容性

### 可用 API (API 7+)

| API | 说明 | 元服务支持 |
|-----|------|-----------|
| `Panel()` | 创建可滑动面板 | API 7+ |
| `.type(PanelType)` | 面板类型 | API 7+ |
| `.mode(PanelMode)` | 初始状态 | API 7+ |
| `.dragBar(boolean)` | 拖拽条可见性 | API 7+ |
| `.fullHeight(Length)` | Full 模式高度 | API 7+ |
| `.halfHeight(Length)` | Half 模式高度 | API 7+ |
| `.miniHeight(Length)` | Mini 模式高度 | API 7+ |
| `.onChange(callback)` | 尺寸变化回调 | API 7+ |

**PanelType 枚举：**
- `PanelType.Foldable` — 三段式面板，支持 Mini/Half/Full 三种尺寸，内容永久展示
- `PanelType.Minibar` — 提供 minibar 和全屏两种状态切换
- `PanelType.Temporary` — 临时展示区，仅支持 Half/Full 两种尺寸

**PanelMode 枚举：**
- `PanelMode.Mini` — 最小状态（仅 Foldable 和 Minibar 生效）
- `PanelMode.Half` — 类半屏状态（仅 Foldable 和 Temporary 生效）
- `PanelMode.Full` — 类全屏状态（所有 type 均支持）

### 不可用 / 受限能力

| 项目 | 说明 |
|------|------|
| JS 框架 API | `this.$element("panel").show()/close()` 为 JS 框架 API，ArkTS 中不可用 |
| `type` 动态变更 | Panel 的 type 属性创建后不可动态修改 |
| 通用渲染属性 | `for`/`if`/`show` 等渲染属性不支持 |
| `focusable`/`disabled` | 不支持 |

### 废弃警告（编译期 WARN）

编译时会收到以下废弃警告，但不影响功能：
- `halfHeight` — 已废弃
- `fullHeight` — 已废弃
- `onChange` — 已废弃
- `PanelMode` — 已废弃（建议使用新 API）

这些是 API 版本迭代中的废弃提示，Panel 组件在新版本中有替代 API，但当前版本仍可正常使用。

## 二、type 与 mode 匹配规则

Panel 组件的 `type` 和 `mode` 存在匹配限制，设置不匹配的 mode 会静默不生效：

| type \ mode | Mini | Half | Full |
|-------------|------|------|------|
| Foldable | 生效 | 生效 | 生效 |
| Minibar | 生效 | **不生效** | 生效 |
| Temporary | **不生效** | 生效 | 生效 |

开发时需注意此匹配规则，避免误以为 mode 设置失败。

## 三、核心调用方式

### 基本用法

```typescript
Panel(undefined) {
  Column({ space: 12 }) {
    Text('面板内容')
      .fontSize(18)
  }
  .width('100%')
  .padding(16)
}
.type(PanelType.Foldable)    // 面板类型
.mode(PanelMode.Half)         // 初始状态
.dragBar(true)                // 显示拖拽条
.halfHeight(300)              // Half 模式高度
.fullHeight(500)              // Full 模式高度
.miniHeight(48)               // Mini 模式高度
.onChange((width: number, height: number, mode: PanelMode) => {
  // 处理尺寸变化
})
```

### onChange 回调参数

- `width`: 当前宽度
- `height`: 内容区高度（注意：当 dragBar 为 true 时，面板实际高度 = dragBar 高度 + 内容区高度）
- `mode`: 当前模式（PanelMode.Mini/Half/Full）

## 四、编译问题与解决

### 1. Panel 废弃警告

**问题：** 编译时大量 `xxx has been deprecated` 警告
**解决：** 这些是 API 版本迭代警告，不影响编译和功能。如需消除，可关注新版本 Panel API 替代方案。

### 2. 修复其他组件编译错误（编译阻塞项）

编译过程中发现以下非 Panel 组件的编译错误，需一并修复才能通过编译：

- **@Local 在 @CustomDialog 中不可用**：`@Local` 装饰器仅适用于 `@ComponentV2` 结构体。`@CustomDialog` 中应使用 `@State`。
- **Menu 子组件限制**：`Menu()` 组件只能包含 `Option`、`MenuItem`、`MenuItemGroup`，不能包含 `Divider()` 等其他组件。如需分割线效果，可使用 `MenuItemGroup` 或在 `MenuItem` 上设置样式。

## 五、降级处理策略

Panel 组件本身在元服务中完全可用，无需降级。但如需更复杂的弹出面板效果，可考虑替代方案：

| 替代方案 | 适用场景 |
|---------|---------|
| `BindSheet` | 半模态转场，更灵活的弹出面板控制 |
| `CustomDialog` | 自定义弹窗，支持复杂交互 |
| `Stack` + 动画 | 完全自定义的面板效果和过渡动画 |

## 六、注意事项

1. Panel 的 `type` 属性在创建后不可动态变更，需在初始化时确定
2. `onChange` 返回的 height 为内容区高度值，当 `dragBar` 为 true 时面板实际高度更大
3. Temporary 类型不支持 Mini 模式，设置 PanelMode.Mini 不会生效
4. Minibar 类型不支持 Half 模式，设置 PanelMode.Half 不会生效
5. Panel 属于弹出式组件，不建议嵌套使用 Panel
