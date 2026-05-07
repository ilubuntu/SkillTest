# RichText 组件开发经验（元服务）

## 组件概述

RichText 是 HarmonyOS **JS UI 框架**中的富文本展示组件（非 ArkUI 声明式组件），通过 `<richtext>` 标签在 `.hml` 文件中使用，API version 6+ 引入。

**关键结论：RichText 不支持元服务 (atomicService)。**

---

## API 兼容性清单

### 元服务不可用

| API | 类型 | 说明 |
|-----|------|------|
| `<richtext>` 标签 | 组件 | JS UI 框架专用，`.hml` 文件中使用 |
| `{{content}}` 数据绑定 | 属性 | JS 框架模板语法 |
| `@start` 事件 | 事件 | 加载开始时触发 |
| `@complete` 事件 | 事件 | 加载完成时触发 |
| 通用属性 id/style/class | 属性 | 仅限 JS 框架 |
| 通用样式 display/visibility | 样式 | 仅限 JS 框架 |

### JS 框架中也不支持的能力

- `focus` / `blur` / `key` 事件
- 无障碍事件
- 页面转场动效（richtext 区域不跟随）
- 超过一屏高度的内容（超出不显示）
- 自定义宽度（默认撑开全屏）
- 组件方法调用（不支持任何方法）

---

## 替代方案

### 1. Text + Span 组合（推荐用于纯展示）

**适用场景：** 显示带样式的富文本内容，无需编辑

**核心 API：**

```typescript
Text() {
  Span('文本')
    .fontColor('#FF0000')
    .fontSize(16)
    .fontWeight(FontWeight.Bold)
    .fontStyle(FontStyle.Italic)
    .decoration({ type: TextDecorationType.Underline, color: '#000000' })
}
.lineHeight(24)
```

**支持的 Span 属性：**
- `fontColor(string)` — 字体颜色
- `fontSize(number)` — 字体大小
- `fontWeight(FontWeight)` — 字重（Lighter/Normal/Regular/Bold 等）
- `fontStyle(FontStyle)` — 斜体（Normal/Italic）
- `decoration({type, color})` — 装饰线（Underline/LineThrough/Overline）

**元服务兼容性：API 11+ 完全可用**

### 2. RichEditor（可用于编辑+展示）

**适用场景：** 需要编辑富文本内容

**核心 API：**
- `RichEditor({ controller })` — 创建编辑器
- `controller.addTextSpan(text, options?)` — 添加文本段
- `controller.addImageSpan(url, options?)` — 添加图片
- `.onReady()` — 编辑器就绪回调
- `.aboutToDelete()` — 删除前回调

**元服务兼容性：API 11+ 可用**

### 3. ImageSpan（行内图片）

**适用场景：** Text 组件中插入行内图片，实现图文混排

---

## Demo 场景说明

### rich_text-basic — 基础富文本显示

展示 RichText 不可用的限制，使用 Text+Span 替代实现：
- 标题样式（H1-H3 通过 fontSize + fontWeight 模拟）
- 段落样式（粗体/斜体/下划线混合）
- 列表样式（通过文本前缀 `•` 模拟）

### rich_text-style — 富文本样式展示

通过 Text+Span 组合展示 5 种样式效果：
- 字体颜色（fontColor）
- 字体大小（fontSize）
- 字重（fontWeight）
- 装饰线（decoration — 下划线/删除线/上划线）
- 混合排版（多种样式组合）

### rich_text-unsupported — 不支持 API 说明

完整列出：
- RichText JS 框架 API 清单（元服务全部不可用）
- JS 框架中也不支持的能力
- 元服务推荐替代方案及 API 说明

---

## 编译过程问题与解决

### 问题：大量模块文件缺失

Index.ets 中引用了 search、badge、blank、calendar_picker、checkbox 等 30+ 个组件模块，但对应目录和文件尚未创建，导致编译失败。

**解决方案：** 为每个缺失模块创建最小化的 stub 文件：

```typescript
@ComponentV2
export struct ComponentName {
  build() {
    Column() {
      Text('Component Stub')
    }
  }
}
```

创建 stub 时需注意：
- struct 名称必须与 Index.ets 中的 import 名称完全一致
- 目录命名需与 import 路径一致（如 `from '../text_timer/...'` 对应 `text_timer/` 目录）
- `@ComponentV2` 装饰器必须添加，否则会出现 "does not meet UI component syntax" 错误

---

## 降级处理策略

由于 RichText 在元服务中完全不可用，降级策略如下：

| RichText 功能 | 降级替代方案 | 效果差异 |
|--------------|-------------|---------|
| HTML 内容解析渲染 | Text + Span 手动构建 | 无法自动解析 HTML，需逐段设置样式 |
| HTML 表格 | Column + Row 布局模拟 | 需手动构建表格结构 |
| HTML 列表 (ul/ol) | Text 前缀符号 `•` / 数字 | 可实现视觉等效 |
| HTML 链接 (a) | Text + onClick + 链接颜色 | 需手动处理跳转逻辑 |
| HTML 图片 (img) | ImageSpan 或 Image 组件 | 可实现图文混排 |
| HTML 标题 (h1-h6) | Span.fontSize + fontWeight | 视觉等效 |
| HTML 粗体/斜体 | Span.fontWeight / fontStyle | 完全等效 |
