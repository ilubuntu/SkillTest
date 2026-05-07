/**
 * text_picker_style — TextPicker 文本样式定制
 * 展示 disappearTextStyle / textStyle / selectedTextStyle / defaultPickerItemHeight
 * 元服务兼容性：文本样式相关 API 11+ 可用
 */
@ComponentV2
export struct TextPickerStyle {
  @Local resultText: string = '当前选中: --'
  @Local eventLog: string = '等待操作...'
  @Local itemHeight: number = 50

  private fruits: string[] = ['apple1', 'orange2', 'peach3', 'grape4', 'banana5']

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('TextPicker 文本样式')
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

        // 事件日志区
        Column() {
          Text(this.eventLog)
            .fontSize(12)
            .fontColor('#666666')
            .width('100%')
            .padding(12)
        }
        .width('90%')
        .backgroundColor('#F0F0F0')
        .borderRadius(8)

        // 自定义样式选择器
        Text('自定义文本样式')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        TextPicker({ range: this.fruits, selected: 1 })
          .disappearTextStyle({ color: Color.Red, font: { size: 15, weight: FontWeight.Lighter } })
          .textStyle({ color: Color.Black, font: { size: 20, weight: FontWeight.Normal } })
          .selectedTextStyle({ color: Color.Blue, font: { size: 30, weight: FontWeight.Bolder } })
          .defaultPickerItemHeight(this.itemHeight)
          .onChange((value: string | string[], index: number | number[]) => {
            try {
              const v = value as string
              const i = index as number
              this.resultText = `当前选中: ${v} (索引 ${i})`
              this.eventLog = `onChange → value: ${v}, index: ${i}`
            } catch (err) {
              this.eventLog = `错误: ${(err as BusinessError).message}`
            }
          })

        // 参数控制区 — 选择项高度
        Text('选择项高度控制')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Row({ space: 8 }) {
          Button('40vp')
            .fontSize(12)
            .height(36)
            .backgroundColor(this.itemHeight === 40 ? '#007DFF' : '#CCCCCC')
            .onClick(() => {
              this.itemHeight = 40
              this.eventLog = 'defaultPickerItemHeight = 40'
            })
          Button('50vp')
            .fontSize(12)
            .height(36)
            .backgroundColor(this.itemHeight === 50 ? '#007DFF' : '#CCCCCC')
            .onClick(() => {
              this.itemHeight = 50
              this.eventLog = 'defaultPickerItemHeight = 50'
            })
          Button('60vp')
            .fontSize(12)
            .height(36)
            .backgroundColor(this.itemHeight === 60 ? '#007DFF' : '#CCCCCC')
            .onClick(() => {
              this.itemHeight = 60
              this.eventLog = 'defaultPickerItemHeight = 60'
            })
          Button('80vp')
            .fontSize(12)
            .height(36)
            .backgroundColor(this.itemHeight === 80 ? '#007DFF' : '#CCCCCC')
            .onClick(() => {
              this.itemHeight = 80
              this.eventLog = 'defaultPickerItemHeight = 80'
            })
        }

        // 样式说明
        Column() {
          Text('三层文本样式说明')
            .fontSize(13)
            .fontWeight(FontWeight.Medium)
            .width('100%')
            .margin({ bottom: 4 })
          Text('selectedTextStyle — 选中项 (蓝色 30fp Bold)')
            .fontSize(12)
            .fontColor('#333333')
            .width('100%')
          Text('textStyle — 待选项，选中项上下第一项 (黑色 20fp)')
            .fontSize(12)
            .fontColor('#333333')
            .margin({ top: 2 })
            .width('100%')
          Text('disappearTextStyle — 边缘项，上下第二项 (红色 15fp Light)')
            .fontSize(12)
            .fontColor('#333333')
            .margin({ top: 2 })
            .width('100%')
          Text('defaultPickerItemHeight — 所有选项高度统一设置')
            .fontSize(12)
            .fontColor('#333333')
            .margin({ top: 2 })
            .width('100%')
        }
        .width('90%')
        .backgroundColor('#E3F2FD')
        .borderRadius(8)
        .padding(12)

        // API 说明区
        Column() {
          Text('API 说明')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 8 })
          Text('.disappearTextStyle({ color, font: { size, weight } })')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('.textStyle({ color, font: { size, weight } })')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('.selectedTextStyle({ color, font: { size, weight } })')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('.defaultPickerItemHeight(number | string)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('元服务兼容: 以上样式 API 11+ 全部可用')
            .fontSize(12)
            .fontColor('#4CAF50')
            .width('100%')
            .margin({ top: 4 })
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
