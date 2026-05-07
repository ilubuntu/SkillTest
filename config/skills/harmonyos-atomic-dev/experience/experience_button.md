# Button 组件开发经验

## 元服务 API 兼容性清单

### 可用 API

| 组件 / API | 元服务起始版本 | 说明 |
|---|---|---|
| `Button` (基础按钮) | 基础组件，始终可用 | Capsule / Circle / Normal 三种类型 |
| `Button.type` | 基础组件 | `ButtonType.Capsule` / `ButtonType.Circle` / `ButtonType.Normal` |
| `Button.stateEffect` | 基础组件 | 控制按压效果 |
| `Button.onClick()` | 基础组件 | 点击事件 |
| `Button` 子组件形式 | 基础组件 | `Button({ type, stateEffect }) { 子组件 }` |
| `.borderRadius()` | 通用属性 | Capsule/Circle 类型不可修改 |
| `.fontSize()` / `.fontColor()` / `.fontWeight()` | 通用属性 | 文本样式 |
| `.backgroundColor()` | 通用属性 | 背景颜色 |
| `.enabled()` | 通用属性 | 控制是否可交互 |
| `SegmentButton` | API 12 | 页签类 / 胶囊类（单选/多选） |
| `ProgressButton` | API 11 | 带进度的下载按钮 |
| `SaveButton` | API 11 | 安全保存控件 |
| `FunctionalButton` | 4.1.0(11) | 场景化按钮（手机号验证、设置、头像选择等） |

### 不可用 / 当前 SDK 不可用的 API

| API | 状态 | 替代方案 |
|---|---|---|
| `ButtonType.ROUNDED_RECTANGLE` | 当前 SDK 未导出 | 使用 `ButtonType.Normal` + `.borderRadius(20)` 模拟 |
| `FunctionalButton OpenType.GET_RISK_LEVEL` | 当前 SDK 未导出 | 等待更高版本 ScenarioFusionKit |
| `functionalButtonComponentManager.GetRiskLevelResult` | 当前 SDK 未导出 | 同上 |
| `OpenSettingResult.authSetting` | 当前 SDK 无此属性 | 直接 `JSON.stringify(data)` 打印完整结果 |
| `ArcButton` | API 18+, 仅穿戴设备 | 非元服务典型场景 |

---

## 各场景核心调用方式

### 1. 基础 Button 类型

```typescript
// 胶囊（默认）
Button('Capsule', { type: ButtonType.Capsule, stateEffect: true })

// 圆形
Button('A', { type: ButtonType.Circle, stateEffect: true })
  .width(60).height(60)

// 普通（可自定义圆角）
Button('Normal', { type: ButtonType.Normal, stateEffect: true })
  .borderRadius(8)
```

**注意事项：**
- struct 命名不能与 `ButtonType` 枚举同名，否则类型引用冲突
- Capsule 圆角自动为高度一半，不可通过 borderRadius 修改
- Circle 不可通过 borderRadius 修改

### 2. Button 样式自定义

```typescript
Button('styled', { type: ButtonType.Normal })
  .borderRadius(20)
  .fontSize(20)
  .fontColor(Color.Pink)
  .fontWeight(800)
  .backgroundColor(0xF55A42)
  .stateEffect(true)
```

### 3. Button 子组件（容器模式）

```typescript
Button({ type: ButtonType.Normal, stateEffect: true }) {
  Row({ space: 8 }) {
    Text('📁').fontSize(18)
    Text('打开文件').fontSize(14).fontColor(Color.White)
  }.alignItems(VerticalAlign.Center)
}
.borderRadius(8)
```

**注意：** 只支持包含一个子组件。

### 4. SegmentButton 分段按钮

```typescript
import { SegmentButton, SegmentButtonOptions } from '@kit.ArkUI'

// 必须用 @State 装饰 options（因 SegmentButton.options 为 @ObjectLink）
@State tabOptions: SegmentButtonOptions = SegmentButtonOptions.tab({
  buttons: [{ text: '页签1' }, { text: '页签2' }] as ItemRestriction<SegmentButtonTextItem>,
})

SegmentButton({ options: this.tabOptions, selectedIndexes: this.tabSelectedIndexes })
```

**关键经验：**
- `SegmentButton` 是 V1 `@Component`，`selectedIndexes` 用 `@Link` 装饰
- **不能在 `@ComponentV2` 中直接使用**，会报 "A V2 component cannot be used with any member property decorated by '@Link'"
- **解决方案：** 包含 SegmentButton 的 demo 整体使用 V1 `@Component` + `@State`
- `options` 必须用 `@State` 装饰（非 `private`），因为 `@ObjectLink` 要求源为状态变量
- buttons 数组支持 2~5 个元素
- `onItemClicked` 回调从 API 13 开始支持

### 5. ProgressButton 进度按钮

```typescript
import { ProgressButton } from '@kit.ArkUI'

ProgressButton({
  progress: this.progressIndex,   // [0, 100]
  content: this.textState,         // 按钮文本
  progressButtonWidth: 200,        // >= 44vp
  enable: this.enableState,        // 是否可点击
  clickCallback: () => { ... },
})
```

**注意：** 不支持通用属性和通用事件。

### 6. SaveButton 安全保存控件

```typescript
SaveButton({
  icon: SaveIconStyle.FULL_FILLED,
  text: SaveDescription.SAVE,
  buttonType: ButtonType.Capsule
})
.onClick((event: ClickEvent, result: SaveButtonOnClickResult, error?: BusinessError) => {
  if (result === SaveButtonOnClickResult.SUCCESS) {
    // 授权成功，可访问媒体库
  }
})
```

**关键经验：**
- 授权持续时间：API 19 及之前 10 秒，API 20+ 为 1 分钟
- 不支持通用属性，仅继承安全控件通用属性
- `icon` / `text` / `buttonType` 不支持动态修改
- 背景色 alpha 低于 0x1a 会被系统强制调整为 0xff

### 7. FunctionalButton 场景化按钮

```typescript
import { FunctionalButton, functionalButtonComponentManager } from '@kit.ScenarioFusionKit'

FunctionalButton({
  params: {
    openType: functionalButtonComponentManager.OpenType.GET_PHONE_NUMBER,
    label: '快速验证手机号',
    styleOption: {
      bgColor: functionalButtonComponentManager.ColorType.DEFAULT,
      size: functionalButtonComponentManager.SizeType.DEFAULT,
      plain: false,
      disabled: false,
      loading: false,
    },
  },
  controller: new functionalButtonComponentManager.FunctionalButtonController()
    .onGetPhoneNumber((err, data) => {
      // data.code 为授权码
    })
})
```

**关键经验：**
- `controller` 的回调方法必须与 `openType` 匹配
- 当前 SDK 可用 OpenType：`GET_PHONE_NUMBER`、`OPEN_SETTING`、`CHOOSE_AVATAR`、`LAUNCH_APP` 等
- 当前 SDK 不可用：`GET_RISK_LEVEL`（枚举未导出）

---