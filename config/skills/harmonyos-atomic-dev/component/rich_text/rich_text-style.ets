/**
 * rich_text-style — RichText 富文本样式展示
 * 展示通过 Text+Span 组合实现多种富文本样式效果
 * 元服务兼容性：RichText 不支持，使用 Text+Span 替代
 */

import { BusinessError } from '@kit.BasicServicesKit'

@ComponentV2
export struct RichTextStyle {
  @Local resultText: string = '选择下方样式查看效果'
  @Local eventLog: string = ''
  @Local selectedStyle: string = 'color'

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('RichText 富文本样式')
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

        // 元服务不支持提示
        Column() {
          Text('⚠ RichText 不支持元服务，以下使用 Text+Span 实现等效效果')
            .fontSize(13)
            .fontColor('#E65100')
            .width('100%')
        }
        .width('90%')
        .backgroundColor('#FFF3E0')
        .borderRadius(8)
        .padding(12)
        .borderWidth(1)
        .borderColor('#FFE0B2')

        // 样式展示区
        Column() {
          Text('样式效果预览')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .width('100%')
            .margin({ bottom: 12 })

          if (this.selectedStyle === 'color') {
            // 颜色样式
            Text() {
              Span('红色文本 ').fontColor('#FF0000').fontSize(16)
              Span('蓝色文本 ').fontColor('#2196F3').fontSize(16)
              Span('绿色文本 ').fontColor('#4CAF50').fontSize(16)
              Span('橙色文本 ').fontColor('#FF9800').fontSize(16)
              Span('紫色文本').fontColor('#9C27B0').fontSize(16)
            }
            .width('100%')
            .lineHeight(28)
          } else if (this.selectedStyle === 'fontSize') {
            // 字号样式
            Text() {
              Span('12号字体 ').fontSize(12)
              Span('14号字体 ').fontSize(14)
              Span('16号字体 ').fontSize(16)
              Span('20号字体 ').fontSize(20)
              Span('24号字体').fontSize(24)
            }
            .width('100%')
            .lineHeight(36)
          } else if (this.selectedStyle === 'fontWeight') {
            // 字重样式
            Text() {
              Span('Lighter ').fontWeight(FontWeight.Lighter).fontSize(16)
              Span('Normal ').fontWeight(FontWeight.Normal).fontSize(16)
              Span('Regular ').fontWeight(FontWeight.Regular).fontSize(16)
              Span('Bold').fontWeight(FontWeight.Bold).fontSize(16)
            }
            .width('100%')
            .lineHeight(28)
          } else if (this.selectedStyle === 'decoration') {
            // 装饰样式
            Text() {
              Span('下划线文本 ')
                .fontSize(16)
                .decoration({ type: TextDecorationType.Underline, color: '#2196F3' })
              Span('删除线文本 ')
                .fontSize(16)
                .decoration({ type: TextDecorationType.LineThrough, color: '#FF0000' })
              Span('上划线文本')
                .fontSize(16)
                .decoration({ type: TextDecorationType.Overline, color: '#4CAF50' })
            }
            .width('100%')
            .lineHeight(28)
          } else if (this.selectedStyle === 'mixed') {
            // 混合样式
            Text() {
              Span('文章标题\n').fontSize(22).fontWeight(FontWeight.Bold).fontColor('#212121')
              Span('\n')
              Span('正文内容：这段文字展示了')
                .fontSize(14).fontColor('#424242')
              Span('粗体').fontWeight(FontWeight.Bold).fontSize(14)
              Span('、')
                .fontSize(14).fontColor('#424242')
              Span('斜体').fontStyle(FontStyle.Italic).fontSize(14)
              Span('、')
                .fontSize(14).fontColor('#424242')
              Span('彩色高亮').fontColor('#E91E63').fontSize(14).fontWeight(FontWeight.Bold)
              Span(' 等混合排版效果。')
                .fontSize(14).fontColor('#424242')
            }
            .width('100%')
            .lineHeight(24)
          }
        }
        .width('90%')
        .padding(16)
        .backgroundColor('#FFFFFF')
        .borderRadius(8)
        .borderWidth(1)
        .borderColor('#E0E0E0')

        // 样式切换按钮
        Row({ space: 6 }) {
          Button('颜色')
            .fontSize(12)
            .height(34)
            .layoutWeight(1)
            .backgroundColor(this.selectedStyle === 'color' ? '#1976D2' : '#007DFF')
            .onClick(() => {
              try {
                this.selectedStyle = 'color'
                this.resultText = '展示字体颜色样式'
                this.eventLog = 'Span.fontColor(string) 设置字体颜色'
              } catch (err) {
                const error = err as BusinessError
                this.resultText = `错误: ${error.code} - ${error.message}`
              }
            })
          Button('字号')
            .fontSize(12)
            .height(34)
            .layoutWeight(1)
            .backgroundColor(this.selectedStyle === 'fontSize' ? '#1976D2' : '#007DFF')
            .onClick(() => {
              try {
                this.selectedStyle = 'fontSize'
                this.resultText = '展示字体大小样式'
                this.eventLog = 'Span.fontSize(number) 设置字体大小'
              } catch (err) {
                const error = err as BusinessError
                this.resultText = `错误: ${error.code} - ${error.message}`
              }
            })
          Button('字重')
            .fontSize(12)
            .height(34)
            .layoutWeight(1)
            .backgroundColor(this.selectedStyle === 'fontWeight' ? '#1976D2' : '#007DFF')
            .onClick(() => {
              try {
                this.selectedStyle = 'fontWeight'
                this.resultText = '展示字重样式'
                this.eventLog = 'Span.fontWeight(FontWeight) 设置字重'
              } catch (err) {
                const error = err as BusinessError
                this.resultText = `错误: ${error.code} - ${error.message}`
              }
            })
        }
        .width('90%')

        Row({ space: 6 }) {
          Button('装饰线')
            .fontSize(12)
            .height(34)
            .layoutWeight(1)
            .backgroundColor(this.selectedStyle === 'decoration' ? '#1976D2' : '#007DFF')
            .onClick(() => {
              try {
                this.selectedStyle = 'decoration'
                this.resultText = '展示文本装饰线样式'
                this.eventLog = 'Span.decoration({type, color}) 设置装饰线'
              } catch (err) {
                const error = err as BusinessError
                this.resultText = `错误: ${error.code} - ${error.message}`
              }
            })
          Button('混合排版')
            .fontSize(12)
            .height(34)
            .layoutWeight(1)
            .backgroundColor(this.selectedStyle === 'mixed' ? '#1976D2' : '#007DFF')
            .onClick(() => {
              try {
                this.selectedStyle = 'mixed'
                this.resultText = '展示混合排版效果'
                this.eventLog = '多个 Span 组合实现复杂排版'
              } catch (err) {
                const error = err as BusinessError
                this.resultText = `错误: ${error.code} - ${error.message}`
              }
            })
        }
        .width('90%')

        // 事件日志
        if (this.eventLog) {
          Column() {
            Text(this.eventLog)
              .fontSize(12)
              .fontColor('#666666')
              .width('100%')
              .padding(12)
          }
          .width('90%')
          .backgroundColor('#F0F0F0')
          .borderRadius(8)
        }

        // API 说明区
        Column() {
          Text('API 说明 — Text + Span 替代方案')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 8 })
          Text('Span.fontColor(value: string) — 设置字体颜色')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('Span.fontSize(value: number) — 设置字体大小')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('Span.fontWeight(value: FontWeight) — 设置字重')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('Span.fontStyle(value: FontStyle) — 设置斜体')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('Span.decoration({type, color}) — 设置装饰线')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('Text().lineHeight(value) — 设置行高')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('元服务：Text+Span API 11+ 完全可用')
            .fontSize(12)
            .fontColor('#4CAF50')
            .width('100%')
            .margin({ top: 4 })
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
