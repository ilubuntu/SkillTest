# Menu 组件开发经验 — 元服务兼容性

## API 兼容性总览

### 元服务可用 API（API 11+）

| API / 属性 | 说明 | 元服务起始版本 |
|-----------|------|--------------|
| `bindMenu(MenuElement[])` | 绑定默认样式点击菜单 | API 11 |
| `bindMenu(CustomBuilder)` | 绑定自定义 Builder 菜单 | API 11 |
| `bindContextMenu(CustomBuilder, ResponseType)` | 绑定右键/长按上下文菜单 | API 11 |
| `Menu` 组件 | 自定义菜单容器 | API 9（元服务 11） |
| `MenuItem` 组件 | 菜单项 | API 9（元服务 11） |
| `MenuItemGroup` 组件 | 菜单项分组 | API 9（元服务 11） |
| `MenuItemOptions.startIcon` | 菜单项起始图标 | API 11 |
| `MenuItemOptions.content` | 菜单项文本内容 | API 11 |
| `MenuItemOptions.endIcon` | 菜单项末尾图标 | API 11 |
| `MenuItemOptions.labelInfo` | 菜单项标签信息（如快捷键） | API 11 |
| `MenuItemOptions.builder` | 绑定二级子菜单 | API 11 |
| `MenuItem.selected` | 选中状态（支持双向绑定） | API 11 |
| `MenuItem.selectIcon` | 显示选中图标 | API 11 |
| `MenuItem.contentFont` | 内容字体样式 | API 11 |
| `MenuItem.contentFontColor` | 内容字体颜色 | API 11 |
| `MenuItem.labelFont` | 标签字体样式 | API 11 |
| `MenuItem.labelFontColor` | 标签字体颜色 | API 11 |
| `MenuItem.onChange` | 选中状态变化回调 | API 11 |
| `MenuItemGroupOptions.header` | 分组标题 | API 11 |
| `MenuItemGroupOptions.footer` | 分组尾部信息 | API 11 |
| `ContextMenu.close()` | 关闭上下文菜单（已废弃） | API 11 |

### 元服务不可用 API

| API | 说明 | 要求版本 | 不可用原因 |
|-----|------|---------|-----------|
| `openMenu` | 全局菜单弹出（不依赖UI组件） | API 18 | API 版本过高 |
| `updateMenu` | 全局菜单样式更新 | API 18 | API 版本过高 |
| `closeMenu` | 全局菜单关闭 | API 18 | API 版本过高 |
| `hapticFeedbackMode` | 菜单弹出振动效果 | API 18 | API 版本过高 |
| `enableHoverMode` | 折叠屏中轴避让 | API 18 | API 版本过高 |
| `modalMode` | 子窗模态事件透传控制 | API 20 | API 版本过高 |
| `anchorPosition` | 基于绑定组件指定位置弹出 | API 20 | API 版本过高 |
| `symbolStartIcon` | Symbol 起始图标 | API 12 | 需验证元服务支持 |
| `symbolEndIcon` | Symbol 末尾图标 | API 12 | 需验证元服务支持 |

## 核心调用方式

### 1. bindMenu 默认样式菜单

最简用法，传入 `MenuElement[]` 数组：

```typescript
Button('点击弹出菜单')
  .bindMenu([
    { value: '菜单项1', action: () => { /* 处理点击 */ } },
    { value: '菜单项2', action: () => { /* 处理点击 */ } }
  ])
```

**要点**：
- `value` 为菜单项文本
- `action` 为点击回调
- 默认样式无法自定义图标、字体等

### 2. bindMenu + CustomBuilder 自定义菜单

使用 `@Builder` 定义 `Menu` + `MenuItem` / `MenuItemGroup` 结构：

```typescript
@Builder
MyMenu() {
  Menu() {
    MenuItem({ content: '复制', labelInfo: 'Ctrl+C' })
    MenuItemGroup({ header: '编辑操作' }) {
      MenuItem({ content: '全选' })
        .selectIcon(true)
        .selected(this.isSelected)
        .onChange((selected: boolean) => { /* 状态变更 */ })
    }
  }
}

Button('自定义菜单')
  .bindMenu(this.MyMenu)
```

**要点**：
- `MenuItem` 的 `onClick` 在点击时触发（非 `action` 参数）
- `MenuItemGroup` 的 `header` / `footer` 为 `ResourceStr` 类型
- `selectIcon(true)` + `selected()` + `onChange()` 实现可选菜单项

### 3. bindContextMenu 右键/长按菜单

```typescript
Column() { Text('右键/长按此区域') }
  .bindContextMenu(this.MyMenu, ResponseType.RightClick)  // 右键
  .bindContextMenu(this.MyMenu, ResponseType.LongPress)    // 长按
```

**要点**：
- `bindContextMenu` 菜单在独立子窗口弹出，可超出应用窗口
- `ResponseType.RightClick` — 右键触发（PC/2in1）
- `ResponseType.LongPress` — 长按触发（手机/平板）
- 设置 preview 图时变为模态菜单（有蒙层），否则为非模态

### 4. 子菜单

通过 `MenuItemOptions.builder` 绑定二级菜单：

```typescript
@Builder
SubMenu() {
  Menu() {
    MenuItem({ content: '子菜单项1' })
    MenuItem({ content: '子菜单项2' })
  }
}

MenuItem({
  content: '编辑',
  labelInfo: '▶',
  builder: this.SubMenu
})
```

**要点**：
- 鼠标 hover 时自动展开子菜单
- 子菜单同样使用 `Menu` + `MenuItem` 结构
- 理论上支持多级嵌套，但元服务建议不超过二级

## 编译问题与解决方案

### 问题：编译无 menu 相关错误

本次 menu demo 编译通过，无新增编译错误。已有的编译错误均为其他缺失模块（search、panel、particle、repeat、save_button、scroll_bar、with_theme、xcomponent 等）。

### 注意事项

1. **`@Builder` 中使用 `this`**：在 `@ComponentV2` 中，`@Builder` 方法可以正常通过 `this` 访问 `@Local` 状态变量
2. **`MenuItem.onClick` vs `action`**：默认样式菜单用 `action` 回调，自定义 MenuItem 用 `.onClick()` 链式调用
3. **`Divider` 在 Menu 中使用**：可以在 `Menu` 内使用 `Divider` 作为分割线，需要设置 `strokeWidth` 和 `color`
4. **`enabled(false)` 禁用菜单项**：使用 `.enabled(false)` 可禁用单个菜单项

## 降级策略

对于元服务不可用的 API：

| 不可用 API | 降级方案 |
|-----------|---------|
| `openMenu` (全局菜单) | 使用 `bindMenu` / `bindContextMenu` 绑定到隐形占位组件上 |
| `hapticFeedbackMode` (振动) | 纯视觉菜单，无振动反馈 |
| `enableHoverMode` (中轴避让) | 不做特殊处理，使用默认定位 |
| `modalMode` (模态控制) | 使用 `bindContextMenu` 默认行为 |
| `anchorPosition` (指定位置) | 使用 `bindMenu` 的默认定位 + `offset` 微调 |