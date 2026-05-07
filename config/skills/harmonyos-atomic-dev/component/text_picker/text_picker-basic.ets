/**
 * text_picker-basic — TextPicker 基础用法
 * 展示单列文本选择器的创建、range 数据源、selected/value 双向绑定、onChange 事件
 * 元服务兼容性：TextPicker 构造函数 API 11+ 可用
 */
@ComponentV2
export struct TextPickerBasic {
  @Local selectedIndex: number = 1
  @Local selectedValue: string = 'orange2'
  @Local resultText: string = '当前选中: orange2 (索引 1)'
  @Local eventLog: string = '等待操作...'

  private fruits: string[] = ['apple1', 'orange2', 'peach3', 'grape4', 'banana5']

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('TextPicker 基础用法')
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

        // 单列文本选择器
        Text('单列文本选择器')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        TextPicker({ range: this.fruits, selected: this.selectedIndex, value: this.selectedValue })
          .onChange((value: string | string[], index: number | number[]) => {
            try {
              const v = value as string
              const i = index as number
              this.selectedValue = v
              this.selectedIndex = i
              this.resultText = `当前选中: ${v} (索引 ${i})`
              this.eventLog = `onChange → value: ${v}, index: ${i}`
            } catch (err) {
              this.eventLog = `错误: ${(err as BusinessError).message}`
            }
          })

        // 使用 selectedIndex 属性切换
        Text('点击按钮切换选中项')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Row({ space: 8 }) {
          Button('选中第0项')
            .fontSize(12)
            .height(36)
            .onClick(() => {
              this.selectedIndex = 0
              this.selectedValue = this.fruits[0]
              this.eventLog = '手动设置 selectedIndex = 0'
            })
          Button('选中第2项')
            .fontSize(12)
            .height(36)
            .onClick(() => {
              this.selectedIndex = 2
              this.selectedValue = this.fruits[2]
              this.eventLog = '手动设置 selectedIndex = 2'
            })
          Button('选中末项')
            .fontSize(12)
            .height(36)
            .onClick(() => {
              this.selectedIndex = this.fruits.length - 1
              this.selectedValue = this.fruits[this.fruits.length - 1]
              this.eventLog = `手动设置 selectedIndex = ${this.fruits.length - 1}`
            })
        }

        // 重置按钮
        Button('重置为默认值')
          .width('90%')
          .height(40)
          .backgroundColor('#007DFF')
          .onClick(() => {
            this.selectedIndex = 1
            this.selectedValue = 'orange2'
            this.resultText = '当前选中: orange2 (索引 1)'
            this.eventLog = '已重置'
          })

        // API 说明区
        Column() {
          Text('API 说明')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 8 })
          Text('TextPicker({ range, selected?, value? })')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('range: string[] | Resource — 数据源')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('selected: number — 默认选中索引 (支持 $$ 双向绑定)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('value: ResourceStr — 默认选中值 (支持 $$ 双向绑定)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('.selectedIndex(number) — 设置选中项索引 (API 11+)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('.onChange((value, index) => void) — 滑动选中回调')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('元服务兼容: API 11+ 全部可用')
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
