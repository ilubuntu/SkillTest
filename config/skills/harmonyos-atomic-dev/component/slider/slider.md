# Slider 组件 HarmonyOS 6.0 开发 Skill

## 概述

Slider 组件是 OpenHarmony 中的滑动选择器组件，用于在指定的范围内选择一个数值。用户可以通过拖动滑块在最小值和最大值之间进行选择，常用于音量调节、亮度调节、进度控制等场景。

## 重要说明

- **基础组件**: Slider 是 ArkUI 的基础内置组件，无需导入
- **数值范围**: 支持自定义最小值和最大值
- **步长设置**: 支持设置滑动步长，实现离散值选择
- **方向支持**: 支持水平和垂直两个方向
- **样式自定义**: 支持自定义滑块颜色、轨道颜色等样式

## 模块信息

- **组件名称**: Slider
- **SDK 版本**: HarmonyOS 6.0 (API 12+)
- **系统能力**: SystemCapability.ArkUI.ArkUI.Full
- **更新日期**: 2026-02-24
- **官方文档**:
  - [Slider 滑动条 - 华为开发者](https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V5/ts-basic-components-slider-V5)

## 一、组件基础

### 1.1 导入方式

```typescript
// Slider 是内置组件，无需导入
// 直接使用即可
Slider({ value: 50, min: 0, max: 100 })
```

### 1.2 基础用法

```typescript
// 基础滑动条
Slider({ value: 50, min: 0, max: 100 })
  .onChange((value: number) => {
    console.info('Slider value: ' + value)
  })

// 设置步长
Slider({ value: 25, min: 0, max: 100, step: 25 })

// 垂直滑动条
Slider({ value: 50, min: 0, max: 100 })
  .direction(Axis.Vertical)
```

## 二、API 参数

### 2.1 构造参数

| 参数 | 类型 | 必填 | 默认值 | 描述 |
|------|------|------|--------|------|
| value | `number` | 是 | - | 当前值 |
| min | `number` | 否 | 0 | 最小值 |
| max | `number` | 否 | 100 | 最大值 |
| step | `number` | 否 | 1 | 步长 |
| style | `SliderStyle` | 否 | SliderStyle.OutSet | 滑块样式 |
| direction | `Axis` | 否 | Axis.Horizontal | 滑动方向 |

### 2.2 SliderStyle 枚举

| 值 | 描述 |
|----|------|
| `SliderStyle.OutSet` | 滑块在轨道外 |
| `SliderStyle.InSet` | 滑块在轨道内 |

### 2.3 Axis 枚举

| 值 | 描述 |
|----|------|
| `Axis.Horizontal` | 水平方向 |
| `Axis.Vertical` | 垂直方向 |

### 2.4 样式属性

| 属性 | 类型 | 默认值 | 描述 |
|------|------|--------|------|
| `blockColor` | `ResourceColor` | - | 滑块颜色 |
| `trackColor` | `ResourceColor` | - | 轨道颜色 |
| `selectedColor` | `ResourceColor` | - | 已选择部分颜色 |
| `showSteps` | `boolean` | false | 是否显示步长刻度 |
| `trackThickness` | `Length` | - | 轨道粗细 |

### 2.5 交互属性

| 属性 | 类型 | 默认值 | 描述 |
|------|------|--------|------|
| `onChange` | `(value: number) => void` | - | 值变化回调 |

## 三、使用示例

### 3.1 基础 Slider 示例

```typescript
@ComponentV2
struct BasicSliderExample {
  @Local sliderValue: number = 50

  build() {
    Column({ space: 16 }) {
      Text('基础 Slider')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)

      // 基础滑动条
      Slider({ value: this.sliderValue, min: 0, max: 100 })
        .onChange((value: number) => {
          this.sliderValue = value
          console.info('Slider value: ' + value)
        })

      Text(`当前值: ${this.sliderValue}`)
        .fontSize(16)
        .fontColor('#666666')
    }
    .padding(16)
  }
}
```

### 3.2 设置步长示例

```typescript
@ComponentV2
struct StepSliderExample {
  @Local stepValue: number = 25

  build() {
    Column({ space: 16 }) {
      Text('步长 Slider')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)

      // 设置步长为 25（0, 25, 50, 75, 100）
      Slider({
        value: this.stepValue,
        min: 0,
        max: 100,
        step: 25
      })
        .showSteps(true) // 显示刻度
        .onChange((value: number) => {
          this.stepValue = value
        })

      Text(`当前值: ${this.stepValue}`)
        .fontSize(16)
        .fontColor('#666666')

      // 离散值选择（1-5 星）
      Slider({
        value: 3,
        min: 1,
        max: 5,
        step: 1
      })
        .showSteps(true)
        .selectedColor('#FFC107')
    }
    .padding(16)
  }
}
```

### 3.3 自定义样式示例

```typescript
@ComponentV2
struct StyledSliderExample {
  @Local value: number = 50

  build() {
    Column({ space: 20 }) {
      Text('自定义样式 Slider')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)

      // 自定义颜色
      Slider({ value: this.value, min: 0, max: 100 })
        .blockColor('#007DFF') // 滑块颜色
        .selectedColor('#007DFF') // 已选择部分颜色
        .trackColor('#E0E0E0') // 轨道颜色
        .onChange((value: number) => {
          this.value = value
        })

      // 自定义轨道粗细
      Slider({ value: 50, min: 0, max: 100 })
        .trackThickness(8) // 轨道粗细
        .selectedColor('#28A745')

      // 滑块在轨道内
      Slider({ value: 50, min: 0, max: 100, style: SliderStyle.InSet })
        .selectedColor('#FFC107')
    }
    .padding(16)
  }
}
```

### 3.4 垂直 Slider 示例

```typescript
@ComponentV2
struct VerticalSliderExample {
  @Local verticalValue: number = 50

  build() {
    Row({ space: 40 }) {
      // 水平 Slider
      Column({ space: 8 }) {
        Text('水平')
          .fontSize(14)
        Slider({
          value: this.verticalValue,
          min: 0,
          max: 100,
          direction: Axis.Horizontal
        })
          .width(200)
          .onChange((value: number) => {
            this.verticalValue = value
          })
        Text(`值: ${this.verticalValue}`)
          .fontSize(14)
      }

      // 垂直 Slider
      Column({ space: 8 }) {
        Text('垂直')
          .fontSize(14)
        Slider({
          value: this.verticalValue,
          min: 0,
          max: 100,
          direction: Axis.Vertical
        })
          .height(200)
          .onChange((value: number) => {
            this.verticalValue = value
          })
        Text(`值: ${this.verticalValue}`)
          .fontSize(14)
      }
    }
    .padding(16)
  }
}
```

### 3.5 实际应用场景

```typescript
@ComponentV2
struct MediaControlPanel {
  @Local volumeValue: number = 80
  @Local brightnessValue: number = 60
  @Local progressValue: number = 30

  build() {
    Column({ space: 24 }) {
      Text('媒体控制面板')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)

      // 音量控制
      Column({ space: 8 }) {
        Row() {
          Text('\uE8E1') // 喇叭图标
            .fontSize(20)
          Text('音量')
            .fontSize(16)
            .margin({ left: 8 })
          Blank()
          Text(`${this.volumeValue}%`)
            .fontSize(14)
            .fontColor('#666666')
        }
        .width('100%')

        Slider({
          value: this.volumeValue,
          min: 0,
          max: 100
        })
          .selectedColor('#007DFF')
          .onChange((value: number) => {
            this.volumeValue = value
          })
      }

      // 亮度控制
      Column({ space: 8 }) {
        Row() {
          Text('\uE617') // 亮度图标
            .fontSize(20)
          Text('亮度')
            .fontSize(16)
            .margin({ left: 8 })
          Blank()
          Text(`${this.brightnessValue}%`)
            .fontSize(14)
            .fontColor('#666666')
        }
        .width('100%')

        Slider({
          value: this.brightnessValue,
          min: 0,
          max: 100
        })
          .selectedColor('#FFC107')
          .onChange((value: number) => {
            this.brightnessValue = value
          })
      }

      // 进度控制
      Column({ space: 8 }) {
        Row() {
          Text('播放进度')
            .fontSize(16)
          Blank()
          Text(`${this.progressValue}%`)
            .fontSize(14)
            .fontColor('#666666')
        }
        .width('100%')

        Slider({
          value: this.progressValue,
          min: 0,
          max: 100
        })
          .selectedColor('#28A745')
          .onChange((value: number) => {
            this.progressValue = value
          })
      }
    }
    .padding(16)
  }
}
```

## 四、高级用法

### 4.1 双滑块范围选择

```typescript
@ComponentV2
struct RangeSliderExample {
  @Local minValue: number = 30
  @Local maxValue: number = 70

  build() {
    Column({ space: 16 }) {
      Text('范围选择')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)

      // 最小值滑块
      Row({ space: 8 }) {
        Text('最小:')
          .fontSize(14)
        Slider({
          value: this.minValue,
          min: 0,
          max: this.maxValue - 10
        })
          .onChange((value: number) => {
            if (value < this.maxValue) {
              this.minValue = value
            }
          })
        Text(`${this.minValue}`)
          .fontSize(14)
          .width(40)
      }

      // 最大值滑块
      Row({ space: 8 }) {
        Text('最大:')
          .fontSize(14)
        Slider({
          value: this.maxValue,
          min: this.minValue + 10,
          max: 100
        })
          .onChange((value: number) => {
            if (value > this.minValue) {
              this.maxValue = value
            }
          })
        Text(`${this.maxValue}`)
          .fontSize(14)
          .width(40)
      }

      Text(`范围: ${this.minValue} - ${this.maxValue}`)
        .fontSize(16)
        .fontColor('#007DFF')
    }
    .padding(16)
  }
}
```

### 4.2 动态调整范围

```typescript
@ComponentV2
struct DynamicRangeSlider {
  @Local value: number = 50
  @Local maxLimit: number = 100

  build() {
    Column({ space: 20 }) {
      Text('动态范围')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)

      // 范围选择按钮
      Row({ space: 12 }) {
        Button('100')
          .onClick(() => {
            this.maxLimit = 100
            this.value = Math.min(this.value, 100)
          })

        Button('200')
          .onClick(() => {
            this.maxLimit = 200
          })

        Button('500')
          .onClick(() => {
            this.maxLimit = 500
          })
      }

      // 滑块
      Slider({
        value: this.value,
        min: 0,
        max: this.maxLimit
      })
        .selectedColor('#007DFF')
        .onChange((value: number) => {
          this.value = value
        })

      Text(`当前值: ${this.value} / ${this.maxLimit}`)
        .fontSize(16)
        .fontColor('#666666')
    }
    .padding(16)
  }
}
```

### 4.3 带预览的 Slider

```typescript
@ComponentV2
struct PreviewSlider {
  @Local value: number = 50
  @Local showPreview: boolean = false

  build() {
    Column({ space: 16 }) {
      Text('带预览的 Slider')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)

      Stack() {
        Slider({
          value: this.value,
          min: 0,
          max: 100
        })
          .selectedColor('#007DFF')
          .onChange((value: number) => {
            this.value = value
          })
          .onTouch((event: TouchEvent) => {
            this.showPreview = event.type === TouchType.Down
          })

        // 预览气泡
        if (this.showPreview) {
          Text(`${Math.round(this.value)}`)
            .padding(8)
            .backgroundColor('#333333')
            .fontColor(Color.White)
            .borderRadius(4)
            .position({
              x: `${this.value}%`,
              y: -50
            })
            .markAnchor({ x: '50%', y: '100%' })
        }
      }
      .width('100%')
    }
    .padding(16)
  }
}
```

## 五、最佳实践

### 5.1 合理设置步长

```typescript
// ✅ 推荐：根据实际需求设置步长
// 百分比控制
Slider({ value: 50, min: 0, max: 100, step: 1 })

// 离散选项（如星级）
Slider({ value: 3, min: 1, max: 5, step: 1 })

// 时间选择（分钟）
Slider({ value: 30, min: 0, max: 60, step: 5 })
```

### 5.2 显示当前值

```typescript
// ✅ 推荐：显示当前选择的值
@ComponentV2
struct GoodSlider {
  @Local value: number = 50

  build() {
    Column({ space: 8 }) {
      Row() {
        Text('进度:')
          .fontSize(14)
        Blank()
        Text(`${this.value}%`)
          .fontSize(14)
          .fontColor('#666666')
      }

      Slider({ value: this.value, min: 0, max: 100 })
        .onChange((value: number) => {
          this.value = value
        })
    }
  }
}
```

### 5.3 颜色选择

```typescript
// ✅ 推荐：根据状态使用不同颜色
// 正常状态
Slider({ value: 50, min: 0, max: 100 })
  .selectedColor('#007DFF')

// 警告状态
Slider({ value: 80, min: 0, max: 100 })
  .selectedColor('#FFC107')

// 危险状态
Slider({ value: 90, min: 0, max: 100 })
  .selectedColor('#DC3545')
```

### 5.4 响应式尺寸

```typescript
// ✅ 推荐：使用百分比实现响应式
Slider({ value: 50, min: 0, max: 100 })
  .width('100%')
```

## 六、常见问题

### Q1: Slider 值不精确？

**问题**: 设置的值与实际显示的值不一致。

**解决方案**:
```typescript
// 确保步长能整除最大值
// ✅ 正确
Slider({ value: 50, min: 0, max: 100, step: 5 })

// ❌ 错误（步长无法整除最大值）
Slider({ value: 50, min: 0, max: 100, step: 3 })
```

### Q2: 如何实现范围选择？

**解决方案**:
```typescript
// 使用两个 Slider
@ComponentV2
struct RangeSlider {
  @Local minValue: number = 30
  @Local maxValue: number = 70

  build() {
    Column() {
      Slider({
        value: this.minValue,
        min: 0,
        max: this.maxValue - 10
      })
        .onChange((value: number) => {
          this.minValue = value
        })

      Slider({
        value: this.maxValue,
        min: this.minValue + 10,
        max: 100
      })
        .onChange((value: number) => {
          this.maxValue = value
        })
    }
  }
}
```

### Q3: 垂直 Slider 高度不生效？

**解决方案**:
```typescript
// ❌ 错误：使用 width
Slider({
  value: 50,
  min: 0,
  max: 100,
  direction: Axis.Vertical
})
  .width(200) // 错误

// ✅ 正确：使用 height
Slider({
  value: 50,
  min: 0,
  max: 100,
  direction: Axis.Vertical
})
  .height(200) // 正确
```

### Q4: 如何实现双向绑定？

**解决方案**:
```typescript
// ✅ 使用 onChange 更新状态
@ComponentV2
struct TwoWayBinding {
  @Local value: number = 50

  build() {
    Slider({ value: this.value, min: 0, max: 100 })
      .onChange((newValue: number) => {
        this.value = newValue // 更新状态
      })
  }
}
```

### Q5: 滑块太小不好操作？

**解决方案**:
```typescript
// 使用 trackThickness 增加轨道粗细
Slider({ value: 50, min: 0, max: 100 })
  .trackThickness(12) // 更粗的轨道
  .blockColor('#007DFF') // 明显的滑块颜色
```

## 七、版本兼容性

| API 版本 | 支持状态 | 备注 |
|----------|----------|------|
| API 9+ | ✅ | 完全支持 |
| API 10+ | ✅ | 增加了 style 参数 |
| API 12+ | ✅ | 增加了 trackThickness 属性 |

## 八、参考资料

- [Slider 滑动条 - 华为开发者官方文档](https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V5/ts-basic-components-slider-V5)
- [通用属性 - 华为开发者](https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V5/ts-universal-attributes-size-V5)
