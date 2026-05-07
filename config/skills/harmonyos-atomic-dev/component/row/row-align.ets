/**
 * row-align — Row 垂直对齐
 * 展示 Row alignItems 属性：Top、Center、Bottom
 * 元服务兼容性：alignItems API 7+，元服务 API 11+ 可用
 */
@ComponentV2
export struct RowAlign {
  @Local currentAlign: string = 'Center'
  @Local resultText: string = '当前对齐: VerticalAlign.Center（默认值）'

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('Row 垂直对齐 (alignItems)')
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

        // 对齐预览区（不同高度子元素）
        Text('对齐预览（子元素高度不同）')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Row({ space: 10 }) {
          Column().width(50).height(30).backgroundColor(0xF5DEB3).borderRadius(6)
          Column().width(50).height(50).backgroundColor(0xD2B48C).borderRadius(6)
          Column().width(50).height(70).backgroundColor(0xF5DEB3).borderRadius(6)
        }
        .width('90%')
        .height(140)
        .padding(8)
        .border({ width: 1, color: '#DDDDDD' })
        .borderRadius(8)
        .alignItems(this.getAlignValue())

        // 对齐控制按钮
        Text('切换对齐方式')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Row({ space: 12 }) {
          Button('Top')
            .fontSize(13)
            .width(80)
            .height(36)
            .backgroundColor(this.currentAlign === 'Top' ? '#007DFF' : '#CCCCCC')
            .onClick(() => {
              this.currentAlign = 'Top'
              this.resultText = '当前对齐: VerticalAlign.Top（顶部对齐）'
            })
          Button('Center')
            .fontSize(13)
            .width(80)
            .height(36)
            .backgroundColor(this.currentAlign === 'Center' ? '#007DFF' : '#CCCCCC')
            .onClick(() => {
              this.currentAlign = 'Center'
              this.resultText = '当前对齐: VerticalAlign.Center（居中，默认值）'
            })
          Button('Bottom')
            .fontSize(13)
            .width(80)
            .height(36)
            .backgroundColor(this.currentAlign === 'Bottom' ? '#007DFF' : '#CCCCCC')
            .onClick(() => {
              this.currentAlign = 'Bottom'
              this.resultText = '当前对齐: VerticalAlign.Bottom（底部对齐）'
            })
        }

        // 等高子元素场景
        Text('等高子元素（对齐效果一致）')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Row({ space: 8 }) {
          Column().width('25%').height(40).backgroundColor(0xAFEEEE).borderRadius(4)
          Column().width('25%').height(40).backgroundColor(0x00CED1).borderRadius(4)
          Column().width('25%').height(40).backgroundColor(0xAFEEEE).borderRadius(4)
        }
        .width('90%')
        .height(100)
        .padding(8)
        .border({ width: 1, color: '#DDDDDD' })
        .borderRadius(8)
        .alignItems(this.getAlignValue())

        // API 说明区
        Column() {
          Text('API 说明')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 8 })
          Text('.alignItems(value: VerticalAlign)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('VerticalAlign.Top — 垂直顶部对齐')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('VerticalAlign.Center — 垂直居中（默认值）')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('VerticalAlign.Bottom — 垂直底部对齐')
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

  private getAlignValue(): VerticalAlign {
    if (this.currentAlign === 'Top') {
      return VerticalAlign.Top
    } else if (this.currentAlign === 'Bottom') {
      return VerticalAlign.Bottom
    }
    return VerticalAlign.Center
  }
}
