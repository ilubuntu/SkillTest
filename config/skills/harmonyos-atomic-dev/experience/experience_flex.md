# Flex 弹性布局组件开发经验

## 元服务 API 兼容性

### 可用 API（元服务 API 11+）

| API | 类型 | 说明 |
|-----|------|------|
| `Flex(value?: FlexOptions)` | 容器接口 | 弹性布局容器，元服务 API 11+ |
| `FlexOptions.direction` | 参数 | `FlexDirection` 枚举：Row/RowReverse/Column/ColumnReverse，默认 Row |
| `FlexOptions.wrap` | 参数 | `FlexWrap` 枚举：NoWrap/Wrap/WrapReverse，默认 NoWrap |
| `FlexOptions.justifyContent` | 参数 | `FlexAlign` 枚举：Start/Center/End/SpaceBetween/SpaceAround/SpaceEvenly，默认 Start |
| `FlexOptions.alignItems` | 参数 | `ItemAlign` 枚举：Auto/Start/Center/End/Stretch/Baseline，默认 Start |
| `FlexOptions.alignContent` | 参数 | `FlexAlign` 枚举，仅在 wrap 为 Wrap/WrapReverse 时生效，默认 Start |
| `.flexBasis(value: number \| string)` | 子元素属性 | 主轴基准尺寸，默认 'auto' |
| `.flexGrow(value: number)` | 子元素属性 | 剩余空间分配比例，默认 0 |
| `.flexShrink(value: number)` | 子元素属性 | 空间不足时压缩比例，默认 1 |
| `.alignSelf(value: ItemAlign)` | 子元素属性 | 覆盖容器 alignItems 的交叉轴对齐 |

### 可用 API（元服务 API 12+）

| API | 类型 | 说明 |
|-----|------|------|
| `FlexOptions.space` | 参数 | `FlexSpaceOptions12+`，设置主轴/交叉轴间距，需搭配 `LengthMetrics` |

### 不适用/需注意

| 项目 | 说明 |
|------|------|
| 性能 | Flex 存在二次布局过程，性能敏感场景建议用 Column/Row 代替 |
| 主轴默认 | Flex 主轴不设长度时默认撑满父容器（与 Column/Row 默认跟随子节点不同） |
| 空容器 | Flex/Column/Row 无子节点且不设宽高时，默认宽高为 -1 |
| auto 宽度 | 主轴长度可设为 auto 使 Flex 自适应子组件布局，受 constraintSize 和父容器限制 |

## 各场景核心调用方式

### 1. 布局方向（direction）

```typescript
Flex({ direction: FlexDirection.Row }) { /* 子组件 */ }
// Row（默认）: 水平排列
// RowReverse: 水平反向
// Column: 垂直排列
// ColumnReverse: 垂直反向
```

### 2. 换行模式（wrap）

```typescript
Flex({ wrap: FlexWrap.Wrap }) { /* 子组件 */ }
// NoWrap（默认）: 不换行，超出时压缩
// Wrap: 换行
// WrapReverse: 反向换行
// alignContent 仅在 Wrap/WrapReverse 下生效
```

### 3. 主轴对齐（justifyContent）

```typescript
Flex({ justifyContent: FlexAlign.SpaceBetween }) { /* 子组件 */ }
// Start/Center/End: 首端/居中/尾端
// SpaceBetween: 两端对齐，中间等分
// SpaceAround: 两侧间距为中间间距一半
// SpaceEvenly: 所有间距完全相等
```

### 4. 交叉轴对齐（alignItems）

```typescript
Flex({ alignItems: ItemAlign.Center }) { /* 子组件 */ }
// Auto/Start/Center/End/Baseline: 对齐方式
// Stretch: 未设尺寸时拉伸到容器尺寸
// 子元素 alignSelf 可覆盖容器 alignItems
```

### 5. 多行对齐（alignContent）

```typescript
Flex({ wrap: FlexWrap.Wrap, alignContent: FlexAlign.Center }) { /* 子组件 */ }
// 仅在 wrap=Wrap/WrapReverse 时生效
// 枚举值同 justifyContent 的 FlexAlign
```

### 6. 自适应拉伸（flexGrow/flexShrink/flexBasis）

```typescript
// flexGrow: 剩余空间按比例分配
Text('grow').flexGrow(2) // 占剩余空间 2/(2+1)
Text('grow').flexGrow(1) // 占剩余空间 1/(2+1)

// flexShrink: 超出时按比例压缩
Text('shrink').flexShrink(0) // 不压缩
Text('shrink').flexShrink(3) // 按比例压缩

// flexBasis: 主轴基准尺寸，覆盖 width/height
Text('basis').flexBasis(100)  // 100vp
Text('basis').flexBasis('auto') // 使用组件原本大小
```

### 7. 子元素对齐覆盖（alignSelf）

```typescript
Flex({ alignItems: ItemAlign.Center }) {
  Text('default').width('25%').height(50) // 居中
  Text('override').alignSelf(ItemAlign.End).width('25%').height(50) // 尾部对齐
}
```

## 编译问题与解决

本次编译无新增错误，BUILD SUCCESSFUL。仅有已存在的 `getContext` deprecated 警告（与 Flex 无关）。

## 降级处理策略

- `FlexOptions.space`（API 12+）在元服务中需要 API 12+ 支持，低于此版本使用子元素 margin 模拟间距
- Flex 性能劣于 Column/Row，简单线性布局优先使用 Column/Row
- 使用 `width('auto')` + `constraintSize` 实现 Flex 自适应宽度
