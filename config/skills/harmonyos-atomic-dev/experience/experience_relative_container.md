# experience_relative_container — RelativeContainer 开发经验

## 可用/不可用 API 清单（元服务兼容性）

| API | 最低版本 | 元服务可用 |
|-----|---------|-----------|
| `RelativeContainer()` | API 9 | ✅ API 11+ |
| `.alignRules()` | API 9 | ✅ API 11+ |
| `.id()` | API 9 | ✅ API 11+ |
| `.bias()` | API 9 | ⚠️ SDK 可能不支持，编译报错 |
| `.guideLine()` | API 12 | ✅ API 12+ |
| `.barrier()` | API 12 | ✅ API 12+ |
| `chainMode()` | API 12 | ✅ API 12+ |
| `chainWeight()` | API 14 | ✅ API 14+ |
| `LayoutPolicy` | API 20 | ❌ 低版本不可用 |

## 各场景核心调用方式

### 1. 基础容器锚定
- 锚点使用 `__container__` 字符串表示容器自身
- 水平对齐: `HorizontalAlign.Start / Center / End`
- 垂直对齐: `VerticalAlign.Top / Center / Bottom`
- 每个子组件必须设置 `.id()` 供兄弟组件引用

### 2. 兄弟组件锚定
- 锚点值改为兄弟组件的 id 字符串
- 支持链式依赖（A→B→C）
- 禁止循环依赖（A→B→A 会导致布局异常）

### 3. guideLine 辅助线 (API 12+)
```typescript
.guideLine([
  { id: 'vLine', direction: Axis.Vertical, position: { start: '50%' } },
  { id: 'hLine', direction: Axis.Horizontal, position: { start: '30%' } }
])
```
- 子组件可通过辅助线 id 作为锚点
- 容器尺寸为 auto 时，position 只能用 start 方式

### 4. barrier 屏障 (API 12+)
```typescript
.barrier([
  { id: 'rightBarrier', direction: BarrierDirection.RIGHT, referencedId: ['compA', 'compB'] }
])
```
- 自动计算一组组件的最大边界
- 方向: `BarrierDirection.LEFT / RIGHT / TOP / BOTTOM`

### 5. 居中与偏移
- 设置双方向锚点（top+bottom / left+right）→ 组件在锚点间居中
- 设置单方向锚点 → 组件靠近已设置锚点
- `.bias()` 在当前 SDK 编译报错，需用 alignRules 组合替代

## 编译问题与解决方案

### 问题 1: `.bias()` 编译报错
- **错误**: `Property 'bias' does not exist on type 'RowAttribute'`
- **原因**: `.bias()` 可能在当前 SDK 版本中类型定义缺失或需要更高 API 版本
- **解决**: 使用双方向 alignRules（top+bottom / left+right）实现居中效果，替代 bias

### 问题 2: guideLine 百分比位置
- **注意**: position 使用字符串百分比需要引号包裹，如 `start: '50%'`
- 容器 auto 模式下只能用 start 定位

## 降级处理策略

1. **LayoutPolicy 不可用**: 使用固定尺寸或 `width/height: "auto"`
2. **bias 不可用**: 用双方向锚点 + offset 微调替代
3. **chainMode 不可用**: 用多个 RelativeContainer 嵌套或改用 Flex/Column 布局
