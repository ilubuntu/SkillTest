# Toggle 组件开发经验

## 元服务 API 兼容性清单

### 可用 API

| 组件 / API | 元服务起始版本 | 说明 |
|---|---|---|
| `Toggle(options: ToggleOptions)` | API 11+ | 主接口，卡片 API 9+ |
| `ToggleType.Checkbox` | API 11+ | 勾选框样式，默认 20x20vp，API 11 起为圆形 |
| `ToggleType.Switch` | API 11+ | 开关样式，默认 36x20vp |
| `ToggleType.Button` | API 11+ | 状态按钮样式，默认高度 28vp，可含子组件 |
| `ToggleOptions.isOn` | API 11+ | 开关状态，默认 false，支持 `$$` 和 `!!` 双向绑定 |
| `.selectedColor(color)` | API 11+ | 选中状态背景色 |
| `.switchPointColor(color)` | API 11+ | Switch 滑块颜色，仅 Switch 类型生效 |
| `.onChange((isOn) => void)` | API 11+ | 状态切换回调 |
| `.switchStyle(SwitchStyle)` | API 12+ | Switch 高级样式自定义 |
| `SwitchStyle.pointRadius` | API 12+ | 滑块半径 (vp)，不支持百分比 |
| `SwitchStyle.unselectedColor` | API 12+ | 关闭状态背景色，默认 0x337F7F7F |
| `SwitchStyle.pointColor` | API 12+ | 滑块颜色 |
| `SwitchStyle.trackBorderRadius` | API 12+ | 滑轨圆角 (vp)，不支持百分比 |
| `.contentModifier(modifier)` | API 12+ | 自定义内容区，需实现 ContentModifier<ToggleConfiguration> |

### 不可用 / 受限 API

| API | 状态 | 说明 |
|---|---|---|
| `ToggleOptions` 规范化对象 | API 18+ | 仅对象定义规范化，内部属性从 API 8+ 即支持，不影响使用 |
| `SwitchStyle.unselectedColor` 默认值优化 | API 20+ | 深浅色模式默认值优化，API 12-19 使用固定 0x337F7F7F |

---

## 各场景核心调用方式

### 1. Checkbox 勾选框

```typescript
Toggle({ type: ToggleType.Checkbox, isOn: this.isChecked })
  .selectedColor('#007DFF')
  .onChange((isOn: boolean) => {
    this.isChecked = isOn
  })
```

**注意：** API 11 起默认由圆角方形变为圆形；默认 margin 各方向 14px。

### 2. Switch 开关

```typescript
Toggle({ type: ToggleType.Switch, isOn: this.isOn })
  .selectedColor('#00B578')
  .switchPointColor('#FFFFFF')
  .onChange((isOn: boolean) => {
    this.isOn = isOn
  })
```

**注意：** 默认 margin 上下 6px，左右 14px。`switchPointColor` 仅对 Switch 类型生效。

### 3. Button 状态按钮

```typescript
Toggle({ type: ToggleType.Button, isOn: this.buttonOn }) {
  Text(this.buttonOn ? '已启用' : '已禁用')
    .fontSize(14)
    .fontColor('#FFFFFF')
}
.selectedColor('#007DFF')
.onChange((isOn: boolean) => {
  this.buttonOn = isOn
})
```

**注意：** 仅 Button 类型支持子组件；默认高度 28vp，宽度无默认值。

### 4. SwitchStyle 高级自定义 (API 12+)

```typescript
Toggle({ type: ToggleType.Switch, isOn: true })
  .switchStyle({
    pointRadius: 8,
    unselectedColor: '#E0E0E0',
    pointColor: '#FFFFFF',
    trackBorderRadius: 12
  })
  .selectedColor('#007DFF')
```

**关键计算：**
- `pointRadius` 默认算法：`(height/2) - (2 * height/20)`
- `trackBorderRadius` 默认算法：`height / 2`
- `pointRadius`: <0 按默认，>=0 按设定
- `trackBorderRadius`: <0 按默认，>height/2 按 height/2，其余按设定

---

## 降级处理策略

| 不可用 API | 降级方案 |
|---|---|
| `contentModifier` (API 12+) | 使用 `ToggleType.Button` + 自定义子组件实现类似视觉效果 |
| `switchStyle` (API 12+) | 使用 `.selectedColor()` 和 `.switchPointColor()` 做基本颜色自定义 |
