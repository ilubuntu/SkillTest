# Localization Kit 开发经验

## 一、元服务 API 兼容性清单

### 可用 API

| API | 模块 | 说明 | 备注 |
|-----|------|------|------|
| `i18n.getCalendar()` | `@ohos.i18n` | 获取日历实例 | 可用 |
| `i18n.PhoneNumberFormat` | `@ohos.i18n` | 电话号码格式化 | 可用 |
| `intl.NumberFormat` | `@ohos.intl` | 数字格式化 | 完全可用 |
| `intl.DateTimeFormat` | `@ohos.intl` | 日期时间格式化 | 完全可用 |
| `intl.RelativeTimeFormat` | `@ohos.intl` | 相对时间格式化 | 可用 |
| `intl.Collator` | `@ohos.intl` | 字符串排序比较 | 完全可用 |
| `intl.PluralRules` | `@ohos.intl` | 复数规则 | 可用 |
| `Intl.NumberFormat` | `Intl` | 浏览器标准 NumberFormat | 可用 |

### 不可用/受限 API

| API | 模块 | 说明 | 原因 |
|-----|------|------|------|
| `i18n.getSystemLocale()` | `@ohos.i18n` | 获取系统区域设置 | 原子化服务不支持 |
| `i18n.getSystemLanguage()` | `@ohos.i18n` | 获取系统语言 | 原子化服务不支持 |
| `i18n.getSystemRegion()` | `@ohos.i18n` | 获取系统地区 | 原子化服务不支持 |
| `i18n.getSystemTimezone()` | `@ohos.i18n` | 获取系统时区 | 原子化服务不支持 |
| `i18n.is24HourClock()` | `@ohos.i18n` | 24小时制判断 | 原子化服务不支持 |
| `i18n.getSystemLocales()` | `@ohos.i18n` | 获取可用区域列表 | 原子化服务不支持 |

## 二、核心调用方式

### i18n 系统信息查询

```typescript
import i18n from '@ohos.i18n'

// 日历信息（可用）
let cal = i18n.getCalendar('zh-Hans', 'gregorian')
let firstDay = cal.getFirstDayOfWeek()  // 每周首日

// 电话号码格式化（可用）
let formatter = new i18n.PhoneNumberFormat('CN')
let formatted = formatter.format('13800138000')

// 系统语言/地区/时区（不可用）
// i18n.getSystemLocale()    -- 原子化服务不支持
// i18n.getSystemLanguage()  -- 原子化服务不支持
// i18n.getSystemTimezone()  -- 原子化服务不支持
```

### intl 格式化

```typescript
import intl from '@ohos.intl'

// 数字格式化
let nf = new intl.NumberFormat('zh-Hans-CN')
nf.format(1234567.89)  // "1,234,567.89"

// 货币格式化
let cf = new intl.NumberFormat('zh-Hans-CN', { style: 'currency', currency: 'CNY' })
cf.format(1234567.89)  // "¥1,234,567.89"

// 日期格式化
let df = new intl.DateTimeFormat('zh-Hans-CN', { dateStyle: 'full', timeStyle: 'medium' })
df.format(new Date())

// 相对时间
let rt = new intl.RelativeTimeFormat('zh-Hans-CN', { numeric: 'auto' })
rt.format(-1, 'day')   // "昨天"
rt.format(2, 'hour')   // "2小时后"

// 排序比较
let coll = new intl.Collator('zh-Hans-CN')
let words = ['苹果', '香蕉', '樱桃']
words.sort((a, b) => coll.compare(a, b))

// 复数规则
let pr = new intl.PluralRules('en-US')
pr.select(1)  // "one"
pr.select(5)  // "other"
```

## 三、编译问题与解决方案

1. **i18n 系统信息不可用**: `getSystemLocale`/`getSystemLanguage`/`getSystemRegion`/`getSystemTimezone` 等方法在原子化服务中不支持。可通过 `Intl` 标准对象的 `resolvedOptions()` 获取部分信息。
2. **数字格式属性**: 使用 `new Intl.NumberFormat('zh-Hans').resolvedOptions()` 可获取最小小数位数等配置信息。
3. **应用内多语言**: 建议配合资源目录 `resources/` 实现应用内多语言切换，不依赖系统 i18n API。

## 四、降级处理策略

1. **系统语言获取** -- 使用 `Intl.DateTimeFormat().resolvedOptions().locale` 间接获取当前 locale。
2. **时区信息** -- 通过 `new Date().getTimezoneOffset()` 获取时区偏移量。
3. **24小时制判断** -- 无法通过 i18n API 获取，可提供应用内设置让用户选择。
4. **格式化功能** -- `intl` 模块的 `NumberFormat`/`DateTimeFormat`/`Collator`/`PluralRules` 完全可用，建议优先使用。
5. **应用内多语言** -- 配合 `resources/` 目录的 `zh-CN`/`en-US` 等资源文件夹实现。
