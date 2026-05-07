/**
 * span-basic — Span 基础创建与多段内联文本
 * 展示 Span 作为 Text 子组件创建多个行内文本段，不同字体颜色、大小
 * 元服务兼容性：Span(value) / fontColor / fontSize / fontWeight 元服务 API 7+ 可用
 */
@ComponentV2
export struct SpanBasic {
  @Local resultText: string = '展示 Span 基础内联文本'
  @Local eventLog: string = '点击按钮切换示例'

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('Span 基础创建')
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

        // 多段 Span 演示
        Column() {
          Text('多段 Span 示例:')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .width('100%')
            .margin({ bottom: 8 })

          Text() {
            Span('正常文本，')
              .fontSize(16)
            Span('红色粗体，')
              .fontSize(16)
              .fontColor(Color.Red)
              .fontWeight(FontWeight.Bold)
            Span('蓝色斜体，')
              .fontSize(16)
              .fontColor(Color.Blue)
              .fontStyle(FontStyle.Italic)
            Span('绿色大字')
              .fontSize(20)
              .fontColor(Color.Green)
          }
          .width('100%')
          .padding(12)
          .borderWidth(1)
          .borderColor('#E0E0E0')
          .borderRadius(4)
        }
        .width('90%')
        .padding(12)
        .backgroundColor('#FFFFFF')
        .borderRadius(8)
        .shadow({ radius: 2, color: '#22000000', offsetX: 0, offsetY: 1 })

        // Text 与 Span 同时存在
        Column() {
          Text('Text 与 Span 同时设置:')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .width('100%')
            .margin({ bottom: 8 })

          Text('Text 的文本内容') {
            Span('Span 内容覆盖了 Text 的内容')
              .fontSize(14)
              .fontColor('#FF6600')
          }
          .width('100%')
          .padding(12)
          .borderWidth(1)
          .borderColor('#E0E0E0')
          .borderRadius(4)
        }
        .width('90%')
        .padding(12)
        .backgroundColor('#FFFFFF')
        .borderRadius(8)
        .shadow({ radius: 2, color: '#22000000', offsetX: 0, offsetY: 1 })

        // 操作按钮
        Column() {
          Text('参数控制')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .width('100%')
            .margin({ bottom: 8 })

          Row({ space: 8 }) {
            Button('切换内容')
              .fontSize(12)
              .height(36)
              .onClick(() => {
                try {
                  this.resultText = 'Span 可在 Text 内创建多个行内文本段'
                  this.eventLog = 'Span 创建成功'
                } catch (err) {
                  this.eventLog = `错误: ${(err as BusinessError).message}`
                }
              })
          }
        }
        .width('90%')
        .padding(12)
        .backgroundColor('#FFFFFF')
        .borderRadius(8)
        .shadow({ radius: 2, color: '#22000000', offsetX: 0, offsetY: 1 })

        // 事件日志区
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

        // API 说明区
        Column() {
          Text('API 说明')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 8 })
          Text('Span(value: string | Resource)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('作为 Text / RichEditor 子组件显示行内文本')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('Text 与 Span 同时配置文本时, Span 内容覆盖 Text 内容')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('.fontColor / .fontSize / .fontWeight / .fontStyle')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('元服务兼容: Span() 及基础样式属性 API 7+ 可用')
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
