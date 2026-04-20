# NavDestination 组件 HarmonyOS 6.0 开发 Skill

## 概述

NavDestination 组件是 OpenHarmony 中用于定义导航目标页面的组件。它是 Navigation 和 NavRouter 的核心子组件，用于包装页面内容并提供完整的页面生命周期管理。NavDestination 支持标题栏配置、转场动画、生命周期回调等丰富的功能。

## 重要说明

- **页面容器**: NavDestination 是页面的容器组件
- **生命周期**: 提供完整的页面生命周期回调
- **标题栏**: 内置可配置的标题栏
- **路由配合**: 必须与 Navigation 或 NavRouter 配合使用
- **转场动画**: 支持自定义页面转场动画

## 模块信息

- **组件名称**: NavDestination
- **SDK 版本**: HarmonyOS 6.0 (API 12+)
- **系统能力**: SystemCapability.ArkUI.ArkUI.Full
- **更新日期**: 2026-02-24
- **官方文档**:
  - [NavDestination - 华为开发者](https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V5/ts-basic-components-navdestination-V5)

## 一、组件基础

### 1.1 导入方式

```typescript
import { NavDestination } from '@kit.ArkUI'
```

### 1.2 基础用法

```typescript
@ComponentV2
struct NavDestinationExample {
  @Param navPathStack: NavPathStack = new NavPathStack()

  build() {
    NavDestination() {
      Column() {
        Text('页面内容')
          .fontSize(20)
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
    }
    .title('页面标题')
    .mode(NavDestinationMode.STANDARD)
  }
}
```

## 二、API 参数

### 2.1 构造参数

| 参数 | 类型 | 必填 | 默认值 | 描述 |
|------|------|------|--------|------|
| content | `BuilderParam` | 是 | - | 页面内容 |

### 2.2 页面模式

| 属性 | 类型 | 默认值 | 描述 |
|------|------|--------|------|
| `mode` | `NavDestinationMode` | NavDestinationMode.STANDARD | 页面模式 |
| - NavDestinationMode.STANDARD | - | - | 标准页面模式 |
| - NavDestinationMode.DIALOG | - | - | 对话框页面模式 |
| - NavDestinationMode.MODAL | - | - | 模态页面模式 |

### 2.3 标题栏属性

| 属性 | 类型 | 默认值 | 描述 |
|------|------|--------|------|
| `title` | `string \| Resource` | - | 页面标题 |
| `subtitle` | `string` | - | 副标题 |
| `hideTitleBar` | `boolean` | false | 是否隐藏标题栏 |
| `titleBackgroundColor` | `ResourceColor` | - | 标题栏背景色 |

### 2.4 生命周期回调

| 事件 | 类型 | 描述 |
|------|------|------|
| `onReady` | `(context: NavDestinationContext) => void` | 页面准备就绪 |
| `onWillShow` | `() => void` | 页面即将显示 |
| `onShown` | `() => void` | 页面已显示 |
| `onWillHide` | `() => void` | 页面即将隐藏 |
| `onHidden` | `() => void` | 页面已隐藏 |
| `onWillDisappear` | `() => void` | 页面即将消失 |
| `onWillDisappear` | `() => void` | 页面即将消失（API 18+） |

### 2.5 导航栏属性

| 属性 | 类型 | 默认值 | 描述 |
|------|------|--------|------|
| `hideBackButton` | `boolean` | false | 是否隐藏返回按钮 |
| `backButtonIcon` | `ResourceStr` | - | 自定义返回按钮图标 |

### 2.6 转场动画

| 属性 | 类型 | 默认值 | 描述 |
|------|------|--------|------|
| `transition` | `TransitionEffect` | - | 页面转场动画效果 |

## 三、使用示例

### 3.1 基础 NavDestination 示例

```typescript
@ComponentV2
export struct BasicNavDestinationExample {
  @Param navPathStack: NavPathStack = new NavPathStack()

  build() {
    NavDestination() {
      Column({ space: 16 }) {
        Text('NavDestination 基础示例')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)

        Text('这是一个标准的 NavDestination 页面')
          .fontSize(16)
          .fontColor('#666666')

        Button('返回上一页')
          .onClick(() => {
            this.navPathStack.pop()
          })
      }
      .width('100%')
      .height('100%')
      .padding(16)
      .justifyContent(FlexAlign.Center)
    }
    .title('基础页面')
    .mode(NavDestinationMode.STANDARD)
  }
}
```

### 3.2 带生命周期的 NavDestination

```typescript
@ComponentV2
struct LifecycleNavDestinationExample {
  @Param navPathStack: NavPathStack = new NavPathStack()
  @Local lifecycleLog: string[] = []

  build() {
    NavDestination() {
      Column({ space: 16 }) {
        Text('生命周期示例')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)

        Text('生命周期日志:')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)

        ForEach(this.lifecycleLog, (log: string) => {
          Text(log)
            .fontSize(14)
            .fontColor('#666666')
            .width('100%')
        })

        Button('返回')
          .onClick(() => {
            this.navPathStack.pop()
          })
      }
      .width('100%')
      .height('100%')
      .padding(16)
    }
    .title('生命周期页面')
    .onReady(() => {
      this.addLog('onReady: 页面准备就绪')
    })
    .onWillShow(() => {
      this.addLog('onWillShow: 页面即将显示')
    })
    .onShown(() => {
      this.addLog('onShown: 页面已显示')
    })
    .onWillHide(() => {
      this.addLog('onWillHide: 页面即将隐藏')
    })
    .onHidden(() => {
      this.addLog('onHidden: 页面已隐藏')
    })
  }

  addLog(message: string) {
    const timestamp = new Date().toLocaleTimeString()
    this.lifecycleLog.unshift(`[${timestamp}] ${message}`)
    if (this.lifecycleLog.length > 10) {
      this.lifecycleLog.pop()
    }
  }
}
```

### 3.3 自定义标题栏

```typescript
@ComponentV2
struct CustomTitleBarExample {
  @Param navPathStack: NavPathStack = new NavPathStack()
  @Local title: string = '自定义标题'

  build() {
    NavDestination() {
      Column({ space: 16 }) {
        Text('自定义标题栏示例')
          .fontSize(24)

        Button('修改标题')
          .onClick(() => {
            this.title = `标题 - ${Math.floor(Math.random() * 100)}`
          })
      }
      .justifyContent(FlexAlign.Center)
    }
    .title(this.title)
    .subtitle('这是副标题')
    .titleBackgroundColor('#007DFF')
  }
}
```

### 3.4 隐藏标题栏

```typescript
@ComponentV2
struct NoTitleBarExample {
  @Param navPathStack: NavPathStack = new NavPathStack()

  build() {
    NavDestination() {
      Column({ space: 16 }) {
        // 自定义顶部栏
        Row() {
          Button('返回')
            .onClick(() => {
              this.navPathStack.pop()
            })
          Text('自定义标题栏')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .layoutWeight(1)
            .textAlign(TextAlign.Center)
          Blank()
            .width(60) // 占位，保持标题居中
        }
        .width('100%')
        .height(56)
        .padding({ left: 16, right: 16 })
        .backgroundColor('#FFFFFF')
        .shadow({ radius: 4, color: '#E0E0E0' })

        // 内容区
        Column() {
          Text('无标题栏页面')
            .fontSize(24)
            .margin({ top: 20 })
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      }
      .width('100%')
      .height('100%')
    }
    .hideTitleBar(true)
  }
}
```

### 3.5 对话框模式

```typescript
@ComponentV2
struct DialogModeExample {
  @Param navPathStack: NavPathStack = new NavPathStack()
  @Local userInput: string = ''

  build() {
    NavDestination() {
      Column({ space: 16 }) {
        Text('确认操作')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)

        Text('确定要执行此操作吗？')
          .fontSize(16)
          .fontColor('#666666')

        TextInput({ placeholder: '请输入备注', text: this.userInput })
          .onChange((value: string) => {
            this.userInput = value
          })

        Row({ space: 12 }) {
          Button('取消')
            .width('48%')
            .backgroundColor('#6C757D')
            .onClick(() => {
              this.navPathStack.pop()
            })

          Button('确认')
            .width('48%')
            .backgroundColor('#007DFF')
            .onClick(() => {
              console.info(`用户确认: ${this.userInput}`)
              this.navPathStack.pop()
            })
        }
        .width('100%')
      }
      .width('100%')
      .padding(24)
      .backgroundColor('#FFFFFF')
      .borderRadius(12)
    }
    .title('对话框')
    .mode(NavDestinationMode.DIALOG)
  }
}
```

### 3.6 模态页面

```typescript
@ComponentV2
struct ModalModeExample {
  @Param navPathStack: NavPathStack = new NavPathStack()
  @Local selectedOption: string = ''

  build() {
    NavDestination() {
      Column({ space: 16 }) {
        Text('选择选项')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)

        ForEach(['选项1', '选项2', '选项3'], (option: string) => {
          Row() {
            Text(option)
              .fontSize(16)
              .layoutWeight(1)
            if (this.selectedOption === option) {
              Text('\uE6DB') // 选中图标
                .fontSize(20)
                .fontColor('#007DFF')
            }
          }
          .width('100%')
          .padding(16)
          .backgroundColor('#F5F5F5')
          .borderRadius(8)
          .onClick(() => {
            this.selectedOption = option
            setTimeout(() => {
              this.navPathStack.pop()
            }, 300)
          })
        })

        Button('取消')
          .width('100%')
          .backgroundColor('#E0E0E0')
          .fontColor('#333333')
          .onClick(() => {
            this.navPathStack.pop()
          })
      }
      .width('100%')
      .padding(24)
    }
    .title('选择')
    .mode(NavDestinationMode.MODAL)
  }
}
```

### 3.7 带参数的 NavDestination

```typescript
// 定义参数接口
interface PageParams {
  userId: number
  userName: string
  fromPage: string
}

@ComponentV2
struct ParameterNavDestinationExample {
  @Param navPathStack: NavPathStack = new NavPathStack()
  @Param params: PageParams | null = null

  build() {
    NavDestination() {
      Column({ space: 16 }) {
        Text('参数传递示例')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)

        if (this.params) {
          Column({ space: 12 }) {
            Text(`用户ID: ${this.params.userId}`)
              .fontSize(16)
            Text(`用户名: ${this.params.userName}`)
              .fontSize(16)
            Text(`来源页面: ${this.params.fromPage}`)
              .fontSize(16)
          }
          .width('100%')
          .padding(16)
          .backgroundColor('#F5F5F5')
          .borderRadius(8)
        } else {
          Text('未接收到参数')
            .fontSize(16)
            .fontColor('#666666')
        }

        Button('返回')
          .onClick(() => {
            this.navPathStack.pop()
          })
      }
      .width('100%')
      .height('100%')
      .padding(16)
      .justifyContent(FlexAlign.Center)
    }
    .title('参数详情')
  }
}
```

### 3.8 自定义转场动画

```typescript
@ComponentV2
struct TransitionNavDestinationExample {
  @Param navPathStack: NavPathStack = new NavPathStack()

  build() {
    NavDestination() {
      Column({ space: 16 }) {
        Text('自定义转场动画')
          .fontSize(24)

        ForEach(['页面1', '页面2', '页面3'], (page: string) => {
          Button(`跳转到${page}`)
            .onClick(() => {
              this.navPathStack.pushPathByName(page, null)
            })
        })

        Button('返回')
          .onClick(() => {
            this.navPathStack.pop()
          })
      }
      .justifyContent(FlexAlign.Center)
    }
    .title('转场动画示例')
    .transition(TransitionEffect.IDENTITY.animation({
      duration: 300,
      curve: curves.initCurve(curves.Curve.EaseInOut)
    }))
  }
}
```

### 3.9 页面结果返回

```typescript
@ComponentV2
struct ResultNavDestinationExample {
  @Param navPathStack: NavPathStack = new NavPathStack()
  @Local selectedItem: string = ''

  build() {
    NavDestination() {
      Column({ space: 16 }) {
        Text('选择一项')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)

        ForEach(['选项A', '选项B', '选项C'], (option: string) => {
          Row() {
            Text(option)
              .fontSize(16)
              .layoutWeight(1)
          }
          .width('100%')
          .padding(16)
          .backgroundColor(this.selectedItem === option ? '#E3F2FD' : '#F5F5F5')
          .borderRadius(8)
          .onClick(() => {
            this.selectedItem = option
            // 返回结果
            this.navPathStack.pop({
              result: option,
              timestamp: Date.now()
            })
          })
        })
      }
      .width('100%')
      .padding(16)
    }
    .title('选择')
  }
}

// 使用示例
@ComponentV2
struct ParentPage {
  @Local navPathStack: NavPathStack = new NavPathStack()
  @Local result: string = ''

  build() {
    Navigation(this.navPathStack) {
      Column({ space: 16 }) {
        Text(`选择结果: ${this.result}`)
          .fontSize(18)

        Button('打开选择页面')
          .onClick(() => {
            this.navPathStack.pushPathByName('ResultPage', null)
          })
      }
      .justifyContent(FlexAlign.Center)
    }
    .navDestination(this.PageBuilder)
    .onReady((context: NavigationContext) => {
      // 监听页面返回结果
      context.pathStack.on('pop', (info: PopInfo) => {
        if (info.result) {
          this.result = info.result.result as string
        }
      })
    })
  }

  @Builder
  PageBuilder(name: string, params: Object) {
    if (name === 'ResultPage') {
      ResultNavDestinationExample({ navPathStack: this.navPathStack })
    }
  }
}
```

## 四、高级用法

### 4.1 页面间数据共享

```typescript
@ObservedV2
class SharedData {
  @Trace counter: number = 0
  @Trace message: string = ''
}

@ComponentV2
struct Page1WithSharedData {
  @Param navPathStack: NavPathStack = new NavPathStack()
  @Param sharedData: SharedData = new SharedData()

  build() {
    NavDestination() {
      Column({ space: 16 }) {
        Text('页面1')
          .fontSize(24)
        Text(`计数器: ${this.sharedData.counter}`)
          .fontSize(18)
        Button('增加')
          .onClick(() => {
            this.sharedData.counter++
          })
        Button('前往页面2')
          .onClick(() => {
            this.navPathStack.pushPathByName('Page2', null)
          })
      }
      .justifyContent(FlexAlign.Center)
    }
    .title('页面1')
  }
}
```

### 4.2 页面状态保存与恢复

```typescript
@ComponentV2
struct StatefulNavDestinationExample {
  @Param navPathStack: NavPathStack = new NavPathStack()
  @Local scrollOffset: number = 0
  @Local inputText: string = ''

  build() {
    NavDestination() {
      Column({ space: 16 }) {
        TextInput({ placeholder: '输入内容', text: this.inputText })
          .onChange((value: string) => {
            this.inputText = value
          })

        Scroll() {
          Column() {
            ForEach(Array.from({ length: 50 }, (_, i) => i + 1), (item: number) => {
              Text(`项目 ${item}`)
                .fontSize(16)
                .padding(8)
                .width('100%')
            })
          }
          .width('100%')
          .onScroll((xOffset: number, yOffset: number) => {
            this.scrollOffset = yOffset
          })
        }
        .width('100%')
        .layoutWeight(1)
      }
      .width('100%')
      .padding(16)
    }
    .title('状态保存')
    .onShown(() => {
      // 恢复状态
      console.info(`恢复滚动位置: ${this.scrollOffset}`)
    })
  }
}
```

## 五、最佳实践

### 5.1 生命周期管理

```typescript
// ✅ 推荐：合理使用生命周期
.onReady(() => {
  // 初始化数据
  this.loadData()
})
.onShown(() => {
  // 恢复动画、定时器等
})
.onHidden(() => {
  // 暂停动画、定时器等
})

// ❌ 避免：在生命周期中进行耗时操作
.onReady(() => {
  // 同步网络请求（会阻塞UI）
  const data = this.fetchDataSync()
})
```

### 5.2 参数传递

```typescript
// ✅ 推荐：使用接口定义参数类型
interface DetailParams {
  id: number
  title: string
}

@Param params: DetailParams = { id: 0, title: '' }

// ❌ 避免：使用 any 类型
@Param params: any = null
```

### 5.3 页面模式选择

```typescript
// ✅ 推荐：根据场景选择合适的模式
// 标准页面
NavDestination() { /* 内容 */ }
  .mode(NavDestinationMode.STANDARD)

// 确认对话框
NavDestination() { /* 内容 */ }
  .mode(NavDestinationMode.DIALOG)

// 选择器模态页
NavDestination() { /* 内容 */ }
  .mode(NavDestinationMode.MODAL)
```

## 六、常见问题

### Q1: NavDestination 与普通页面有什么区别？

**答**: NavDestination 是专门为导航设计的页面容器，提供完整的生命周期管理、标题栏配置、转场动画等功能。

### Q2: 如何隐藏默认的返回按钮？

**答**: 使用 `.hideBackButton(true)` 属性。

### Q3: 如何自定义标题栏样式？

**答**: 使用 `.titleBackgroundColor()` 等属性，或完全隐藏标题栏自行实现。

### Q4: NavDestination 可以嵌套使用吗？

**答**: NavDestination 本身不支持嵌套，但可以在其内容中包含其他导航组件。

### Q5: 如何监听页面返回事件？

**答**: 使用 `onWillDisappear` 或 `onWillHide` 生命周期回调。

## 七、版本兼容性

| API 版本 | 支持状态 | 备注 |
|----------|----------|------|
| API 12+ | ✅ | NavDestination 组件首次引入 |
| API 18+ | ✅ | 增强生命周期回调 |

## 八、参考资料

- [NavDestination - 华为开发者官方文档](https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V5/ts-basic-components-navdestination-V5)
- [Navigation 组件 - 华为开发者](https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V5/ts-basic-components-navigation-V5)
- [页面路由 - 华为开发者](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides-V5/arkts-navigation-navigation-V5)
