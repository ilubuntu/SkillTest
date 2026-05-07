/**
 * flex-justify — Flex 主轴对齐
 * 展示 FlexOptions.justifyContent 属性：Start、Center、End、SpaceBetween、SpaceAround、SpaceEvenly
 * 元服务兼容性：justifyContent API 7+，元服务 API 11+ 可用
 */
@ComponentV2
export struct FlexJustifyDemo {
  @Local currentJustify: string = 'Start'
  @Local resultText: string = '当前对齐: FlexAlign.Start（首端对齐，默认值）'

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('Flex 主轴对齐 (justifyContent)')
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

        // 主轴对齐预览
        Text('对齐预览（子元素宽度 20%）')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Flex({ justifyContent: this.getJustifyValue() }) {
          Text('1').width('20%').height(50).backgroundColor(0xF5DEB3).textAlign(TextAlign.Center)
          Text('2').width('20%').height(50).backgroundColor(0xD2B48C).textAlign(TextAlign.Center)
          Text('3').width('20%').height(50).backgroundColor(0xF5DEB3).textAlign(TextAlign.Center)
        }
        .width('90%')
        .height(100)
        .padding(10)
        .backgroundColor(0xAFEEEE)
        .borderRadius(8)

        // 对齐控制按钮
        Text('切换主轴对齐方式')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Row({ space: 8 }) {
          Button('Start')
            .fontSize(12)
            .width(70)
            .height(36)
            .backgroundColor(this.currentJustify === 'Start' ? '#007DFF' : '#CCCCCC')
            .onClick(() => {
              this.currentJustify = 'Start'
              this.resultText = '当前对齐: FlexAlign.Start（首端对齐，默认值）'
            })
          Button('Center')
            .fontSize(12)
            .width(70)
            .height(36)
            .backgroundColor(this.currentJustify === 'Center' ? '#007DFF' : '#CCCCCC')
            .onClick(() => {
              this.currentJustify = 'Center'
              this.resultText = '当前对齐: FlexAlign.Center（居中对齐）'
            })
          Button('End')
            .fontSize(12)
            .width(70)
            .height(36)
            .backgroundColor(this.currentJustify === 'End' ? '#007DFF' : '#CCCCCC')
            .onClick(() => {
              this.currentJustify = 'End'
              this.resultText = '当前对齐: FlexAlign.End（尾端对齐）'
            })
        }

        Row({ space: 8 }) {
          Button('SpaceBetween')
            .fontSize(11)
            .width(110)
            .height(36)
            .backgroundColor(this.currentJustify === 'SpaceBetween' ? '#007DFF' : '#CCCCCC')
            .onClick(() => {
              this.currentJustify = 'SpaceBetween'
              this.resultText = '当前对齐: FlexAlign.SpaceBetween（两端对齐，间距相等）'
            })
          Button('SpaceAround')
            .fontSize(11)
            .width(110)
            .height(36)
            .backgroundColor(this.currentJustify === 'SpaceAround' ? '#007DFF' : '#CCCCCC')
            .onClick(() => {
              this.currentJustify = 'SpaceAround'
              this.resultText = '当前对齐: FlexAlign.SpaceAround（两侧间距为元素间距一半）'
            })
        }

        Row({ space: 8 }) {
          Button('SpaceEvenly')
            .fontSize(11)
            .width(110)
            .height(36)
            .backgroundColor(this.currentJustify === 'SpaceEvenly' ? '#007DFF' : '#CCCCCC')
            .onClick(() => {
              this.currentJustify = 'SpaceEvenly'
              this.resultText = '当前对齐: FlexAlign.SpaceEvenly（等间距分布）'
            })
        }

        // API 说明区
        Column() {
          Text('API 说明')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 8 })
          Text('FlexOptions.justifyContent?: FlexAlign')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('FlexAlign.Start — 首端对齐（默认值）')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('FlexAlign.Center — 居中对齐')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('FlexAlign.End — 尾端对齐')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('FlexAlign.SpaceBetween — 两端对齐，中间等分')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('FlexAlign.SpaceAround — 两侧间距为中间间距一半')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('FlexAlign.SpaceEvenly — 所有间距完全相等')
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

  private getJustifyValue(): FlexAlign {
    if (this.currentJustify === 'Center') {
      return FlexAlign.Center
    } else if (this.currentJustify === 'End') {
      return FlexAlign.End
    } else if (this.currentJustify === 'SpaceBetween') {
      return FlexAlign.SpaceBetween
    } else if (this.currentJustify === 'SpaceAround') {
      return FlexAlign.SpaceAround
    } else if (this.currentJustify === 'SpaceEvenly') {
      return FlexAlign.SpaceEvenly
    }
    return FlexAlign.Start
  }
}
