# Divider 分隔线开发经验

## 可用 API 清单（元服务兼容性）

### 完全可用

| API | 元服务起始版本 | 说明 |
|-----|--------------|------|
| `Divider()` | API 7+ | 创建分隔线组件 |
| `.vertical(boolean)` | API 7+ | 是否垂直方向，默认 false（水平） |
| `.color(ResourceColor)` | API 7+ | 分隔线颜色，默认 #3C3C3C |
| `.strokeWidth(Length)` | API 7+ | 分隔线粗细，默认 1vp |
| `.lineCap(LineCapStyle)` | API 9+ | 端点样式：Butt / Round / Square |

通用属性：width / height / margin / padding / opacity / visibility / backgroundColor / border / borderRadius 等均可用。

### 不支持

| 能力 | 说明 |
|------|------|
| 事件 | Divider 不支持 onClick / onTouch 等任何事件，仅为视觉分隔组件 |

## 各场景核心调用方式

### 1. 基础水平分隔线

```typescript
Column() {
  Text('上方内容')
  Divider()
  Text('下方内容')
}
```

**注意**：水平 Divider 默认宽度撑满父容器，高度由 strokeWidth 决定。

### 2. 垂直分隔线

```typescript
Row() {
  Text('左侧')
  Divider()
    .vertical(true)
    .height(40)
  Text('右侧')
}
```

**关键**：垂直 Divider **必须手动设置 `.height()`**，否则高度为 0 不可见。

### 3. 自定义颜色和粗细

```typescript
Divider()
  .color('#FA2A2D')
  .strokeWidth(2)
```

### 4. 端点样式

```typescript
Divider()
  .strokeWidth(4)
  .lineCap(LineCapStyle.Round)
```

- `Butt` — 默认，平行端点
- `Round` — 两端半圆，额外增加一个线宽长度
- `Square` — 两端半方，额外增加一个线宽长度

### 5. 带缩进的分隔线

```typescript
Divider()
  .color('#E0E0E0')
  .margin({ left: 24, right: 24 })
```

### 6. 列表项分隔

```typescript
Column() {
  // 列表项
  Row() { Text('设置项') }.width('100%').padding(12)
  Divider().color('#F0F0F0').strokeWidth(0.5)
  Row() { Text('设置项') }.width('100%').padding(12)
}
```

## 编译过程中遇到的问题和解决方案

Divider 组件 API 简洁，编译过程无特殊问题。

## 降级处理策略

Divider 组件在元服务中完全可用（API 7+），无需降级。如需更丰富的分隔效果，可使用：
- Row/Column + backgroundColor 模拟自定义分隔线
- Border 属性在列表项间实现分隔
- Canvas 绘制复杂分隔图案
