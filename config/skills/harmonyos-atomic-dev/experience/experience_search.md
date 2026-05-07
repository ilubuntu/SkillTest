# Search 组件开发经验

## 组件概述

HarmonyOS 元服务中的搜索框组件有两个版本：
- **标准 Search** (`ts-basic-components-search`)：使用链式方法 API，API 7+，适用于普通应用
- **AtomicServiceSearch** (`@kit.ArkUI`)：使用参数式 API，API 18+，专为元服务设计

元服务开发中应优先使用 **AtomicServiceSearch**。

导入方式：
```typescript
import { AtomicServiceSearch } from '@kit.ArkUI';
```

---

## API 可用性清单（元服务兼容性）

### AtomicServiceSearch 构造参数

| 参数 | 类型 | 元服务可用 | 说明 |
|------|------|-----------|------|
| value | ResourceStr | API 18+ | 当前搜索文本 |
| placeholder | ResourceStr | API 18+ | 占位提示文本 |
| controller | SearchController | API 18+ | 控制器（光标/选区/编辑态） |
| select | SelectParams | API 18+ | 左侧下拉选择区 |
| search | SearchParams | API 18+ | 搜索区事件和样式 |
| operation | OperationParams | API 18+ | 右侧功能区 |

### SearchParams 样式属性

| 属性 | 元服务可用 | 说明 |
|------|-----------|------|
| searchButton | API 18+ | 搜索按钮（文本+样式） |
| componentBackgroundColor | API 18+ | 搜索框背景色 |
| pressedBackgroundColor | API 18+ | 按压态背景色 |
| placeholderColor | API 18+ | 占位文本颜色 |
| placeholderFont | API 18+ | 占位文本字体 |
| textFont | API 18+ | 输入文本字体 |
| fontColor | API 18+ | 输入文本颜色 |
| textAlign | API 18+ | 文本对齐（Start/Center/End） |
| caretStyle | API 18+ | 光标样式 { width, color } |
| selectedBackgroundColor | API 18+ | 选中背景色 |
| copyOptions | API 18+ | 复制选项 |
| searchIcon | API 18+ | 左侧搜索图标 |
| cancelIcon | API 18+ | 右侧清除按钮 |
| type | API 18+ | 输入框类型 (SearchType) |
| maxLength | API 18+ | 最大输入字符数 |
| enterKeyType | API 18+ | 回车键类型 |
| decoration | API 18+ | 文本装饰线 |
| letterSpacing | API 18+ | 字符间距 |
| fontFeature | API 18+ | 文字特性（如 "ss01" on 等宽数字） |
| inputFilter | API 18+ | 正则输入过滤 |
| textIndent | API 18+ | 首行缩进 |
| minFontSize / maxFontSize | API 18+ | 自适应字号范围 |
| editMenuOptions | API 18+ | 自定义菜单扩展项 |
| enableKeyboardOnFocus | API 18+ | 获焦拉起键盘 |
| hideSelectionMenu | API 18+ | 隐藏文本选择菜单 |
| enablePreviewText | API 18+ | 输入预上屏 |
| enableHapticFeedback | API 18+ | 触控反馈 |

### SearchParams 事件

| 事件 | 元服务可用 | 说明 |
|------|-----------|------|
| onSubmit | API 18+ | 提交搜索 |
| onChange | API 18+ | 内容变化 |
| onEditChange | API 18+ | 编辑状态变化 |
| onCopy | API 18+ | 复制操作 |
| onCut | API 18+ | 剪切操作 |
| onPaste | API 18+ | 粘贴操作 |
| onTextSelectionChange | API 18+ | 选区/光标变化 |
| onContentScroll | API 18+ | 文本内容滚动 |
| onWillInsert | API 18+ | 将要输入（可拦截） |
| onDidInsert | API 18+ | 输入完成 |
| onWillDelete | API 18+ | 将要删除（可拦截） |
| onDidDelete | API 18+ | 删除完成 |

### SearchController 方法

| 方法 | 元服务可用 | 说明 |
|------|-----------|------|
| caretPosition(n) | API 18+ | 设置光标位置 |
| stopEditing() | API 18+ | 退出编辑态 |
| setTextSelection(start, end) | API 18+ | 选中指定区域 |

---

## 不可用 API

| API | 说明 |
|-----|------|
| 标准 Search 链式方法 | `.searchButton()`, `.placeholderColor()`, `.textFont()` 等，需用 AtomicServiceSearch 参数式替代 |
| 子组件嵌套 | AtomicServiceSearch 不支持通过子组件自定义内部布局 |
| .contentModifier() | 标准 Search 的自定义内容修改器，AtomicServiceSearch 不支持 |

---

## 核心调用方式

### 基础搜索 + 事件

```typescript
AtomicServiceSearch({
  value: this.searchValue,
  placeholder: '请输入搜索内容...',
  controller: this.controller,
  search: {
    searchButton: {
      searchButtonValue: '搜索',
      options: { fontSize: '14fp', fontColor: '#ff0e1216' }
    },
    onSubmit: (value: string) => { /* 处理提交 */ },
    onChange: (value: string) => { /* 处理变化 */ },
    onEditChange: (isEditing: boolean) => { /* 编辑状态 */ }
  }
})
```

### 选择区 + 功能区

```typescript
AtomicServiceSearch({
  select: {
    options: [{ value: '全部' }, { value: '商品' }],
    selected: -1,
    selectValue: '全部',
    onSelect: (index: number, value: string) => { /* 选择回调 */ }
  },
  operation: {
    auxiliaryItem: {
      value: $r('app.media.icon'),
      action: () => { /* 附属于搜索区的功能位 */ }
    },
    independentItem: {
      value: $r('app.media.icon'),
      action: () => { /* 独立于搜索区的功能位 */ }
    }
  }
})
```

### 输入过滤

```typescript
search: {
  inputFilter: {
    inputFilterValue: '[a-z]',  // 正则表达式
    error: (filtered: string) => { /* 被过滤的内容 */ }
  }
}
```

### 样式定制

```typescript
search: {
  componentBackgroundColor: '#F5F5F5',
  caretStyle: { width: 3, color: Color.Green },
  fontColor: '#333333',
  placeholderColor: '#999999',
  textAlign: TextAlign.Center,
  selectedBackgroundColor: '#3399FF',
  fontFeature: '"ss01" on',  // 等宽数字
  minFontSize: 4,
  maxFontSize: 40
}
```

---

## 编译注意事项

1. **导入路径**：`import { AtomicServiceSearch } from '@kit.ArkUI'`，不是从组件路径导入
2. **SearchController**：通过 `new SearchController()` 创建，作为参数传入组件
3. **参数式 API**：所有属性通过 `search` / `select` / `operation` 对象传入，不支持链式方法
4. **operation 限制**：最多两个功能位（auxiliaryItem + independentItem）
5. **编译无额外问题**：使用 AtomicServiceSearch 编译直接通过，无特殊配置需求
