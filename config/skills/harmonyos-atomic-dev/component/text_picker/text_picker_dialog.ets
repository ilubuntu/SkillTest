/**
 * text_picker_dialog — TextPickerDialog 弹窗选择器
 * 展示 showTextPickerDialog 弹窗用法、onAccept/onCancel/onChange 回调
 * 元服务兼容性：TextPickerDialog API 11+ 可用，推荐使用 UIContext.showTextPickerDialog
 */
@ComponentV2
export struct TextPickerDialog {
  @Local selectedValue: string = '未选择'
  @Local eventLog: string = '等待操作...'
  @Local selectIndex: number = 0

  private fruits: string[] = ['apple1', 'orange2', 'peach3', 'grape4', 'banana5']

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('TextPickerDialog 弹窗')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20, bottom: 10 })

        // 结果展示区
        Column() {
          Text(`选中结果: ${this.selectedValue}`)
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

        // 基础弹窗
        Text('基础弹窗选择器')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Button('打开基础文本选择弹窗')
          .width('90%')
          .height(40)
          .backgroundColor('#007DFF')
          .onClick(() => {
            try {
              this.getUIContext().showTextPickerDialog({
                range: this.fruits,
                selected: this.selectIndex,
                onAccept: (value: TextPickerResult) => {
                  this.selectIndex = value.index as number
                  this.selectedValue = value.value as string
                  this.eventLog = `onAccept → value: ${value.value}, index: ${value.index}`
                },
                onCancel: () => {
                  this.eventLog = 'onCancel → 用户取消选择'
                },
                onChange: (value: TextPickerResult) => {
                  this.eventLog = `onChange → value: ${value.value}, index: ${value.index}`
                }
              })
            } catch (err) {
              this.eventLog = `错误: ${(err as BusinessError).message}`
            }
          })

        // 自定义样式弹窗
        Text('自定义样式弹窗')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Button('打开自定义样式弹窗')
          .width('90%')
          .height(40)
          .backgroundColor('#FF6B00')
          .onClick(() => {
            try {
              this.getUIContext().showTextPickerDialog({
                range: this.fruits,
                selected: this.selectIndex,
                defaultPickerItemHeight: 50,
                disappearTextStyle: { color: '#999999', font: { size: 14, weight: FontWeight.Lighter } },
                textStyle: { color: '#333333', font: { size: 18, weight: FontWeight.Normal } },
                selectedTextStyle: { color: '#007DFF', font: { size: 24, weight: FontWeight.Bold } },
                canLoop: true,
                alignment: DialogAlignment.Bottom,
                onAccept: (value: TextPickerResult) => {
                  this.selectIndex = value.index as number
                  this.selectedValue = value.value as string
                  this.eventLog = `自定义样式 onAccept → ${value.value}`
                },
                onCancel: () => {
                  this.eventLog = '自定义样式 onCancel → 用户取消'
                }
              })
            } catch (err) {
              this.eventLog = `错误: ${(err as BusinessError).message}`
            }
          })

        // 居中弹窗
        Text('居中弹窗 + 偏移')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Button('打开居中偏移弹窗')
          .width('90%')
          .height(40)
          .backgroundColor('#4CAF50')
          .onClick(() => {
            try {
              this.getUIContext().showTextPickerDialog({
                range: this.fruits,
                selected: this.selectIndex,
                alignment: DialogAlignment.Center,
                offset: { dx: 0, dy: -50 },
                onAccept: (value: TextPickerResult) => {
                  this.selectIndex = value.index as number
                  this.selectedValue = value.value as string
                  this.eventLog = `居中弹窗 onAccept → ${value.value}`
                }
              })
            } catch (err) {
              this.eventLog = `错误: ${(err as BusinessError).message}`
            }
          })

        // API 说明区
        Column() {
          Text('API 说明')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 8 })
          Text('UIContext.showTextPickerDialog(options)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('options.range — 数据源')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('options.selected — 默认选中索引')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('options.onAccept(TextPickerResult) — 确定回调')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('options.onCancel() — 取消回调')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('options.onChange(TextPickerResult) — 滑动回调')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('options.alignment — 弹窗对齐方式 (API 11+)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('options.offset — 弹窗偏移量 (API 11+)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('TextPickerDialog.show() 已废弃(API 18)，推荐 showTextPickerDialog')
            .fontSize(12)
            .fontColor('#FF6B00')
            .width('100%')
            .margin({ top: 4 })
          Text('元服务兼容: showTextPickerDialog API 11+ 可用')
            .fontSize(12)
            .fontColor('#4CAF50')
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
