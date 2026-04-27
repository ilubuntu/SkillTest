/**
 * navigation-router-push-destination — pushDestination 异步跳转
 * 展示 pushDestination / pushDestinationByName 的 Promise 版本和错误处理
 * 元服务兼容性：API 12+
 */
import { BusinessError } from '@kit.BasicServicesKit'

@ComponentV2
export struct NavigationRouterPushDestination {
  @Local resultText: string = '点击按钮进行 pushDestination 异步跳转'
  @Local stackSize: number = 0
  @Local pushStatus: string = ''
  navPathStack: NavPathStack = new NavPathStack()

  @Builder
  pageMap(name: string) {
    if (name === 'asyncPageA') {
      PushDestAsyncPageA()
    } else if (name === 'asyncPageB') {
      PushDestAsyncPageB()
    }
  }

  private updateInfo(opName: string): void {
    this.stackSize = this.navPathStack.size()
    this.resultText = `${opName} 成功，栈深度: ${this.stackSize}`
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('pushDestination 异步跳转')
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
          if (this.pushStatus) {
            Text(this.pushStatus)
              .fontSize(13)
              .fontColor('#4CAF50')
              .width('100%')
              .padding({ left: 12, bottom: 8 })
          }
        }
        .width('90%')
        .backgroundColor('#F5F5F5')
        .borderRadius(8)

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
              Button('PushDest A')
                .fontSize(13)
                .height(36)
                .onClick(() => {
                  this.pushStatus = '正在跳转...'
                  try {
                    this.navPathStack.pushDestination({ name: 'asyncPageA' }, false)
                      .then(() => {
                        this.pushStatus = 'pushDestination 成功（Promise resolved）'
                        this.updateInfo('pushDestination(asyncPageA)')
                      })
                      .catch((err: BusinessError) => {
                        this.pushStatus = `pushDestination 失败: code=${err.code}, msg=${err.message}`
                      })
                  } catch (err) {
                    const e = err as BusinessError
                    this.pushStatus = `同步异常: ${e.message}`
                  }
                })
              Button('PushDestByName B')
                .fontSize(13)
                .height(36)
                .onClick(() => {
                  this.pushStatus = '正在跳转...'
                  try {
                    this.navPathStack.pushDestinationByName('asyncPageB', { source: '首页' }, false)
                      .then(() => {
                        this.pushStatus = 'pushDestinationByName 成功（Promise resolved）'
                        this.updateInfo('pushDestinationByName(asyncPageB)')
                      })
                      .catch((err: BusinessError) => {
                        this.pushStatus = `pushDestinationByName 失败: code=${err.code}, msg=${err.message}`
                      })
                  } catch (err) {
                    const e = err as BusinessError
                    this.pushStatus = `同步异常: ${e.message}`
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
          Text('pushDestination(info, animated?) — Promise<void>')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('pushDestinationByName(name, param, animated?) — Promise<void>')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('与 pushPath / pushPathByName 区别：')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
            .margin({ top: 4 })
          Text('  pushPath 同步执行，不返回 Promise')
            .fontSize(11)
            .fontColor('#999999')
            .fontFamily('monospace')
            .width('100%')
          Text('  pushDestination 异步执行，返回 Promise<void>')
            .fontSize(11)
            .fontColor('#999999')
            .fontFamily('monospace')
            .width('100%')
          Text('  适用于需要确认跳转成功后再执行逻辑的场景')
            .fontSize(11)
            .fontColor('#999999')
            .width('100%')
          Text('元服务：API 12+ 支持所有 pushDestination 重载')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
            .margin({ top: 4 })
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
struct PushDestAsyncPageA {
  pageInfo: NavPathStack = new NavPathStack()

  build() {
    NavDestination() {
      Column({ space: 12 }) {
        Text('异步跳转页面 A')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
        Text('此页面通过 pushDestination 跳转')
          .fontSize(13)
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
    .title('Async Page A')
    .onReady((context: NavDestinationContext) => {
      this.pageInfo = context.pathStack
    })
  }
}

@Component
struct PushDestAsyncPageB {
  pageInfo: NavPathStack = new NavPathStack()
  @State receivedParam: string = ''

  build() {
    NavDestination() {
      Column({ space: 12 }) {
        Text('异步跳转页面 B')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
        Text(`接收参数: ${this.receivedParam}`)
          .fontSize(13)
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
    .title('Async Page B')
    .onReady((context: NavDestinationContext) => {
      this.pageInfo = context.pathStack
      const param = context.pathStack.getParamByName('asyncPageB') as Object[]
      if (param && param.length > 0) {
        this.receivedParam = JSON.stringify(param[param.length - 1])
      }
    })
  }
}
