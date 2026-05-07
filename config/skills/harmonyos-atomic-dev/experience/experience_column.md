# Column 组件开发经验（元服务）

## API 兼容性清单

### 构造函数

| API | 版本 | 元服务可用性 | 说明 |
|-----|------|-------------|------|
| `Column(options?: ColumnOptions)` | API 7+ | 元服务 API 11+ | `space` 参数仅支持 `number \| string` |
| `Column(options?: ColumnOptions \| ColumnOptionsV2)` | API 18+ | 元服务 API 18+ | `space` 额外支持 `Resource` 类型 |

### 属性

| 属性 | 版本 | 元服务可用性 | 说明 |
|------|------|-------------|------|
| `.alignItems(HorizontalAlign)` | API 7+ | 元服务 API 11+ | 水平对齐，默认 `Center` |
| `.justifyContent(FlexAlign)` | API 8+ | 元服务 API 11+ | 垂直排列，默认 `Start` |
| `.reverse(Optional<boolean>)` | API 12+ | 元服务 API 12+ | 反转子元素排列，默认 `true`（反转） |

### 对齐枚举值

**HorizontalAlign**（Column 交叉轴）：
- `Start` — 左对齐
- `Center` — 居中（默认值）
- `End` — 右对齐

**FlexAlign**（Column 主轴）：
- `Start` — 顶部对齐（默认值）
- `Center` — 垂直居中
- `End` — 底部对齐
- `SpaceBetween` — 两端对齐，中间均分
- `SpaceAround` — 等间距环绕
- `SpaceEvenly` — 完全均分（含两端）

### 通用属性与事件

- 通用属性（width、height、padding、margin、backgroundColor、border 等）全部可用
- 通用事件（onClick、onTouch、onAppear 等）全部可用
- `Blank` 组件、`layoutWeight` 属性在 Column 内嵌套场景正常可用

## 各场景核心调用方式

### 1. 子元素间距 (space)

```typescript
Column({ space: 20 }) {
  Text('Item 1')
  Text('Item 2')
  Text('Item 3')
}
```

- `space` 为负数时按默认值 0 处理
- `justifyContent` 设为 `SpaceBetween`/`SpaceAround`/`SpaceEvenly` 时，`space` 不生效
- 动态修改 `space` 值可实现交互式间距调节

### 2. 水平对齐 (alignItems)

```typescript
Column() { ... }
  .alignItems(HorizontalAlign.Start)  // 左对齐
  .alignItems(HorizontalAlign.Center) // 居中（默认）
  .alignItems(HorizontalAlign.End)    // 右对齐
```

- 控制子元素在水平方向（交叉轴）的对齐方式
- 子元素宽度不一致时效果最明显

### 3. 垂直排列 (justifyContent)

```typescript
Column() { ... }
  .height(300)  // 必须设置固定高度
  .justifyContent(FlexAlign.Center)
```

- **Column 未设置高度时自适应子组件**，此时 `Center` 和 `End` 会失效
- 子组件未设 `flexShrink` 时默认不压缩，主轴总和可超过容器

### 4. 反转排列 (reverse)

```typescript
Column() { ... }
  .reverse(true)  // 反转排列
```

- 需要 API 12+
- 未设置 `reverse` 时主轴不反转；设为 `undefined` 视为 `true`
- `direction` 属性只改变交叉轴方向，与 `reverse` 互不影响

### 5. 嵌套布局

```typescript
Column() {
  Row() {
    Text('标题')
    Blank()         // 自适应填充空白
    Text('更多')
  }
  Row() {
    Column().layoutWeight(1)  // 权重分配
    Column().layoutWeight(2)
  }
}
```

- Column + Row 组合是 HarmonyOS 最常用的布局模式
- `Blank` 组件实现自适应拉伸
- `layoutWeight` 按权重分配剩余空间

## 编译过程

本次开发编译一次通过，无新增错误。已有项目中的 `getContext` 弃用警告与 Column 组件无关。

## 降级处理策略

| 场景 | 策略 |
|------|------|
| `ColumnOptionsV2`（API 18+）不可用 | 使用 `ColumnOptions` 的 `number` 类型 `space` 代替 `string`/`Resource` 类型 |
| `reverse`（API 12+）不可用 | 手动反转数据数组顺序实现相同视觉效果 |
| `justifyContent` 的 `Center`/`End` 不生效 | 确保为 Column 设置固定高度 |
