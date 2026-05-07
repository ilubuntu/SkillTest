# DatePicker 组件开发经验

## 元服务 API 兼容性清单

### 可用 API

| API | 元服务版本 | 说明 |
|---|---|---|
| `DatePicker(options?: DatePickerOptions)` | API 11+ | 日期选择器 |
| `DatePickerOptions.start / end / selected` | API 11+ | 起止和初始日期 |
| `.lunar(bool)` | API 11+ | 农历模式 |
| `.textStyle / .selectedTextStyle / .disappearTextStyle` | API 11+ | 文字样式 |
| `.onDateChange(Callback<Date>)` | API 11+ | 日期变化（替代废弃的 onChange） |

### 不可用 API

| API | 所需版本 | 说明 |
|---|---|---|
| `DatePickerMode` (DATE/YEAR_AND_MONTH/MONTH_AND_DAY) | API 18+ | 选择器模式 |
| `.enableHapticFeedback(bool)` | API 18+ | 触觉反馈 |
| `.canLoop(bool)` | API 20+ | 循环滚动控制 |
| `.digitalCrownSensitivity` | API 18+ | 仅穿戴设备 |

## 核心调用方式

```typescript
DatePicker({
  start: new Date('2020-01-01'),
  end: new Date('2030-12-31'),
  selected: new Date(2026, 3, 21)
}).lunar(false)
  .textStyle({ color: '#007DFF' })
  .onDateChange((value: Date) => { /* value.getFullYear()... */ })
```

## 降级策略

| 不可用 API | 降级方案 |
|---|---|
| DatePickerMode (API 18+) | 当前仅支持完整日期选择 |
| canLoop (API 20+) | 默认循环滚动，无法关闭 |
