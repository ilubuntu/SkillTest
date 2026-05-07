# CalendarPicker 组件开发经验

## 元服务 API 兼容性清单

### 可用 API

| API | 元服务版本 | 说明 |
|---|---|---|
| `CalendarPicker(options?: CalendarOptions)` | API 11+ | 日历选择器 |
| `CalendarOptions.hintRadius` | API 11+ | 提示圆半径 |
| `CalendarOptions.selected` | API 11+ | 初始选中日期 |
| `.edgeAlign(CalendarAlign)` | API 11+ | START/CENTER/END |
| `.textStyle(PickerTextStyle)` | API 11+ | 文字样式 |
| `.onChange(Callback<Date>)` | API 11+ | 日期变化回调 |

### 不可用 API

| API | 所需版本 | 说明 |
|---|---|---|
| `CalendarOptions.start / end` | API 18+ | 可选日期范围 |
| `.markToday(bool)` | API 19+ | 高亮今天 |
| `CalendarOptions.disabledDateRange` | API 19+ | 禁用日期范围 |

## 降级策略

| 不可用 API | 降级方案 |
|---|---|
| start/end (API 18+) | 在 onChange 中手动校验日期范围 |
| markToday (API 19+) | 通过 textStyle 自定义颜色 |

**注意：** Wearable 设备运行时会抛出"接口未定义"错误。
