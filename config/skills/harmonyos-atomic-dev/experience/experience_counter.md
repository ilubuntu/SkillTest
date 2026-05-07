# Counter 组件开发经验

## 元服务 API 兼容性清单

**全部可用 (API 11+)**，无不可用 API。

### 可用 API

| API | 元服务版本 | 说明 |
|---|---|---|
| `Counter()` | API 11+ | 计数器容器，包含子组件 |
| `.enableInc(bool)` | API 11+ | 启用增加按钮 |
| `.enableDec(bool)` | API 11+ | 启用减少按钮 |
| `.onInc(() => void)` | API 11+ | 增加回调 |
| `.onDec(() => void)` | API 11+ | 减少回调 |

## 核心调用方式

```typescript
Counter() {
  Text(`${this.count}`).fontSize(24)
}.enableInc(this.count < 10)
  .enableDec(this.count > 0)
  .onInc(() => { this.count++ })
  .onDec(() => { this.count-- })
```

Counter 是轻量级组件（API 7+），逻辑完全在 onInc/onDec 回调中处理。
