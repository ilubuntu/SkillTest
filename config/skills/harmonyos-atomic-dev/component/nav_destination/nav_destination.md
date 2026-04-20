# NavDestination 组件 HarmonyOS 6.0 开发 Skill

## 概述

NavDestination 是 OpenHarmony 中用于实现页面导航的目标容器组件，通常与 Navigation 组件配合使用。它表示导航栈中的具体页面内容，支持标准模式和弹窗模式，并提供丰富的页面切换动画和生命周期管理。

## 重要说明

- **导航容器**: NavDestination 必须作为 Navigation 组件的子组件使用
- **页面栈管理**: 通过 NavPathStack 管理页面的 push、pop、replace 等操作
- **生命周期**: 提供完整的页面生命周期回调（onAppear、onDisappear、onShown、onHidden）
- **双模式**: 支持标准模式（STANDARD）和弹窗模式（DIALOG）
- **转场动画**: 内置多种转场动画，支持自定义共享元素转场

## 模块信息

- **组件名称**: NavDestination
- **SDK 版本**: HarmonyOS 6.0 (API 12+)
- **系统能力**: SystemCapability.ArkUI.ArkUI.Full
- **更新日期**: 2026-02-24
- **官方文档**:
  - [NavDestination - 华为开发者](https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V5/ts-basic-components-navdestination-V5)
  - [Navigation - 华为开发者](https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V5/ts-basic-components-navigation-V5)

## 一、组件基础

### 1.1 导入方式

```typescript
// NavDestination 是内置组件，无需导入
// 直接使用即可
Navigation(navPathStack) {
  NavDestination() {
    // 页面内容
  }
}
```

### 1.2 基础用法

```typescript
// 创建导航栈
@Local navPathStack: NavPathStack = new NavPathStack()

// 定义 NavDestination 页面
@Builder
function MyPage(name: string, params: Object) {
  NavDestination() {
    Column() {
      Text('页面内容')
    }
  }
  .title('页面标题')
  .mode(NavDestinationMode.STANDARD)
}

// 使用 Navigation 容器
Navigation(this.navPathStack) {
  // 首页内容
}
.navDestination(MyPage)

// 导航到新页面
this.navPathStack.pushPathByName('MyPage', params)
```

## 二、API 参数

### 2.1 构造参数

NavDestination 组件不需要构造参数，直接使用即可。

### 2.2 NavDestination 属性

| 属性 | 类型 | 默认值 | 描述 |
|------|------|--------|------|
| `title` | `string` | - | 页面标题 |
| `subtitle` | `string` | - | 页面副标题 |
| `mode` | `NavDestinationMode` | STANDARD | 页面显示模式 |
| `hideTitleBar` | `boolean` | false | 是否隐藏标题栏 |
| `leading` | `CustomBuilder` | - | 标题栏前置自定义组件 |
| `trailing` | `CustomBuilder` | - | 标题栏后置自定义组件 |

### 2.3 NavDestinationMode 枚举

| 值 | 描述 | 使用场景 |
|----|------|----------|
| `STANDARD` | 标准全屏模式 | 普通页面导航 |
| `DIALOG` | 弹窗模式 | 弹窗式页面，带半透明背景 |
| `MODAL` | 模态窗口模式 | API 12+，模态展示 |

### 2.4 NavDestination 生命周期

| 生命周期 | 触发时机 |
|----------|----------|
| `onAppear()` | 页面即将显示时 |
| `onDisappear()` | 页面即将消失时 |
| `onShown()` | 页面完全显示后 |
| `onHidden()` | 页面完全隐藏后 |

### 2.5 NavPathStack 方法

| 方法 | 参数 | 描述 |
|------|------|------|
| `pushPath()` | `path: string, params: Object` | 压栈新页面 |
| `pushPathByName()` | `name: string, params: Object` | 通过名称压栈页面 |
| `pop()` | - | 出栈当前页面 |
| `popToName()` | `name: string` | 出栈到指定页面 |
| `popToIndex()` | `index: number` | 出栈到指定索引 |
| `replacePath()` | `path: string, params: Object` | 替换当前页面 |
| `replacePathByName()` | `name: string, params: Object` | 通过名称替换页面 |
| `clear()` | - | 清空页面栈 |
| `getAllPathName()` | - | 获取所有页面名称 |
| `size()` | - | 获取页面栈大小 |

## 三、使用示例

### 3.1 基础 NavDestination

```typescript
@ComponentV2
struct BasicNavDestinationExample {
  @Local navPathStack: NavPathStack = new NavPathStack()

  build() {
    Column({ space: 16 }) {
      Text('基础 NavDestination')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)

      Navigation(this.navPathStack) {
        Column({ space: 12 }) {
          Text('首页内容')
            .fontSize(16)

          Button('跳转到详情页')
            .onClick(() => {
              this.navPathStack.pushPathByName('DetailPage', { id: 123 })
            })
        }
        .width('100%')
        .padding(20)
      }
      .navDestination(this.PageBuilder)
      .height(300)
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#F5F5F5')
    .borderRadius(12)
  }

  @Builder
  PageBuilder(name: string, params: Object) {
    if (name === 'DetailPage') {
      NavDestination() {
        Column({ space: 12 }) {
          Text('详情页')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
          Text(`参数: ${JSON.stringify(params)}`)
            .fontSize(14)
          Button('返回')
            .onClick(() => {
              this.navPathStack.pop()
            })
        }
        .width('100%')
        .padding(20)
      }
      .title('详情页')
      .mode(NavDestinationMode.STANDARD)
    }
  }
}
```

### 3.2 弹窗模式 NavDestination

```typescript
@ComponentV2
struct DialogNavDestinationExample {
  @Local navPathStack: NavPathStack = new NavPathStack()

  build() {
    Column({ space: 16 }) {
      Text('弹窗模式 NavDestination')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)

      Navigation(this.navPathStack) {
        Button('打开弹窗页面')
          .onClick(() => {
            this.navPathStack.pushPathByName('DialogPage', null)
          })
      }
      .navDestination(this.PageBuilder)
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#F5F5F5')
    .borderRadius(12)
  }

  @Builder
  PageBuilder(name: string, params: Object) {
    if (name === 'DialogPage') {
      NavDestination() {
        Column({ space: 16 }) {
          Text('弹窗页面内容')
            .fontSize(16)

          Button('关闭')
            .onClick(() => {
              this.navPathStack.pop()
            })
        }
        .width('100%')
        .padding(20)
        .backgroundColor(Color.White)
        .borderRadius(12)
      }
      .title('弹窗标题')
      .mode(NavDestinationMode.DIALOG)
    }
  }
}
```

### 3.3 自定义标题栏

```typescript
@ComponentV2
struct CustomTitleBarExample {
  @Local navPathStack: NavPathStack = new NavPathStack()

  build() {
    Column({ space: 16 }) {
      Navigation(this.navPathStack) {
        Button('打开自定义标题栏页面')
          .onClick(() => {
            this.navPathStack.pushPathByName('CustomTitlePage', null)
          })
      }
      .navDestination(this.PageBuilder)
      .height(400)
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#F5F5F5')
    .borderRadius(12)
  }

  @Builder
  PageBuilder(name: string, params: Object) {
    if (name === 'CustomTitlePage') {
      NavDestination() {
        Column() {
          Text('页面内容')
            .fontSize(16)
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
      }
      .title('自定义标题')
      .subtitle('副标题')
      .leading(() => {
        // 自定义返回按钮
        Button('返回')
          .fontSize(14)
          .onClick(() => {
            this.navPathStack.pop()
          })
      })
      .trailing(() => {
        // 自定义右侧按钮
        Row({ space: 8 }) {
          Button('分享')
            .fontSize(14)
          Button('设置')
            .fontSize(14)
        }
      })
    }
  }
}
```

### 3.4 页面栈操作

```typescript
@ComponentV2
struct StackOperationsExample {
  @Local navPathStack: NavPathStack = new NavPathStack()
  @Local stackSize: number = 1

  build() {
    Column({ space: 16 }) {
      Text('页面栈操作')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)

      Navigation(this.navPathStack) {
        Column({ space: 12 }) {
          Text(`当前栈大小: ${this.stackSize}`)
            .fontSize(14)

          Row({ space: 8 }) {
            Button('Push A')
              .onClick(() => {
                this.navPathStack.pushPathByName('PageA', null)
                this.updateStackSize()
              })

            Button('Push B')
              .onClick(() => {
                this.navPathStack.pushPathByName('PageB', null)
                this.updateStackSize()
              })
          }

          Row({ space: 8 }) {
            Button('Pop')
              .onClick(() => {
                this.navPathStack.pop()
                this.updateStackSize()
              })

            Button('PopTo A')
              .onClick(() => {
                this.navPathStack.popToName('PageA')
                this.updateStackSize()
              })

            Button('Clear')
              .onClick(() => {
                this.navPathStack.clear()
                this.updateStackSize()
              })
          }
        }
      }
      .navDestination(this.PageBuilder)
      .height(400)
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#F5F5F5')
    .borderRadius(12)
  }

  @Builder
  PageBuilder(name: string, params: Object) {
    if (name === 'PageA') {
      NavDestination() {
        Column({ space: 12 }) {
          Text('页面 A')
            .fontSize(20)
          Button('返回')
            .onClick(() => {
              this.navPathStack.pop()
              this.updateStackSize()
            })
        }
        .width('100%')
        .padding(20)
      }
      .title('Page A')
    } else if (name === 'PageB') {
      NavDestination() {
        Column({ space: 12 }) {
          Text('页面 B')
            .fontSize(20)
          Button('返回')
            .onClick(() => {
              this.navPathStack.pop()
              this.updateStackSize()
            })
        }
        .width('100%')
        .padding(20)
      }
      .title('Page B')
    }
  }

  private updateStackSize(): void {
    this.stackSize = this.navPathStack.size()
  }
}
```

### 3.5 页面参数传递

```typescript
interface UserDetailParams {
  id: number
  name: string
  avatar: string
}

@ComponentV2
struct ParamsPassingExample {
  @Local navPathStack: NavPathStack = new NavPathStack()

  build() {
    Column({ space: 16 }) {
      Navigation(this.navPathStack) {
        Column({ space: 12 }) {
          Button('查看用户详情')
            .onClick(() => {
              const params: UserDetailParams = {
                id: 1001,
                name: '张三',
                avatar: '/common/avatar.png'
              }
              this.navPathStack.pushPathByName('UserDetail', params)
            })
        }
      }
      .navDestination(this.PageBuilder)
      .height(400)
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#F5F5F5')
    .borderRadius(12)
  }

  @Builder
  PageBuilder(name: string, params: Object) {
    if (name === 'UserDetail') {
      NavDestination() {
        Column({ space: 16 }) {
          Image((params as UserDetailParams).avatar)
            .width(80)
            .height(80)
            .borderRadius(40)

          Text(`ID: ${(params as UserDetailParams).id}`)
            .fontSize(14)
            .fontColor('#666666')

          Text(`姓名: ${(params as UserDetailParams).name}`)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)

          Button('返回')
            .onClick(() => {
              this.navPathStack.pop()
            })
        }
        .width('100%')
        .padding(20)
      }
      .title('用户详情')
    }
  }
}
```

### 3.6 生命周期管理

```typescript
@ComponentV2
struct LifecycleExample {
  @Local navPathStack: NavPathStack = new NavPathStack()
  @Local lifecycleLogs: string[] = []

  build() {
    Column({ space: 16 }) {
      Text('生命周期示例')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)

      Navigation(this.navPathStack) {
        Button('打开页面')
          .onClick(() => {
            this.navPathStack.pushPathByName('LifecyclePage', null)
          })
      }
      .navDestination(this.PageBuilder)
      .height(400)

      // 显示生命周期日志
      Column({ space: 4 }) {
        Text('生命周期日志:')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)

        ForEach(this.lifecycleLogs, (log: string, index: number) => {
          Text(log)
            .fontSize(12)
            .fontColor('#666666')
        })
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')
      .padding(12)
      .backgroundColor('#FFFFFF')
      .borderRadius(8)
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#F5F5F5')
    .borderRadius(12)
  }

  @Builder
  PageBuilder(name: string, params: Object) {
    if (name === 'LifecyclePage') {
      NavDestination() {
        LifecyclePageContent({
          onLifecycle: (event: string) => {
            this.lifecycleLogs.unshift(`${new Date().toLocaleTimeString()} - ${event}`)
            if (this.lifecycleLogs.length > 5) {
              this.lifecycleLogs.pop()
            }
          }
        })
      }
      .title('生命周期测试')
      .onAppear(() => {
        console.info('NavDestination onAppear')
      })
      .onDisappear(() => {
        console.info('NavDestination onDisappear')
      })
    }
  }
}

@ComponentV2
struct LifecyclePageContent {
  @Param onLifecycle: (event: string) => void = () => {}

  aboutToAppear(): void {
    this.onLifecycle('aboutToAppear')
  }

  aboutToDisappear(): void {
    this.onLifecycle('aboutToDisappear')
  }

  build() {
    Column({ space: 12 }) {
      Text('生命周期测试页面')
        .fontSize(16)

      Button('测试 onShown')
        .onClick(() => {
          this.onLifecycle('onShown')
        })

      Button('测试 onHidden')
        .onClick(() => {
          this.onLifecycle('onHidden')
        })
    }
    .width('100%')
    .padding(20)
  }
}
```

### 3.7 页面替换

```typescript
@ComponentV2
struct ReplacePageExample {
  @Local navPathStack: NavPathStack = new NavPathStack()

  build() {
    Column({ space: 16 }) {
      Navigation(this.navPathStack) {
        Column({ space: 12 }) {
          Text('首页')
            .fontSize(20)

          Row({ space: 8 }) {
            Button('Push 页面 A')
              .onClick(() => {
                this.navPathStack.pushPathByName('PageA', null)
              })

            Button('Replace 页面 B')
              .onClick(() => {
                this.navPathStack.replacePathByName('PageB', null)
              })
          }
        }
      }
      .navDestination(this.PageBuilder)
      .height(400)
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#F5F5F5')
    .borderRadius(12)
  }

  @Builder
  PageBuilder(name: string, params: Object) {
    if (name === 'PageA') {
      NavDestination() {
        Column({ space: 12 }) {
          Text('页面 A')
            .fontSize(20)
          Button('返回')
            .onClick(() => {
              this.navPathStack.pop()
            })
          Button('Replace 为页面 B')
            .onClick(() => {
              this.navPathStack.replacePathByName('PageB', null)
            })
        }
        .width('100%')
        .padding(20)
      }
      .title('Page A')
    } else if (name === 'PageB') {
      NavDestination() {
        Column({ space: 12 }) {
          Text('页面 B')
            .fontSize(20)
          Button('返回')
            .onClick(() => {
              this.navPathStack.pop()
            })
        }
        .width('100%')
        .padding(20)
      }
      .title('Page B')
    }
  }
}
```

### 3.8 隐藏标题栏

```typescript
@ComponentV2
struct HideTitleBarExample {
  @Local navPathStack: NavPathStack = new NavPathStack()

  build() {
    Column({ space: 16 }) {
      Navigation(this.navPathStack) {
        Button('打开无标题栏页面')
          .onClick(() => {
            this.navPathStack.pushPathByName('NoTitlePage', null)
          })
      }
      .navDestination(this.PageBuilder)
      .height(400)
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#F5F5F5')
    .borderRadius(12)
  }

  @Builder
  PageBuilder(name: string, params: Object) {
    if (name === 'NoTitlePage') {
      NavDestination() {
        Column({ space: 12 }) {
          Text('无标题栏页面')
            .fontSize(20)

          Button('关闭')
            .onClick(() => {
              this.navPathStack.pop()
            })
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
      }
      .hideTitleBar(true)
    }
  }
}
```

## 四、高级用法

### 4.1 自定义转场动画

```typescript
@ComponentV2
struct CustomTransitionExample {
  @Local navPathStack: NavPathStack = new NavPathStack()

  build() {
    Column({ space: 16 }) {
      Navigation(this.navPathStack) {
        Button('打开自定义转场页面')
          .onClick(() => {
            this.navPathStack.pushPathByName('CustomTransitionPage', {
              transition: PageTransitionType.Slide
            })
          })
      }
      .navDestination(this.PageBuilder)
      .height(400)
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#F5F5F5')
    .borderRadius(12)
  }

  @Builder
  PageBuilder(name: string, params: Object) {
    if (name === 'CustomTransitionPage') {
      NavDestination() {
        Column({ space: 12 }) {
          Text('自定义转场动画')
            .fontSize(20)
          Button('返回')
            .onClick(() => {
              this.navPathStack.pop()
            })
        }
        .width('100%')
        .padding(20)
      }
      .title('自定义转场')
      .pageTransition(PageTransitionType.Slide)
    }
  }
}
```

### 4.2 嵌套导航

```typescript
@ComponentV2
struct NestedNavigationExample {
  @Local parentNavStack: NavPathStack = new NavPathStack()

  build() {
    Navigation(this.parentNavStack) {
      Column({ space: 12 }) {
        Text('父导航容器')
          .fontSize(20)

        Button('打开子导航页面')
          .onClick(() => {
            this.parentNavStack.pushPathByName('ChildNavPage', null)
          })
      }
    }
    .navDestination(this.ParentPageBuilder)
  }

  @Builder
  ParentPageBuilder(name: string, params: Object) {
    if (name === 'ChildNavPage') {
      NavDestination() {
        ChildNavigationPage()
      }
      .title('子导航')
    }
  }
}

@ComponentV2
struct ChildNavigationPage {
  @Local childNavStack: NavPathStack = new NavPathStack()

  build() {
    Navigation(this.childNavStack) {
      Column({ space: 12 }) {
        Text('子导航容器内容')
          .fontSize(16)

        Button('打开子页面')
          .onClick(() => {
            this.childNavStack.pushPathByName('ChildPage', null)
          })
      }
    }
    .navDestination(this.ChildPageBuilder)
  }

  @Builder
  ChildPageBuilder(name: string, params: Object) {
    if (name === 'ChildPage') {
      NavDestination() {
        Column({ space: 12 }) {
          Text('子页面')
            .fontSize(16)
          Button('返回')
            .onClick(() => {
              this.childNavStack.pop()
            })
        }
        .width('100%')
        .padding(20)
      }
      .title('子页面')
    }
  }
}
```

### 4.3 页面返回结果

```typescript
@ComponentV2
struct PageResultExample {
  @Local navPathStack: NavPathStack = new NavPathStack()
  @Local result: string = ''

  build() {
    Column({ space: 16 }) {
      Navigation(this.navPathStack) {
        Column({ space: 12 }) {
          Button('打开选择页面')
            .onClick(() => {
              this.navPathStack.pushPathByName('SelectionPage', {
                onResult: (data: string) => {
                  this.result = data
                }
              })
            })

          if (this.result) {
            Text(`选择结果: ${this.result}`)
              .fontSize(14)
          }
        }
      }
      .navDestination(this.PageBuilder)
      .height(400)
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#F5F5F5')
    .borderRadius(12)
  }

  @Builder
  PageBuilder(name: string, params: Object) {
    if (name === 'SelectionPage') {
      NavDestination() {
        SelectionPageContent({
          params: params as SelectionPageParams
        })
      }
      .title('选择')
    }
  }
}

interface SelectionPageParams {
  onResult: (data: string) => void
}

@ComponentV2
struct SelectionPageContent {
  @Param params: SelectionPageParams

  build() {
    Column({ space: 12 }) {
      Button('选项 A')
        .onClick(() => {
          this.params.onResult('选项 A')
          // 返回上一页
        })

      Button('选项 B')
        .onClick(() => {
          this.params.onResult('选项 B')
          // 返回上一页
        })

      Button('选项 C')
        .onClick(() => {
          this.params.onResult('选项 C')
          // 返回上一页
        })
    }
    .width('100%')
    .padding(20)
  }
}
```

## 五、最佳实践

### 5.1 页面命名规范

```typescript
// ✅ 推荐: 使用描述性的页面名称
const PAGE_USER_DETAIL = 'UserDetailPage'
const PAGE_SETTINGS = 'SettingsPage'

// ❌ 避免: 使用无意义的名称
const PAGE_1 = 'Page1'
const PAGE_ABC = 'ABC'
```

### 5.2 参数类型定义

```typescript
// ✅ 推荐: 定义明确的接口
interface UserDetailParams {
  id: number
  name: string
  avatar?: string
}

interface ListPageParams {
  category: string
  page: number
  sortType?: 'asc' | 'desc'
}

// ❌ 避免: 直接使用 Object
function getPageParams(): Object {
  return { id: 123, name: 'test' }
}
```

### 5.3 页面栈管理

```typescript
// ✅ 推荐: 在适当时机清理页面栈
class NavigationManager {
  private navStack: NavPathStack

  navigateToHome(): void {
    // 清空栈并导航到首页
    this.navStack.clear()
    this.navStack.pushPathByName('HomePage', null)
  }

  navigateToMain(): void {
    // 返回到主页面（保留首页）
    this.navStack.popToName('HomePage')
  }
}
```

### 5.4 内存优化

```typescript
// ✅ 推荐: 及时清理大对象
@ComponentV2
struct HeavyPage {
  @Local largeData: any[] = []
  @Local navPathStack: NavPathStack

  aboutToDisappear(): void {
    // 清理大对象
    this.largeData = []
  }

  build() {
    NavDestination() {
      // 页面内容
    }
  }
}
```

## 六、常见问题

### Q1: NavDestination 和 Page 的区别？

**答案**:
- **Page**: 使用 @Entry 装饰器，是应用的顶级页面
- **NavDestination**: 嵌入在 Navigation 容器中的子页面，可以灵活管理页面栈

### Q2: 如何实现类似 Android startActivityForResult 的功能？

**解决方案**: 使用回调函数传递结果
```typescript
// 发起页面
this.navStack.pushPathByName('ResultPage', {
  onResult: (result: any) => {
    console.info('收到结果:', result)
  }
})

// 结果页面
interface ResultPageParams {
  onResult: (result: any) => void
}

@ComponentV2
struct ResultPage {
  @Param params: ResultPageParams

  finishWithResult(result: any): void {
    this.params.onResult(result)
    this.navStack.pop()
  }
}
```

### Q3: NavDestination 如何获取父组件的导航栈？

**解决方案**: 通过参数传递或使用全局单例
```typescript
// 方式1: 通过参数传递
this.navStack.pushPathByName('ChildPage', {
  parentNavStack: this.navStack
})

// 方式2: 使用全局单例
class NavigationManager {
  static getInstance(): NavigationManager {
    // 单例实现
  }
}
```

### Q4: 如何实现页面缓存？

**解决方案**: 使用 @ObservedV2 装饰的缓存管理器
```typescript
@ObservedV2
class PageCacheManager {
  @Trace cache: Map<string, any> = new Map()

  get(key: string): any {
    return this.cache.get(key)
  }

  set(key: string, value: any): void {
    this.cache.set(key, value)
  }
}
```

## 七、版本兼容性

| API 版本 | NavDestination | Navigation | NavPathStack |
|----------|----------------|------------|--------------|
| API 9 | ❌ | ✅ | ❌ |
| API 10 | ✅ | ✅ | ✅ |
| API 11 | ✅ | ✅ | ✅ |
| API 12+ | ✅ | ✅ | ✅ |

## 八、参考资料

### 官方文档
- [NavDestination - 华为开发者](https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V5/ts-basic-components-navdestination-V5)
- [Navigation - 华为开发者](https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V5/ts-basic-components-navigation-V5)
- [NavPathStack - 华为开发者](https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V5/ts-basic-components-navigation-navpathstack-V5)

### 相关组件
- [Router 路由](https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V5/ts-basic-components-router-V5)
- [NavRouter - 华为开发者](https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V5/ts-basic-components-navrouter-V5)
