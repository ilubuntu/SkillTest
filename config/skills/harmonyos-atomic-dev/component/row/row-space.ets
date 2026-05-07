/**
 * row-space — Row 子元素间距
 * 展示 Row space 参数：number 类型间距、动态调节间距
 * 元服务兼容性：space 参数 API 7+，元服务 API 11+ 可用
 */
@ComponentV2
export struct RowSpace {
  @Local currentSpace: number = 10
  @Local resultText: string = '当前 space: 10'

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('Row 子元素间距')
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

        // 动态间距预览
        Text('间距预览（水平排列）')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Row({ space: this.currentSpace }) {
          Column().width(40).height(60).backgroundColor(0xF5DEB3).borderRadius(6)
          Column().width(40).height(60).backgroundColor(0xD2B48C).borderRadius(6)
          Column().width(40).height(60).backgroundColor(0xF5DEB3).borderRadius(6)
          Column().width(40).height(60).backgroundColor(0xD2B48C).borderRadius(6)
        }
        .width('90%')
        .height(100)
        .padding(8)
        .border({ width: 1, color: '#DDDDDD' })
        .borderRadius(8)

        // 间距控制按钮
        Text('调节间距')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Row({ space: 8 }) {
          Button('0')
            .fontSize(13)
            .width(50)
            .height(36)
            .onClick(() => {
              this.currentSpace = 0
              this.resultText = '当前 space: 0（无间距）'
            })
          Button('5')
            .fontSize(13)
            .width(50)
            .height(36)
            .onClick(() => {
              this.currentSpace = 5
              this.resultText = '当前 space: 5'
            })
          Button('10')
            .fontSize(13)
            .width(50)
            .height(36)
            .onClick(() => {
              this.currentSpace = 10
              this.resultText = '当前 space: 10'
            })
          Button('20')
            .fontSize(13)
            .width(50)
            .height(36)
            .onClick(() => {
              this.currentSpace = 20
              this.resultText = '当前 space: 20'
            })
          Button('30')
            .fontSize(13)
            .width(50)
            .height(36)
            .onClick(() => {
              this.currentSpace = 30
              this.resultText = '当前 space: 30'
            })
        }

        // space 负值不生效提示
        Text('space 与 justifyContent 交互')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Column() {
          Text('当 justifyContent 设为 SpaceBetween / SpaceAround / SpaceEvenly 时，space 不生效')
            .fontSize(13)
            .fontColor('#FF6B00')
            .fontWeight(FontWeight.Medium)
            .width('100%')
          Text('space 为负数时按默认值 0 处理')
            .fontSize(12)
            .fontColor('#996600')
            .margin({ top: 4 })
            .width('100%')
        }
        .width('90%')
        .backgroundColor('#FFF3CD')
        .borderRadius(8)
        .padding(12)

        // RowOptionsV2 (API 18+) 限制提示
        Text('RowOptionsV2 (API 18+)')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Column() {
          Text('RowOptionsV2 支持 space 为 string | Resource 类型')
            .fontSize(13)
            .fontColor('#FF6B00')
            .fontWeight(FontWeight.Medium)
            .width('100%')
          Text('该能力需要 API 18+ 元服务支持，当前使用 number 类型 space')
            .fontSize(12)
            .fontColor('#996600')
            .margin({ top: 4 })
            .width('100%')
        }
        .width('90%')
        .backgroundColor('#FFF3CD')
        .borderRadius(8)
        .padding(12)

        // API 说明区
        Column() {
          Text('API 说明')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 8 })
          Text('Row(options?: RowOptions)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('RowOptions.space?: number | string')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('space 为负数时按默认值 0 处理')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('space 与 justifyContent(SpaceBetween/Around/Evenly) 同时设置时 space 不生效')
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
}
