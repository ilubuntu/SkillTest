# DataPanel 组件开发经验

## 元服务 API 兼容性清单

### 可用 API

| API | 元服务版本 | 说明 |
|---|---|---|
| `DataPanel({ values, max, type })` | API 11+ | 数据面板 |
| `DataPanelType.Line / Circle` | API 11+ | 线性/环形 |
| `.valueColors(Array<ResourceColor>)` | API 11+ | 颜色数组，不支持嵌套数组 |
| `.trackBackgroundColor(ResourceColor)` | API 11+ | 轨道背景色 |
| `.strokeWidth(Length)` | API 11+ | 线宽（仅 Circle） |
| `.closeEffect(bool)` | API 11+ | 关闭加载动画 |
| `.trackShadow(DataPanelShadowOptions)` | API 11+ | 阴影 |

### 不可用 API

| API | 所需版本 |
|---|---|
| `.contentModifier` | API 12+ |

## 核心调用方式

```typescript
DataPanel({ values: [20, 40, 30], max: 100, type: DataPanelType.Circle })
  .valueColors(['#007DFF', '#FF6B00', '#00B578'])  // 颜色字符串数组
  .trackBackgroundColor('#E0E0E0')
  .strokeWidth(16)
```

## 编译问题

`.valueColors()` 参数类型是 `Array<ResourceColor | LinearGradient>`，不是嵌套数组。不能用 `[['#007DFF']]`，应直接用 `['#007DFF']`。
