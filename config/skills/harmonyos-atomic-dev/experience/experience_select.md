# Select 组件开发经验

## 组件概述

Select 提供下拉选择菜单，让用户在多个选项间选择。API version 8 开始支持，元服务从 API 11 开始支持。

官方参考：https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ts-basic-components-select

---

## 元服务 API 兼容性清单

### API 11+ 可用（元服务基础支持）

| API | 说明 | 元服务版本 |
|-----|------|-----------|
| `Select(options: Array<SelectOption>)` | 创建下拉选择 | API 11+ |
| `SelectOption.value` | 选项文本 | API 11+ |
| `SelectOption.icon` | 选项图片 | API 11+ |
| `.selected(value: number \| Resource)` | 设置初始选中项索引 | API 11+ |
| `.value(value: ResourceStr)` | 设置按钮显示文本 | API 11+ |
| `.font(value: Font)` | 设置按钮文本样式 | API 11+ |
| `.fontColor(value: ResourceColor)` | 设置按钮文本颜色 | API 11+ |
| `.selectedOptionBgColor(value)` | 选中项背景色 | API 11+ |
| `.selectedOptionFont(value)` | 选中项文本样式 | API 11+ |
| `.selectedOptionFontColor(value)` | 选中项文本颜色 | API 11+ |
| `.optionBgColor(value)` | 菜单项背景色 | API 11+ |
| `.optionFont(value)` | 菜单项文本样式 | API 11+ |
| `.optionFontColor(value)` | 菜单项文本颜色 | API 11+ |
| `.space(value: Length)` | 文本与箭头间距，默认 8 | API 11+ |
| `.arrowPosition(value)` | 箭头位置 END/START | API 11+ |
| `.menuAlign(type, offset?)` | 菜单对齐方式 | API 11+ |
| `.onSelect(callback)` | 选中项回调 | API 11+ |
| `ArrowPosition` 枚举 | END(0) / START(1) | API 11+ |
| `MenuAlignType` 枚举 | START(0) / CENTER(1) / END(2) | API 11+ |

### API 12+ 可用

| API | 说明 | 元服务版本 |
|-----|------|-----------|
| `SelectOption.symbolIcon` | Symbol 图标，优先级高于 icon | API 12+ |
| `.controlSize(value: ControlSize)` | 组件尺寸控制 | API 12+ |
| `.menuItemContentModifier(modifier)` | 自定义菜单项内容 | API 12+ |
| `.divider(options \| null)` | 分割线样式 | API 12+ |
| `.optionWidth(value)` | 菜单项宽度 | API 12+ |
| `.optionHeight(value)` | 菜单最大高度 | API 12+ |
| `.menuBackgroundColor(value)` | 菜单背景色 | API 12+ |
| `.menuBackgroundBlurStyle(value)` | 菜单背景模糊材质 | API 12+ |
| `MenuItemConfiguration` | 自定义菜单项配置对象 | API 12+ |

### API 18+ Optional 重载版本

所有 API 11+/12+ 的属性都有对应的 `Optional<T>` 参数重载版本（API 18+ 元服务可用），支持 `undefined` 类型和 `!!` 双向绑定。**非 Optional 版本完全可替代，不影响实际开发。**

### API 19+ 新增

| API | 说明 | 元服务版本 |
|-----|------|-----------|
| `.avoidance(mode)` | 菜单避让模式 | API 19+ |
| `.dividerStyle(style)` | 分割线样式（支持 EMBEDDED_IN_MENU 模式） | API 19+ |

### API 20+ 新增

| API | 说明 | 元服务版本 |
|-----|------|-----------|
| `.menuOutline(outline)` | 菜单外描边样式 | API 20+ |
| `.showDefaultSelectedIcon(show)` | 显示默认选中图标 | API 20+ |
| `.textModifier(modifier)` | 定制按钮文本样式 | API 20+ |
| `.arrowModifier(modifier)` | 定制箭头图标样式 | API 20+ |
| `.optionTextModifier(modifier)` | 定制未选中项文本样式 | API 20+ |
| `.selectedOptionTextModifier(modifier)` | 定制选中项文本样式 | API 20+ |
| `.showInSubWindow(show)` | 菜单显示在子窗中（仅 PC/2in1） | API 20+ |

---

## 核心调用方式

### 基础用法

```typescript
Select([
  { value: '选项一' },
  { value: '选项二' },
  { value: '选项三' }
])
  .selected(0)           // 初始选中第一项
  .value('请选择')       // 按钮文本
  .font({ size: 16, weight: 500 })
  .fontColor('#182431')
  .onSelect((index: number, text?: string) => {
    console.info(`选中: ${index}, ${text}`)
  })
```

### 样式定制

```typescript
Select(options)
  .selectedOptionBgColor('#E3F2FD')     // 选中项背景
  .selectedOptionFontColor('#1976D2')   // 选中项文字颜色
  .selectedOptionFont({ size: 16, weight: FontWeight.Bold })
  .optionBgColor('#FFFFFF')             // 菜单项背景
  .optionFontColor('#666666')           // 菜单项文字颜色
  .optionFont({ size: 14, weight: FontWeight.Normal })
```

### 布局与对齐

```typescript
Select(options)
  .space(20)                              // 文本与箭头间距
  .arrowPosition(ArrowPosition.END)       // 箭头在文字后
  .menuAlign(MenuAlignType.START)         // 菜单左对齐
  .optionWidth(200)                       // 菜单项宽度（API 12+）
  .optionHeight(300)                      // 菜单最大高度（API 12+）
```

### 自定义分割线

```typescript
Select(options)
  .divider({                    // API 12+
    strokeWidth: 2,
    color: '#2196F3',
    startMargin: 10,
    endMargin: 10
  })
// .divider(null)               // 不显示分割线
```

### 自定义菜单项

```typescript
class MyModifier implements ContentModifier<MenuItemConfiguration> {
  applyContent(): WrappedBuilder<[MenuItemConfiguration]> {
    return wrapBuilder(itemBuilder)
  }
}

@Builder
function itemBuilder(config: MenuItemConfiguration) {
  Row() {
    Text(config.value)
      .fontColor(config.selected ? '#1976D2' : '#666666')
    if (config.selected) { Text('✓') }
  }
  .onClick(() => {
    config.triggerSelect(config.index, config.value.valueOf().toString())
  })
}

Select(options)
  .menuItemContentModifier(new MyModifier())  // API 12+
```

---

## 编译问题与解决方案
### 1. selected 属性行为

- `selected(-1)` 或不设置：菜单项不选中
- `selected(undefined/null)`：选中第一项
- `selected(0)`：选中第一项
- 选中后按钮文本会自动更新为选中项文本

---

## 降级处理策略

| 目标 API | 不可用 API | 替代方案 |
|---------|-----------|---------|
| API 11 | optionWidth/optionHeight | 使用默认菜单宽度 |
| API 11 | divider/controlSize | 不设置，使用默认 |
| API 11 | menuItemContentModifier | 使用 fontColor/BgColor 定制 |
| API < 18 | Optional 参数重载 | 使用非 Optional 版本 |
| API < 18 | !! 双向绑定 | 使用 onSelect 手动管理状态 |
| API < 19 | avoidance/dividerStyle | 使用 divider() |
| API < 20 | textModifier/arrowModifier | 使用 font/fontColor |
