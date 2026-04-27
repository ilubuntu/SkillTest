/**
 * navigation-router-interception — 路由拦截 setInterception
 * 展示 NavigationInterception 路由拦截器的 willShow/didShow/willHide/didHide 回调
 * 元服务兼容性：API 12+
 */
import { BusinessError } from '@kit.BasicServicesKit'

@ComponentV2
export struct NavigationRouterInterception {
  @Local resultText: string = '点击按钮启用路由拦截器'
  @Local interceptionLog: string = ''
  @Local isInterceptionEnabled: boolean = false
  navPathStack: NavPathStack = new NavPathStack()

  @Builder
  pageMap(name: string) {
    if (name === 'interceptPageA') {
      InterceptSubPage({ pageName: 'A' })
    } else if (name === 'interceptPageB') {
      InterceptSubPage({ pageName: 'B' })
    }
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('路由拦截 setInterception')
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

        // 拦截日志展示
        Column() {
          Text('拦截日志:')
            .fontSize(13)
            .fontWeight(FontWeight.Medium)
            .width('100%')
            .margin({ bottom: 4 })
          Scroll() {
            Text(this.interceptionLog || '（暂无日志）')
              .fontSize(12)
              .fontColor('#666666')
              .width('100%')
          }
          .height(80)
          .width('100%')
        }
        .width('90%')
        .backgroundColor('#F0F8FF')
        .borderRadius(8)
        .padding(12)

        // 操作按钮区
        Row({ space: 8 }) {
          Button(this.isInterceptionEnabled ? '已启用拦截' : '启用拦截')
            .fontSize(13)
            .height(36)
            .backgroundColor(this.isInterceptionEnabled ? '#4CAF50' : '#007DFF')
            .onClick(() => {
              if (!this.isInterceptionEnabled) {
                try {
                  this.navPathStack.setInterception({
                    willShow: (from: NavDestinationContext | NavBar, to: NavDestinationContext | NavBar,
                      operation: NavigationOperation, isAnimated: boolean) => {
                      const opName = operation === NavigationOperation.PUSH ? 'PUSH' :
                        operation === NavigationOperation.POP ? 'POP' : 'REPLACE'
                      this.interceptionLog += `[willShow] ${opName} animated=${isAnimated}\n`
                    },
                    didShow: (from: NavDestinationContext | NavBar, to: NavDestinationContext | NavBar,
                      operation: NavigationOperation, isAnimated: boolean) => {
                      const opName = operation === NavigationOperation.PUSH ? 'PUSH' :
                        operation === NavigationOperation.POP ? 'POP' : 'REPLACE'
                      this.interceptionLog += `[didShow] ${opName} 完成\n---\n`
                    }
                  })
                  this.isInterceptionEnabled = true
                  this.resultText = '路由拦截器已启用，请操作导航观察日志'
                } catch (err) {
                  const e = err as BusinessError
                  this.resultText = `setInterception 失败: ${e.message}`
                }
              }
            })
          Button('清空日志')
            .fontSize(13)
            .height(36)
            .backgroundColor('#FF6B00')
            .onClick(() => {
              this.interceptionLog = ''
            })
        }

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
              Button('Push A')
                .fontSize(13)
                .height(36)
                .onClick(() => {
                  try {
                    this.navPathStack.pushPathByName('interceptPageA', null, false)
                  } catch (err) {
                    const e = err as BusinessError
                  }
                })
              Button('Push B')
                .fontSize(13)
                .height(36)
                .onClick(() => {
                  try {
                    this.navPathStack.pushPathByName('interceptPageB', null, false)
                  } catch (err) {
                    const e = err as BusinessError
                  }
                })
              Button('Replace → B')
                .fontSize(13)
                .height(36)
                .onClick(() => {
                  try {
                    this.navPathStack.replacePathByName('interceptPageB', null, false)
                  } catch (err) {
                    const e = err as BusinessError
                  }
                })
              Button('Pop')
                .fontSize(13)
                .height(36)
                .onClick(() => {
                  this.navPathStack.pop()
                })
            }
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
        }
        .navDestination(this.pageMap)
        .height(250)
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
          Text('setInterception(interception: NavigationInterception)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('NavigationInterception 回调:')
            .fontSize(12)
            .fontColor('#666666')
            .width('100%')
          Text('  willShow: 页面即将显示前触发，允许操作栈')
            .fontSize(11)
            .fontColor('#999999')
            .fontFamily('monospace')
            .width('100%')
          Text('  didShow: 页面显示完成后触发')
            .fontSize(11)
            .fontColor('#999999')
            .fontFamily('monospace')
            .width('100%')
          Text('回调参数: (from, to, operation, isAnimated)')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('  from/to: NavDestinationContext | NavBar')
            .fontSize(11)
            .fontColor('#999999')
            .fontFamily('monospace')
            .width('100%')
          Text('  operation: NavigationOperation.PUSH | POP | REPLACE')
            .fontSize(11)
            .fontColor('#999999')
            .fontFamily('monospace')
            .width('100%')
          Text('典型用途：页面跳转埋点、权限拦截、页面跳转动画控制')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
            .margin({ top: 4 })
          Text('元服务：API 12+ 支持')
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
struct InterceptSubPage {
  pageInfo: NavPathStack = new NavPathStack()
  @State pageName: string = ''

  build() {
    NavDestination() {
      Column({ space: 12 }) {
        Text(`拦截页 ${this.pageName}`)
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
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
    .title(`Intercept ${this.pageName}`)
    .onReady((context: NavDestinationContext) => {
      this.pageInfo = context.pathStack
    })
  }
}
