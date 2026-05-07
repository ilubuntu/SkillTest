/**
 * relative_container-guideline — RelativeContainer 辅助线
 * 展示 guideLine 辅助线的使用：创建水平/垂直锚点线
 * 元服务兼容性：API 12+ 可用
 */

@ComponentV2
export struct RelativeContainerGuideline {
  @Local resultText: string = '等待操作...'
  @Local guidePosition: number = 50

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('RelativeContainer 辅助线')
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

        // 布局预览
        Text('辅助线布局预览')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        RelativeContainer() {
          // 对齐到垂直辅助线左侧
          Row() {
            Text('垂直线左')
              .fontSize(12)
              .fontColor('#FFFFFF')
          }
          .width(80)
          .height(80)
          .backgroundColor('#2196F3')
          .borderRadius(8)
          .justifyContent(FlexAlign.Center)
          .alignRules({
            right: { anchor: 'vLine', align: HorizontalAlign.Start },
            top: { anchor: 'hLine', align: VerticalAlign.Top }
          })
          .id('leftBox')

          // 对齐到垂直辅助线右侧
          Row() {
            Text('垂直线右')
              .fontSize(12)
              .fontColor('#FFFFFF')
          }
          .width(80)
          .height(80)
          .backgroundColor('#4CAF50')
          .borderRadius(8)
          .justifyContent(FlexAlign.Center)
          .alignRules({
            left: { anchor: 'vLine', align: HorizontalAlign.End },
            top: { anchor: 'hLine', align: VerticalAlign.Top }
          })
          .id('rightBox')

          // 对齐到水平辅助线下方
          Row() {
            Text('水平线下')
              .fontSize(12)
              .fontColor('#FFFFFF')
          }
          .width(80)
          .height(80)
          .backgroundColor('#FF9800')
          .borderRadius(8)
          .justifyContent(FlexAlign.Center)
          .alignRules({
            top: { anchor: 'hLine', align: VerticalAlign.Bottom },
            middle: { anchor: '__container__', align: HorizontalAlign.Center }
          })
          .id('bottomBox')
        }
        .guideLine([
          { id: 'vLine', direction: Axis.Vertical, position: { start: `${this.guidePosition}%` } },
          { id: 'hLine', direction: Axis.Horizontal, position: { start: '30%' } }
        ])
        .width('90%')
        .height(300)
        .backgroundColor('#E8E8E8')
        .borderRadius(12)

        // 辅助线位置控制
        Text(`垂直辅助线位置: ${this.guidePosition}%`)
          .fontSize(14)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16 })

        Slider({
          value: this.guidePosition,
          min: 10,
          max: 90,
          step: 5
        })
          .width('90%')
          .onChange((value: number) => {
            this.guidePosition = value
          })

        // 操作按钮
        Row({ space: 8 }) {
          Button('居中辅助线')
            .fontSize(13)
            .layoutWeight(1)
            .height(36)
            .onClick(() => {
              this.guidePosition = 50
              this.resultText = '垂直辅助线移至 50%（中心位置）\n左右组件对称分布'
            })
          Button('偏左辅助线')
            .fontSize(13)
            .layoutWeight(1)
            .height(36)
            .onClick(() => {
              this.guidePosition = 25
              this.resultText = '垂直辅助线移至 25%\n左侧空间缩小，右侧空间增大'
            })
          Button('偏右辅助线')
            .fontSize(13)
            .layoutWeight(1)
            .height(36)
            .onClick(() => {
              this.guidePosition = 75
              this.resultText = '垂直辅助线移至 75%\n左侧空间增大，右侧空间缩小'
            })
        }
        .width('90%')

        // API 说明区
        Column() {
          Text('API 说明')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 8 })
          Text('.guideLine([{ id, direction, position: { start/end } }])')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('direction: Axis.Vertical | Axis.Horizontal')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('子组件可通过辅助线 id 作为锚点')
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
        .margin({ top: 8, bottom: 20 })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
  }
}
