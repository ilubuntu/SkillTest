/**
 * column-align — Column 水平对齐
 * 展示 Column alignItems 属性：Start、Center、End
 * 元服务兼容性：alignItems API 7+，元服务 API 11+ 可用
 */
@ComponentV2
export struct ColumnAlign {
  @Local currentAlign: string = 'Center'
  @Local resultText: string = '当前对齐: HorizontalAlign.Center（默认值）'

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('Column 水平对齐 (alignItems)')
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

        // 对齐预览区
        Text('对齐预览（子元素宽度 60%）')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Column({ space: 8 }) {
          Row().width('60%').height(40).backgroundColor(0xF5DEB3).borderRadius(6)
          Row().width('60%').height(40).backgroundColor(0xD2B48C).borderRadius(6)
          Row().width('60%').height(40).backgroundColor(0xF5DEB3).borderRadius(6)
        }
        .width('90%')
        .height(180)
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
          Button('Start')
            .fontSize(13)
            .width(80)
            .height(36)
            .backgroundColor(this.currentAlign === 'Start' ? '#007DFF' : '#CCCCCC')
            .onClick(() => {
              this.currentAlign = 'Start'
              this.resultText = '当前对齐: HorizontalAlign.Start（左对齐）'
            })
          Button('Center')
            .fontSize(13)
            .width(80)
            .height(36)
            .backgroundColor(this.currentAlign === 'Center' ? '#007DFF' : '#CCCCCC')
            .onClick(() => {
              this.currentAlign = 'Center'
              this.resultText = '当前对齐: HorizontalAlign.Center（居中，默认值）'
            })
          Button('End')
            .fontSize(13)
            .width(80)
            .height(36)
            .backgroundColor(this.currentAlign === 'End' ? '#007DFF' : '#CCCCCC')
            .onClick(() => {
              this.currentAlign = 'End'
              this.resultText = '当前对齐: HorizontalAlign.End（右对齐）'
            })
        }

        // 不同宽度子元素的对齐
        Text('不同宽度子元素对齐效果')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Column({ space: 6 }) {
          Row().width('30%').height(30).backgroundColor(0xAFEEEE).borderRadius(4)
          Row().width('60%').height(30).backgroundColor(0x00CED1).borderRadius(4)
          Row().width('90%').height(30).backgroundColor(0xAFEEEE).borderRadius(4)
        }
        .width('90%')
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
          Text('.alignItems(value: HorizontalAlign)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('HorizontalAlign.Start — 水平左对齐')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('HorizontalAlign.Center — 水平居中（默认值）')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('HorizontalAlign.End — 水平右对齐')
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

  private getAlignValue(): HorizontalAlign {
    if (this.currentAlign === 'Start') {
      return HorizontalAlign.Start
    } else if (this.currentAlign === 'End') {
      return HorizontalAlign.End
    }
    return HorizontalAlign.Center
  }
}
