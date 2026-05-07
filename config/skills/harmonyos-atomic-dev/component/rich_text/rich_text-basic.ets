/**
 * rich_text-basic — RichText 基础富文本显示
 * 展示 RichText 组件在元服务中的限制，以及 Text+Span 替代方案
 * 元服务兼容性：RichText 不支持元服务，使用 Text+Span 替代
 */

import { BusinessError } from '@kit.BasicServicesKit'

@ComponentV2
export struct RichTextBasic {
  @Local resultText: string = '等待操作...'
  @Local eventLog: string = ''
  @Local currentContent: string = 'heading'

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('RichText 基础富文本显示')
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
          Row() {
            Text('⚠ ')
              .fontSize(16)
            Text('RichText 组件不支持元服务 (atomicService)')
              .fontSize(14)
              .fontColor('#E65100')
              .fontWeight(FontWeight.Medium)
          }
          .width('100%')
          .margin({ bottom: 8 })
          Text('RichText 是 JS UI 框架组件 (<richtext>)，非 ArkUI 声明式组件')
            .fontSize(12)
            .fontColor('#666666')
            .width('100%')
            .margin({ bottom: 4 })
          Text('替代方案：使用 Text + Span 组合实现富文本显示效果')
            .fontSize(12)
            .fontColor('#666666')
            .width('100%')
        }
        .width('90%')
        .backgroundColor('#FFF3E0')
        .borderRadius(8)
        .padding(16)
        .borderWidth(1)
        .borderColor('#FFE0B2')

        // Text+Span 替代展示区
        Text('Text + Span 替代方案')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Column() {
          if (this.currentContent === 'heading') {
            // 标题展示
            Text() {
              Span('标题 H1').fontSize(28).fontWeight(FontWeight.Bold)
            }
            .width('100%')
            .margin({ bottom: 8 })
            Text() {
              Span('标题 H2').fontSize(24).fontWeight(FontWeight.Bold)
            }
            .width('100%')
            .margin({ bottom: 8 })
            Text() {
              Span('标题 H3').fontSize(20).fontWeight(FontWeight.Bold)
            }
            .width('100%')
          } else if (this.currentContent === 'paragraph') {
            // 段落展示
            Text() {
              Span('这是一段普通文本。')
                .fontSize(14)
                .fontColor('#333333')
              Span('这是粗体文本。')
                .fontSize(14)
                .fontWeight(FontWeight.Bold)
              Span('这是斜体文本。')
                .fontSize(14)
                .fontStyle(FontStyle.Italic)
              Span('这是带下划线的文本。')
                .fontSize(14)
                .decoration({ type: TextDecorationType.Underline, color: '#000000' })
            }
            .width('100%')
            .lineHeight(24)
          } else if (this.currentContent === 'list') {
            // 列表展示
            Text() {
              Span('• 列表项 1：支持设置字体颜色\n')
                .fontSize(14)
                .fontColor('#333333')
              Span('• 列表项 2：支持设置字体大小\n')
                .fontSize(14)
                .fontColor('#333333')
              Span('• 列表项 3：支持设置粗体样式\n')
                .fontSize(14)
                .fontColor('#333333')
              Span('• 列表项 4：支持混合样式组合\n')
                .fontSize(14)
                .fontColor('#333333')
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

        // 操作按钮
        Row({ space: 8 }) {
          Button('标题')
            .fontSize(13)
            .layoutWeight(1)
            .height(36)
            .backgroundColor(this.currentContent === 'heading' ? '#1976D2' : '#007DFF')
            .onClick(() => {
              try {
                this.currentContent = 'heading'
                this.resultText = '展示标题样式 (H1-H3)'
                this.eventLog = '切换到标题展示'
              } catch (err) {
                const error = err as BusinessError
                this.resultText = `错误: ${error.code} - ${error.message}`
              }
            })
          Button('段落')
            .fontSize(13)
            .layoutWeight(1)
            .height(36)
            .backgroundColor(this.currentContent === 'paragraph' ? '#1976D2' : '#007DFF')
            .onClick(() => {
              try {
                this.currentContent = 'paragraph'
                this.resultText = '展示段落样式 (粗体/斜体/下划线)'
                this.eventLog = '切换到段落展示'
              } catch (err) {
                const error = err as BusinessError
                this.resultText = `错误: ${error.code} - ${error.message}`
              }
            })
          Button('列表')
            .fontSize(13)
            .layoutWeight(1)
            .height(36)
            .backgroundColor(this.currentContent === 'list' ? '#1976D2' : '#007DFF')
            .onClick(() => {
              try {
                this.currentContent = 'list'
                this.resultText = '展示列表样式'
                this.eventLog = '切换到列表展示'
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
          Text('API 说明')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 8 })
          Text('RichText 为 JS UI 框架组件，非 ArkUI 声明式组件')
            .fontSize(12)
            .fontColor('#E65100')
            .width('100%')
          Text('JS 用法: <richtext @start="..." @complete="...">{{content}}</richtext>')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
            .margin({ top: 4 })
          Text('事件: start(开始加载) / complete(加载完成)')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('属性: 仅支持 id、style、class')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('样式: 仅支持 display、visibility')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('元服务：不支持，需使用 Text+Span 或 RichEditor 替代')
            .fontSize(12)
            .fontColor('#E65100')
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
