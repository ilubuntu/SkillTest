/**
 * date_picker-basic — DatePicker 日期选择器基础用法
 * 展示日期滚动选择、样式自定义、农历模式
 * 元服务兼容性：DatePicker 从 API 11+ 可用
 */
@ComponentV2
export struct DatePickerBasic {
  @Local resultLog: string = '等待选择日期...'
  @Local showLunar: boolean = false

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('DatePicker 日期选择器')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20, bottom: 10 })

        Column() {
          Text(this.resultLog)
            .fontSize(14)
            .fontColor('#333333')
            .width('100%')
            .padding(12)
        }
        .width('90%')
        .backgroundColor('#F5F5F5')
        .borderRadius(8)

        Text('1. 基础日期选择')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        DatePicker({
          start: new Date('2020-01-01'),
          end: new Date('2030-12-31'),
          selected: new Date(2026, 3, 21)
        })
          .onDateChange((value: Date) => {
            this.resultLog = `选中: ${value.getFullYear()}-${value.getMonth() + 1}-${value.getDate()}`
          })

        Text('start: 2020, end: 2030, selected: 2026-04-21')
          .fontSize(12)
          .fontColor('#999999')
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16 })

        // ---- 农历模式 ----
        Text('2. 农历模式')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 12 })

        Button(this.showLunar ? '关闭农历' : '开启农历')
          .fontSize(13)
          .onClick(() => {
            this.showLunar = !this.showLunar
          })

        DatePicker()
          .lunar(this.showLunar)
          .onDateChange((value: Date) => {
            this.resultLog = `农历模式(${this.showLunar}): ${value.getFullYear()}-${value.getMonth() + 1}-${value.getDate()}`
          })

        // ---- 自定义文字样式 ----
        Text('3. 自定义文字样式')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 12 })

        DatePicker()
          .textStyle({ color: '#007DFF', font: { size: 16 } })
          .selectedTextStyle({ color: '#FFFFFF', font: { size: 18, weight: FontWeight.Bold } })
          .disappearTextStyle({ color: '#CCCCCC', font: { size: 14 } })
          .onDateChange((value: Date) => {
            this.resultLog = `自定义样式: ${value.getFullYear()}-${value.getMonth() + 1}-${value.getDate()}`
          })

        // API 说明区
        Column() {
          Text('API 说明')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 8 })
          Text('DatePicker(options?: DatePickerOptions)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('  start?: Date, end?: Date, selected?: Date')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('.lunar(bool) — 农历模式')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('.textStyle / .selectedTextStyle / .disappearTextStyle')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('.onDateChange((date: Date) => void) — 日期变化')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('元服务API: API 11+ | mode(年月/月日): API 18+')
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
