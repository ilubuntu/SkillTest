/**
 * flex-content-align — Flex 多行对齐
 * 展示 FlexOptions.alignContent 属性（多行模式下交叉轴对齐）
 * 元服务兼容性：alignContent API 7+，元服务 API 11+ 可用
 */
@ComponentV2
export struct FlexContentAlignDemo {
  @Local currentAlign: string = 'Start'
  @Local resultText: string = '当前多行对齐: FlexAlign.Start（默认值）'

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('Flex 多行对齐 (alignContent)')
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

        // 多行对齐预览
        Text('多行对齐预览（wrap=Wrap，子元素宽度 50%）')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Flex({
          wrap: FlexWrap.Wrap,
          alignContent: this.getAlignValue(),
          justifyContent: FlexAlign.SpaceBetween
        }) {
          Text('1').width('50%').height(20).backgroundColor(0xF5DEB3).textAlign(TextAlign.Center)
          Text('2').width('50%').height(20).backgroundColor(0xD2B48C).textAlign(TextAlign.Center)
          Text('3').width('50%').height(20).backgroundColor(0xD2B48C).textAlign(TextAlign.Center)
        }
        .width('90%')
        .height(100)
        .padding(10)
        .backgroundColor(0xAFEEEE)
        .borderRadius(8)

        // 5 个子元素效果
        Text('5 个子元素对齐效果（宽度 30%-60% 不等）')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Flex({
          wrap: FlexWrap.Wrap,
          alignContent: this.getAlignValue(),
          justifyContent: FlexAlign.SpaceBetween
        }) {
          Text('1').width('30%').height(20).backgroundColor(0xF5DEB3).textAlign(TextAlign.Center)
          Text('2').width('60%').height(20).backgroundColor(0xD2B48C).textAlign(TextAlign.Center)
          Text('3').width('40%').height(20).backgroundColor(0xD2B48C).textAlign(TextAlign.Center)
          Text('4').width('30%').height(20).backgroundColor(0xF5DEB3).textAlign(TextAlign.Center)
          Text('5').width('20%').height(20).backgroundColor(0xD2B48C).textAlign(TextAlign.Center)
        }
        .width('90%')
        .height(100)
        .padding(10)
        .backgroundColor(0xAFEEEE)
        .borderRadius(8)

        // 对齐控制按钮
        Text('切换多行对齐方式')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Row({ space: 8 }) {
          Button('Start')
            .fontSize(12)
            .width(70)
            .height(36)
            .backgroundColor(this.currentAlign === 'Start' ? '#007DFF' : '#CCCCCC')
            .onClick(() => {
              this.currentAlign = 'Start'
              this.resultText = '当前多行对齐: FlexAlign.Start（与交叉轴起点对齐）'
            })
          Button('Center')
            .fontSize(12)
            .width(70)
            .height(36)
            .backgroundColor(this.currentAlign === 'Center' ? '#007DFF' : '#CCCCCC')
            .onClick(() => {
              this.currentAlign = 'Center'
              this.resultText = '当前多行对齐: FlexAlign.Center（交叉轴居中）'
            })
          Button('End')
            .fontSize(12)
            .width(70)
            .height(36)
            .backgroundColor(this.currentAlign === 'End' ? '#007DFF' : '#CCCCCC')
            .onClick(() => {
              this.currentAlign = 'End'
              this.resultText = '当前多行对齐: FlexAlign.End（与交叉轴终点对齐）'
            })
        }

        Row({ space: 8 }) {
          Button('SpaceBetween')
            .fontSize(11)
            .width(110)
            .height(36)
            .backgroundColor(this.currentAlign === 'SpaceBetween' ? '#007DFF' : '#CCCCCC')
            .onClick(() => {
              this.currentAlign = 'SpaceBetween'
              this.resultText = '当前多行对齐: FlexAlign.SpaceBetween（两端对齐，行间距等分）'
            })
          Button('SpaceAround')
            .fontSize(11)
            .width(110)
            .height(36)
            .backgroundColor(this.currentAlign === 'SpaceAround' ? '#007DFF' : '#CCCCCC')
            .onClick(() => {
              this.currentAlign = 'SpaceAround'
              this.resultText = '当前多行对齐: FlexAlign.SpaceAround（行间距相等，首尾为行间距一半）'
            })
        }

        Row({ space: 8 }) {
          Button('SpaceEvenly')
            .fontSize(11)
            .width(110)
            .height(36)
            .backgroundColor(this.currentAlign === 'SpaceEvenly' ? '#007DFF' : '#CCCCCC')
            .onClick(() => {
              this.currentAlign = 'SpaceEvenly'
              this.resultText = '当前多行对齐: FlexAlign.SpaceEvenly（行间距与首尾间距完全相等）'
            })
        }

        // API 说明区
        Column() {
          Text('API 说明')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 8 })
          Text('FlexOptions.alignContent?: FlexAlign')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('仅在 wrap 为 Wrap 或 WrapReverse 时生效')
            .fontSize(12)
            .fontColor('#FF6B00')
            .width('100%')
          Text('默认值: FlexAlign.Start')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('FlexAlign.Start — 与交叉轴起点对齐')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('FlexAlign.Center — 交叉轴居中')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('FlexAlign.End — 与交叉轴终点对齐')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('FlexAlign.SpaceBetween — 两端对齐，行间距等分')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('FlexAlign.SpaceAround — 行间距相等，首尾为行间距一半')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('FlexAlign.SpaceEvenly — 行间距与首尾间距完全相等')
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

  private getAlignValue(): FlexAlign {
    if (this.currentAlign === 'Center') {
      return FlexAlign.Center
    } else if (this.currentAlign === 'End') {
      return FlexAlign.End
    } else if (this.currentAlign === 'SpaceBetween') {
      return FlexAlign.SpaceBetween
    } else if (this.currentAlign === 'SpaceAround') {
      return FlexAlign.SpaceAround
    } else if (this.currentAlign === 'SpaceEvenly') {
      return FlexAlign.SpaceEvenly
    }
    return FlexAlign.Start
  }
}
