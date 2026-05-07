# TextInput 组件开发经验 — 元服务 (AtomicService)

## 一、API 兼容性清单

### 1.1 元服务 API 11+ 可用（基础能力，稳定可用）

| 分类 | API | 说明 |
|------|-----|------|
| **接口** | `TextInput(value?: TextInputOptions)` | 基础构造，placeholder/text/controller 参数 |
| **输入类型** | `InputType.Normal` | 基本输入模式，无限制 |
| | `InputType.Number` | 纯数字输入（不支持负数、小数） |
| | `InputType.PhoneNumber` | 电话号码（数字、空格、+、-、*、#、括号） |
| | `InputType.Email` | 邮箱地址输入 |
| | `InputType.NUMBER_DECIMAL` | 带小数点的数字 |
| | `InputType.Password` | 密码输入 |
| **样式属性** | `placeholderColor` | placeholder 文本颜色 |
| | `placeholderFont` | placeholder 字体样式（大小/粗细/族/风格） |
| | `caretColor` | 光标颜色，默认 #007DFF |
| | `fontColor` | 输入文本字体颜色 |
| | `fontSize` | 字体大小，number 时 fp 单位，默认 16fp |
| | `fontStyle` | FontStyle.Normal/Italic |
| | `fontWeight` | 字体粗细 100-900，默认 400 |
| | `fontFamily` | 字体列表，默认 HarmonyOS Sans |
| | `textAlign` | 水平对齐：Start/Center/End |
| | `selectedBackgroundColor` | 文本选中底板颜色（默认 20% 不透明度） |
| | `caretStyle` | 光标风格（宽度等） |
| | `caretPosition` | 初始光标位置（属性级别） |
| | `maxLength` | 最大输入字符数，默认 Infinity |
| | `inputFilter` | 正则过滤输入，error 回调返回被过滤内容 |
| | `copyOption` | 文本可复制性（LocalDevice/CrossDevice/None） |
| | `showPasswordIcon` | 密码模式末尾图标显隐 |
| | `style` | TextInputStyle.Default/Inline |
| | `showUnderline` | 下划线模式，仅 Normal 类型，默认 false |
| | `showError` | 错误提示文本 |
| | `showUnit` | 文本框单位控件，需搭配 showUnderline |
| | `passwordIcon` | 密码模式末尾自定义图标（PasswordIcon 对象） |
| | `enableKeyboardOnFocus` | 非点击获焦时是否拉起键盘，默认 true |
| | `selectionMenuHidden` | 隐藏系统文本选择菜单 |
| | `barState` | 内联模式编辑态滚动条显示模式 |
| | `maxLines` | 内联模式编辑态最大行数，默认 3 |
| | `customKeyboard` | 自定义键盘（CustomBuilder） |
| | `showCounter` | 字符计数器，需配合 maxLength |
| | `enterKeyType` | 回车键类型：Go/Search/Send/Next/Done |
| **事件** | `onChange` | 输入内容变化回调 |
| | `onSubmit` | 回车键提交回调 |
| | `onEditChange` | 编辑状态变化（有无光标） |
| | `onCopy` / `onCut` / `onPaste` | 复制/剪切/粘贴操作回调 |
| | `onTextSelectionChange` | 选择/光标位置变化回调 |
| | `onContentScroll` | 文本内容滚动回调 |
| **控制器** | `TextInputController` | 控制器（caretPosition/setTextSelection/stopEditing） |

### 1.2 元服务 API 12+ 可用（需确认目标 API 版本）

| 分类 | API | 说明 |
|------|-----|------|
| **输入类型** | `InputType.NUMBER_PASSWORD` | 纯数字密码 |
| | `InputType.USER_NAME` | 用户名（支持密码保险箱） |
| | `InputType.NEW_PASSWORD` | 新密码（支持密码保险箱） |
| | `InputType.URL` | URL 输入 |
| **属性** | `enableAutoFill` | 自动填充开关，默认 true |
| | `passwordRules` | 密码生成规则 |
| | `cancelButton` | 右侧清除按钮样式 |
| | `selectAll` | 初始全选文本 |
| | `contentType` | 自动填充类型（ContentType 枚举） |
| | `underlineColor` | 下划线颜色（各状态） |
| | `lineHeight` | 文本行高 |
| | `decoration` | 文本装饰线（类型/颜色/样式） |
| | `letterSpacing` | 字符间距 |
| | `fontFeature` | 文字特性效果 |
| | `wordBreak` | 文本断行规则 |
| | `textOverflow` | 超长显示方式（仅内联模式） |
| | `textIndent` | 首行缩进 |
| | `minFontSize` / `maxFontSize` | 自适应字号范围 |
| | `heightAdaptivePolicy` | 自适应高度策略 |
| | `showPassword` | 密码显隐控制 |
| | `lineBreakStrategy` | 折行规则 |
| | `editMenuOptions` | 自定义菜单扩展项 |
| | `enablePreviewText` | 输入预上屏 |
| **事件** | `onSecurityStateChange` | 密码显隐状态变化 |
| | `onWillInsert` / `onDidInsert` | 输入拦截（仅系统输入法） |
| | `onWillDelete` / `onDidDelete` | 删除拦截（仅系统输入法） |

### 1.3 元服务 API 13+ / 15+ / 18+ / 20+ 可用

| API 版本 | API | 说明 |
|----------|-----|------|
| 13+ | `enableHapticFeedback` | 触控反馈（需 VIBRATE 权限） |
| 15+ | `keyboardAppearance` | 键盘样式 |
| 15+ | `stopBackPress` | 阻止返回键 |
| 15+ | `onWillChange` | 文本变化拦截 |
| 18+ | `halfLeading` | 文本垂直居中 |
| 18+ | `minFontScale` / `maxFontScale` | 字体缩放范围 |
| 18+ | `ellipsisMode` | 省略位置 |
| 20+ | `autoCapitalizationMode` | 自动大小写 |
| 20+ | `strokeWidth` / `strokeColor` | 文本描边 |
| 20+ | `enableAutoSpacing` | 中西文自动间距 |
| 20+ | `onWillAttachIME` | 输入法绑定回调 |

### 1.4 不可用 / 受限 API

| API | 限制原因 |
|-----|----------|
| `InputType.ONE_TIME_CODE` | API 20+，元服务版本依赖 |
| `enableSelectedDataDetector` | API 22+ |
| 组件级拖拽 | 元服务不支持 |

## 二、核心调用方式

### 2.1 基本输入框创建

```typescript
TextInput({ placeholder: '提示文本', text: '初始内容' })
  .type(InputType.Normal)
  .width('90%')
  .height(48)
  .onChange((value: string) => { /* 处理 */ })
```

### 2.2 输入过滤（正则）

```typescript
TextInput({ placeholder: '仅字母数字' })
  .inputFilter('^[a-zA-Z0-9]*$', (err: string) => {
    // err 为被过滤的字符
  })
```

**注意**: 设置 inputFilter 且输入不为空时，`type` 附带的文本过滤效果会失效。

### 2.3 密码模式

```typescript
TextInput({ placeholder: '密码' })
  .type(InputType.Password)        // 或 NUMBER_PASSWORD / NEW_PASSWORD
  .showPasswordIcon(true)           // 末尾眼睛图标
  .showPassword(this.isShowPwd)     // API 12+: 显隐控制
  .passwordRules('required: upper; required: lower; required: digit; minlength: 8')
  .onSecurityStateChange((isSecure: boolean) => { /* 同步状态 */ })
```

**限制**:
- 密码模式下 `showUnderline` 和 `decoration` 不生效
- `onSecurityStateChange` 建议配合 `showPassword` 使用，保持状态同步

### 2.4 控制器操作

```typescript
const controller = new TextInputController()

TextInput({ controller: controller })
  // ...
controller.caretPosition(5)                              // 设置光标位置
controller.setTextSelection(0, text.length)               // 全选
controller.stopEditing()                                  // 退出编辑态
```

### 2.5 回车键类型

```typescript
TextInput({ placeholder: '搜索...' })
  .enterKeyType(EnterKeyType.Search)   // Go/Search/Send/Next/Done
  .onSubmit((enterKey: EnterKeyType) => {
    // 非TV设备按下回车默认失焦+收起键盘
  })
```

### 2.6 字符计数器

```typescript
TextInput({ placeholder: '最多20字' })
  .maxLength(20)
  .showCounter(true)  // 需配合 maxLength 使用
```

**注意**: 内联模式和密码模式下计数器不显示。

### 2.7 下划线模式

```typescript
TextInput({ placeholder: '下划线风格' })
  .showUnderline(true)    // 仅 Normal 类型有效
  .showError('格式错误')  // 搭配错误提示
  .showUnit(() => { Text('元') })  // 搭配单位显示
```

### 2.8 内联模式

```typescript
TextInput({ placeholder: '内联输入' })
  .style(TextInputStyle.Inline)     // 内联风格，仅 Normal 类型
  .maxLines(5)                       // 编辑态最大行数
  .barState(BarState.Auto)           // 滚动条模式
  .wordBreak(WordBreak.BREAK_ALL)    // 断行规则
  .textOverflow(TextOverflow.Ellipsis) // 超长省略
```

## 三、降级处理策略

### 3.1 高版本 API 降级

| 高版本 API | 降级方案 |
|------------|----------|
| `showPassword` (12+) | 使用 `showPasswordIcon` 控制图标显隐，手动管理密码状态 |
| `contentType` (12+) | 不使用自动填充，手动实现表单逻辑 |
| `editMenuOptions` (12+) | 使用 `selectionMenuHidden(true)` 隐藏菜单后自行实现 |
| `onWillInsert/onWillDelete` (12+) | 在 `onChange` 中做后置校验和回滚 |
| `enableHapticFeedback` (13+) | 不设置，使用系统默认行为 |
| `keyboardAppearance` (15+) | 不设置，使用系统默认键盘样式 |
| `ellipsisMode` (18+) | 默认 EllipsisMode.END 已满足大多数场景 |
| `autoCapitalizationMode` (20+) | 依赖输入法自身设置 |

### 3.2 核心建议

- **优先使用 API 11+ 的基础属性**，覆盖 90% 常见输入场景
- **API 12+ 的密码相关类型**（NUMBER_PASSWORD/USER_NAME/NEW_PASSWORD）配合密码保险箱使用
- **`inputFilter` 可替代部分 InputType 的过滤能力**，但会覆盖 type 的过滤效果
- **内联模式 (`TextInputStyle.Inline`) 仅支持 Normal 类型**，其他类型会回退到 Default
