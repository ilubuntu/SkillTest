# WaterFlow 组件开发经验

## 元服务 API 兼容性清单

### 可用 API

| API | 元服务版本 | 说明 |
|---|---|---|
| `WaterFlow(options?)` | API 11+ | 瀑布流容器 |
| `.columnsTemplate(string)` | API 11+ | 列模板 |
| `.rowsTemplate(string)` | API 11+ | 行模板 |
| `.columnsGap / .rowsGap` | API 11+ | 间距 |
| `.cachedCount(number)` | API 12+ | 缓存数量（单参数） |
| `WaterFlowSections` | API 12+ | 分段管理 |
| `WaterFlowLayoutMode` | API 12+ | ALWAYS_TOP_DOWN / SLIDING_WINDOW |
| `.onReachStart / .onReachEnd` | API 11+ | 滚动到头尾 |
| `.onScrollIndex` | API 11+ | 滚动索引 |

### 不可用 API

| API | 所需版本 | 说明 |
|---|---|---|
| `.columnsTemplate(ItemFillPolicy)` | API 22+ | 非字符串模板 |
| `.cachedCount(count, show)` | API 14+ | 带可见性的重载 |
| `.syncLoad(bool)` | API 20+ | 同步加载 |

## 核心调用方式

```typescript
WaterFlow() {
  ForEach(items, (item: number) => {
    FlowItem() { Text(`${item}`) }.height(动态高度)
  }, (item: number) => item.toString())
}.columnsTemplate('1fr 1fr').columnsGap(10).rowsGap(10)
```

## 降级策略

| 不可用 API | 降级方案 |
|---|---|
| columnsTemplate(ItemFillPolicy) | 使用字符串模板 "1fr 1fr" |
| cachedCount 两参数重载 | 使用单参数版本 |
