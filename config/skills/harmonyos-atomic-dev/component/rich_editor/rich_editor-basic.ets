/**
 * rich_editor-basic — RichEditor 基础富文本编辑
 * 展示 RichEditor 基本创建与文本编辑
 * 元服务兼容性：API 11+ 可用
 */

import { BusinessError } from '@kit.BasicServicesKit'

@ComponentV2
export struct RichEditorBasic {
  @Local resultText: string = '等待操作...'
  controller: RichEditorController = new RichEditorController()

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('RichEditor 基础富文本编辑')
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

        // RichEditor 编辑区
        Text('编辑区')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        RichEditor({ controller: this.controller })
          .width('90%')
          .height(200)
          .borderWidth(1)
          .borderColor('#CCCCCC')
          .borderRadius(8)
          .padding(12)
          .onReady(() => {
            this.resultText = 'RichEditor 已就绪'
          })

        // 操作按钮
        Row({ space: 8 }) {
          Button('添加文本')
            .fontSize(13)
            .layoutWeight(1)
            .height(36)
            .onClick(() => {
              try {
                this.controller.addTextSpan('Hello RichEditor! ')
                this.resultText = '已添加文本段'
              } catch (error) {
                const err = error as BusinessError
                this.resultText = `错误: ${err.code} - ${err.message}`
              }
            })
          Button('添加样式文本')
            .fontSize(13)
            .layoutWeight(1)
            .height(36)
            .onClick(() => {
              try {
                this.controller.addTextSpan('红色粗体 ', {
                  style: {
                    fontColor: '#FF0000',
                    fontSize: 20,
                    fontWeight: FontWeight.Bold
                  }
                })
                this.resultText = '已添加红色粗体文本'
              } catch (error) {
                const err = error as BusinessError
                this.resultText = `错误: ${err.code} - ${err.message}`
              }
            })
          Button('清空重置')
            .fontSize(13)
            .layoutWeight(1)
            .height(36)
            .onClick(() => {
              this.controller = new RichEditorController()
              this.resultText = '已清空内容'
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
          Text('RichEditor({ controller: RichEditorController })')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('controller.addTextSpan(text, options?) — 添加文本段')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('options.style 可设置 fontColor/fontSize/fontWeight 等')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('元服务：API 11+ 可用')
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
