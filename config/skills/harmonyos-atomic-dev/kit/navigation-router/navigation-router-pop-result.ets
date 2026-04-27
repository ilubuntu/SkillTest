/**
 * navigation-router-pop-result — pop 返回传值与 onPop 回调
 * 展示 pop(result) 返回数据、pushPathByName 的 onPop 回调接收返回值
 * 元服务兼容性：API 12+
 */
import { BusinessError } from '@kit.BasicServicesKit'

interface PopResultData {
  message: string
}

interface FormResultData {
  formResult: string
}

@ComponentV2
export struct NavigationRouterPopResult {
  @Local resultText: string = '点击按钮跳转，子页面 pop 时可携带返回值'
  @Local returnedValue: string = '（等待返回值）'
  navPathStack: NavPathStack = new NavPathStack()

  @Builder
  pageMap(name: string) {
    if (name === 'formPage') {
      PopResultFormPage({ onReturnData: (data: string) => {
        this.returnedValue = data
        this.resultText = `收到子页面返回数据: ${data}`
      }})
    }
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('pop 返回传值与 onPop 回调')
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
          Text(`返回值: ${this.returnedValue}`)
            .fontSize(13)
            .fontColor('#4CAF50')
            .width('100%')
            .padding({ left: 12, bottom: 8 })
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
            Text(`onPop 返回值: ${this.returnedValue}`)
              .fontSize(13)
              .fontColor('#4CAF50')
            Row({ space: 8 }) {
              Button('pushPathByName + onPop')
                .fontSize(13)
                .height(36)
                .onClick(() => {
                  try {
                    this.navPathStack.pushPathByName('formPage', '首页传来的初始数据', (popInfo: PopInfo) => {
                      const result = popInfo.result
                      if (result) {
                        this.returnedValue = JSON.stringify(result)
                        this.resultText = `onPop 回调收到返回值`
                      }
                    }, false)
                  } catch (err) {
                    const e = err as BusinessError
                    this.resultText = `pushPathByName 失败: ${e.message}`
                  }
                })
              Button('普通 pop 测试')
                .fontSize(13)
                .height(36)
                .onClick(() => {
                  try {
                    const info = this.navPathStack.pop('首页主动 pop 的返回值' as Object, false)
                    if (info) {
                      this.resultText = `pop 成功，弹出页面: ${info.name}`
                    } else {
                      this.resultText = '栈为空，无页面可 pop'
                    }
                  } catch (err) {
                    const e = err as BusinessError
                    this.resultText = `pop 失败: ${e.message}`
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
          Text('pushPathByName(name, param, onPop, animated?)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('  onPop: Callback<PopInfo> — 页面 pop 时的回调')
            .fontSize(11)
            .fontColor('#999999')
            .fontFamily('monospace')
            .width('100%')
          Text('  PopInfo.result 包含 pop 时传递的返回值')
            .fontSize(11)
            .fontColor('#999999')
            .fontFamily('monospace')
            .width('100%')
          Text('pop(result?, animated?) — 携带返回值出栈')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('  result: 任意对象，传递给 onPop 回调')
            .fontSize(11)
            .fontColor('#999999')
            .fontFamily('monospace')
            .width('100%')
          Text('popToName(name, result?, animated?) — 携带返回值返回指定页面')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('典型场景：表单页填写完成后 pop(result) 将数据返回给列表页')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
            .margin({ top: 4 })
          Text('元服务：pop(result) 和 pushPathByName onPop 均从 API 12+ 支持')
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
struct PopResultFormPage {
  pageInfo: NavPathStack = new NavPathStack()
  @State inputText: string = '表单填写的内容'
  onReturnData: (data: string) => void = () => {}

  build() {
    NavDestination() {
      Column({ space: 12 }) {
        Text('表单页（formPage）')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
        TextInput({ text: $$this.inputText, placeholder: '输入要返回的数据' })
          .width('80%')
          .height(40)
          .fontSize(14)
        Row({ space: 8 }) {
          Button('Pop 返回值')
            .fontSize(13)
            .height(36)
            .onClick(() => {
              try {
                const resultData: FormResultData = { formResult: this.inputText }
                this.pageInfo.pop(resultData as Object, false)
              } catch (err) {
                const e = err as BusinessError
              }
            })
          Button('普通 Pop')
            .fontSize(13)
            .height(36)
            .onClick(() => {
              this.pageInfo.pop()
            })
        }
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
    }
    .title('Form')
    .onReady((context: NavDestinationContext) => {
      this.pageInfo = context.pathStack
    })
  }
}
