/**
 * blank-basic — Blank 空白填充基础用法
 * 展示空白填充在 Row/Column/Flex 中的使用
 * 元服务兼容性：Blank 从 API 11+ 全部可用，无不可用 API
 */
@ComponentV2
export struct BlankBasic {
  @Local resultLog: string = '等待操作...'

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('Blank 空白填充基础用法')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20, bottom: 10 })

        // 结果展示区
        Column() {
          Text(this.resultLog)
            .fontSize(14)
            .fontColor('#333333')
            .width('100%')
            .padding(12)
        }
        .width('90%')
        .backgroundColor('#F5F5F5')
        .borderRadius(8)

        // ---- Row 中使用 Blank ----
        Text('1. Row 中使用 Blank（水平填充）')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Row() {
          Text('左侧')
            .fontSize(14)
            .padding(8)
            .backgroundColor('#007DFF')
            .fontColor('#FFFFFF')

          Blank()

          Text('右侧')
            .fontSize(14)
            .padding(8)
            .backgroundColor('#FF6B00')
            .fontColor('#FFFFFF')
        }
        .width('90%')
        .height(50)
        .backgroundColor('#F0F0F0')
        .borderRadius(8)
        .padding({ left: 8, right: 8 })

        Text('Blank 填充了中间的空白区域，将两侧内容推开')
          .fontSize(12)
          .fontColor('#999999')
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16 })

        // ---- Column 中使用 Blank ----
        Text('2. Column 中使用 Blank（垂直填充）')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 12 })

        Column() {
          Text('顶部')
            .fontSize(14)
            .padding(8)
            .backgroundColor('#00B578')
            .fontColor('#FFFFFF')

          Blank()

          Text('底部')
            .fontSize(14)
            .padding(8)
            .backgroundColor('#9B59B6')
            .fontColor('#FFFFFF')
        }
        .width('90%')
        .height(150)
        .backgroundColor('#F0F0F0')
        .borderRadius(8)
        .padding(8)

        // ---- Blank 带颜色 ----
        Text('3. Blank 带颜色填充')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 12 })

        Row() {
          Text('A')
            .fontSize(14)
            .padding(8)
            .backgroundColor('#007DFF')
            .fontColor('#FFFFFF')

          Blank().color('#FFEAA7')

          Text('B')
            .fontSize(14)
            .padding(8)
            .backgroundColor('#FF6B00')
            .fontColor('#FFFFFF')
        }
        .width('90%')
        .height(50)
        .backgroundColor('#F0F0F0')
        .borderRadius(8)
        .padding({ left: 8, right: 8 })

        Text('Blank().color("#FFEAA7") 设置空白区域的填充色')
          .fontSize(12)
          .fontColor('#999999')
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16 })

        // ---- Blank 带 min 参数 ----
        Text('4. Blank(min) 最小尺寸')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 12 })

        Row() {
          Text('左')
            .fontSize(14)
            .padding(8)
            .backgroundColor('#007DFF')
            .fontColor('#FFFFFF')

          Blank(80).color('#DDA0DD')

          Text('右')
            .fontSize(14)
            .padding(8)
            .backgroundColor('#FF6B00')
            .fontColor('#FFFFFF')
        }
        .width('90%')
        .height(50)
        .backgroundColor('#F0F0F0')
        .borderRadius(8)
        .padding({ left: 8, right: 8 })

        Text('Blank(80) 设置主轴方向最小尺寸为 80vp')
          .fontSize(12)
          .fontColor('#999999')
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16 })

        // ---- Flex 中使用 Blank ----
        Text('5. Flex 中使用 Blank')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 12 })

        Flex({ direction: FlexDirection.Row, alignItems: ItemAlign.Center }) {
          Text('1')
            .fontSize(14)
            .padding(8)
            .backgroundColor('#FA2A2D')
            .fontColor('#FFFFFF')

          Blank().color('#E8E8E8')

          Text('2')
            .fontSize(14)
            .padding(8)
            .backgroundColor('#007DFF')
            .fontColor('#FFFFFF')

          Blank().color('#D5E8D4')

          Text('3')
            .fontSize(14)
            .padding(8)
            .backgroundColor('#00B578')
            .fontColor('#FFFFFF')
        }
        .width('90%')
        .height(50)
        .borderRadius(8)

        Text('多个 Blank 均分剩余空间')
          .fontSize(12)
          .fontColor('#999999')
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16 })

        // API 说明区
        Column() {
          Text('API 说明')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 8 })
          Text('Blank(min?: number | string) — 最小尺寸，不支持百分比')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('.color(ResourceColor) — 填充颜色')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('仅在 Row/Column/Flex 容器中生效')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('不支持子组件，min 负值/非法值默认为 0')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('元服务API: API 11+ | 卡片: API 9+ | 全部可用')
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
