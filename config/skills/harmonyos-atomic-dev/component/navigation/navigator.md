# Navigator 组件 HarmonyOS 6.0 开发 Skill

## 概述

Navigator 组件是 OpenHarmony 中用于声明式页面跳转的组件。它提供了比 Router 更灵活的页面跳转方式，支持自定义跳转动画、参数传递、以及更细粒度的跳转控制。Navigator 通常用于跳转到非 Navigation 管理的页面，或作为页面内部的导航触发器。

## 重要说明

- **声明式导航**: Navigator 是声明式组件，比命令式 Router 更灵活
- **使用场景**: 适合简单的页面跳转，复杂导航建议使用 Navigation
- **目标类型**: 支持跳转到普通页面和模态半模态页面
- **动画支持**: 内置多种转场动画效果
- **参数传递**: 支持页面间参数传递

## 模块信息

- **组件名称**: Navigator
- **SDK 版本**: HarmonyOS 6.0 (API 12+)
- **系统能力**: SystemCapability.ArkUI.ArkUI.Full
- **更新日期**: 2026-02-24
- **官方文档**:
  - [Navigator - 华为开发者](https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V5/ts-basic-components-navigator-V5)

## 一、组件基础

### 1.1 导入方式

```typescript
// Navigator 是内置组件，无需导入
// 直接使用即可
```

### 1.2 基础用法

```typescript
@ComponentV2
struct NavigatorExample {
  build() {
    Column() {
      // 简单跳转
      Navigator({ target: 'pages/DetailPage' }) {
        Text('跳转到详情页')
          .fontSize(18)
          .padding(12)
      }

      // 带类型的跳转
      Navigator({
        target: 'pages/DetailPage',
        type: NavigationType.Push
      }) {
        Button('按钮跳转')
      }
    }
  }
}
```

## 二、API 参数

### 2.1 构造参数

| 参数 | 类型 | 必填 | 默认值 | 描述 |
|------|------|------|--------|------|
| target | `string` | 是 | - | 目标页面的路径 |
| type | `NavigationType` | 否 | NavigationType.Push | 导航类型 |
| params | `Object` | 否 | - | 传递给目标页面的参数 |

### 2.2 导航类型

| 类型 | 描述 |
|------|------|
| NavigationType.Push | 普通页面跳转，当前页面入栈 |
| NavigationType.Replace | 替换当前页面 |
| NavigationType.Back | 返回上一页 |

### 2.3 属性

| 属性 | 类型 | 默认值 | 描述 |
|------|------|--------|------|
| `active` | `boolean` | true | 是否激活导航功能 |
| `transition` | `Transition` | - | 转场动画效果 |

### 2.4 事件

| 事件 | 类型 | 描述 |
|------|------|------|
| `onClick` | `() => void` | 点击事件回调 |

## 三、使用示例

### 3.1 基础 Navigator 示例

```typescript
@ComponentV2
struct BasicNavigatorExample {
  build() {
    Column({ space: 16 }) {
      Text('Navigator 基础示例')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .width('100%')

      // 普通跳转
      Navigator({ target: 'pages/DetailPage' }) {
        Text('跳转到详情页')
          .fontSize(16)
          .padding(12)
          .backgroundColor('#007DFF')
          .fontColor(Color.White)
          .borderRadius(8)
      }

      // 按钮形式跳转
      Navigator({ target: 'pages/DetailPage' }) {
        Button('按钮跳转')
          .width('100%')
      }

      // 图片形式跳转
      Navigator({ target: 'pages/ImagePage' }) {
        Image($r('app.media.icon'))
          .width(100)
          .height(100)
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#F5F5F5')
    .borderRadius(12)
  }
}
```

### 3.2 带参数的 Navigator

```typescript
@ComponentV2
struct NavigatorWithParamsExample {
  @Local userId: number = 123
  @Local userName: string = '张三'

  build() {
    Column({ space: 16 }) {
      Text('带参数的 Navigator')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)

      // 传递对象参数
      Navigator({
        target: 'pages/UserProfile',
        params: {
          userId: this.userId,
          userName: this.userName
        }
      }) {
        Row({ space: 8 }) {
          Text('用户资料')
            .fontSize(16)
          Text(`(${this.userName})`)
            .fontSize(14)
            .fontColor('#666666')
        }
        .padding(12)
        .backgroundColor('#FFFFFF')
        .borderRadius(8)
        .width('100%')
      }

      // 传递简单参数
      Navigator({
        target: 'pages/DetailPage',
        params: { itemId: 456 }
      }) {
        Button('查看详情')
          .width('100%')
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#F5F5F5')
    .borderRadius(12)
  }
}
```

### 3.3 不同类型的 Navigator

```typescript
@ComponentV2
struct NavigatorTypeExample {
  build() {
    Column({ space: 16 }) {
      Text('Navigator 类型示例')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)

      // Push 类型 - 普通跳转
      Navigator({
        target: 'pages/Page1',
        type: NavigationType.Push
      }) {
        Text('Push 跳转')
          .fontSize(16)
          .padding(12)
          .backgroundColor('#007DFF')
          .fontColor(Color.White)
          .borderRadius(8)
      }

      // Replace 类型 - 替换当前页面
      Navigator({
        target: 'pages/Page2',
        type: NavigationType.Replace
      }) {
        Text('Replace 跳转')
          .fontSize(16)
          .padding(12)
          .backgroundColor('#28A745')
          .fontColor(Color.White)
          .borderRadius(8)
      }

      // Back 类型 - 返回上一页
      Navigator({
        target: '',
        type: NavigationType.Back
      }) {
        Text('返回上一页')
          .fontSize(16)
          .padding(12)
          .backgroundColor('#6C757D')
          .fontColor(Color.White)
          .borderRadius(8)
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#F5F5F5')
    .borderRadius(12)
  }
}
```

### 3.4 自定义转场动画

```typescript
@ComponentV2
struct NavigatorTransitionExample {
  build() {
    Column({ space: 16 }) {
      Text('自定义转场动画')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)

      // 淡入淡出动画
      Navigator({
        target: 'pages/Page1'
      }) {
        Text('淡入淡出')
          .fontSize(16)
          .padding(12)
          .backgroundColor('#007DFF')
          .fontColor(Color.White)
          .borderRadius(8)
      }
      .transition({
        type: TransitionType.Insert,
        opacity: 0
      })
      .transition({
        type: TransitionType.Delete,
        opacity: 0
      })

      // 滑动动画
      Navigator({
        target: 'pages/Page2'
      }) {
        Text('滑动进入')
          .fontSize(16)
          .padding(12)
          .backgroundColor('#28A745')
          .fontColor(Color.White)
          .borderRadius(8)
      }
      .transition({
        type: TransitionType.Insert,
        translate: { x: '100%' }
      })
      .transition({
        type: TransitionType.Delete,
        translate: { x: '-100%' }
      })
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#F5F5F5')
    .borderRadius(12)
  }
}
```

### 3.5 动态目标 Navigator

```typescript
@ComponentV2
struct DynamicNavigatorExample {
  @Local selectedPage: string = 'pages/HomePage'
  @Local pages: string[] = ['pages/HomePage', 'pages/DetailPage', 'pages/ProfilePage']

  build() {
    Column({ space: 16 }) {
      Text('动态目标 Navigator')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)

      // 页面选择器
      Row({ space: 8 }) {
        ForEach(this.pages, (page: string) => {
          Button(page.split('/').pop())
            .onClick(() => {
              this.selectedPage = page
            })
            .backgroundColor(this.selectedPage === page ? '#007DFF' : '#E0E0E0')
            .fontColor(this.selectedPage === page ? Color.White : '#333333')
        })
      }
      .width('100%')

      // 动态目标 Navigator
      Navigator({ target: this.selectedPage }) {
        Row({ space: 8 }) {
          Text('跳转到:')
            .fontSize(14)
          Text(this.selectedPage)
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
          Text('\uE6E0') // 箭头图标
            .fontSize(14)
        }
        .padding(12)
        .backgroundColor('#FFFFFF')
        .borderRadius(8)
        .width('100%')
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#F5F5F5')
    .borderRadius(12)
  }
}
```

### 3.6 条件激活 Navigator

```typescript
@ComponentV2
struct ConditionalNavigatorExample {
  @Local isLoggedIn: boolean = false
  @Local hasPermission: boolean = true

  build() {
    Column({ space: 16 }) {
      Text('条件激活 Navigator')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)

      // 模拟登录状态切换
      Row({ space: 8 }) {
        Button('登录')
          .onClick(() => {
            this.isLoggedIn = true
          })
        Button('登出')
          .onClick(() => {
            this.isLoggedIn = false
          })
      }

      // 根据登录状态激活或禁用导航
      Navigator({
        target: 'pages/UserCenter',
        active: this.isLoggedIn
      }) {
        Text('用户中心')
          .fontSize(16)
          .padding(12)
          .backgroundColor(this.isLoggedIn ? '#007DFF' : '#CCCCCC')
          .fontColor(Color.White)
          .borderRadius(8)
          .width('100%')
      }

      // 根据权限激活导航
      Navigator({
        target: 'pages/AdminPage',
        active: this.hasPermission
      }) {
        Text('管理页面')
          .fontSize(16)
          .padding(12)
          .backgroundColor(this.hasPermission ? '#28A745' : '#CCCCCC')
          .fontColor(Color.White)
          .borderRadius(8)
          .width('100%')
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#F5F5F5')
    .borderRadius(12)
  }
}
```

### 3.7 卡片式 Navigator

```typescript
@ComponentV2
struct CardNavigatorExample {
  @Local items: Array<{ title: string; description: string; page: string }> = [
    { title: '用户管理', description: '管理系统用户', page: 'pages/UserManage' },
    { title: '数据统计', description: '查看数据分析', page: 'pages/Statistics' },
    { title: '系统设置', description: '配置系统参数', page: 'pages/Settings' }
  ]

  build() {
    Column({ space: 16 }) {
      Text('功能导航')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)

      ForEach(this.items, (item: { title: string; description: string; page: string }) => {
        Navigator({ target: item.page }) {
          Column({ space: 8 }) {
            Row() {
              Text(item.title)
                .fontSize(18)
                .fontWeight(FontWeight.Medium)
                .layoutWeight(1)
              Text('\uE6E0')
                .fontSize(16)
                .fontColor('#CCCCCC')
            }
            .width('100%')

            Text(item.description)
              .fontSize(14)
              .fontColor('#666666')
          }
          .width('100%')
          .padding(16)
          .backgroundColor('#FFFFFF')
          .borderRadius(12)
        }
      })
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#F5F5F5')
    .borderRadius(12)
  }
}
```

## 四、高级用法

### 4.1 Navigator 与状态管理结合

```typescript
@ComponentV2
struct NavigatorWithStateExample {
  @Local navigationHistory: string[] = []
  @Local currentPage: string = 'Home'

  navigateTo(targetPage: string) {
    this.navigationHistory.push(this.currentPage)
    this.currentPage = targetPage
  }

  build() {
    Column({ space: 16 }) {
      Text(`当前页面: ${this.currentPage}`)
        .fontSize(18)

      Navigator({ target: 'pages/Page1' }) {
        Button('跳转到页面1')
          .onClick(() => {
            this.navigateTo('Page1')
          })
      }
    }
  }
}
```

### 4.2 嵌套 Navigator

```typescript
@ComponentV2
struct NestedNavigatorExample {
  build() {
    Column() {
      // 外层 Navigator
      Navigator({ target: 'pages/OuterPage' }) {
        Column({ space: 8 }) {
          Text('外层导航')
            .fontSize(16)

          // 内层 Navigator
          Navigator({ target: 'pages/InnerPage' }) {
            Text('内层导航')
              .fontSize(14)
              .padding(8)
              .backgroundColor('#E0E0E0')
              .borderRadius(4)
          }
        }
        .padding(16)
        .backgroundColor('#F5F5F5')
        .borderRadius(8)
      }
    }
  }
}
```

### 4.3 Navigator 事件监听

```typescript
@ComponentV2
struct NavigatorEventExample {
  @Local clickCount: number = 0

  build() {
    Column({ space: 16 }) {
      Text(`点击次数: ${this.clickCount}`)
        .fontSize(18)

      Navigator({ target: 'pages/DetailPage' }) {
        Button('带事件监听的跳转')
      }
      .onClick(() => {
        this.clickCount++
        console.info(`Navigator clicked ${this.clickCount} times`)
      })
    }
  }
}
```

## 五、最佳实践

### 5.1 选择合适的导航组件

```typescript
// ✅ 推荐：复杂应用使用 Navigation
Navigation(this.navPathStack) {
  // 内容
}
.navDestination(this.PageBuilder)

// ✅ 推荐：简单跳转使用 Navigator
Navigator({ target: 'pages/Detail' }) {
  Text('跳转')
}

// ❌ 避免：在复杂应用中仅使用 Navigator
```

### 5.2 使用常量定义页面路径

```typescript
// ✅ 推荐：使用常量
const PagePaths = {
  HOME: 'pages/HomePage',
  DETAIL: 'pages/DetailPage',
  PROFILE: 'pages/ProfilePage'
} as const

Navigator({ target: PagePaths.DETAIL })

// ❌ 避免：硬编码路径
Navigator({ target: 'pages/DetailPage' })
```

### 5.3 参数传递类型安全

```typescript
// ✅ 推荐：定义参数接口
interface DetailPageParams {
  itemId: number
  itemTitle: string
}

Navigator({
  target: PagePaths.DETAIL,
  params: {
    itemId: 123,
    itemTitle: '商品标题'
  } as DetailPageParams
})

// ❌ 避免：直接传递对象
Navigator({
  target: PagePaths.DETAIL,
  params: { id: 123, name: '标题' } // 类型不明确
})
```

### 5.4 条件导航

```typescript
// ✅ 推荐：根据条件设置 active
Navigator({
  target: PagePaths.ADMIN,
  active: this.isAdmin
}) {
  Text('管理页面')
}

// ❌ 避免：使用 onClick 阻止导航
Navigator({ target: PagePaths.ADMIN }) {
  Text('管理页面')
}
.onClick(() => {
  if (!this.isAdmin) {
    // 阻止导航的逻辑
  }
})
```

## 六、常见问题

### Q1: Navigator 和 Navigation 有什么区别？

**答**:
- **Navigator**: 简单的声明式跳转组件，适合单个跳转触发器
- **Navigation**: 完整的导航容器，支持页面栈管理、路由拦截、生命周期等

### Q2: 如何在目标页面获取传递的参数？

**答**: 在目标页面使用 `router.getParams()` 或在 Navigation 中通过 `params` 参数获取。

### Q3: Navigator 支持返回吗？

**答**: Navigator 的 `type: NavigationType.Back` 可以触发返回操作，但通常使用 `router.back()` 更方便。

### Q4: 如何实现复杂的转场动画？

**答**: 对于复杂动画，建议使用 Navigation 组件的 `transition` 属性，它可以提供更精细的控制。

### Q5: Navigator 的 active 属性如何使用？

**答**: 设置 `active: false` 可以禁用导航，此时点击不会触发页面跳转，适合权限控制场景。

## 七、版本兼容性

| API 版本 | 支持状态 | 备注 |
|----------|----------|------|
| API 9+ | ✅ | Navigator 组件首次引入 |
| API 12+ | ✅ | 增强功能，支持更多动画选项 |

## 八、参考资料

- [Navigator - 华为开发者官方文档](https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V5/ts-basic-components-navigator-V5)
- [页面路由 - 华为开发者](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides-V5/arkts-navigation-router-V5)
