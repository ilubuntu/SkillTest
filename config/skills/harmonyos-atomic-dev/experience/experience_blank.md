# Blank 组件开发经验

## 元服务 API 兼容性清单

**全部可用 (API 11+)**，无不可用 API。

### 可用 API

| API | 元服务版本 | 说明 |
|---|---|---|
| `Blank(min?: number \| string)` | API 11+ | 空白填充，min 不支持百分比，负值/非法值默认 0 |
| `.color(ResourceColor)` | API 11+ | 填充颜色 |
| 通用属性/事件 | API 11+ | 全部支持 |

## 核心调用方式

```typescript
Row() {
  Text('左')
  Blank().color('#FFEAA7')  // 填充中间空白
  Text('右')
}
```

**注意：** 仅在 Row/Column/Flex 中生效；不支持子组件。
