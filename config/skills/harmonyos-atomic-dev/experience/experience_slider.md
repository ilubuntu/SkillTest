# Slider 组件开发经验

## 元服务 API 兼容性清单

### 可用 API（元服务 API 7+）

| API | 说明 | 参数类型 |
|-----|------|---------|
| `Slider(options)` | 构造函数 | `{ value?, min?, max?, step?, style?, direction?, reverse? }` |
| `value` | 当前值 | `number`，默认 0 |
| `min` | 最小值 | `number`，默认 0 |
| `max` | 最大值 | `number`，默认 100 |
| `step` | 步长 | `number`，默认 0（连续） |
| `style` | 滑块样式 | `SliderStyle.OutSet / InSet / NONE` |
| `direction` | 方向 | `Axis.Horizontal / Axis.Vertical` |
| `reverse` | 是否反转 | `boolean` |
| `.blockColor(color)` | 滑块颜色 | `ResourceColor` |
| `.trackColor(color)` | 轨道背景色 | `ResourceColor` |
| `.selectedColor(color)` | 已选轨道颜色 | `ResourceColor` |
| `.trackThickness(number)` | 轨道厚度 | `number` (vp) |
| `.blockSize({ width, height })` | 滑块尺寸 | `SizeOptions` |
| `.blockBorderColor(color)` | 滑块边框颜色 | `ResourceColor` |
| `.blockBorderWidth(number)` | 滑块边框宽度 | `number` |
| `.trackBorderRadius(number)` | 轨道圆角 | `number` |
| `.showSteps(boolean)` | 显示步长刻度 | 配合 step 使用 |
| `.showTips(boolean)` | 显示气泡提示 | 滑动时在滑块上方显示当前值 |
| `.stepColor(color)` | 刻度线颜色 | `ResourceColor` |
| `.onChange(callback)` | 值变更回调 | `(value: number, mode: SliderChangeMode) => void` |

### 不可用 / 受限 API

| API | 限制说明 | 降级方案 |
|-----|---------|---------|
| `ArcSlider` | 穿戴设备专用，API 18+，需 `@kit.ArkUI` 导入 | 手机端使用标准 Slider 自定义外观 |
| 双滑块范围选择 | Slider 不支持双滑块 | 两个独立 Slider 分别控制最小/最大值 |
| `enableAnimate` | 不支持精细动画控制 | 使用 `animateTo` 在 onChange 中自行驱动 |
| 自定义手势组合 | Slider 内部已处理手势，不建议叠加 GestureGroup | 使用 Row + Progress 自行实现 |

## SliderChangeMode 枚举

`onChange` 回调的第二个参数 `mode` 用于区分触发方式：

| 枚举值 | 数值 | 说明 |
|--------|------|------|
| `SliderChangeMode.Begin` | 0 | 用户开始滑动 |
| `SliderChangeMode.Moving` | 1 | 用户正在滑动 |
| `SliderChangeMode.End` | 2 | 用户结束滑动 |
| `SliderChangeMode.Click` | 3 | 用户点击轨道 |

典型用法 — 区分拖拽提交和点击：
```typescript
.onChange((value: number, mode: SliderChangeMode) => {
  if (mode === SliderChangeMode.End) {
    // 用户松手后才提交值
    this.submitValue = Math.round(value)
  }
})
```

## SliderStyle 三种样式

| 样式 | 效果 | 典型用途 |
|------|------|---------|
| `OutSet`（默认） | 滑块在轨道上方，滑块中心与滑轨端点对齐 | 通用场景 |
| `InSet` | 滑块嵌入轨道内，滑块与滑轨中心对齐 | 亮度/音量调节 |
| `NONE` | 无滑块，仅进度轨道 | 纯进度指示 |

注意：枚举值为全大写 `NONE`，而非 `None`。

## 垂直方向与反转

Slider 原生支持垂直方向和反转，无需 rotate hack：

- `direction: Axis.Vertical`：垂直显示，需设置 `.height()` 而非 `.width()`
- `reverse: true`：水平时从右向左，垂直时从下向上
- 两者可组合使用

```typescript
Slider({
  value: 50,
  min: 0,
  max: 100,
  direction: Axis.Vertical,
  reverse: true
}).height(200)
```

## onChange 返回浮点数

onChange 回调的 value 参数为浮点数，即使设置了 step。需用 `Math.round(value)` 取整：

```typescript
.onChange((value: number) => {
  this.currentValue = Math.round(value)
})
```

## 编译注意事项

- Slider 为 ArkUI 内置组件，无需额外 import
- `BusinessError` 类型通过 `(err as BusinessError).message` 使用，无需显式 import
- `SliderStyle.NONE` 全大写，不能用 `SliderStyle.None`
- 编译通过，无 warning 产生