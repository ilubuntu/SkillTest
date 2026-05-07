# Badge 组件开发经验

## 元服务 API 兼容性清单

### 可用 API

| 组件 / API | 元服务起始版本 | 说明 |
|---|---|---|
| `Badge(value: BadgeParamWithNumber)` | API 11+ | 根据数字创建标记，卡片能力 API 9+ |
| `Badge(value: BadgeParamWithString)` | API 11+ | 根据字符串创建标记，卡片能力 API 9+ |
| `BadgeParam.position` (BadgePosition) | API 11+ | RightTop / Right / Left 三种位置 |
| `BadgeParam.position` (Position) | API 10+ | 自定义坐标 { x, y }，不支持百分比 |
| `BadgeParamWithNumber.count` | API 11+ | 消息数，<=0 时不显示标记 |
| `BadgeParamWithNumber.maxCount` | API 11+ | 最大消息数，默认 99，超过显示 maxCount+ |
| `BadgeParamWithString.value` | API 11+ | 提示文本（string 类型），API 20+ 支持 ResourceStr |
| `BadgeStyle.badgeSize` | API 11+ | Badge 大小，默认 16vp |
| `BadgeStyle.badgeColor` | API 11+ | Badge 背景色，默认 Color.Red |
| `BadgeStyle.fontSize` | API 11+ | 文本大小，默认 10vp |
| `BadgeStyle.fontWeight` | API 10+ | 字体粗细，默认 FontWeight.Normal |
| `BadgeStyle.color` | API 11+ | 文本颜色，默认 Color.White |
| `BadgeStyle.borderColor` | API 10+ | 底板描边颜色，默认 Color.Red |
| `BadgeStyle.borderWidth` | API 10+ | 底板描边粗细，默认 1vp |

### 不可用 API

| API | 要求版本 | 状态 | 说明 |
|---|---|---|---|
| `BadgeStyle.outerBorderColor` | API 22+ | 不可用 | 底板外描边颜色，默认 Color.White |
| `BadgeStyle.outerBorderWidth` | API 22+ | 不可用 | 底板外描边粗细，默认 0vp |
| `BadgeStyle.enableAutoAvoidance` | API 22+ | 不可用 | 角标文本延伸时是否避让子组件 |
| `BadgeParamWithString.value` (ResourceStr) | API 20+ | 部分不可用 | API 11-19 仅支持 string 类型 |
| `BadgeStyle.fontSize` (ResourceStr) | API 20+ | 部分不可用 | API 11-19 仅支持 number 类型 |
| `BadgeStyle.badgeSize` (ResourceStr) | API 20+ | 部分不可用 | API 11-19 仅支持 number 类型 |

---

## 各场景核心调用方式

### 1. 数字标记（BadgeParamWithNumber）

最基础的用法，通过 `count` 显示消息数量：

```typescript
Badge({
  count: 1,
  maxCount: 99,
  position: BadgePosition.RightTop,
  style: { badgeSize: 16, badgeColor: '#FA2A2D' }
}) {
  // 子组件（仅支持单个）
  Text('消息')
}
```

**关键参数：**
- `count`: <=0 时标记不显示；> maxCount 时显示 `maxCount+`
- `maxCount`: 默认 99，取值范围 [-2147483648, 2147483647]
- 非整数时会舍去小数部分

### 2. 文本标记（BadgeParamWithString）

显示自定义文本而非数字：

```typescript
Badge({
  value: 'NEW',
  position: BadgePosition.Right,
  style: { badgeSize: 20, badgeColor: '#00B578', fontSize: 10 }
}) {
  Text('功能入口')
}
```

**注意：** 使用 `value` 时 `count` 和 `maxCount` 不生效。

### 3. 位置控制

```typescript
// 枚举位置
position: BadgePosition.RightTop  // 右上角（默认）
position: BadgePosition.Right     // 右侧纵向居中
position: BadgePosition.Left      // 左侧纵向居中

// 自定义坐标（API 10+）
position: { x: 80, y: 0 }  // 不支持百分比，非法值默认 (0,0)
```

**注意：** `BadgePosition` 会跟随 `Direction` 属性控制镜像显示；`Position` 不会。

### 4. 样式自定义

```typescript
style: {
  badgeSize: 24,           // Badge 大小（vp）
  badgeColor: '#9B59B6',   // 背景色
  fontSize: 14,            // 文本大小（vp）
  fontWeight: FontWeight.Bold,  // API 10+
  color: Color.White,      // 文本颜色
  borderColor: '#FF6B00',  // 描边颜色（API 10+）
  borderWidth: 2           // 描边粗细 vp（API 10+）
}
```

**注意：** 当 `borderWidth > 0` 且 `borderColor !== badgeColor` 时，由于抗锯齿处理，四角会出现 badgeColor 颜色的描边线。如需完美效果，建议使用 Text 组件设置 outline 代替。

### 5. 圆点标记

将 `value` 设为空字符串可创建纯圆点标记：

```typescript
Badge({
  value: '',
  position: BadgePosition.RightTop,
  style: { badgeSize: 8, badgeColor: '#FA2A2D' }
}) {
  Text('圆点提醒')
}
```

### 6. 动态显隐

通过 `if/else` 条件控制 Badge 的显示和隐藏：

```typescript
if (this.badgeVisible && this.badgeCount > 0) {
  Badge({ count: this.badgeCount, ... }) {
    Text('消息')
  }
} else {
  Text('消息（标记隐藏）')
}
```

**注意：** Badge 组件显隐时支持 scale 动效（API 12+）。

---

## 子组件注意事项

1. **仅支持单个子组件**，多个子组件时只有最后一个会显示，但其余子组件状态更新仍会触发重新布局渲染
2. 子组件可以是系统组件或自定义组件
3. 支持 `if/else`、`ForEach`、`LazyForEach` 渲染控制
4. **自定义组件宽高默认为 0**，必须显式设置宽高，否则 Badge 不显示
5. Badge 不影响子组件布局，不会主动规避子组件内容

---

## 编译过程中的问题与解决方案

### 无 badge 相关编译错误

Badge 组件在元服务中编译表现良好，使用 `@ComponentV2` + `@Local` 装饰器无兼容性问题。所有 API 11+ 级别的属性均能正常通过编译。

### 注意事项

- `BadgePosition` 枚举和 `Position` 类型（自定义坐标）均可正常使用
- `borderColor`/`borderWidth`（API 10+）在 `BadgeStyle` 中直接使用即可，无需额外导入
- Badge 组件支持通用属性和通用事件

---

## 降级处理策略

| 不可用 API | 降级方案 |
|---|---|
| `outerBorderColor` / `outerBorderWidth`（API 22+） | 使用 `borderColor` + `borderWidth`（API 10+）实现描边效果，视觉上模拟外描边 |
| `enableAutoAvoidance`（API 22+） | 当前版本角标不进行避让，文本可能覆盖子组件；可通过调整 `badgeSize` 和子组件 padding 缓解 |
| `BadgeParamWithString.value` (ResourceStr) | 使用纯字符串值，避免传入 Resource 引用 |
