# Radio 组件元服务开发经验

## 一、API 元服务兼容性清单

### 1.1 可用 API

| API | 元服务起始版本 | 说明 |
|-----|---------------|------|
| `Radio(options: RadioOptions)` | API 11+ | 创建单选框组件 |
| `RadioOptions.value` | API 11+ | 单选框的值 |
| `RadioOptions.group` | API 11+ | 所属群组名称，同组仅一个可选中 |
| `RadioOptions.indicatorType` | API 12+ | 选中样式 (TICK/DOT/CUSTOM) |
| `RadioOptions.indicatorBuilder` | API 12+ | 自定义选中指示器 (CustomBuilder) |
| `RadioIndicatorType` 枚举 | API 12+ | TICK=0, DOT=1, CUSTOM=2 |
| `checked(value: boolean)` | API 11+ | 设置选中状态，默认 false |
| `radioStyle(value?: RadioStyle)` | API 11+ | 设置选中/非选中样式 |
| `RadioStyle.checkedBackgroundColor` | API 11+ | 选中底板颜色 |
| `RadioStyle.uncheckedBorderColor` | API 11+ | 未选中描边颜色 |
| `RadioStyle.indicatorColor` | API 11+ | 选中时内部指示器颜色 |
| `onChange(callback)` | API 11+ | 选中状态变化回调 |
| `contentModifier(modifier)` | API 12+ | 定制 Radio 内容区 |
| `RadioConfiguration` | API 12+ | contentModifier 配置对象 |

### 1.2 不支持 / 受限 API

| API | 版本要求 | 说明 | 替代方案 |
|-----|---------|------|---------|
| `checked(isChecked: Optional<boolean>)` | API 18+ | 支持 undefined 参数 | 使用 `checked(value: boolean)` (API 11+) |
| `onChange(callback: Optional<...>)` | API 18+ | callback 支持 undefined | 使用 `onChange(callback)` (API 11+) |
| `contentModifier(modifier: Optional<...>)` | API 18+ | modifier 支持 undefined | 使用 `contentModifier(modifier)` (API 12+) |
| `checked` 属性 `!!` 双向绑定 | API 18+ | 新双向绑定语法 | 使用手动 onChange 管理状态 |

## 二、各场景核心调用方式

### 2.1 基础创建与分组单选

```typescript
Radio({ value: 'option1', group: 'myGroup' })
  .checked(true)
  .onChange((isChecked: boolean) => {
    if (isChecked) { /* 处理选中 */ }
  })
```

关键点：
- `value` 标识当前 Radio，`group` 控制单选互斥
- 同 group 的 Radio 只有一个可选中，切换时旧项触发 `onChange(false)`，新项触发 `onChange(true)`
- `checked` 默认 false，需显式设置初始选中项

### 2.2 样式定制 (radioStyle)

```typescript
Radio({ value: 'v1', group: 'g1' })
  .radioStyle({
    checkedBackgroundColor: Color.Pink,    // 选中底板色
    uncheckedBorderColor: '#FF6B6B',       // 未选中描边色
    indicatorColor: '#FFFFFF'              // 内部指示器色
  })
```

关键点：
- `RadioStyle` 三个属性均为可选，可单独设置
- `indicatorColor` 在 `indicatorType` 为 CUSTOM 时不生效
- 默认颜色使用系统资源 `$r('sys.color.ohos_id_color_*')`

### 2.3 指示器类型 (indicatorType)

```typescript
// TICK 样式 (API 12+ 默认)
Radio({ value: 'v1', group: 'g1', indicatorType: RadioIndicatorType.TICK })

// DOT 样式 (API 8~11 默认)
Radio({ value: 'v2', group: 'g1', indicatorType: RadioIndicatorType.DOT })

// CUSTOM 自定义
Radio({
  value: 'v3', group: 'g1',
  indicatorType: RadioIndicatorType.CUSTOM,
  indicatorBuilder: () => { this.myBuilder() }
})
```

关键点：
- API 12 起默认由 DOT 改为 TICK
- CUSTOM 模式需配合 `indicatorBuilder`，自定义组件与 Radio 中心点对齐
- `indicatorBuilder` 设为 undefined 时按 TICK 显示

### 2.4 自定义内容 (contentModifier)

```typescript
class MyModifier implements ContentModifier<RadioConfiguration> {
  applyContent(): WrappedBuilder<[RadioConfiguration]> {
    return wrapBuilder(buildMyRadio)
  }
}

@Builder
function buildMyRadio(config: RadioConfiguration) {
  // config.value: string — Radio 的值
  // config.checked: boolean — 选中状态
  // config.triggerChange(bool) — 触发状态变化
  // config.contentModifier — 可强转为自定义 class 获取额外数据
}
```

关键点：
- 必须实现 `ContentModifier<RadioConfiguration>` 接口
- `applyContent()` 返回 `WrappedBuilder`，通过 `wrapBuilder` 包装
- 通过 `config.contentModifier as MyModifier` 可获取自定义 class 的属性
- `triggerChange()` 用于在自定义 UI 中触发 Radio 状态变化

### 2.5 状态管理注意事项

- 同组 Radio 切换时，需要手动管理各 Radio 的 `checked` 状态
- `onChange` 回调中 `isChecked=true` 表示选中，`false` 表示取消选中
- 切换顺序：先触发旧项的 `onChange(false)`，再触发新项的 `onChange(true)`

## 三、编译问题与解决方案

### 3.1 overlay 类型错误

**问题**：`Circle().overlay(Text(...))` 编译报错：
```
Argument of type 'TextAttribute' is not assignable to parameter of type
'string | CustomBuilder | ComponentContent<Object>'
```

**原因**：`overlay()` 不接受组件实例，只接受 `string | CustomBuilder | ComponentContent`。

**解决方案**：使用 `Stack()` 容器替代 `overlay()`，将 Circle 和条件渲染的 Text 叠放：
```typescript
Stack() {
  Circle({ width: 40, height: 40 })
    .fill(...)
  if (config.checked) {
    Text('✓')
  }
}
```

## 四、降级处理策略

### 4.1 API 版本降级

- **API 12+ 特性** (indicatorType/indicatorBuilder/contentModifier)：在低版本 SDK 上不可用，使用默认 TICK 样式和 onChange 回调替代
- **API 18+ Optional 重载**：使用非 Optional 版本完全可替代，无功能损失

### 4.2 元服务通用建议

- Radio 组件在元服务中功能完整，核心 API (11+) 覆盖创建、样式、事件
- API 12+ 扩展能力 (自定义指示器/内容修改器) 进一步丰富定制选项
- 所有 API 18+ 不支持的均为 Optional 参数重载，不影响实际开发
