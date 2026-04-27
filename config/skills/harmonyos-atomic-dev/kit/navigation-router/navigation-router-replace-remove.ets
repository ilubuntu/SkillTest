/**
 * navigation-router-replace-remove — 页面替换与栈管理
 * 展示 replacePathByName、removeByName、removeByIndexes、moveToTop、moveIndexToTop
 * 元服务兼容性：replacePathByName/removeByName/removeByIndexes API 12+，moveToTop/moveIndexToTop API 11+
 */
import { BusinessError } from '@kit.BasicServicesKit'

@ComponentV2
export struct NavigationRouterReplaceRemove {
  @Local resultText: string = '点击按钮操作路由栈'
  @Local stackSize: number = 0
  @Local pathNames: string = ''
  navPathStack: NavPathStack = new NavPathStack()

  @Builder
  pageMap(name: string) {
    if (name === 'pageAlpha') {
      ReplaceRemoveSubPage({ pageName: 'Alpha' })
    } else if (name === 'pageBeta') {
      ReplaceRemoveSubPage({ pageName: 'Beta' })
    } else if (name === 'pageGamma') {
      ReplaceRemoveSubPage({ pageName: 'Gamma' })
    }
  }

  private refreshStack(): void {
    this.stackSize = this.navPathStack.size()
    const names = this.navPathStack.getAllPathName()
    this.pathNames = names.join(' -> ')
    this.resultText = `栈深度: ${this.stackSize}，栈内容: ${this.pathNames || '(空)'}`
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('页面替换与栈管理')
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
                .fontSize(12)
                .height(32)
                .onClick(() => {
                  try {
                    this.navPathStack.pushPathByName('pageAlpha', null, false)
                    this.refreshStack()
                  } catch (err) {
                    const e = err as BusinessError
                    this.resultText = `pushPathByName 失败: ${e.message}`
                  }
                })
              Button('Push B')
                .fontSize(12)
                .height(32)
                .onClick(() => {
                  try {
                    this.navPathStack.pushPathByName('pageBeta', null, false)
                    this.refreshStack()
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
        .height(250)
        .width('90%')
        .borderRadius(8)
        .title('Navigation')
        .titleMode(NavigationTitleMode.Mini)

        // 操作按钮区
        Text('替换操作')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Row({ space: 8 }) {
          Button('Replace → Gamma')
            .fontSize(12)
            .height(32)
            .onClick(() => {
              try {
                this.navPathStack.replacePathByName('pageGamma', null, false)
                this.refreshStack()
              } catch (err) {
                const e = err as BusinessError
                this.resultText = `replacePathByName 失败: ${e.message}`
              }
            })
        }

        Text('删除操作')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Row({ space: 8 }) {
          Button('Remove Alpha')
            .fontSize(12)
            .height(32)
            .onClick(() => {
              try {
                const count = this.navPathStack.removeByName('pageAlpha')
                this.refreshStack()
                this.resultText = `removeByName 移除了 ${count} 个页面`
              } catch (err) {
                const e = err as BusinessError
                this.resultText = `removeByName 失败: ${e.message}`
              }
            })
          Button('Remove Index 0')
            .fontSize(12)
            .height(32)
            .onClick(() => {
              try {
                const count = this.navPathStack.removeByIndexes([0])
                this.refreshStack()
                this.resultText = `removeByIndexes 移除了 ${count} 个页面`
              } catch (err) {
                const e = err as BusinessError
                this.resultText = `removeByIndexes 失败: ${e.message}`
              }
            })
        }

        Text('移动操作')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Row({ space: 8 }) {
          Button('moveToTop Alpha')
            .fontSize(12)
            .height(32)
            .onClick(() => {
              try {
                const idx = this.navPathStack.moveToTop('pageAlpha', false)
                this.refreshStack()
                this.resultText = `moveToTop 返回索引: ${idx}`
              } catch (err) {
                const e = err as BusinessError
                this.resultText = `moveToTop 失败: ${e.message}`
              }
            })
          Button('Clear')
            .fontSize(12)
            .height(32)
            .onClick(() => {
              try {
                this.navPathStack.clear(false)
                this.refreshStack()
              } catch (err) {
                const e = err as BusinessError
                this.resultText = `clear 失败: ${e.message}`
              }
            })
        }

        // API 说明区
        Column() {
          Text('API 说明')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 8 })
          Text('replacePathByName(name, param, animated?) — 用指定页面替换栈顶')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('removeByName(name): number — 移除所有同名页面，返回移除数量')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('removeByIndexes(indexes): number — 按索引移除页面')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('moveToTop(name, animated?): number — 将同名页面移到栈顶')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('元服务：replace/remove API 12+，moveToTop API 11+')
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
struct ReplaceRemoveSubPage {
  pageInfo: NavPathStack = new NavPathStack()
  @State pageName: string = ''

  build() {
    NavDestination() {
      Column({ space: 12 }) {
        Text(`子页面 ${this.pageName}`)
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
    .title(`Page ${this.pageName}`)
    .onReady((context: NavDestinationContext) => {
      this.pageInfo = context.pathStack
    })
  }
}
