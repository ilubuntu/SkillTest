/**
 * rich_editor-style — RichEditor 文本样式
 * 展示 RichEditor 添加带样式的文本段
 * 元服务兼容性：API 11+ 可用
 */

import { BusinessError } from '@kit.BasicServicesKit'

@ComponentV2
export struct RichEditorStyle {
  @Local resultText: string = '等待操作...'
  controller: RichEditorController = new RichEditorController()

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('RichEditor 文本样式')
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
        Text('富文本编辑区')
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
            this.resultText = '编辑器就绪，点击按钮添加不同样式'
          })

        // 样式操作按钮
        Text('文本样式')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Row({ space: 8 }) {
          Button('红色大字')
            .fontSize(13)
            .layoutWeight(1)
            .height(36)
            .onClick(() => {
              try {
                this.controller.addTextSpan('红色大字 ', {
                  style: {
                    fontColor: '#FF0000',
                    fontSize: 24,
                    fontWeight: FontWeight.Bold
                  }
                })
                this.resultText = '添加红色 24px 粗体文本'
              } catch (error) {
                const err = error as BusinessError
                this.resultText = `错误: ${err.code} - ${err.message}`
              }
            })
          Button('蓝色斜体')
            .fontSize(13)
            .layoutWeight(1)
            .height(36)
            .onClick(() => {
              try {
                this.controller.addTextSpan('蓝色斜体 ', {
                  style: {
                    fontColor: '#2196F3',
                    fontSize: 16,
                    fontStyle: FontStyle.Italic
                  }
                })
                this.resultText = '添加蓝色 16px 斜体文本'
              } catch (error) {
                const err = error as BusinessError
                this.resultText = `错误: ${err.code} - ${err.message}`
              }
            })
          Button('下划线')
            .fontSize(13)
            .layoutWeight(1)
            .height(36)
            .onClick(() => {
              try {
                this.controller.addTextSpan('下划线文本 ', {
                  style: {
                    fontColor: '#333333',
                    fontSize: 16,
                    decoration: {
                      type: TextDecorationType.Underline,
                      color: '#FF0000'
                    }
                  }
                })
                this.resultText = '添加带红色下划线文本'
              } catch (error) {
                const err = error as BusinessError
                this.resultText = `错误: ${err.code} - ${err.message}`
              }
            })
        }
        .width('90%')

        Row({ space: 8 }) {
          Button('绿色删除线')
            .fontSize(13)
            .layoutWeight(1)
            .height(36)
            .onClick(() => {
              try {
                this.controller.addTextSpan('删除线 ', {
                  style: {
                    fontColor: '#4CAF50',
                    fontSize: 16,
                    decoration: {
                      type: TextDecorationType.LineThrough,
                      color: '#4CAF50'
                    }
                  }
                })
                this.resultText = '添加绿色删除线文本'
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
              this.resultText = '已清空'
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
          Text('addTextSpan(text, { style: { fontColor, fontSize, fontWeight, fontStyle, decoration } })')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('decoration: { type, color } 文本装饰（下划线/删除线）')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('fontStyle: FontStyle.Italic 斜体')
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
