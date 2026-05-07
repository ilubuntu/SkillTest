/**
 * text_area_controller — TextArea 控制器
 * 展示 TextAreaController 用法：caretPosition、getTextContentRect、getTextContentLineCount
 * 元服务兼容性：TextAreaController API 8+，元服务 API 11+ 可用
 */

import { BusinessError } from '@kit.BasicServicesKit'

@ComponentV2
export struct TextAreaControllerOps {
  @Local resultText: string = '等待操作...'
  @Local inputText: string = '这是一段示例文本，用于演示控制器功能。\n第二行内容。\n第三行内容。'
  @Local caretPos: number = 0
  @Local lineCount: string = '未知'
  @Local contentRect: string = '未知'
  controller: TextAreaController = new TextAreaController()

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('TextArea 控制器')
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

        // TextArea 绑定控制器
        Text('输入框（绑定 TextAreaController）')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        TextArea({ text: this.inputText, placeholder: '输入文本...', controller: this.controller })
          .width('90%')
          .height(150)
          .onChange((value: string) => {
            this.inputText = value
          })

        // 光标位置控制
        Text(`光标位置: ${this.caretPos}`)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Row({ space: 8 }) {
          Button('-10')
            .fontSize(13)
            .layoutWeight(1)
            .height(36)
            .onClick(() => {
              this.caretPos = Math.max(0, this.caretPos - 10)
            })
          Button('-1')
            .fontSize(13)
            .layoutWeight(1)
            .height(36)
            .onClick(() => {
              this.caretPos = Math.max(0, this.caretPos - 1)
            })
          Button('+1')
            .fontSize(13)
            .layoutWeight(1)
            .height(36)
            .onClick(() => {
              this.caretPos = Math.min(this.inputText.length, this.caretPos + 1)
            })
          Button('+10')
            .fontSize(13)
            .layoutWeight(1)
            .height(36)
            .onClick(() => {
              this.caretPos = Math.min(this.inputText.length, this.caretPos + 10)
            })
        }
        .width('90%')

        Row({ space: 8 }) {
          Button('设置光标位置')
            .fontSize(13)
            .layoutWeight(1)
            .height(36)
            .onClick(() => {
              try {
                this.controller.caretPosition(this.caretPos)
                this.resultText = `光标已设置到位置 ${this.caretPos}`
              } catch (e) {
                const err = e as BusinessError
                this.resultText = `设置光标异常: code=${err.code}, msg=${err.message}`
              }
            })
          Button('移到末尾')
            .fontSize(13)
            .layoutWeight(1)
            .height(36)
            .onClick(() => {
              try {
                this.caretPos = this.inputText.length
                this.controller.caretPosition(this.caretPos)
                this.resultText = `光标已移到末尾 (位置 ${this.caretPos})`
              } catch (e) {
                const err = e as BusinessError
                this.resultText = `异常: ${(e as Error).message}`
              }
            })
        }
        .width('90%')

        // 信息查询
        Text('信息查询')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Row({ space: 8 }) {
          Button('获取行数')
            .fontSize(13)
            .layoutWeight(1)
            .height(36)
            .onClick(() => {
              try {
                const count = this.controller.getTextContentLineCount()
                this.lineCount = `${count}`
                this.resultText = `当前文本行数: ${count}`
              } catch (e) {
                const err = e as BusinessError
                this.resultText = `获取行数异常: code=${err.code}, msg=${err.message}`
              }
            })
          Button('获取文本区域')
            .fontSize(13)
            .layoutWeight(1)
            .height(36)
            .onClick(() => {
              try {
                const rect = this.controller.getTextContentRect()
                this.contentRect = `x=${rect.x.toFixed(0)}, y=${rect.y.toFixed(0)}, w=${rect.width.toFixed(0)}, h=${rect.height.toFixed(0)}`
                this.resultText = `文本区域: ${this.contentRect}`
              } catch (e) {
                const err = e as BusinessError
                this.resultText = `获取区域异常: code=${err.code}, msg=${err.message}`
              }
            })
        }
        .width('90%')

        // API 说明区
        Column() {
          Text('API 说明')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 8 })
          Text('TextAreaController — 文本区域控制器')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('.caretPosition(index: number): 设置光标位置')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('.getTextContentLineCount(): number — 获取文本行数')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('.getTextContentRect(): RectResult — 获取文本内容区域')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('元服务：TextAreaController API 8+ 可用，API 11+ 支持元服务')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
        }
        .width('90%')
        .backgroundColor('#FFF9E6')
        .borderRadius(8)
        .padding(12)
        .margin({ top: 8, bottom: 20 })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
  }
}
