# Curves 动画曲线开发经验

## 元服务 API 兼容性清单

### 可用 API

| API | 说明 |
|---|---|
| `Curve` 枚举预设 | Linear / Ease / EaseIn / EaseOut / EaseInOut / FastOutSlowIn / LinearOutSlowIn / FastOutLinearIn / Spring |
| `curves.springCurve(velocity, mass, stiffness, damping)` | 弹簧曲线 |
| `curves.springMotion(mass, stiffness, damping)` | 弹簧运动 |
| `curves.responsiveSpringMotion(mass, stiffness, damping)` | 响应式弹簧运动 |

需要 `import { curves } from '@kit.ArkUI'`

### 不可用 API

| API | 状态 | 说明 |
|---|---|---|
| `curves.cubicBezier(x1, y1, x2, y2)` | 不支持元服务 | 编译报错 "can't support atomicservice application" |
| `curves.linear()` / `curves.ease()` 等 | 不存在 | 预设曲线应使用 `Curve` 枚举，不是 `curves` 工厂 |

## 核心调用方式

```typescript
// Curve 枚举（预设曲线，直接使用）
animateTo({ curve: Curve.EaseInOut }, () => { ... })
animateTo({ curve: Curve.Linear }, () => { ... })

// curves 工厂（弹簧曲线）
import { curves } from '@kit.ArkUI'
animateTo({ curve: curves.springMotion(0.555, 0, 0) }, () => { ... })
animateTo({ curve: curves.springCurve(1, 1, 1, 1) }, () => { ... })
```

## 编译问题

1. 命名空间是 `curves`（小写），不是 `Curves`。导入：`import { curves } from '@kit.ArkUI'`
2. `curves.cubicBezier` 编译报错 "can't support atomicservice application"
3. `curves.linear()` 等方法不存在 — 预设曲线用 `Curve` 枚举

## 降级策略

| 不可用 API | 降级方案 |
|---|---|
| `curves.cubicBezier` | 使用 `Curve.EaseInOut` / `Curve.FastOutSlowIn` 等预设枚举替代 |
