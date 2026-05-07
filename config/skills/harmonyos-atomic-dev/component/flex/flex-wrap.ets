/**
 * flex-wrap — Flex 换行模式
 * 展示 FlexOptions.wrap 属性：NoWrap、Wrap、WrapReverse
 * 元服务兼容性：wrap API 7+，元服务 API 11+ 可用
 */
@ComponentV2
export struct FlexWrapDemo {
  @Local currentWrap: string = 'NoWrap'
  @Local resultText: string = '当前换行: FlexWrap.NoWrap（不换行，默认值）'

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('Flex 换行模式 (wrap)')
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

        // 换行预览区
        Text('换行预览（子元素宽度 50%）')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Flex({ wrap: this.getWrapValue(), direction: FlexDirection.Row }) {
          Text('1').width('50%').height(50).backgroundColor(0xF5DEB3).textAlign(TextAlign.Center)
          Text('2').width('50%').height(50).backgroundColor(0xD2B48C).textAlign(TextAlign.Center)
          Text('3').width('50%').height(50).backgroundColor(0xD2B48C).textAlign(TextAlign.Center)
        }
        .width('90%')
        .height(180)
        .padding(10)
        .backgroundColor(0xAFEEEE)
        .borderRadius(8)

        // 换行控制按钮
        Text('切换换行模式')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Row({ space: 8 }) {
          Button('NoWrap')
            .fontSize(12)
            .width(90)
            .height(36)
            .backgroundColor(this.currentWrap === 'NoWrap' ? '#007DFF' : '#CCCCCC')
            .onClick(() => {
              this.currentWrap = 'NoWrap'
              this.resultText = '当前换行: FlexWrap.NoWrap（不换行，默认值，超出部分压缩）'
            })
          Button('Wrap')
            .fontSize(12)
            .width(80)
            .height(36)
            .backgroundColor(this.currentWrap === 'Wrap' ? '#007DFF' : '#CCCCCC')
            .onClick(() => {
              this.currentWrap = 'Wrap'
              this.resultText = '当前换行: FlexWrap.Wrap（换行，按主轴方向排列）'
            })
          Button('WrapReverse')
            .fontSize(12)
            .width(110)
            .height(36)
            .backgroundColor(this.currentWrap === 'WrapReverse' ? '#007DFF' : '#CCCCCC')
            .onClick(() => {
              this.currentWrap = 'WrapReverse'
              this.resultText = '当前换行: FlexWrap.WrapReverse（换行，按主轴反方向排列）'
            })
        }

        // 不同数量子元素效果
        Text('4 个子元素（宽度 40%）换行效果')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Flex({ wrap: this.getWrapValue(), direction: FlexDirection.Row }) {
          Text('1').width('40%').height(40).backgroundColor(0xAFEEEE).textAlign(TextAlign.Center)
          Text('2').width('40%').height(40).backgroundColor(0x00CED1).textAlign(TextAlign.Center)
          Text('3').width('40%').height(40).backgroundColor(0xAFEEEE).textAlign(TextAlign.Center)
          Text('4').width('40%').height(40).backgroundColor(0x00CED1).textAlign(TextAlign.Center)
        }
        .width('90%')
        .height(140)
        .padding(10)
        .backgroundColor(0xAFEEEE)
        .borderRadius(8)

        // API 说明区
        Column() {
          Text('API 说明')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 8 })
          Text('FlexOptions.wrap?: FlexWrap')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('FlexWrap.NoWrap — 不换行（默认值），超出时压缩子元素')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('FlexWrap.Wrap — 换行，按主轴方向排列新行')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('FlexWrap.WrapReverse — 换行，按主轴反方向排列新行')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('多行布局时 alignContent 属性才生效')
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

  private getWrapValue(): FlexWrap {
    if (this.currentWrap === 'Wrap') {
      return FlexWrap.Wrap
    } else if (this.currentWrap === 'WrapReverse') {
      return FlexWrap.WrapReverse
    }
    return FlexWrap.NoWrap
  }
}
