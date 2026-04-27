/**
 * navigation-router-push-by-name — pushPathByName 按名称跳转传参
 * 展示 pushPathByName 按名称跳转、参数传递与 getParamByName 获取参数
 * 元服务兼容性：API 11+
 */
import { BusinessError } from '@kit.BasicServicesKit'

@ComponentV2
export struct NavigationRouterPushByName {
  @Local resultText: string = '点击按钮进行 pushPathByName 跳转'
  @Local stackSize: number = 0
  @Local inputParam: string = '来自首页的参数'
  navPathStack: NavPathStack = new NavPathStack()

  @Builder
  pageMap(name: string) {
    if (name === 'detailPage') {
      PushByNameDetailPage()
    } else if (name === 'listPage') {
      PushByNameListPage()
    }
  }

  private updateInfo(opName: string): void {
    this.stackSize = this.navPathStack.size()
    this.resultText = `${opName} 成功，栈深度: ${this.stackSize}`
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('pushPathByName 按名称跳转传参')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20, bottom: 10 })

        // 结果展示区
        Column() {
          Text(this.resultText)
            .fontSize(14)
            .fontColor('#333333')
            .width('100%')
            .padding(12)
        }
        .width('90%')
        .backgroundColor('#F5F5F5')
        .borderRadius(8)

        // 参数控制区
        Text('跳转参数')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16 })

        TextInput({ text: $$this.inputParam, placeholder: '输入传递给子页面的参数' })
          .width('90%')
          .height(40)
          .fontSize(14)

        // 导航预览区
        Text('导航预览')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Navigation(this.navPathStack) {
          Column({ space: 12 }) {
            Text('首页')
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
            Row({ space: 8 }) {
              Button('跳转详情')
                .fontSize(13)
                .height(36)
                .onClick(() => {
                  try {
                    this.navPathStack.pushPathByName('detailPage', this.inputParam, false)
                    this.updateInfo('pushPathByName(detailPage)')
                  } catch (err) {
                    const e = err as BusinessError
                    this.resultText = `pushPathByName 失败: ${e.message}`
                  }
                })
              Button('跳转列表')
                .fontSize(13)
                .height(36)
                .onClick(() => {
                  try {
                    this.navPathStack.pushPathByName('listPage', '商品列表参数' as Object, false)
                    this.updateInfo('pushPathByName(listPage)')
                  } catch (err) {
                    const e = err as BusinessError
                    this.resultText = `pushPathByName 失败: ${e.message}`
                  }
                })
            }
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
        }
        .navDestination(this.pageMap)
        .height(300)
        .width('90%')
        .borderRadius(8)
        .title('Navigation')
        .titleMode(NavigationTitleMode.Mini)

        // API 说明区
        Column() {
          Text('API 说明')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 8 })
          Text('pushPathByName(name, param, animated?) — 按名称入栈跳转')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('  name: 路由名称（对应系统路由表或 @Builder 映射）')
            .fontSize(11)
            .fontColor('#999999')
            .fontFamily('monospace')
            .width('100%')
          Text('  param: 传递给目标页面的参数（Object 或基础类型）')
            .fontSize(11)
            .fontColor('#999999')
            .fontFamily('monospace')
            .width('100%')
          Text('  animated: 是否使用转场动画，默认 true')
            .fontSize(11)
            .fontColor('#999999')
            .fontFamily('monospace')
            .width('100%')
          Text('getParamByName(name) — 获取指定名称页面的参数列表')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('与 pushPath(info) 区别：pushPathByName 直接传名称字符串，无需构造 NavPathInfo')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
            .margin({ top: 4 })
          Text('元服务：API 11+ 支持 pushPathByName(name, param, animated?)')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
        }
        .width('90%')
        .backgroundColor('#FFF9E6')
        .borderRadius(8)
        .padding(12)
        .margin({ top: 8 })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
  }
}

@Component
struct PushByNameDetailPage {
  pageInfo: NavPathStack = new NavPathStack()
  @State receivedParam: string = ''

  build() {
    NavDestination() {
      Column({ space: 12 }) {
        Text('详情页（detailPage）')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
        Text(`接收参数: ${this.receivedParam}`)
          .fontSize(14)
          .fontColor('#666666')
        Button('Pop 返回')
          .fontSize(13)
          .height(36)
          .onClick(() => {
            this.pageInfo.pop()
          })
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
    }
    .title('Detail')
    .onReady((context: NavDestinationContext) => {
      this.pageInfo = context.pathStack
      const param = context.pathStack.getParamByName('detailPage') as string[]
      if (param && param.length > 0) {
        this.receivedParam = JSON.stringify(param[param.length - 1])
      }
    })
  }
}

@Component
struct PushByNameListPage {
  pageInfo: NavPathStack = new NavPathStack()
  @State receivedParam: string = ''

  build() {
    NavDestination() {
      Column({ space: 12 }) {
        Text('列表页（listPage）')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
        Text(`接收参数: ${this.receivedParam}`)
          .fontSize(14)
          .fontColor('#666666')
        Button('Pop 返回')
          .fontSize(13)
          .height(36)
          .onClick(() => {
            this.pageInfo.pop()
          })
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
    }
    .title('List')
    .onReady((context: NavDestinationContext) => {
      this.pageInfo = context.pathStack
      const param = context.pathStack.getParamByName('listPage') as Object[]
      if (param && param.length > 0) {
        this.receivedParam = JSON.stringify(param[param.length - 1])
      }
    })
  }
}
