# Dialogs 对话框开发经验

## 可用 API 清单（元服务兼容性）

### 完全可用

| API | 元服务起始版本 | 说明 |
|-----|--------------|------|
| `AlertDialog.show()` | API 8+ | 警告对话框，支持单按钮/双按钮 |
| `ActionSheet.show()` | API 8+ | 操作列表，支持多选项 + 取消按钮 |
| `CustomDialogController` | API 8+ | 自定义对话框，通过 `@CustomDialog` 装饰器定义内容 |
| `promptAction.showToast()` | API 11+ | 即时反馈 Toast |
| `promptAction.showDialog()` | API 11+ | 按钮式对话框（已 deprecated，建议用 AlertDialog） |
| `promptAction.showActionMenu()` | API 11+ | 操作菜单，1-6 个按钮 |
| `promptAction.openCustomDialog()` | API 12+ | 通过 builder 创建自定义弹窗 |
| `promptAction.closeCustomDialog()` | API 12+ | 通过 dialogId 关闭自定义弹窗 |
| `ShowToastOptions.backgroundColor` | API 12+ | Toast 背板颜色 |
| `ShowToastOptions.textColor` | API 12+ | Toast 文本颜色 |
| `ShowToastOptions.backgroundBlurStyle` | API 12+ | Toast 背板模糊材质 |
| `ShowToastOptions.shadow` | API 12+ | Toast 背板阴影 |
| `ShowToastOptions.alignment` | API 12+ | Toast 对齐方式 |
| `ShowToastOptions.offset` | API 12+ | Toast 偏移量 |
| `ShowToastOptions.showMode` | API 12+ | Toast 层级（DEFAULT / TOP_MOST） |
| `ShowDialogOptions.alignment` | API 11+ | 对话框竖直对齐 |
| `ShowDialogOptions.isModal` | API 12+ | 是否模态窗口 |
| `ShowDialogOptions.showInSubWindow` | API 12+ | 是否在子窗口显示 |
| `ShowDialogOptions.backgroundColor` | API 12+ | 对话框背板颜色 |
| `ShowDialogOptions.backgroundBlurStyle` | API 12+ | 对话框背板模糊材质 |

### 不可用

| API | 所需版本 | 说明 | 替代方案 |
|-----|---------|------|---------|
| `promptAction.openToast()` | API 18+ | Promise 方式 Toast，返回 id | 使用 `showToast()` |
| `promptAction.closeToast()` | API 18+ | 通过 id 关闭 Toast | 无法手动关闭，等 duration 自动结束 |
| `DialogController` | API 18+ | 弹窗控制器 | 使用 `CustomDialogController` |
| `openCustomDialogWithController()` | API 18+ | 控制器式自定义弹窗 | 使用 `openCustomDialog()` |
| `presentCustomDialog()` | API 18+ | 模态自定义弹窗 | 使用 `CustomDialogController` |
| `LevelMode.EMBEDDED` | API 15+ | 页面级弹出框 | 使用全局级别弹窗（默认行为） |
| `ImmersiveMode.EXTEND` | API 15+ | 蒙层覆盖状态栏 | 无直接替代 |
| `LevelOrder.clamp()` | API 18+ | 弹窗显示顺序控制 | 按调用顺序管理 |
| `onWillAppear/onDidAppear` | API 19+ | ShowDialogOptions 生命周期回调 | 在 then/catch 中处理 |
| `onWillDisappear/onDidDisappear` | API 19+ | ShowDialogOptions 生命周期回调 | 无直接替代 |
| `CommonController.getState()` | API 20+ | 弹窗状态查询 | 使用布尔变量追踪 |
| `ActionMenuOptions.onWillAppear` | API 20+ | ActionMenu 生命周期回调 | 无直接替代 |

## 各场景核心调用方式

### 1. Toast 即时反馈

```typescript
import { promptAction } from '@kit.ArkUI'

// 基础用法
promptAction.showToast({
  message: '操作成功',
  duration: 2000,
  bottom: 100
})

// 自定义位置
promptAction.showToast({
  message: '顶部提示',
  duration: 2000,
  alignment: Alignment.Top,
  offset: { dx: 0, dy: 50 }
})
```

**注意**：`duration` 取值范围 [1500, 10000]，小于 1500 取默认值 1500ms。

### 2. AlertDialog 警告对话框

```typescript
AlertDialog.show({
  title: '提示',
  message: '确认操作？',
  primaryButton: {
    value: '取消',
    action: () => { /* 取消逻辑 */ }
  },
  secondaryButton: {
    value: '确认',
    action: () => { /* 确认逻辑 */ }
  },
  autoCancel: true
})
```

**注意**：`cancel` 回调在点击蒙层时触发。单按钮用 `confirm` 参数，双按钮用 `primaryButton` + `secondaryButton`。

### 3. ActionSheet 操作列表

```typescript
ActionSheet.show({
  title: '选择操作',
  message: '请选择',
  confirm: {
    value: '取消',
    action: () => { /* 取消 */ }
  },
  sheets: [
    { title: '选项一', action: () => {} },
    { title: '选项二', action: () => {} }
  ]
})
```

### 4. promptAction.showDialog

```typescript
promptAction.showDialog({
  title: '提示',
  message: '内容',
  buttons: [
    { text: '取消', color: '#999999' },
    { text: '确定', color: '#007DFF' }
  ]
}).then((result) => {
  // result.index 为选中按钮索引
})
```

**注意**：此 API 已被标记为 deprecated，建议使用 `AlertDialog.show()` 替代。

### 5. promptAction.showActionMenu

```typescript
promptAction.showActionMenu({
  title: '操作菜单',
  buttons: [
    { text: '选项一', color: '#333333' },
    { text: '选项二', color: '#333333' },
    { text: '取消', color: '#999999' }
  ]
}).then((result) => {
  // result.index 为选中按钮索引 (0-based)
})
```

**注意**：`buttons` 支持 1-6 个，超过 6 个只显示前 6 个。

### 6. CustomDialogController 自定义对话框

```typescript
@CustomDialog
struct MyDialog {
  controller: CustomDialogController
  build() {
    Column() {
      Text('自定义内容')
      Button('关闭').onClick(() => { this.controller.close() })
    }
  }
}

// 在组件中使用
@Local dialogController: CustomDialogController = new CustomDialogController({
  builder: MyDialog(),
  alignment: DialogAlignment.Center,
  autoCancel: true
})

// 打开
this.dialogController.open()
```

### 7. openCustomDialog (promptAction 方式)

```typescript
this.getUIContext().getPromptAction().openCustomDialog({
  builder: (): void => {
    // 自定义 Builder
  },
  autoCancel: true,
  alignment: DialogAlignment.Bottom
}).then((dialogId: number) => {
  // 保存 dialogId 用于后续关闭
})
```

## 编译过程中遇到的问题和解决方案

### 问题 1：BusinessError 导入路径错误

**现象**：`Module '"@kit.ArkUI"' has no exported member 'BusinessError'`

**解决**：`BusinessError` 应从 `@kit.BasicServicesKit` 导入，而非 `@kit.ArkUI`：

```typescript
// 错误
import { promptAction, BusinessError } from '@kit.ArkUI'

// 正确
import { promptAction } from '@kit.ArkUI'
import { BusinessError } from '@kit.BasicServicesKit'
```

### 问题 2：showDialog 已被标记为 deprecated

**现象**：编译时出现 WARN `'showDialog' has been deprecated`

**说明**：`promptAction.showDialog()` 在较新版本中已弃用，推荐使用 `AlertDialog.show()` 替代。保留在 demo 中是为了展示兼容用法。

## 降级处理策略

| 不可用 API | 降级方案 |
|-----------|---------|
| `openToast`/`closeToast` | 使用 `showToast()`，无法手动关闭 |
| `DialogController` | 使用 `CustomDialogController` |
| `openCustomDialogWithController` | 使用 `openCustomDialog()` |
| `LevelMode.EMBEDDED` | 使用全局弹窗，路由切换时手动关闭 |
| `ImmersiveMode.EXTEND` | 接受默认蒙层不覆盖状态栏 |
| `LevelOrder` | 按需顺序调用，手动管理弹窗层级 |
| 生命周期回调 | 在 `then`/`catch` 和按钮 `action` 中处理 |
| `CommonState.getState()` | 使用 `@Local` 布尔变量追踪弹窗状态 |
