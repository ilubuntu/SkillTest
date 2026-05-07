/**
 * row-reverse — Row 子元素反转排列
 * 展示 Row reverse 属性：子元素水平方向反转排列
 * 元服务兼容性：reverse API 12+，元服务 API 12+ 可用
 */
@ComponentV2
export struct RowReverse {
  @Local isReversed: boolean = false
  @Local resultText: string = '当前排列: 正序（未反转）'

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('Row 反转排列 (reverse)')
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

        // 正序展示
        Text('正序排列（reverse 未设置）')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Row({ space: 8 }) {
          Text('1')
            .fontSize(13)
            .width(60)
            .height(40)
            .textAlign(TextAlign.Center)
            .backgroundColor(0xF5DEB3)
            .borderRadius(4)
          Text('2')
            .fontSize(13)
            .width(60)
            .height(40)
            .textAlign(TextAlign.Center)
            .backgroundColor(0xD2B48C)
            .borderRadius(4)
          Text('3')
            .fontSize(13)
            .width(60)
            .height(40)
            .textAlign(TextAlign.Center)
            .backgroundColor(0xF5DEB3)
            .borderRadius(4)
        }
        .width('90%')
        .height(80)
        .padding(8)
        .border({ width: 1, color: '#DDDDDD' })
        .borderRadius(8)

        // 反转展示
        Text('反转排列（reverse(true)）')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Row({ space: 8 }) {
          Text('1')
            .fontSize(13)
            .width(60)
            .height(40)
            .textAlign(TextAlign.Center)
            .backgroundColor(0xF5DEB3)
            .borderRadius(4)
          Text('2')
            .fontSize(13)
            .width(60)
            .height(40)
            .textAlign(TextAlign.Center)
            .backgroundColor(0xD2B48C)
            .borderRadius(4)
          Text('3')
            .fontSize(13)
            .width(60)
            .height(40)
            .textAlign(TextAlign.Center)
            .backgroundColor(0xF5DEB3)
            .borderRadius(4)
        }
        .width('90%')
        .height(80)
        .padding(8)
        .border({ width: 1, color: '#DDDDDD' })
        .borderRadius(8)
        .reverse(this.isReversed)

        // 切换按钮
        Row({ space: 12 }) {
          Button('正序')
            .fontSize(13)
            .width(100)
            .height(36)
            .backgroundColor(!this.isReversed ? '#007DFF' : '#CCCCCC')
            .onClick(() => {
              this.isReversed = false
              this.resultText = '当前排列: 正序（reverse 未设置）'
            })
          Button('反转')
            .fontSize(13)
            .width(100)
            .height(36)
            .backgroundColor(this.isReversed ? '#007DFF' : '#CCCCCC')
            .onClick(() => {
              this.isReversed = true
              this.resultText = '当前排列: 反转（reverse(true)）'
            })
        }

        // 注意事项
        Column() {
          Text('注意事项')
            .fontSize(13)
            .fontColor('#FF6B00')
            .fontWeight(FontWeight.Medium)
            .width('100%')
          Text('reverse 属性需要 API 12+，元服务 API 12+ 可用')
            .fontSize(12)
            .fontColor('#996600')
            .margin({ top: 4 })
            .width('100%')
          Text('direction 属性改变 Row 交叉轴方向，reverse 在 direction 结果上再做一次反转')
            .fontSize(12)
            .fontColor('#996600')
            .margin({ top: 2 })
            .width('100%')
          Text('未设置 reverse 时主轴不反转；设为 undefined 时视为 true')
            .fontSize(12)
            .fontColor('#996600')
            .margin({ top: 2 })
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
          Text('.reverse(isReversed: Optional<boolean>)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('true — 子组件水平方向反转排列')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('false — 子组件水平方向正序排列')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('默认值: true（设置后不传参默认反转）')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('元服务：API 12+ 可用')
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
