/**
 * flex-direction — Flex 布局方向
 * 展示 FlexOptions.direction 属性：Row、RowReverse、Column、ColumnReverse
 * 元服务兼容性：direction API 7+，元服务 API 11+ 可用
 */
@ComponentV2
export struct FlexDirectionDemo {
  @Local currentDirection: string = 'Row'
  @Local resultText: string = '当前方向: FlexDirection.Row（水平排列，默认值）'

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('Flex 布局方向 (direction)')
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

        // 布局预览区
        Text('布局预览')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Flex({ direction: this.getDirectionValue() }) {
          Text('1').width(60).height(50).backgroundColor(0xF5DEB3).textAlign(TextAlign.Center)
          Text('2').width(60).height(50).backgroundColor(0xD2B48C).textAlign(TextAlign.Center)
          Text('3').width(60).height(50).backgroundColor(0xF5DEB3).textAlign(TextAlign.Center)
          Text('4').width(60).height(50).backgroundColor(0xD2B48C).textAlign(TextAlign.Center)
        }
        .width('90%')
        .height(180)
        .padding(10)
        .backgroundColor(0xAFEEEE)
        .borderRadius(8)

        // 方向控制按钮
        Text('切换布局方向')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Row({ space: 8 }) {
          Button('Row')
            .fontSize(12)
            .width(80)
            .height(36)
            .backgroundColor(this.currentDirection === 'Row' ? '#007DFF' : '#CCCCCC')
            .onClick(() => {
              this.currentDirection = 'Row'
              this.resultText = '当前方向: FlexDirection.Row（水平排列，默认值）'
            })
          Button('RowReverse')
            .fontSize(12)
            .width(100)
            .height(36)
            .backgroundColor(this.currentDirection === 'RowReverse' ? '#007DFF' : '#CCCCCC')
            .onClick(() => {
              this.currentDirection = 'RowReverse'
              this.resultText = '当前方向: FlexDirection.RowReverse（水平反向排列）'
            })
        }

        Row({ space: 8 }) {
          Button('Column')
            .fontSize(12)
            .width(80)
            .height(36)
            .backgroundColor(this.currentDirection === 'Column' ? '#007DFF' : '#CCCCCC')
            .onClick(() => {
              this.currentDirection = 'Column'
              this.resultText = '当前方向: FlexDirection.Column（垂直排列）'
            })
          Button('ColumnReverse')
            .fontSize(12)
            .width(110)
            .height(36)
            .backgroundColor(this.currentDirection === 'ColumnReverse' ? '#007DFF' : '#CCCCCC')
            .onClick(() => {
              this.currentDirection = 'ColumnReverse'
              this.resultText = '当前方向: FlexDirection.ColumnReverse（垂直反向排列）'
            })
        }

        // API 说明区
        Column() {
          Text('API 说明')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 8 })
          Text('Flex(value?: FlexOptions)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('FlexOptions.direction?: FlexDirection')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('FlexDirection.Row — 水平排列（默认值）')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('FlexDirection.RowReverse — 水平反向排列')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('FlexDirection.Column — 垂直排列')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('FlexDirection.ColumnReverse — 垂直反向排列')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('注意: Flex 存在二次布局，性能敏感场景建议用 Row/Column 代替')
            .fontSize(12)
            .fontColor('#FF6B00')
            .width('100%')
            .margin({ top: 4 })
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

  private getDirectionValue(): FlexDirection {
    if (this.currentDirection === 'RowReverse') {
      return FlexDirection.RowReverse
    } else if (this.currentDirection === 'Column') {
      return FlexDirection.Column
    } else if (this.currentDirection === 'ColumnReverse') {
      return FlexDirection.ColumnReverse
    }
    return FlexDirection.Row
  }
}
