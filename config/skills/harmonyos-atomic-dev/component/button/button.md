# Button 组件 HarmonyOS 6.0 开发 Skill

## 概述

Button 组件是 OpenHarmony 中最基础且最重要的交互组件之一，用于触发操作或事件。它支持多种类型（胶囊、圆形、矩形等）、样式模式、角色和尺寸，可高度自定义以满足不同的设计需求。

## 重要说明

- **基础组件**: Button 是 ArkUI 的基础内置组件，无需导入
- **多种类型**: 支持 Capsule（胶囊）、Circle（圆形）、Normal（普通）、ROUNDED_RECTANGLE（圆角矩形）四种类型
- **样式模式**: 支持 NORMAL（普通）、EMPHASIZED（强调）、TEXTUAL（文本）三种样式
- **角色定义**: 支持 NORMAL（普通操作）和 ERROR（危险操作）两种角色
- **尺寸规格**: 提供 SMALL（小）和 NORMAL（正常）两种控件尺寸
- **自定义内容**: 支持通过 @Builder 装饰器自定义按钮内部内容

## 模块信息

- **组件名称**: Button
- **SDK 版本**: HarmonyOS 6.0 (API 12+)
- **系统能力**: SystemCapability.ArkUI.ArkUI.Full
- **更新日期**: 2026-03-10
- **官方文档**:
  - [Button 按钮 - 华为开发者](https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V5/ts-basic-components-button-V5)

## 一、组件基础

### 1.1 导入方式

```typescript
// Button 是内置组件，无需导入
// 直接使用即可
Button('Click Me')
```

### 1.2 基础用法

```typescript
// 文本按钮
Button('Submit')
  .onClick(() => {
    console.info('Button clicked')
  })

// 带类型的按钮
Button('Capsule', { type: ButtonType.Capsule })
  .width('100%')
  .height(45)

// 自定义内容按钮
Button() {
  Row({ space: 8 }) {
    Text('\uE641')
      .fontSize(20)
    Text('Download')
      .fontSize(16)
  }
}
.width('100%')
.height(45)
```

## 二、API 参数

### 2.1 构造参数

| 参数 | 类型 | 必填 | 默认值 | 描述 |
|------|------|------|--------|------|
| label | `string \| Resource` | 否 | - | 按钮文本内容 |
| options | `ButtonOptions` | 否 | - | 按钮配置选项 |

### 2.2 ButtonOptions 接口

| 参数 | 类型 | 必填 | 默认值 | 描述 |
|------|------|------|--------|------|
| type | `ButtonType` | 否 | ButtonType.Capsule | 按钮类型 |
| stateEffect | `boolean` | 否 | true | 是否开启状态效果（按下效果） |
| buttonStyle | `ButtonStyleMode` | 否 | ButtonStyleMode.EMPHASIZED | 按钮样式模式 |
| role | `ButtonRole` | 否 | ButtonRole.NORMAL | 按钮角色 |
| controlSize | `ControlSize` | 否 | ControlSize.NORMAL | 控件尺寸 |

### 2.3 ButtonType 枚举

| 类型 | 描述 | 使用场景 |
|------|------|----------|
| `ButtonType.Capsule` | 胶囊型按钮（圆角半径为高度的一半） | 主要操作按钮、提交按钮 |
| `ButtonType.Circle` | 圆形按钮 | 图标按钮、悬浮按钮 |
| `ButtonType.Normal` | 普通矩形按钮 | 工具栏按钮、次要操作 |
| `ButtonType.ROUNDED_RECTANGLE` | 圆角矩形按钮（API 15+） | 自定义圆角按钮 |

### 2.4 ButtonStyleMode 枚举

| 样式 | 描述 | 使用场景 |
|------|------|----------|
| `ButtonStyleMode.NORMAL` | 普通样式 | 次要操作 |
| `ButtonStyleMode.EMPHASIZED` | 强调样式（默认） | 主要操作 |
| `ButtonStyleMode.TEXTUAL` | 文本样式 | 文本链接、取消操作 |

### 2.5 ButtonRole 枚举

| 角色 | 描述 | 使用场景 |
|------|------|----------|
| `ButtonRole.NORMAL` | 普通角色（默认） | 常规操作 |
| `ButtonRole.ERROR` | 错误角色 | 删除、危险操作 |

### 2.6 ControlSize 枚举

| 尺寸 | 描述 | 使用场景 |
|------|------|----------|
| `ControlSize.SMALL` | 小尺寸 | 紧凑布局、工具栏 |
| `ControlSize.NORMAL` | 正常尺寸（默认） | 常规按钮 |

### 2.7 LabelStyle 接口

```typescript
interface LabelStyle {
  overflow?: TextOverflow;          // 文本溢出方式
  maxLines?: number;                // 最大行数
  font?: Font;                      // 字体样式
  minFontScale?: number;            // 最小字体缩放比例
  maxFontScale?: number;            // 最大字体缩放比例
}
```

### 2.8 常用属性

| 属性 | 类型 | 默认值 | 描述 |
|------|------|--------|------|
| `type` | `ButtonType` | ButtonType.Capsule | 设置按钮类型 |
| `buttonStyle` | `ButtonStyleMode` | ButtonStyleMode.EMPHASIZED | 设置按钮样式模式 |
| `role` | `ButtonRole` | ButtonRole.NORMAL | 设置按钮角色 |
| `controlSize` | `ControlSize` | ControlSize.NORMAL | 设置控件尺寸 |
| `stateEffect` | `boolean` | true | 是否开启状态效果 |
| `labelStyle` | `LabelStyle` | - | 设置标签样式 |
| `backgroundColor` | `ResourceColor` | - | 背景色 |
| `fontColor` | `ResourceColor` | - | 文本颜色 |
| `fontSize` | `number \| string \| Resource` | - | 字体大小 |
| `enabled` | `boolean` | true | 是否启用 |

### 2.9 事件

| 事件 | 类型 | 描述 |
|------|------|------|
| `onClick` | `() => void` | 点击按钮时触发 |

## 三、使用示例

### 3.1 按钮类型示例

```typescript
@ComponentV2
struct ButtonTypesExample {
  build() {
    Column({ space: 16 }) {
      Text('Button Types')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)

      // Capsule 胶囊按钮
      Button('Capsule Button', { type: ButtonType.Capsule })
        .width('100%')
        .height(45)
        .backgroundColor('#007DFF')
        .fontColor(Color.White)

      // Circle 圆形按钮
      Button('OK', { type: ButtonType.Circle })
        .width(70)
        .height(70)
        .fontSize(20)
        .backgroundColor('#28A745')
        .fontColor(Color.White)

      // Normal 普通按钮
      Button('Normal Button', { type: ButtonType.Normal })
        .width('100%')
        .height(45)
        .backgroundColor('#6C757D')
        .fontColor(Color.White)

      // ROUNDED_RECTANGLE 圆角矩形按钮 (API 15+)
      Button('Rounded Rect', { type: ButtonType.ROUNDED_RECTANGLE })
        .width('100%')
        .height(45)
        .borderRadius(12)
        .backgroundColor('#FFC107')
        .fontColor(Color.White)
    }
    .width('100%')
    .padding(16)
  }
}
```

### 3.2 按钮样式模式示例

```typescript
@ComponentV2
struct ButtonStyleModeExample {
  build() {
    Column({ space: 16 }) {
      Text('Button Style Mode')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)

      // NORMAL 普通样式
      Button('Normal Style', { buttonStyle: ButtonStyleMode.NORMAL })
        .width('100%')
        .height(45)

      // EMPHASIZED 强调样式（默认）
      Button('Emphasized Style', { buttonStyle: ButtonStyleMode.EMPHASIZED })
        .width('100%')
        .height(45)

      // TEXTUAL 文本样式
      Button('Textual Style', { buttonStyle: ButtonStyleMode.TEXTUAL })
        .width('100%')
        .height(45)
        .fontColor('#007DFF')
    }
    .width('100%')
    .padding(16)
  }
}
```

### 3.3 按钮角色示例

```typescript
@ComponentV2
struct ButtonRoleExample {
  build() {
    Column({ space: 16 }) {
      Text('Button Role')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)

      // NORMAL 普通角色
      Button('Normal Action', { role: ButtonRole.NORMAL })
        .width('100%')
        .height(45)
        .type(ButtonType.Capsule)
        .backgroundColor('#007DFF')
        .fontColor(Color.White)

      // ERROR 错误角色
      Button('Delete', { role: ButtonRole.ERROR })
        .width('100%')
        .height(45)
        .type(ButtonType.Capsule)
        .fontColor(Color.White)
    }
    .width('100%')
    .padding(16)
  }
}
```

### 3.4 控件尺寸示例

```typescript
@ComponentV2
struct ControlSizeExample {
  build() {
    Column({ space: 16 }) {
      Text('Control Size')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)

      // SMALL 小尺寸
      Button('Small', { controlSize: ControlSize.SMALL })
        .backgroundColor('#007DFF')
        .fontColor(Color.White)

      // NORMAL 正常尺寸
      Button('Normal', { controlSize: ControlSize.NORMAL })
        .backgroundColor('#007DFF')
        .fontColor(Color.White)
    }
    .width('100%')
    .padding(16)
  }
}
```

### 3.5 Label 样式示例

```typescript
@ComponentV2
struct LabelStyleExample {
  build() {
    Column({ space: 16 }) {
      Text('Label Style')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)

      // 基础 label 样式
      Button('Button with Label Style')
        .labelStyle({
          overflow: TextOverflow.Ellipsis,
          maxLines: 1,
          font: {
            size: 16,
            weight: FontWeight.Medium
          }
        })
        .width('100%')
        .height(45)
        .backgroundColor('#007DFF')
        .fontColor(Color.White)

      // 多行文本
      Button('Very Long Button Text That Should Wrap to Multiple Lines')
        .labelStyle({
          maxLines: 2,
          overflow: TextOverflow.Clip,
          font: {
            size: 14
          }
        })
        .width('100%')
        .height(60)
        .backgroundColor('#28A745')
        .fontColor(Color.White)

      // 自定义字体
      Button('Custom Font')
        .labelStyle({
          font: {
            size: 18,
            weight: FontWeight.Bold,
            family: 'sans-serif'
          }
        })
        .width('100%')
        .height(45)
        .backgroundColor('#FFC107')
        .fontColor(Color.White)
    }
    .width('100%')
    .padding(16)
  }
}
```

### 3.6 状态效果示例

```typescript
@ComponentV2
struct StateEffectExample {
  build() {
    Column({ space: 16 }) {
      Text('State Effect')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)

      // 开启状态效果（默认）
      Button('With Effect', { stateEffect: true })
        .width('100%')
        .height(45)
        .type(ButtonType.Capsule)
        .backgroundColor('#007DFF')
        .fontColor(Color.White)

      // 关闭状态效果
      Button('Without Effect', { stateEffect: false })
        .width('100%')
        .height(45)
        .type(ButtonType.Capsule)
        .backgroundColor('#28A745')
        .fontColor(Color.White)
    }
    .width('100%')
    .padding(16)
  }
}
```

### 3.7 自定义内容按钮示例

```typescript
@ComponentV2
struct CustomContentExample {
  @Local clickCount: number = 0

  build() {
    Column({ space: 16 }) {
      Text('Custom Content')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)

      // 带图标和文本的按钮
      Button() {
        Row({ space: 8 }) {
          Text('\uE641') // Unicode 图标
            .fontSize(20)
            .fontColor(Color.White)
          Text('Download')
            .fontSize(16)
            .fontColor(Color.White)
        }
      }
      .width('100%')
      .height(45)
      .type(ButtonType.Capsule)
      .backgroundColor('#007DFF')
      .onClick(() => {
        this.clickCount++
        console.info(`Download clicked ${this.clickCount} times`)
      })

      // 纯图标按钮
      Button() {
        Text('\uE8EF') // 搜索图标
          .fontSize(24)
          .fontColor(Color.White)
      }
      .width(50)
      .height(50)
      .type(ButtonType.Circle)
      .backgroundColor('#28A745')

      // 自定义布局按钮
      Button() {
        Row() {
          Column({ space: 4 }) {
            Text('Click Me')
              .fontSize(14)
              .fontColor(Color.White)
            Text(`Count: ${this.clickCount}`)
              .fontSize(12)
              .fontColor(Color.White)
              .opacity(0.8)
          }
          .alignItems(HorizontalAlign.Center)
        }
      }
      .width('100%')
      .height(60)
      .type(ButtonType.Normal)
      .backgroundColor('#FFC107')
    }
    .width('100%')
    .padding(16)
  }
}
```

### 3.8 加载状态按钮示例

```typescript
@ComponentV2
struct LoadingButtonExample {
  @Local isLoading: boolean = false

  build() {
    Column({ space: 16 }) {
      Text('Loading Button')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)

      Button() {
        if (this.isLoading) {
          Row({ space: 8 }) {
            LoadingProgress()
              .width(20)
              .height(20)
              .color(Color.White)
            Text('Loading...')
              .fontSize(16)
              .fontColor(Color.White)
          }
        } else {
          Text('Submit')
            .fontSize(16)
            .fontColor(Color.White)
        }
      }
      .width('100%')
      .height(45)
      .type(ButtonType.Capsule)
      .backgroundColor(this.isLoading ? '#CCCCCC' : '#007DFF')
      .enabled(!this.isLoading)
      .onClick(() => {
        if (!this.isLoading) {
          this.isLoading = true
          // 模拟异步操作
          setTimeout(() => {
            this.isLoading = false
            console.info('Submit completed')
          }, 2000)
        }
      })

      Text('Click to see loading state')
        .fontSize(14)
        .fontColor('#666666')
        .margin({ top: 8 })
    }
    .width('100%')
    .padding(16)
  }
}
```

### 3.9 按钮组示例

```typescript
@ComponentV2
struct ButtonGroupExample {
  @Local selectedIndex: number = 0

  build() {
    Column({ space: 16 }) {
      Text('Button Group')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)

      // 时间选择按钮组
      Row({ space: 8 }) {
        ForEach(['Day', 'Week', 'Month', 'Year'], (item: string, index: number) => {
          Button(item)
            .width(65)
            .height(36)
            .type(ButtonType.Normal)
            .backgroundColor(index === this.selectedIndex ? '#007DFF' : '#E0E0E0')
            .fontColor(index === this.selectedIndex ? Color.White : '#333333')
            .onClick(() => {
              this.selectedIndex = index
              console.info(`Selected: ${item}`)
            })
        })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceEvenly)

      // 操作按钮组（取消/确认）
      Row({ space: 12 }) {
        Button('Cancel')
          .width('48%')
          .height(45)
          .type(ButtonType.Capsule)
          .backgroundColor('#6C757D')
          .fontColor(Color.White)

        Button('Confirm')
          .width('48%')
          .height(45)
          .type(ButtonType.Capsule)
          .backgroundColor('#007DFF')
          .fontColor(Color.White)
      }
      .width('100%')
    }
    .width('100%')
    .padding(16)
  }
}
```

## 四、高级用法

### 4.1 渐变背景按钮

```typescript
@ComponentV2
struct GradientButtonExample {
  build() {
    Column({ space: 16 }) {
      Text('Gradient Button')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)

      // 线性渐变
      Button('Linear Gradient')
        .width('100%')
        .height(45)
        .linearGradient({
          angle: 90,
          colors: [['#007DFF', 0], ['#28A745', 1]]
        })
        .fontColor(Color.White)

      // 径向渐变
      Button('Radial Gradient')
        .width(100)
        .height(100)
        .type(ButtonType.Circle)
        .radialGradient({
          center: [50, 50],
          radius: 50,
          colors: [['#FFC107', 0], ['#FF6B6B', 1]]
        })
        .fontColor(Color.White)
    }
    .width('100%')
    .padding(16)
  }
}
```

### 4.2 阴影效果按钮

```typescript
@ComponentV2
struct ShadowButtonExample {
  build() {
    Column({ space: 16 }) {
      Text('Shadow Button')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)

      Button('With Shadow')
        .width('100%')
        .height(45)
        .type(ButtonType.Capsule)
        .backgroundColor('#007DFF')
        .fontColor(Color.White)
        .shadow({
          radius: 10,
          color: '#40007DFF',
          offsetX: 0,
          offsetY: 4
        })
    }
    .width('100%')
    .padding(16)
  }
}
```

### 4.3 动画效果按钮

```typescript
@ComponentV2
struct AnimatedButtonExample {
  @Local buttonWidth: number = 200
  @Local buttonHeight: number = 45

  build() {
    Column({ space: 16 }) {
      Text('Animated Button')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)

      Button('Click Me')
        .width(this.buttonWidth)
        .height(this.buttonHeight)
        .type(ButtonType.Capsule)
        .backgroundColor('#007DFF')
        .fontColor(Color.White)
        .animation({
          duration: 300,
          curve: Curve.EaseInOut
        })
        .onClick(() => {
          // 点击时改变尺寸
          this.buttonWidth = this.buttonWidth === 200 ? 250 : 200
          this.buttonHeight = this.buttonHeight === 45 ? 55 : 45
        })
    }
    .width('100%')
    .padding(16)
  }
}
```

### 4.4 禁用状态按钮

```typescript
@ComponentV2
struct DisabledButtonExample {
  @Local isFormValid: boolean = false

  build() {
    Column({ space: 16 }) {
      Text('Disabled Button')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)

      // 禁用状态按钮
      Button('Submit')
        .width('100%')
        .height(45)
        .type(ButtonType.Capsule)
        .backgroundColor(this.isFormValid ? '#007DFF' : '#CCCCCC')
        .fontColor(Color.White)
        .enabled(this.isFormValid)
        .opacity(this.isFormValid ? 1 : 0.6)

      Button('Toggle Form Valid')
        .onClick(() => {
          this.isFormValid = !this.isFormValid
        })
    }
    .width('100%')
    .padding(16)
  }
}
```

### 4.5 悬浮按钮（FAB）

```typescript
@ComponentV2
struct FloatingActionButtonExample {
  build() {
    Stack({ alignContent: Alignment.BottomEnd }) {
      // 主要内容
      Column() {
        Text('Main Content')
          .fontSize(20)
      }
      .width('100%')
      .height('100%')

      // 悬浮按钮
      Button() {
        Text('+')
          .fontSize(32)
          .fontColor(Color.White)
      }
      .width(56)
      .height(56)
      .type(ButtonType.Circle)
      .backgroundColor('#007DFF')
      .shadow({
        radius: 8,
        color: '#40000000',
        offsetX: 0,
        offsetY: 4
      })
      .margin({ right: 16, bottom: 16 })
      .onClick(() => {
        console.info('FAB clicked')
      })
    }
    .width('100%')
    .height(400)
  }
}
```

### 4.6 图标按钮组

```typescript
@ComponentV2
struct IconButtonGroupExample {
  build() {
    Column({ space: 16 }) {
      Text('Icon Button Group')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)

      Row({ space: 12 }) {
        // 主页按钮
        Button() {
          Text('\uE641')
            .fontSize(24)
            .fontColor(Color.White)
        }
        .width(50)
        .height(50)
        .type(ButtonType.Circle)
        .backgroundColor('#007DFF')

        // 搜索按钮
        Button() {
          Text('\uE8EF')
            .fontSize(24)
            .fontColor(Color.White)
        }
        .width(50)
        .height(50)
        .type(ButtonType.Circle)
        .backgroundColor('#28A745')

        // 设置按钮
        Button() {
          Text('\uE63B')
            .fontSize(24)
            .fontColor(Color.White)
        }
        .width(50)
        .height(50)
        .type(ButtonType.Circle)
        .backgroundColor('#FFC107')
      }
      .justifyContent(FlexAlign.Center)
    }
    .width('100%')
    .padding(16)
  }
}
```

## 五、最佳实践

### 5.1 按钮类型选择

```typescript
// ✅ 推荐：主要操作使用 Capsule 类型
Button('Submit')
  .type(ButtonType.Capsule)
  .backgroundColor('#007DFF')

// ✅ 推荐：图标操作使用 Circle 类型
Button() {
  Text('\uE641')
}
.type(ButtonType.Circle)
.width(50)
.height(50)

// ✅ 推荐：工具栏使用 Normal 类型
Button('Edit')
  .type(ButtonType.Normal)
  .backgroundColor('#6C757D')
```

### 5.2 颜色使用

```typescript
// ✅ 推荐：使用主题色
Button('Primary Action')
  .backgroundColor($r('app.color.primary'))
  .fontColor(Color.White)

// ✅ 推荐：危险操作使用红色
Button('Delete', { role: ButtonRole.ERROR })
  .backgroundColor('#DC3545')
  .fontColor(Color.White)

// ✅ 推荐：次要操作使用灰色
Button('Cancel')
  .backgroundColor('#6C757D')
  .fontColor(Color.White)
```

### 5.3 尺寸设置

```typescript
// ✅ 推荐：主要按钮使用标准尺寸
Button('Submit')
  .width('100%')
  .height(45)

// ✅ 推荐：工具栏按钮使用小尺寸
Button('Edit', { controlSize: ControlSize.SMALL })

// ✅ 推荐：图标按钮保持 1:1 比例
Button() {
  Text('\uE641')
}
.width(50)
.height(50)
.type(ButtonType.Circle)
```

### 5.4 文本处理

```typescript
// ✅ 推荐：限制文本行数
Button('Very Long Button Text')
  .labelStyle({
    maxLines: 1,
    overflow: TextOverflow.Ellipsis
  })

// ❌ 避免：文本过长不处理
Button('Very Long Button Text That May Overflow')
  .width(100) // 文本可能被截断
```

### 5.5 状态管理

```typescript
// ✅ 推荐：使用 @Local 管理按钮状态
@ComponentV2
struct GoodButtonExample {
  @Local isLoading: boolean = false

  build() {
    Button(this.isLoading ? 'Loading...' : 'Submit')
      .enabled(!this.isLoading)
      .onClick(async () => {
        this.isLoading = true
        await this.submitForm()
        this.isLoading = false
      })
  }
}
```

### 5.6 性能优化

```typescript
// ✅ 推荐：避免在 onClick 中进行复杂计算
Button('Submit')
  .onClick(() => {
    // 简单的状态更新
    this.handleSubmit()
  })

// ❌ 避免：在 onClick 中进行大量计算
Button('Submit')
  .onClick(() => {
    // 复杂计算会阻塞 UI
    for (let i = 0; i < 1000000; i++) {
      // ...
    }
  })
```

## 六、常见问题

### Q1: Button 文本显示不全？

**问题**: 按钮文本被截断。

**解决方案**:
```typescript
// 方案 1: 使用 labelStyle 限制行数
Button('Long Text')
  .labelStyle({
    maxLines: 1,
    overflow: TextOverflow.Ellipsis
  })
  .width(150)

// 方案 2: 增加按钮宽度
Button('Long Text')
  .width('100%')

// 方案 3: 减小字体大小
Button('Long Text')
  .fontSize(14)
```

### Q2: 如何实现禁用状态？

**解决方案**:
```typescript
Button('Submit')
  .enabled(false) // 禁用按钮
  .backgroundColor('#CCCCCC') // 禁用颜色
  .opacity(0.6) // 降低不透明度
```

### Q3: Button 的 onClick 不触发？

**问题**: 点击按钮没有反应。

**解决方案**:
```typescript
// ❌ 错误：按钮被禁用
Button('Click')
  .enabled(false)
  .onClick(() => {
    console.info('Clicked') // 不会触发
  })

// ✅ 正确：确保按钮启用
Button('Click')
  .enabled(true)
  .onClick(() => {
    console.info('Clicked')
  })
```

### Q4: 如何实现按钮的加载状态？

**解决方案**:
```typescript
@ComponentV2
struct LoadingButton {
  @Local isLoading: boolean = false

  build() {
    Button() {
      if (this.isLoading) {
        Row({ space: 8 }) {
          LoadingProgress()
            .width(20)
            .height(20)
          Text('Loading...')
        }
      } else {
        Text('Submit')
      }
    }
    .enabled(!this.isLoading)
    .onClick(() => {
      this.isLoading = true
      setTimeout(() => {
        this.isLoading = false
      }, 2000)
    })
  }
}
```

### Q5: ButtonType.ROUNDED_RECTANGLE 不生效？

**问题**: 设置 ROUNDED_RECTANGLE 类型后按钮没有变化。

**解决方案**:
```typescript
// ROUNDED_RECTANGLE 需要 API 15+
// 并且需要同时设置 borderRadius
Button('Rounded Rect', { type: ButtonType.ROUNDED_RECTANGLE })
  .borderRadius(12) // 必须设置
  .width('100%')
  .height(45)
```

### Q6: 如何自定义按钮的圆角大小？

**解决方案**:
```typescript
// 方案 1: 使用 Normal 类型 + borderRadius
Button('Custom Radius')
  .type(ButtonType.Normal)
  .borderRadius(20)

// 方案 2: 使用 ROUNDED_RECTANGLE 类型 (API 15+)
Button('Custom Radius', { type: ButtonType.ROUNDED_RECTANGLE })
  .borderRadius(20)
```

### Q7: 如何实现按钮组互斥选择？

**解决方案**:
```typescript
@ComponentV2
struct ExclusiveButtonGroup {
  @Local selectedIndex: number = 0

  build() {
    Row({ space: 8 }) {
      ForEach(['Option 1', 'Option 2', 'Option 3'], (item: string, index: number) => {
        Button(item)
          .backgroundColor(index === this.selectedIndex ? '#007DFF' : '#E0E0E0')
          .fontColor(index === this.selectedIndex ? Color.White : '#333333')
          .onClick(() => {
            this.selectedIndex = index
          })
      })
    }
  }
}
```

### Q8: 如何在按钮中使用图标？

**解决方案**:
```typescript
// 方案 1: 使用 Unicode 字符
Button() {
  Row({ space: 8 }) {
    Text('\uE641') // 图标 Unicode
    Text('Download')
  }
}

// 方案 2: 使用 SymbolGlyph（推荐）
Button() {
  Row({ space: 8 }) {
    SymbolGlyph($r('sys.symbol.download'))
      .fontSize(20)
      .fontColor(Color.White)
    Text('Download')
  }
}
```

## 七、版本兼容性

| API 版本 | 支持状态 | 备注 |
|----------|----------|------|
| API 9+ | ✅ | 完全支持基础功能 |
| API 12+ | ✅ | 支持 ButtonStyleMode、ButtonRole、ControlSize |
| API 15+ | ✅ | 支持 ButtonType.ROUNDED_RECTANGLE |

## 八、相关组件

- **Toggle**: 开关组件，支持 Checkbox、Switch、Radio、Button 样式
- **Radio**: 单选按钮组件
- **Checkbox**: 复选框组件
- **DatePicker**: 日期选择器
- **TimePicker**: 时间选择器

## 九、参考资料

- [Button 按钮 - 华为开发者官方文档](https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V5/ts-basic-components-button-V5)
- [通用属性 - 华为开发者](https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V5/ts-universal-attributes-size-V5)
- [Button 组件示例 - 华为开发者社区](https://developer.huawei.com/consumer/cn/doc/harmonyos-samples-V5/button-component-V5)
