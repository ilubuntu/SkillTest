/**
 * span-decoration — Span 文本装饰线与大小写
 * 展示 Span 的 decoration 文本装饰线和 textCase 大小写转换
 * 元服务兼容性：decoration / textCase 元服务可用
 */
@ComponentV2
export struct SpanDecoration {
  @Local resultText: string = '展示文本装饰线与大小写'
  @Local eventLog: string = '点击按钮切换装饰类型'
  @Local decoType: number = 0

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('Span 装饰线与大小写')
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

        // 装饰线演示
        Column() {
          Text('文本装饰线:')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .width('100%')
            .margin({ bottom: 8 })

          Text() {
            Span('删除线效果')
              .fontSize(16)
              .decoration({ type: TextDecorationType.LineThrough, color: Color.Red })
            Span('\n下划线效果')
              .fontSize(16)
              .decoration({ type: TextDecorationType.Underline, color: Color.Blue })
            Span('\n上划线效果')
              .fontSize(16)
              .decoration({ type: TextDecorationType.Overline, color: Color.Green })
            Span('\n波浪下划线')
              .fontSize(16)
              .decoration({
                type: TextDecorationType.Underline,
                color: Color.Orange,
                style: TextDecorationStyle.WAVY
              })
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

        // textCase 大小写演示
        Column() {
          Text('大小写转换:')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .width('100%')
            .margin({ bottom: 8 })

          Text() {
            Span('normal text')
              .fontSize(16)
              .textCase(TextCase.Normal)
            Span('\nUPPERCASE TEXT')
              .fontSize(16)
              .textCase(TextCase.LowerCase)
            Span('\nlowercase text')
              .fontSize(16)
              .textCase(TextCase.UpperCase)
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
            Button('切换装饰')
              .fontSize(12)
              .height(36)
              .onClick(() => {
                try {
                  this.decoType = (this.decoType + 1) % 4
                  const types = ['删除线', '下划线', '上划线', '波浪下划线']
                  this.resultText = `当前装饰: ${types[this.decoType]}`
                  this.eventLog = '装饰切换成功'
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
          Text('.decoration({type, color, style})')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('type: LineThrough / Underline / Overline / None')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('style: SOLID / DOUBLED / DOTTED / DASHED / WAVY')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('.textCase(value: TextCase)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('元服务兼容: decoration API 7+, textCase API 10+ 可用')
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
