# TextArea 组件开发经验

## 组件概述

TextArea 是 ArkUI 多行文本输入组件，通过 `TextArea(value?)` 创建，支持多行文本编辑、自动换行、字数限制等能力。

**创建接口**: `TextArea(value?: {placeholder?: ResourceStr, text?: ResourceStr, controller?: TextAreaController})`

---

## 元服务 API 兼容性清单

### 可用 API（元服务 API 11+）

| API | 版本 | 说明 |
|-----|------|------|
| `placeholder` | 7+ | 提示文本 |
| `text` | 7+ | 输入框文本内容 |
| `controller` | 8+ | TextAreaController 控制器 |
| `.onChange(callback)` | 7+ | 输入内容变化回调 |
| `.onFocus(callback)` | 7+ | 获焦回调 |
| `.onBlur(callback)` | 7+ | 失焦回调 |
| `.onTextSelectionChange(callback)` | 10+ | 选区变化回调 |
| `.style(TextContentStyle)` | 10+ | 多态样式（DEFAULT / INLINE） |
| `.maxLength(number)` | 7+ | 最大输入字符数 |
| `.showCounter(boolean)` | 7+ | 显示字数计数器，需配合 maxLength |
| `.placeholderColor(color)` | 7+ | 提示文本颜色 |
| `.caretColor(color)` | 7+ | 光标颜色 |
| `.fontSize / .fontColor / .fontWeight / .fontFamily` | 7+ | 字体样式 |
| `.textAlign(TextAlign)` | 7+ | 文本对齐 |
| `.copyOption(CopyOptions)` | 7+ | 复制行为设置 |
| `.enableKeyboard(boolean)` | 7+ | 是否弹出软键盘 |
| `.backgroundColor(color)` | 7+ | 背景色 |
| `.editMenuOptions(options)` | 10+ | 自定义编辑菜单 |

### TextAreaController 可用方法（元服务 API 11+）

| 方法 | 版本 | 说明 |
|------|------|------|
| `caretPosition(index)` | 8+ | 设置光标位置 |
| `getTextContentRect()` | 10+ | 获取文本内容区域 |
| `getTextContentLineCount()` | 10+ | 获取文本行数 |
| `getCaretOffset()` | 11+ | 获取光标位置信息 |

### 受限/不可用 API

| API | 版本 | 限制说明 |
|-----|------|----------|
| `.minLines(number)` | 20+ | 高版本 API，元服务尚未支持 |
| `.lineSpacing(LengthMetrics, options?)` | 20+ | 高版本 API，元服务尚未支持 |
| `.strokeWidth / .strokeColor` | 20+ | 文本描边，高版本 API |
| `TextMenuController.disableSystemServiceMenuItems()` | 20+ | 禁用系统服务菜单项 |
| `TextMenuController.disableMenuItems()` | 20+ | 禁用指定菜单项 |
| `.onWillInsert / .onDidInsert` | 12+ | 仅系统输入法场景，第三方输入法不触发 |
| `.onWillDelete / .onDidDelete` | 12+ | 仅系统输入法场景 |
| 组件级拖拽 | - | 元服务不支持 |
| `.contentType(ContentType)` | 12+ | 自动填充需系统服务配合，元服务可能受限 |

---

## 各场景核心调用方式

### 1. 基础多行输入

```typescript
TextArea({ placeholder: '提示文本', text: this.inputText })
  .width('90%')
  .height(120)
  .onChange((value: string) => {
    this.inputText = value
  })
```

### 2. 多态样式

```typescript
// DEFAULT: 编辑态和非编辑态样式无区别
TextArea().style(TextContentStyle.DEFAULT)

// INLINE: 编辑态和非编辑态有明显区分
TextArea().style(TextContentStyle.INLINE)
```

### 3. 事件处理

```typescript
TextArea()
  .onChange((value: string) => { /* 文本变化 */ })
  .onFocus(() => { /* 获焦 */ })
  .onBlur(() => { /* 失焦 */ })
  .onTextSelectionChange((start: number, end: number) => { /* 选区变化 */ })
```

### 4. 控制器操作

```typescript
const controller: TextAreaController = new TextAreaController()

TextArea({ controller: controller })
  .onChange((value: string) => { this.inputText = value })

// 设置光标位置
controller.caretPosition(10)

// 获取行数
const lines = controller.getTextContentLineCount()

// 获取文本区域
const rect = controller.getTextContentRect()
```

### 5. 字数限制与计数

```typescript
TextArea({ placeholder: '最多50字...' })
  .maxLength(50)
  .showCounter(true)
```

---

## 编译问题与解决方案

### 问题 1: `.border()` 参数错误

**现象**: `Expected 1 arguments, but got 2`

**原因**: ArkTS 中 `.border()` 接受 `BorderOptions` 对象，而非位置参数

```typescript
// 错误写法
.border(3, '#2196F3')

// 正确写法
.border({ width: 3, color: '#2196F3' })
```

### 问题 2: 通用注意事项

- TextArea 文本超出一行时自动折行，无需额外配置
- `showCounter` 必须配合 `maxLength` 使用，否则不生效
- `onChange` 在改变 `text` 属性值时不会触发（从 API 5 开始）
- `TextAreaController` 需在组件创建时绑定，之后才能调用方法

---

## 降级处理策略

### minLines 替代方案

`minLines` (API 20+) 在元服务中不可用时，使用 `height("auto")` + `constraintSize` 计算：

```typescript
TextArea({ text: this.inputText })
  .height('auto')
  .constraintSize({
    minHeight: padding * 2 + minLines * lineHeight
  })
```

### 高版本文本拦截事件替代

`onWillInsert`/`onDidInsert` 等 API 12+ 事件在第三方输入法不触发，可在 `onChange` 中进行文本校验和拦截处理。

### editMenuOptions 注意

系统服务菜单项（翻译、搜索、AI 帮写）在元服务中可能受限，自定义菜单项不受影响。
