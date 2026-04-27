/**
 * navigation-router-stack-query — 路由栈查询与动画控制
 * 展示 getAllPathName、getParamByIndex、getParamByName、getIndexByName、size、disableAnimation
 * 元服务兼容性：查询方法 API 11+，disableAnimation API 12+
 */
import { BusinessError } from '@kit.BasicServicesKit'

interface QueryParam {
  id: number
  type: string
}

@ComponentV2
export struct NavigationRouterStackQuery {
  @Local resultText: string = '操作路由栈后点击查询按钮获取信息'
  @Local queryResult: string = ''
  @Local isAnimationDisabled: boolean = false
  navPathStack: NavPathStack = new NavPathStack()

  @Builder
  pageMap(name: string) {
    if (name === 'queryPageA') {
      StackQuerySubPage({ pageName: 'A' })
    } else if (name === 'queryPageB') {
      StackQuerySubPage({ pageName: 'B' })
    }
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('路由栈查询与动画控制')
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

        // 查询结果区
        Column() {
          Text('查询结果:')
            .fontSize(13)
            .fontWeight(FontWeight.Medium)
            .width('100%')
            .margin({ bottom: 4 })
          Text(this.queryResult || '（点击查询按钮获取信息）')
            .fontSize(12)
            .fontColor('#666666')
            .width('100%')
        }
        .width('90%')
        .backgroundColor('#F0F8FF')
        .borderRadius(8)
        .padding(12)

        // 导航预览区
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
                    const paramA: QueryParam = { id: 100, type: 'article' }
                    this.navPathStack.pushPathByName('queryPageA', paramA as Object, true)
                    this.resultText = `pushPathByName(queryPageA) 成功，size=${this.navPathStack.size()}`
                  } catch (err) {
                    const e = err as BusinessError
                    this.resultText = `失败: ${e.message}`
                  }
                })
              Button('Push B')
                .fontSize(12)
                .height(32)
                .onClick(() => {
                  try {
                    const paramB: QueryParam = { id: 200, type: 'video' }
                    this.navPathStack.pushPathByName('queryPageB', paramB as Object, true)
                    this.resultText = `pushPathByName(queryPageB) 成功，size=${this.navPathStack.size()}`
                  } catch (err) {
                    const e = err as BusinessError
                    this.resultText = `失败: ${e.message}`
                  }
                })
              Button('Pop')
                .fontSize(12)
                .height(32)
                .onClick(() => {
                  this.navPathStack.pop()
                  this.resultText = `pop 成功，size=${this.navPathStack.size()}`
                })
              Button('Clear')
                .fontSize(12)
                .height(32)
                .onClick(() => {
                  this.navPathStack.clear()
                  this.resultText = '已清空路由栈'
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

        // 查询按钮区
        Text('路由栈查询')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Row({ space: 8 }) {
          Button('getAllPathName')
            .fontSize(12)
            .height(32)
            .onClick(() => {
              const names = this.navPathStack.getAllPathName()
              this.queryResult = `所有页面名: [${names.join(', ')}]`
            })
          Button('size')
            .fontSize(12)
            .height(32)
            .onClick(() => {
              this.queryResult = `栈深度: ${this.navPathStack.size()}`
            })
        }

        Row({ space: 8 }) {
          Button('getParamByIndex')
            .fontSize(12)
            .height(32)
            .onClick(() => {
              if (this.navPathStack.size() > 0) {
                const param = this.navPathStack.getParamByIndex(0) as Object | undefined
                this.queryResult = `索引 0 参数: ${JSON.stringify(param)}`
              } else {
                this.queryResult = '栈为空，无参数可查询'
              }
            })
          Button('getParamByName')
            .fontSize(12)
            .height(32)
            .onClick(() => {
              const params = this.navPathStack.getParamByName('queryPageA') as Object[]
              this.queryResult = `queryPageA 参数列表: ${JSON.stringify(params)}`
            })
          Button('getIndexByName')
            .fontSize(12)
            .height(32)
            .onClick(() => {
              const indexes = this.navPathStack.getIndexByName('queryPageB')
              this.queryResult = `queryPageB 索引: ${JSON.stringify(indexes)}`
            })
        }

        Text('动画控制')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Row({ space: 8 }) {
          Button(this.isAnimationDisabled ? '恢复动画' : '禁用动画')
            .fontSize(12)
            .height(32)
            .backgroundColor(this.isAnimationDisabled ? '#FF6B00' : '#007DFF')
            .onClick(() => {
              try {
                this.isAnimationDisabled = !this.isAnimationDisabled
                this.navPathStack.disableAnimation(this.isAnimationDisabled)
                this.resultText = `动画已${this.isAnimationDisabled ? '禁用' : '恢复'}`
              } catch (err) {
                const e = err as BusinessError
                this.resultText = `disableAnimation 失败: ${e.message}`
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
          Text('getAllPathName(): Array<string> — 获取栈中所有页面名称')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('size(): number — 获取当前栈深度')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('getParamByIndex(index): Object | undefined — 按索引获取参数')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('getParamByName(name): Array<Object> — 按名称获取所有同名页参数')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('getIndexByName(name): Array<number> — 按名称获取页面索引列表')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('disableAnimation(value: boolean) — 禁用/启用路由转场动画')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('元服务：查询方法 API 11+，disableAnimation API 12+')
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
struct StackQuerySubPage {
  pageInfo: NavPathStack = new NavPathStack()
  @State pageName: string = ''

  build() {
    NavDestination() {
      Column({ space: 12 }) {
        Text(`查询页 ${this.pageName}`)
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
    .title(`Query Page ${this.pageName}`)
    .onReady((context: NavDestinationContext) => {
      this.pageInfo = context.pathStack
    })
  }
}
