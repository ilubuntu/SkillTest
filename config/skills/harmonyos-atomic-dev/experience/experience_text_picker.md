# TextPicker 文本选择器 — 元服务开发经验

## 一、组件概述

TextPicker 是滑动选择文本内容的组件，支持三种模式：
- **单列选择器**：range 传入 `string[]`
- **多列非联动选择器**：range 传入 `string[][]`
- **多列联动选择器**：range 传入 `TextCascadePickerRangeContent[]`

## 二、元服务 API 兼容性清单

### API 11+ 可用（核心）

| API | 说明 |
|-----|------|
| `TextPicker(options?)` | 构造函数，range/selected/value |
| `TextPickerRangeContent` | 单列图文选项（icon + text） |
| `TextCascadePickerRangeContent` | 多列联动选项（text + children） |
| `defaultPickerItemHeight` | 设置所有选项高度（选中/非选中统一） |
| `disappearTextStyle` | 边缘项样式（上下第二项） |
| `textStyle` | 待选项样式（上下第一项） |
| `selectedTextStyle` | 选中项样式 |
| `selectedIndex` | 设置/获取选中项索引 |
| `canLoop` | 是否循环滚动（默认 true） |
| `onChange` | 滑动选中回调 |

### API 12+ 可用

| API | 说明 |
|-----|------|
| `DividerOptions` | 分割线配置对象（strokeWidth/startMargin/endMargin/color） |
| `divider` | 设置分割线样式，传 null 隐藏分割线 |
| `gradientHeight` | 渐隐效果高度（默认 36vp，设 0 无渐隐） |

### API 14+ 可用

| API | 说明 |
|-----|------|
| `onScrollStop` | 滑动停止回调 |

### API 15+ 可用

| API | 说明 |
|-----|------|
| `disableTextStyleAnimation` | 关闭滑动过程中文本样式变化动画 |
| `defaultTextStyle` | 关闭动画后的统一文本样式（需配合 disableTextStyleAnimation） |
| `TextPickerTextStyle` | 扩展文本样式（含 minFontSize/maxFontSize/overflow） |

### API 18+ 可用

| API | 说明 |
|-----|------|
| `onEnterSelectedArea` | 滑动过程中进入选中区域即触发（早于 onChange） |
| `enableHapticFeedback` | 触控反馈（需 VIBRATE 权限） |
| `columnWidths` | 多列时各列宽度（LengthMetrics[]） |
| 各属性的 Optional<> 重载 | 支持 undefined 参数 |

### API 20+ 可用

| API | 说明 |
|-----|------|
| `selectedBackgroundStyle` | 选中项背景颜色和圆角（PickerBackgroundStyle） |
| textStyle/disappearTextStyle/selectedTextStyle 支持 TextPickerTextStyle | 含 minFontSize/maxFontSize/overflow |

### 已废弃

| API | 说明 |
|-----|------|
| `onAccept`（组件级） | API 10 废弃，仅在弹窗有效 |
| `onCancel`（组件级） | API 10 废弃，仅在弹窗有效 |
| `TextPickerDialog.show()` | API 18 废弃，使用 `UIContext.showTextPickerDialog()` |

### 穿戴设备专用

| API | 说明 |
|-----|------|
| `digitalCrownSensitivity` | 表冠灵敏度（API 18+，圆形屏幕穿戴设备） |

## 三、核心调用方式

### 3.1 单列文本选择器

```typescript
TextPicker({ range: ['apple', 'orange', 'peach'], selected: 0 })
  .onChange((value: string | string[], index: number | number[]) => {
    // value: string, index: number
  })
```

### 3.2 多列非联动

```typescript
const multi: string[][] = [['a1','a2'], ['b1','b2'], ['c1','c2']]
TextPicker({ range: multi })
  .onChange((value: string | string[], index: number | number[]) => {
    // value: string[], index: number[]
  })
```

### 3.3 多列联动（级联）

```typescript
const cascade: TextCascadePickerRangeContent[] = [
  { text: '辽宁省', children: [
    { text: '沈阳市', children: [{ text: '沈河区' }, { text: '和平区' }] }
  ]}
]
TextPicker({ range: cascade })
```

### 3.4 弹窗选择器

```typescript
// 推荐：UIContext 方式（API 10+）
this.getUIContext().showTextPickerDialog({
  range: this.fruits,
  selected: 0,
  onAccept: (value: TextPickerResult) => { /* 确定 */ },
  onCancel: () => { /* 取消 */ },
  onChange: (value: TextPickerResult) => { /* 滑动变化 */ }
})
```

### 3.5 分割线样式

```typescript
.divider({ strokeWidth: 2, color: '#33000000', startMargin: 0, endMargin: 0 })
// 隐藏分割线
.divider(null)
```

## 四、关键参数说明

### onChange 回调签名

```
onChange(callback: (value: string | string[], index: number | number[]) => void)
```
- 单列：value 为 `string`，index 为 `number`
- 多列：value 为 `string[]`，index 为 `number[]`
- 回调在滑动动画结束后触发，非即时

### selected 与 selectedIndex 优先级

`selectedIndex` 属性优先级高于 `TextPickerOptions.selected`。

### defaultPickerItemHeight

设置后选中项和非选中项高度统一为此值，不再有选中/非选中差异。

## 五、编译过程注意事项

### 5.1 类型断言

onChange 回调的 value/index 是联合类型 `string | string[]`，需要用 `as string` 或 `as string[]` 断言后使用：
```typescript
.onChange((value: string | string[], index: number | number[]) => {
  const v = value as string  // 单列
  const arr = value as string[]  // 多列
})
```

### 5.2 DividerOptions 类型

divider 属性接受 `DividerOptions | null`，必须用 `as DividerOptions` 显式标注类型：
```typescript
.divider({ strokeWidth: 2, color: '#33000000' } as DividerOptions)
```

### 5.3 TextPickerDialog 废弃处理

`TextPickerDialog.show()` 已废弃，必须使用 `this.getUIContext().showTextPickerDialog()` 调用。在 `@ComponentV2` 中可直接使用 `this.getUIContext()`。

### 5.4 编译警告

编译时会有 `getContext` deprecated 警告（来自其他组件），不影响 TextPicker 功能。TextPicker 组件本身无编译警告。

## 六、降级处理策略

| 场景 | 降级方案 |
|------|---------|
| 需要 onAccept 确认回调 | 使用 TextPickerDialog 弹窗模式 |
| 需要 onEnterSelectedArea (API 18+) | 低版本使用 onChange 替代 |
| 需要 selectedBackgroundStyle (API 20+) | 无法降级，低版本不设置 |
| 需要 columnWidths (API 18+) | 低版本使用默认等宽列 |
| 穿戴设备表冠功能 | 手机端忽略此属性 |