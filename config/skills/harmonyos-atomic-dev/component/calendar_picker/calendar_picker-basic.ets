/**
 * calendar_picker-basic — CalendarPicker 日历选择器基础用法
 * 展示日历选择、日期回调、样式自定义
 * 元服务兼容性：CalendarPicker 从 API 11+ 可用
 */
@ComponentV2
export struct CalendarPickerBasic {
  @Local resultLog: string = '等待选择日期...'
  @Local selectedDate: string = ''

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('CalendarPicker 日历选择器')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20, bottom: 10 })

        // 结果展示区
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

        // ---- 基础日历 ----
        Text('1. 基础日历选择')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        CalendarPicker()
          .edgeAlign(CalendarAlign.CENTER)
          .textStyle({ color: '#333333' })
          .onChange((value: Date) => {
            this.selectedDate = `${value.getFullYear()}-${value.getMonth() + 1}-${value.getDate()}`
            this.resultLog = `选中日期: ${this.selectedDate}`
          })

        // ---- 带初始选中 ----
        Text('2. 带初始选中日期')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 12 })

        CalendarPicker({
          selected: new Date(2026, 3, 21), // 2026-04-21
          hintRadius: 20
        })
          .edgeAlign(CalendarAlign.START)
          .textStyle({ color: '#007DFF' })
          .onChange((value: Date) => {
            this.resultLog = `切换日期: ${value.getFullYear()}-${value.getMonth() + 1}-${value.getDate()}`
          })

        Text('hintRadius: 20, edgeAlign: START, 初始选中 2026-04-21')
          .fontSize(12)
          .fontColor('#999999')
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16 })

        // ---- 样式自定义 ----
        Text('3. 文字样式自定义')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 12 })

        CalendarPicker()
          .textStyle({
            color: '#9B59B6',
            font: { size: 14, weight: FontWeight.Bold }
          })

        // API 说明区
        Column() {
          Text('API 说明')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 8 })
          Text('CalendarPicker(options?: CalendarOptions)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('  hintRadius?: number | Resource — 提示圆半径')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('  selected?: Date — 初始选中日期')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('.edgeAlign(CalendarAlign) — START/CENTER/END')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('.textStyle(PickerTextStyle) — 文字样式')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('.onChange((date: Date) => void) — 日期变化回调')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('元服务API: API 11+ | 注意: Wearable 设备不支持')
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
