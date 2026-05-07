# experience_rich_editor — RichEditor 开发经验

## 可用/不可用 API 清单（元服务兼容性）

| API | 元服务可用 | 备注 |
|-----|-----------|------|
| `RichEditor(controller)` | ✅ API 11+ | 基础构造函数 |
| `controller.addTextSpan()` | ✅ API 11+ | 添加文本段 |
| `controller.setSelection()` | ✅ API 11+ | 设置选区 |
| `controller.getSelection()` | ✅ API 11+ | 返回 RichEditorSelection |
| `.onReady()` | ✅ API 11+ | 就绪回调 |
| `.onFocus()` / `.onBlur()` | ✅ API 11+ | 焦点事件 |
| `controller.getHtml()` | ❌ 不存在 | SDK 中未定义 |
| `controller.setHtml()` | ❌ 不存在 | SDK 中未定义 |
| `controller.deleteContent()` | ❌ 不存在 | 需重建 controller 替代 |
| `controller.insertText()` | ❌ 不存在 | 用 addTextSpan 替代 |
| `controller.undo()` / `redo()` | ❌ 不存在 | SDK 中未定义 |
| `.bias()` | ❌ 编译报错 | 类型定义缺失 |

## 编译问题与解决方案

### 问题 1: getHtml/setHtml/deleteContent 不存在
- **错误**: `Property 'xxx' does not exist on type 'RichEditorController'`
- **原因**: 当前 SDK 版本的 RichEditorController 类型定义中缺少这些方法
- **解决**: 清空内容需重建 controller；不支持 HTML 操作

### 问题 2: onSelectionChange 回调签名错误
- **错误**: `Argument of type '(start: number, end: number) => void' is not assignable`
- **原因**: 回调参数类型为 `RichEditorRange` 而非 `(start, end)`
- **解决**: 使用正确类型 `Callback<RichEditorRange, void>` 或避免使用

### 问题 3: RichEditorSelection 属性
- `selection.start` / `selection.end` 不存在
- 可用属性: `selection.spans` (span 数组)

## 各场景核心调用方式

### 1. 基础编辑
```typescript
controller: RichEditorController = new RichEditorController()
RichEditor({ controller: this.controller })
controller.addTextSpan('文本')
```

### 2. 带样式添加文本
```typescript
controller.addTextSpan('文本', {
  style: {
    fontColor: '#FF0000',
    fontSize: 24,
    fontWeight: FontWeight.Bold,
    fontStyle: FontStyle.Italic,
    decoration: { type: TextDecorationType.Underline, color: '#FF0000' }
  }
})
```

### 3. 清空内容
- 无法用 deleteContent，需重新赋值 controller
```typescript
this.controller = new RichEditorController()
```
