# Navigation 组件 HarmonyOS 6.0 开发 Skill

## 概述

Navigation 组件是 OpenHarmony 中用于管理页面导航的核心容器组件。它提供了完整的导航栈管理、页面切换动画、路由拦截等功能，是 HarmonyOS 6.0 推荐的导航方案。Navigation 组件通常与 NavDestination 和 NavPathStack 配合使用，实现声明式路由导航。

## 重要说明

- **核心组件**: Navigation 是 HarmonyOS 6.0 的核心导航容器
- **路由模式**: 支持声明式路由和命令式路由两种模式
- **页面管理**: 通过 NavPathStack 管理页面栈
- **导航模式**: 支持单页面、分栏、标签页等多种导航模式
- **转场动画**: 内置丰富的页面转场动画
- **生命周期**: 完整的页面生命周期管理

## 模块信息

- **组件名称**: Navigation
- **SDK 版本**: HarmonyOS 6.0 (API 12+)
- **系统能力**: SystemCapability.ArkUI.ArkUI.Full
- **更新日期**: 2026-02-24
- **官方文档**:
  - [Navigation 导航 - 华为开发者](https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V5/ts-basic-components-navigation-V5)

## 一、组件基础

### 1.1 导入方式

```typescript
// Navigation 是内置组件，无需导入
// 但需要导入 NavPathStack 和相关类型
import { NavPathStack, NavDestination } from '@kit.ArkUI'
```

### 1.2 基础用法

```typescript
@Entry
@ComponentV2
struct NavigationExample {
  // 创建路由栈
  @Local navPathStack: NavPathStack = new NavPathStack()

  // 页面构建器
  @Builder
  PageBuilder(name: string, params: Object) {
    if (name === 'HomePage') {
      HomePage()
    } else if (name === 'DetailPage') {
      DetailPage()
    }
  }

  build() {
    Navigation(this.navPathStack) {
      HomePage({
        onNavigate: () => {
          this.navPathStack.pushPathByName('DetailPage', null)
        }
      })
    }
    .navDestination(this.PageBuilder)
    .title('Navigation 示例')
  }
}
```

## 二、API 参数

### 2.1 构造参数

| 参数 | 类型 | 必填 | 默认值 | 描述 |
|------|------|------|--------|------|
| navPathStack | `NavPathStack` | 是 | - | 路由栈对象，用于管理页面导航 |
| content | `BuilderParam` | 是 | - | 导航内容，通常是主页面的组件 |

### 2.2 导航模式

| 属性 | 类型 | 默认值 | 描述 |
|------|------|--------|------|
| `mode` | `NavigationMode` | NavigationMode.Stack | 导航模式 |
| - NavigationMode.Stack | - | - | 标准栈模式，页面依次入栈 |
| - NavigationMode.Split | - | - | 分栏模式，主次页面并排显示 |
| - NavigationMode.Tab | - | - | 标签页模式 |

### 2.3 标题栏属性

| 属性 | 类型 | 默认值 | 描述 |
|------|------|--------|------|
| `title` | `string \| Resource` | - | 导航标题 |
| `titleMode` | `NavigationTitleMode` | NavigationTitleMode.Free | 标题栏模式 |
| `subtitle` | `string` | - | 副标题 |
| `hideTitleBar` | `boolean` | false | 是否隐藏标题栏 |
| `titleBackgroundColor` | `ResourceColor` | - | 标题栏背景色 |

### 2.4 导航栏属性

| 属性 | 类型 | 默认值 | 描述 |
|------|------|--------|------|
| `navBarPosition` | `NavBarPosition` | NavBarPosition.Start | 导航栏位置 |
| `hideNavBar` | `boolean` | false | 是否隐藏导航栏 |
| `navBarWidth` | `number \| string` | - | 导航栏宽度 |

### 2.5 页面配置

| 属性 | 类型 | 默认值 | 描述 |
|------|------|--------|------|
| `navDestination` | `BuilderParam` | - | 页面构建器，用于创建页面内容 |
| `onReady` | `(context: NavigationContext) => void` | - | 导航就绪回调 |

### 2.6 转场动画

| 属性 | 类型 | 默认值 | 描述 |
|------|------|--------|------|
| `transition` | `NavigationTransition` | - | 自定义转场动画 |
| `defaultTransition` | `NavigationTransition` | - | 默认转场动画 |

### 2.7 NavPathStack 方法

| 方法 | 参数 | 返回值 | 描述 |
|------|------|--------|------|
| `pushPathByName` | name: string, param: Object, animated: boolean | string | 通过名称推送页面到栈顶 |
| `pushPath` | path: NavPath, animated: boolean | string | 推送路径到栈顶 |
| `replacePathByName` | name: string, param: Object, animated: boolean | string | 替换当前页面 |
| `replacePath` | path: NavPath, animated: boolean | string | 替换当前路径 |
| `pop` | animated?: boolean | string | 弹出栈顶页面 |
| `popToName` | name: string, animated: boolean | string | 弹出到指定页面 |
| `popToIndex` | index: number, animated: boolean | string | 弹出到指定索引 |
| `clear` | animated?: boolean | string | 清空页面栈 |
| `getAllPathName` | - | string[] | 获取所有页面名称 |
| `getPathByName` | name: string | NavPath[] | 获取指定名称的路径 |
| `getParamByName` | name: string | Object | 获取页面参数 |

## 三、使用示例

### 3.1 基础 Navigation 示例

```typescript
@Entry
@ComponentV2
struct BasicNavigationExample {
  @Local navPathStack: NavPathStack = new NavPathStack()

  @Builder
  PageBuilder(name: string, params: Object) {
    if (name === 'Page1') {
      Page1()
    } else if (name === 'Page2') {
      Page2()
    }
  }

  build() {
    Navigation(this.navPathStack) {
      Column({ space: 16 }) {
        Text('首页')
          .fontSize(20)
        Button('跳转到页面1')
          .onClick(() => {
            this.navPathStack.pushPathByName('Page1', null)
          })
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
    }
    .navDestination(this.PageBuilder)
    .title('基础导航')
    .mode(NavigationMode.Stack)
  }
}

@ComponentV2
struct Page1 {
  @Param navPathStack: NavPathStack = new NavPathStack()

  build() {
    NavDestination() {
      Column({ space: 16 }) {
        Text('页面1')
          .fontSize(20)
        Button('返回')
          .onClick(() => {
            this.navPathStack.pop()
          })
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
    }
    .title('页面1')
  }
}
```

### 3.2 带参数传递的导航

```typescript
// 定义参数接口
interface PageParams {
  userId: number
  userName: string
}

@ComponentV2
struct ParameterNavigationExample {
  @Local navPathStack: NavPathStack = new NavPathStack()

  @Builder
  PageBuilder(name: string, params: Object) {
    if (name === 'UserProfile') {
      UserProfile({
        params: params as PageParams,
        navPathStack: this.navPathStack
      })
    }
  }

  build() {
    Navigation(this.navPathStack) {
      Column({ space: 16 }) {
        Button('跳转到用户资料')
          .onClick(() => {
            const params: PageParams = {
              userId: 123,
              userName: '张三'
            }
            this.navPathStack.pushPathByName('UserProfile', params)
          })
      }
      .justifyContent(FlexAlign.Center)
    }
    .navDestination(this.PageBuilder)
    .title('参数传递示例')
  }
}

@ComponentV2
struct UserProfile {
  @Param params: PageParams = { userId: 0, userName: '' }
  @Param navPathStack: NavPathStack = new NavPathStack()

  build() {
    NavDestination() {
      Column({ space: 16 }) {
        Text(`用户ID: ${this.params.userId}`)
          .fontSize(18)
        Text(`用户名: ${this.params.userName}`)
          .fontSize(18)
        Button('返回')
          .onClick(() => {
            this.navPathStack.pop()
          })
      }
      .justifyContent(FlexAlign.Center)
    }
    .title('用户资料')
  }
}
```

### 3.3 分栏导航模式

```typescript
@ComponentV2
struct SplitNavigationExample {
  @Local navPathStack: NavPathStack = new NavPathStack()
  @Local selectedMenu: string = '菜单1'

  @Builder
  PageBuilder(name: string, params: Object) {
    if (name === 'Content1') {
      ContentPage1()
    } else if (name === 'Content2') {
      ContentPage2()
    }
  }

  @Builder
  MenuBuilder() {
    Column({ space: 8 }) {
      ForEach(['菜单1', '菜单2', '菜单3'], (menu: string) => {
        Text(menu)
          .width('100%')
          .padding(12)
          .backgroundColor(this.selectedMenu === menu ? '#E0E0E0' : 'transparent')
          .onClick(() => {
            this.selectedMenu = menu
            if (menu === '菜单1') {
              this.navPathStack.pushPathByName('Content1', null)
            } else if (menu === '菜单2') {
              this.navPathStack.pushPathByName('Content2', null)
            }
          })
      })
    }
    .width('100%')
    .height('100%')
    .padding(8)
  }

  build() {
    Navigation(this.navPathStack) {
      Column() {
        Text('主内容区域')
          .fontSize(20)
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
    }
    .navDestination(this.PageBuilder)
    .mode(NavigationMode.Split)
    .navBarPosition(NavBarPosition.Start)
    .navBarWidth(200)
  }
}
```

### 3.4 自定义转场动画

```typescript
@ComponentV2
struct TransitionNavigationExample {
  @Local navPathStack: NavPathStack = new NavPathStack()

  @Builder
  PageBuilder(name: string, params: Object) {
    if (name === 'Page1') {
      Page1Nav({ navPathStack: this.navPathStack })
    }
  }

  build() {
    Navigation(this.navPathStack) {
      Column({ space: 16 }) {
        Button('查看转场动画')
          .onClick(() => {
            this.navPathStack.pushPathByName('Page1', null, true)
          })
      }
      .justifyContent(FlexAlign.Center)
    }
    .navDestination(this.PageBuilder)
    .title('转场动画示例')
    .defaultTransition({
      transition: TransitionEffect.IDENTITY
        .animation({ duration: 300, curve: curves.initCurve(curves.Curve.EaseInOut) })
    })
  }
}

@ComponentV2
struct Page1Nav {
  @Param navPathStack: NavPathStack = new NavPathStack()

  build() {
    NavDestination() {
      Column({ space: 16 }) {
        Text('页面1')
          .fontSize(24)
        Button('返回')
          .onClick(() => {
            this.navPathStack.pop()
          })
      }
      .justifyContent(FlexAlign.Center)
    }
    .title('页面1')
  }
}
```

### 3.5 页面替换导航

```typescript
@ComponentV2
struct ReplaceNavigationExample {
  @Local navPathStack: NavPathStack = new NavPathStack()

  @Builder
  PageBuilder(name: string, params: Object) {
    if (name === 'Page1') {
      Page1Replace({ navPathStack: this.navPathStack })
    } else if (name === 'Page2') {
      Page2Replace({ navPathStack: this.navPathStack })
    }
  }

  build() {
    Navigation(this.navPathStack) {
      Column({ space: 16 }) {
        Button('跳转到页面1')
          .onClick(() => {
            this.navPathStack.pushPathByName('Page1', null)
          })
      }
      .justifyContent(FlexAlign.Center)
    }
    .navDestination(this.PageBuilder)
    .title('页面替换示例')
  }
}

@ComponentV2
struct Page1Replace {
  @Param navPathStack: NavPathStack = new NavPathStack()

  build() {
    NavDestination() {
      Column({ space: 16 }) {
        Text('页面1')
          .fontSize(24)
        Button('替换为页面2')
          .onClick(() => {
            this.navPathStack.replacePathByName('Page2', null)
          })
        Button('返回')
          .onClick(() => {
            this.navPathStack.pop()
          })
      }
      .justifyContent(FlexAlign.Center)
    }
    .title('页面1')
  }
}

@ComponentV2
struct Page2Replace {
  @Param navPathStack: NavPathStack = new NavPathStack()

  build() {
    NavDestination() {
      Column({ space: 16 }) {
        Text('页面2 (已替换页面1)')
          .fontSize(24)
        Button('返回')
          .onClick(() => {
            this.navPathStack.pop()
          })
      }
      .justifyContent(FlexAlign.Center)
    }
    .title('页面2')
  }
}
```

### 3.6 多级导航返回

```typescript
@ComponentV2
struct MultiLevelNavigationExample {
  @Local navPathStack: NavPathStack = new NavPathStack()

  @Builder
  PageBuilder(name: string, params: Object) {
    if (name === 'Page1') {
      Page1Multi({ navPathStack: this.navPathStack })
    } else if (name === 'Page2') {
      Page2Multi({ navPathStack: this.navPathStack })
    } else if (name === 'Page3') {
      Page3Multi({ navPathStack: this.navPathStack })
    }
  }

  build() {
    Navigation(this.navPathStack) {
      Column({ space: 16 }) {
        Button('开始导航')
          .onClick(() => {
            this.navPathStack.pushPathByName('Page1', null)
          })
      }
      .justifyContent(FlexAlign.Center)
    }
    .navDestination(this.PageBuilder)
    .title('多级导航示例')
  }
}

@ComponentV2
struct Page3Multi {
  @Param navPathStack: NavPathStack = new NavPathStack()

  build() {
    NavDestination() {
      Column({ space: 16 }) {
        Text('页面3')
          .fontSize(24)
        Button('返回到首页')
          .onClick(() => {
            this.navPathStack.popToName('首页', true)
          })
        Button('返回上一页')
          .onClick(() => {
            this.navPathStack.pop()
          })
      }
      .justifyContent(FlexAlign.Center)
    }
    .title('页面3')
  }
}
```

## 四、高级用法

### 4.1 导航拦截器

```typescript
@ComponentV2
struct NavigationInterceptorExample {
  @Local navPathStack: NavPathStack = new NavPathStack()

  aboutToAppear() {
    // 添加导航拦截器
    this.navPathStack.setInterception({
      willShow: (from: string, to: string, params: Object, operation: NavigationOperation) => {
        console.info(`导航拦截: 从 ${from} 到 ${to}`)
        // 返回 true 允许导航，false 阻止导航
        return true
      },
      didShow: (name: string, params: Object) => {
        console.info(`页面已显示: ${name}`)
      }
    })
  }

  build() {
    Navigation(this.navPathStack) {
      // 内容
    }
    .navDestination(this.PageBuilder)
  }
}
```

### 4.2 获取导航状态

```typescript
@ComponentV2
struct NavigationStateExample {
  @Local navPathStack: NavPathStack = new NavPathStack()
  @Local stackInfo: string = ''

  updateStackInfo() {
    const allPaths = this.navPathStack.getAllPathName()
    this.stackInfo = `当前页面栈: ${allPaths.join(' -> ')}`
  }

  build() {
    Navigation(this.navPathStack) {
      Column({ space: 16 }) {
        Text(this.stackInfo)
          .fontSize(14)
        Button('更新栈信息')
          .onClick(() => {
            this.updateStackInfo()
          })
      }
    }
    .navDestination(this.PageBuilder)
  }
}
```

### 4.3 自定义标题栏

```typescript
@ComponentV2
struct CustomTitleBarExample {
  @Local navPathStack: NavPathStack = new NavPathStack()

  build() {
    Navigation(this.navPathStack) {
      Column() {
        Text('自定义标题栏内容')
      }
    }
    .navDestination(this.PageBuilder)
    .title('自定义标题')
    .titleMode(NavigationTitleMode.Mini)
    .titleBackgroundColor('#007DFF')
  }
}
```

## 五、最佳实践

### 5.1 使用类型安全的路由名称

```typescript
// ✅ 推荐：使用常量定义路由名称
export const RouteNames = {
  HOME: 'HomePage',
  DETAIL: 'DetailPage',
  PROFILE: 'ProfilePage'
} as const

// 使用
this.navPathStack.pushPathByName(RouteNames.DETAIL, params)

// ❌ 避免：硬编码字符串
this.navPathStack.pushPathByName('DetailPage', params)
```

### 5.2 参数类型定义

```typescript
// ✅ 推荐：为每个页面定义参数接口
interface DetailPageParams {
  itemId: number
  itemTitle: string
  fromPage: string
}

// 使用类型安全的参数
const params: DetailPageParams = {
  itemId: 123,
  itemTitle: '商品标题',
  fromPage: 'HomePage'
}
this.navPathStack.pushPathByName(RouteNames.DETAIL, params)
```

### 5.3 页面栈管理

```typescript
// ✅ 推荐：避免页面栈过深
if (this.navPathStack.getAllPathName().length > 5) {
  // 清理页面栈，避免内存问题
  this.navPathStack.popToName('HomePage', false)
}

// ✅ 推荐：使用 replace 避免栈过深
this.navPathStack.replacePathByName('DetailPage', params)
```

### 5.4 导航动画配置

```typescript
// ✅ 推荐：根据场景选择合适的动画
// 标准页面跳转
this.navPathStack.pushPathByName('Page', null, true)

// 快速切换（无动画）
this.navPathStack.pushPathByName('Page', null, false)
```

## 六、常见问题

### Q1: Navigation 与 Router 有什么区别？

**答**: Navigation 是 HarmonyOS 6.0 推荐的新导航方案，支持声明式路由、更好的类型安全、完整的页面生命周期管理。Router 是旧版方案，功能相对有限。

### Q2: 如何实现页面间数据共享？

**答**: 可以通过以下方式：
1. 使用全局状态管理（@ObservedV2）
2. 通过 NavPathStack 传递参数
3. 使用事件总线

### Q3: 页面栈过深怎么办？

**答**: 使用 `replacePath` 替换当前页面，或使用 `popToName` 返回到指定页面。

### Q4: 如何自定义转场动画？

**答**: 使用 `.transition()` 或 `.defaultTransition()` 方法配置 TransitionEffect。

### Q5: Navigation 如何处理返回键？

**答**: 默认情况下，Navigation 会自动处理返回键并弹出栈顶页面。可以通过 `onBackPressed()` 自定义返回行为。

## 七、版本兼容性

| API 版本 | 支持状态 | 备注 |
|----------|----------|------|
| API 12+ | ✅ | Navigation 组件首次引入 |
| API 13+ | ✅ | 增强功能，支持更多导航模式 |
| API 21+ | ✅ | HarmonyOS 6.0 完整支持 |

## 八、参考资料

- [Navigation 导航 - 华为开发者官方文档](https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V5/ts-basic-components-navigation-V5)
- [路由导航 - 华为开发者](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides-V5/arkts-navigation-navigation-V5)
- [NavDestination 组件 - 华为开发者](https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V5/ts-basic-components-navdestination-V5)
