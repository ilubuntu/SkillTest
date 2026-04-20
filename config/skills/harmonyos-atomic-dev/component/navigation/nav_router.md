# NavRouter 组件 HarmonyOS 6.0 开发 Skill

## 概述

NavRouter 组件是 OpenHarmony 中用于实现声明式路由导航的组件。它通过 `NavRouter` 和 `NavDestination` 配合使用，实现内容区域的动态切换。NavRouter 主要用于实现类似标签页、视图切换的场景，是构建应用内导航的重要组件。

## 重要说明

- **路由容器**: NavRouter 是一个路由容器组件
- **配对使用**: 必须与 NavDestination 组件配合使用
- **声明式**: 采用声明式路由，通过状态控制显示内容
- **适用场景**: 标签页、侧边栏导航、视图切换等
- **性能优化**: 内容按需加载，提升应用性能

## 模块信息

- **组件名称**: NavRouter
- **SDK 版本**: HarmonyOS 6.0 (API 12+)
- **系统能力**: SystemCapability.ArkUI.ArkUI.Full
- **更新日期**: 2026-02-24
- **官方文档**:
  - [NavRouter - 华为开发者](https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V5/ts-basic-components-navrouter-V5)

## 一、组件基础

### 1.1 导入方式

```typescript
// NavRouter 是内置组件，无需导入
// 需要配合 NavDestination 使用
import { NavDestination } from '@kit.ArkUI'
```

### 1.2 基础用法

```typescript
@ComponentV2
struct NavRouterExample {
  @Local selectedIndex: number = 0

  build() {
    Column() {
      // NavRouter 容器
      NavRouter() {
        // 导航内容区
        if (this.selectedIndex === 0) {
          NavDestination() {
            Text('首页内容')
          }
        } else if (this.selectedIndex === 1) {
          NavDestination() {
            Text('发现内容')
          }
        } else if (this.selectedIndex === 2) {
          NavDestination() {
            Text('我的内容')
          }
        }
      }
      .width('100%')
      .height('100%')

      // 底部导航栏
      Row() {
        ForEach(['首页', '发现', '我的'], (title: string, index: number) => {
          Column({ space: 4 }) {
            Text(title)
              .fontSize(12)
              .fontColor(this.selectedIndex === index ? '#007DFF' : '#999999')
          }
          .layoutWeight(1)
          .onClick(() => {
            this.selectedIndex = index
          })
        })
      }
      .width('100%')
      .height(60)
      .backgroundColor('#FFFFFF')
    }
  }
}
```

## 二、API 参数

### 2.1 构造参数

| 参数 | 类型 | 必填 | 默认值 | 描述 |
|------|------|------|--------|------|
| content | `BuilderParam` | 是 | - | NavRouter 的内容，通常是 NavDestination 组件 |

### 2.2 属性

| 属性 | 类型 | 默认值 | 描述 |
|------|------|--------|------|
| `mode` | `NavRouterMode` | NavRouterMode.STACK | 路由模式 |
| - NavRouterMode.STACK | - | - | 栈模式，内容依次入栈 |
| - NavRouterMode.SINGLE | - | - | 单例模式，只保留一个页面 |

### 2.3 NavDestination 子组件

| 属性 | 类型 | 默认值 | 描述 |
|------|------|--------|------|
| `title` | `string \| Resource` | - | 目标页面标题 |
| `hideTitleBar` | `boolean` | false | 是否隐藏标题栏 |

## 三、使用示例

### 3.1 基础 NavRouter 示例

```typescript
@ComponentV2
struct BasicNavRouterExample {
  @Local currentIndex: number = 0

  build() {
    Column() {
      NavRouter() {
        if (this.currentIndex === 0) {
          NavDestination() {
            Column({ space: 16 }) {
              Text('首页')
                .fontSize(24)
                .fontWeight(FontWeight.Bold)
              Text('这是首页的内容')
                .fontSize(16)
                .fontColor('#666666')
            }
            .width('100%')
            .height('100%')
            .justifyContent(FlexAlign.Center)
            .backgroundColor('#FFE4E1')
          }
        } else if (this.currentIndex === 1) {
          NavDestination() {
            Column({ space: 16 }) {
              Text('发现')
                .fontSize(24)
                .fontWeight(FontWeight.Bold)
              Text('这是发现页的内容')
                .fontSize(16)
                .fontColor('#666666')
            }
            .width('100%')
            .height('100%')
            .justifyContent(FlexAlign.Center)
            .backgroundColor('#E1FFE4')
          }
        } else if (this.currentIndex === 2) {
          NavDestination() {
            Column({ space: 16 }) {
              Text('我的')
                .fontSize(24)
                .fontWeight(FontWeight.Bold)
              Text('这是我的页的内容')
                .fontSize(16)
                .fontColor('#666666')
            }
            .width('100%')
            .height('100%')
            .justifyContent(FlexAlign.Center)
            .backgroundColor('#E1E4FF')
          }
        }
      }
      .width('100%')
      .layoutWeight(1)

      // 底部导航
      Row() {
        ForEach(['首页', '发现', '我的'], (title: string, index: number) => {
          Column({ space: 4 }) {
            Text(this.getIcon(index))
              .fontSize(24)
              .fontColor(this.currentIndex === index ? '#007DFF' : '#999999')
            Text(title)
              .fontSize(12)
              .fontColor(this.currentIndex === index ? '#007DFF' : '#999999')
          }
          .layoutWeight(1)
          .height('100%')
          .justifyContent(FlexAlign.Center)
          .onClick(() => {
            this.currentIndex = index
          })
        })
      }
      .width('100%')
      .height(60)
      .backgroundColor('#FFFFFF')
      .border({ width: { top: 1 }, color: '#E0E0E0' })
    }
    .width('100%')
    .height('100%')
  }

  getIcon(index: number): string {
    const icons = ['\uE8C6', '\uE8E2', '\uE8C9'] // 首页、发现、我的图标
    return icons[index]
  }
}
```

### 3.2 侧边栏导航

```typescript
@ComponentV2
struct SidebarNavRouterExample {
  @Local selectedMenu: string = 'menu1'

  build() {
    Row() {
      // 左侧导航菜单
      Column({ space: 0 }) {
        ForEach([
          { id: 'menu1', title: '用户管理', icon: '\uE8C6' },
          { id: 'menu2', title: '数据统计', icon: '\uE8E2' },
          { id: 'menu3', title: '系统设置', icon: '\uE8C9' }
        ], (menu: { id: string; title: string; icon: string }) => {
          Column({ space: 8 }) {
            Text(menu.icon)
              .fontSize(24)
              .fontColor(this.selectedMenu === menu.id ? '#007DFF' : '#666666')
            Text(menu.title)
              .fontSize(12)
              .fontColor(this.selectedMenu === menu.id ? '#007DFF' : '#666666')
          }
          .width('100%')
          .padding(16)
          .backgroundColor(this.selectedMenu === menu.id ? '#E3F2FD' : 'transparent')
          .border({ width: { left: 4 }, color: this.selectedMenu === menu.id ? '#007DFF' : 'transparent' })
          .onClick(() => {
            this.selectedMenu = menu.id
          })
        })
      }
      .width(100)
      .height('100%')
      .backgroundColor('#F5F5F5')

      // 右侧内容区
      NavRouter() {
        if (this.selectedMenu === 'menu1') {
          NavDestination() {
            this.UserManagementContent()
          }
        } else if (this.selectedMenu === 'menu2') {
          NavDestination() {
            this.StatisticsContent()
          }
        } else if (this.selectedMenu === 'menu3') {
          NavDestination() {
            this.SettingsContent()
          }
        }
      }
      .width('100%')
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  UserManagementContent() {
    Column({ space: 16 }) {
      Text('用户管理')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
      ForEach(['用户A', '用户B', '用户C'], (user: string) => {
        Text(user)
          .fontSize(16)
          .padding(12)
          .backgroundColor('#FFFFFF')
          .borderRadius(8)
          .width('100%')
      })
    }
    .width('100%')
    .height('100%')
    .padding(16)
    .backgroundColor('#FAFAFA')
  }

  @Builder
  StatisticsContent() {
    Column({ space: 16 }) {
      Text('数据统计')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
      Text('统计数据展示区域')
        .fontSize(16)
        .fontColor('#666666')
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .backgroundColor('#FAFAFA')
  }

  @Builder
  SettingsContent() {
    Column({ space: 16 }) {
      Text('系统设置')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
      Text('系统配置选项')
        .fontSize(16)
        .fontColor('#666666')
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .backgroundColor('#FAFAFA')
  }
}
```

### 3.3 标签页导航

```typescript
@ComponentV2
struct TabNavRouterExample {
  @Local activeTab: number = 0
  private tabs: string[] = ['推荐', '热门', '最新', '关注']

  build() {
    Column() {
      // 顶部标签栏
      Row({ space: 0 }) {
        ForEach(this.tabs, (tab: string, index: number) => {
          Column() {
            Text(tab)
              .fontSize(16)
              .fontWeight(this.activeTab === index ? FontWeight.Bold : FontWeight.Normal)
              .fontColor(this.activeTab === index ? '#007DFF' : '#666666')
              .padding({ top: 12, bottom: 12 })
          }
          .layoutWeight(1)
          .onClick(() => {
            this.activeTab = index
          })
        })
      }
      .width('100%')
      .backgroundColor('#FFFFFF')
      .border({ width: { bottom: 1 }, color: '#E0E0E0' })

      // 内容区
      NavRouter() {
        if (this.activeTab === 0) {
          NavDestination() {
            this.TabContent('推荐内容')
          }
        } else if (this.activeTab === 1) {
          NavDestination() {
            this.TabContent('热门内容')
          }
        } else if (this.activeTab === 2) {
          NavDestination() {
            this.TabContent('最新内容')
          }
        } else if (this.activeTab === 3) {
          NavDestination() {
            this.TabContent('关注内容')
          }
        }
      }
      .width('100%')
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  TabContent(title: string) {
    Column({ space: 16 }) {
      Text(title)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
      ForEach(Array.from({ length: 10 }, (_, i) => i + 1), (item: number) => {
        Text(`${title} - 项目 ${item}`)
          .fontSize(14)
          .padding(12)
          .backgroundColor('#FFFFFF')
          .borderRadius(8)
          .width('100%')
      })
    }
    .width('100%')
    .height('100%')
    .padding(16)
    .backgroundColor('#F5F5F5')
  }
}
```

### 3.4 带动画的导航切换

```typescript
@ComponentV2
struct AnimatedNavRouterExample {
  @Local currentView: string = 'view1'

  build() {
    Column() {
      NavRouter() {
        if (this.currentView === 'view1') {
          NavDestination() {
            Column({ space: 16 }) {
              Text('视图 1')
                .fontSize(24)
                .fontWeight(FontWeight.Bold)
              Text('这是第一个视图的内容')
                .fontSize(16)
              Button('切换到视图2')
                .onClick(() => {
                  this.currentView = 'view2'
                })
            }
            .justifyContent(FlexAlign.Center)
            .backgroundColor('#FFE4E1')
          }
        } else if (this.currentView === 'view2') {
          NavDestination() {
            Column({ space: 16 }) {
              Text('视图 2')
                .fontSize(24)
                .fontWeight(FontWeight.Bold)
              Text('这是第二个视图的内容')
                .fontSize(16)
              Button('切换到视图1')
                .onClick(() => {
                  this.currentView = 'view1'
                })
            }
            .justifyContent(FlexAlign.Center)
            .backgroundColor('#E1FFE4')
          }
        }
      }
      .width('100%')
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
  }
}
```

### 3.5 嵌套 NavRouter

```typescript
@ComponentV2
struct NestedNavRouterExample {
  @Local mainMenu: string = 'home'
  @Local subMenu: string = 'overview'

  build() {
    Column() {
      // 主导航
      Row() {
        ForEach(['首页', '工作台', '消息'], (menu: string, index: number) => {
          Text(menu)
            .fontSize(16)
            .padding(12)
            .fontColor(this.mainMenu === ['home', 'work', 'message'][index] ? '#007DFF' : '#666666')
            .onClick(() => {
              this.mainMenu = ['home', 'work', 'message'][index]
            })
        })
      }
      .width('100%')
      .backgroundColor('#F0F0F0')

      // 内容区
      NavRouter() {
        if (this.mainMenu === 'home') {
          NavDestination() {
            this.HomeContent()
          }
        } else if (this.mainMenu === 'work') {
          NavDestination() {
            this.WorkContent()
          }
        } else if (this.mainMenu === 'message') {
          NavDestination() {
            this.MessageContent()
          }
        }
      }
      .width('100%')
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  HomeContent() {
    Column() {
      Text('首页')
        .fontSize(24)
        .padding(16)
      NavRouter() {
        if (this.subMenu === 'overview') {
          NavDestination() {
            Text('概览内容')
              .fontSize(18)
          }
        } else if (this.subMenu === 'analytics') {
          NavDestination() {
            Text('分析内容')
              .fontSize(18)
          }
        }
      }
      .layoutWeight(1)

      Row() {
        Text('概览')
          .padding(12)
          .onClick(() => {
            this.subMenu = 'overview'
          })
        Text('分析')
          .padding(12)
          .onClick(() => {
            this.subMenu = 'analytics'
          })
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  WorkContent() {
    Column() {
      Text('工作台')
        .fontSize(24)
        .padding(16)
      Text('工作台内容')
        .fontSize(18)
    }
    .justifyContent(FlexAlign.Center)
    .layoutWeight(1)
  }

  @Builder
  MessageContent() {
    Column() {
      Text('消息')
        .fontSize(24)
        .padding(16)
      Text('消息内容')
        .fontSize(18)
    }
    .justifyContent(FlexAlign.Center)
    .layoutWeight(1)
  }
}
```

### 3.6 动态 NavRouter

```typescript
@ComponentV2
struct DynamicNavRouterExample {
  @Local routes: Array<{ id: string; title: string; content: string }> = []
  @Local currentRoute: string = ''

  aboutToAppear() {
    // 动态加载路由
    this.routes = [
      { id: 'route1', title: '路由1', content: '这是路由1的内容' },
      { id: 'route2', title: '路由2', content: '这是路由2的内容' },
      { id: 'route3', title: '路由3', content: '这是路由3的内容' }
    ]
    this.currentRoute = this.routes[0].id
  }

  build() {
    Column() {
      // 动态菜单
      Row({ space: 8 }) {
        ForEach(this.routes, (route: { id: string; title: string; content: string }) => {
          Text(route.title)
            .fontSize(14)
            .padding(12)
            .backgroundColor(this.currentRoute === route.id ? '#007DFF' : '#E0E0E0')
            .fontColor(this.currentRoute === route.id ? Color.White : '#333333')
            .borderRadius(8)
            .onClick(() => {
              this.currentRoute = route.id
            })
        })
      }
      .width('100%')
      .padding(16)

      // 动态内容
      NavRouter() {
        ForEach(this.routes, (route: { id: string; title: string; content: string }) => {
          if (this.currentRoute === route.id) {
            NavDestination() {
              Column({ space: 16 }) {
                Text(route.title)
                  .fontSize(24)
                  .fontWeight(FontWeight.Bold)
                Text(route.content)
                  .fontSize(16)
                  .fontColor('#666666')
              }
              .justifyContent(FlexAlign.Center)
              .backgroundColor('#F5F5F5')
            }
          }
        })
      }
      .width('100%')
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
  }
}
```

## 四、高级用法

### 4.1 带状态管理的 NavRouter

```typescript
@ObservedV2
class RouterState {
  @Trace currentRoute: string = 'home'
  @Trace routeHistory: string[] = []

  navigateTo(route: string) {
    if (this.currentRoute !== route) {
      this.routeHistory.push(this.currentRoute)
      this.currentRoute = route
    }
  }

  goBack() {
    if (this.routeHistory.length > 0) {
      this.currentRoute = this.routeHistory.pop()!
    }
  }
}

@ComponentV2
struct StatefulNavRouterExample {
  @Local routerState: RouterState = new RouterState()

  build() {
    Column() {
      NavRouter() {
        if (this.routerState.currentRoute === 'home') {
          NavDestination() {
            this.HomePage()
          }
        } else if (this.routerState.currentRoute === 'detail') {
          NavDestination() {
            this.DetailPage()
          }
        }
      }
      .layoutWeight(1)

      Button('返回')
        .onClick(() => {
          this.routerState.goBack()
        })
    }
  }

  @Builder
  HomePage() {
    Column({ space: 16 }) {
      Text('首页')
        .fontSize(24)
      Button('前往详情')
        .onClick(() => {
          this.routerState.navigateTo('detail')
        })
    }
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  DetailPage() {
    Column({ space: 16 }) {
      Text('详情页')
        .fontSize(24)
      Button('返回首页')
        .onClick(() => {
          this.routerState.goBack()
        })
    }
    .justifyContent(FlexAlign.Center)
  }
}
```

### 4.2 NavRouter 与动画结合

```typescript
@ComponentV2
struct NavRouterWithAnimationExample {
  @Local activeIndex: number = 0

  build() {
    Column() {
      NavRouter() {
        ForEach([0, 1, 2], (index: number) => {
          if (this.activeIndex === index) {
            NavDestination() {
              Column() {
                Text(`页面 ${index + 1}`)
                  .fontSize(24)
              }
              .justifyContent(FlexAlign.Center)
              .width('100%')
              .height('100%')
              .backgroundColor(index === 0 ? '#FFE4E1' : index === 1 ? '#E1FFE4' : '#E1E4FF')
            }
          }
        })
      }
      .width('100%')
      .layoutWeight(1)

      // 带动画的切换按钮
      Row({ space: 8 }) {
        ForEach([0, 1, 2], (index: number) => {
          Button(`页面${index + 1}`)
            .onClick(() => {
              animateTo({
                duration: 300,
                curve: curves.initCurve(curves.Curve.EaseInOut)
              }, () => {
                this.activeIndex = index
              })
            })
        })
      }
      .padding(16)
    }
  }
}
```

## 五、最佳实践

### 5.1 使用常量定义路由

```typescript
// ✅ 推荐：使用常量定义路由
const ROUTES = {
  HOME: 'home',
  DISCOVER: 'discover',
  PROFILE: 'profile'
} as const

@Local currentRoute: string = ROUTES.HOME

// ❌ 避免：硬编码字符串
@Local currentRoute: string = 'home'
```

### 5.2 组件化内容

```typescript
// ✅ 推荐：将内容提取为独立组件
@ComponentV2
struct HomeContent {
  build() {
    // 首页内容
  }
}

NavRouter() {
  if (this.currentRoute === ROUTES.HOME) {
    NavDestination() {
      HomeContent()
    }
  }
}

// ❌ 避免：内联所有内容
NavRouter() {
  if (this.currentRoute === ROUTES.HOME) {
    NavDestination() {
      Column() {
        // 大量内联代码
      }
    }
  }
}
```

### 5.3 性能优化

```typescript
// ✅ 推荐：使用条件判断避免不必要的渲染
if (this.currentRoute === ROUTES.HOME) {
  NavDestination() {
    HomeContent()
  }
}

// ❌ 避免：使用不必要的透明度控制
NavDestination() {
  HomeContent()
    .opacity(this.currentRoute === ROUTES.HOME ? 1 : 0)
}
```

## 六、常见问题

### Q1: NavRouter 和 Navigation 有什么区别？

**答**:
- **NavRouter**: 轻量级路由容器，适合简单的视图切换
- **Navigation**: 完整的导航容器，支持页面栈、路由拦截等高级功能

### Q2: 如何实现页面切换动画？

**答**: 使用 `animateTo` API 包裹状态更新，或使用 NavDestination 的 `transition` 属性。

### Q3: NavRouter 可以嵌套使用吗？

**答**: 可以，NavRouter 支持嵌套，适合实现多级导航结构。

### Q4: 如何在路由间传递参数？

**答**: 使用组件的 `@Param` 属性或全局状态管理。

### Q5: NavRouter 的性能如何？

**答**: NavRouter 采用按需加载策略，只渲染当前激活的 NavDestination，性能良好。

## 七、版本兼容性

| API 版本 | 支持状态 | 备注 |
|----------|----------|------|
| API 12+ | ✅ | NavRouter 组件首次引入 |

## 八、参考资料

- [NavRouter - 华为开发者官方文档](https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V5/ts-basic-components-navrouter-V5)
- [NavDestination - 华为开发者](https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V5/ts-basic-components-navdestination-V5)
