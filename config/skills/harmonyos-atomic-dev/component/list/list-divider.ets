/**
 * list-divider — 列表分隔线
 * 展示 List divider 属性：strokeWidth, color, startMargin, endMargin
 * 元服务兼容性：divider API 9+，元服务 API 11+ 可用
 */
@ComponentV2
export struct ListDivider {
  @Local strokeWidth: number = 1
  @Local startMargin: number = 16
  @Local endMargin: number = 16
  @Local dividerColor: string = '#E0E0E0'
  @Local resultText: string = '分隔线: 1vp | 左边距: 16 | 右边距: 16'

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('列表分隔线')
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

        // 列表预览
        Text('分隔线效果')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        List({ space: 0 }) {
          ForEach(['蓝牙', 'WLAN', '移动数据', '更多连接', '通知', '声音', '显示', '电池'],
            (item: string, index?: number) => {
              ListItem() {
                Row() {
                  Text(`${(index ?? 0) + 1}`)
                    .fontSize(14)
                    .fontColor('#FFFFFF')
                    .width(28)
                    .height(28)
                    .textAlign(TextAlign.Center)
                    .borderRadius(14)
                    .backgroundColor('#607D8B')

                  Text(item)
                    .fontSize(16)
                    .margin({ left: 12 })
                    .layoutWeight(1)

                  Text('>')
                    .fontSize(14)
                    .fontColor('#CCCCCC')
                }
                .width('100%')
                .padding({ left: 16, right: 16, top: 14, bottom: 14 })
                .backgroundColor('#FFFFFF')
              }
            }, (item: string) => item)
        }
        .divider({
          strokeWidth: this.strokeWidth,
          color: this.dividerColor,
          startMargin: this.startMargin,
          endMargin: this.endMargin
        })
        .width('90%')
        .height(360)
        .borderRadius(8)
        .backgroundColor('#FFFFFF')

        // 参数控制
        Text('线宽')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Row({ space: 8 }) {
          Button('1vp')
            .fontSize(13)
            .width(60)
            .height(36)
            .onClick(() => { this.strokeWidth = 1; this.updateResult() })
          Button('2vp')
            .fontSize(13)
            .width(60)
            .height(36)
            .onClick(() => { this.strokeWidth = 2; this.updateResult() })
          Button('4vp')
            .fontSize(13)
            .width(60)
            .height(36)
            .onClick(() => { this.strokeWidth = 4; this.updateResult() })
        }

        Text('左边距')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Row({ space: 8 }) {
          Button('0')
            .fontSize(13)
            .width(50)
            .height(36)
            .onClick(() => { this.startMargin = 0; this.updateResult() })
          Button('16')
            .fontSize(13)
            .width(50)
            .height(36)
            .onClick(() => { this.startMargin = 16; this.updateResult() })
          Button('48')
            .fontSize(13)
            .width(50)
            .height(36)
            .onClick(() => { this.startMargin = 48; this.updateResult() })
        }

        Text('颜色')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Row({ space: 8 }) {
          Button('#E0E0E0')
            .fontSize(12)
            .width(80)
            .height(36)
            .onClick(() => { this.dividerColor = '#E0E0E0' })
          Button('#FF5722')
            .fontSize(12)
            .width(80)
            .height(36)
            .onClick(() => { this.dividerColor = '#FF5722' })
          Button('#4CAF50')
            .fontSize(12)
            .width(80)
            .height(36)
            .onClick(() => { this.dividerColor = '#4CAF50' })
        }

        // API 说明区
        Column() {
          Text('API 说明')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 8 })
          Text('.divider(value: ListDividerOptions | null)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('ListDividerOptions: { strokeWidth, color, startMargin, endMargin }')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('strokeWidth/startMargin/endMargin 不支持百分比')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('分隔线画在两个 ListItem 之间，首尾不画')
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
        .margin({ top: 8 })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
  }

  private updateResult(): void {
    this.resultText = `分隔线: ${this.strokeWidth}vp | 左边距: ${this.startMargin} | 右边距: ${this.endMargin}`
  }
}
