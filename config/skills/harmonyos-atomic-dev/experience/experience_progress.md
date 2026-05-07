# Progress 组件开发经验

## 元服务 API 兼容性

### 可用 API（API 11+ 元服务支持）

| API | 说明 | 起始版本 |
|-----|------|----------|
| `Progress(options: ProgressOptions)` | 创建进度条 | API 7 (元服务 API 11) |
| `ProgressType.Linear` (= 0) | 线性样式 | API 8 (元服务 API 11) |
| `ProgressType.Ring` (= 1) | 环形无刻度样式 | API 8 (元服务 API 11) |
| `ProgressType.Eclipse` (= 2) | 月食形样式 | API 8 (元服务 API 11) |
| `ProgressType.ScaleRing` (= 3) | 环形有刻度样式 | API 8 (元服务 API 11) |
| `ProgressType.Capsule` (= 4) | 胶囊样式 | API 8 (元服务 API 11) |
| `.value(value: number)` | 动态更新进度值 | API 7 (元服务 API 11) |
| `.color(value: ResourceColor \| LinearGradient)` | 前景色 | API 7 (元服务 API 11) |
| `.backgroundColor(value: ResourceColor)` | 背景色（重写通用属性） | API 7 (元服务 API 11) |
| `.style(value: ProgressStyleOptions)` | 样式选项 | API 8 (元服务 API 11) |
| `.style(value: RingStyleOptions)` | 环形样式（含 shadow, status） | API 10 (元服务 API 11) |
| `.style(value: LinearStyleOptions)` | 线性样式（含 strokeRadius） | API 10 (元服务 API 11) |
| `.style(value: CapsuleStyleOptions)` | 胶囊样式（含 content, font） | API 10 (元服务 API 11) |
| `.style(value: ScaleRingStyleOptions)` | 刻度环形样式 | API 10 (元服务 API 11) |
| `.style(value: EclipseStyleOptions)` | 月食样式 | API 10 (元服务 API 11) |
| `.privacySensitive(boolean)` | 隐私敏感模式 | API 12 (元服务 API 12) |
| `.contentModifier(modifier)` | 自定义内容区 | API 12 (元服务 API 12) |
| `enableSmoothEffect` | 进度平滑过渡动效 | API 10 (元服务 API 11) |
| `enableScanEffect` | 扫光效果（Linear/Ring/Capsule） | API 10 (元服务 API 11) |

### 不可用/不存在的能力

| 能力 | 说明 |
|------|------|
| `.onChange()` 事件 | Progress 无交互事件回调，是纯展示组件 |
| ProgressController | 不提供控制器对象 |
| 动画驱动 | 不支持 animateTo / animation |
| `.style()` 的 `borderRadius` | Capsule 类型圆角半径，API 18+，需要验证元服务支持 |

## 各场景核心调用方式

### 1. 基础创建

```typescript
// 默认线性
Progress({ value: 50, total: 100 })

// 指定类型
Progress({ value: 50, total: 100, type: ProgressType.Ring })
```

### 2. 样式自定义

```typescript
// Ring: strokeWidth 控制环形宽度
Progress({ value: 60, total: 100, type: ProgressType.Ring })
  .color('#007DFF')
  .style({ strokeWidth: 12 })

// ScaleRing: scaleCount + scaleWidth 控制刻度
Progress({ value: 60, total: 100, type: ProgressType.ScaleRing })
  .style({ strokeWidth: 8, scaleCount: 20, scaleWidth: 3 })

// Capsule: 自定义文本和颜色
Progress({ value: 60, total: 100, type: ProgressType.Capsule })
  .style({ content: '加载中', fontColor: '#FFFFFF', showDefaultPercentage: true })
```

### 3. 动态进度更新

```typescript
@Local progressValue: number = 0

// 通过 @Local 绑定实现动态更新
Progress({ value: this.progressValue, total: 100, type: ProgressType.Linear })

// 按钮驱动进度变化
Button('+10').onClick(() => {
  this.progressValue = Math.min(100, this.progressValue + 10)
})
```

### 4. 自适应方向

- Linear: height > width 时自动垂直显示
- Capsule: height > width 时自动垂直显示

## 编译问题与解决方案

### 问题 1: struct 命名冲突导致 ProgressType 枚举不可用

**错误信息**: `Property 'Linear' does not exist on type 'typeof ProgressType'`

**原因**: demo 文件中的 `export struct ProgressType` 与 ArkUI 全局枚举 `ProgressType` 同名，导致 struct 遮蔽了枚举。编译器在 struct 内部解析 `ProgressType.Linear` 时，将 `ProgressType` 解析为 struct 自身而非全局枚举。

**解决方案**: 避免使用与 ArkUI 全局类型同名的 struct。将 `ProgressType` 重命名为 `ProgressAllType`，将 `ProgressStyle` 重命名为 `ProgressStyleCustom`。

**教训**: 在 ArkTS 中，struct/类名不应与 ArkUI 内置的枚举/接口同名（如 ProgressType、ProgressStyle、SliderStyle、ButtonType 等），否则会造成命名遮蔽。

### 问题 2: backgroundColor 行为差异

Progress 组件重写了通用属性 `backgroundColor`。直接添加在 Progress 上设置的是进度条底色，而非组件背景色。如需设置整个 Progress 组件的背景色，需在外层容器上添加 backgroundColor。

## 降级处理策略

Progress 组件在元服务中无 API 级限制（API 11+ 全部可用），无需降级处理。主要限制来自组件设计本身：

- **无交互事件**: 需要外部按钮 + 状态变量手动控制进度
- **无动画 API**: 可通过 setInterval 小步长更新模拟平滑过渡
- **无控制器**: 无法通过代码精确控制动画启停
