# Row 组件开发经验

## API 兼容性清单

### 元服务可用 API

| API | 起始版本 | 元服务起始版本 | 说明 |
|-----|---------|--------------|------|
| `Row(options?: RowOptions)` | API 7 | API 11 | 构造函数，创建水平线性布局容器 |
| `RowOptions.space` (number\|string) | API 7 | API 11 | 子组件水平间距，默认 0vp，负数按 0 处理 |
| `.alignItems(value: VerticalAlign)` | API 7 | API 11 | 交叉轴（垂直方向）对齐，默认 Center |
| `.justifyContent(value: FlexAlign)` | API 8 | API 11 | 主轴（水平方向）排列，默认 Start |
| `.reverse(isReversed: Optional<boolean>)` | API 12 | API 12 | 水平方向反转排列，默认 true 表示反转 |

### 元服务受限 API（需更高版本）

| API | 起始版本 | 元服务起始版本 | 说明 |
|-----|---------|--------------|------|
| `Row(options?: RowOptions \| RowOptionsV2)` | API 18 | API 18 | 支持 RowOptionsV2，space 可为 Resource 类型 |
| `RowOptionsV2.space` (SpaceType) | API 18 | API 18 | 支持 number / string / Resource 类型间距 |

### 通用属性（元服务可用）

Row 支持通用属性，元服务中常用且可用的包括：
- `.width()` / `.height()` — 尺寸
- `.padding()` / `.margin()` — 内外边距
- `.backgroundColor()` — 背景色
- `.border()` / `.borderRadius()` — 边框圆角
- `.onClick()` — 点击事件（元服务页面可用，卡片受限）
- `.visibility()` / `.enabled()` — 可见性和启用状态
- `.layoutWeight()` — 布局权重
- `.flexShrink()` / `.flexGrow()` / `.flexBasis()` — 弹性属性

## 核心场景调用方式

### 1. 子元素间距 (space)

```typescript
Row({ space: 10 }) {
  Text('A')
  Text('B')
}
```

**要点：**
- space 负数按默认值 0 处理
- 当 justifyContent 设为 SpaceBetween / SpaceAround / SpaceEvenly 时，space 不生效
- API 18+ 支持通过 RowOptionsV2 使用 Resource 类型

### 2. 垂直对齐 (alignItems)

```typescript
Row() {
  Text('A').height(30)
  Text('B').height(50)
}
.alignItems(VerticalAlign.Center) // Top | Center | Bottom
```

**要点：**
- Row 交叉轴为垂直方向，使用 `VerticalAlign` 枚举
- 默认值 `VerticalAlign.Center`
- 子元素等高时各对齐方式视觉效果一致

### 3. 主轴排列 (justifyContent)

```typescript
Row() {
  Text('A').width('20%')
  Text('B').width('20%')
}
.justifyContent(FlexAlign.SpaceBetween)
```

**要点：**
- FlexAlign.Start / Center / End / SpaceBetween / SpaceAround / SpaceEvenly
- 默认值 `FlexAlign.Start`
- **关键限制**：子组件不设置 flexShrink 时默认不压缩，总宽度可超过容器，此时 Center 和 End 会失效
- 需配合 `.flexShrink(1)` 或百分比宽度使用

### 4. 反转排列 (reverse)

```typescript
Row() {
  Text('1')
  Text('2')
  Text('3')
}
.reverse(true)
```

**要点：**
- API 12+，元服务 API 12+
- true 表示反转，false 表示正序
- direction 属性影响主轴方向，reverse 在 direction 结果上再做一次反转
- 未设置 reverse 时主轴不反转；设为 undefined 时视为 true

### 5. 嵌套布局 (Row + Column + Blank + layoutWeight)

```typescript
Row() {
  Text('标签')
  Blank()        // 水平方向填充空白
  Text('值 >')
}
.width('100%')
```

**要点：**
- `Blank()` 在 Row 中填充主轴（水平方向）空白
- `layoutWeight()` 按权重分配 Row 主轴剩余空间
- Row 嵌套 Column 实现复杂水平布局
- 建议嵌套不超过 5 层，元服务中总节点数建议不超过 300

## Row vs Flex 性能选择

官方推荐优先使用 Row/Column 代替 Flex：
- Row/Column 是线性布局，计算复杂度低
- Flex 需要计算弹性伸缩，性能开销更大
- 简单水平/垂直排列场景优先用 Row/Column

## 降级策略

- **RowOptionsV2 (API 18+)**：当前使用 number 类型 space 代替 Resource 类型，功能一致
- **reverse (API 12+)**：若目标元服务低于 API 12，可通过手动反转子组件顺序替代
- **justifyContent 子组件溢出**：当 Center/End 失效时，确保子组件设置 `.flexShrink(1)` 或使用百分比宽度
