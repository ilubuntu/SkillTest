/**
 * span-event — Span 点击与悬浮事件
 * 展示 Span 组件的 onClick 点击事件和 onHover 悬浮事件
 * 元服务兼容性：onClick / onHover 元服务可用
 */
@ComponentV2
export struct SpanEvent {
  @Local resultText: string = '点击或悬浮 Span 查看事件'
  @Local clickLog: string = '等待点击...'
  @Local hoverLog: string = '等待悬浮...'
  @Local clickCount: number = 0

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('Span 点击与悬浮事件')
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

        // 可交互 Span 展示
        Column() {
          Text('交互式 Span:')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .width('100%')
            .margin({ bottom: 8 })

          Text() {
            Span('点击我')
              .fontSize(18)
              .fontColor('#1976D2')
              .decoration({ type: TextDecorationType.Underline, color: '#1976D2' })
              .onClick(() => {
                try {
                  this.clickCount++
                  this.clickLog = `Span onClick 触发! 第 ${this.clickCount} 次点击`
                  this.resultText = `已点击 ${this.clickCount} 次`
                } catch (err) {
                  this.clickLog = `错误: ${(err as BusinessError).message}`
                }
              })
            Span('  |  ')
              .fontSize(18)
              .fontColor('#CCCCCC')
            Span('悬浮我')
              .fontSize(18)
              .fontColor('#388E3C')
              .decoration({ type: TextDecorationType.Underline, color: '#388E3C' })
              .onHover((isHover: boolean) => {
                try {
                  this.hoverLog = `Span onHover: isHover=${isHover}`
                  this.resultText = isHover ? '鼠标悬浮中' : '鼠标离开'
                } catch (err) {
                  this.hoverLog = `错误: ${(err as BusinessError).message}`
                }
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

        // 操作按钮
        Column() {
          Text('参数控制')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .width('100%')
            .margin({ bottom: 8 })

          Row({ space: 8 }) {
            Button('重置计数')
              .fontSize(12)
              .height(36)
              .onClick(() => {
                try {
                  this.clickCount = 0
                  this.clickLog = '计数已重置'
                  this.resultText = '计数已重置'
                } catch (err) {
                  this.clickLog = `错误: ${(err as BusinessError).message}`
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
          Text('点击事件:')
            .fontSize(12)
            .fontWeight(FontWeight.Bold)
            .width('100%')
          Text(this.clickLog)
            .fontSize(12)
            .fontColor('#666666')
            .width('100%')
            .margin({ top: 4 })
          Text('悬浮事件:')
            .fontSize(12)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ top: 8 })
          Text(this.hoverLog)
            .fontSize(12)
            .fontColor('#666666')
            .width('100%')
            .margin({ top: 4 })
        }
        .width('90%')
        .backgroundColor('#F0F0F0')
        .borderRadius(8)
        .padding(12)

        // API 说明区
        Column() {
          Text('API 说明')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 8 })
          Text('.onClick(handler: () => void)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('.onHover(handler: (isHover: boolean) => void)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('Span 无尺寸信息, 仅支持 onClick 和 onHover 事件')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('元服务兼容: onClick / onHover 可用')
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
