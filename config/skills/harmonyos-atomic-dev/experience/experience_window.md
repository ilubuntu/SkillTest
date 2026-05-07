# Window Kit 开发经验

## 一、元服务 API 兼容性清单

### 可用 API

| API | 模块 | 说明 | 备注 |
|-----|------|------|------|
| `window.getLastWindow()` | `@ohos.window` | 获取当前子窗口 | 元服务运行在子窗口中 |
| `win.getWindowProperties()` | `@ohos.window` | 查询窗口属性 | 尺寸、类型、密度等 |
| `win.setWindowLayoutFullScreen()` | `@ohos.window` | 切换全屏/非全屏布局 | 可用 |
| `win.setWindowBrightness()` | `@ohos.window` | 设置窗口亮度 (0~1) | 可用 |
| `win.getAvoidArea()` | `@ohos.window` | 获取系统栏避让区域 | 部分受限 |
| `win.setSpecificSystemBarEnabled()` | `@ohos.window` | 控制特定系统栏显隐 | 部分可用 |

### 不可用/受限 API

| API | 模块 | 说明 | 原因 |
|-----|------|------|------|
| `window.createWindow()` | `@ohos.window` | 创建新窗口 | 元服务不允许创建独立窗口 |
| `win.showWindow()` / `hideWindow()` | `@ohos.window` | 显示/隐藏窗口 | 窗口生命周期由宿主管理 |
| `win.minimize()` / `maximize()` | `@ohos.window` | 最小化/最大化 | 元服务无法控制 |
| `win.moveWindowTo()` | `@ohos.window` | 移动窗口位置 | 元服务不允许移动窗口 |
| `win.resize()` | `@ohos.window` | 调整窗口大小 | 元服务不允许调整尺寸 |
| `setWindowSystemBarProperties()` | `@ohos.window` | 修改系统栏颜色/内容 | 由宿主统一管理 |
| `setWindowMode()` / `setWindowFlags()` | `@ohos.window` | 修改窗口模式/标志位 | 元服务无法修改 |
| 多窗口管理 | `@ohos.window` | 创建/管理多个窗口 | 不支持悬浮窗/画中画/分屏 |

## 二、核心调用方式

### 获取窗口信息

```typescript
import window from '@ohos.window'

// 获取当前子窗口
let win = await window.getLastWindow(getContext(this))

// 获取窗口属性
let props = win.getWindowProperties()
let rect = props.windowRect        // { left, top, width, height }
let type = props.type              // 窗口类型
let isFullScreen = props.isFullScreen
let isTransparent = props.isTransparent
let touchable = props.touchable
```

### 全屏切换

```typescript
let win = await window.getLastWindow(getContext(this))
let props = win.getWindowProperties()

// 切换全屏
await win.setWindowLayoutFullScreen(!props.isFullScreen)
```

### 设置亮度

```typescript
let win = await window.getLastWindow(getContext(this))
await win.setWindowBrightness(0.8)  // 0~1 范围
```

### 系统栏避让区域（受限）

```typescript
// getAvoidArea 在原子化服务中不支持
// win.getAvoidArea(window.AvoidAreaType.TYPE_SYSTEM)
// 返回: "原子化服务不支持 getAvoidArea"
```

## 三、编译问题与解决方案

1. **元服务运行在子窗口**: 元服务运行在宿主提供的子窗口中，使用 `getLastWindow()` 获取当前窗口实例，而非 `createWindow()`。
2. **getAvoidArea 受限**: `getAvoidArea()` 在原子化服务中不支持，无法获取系统栏避让区域的具体尺寸。
3. **系统栏样式不可修改**: `setWindowSystemBarProperties()` 由宿主统一管理，元服务无法直接修改状态栏/导航栏的颜色和内容。
4. **窗口尺寸只读**: `getWindowProperties()` 可获取窗口尺寸，但 `moveWindowTo()` / `resize()` 不可用。

## 四、降级处理策略

1. **全屏布局** -- 使用 `setWindowLayoutFullScreen(true)` 配合自定义顶部/底部组件处理系统栏区域，替代直接修改系统栏样式。
2. **多窗口** -- 使用 Navigation 组件管理多个页面，用 `bindSheet` / `bindContentCover` 模拟多窗口效果。
3. **弹窗** -- 使用 `CustomDialog` 或 `bindSheet` 替代创建新窗口。
4. **系统栏避让** -- 虽然无法获取精确的避让区域尺寸，可通过固定 padding 或使用安全区域相关的 ArkUI 属性处理。
5. **窗口亮度** -- `setWindowBrightness()` 可用，在阅读等场景中可正常使用。
