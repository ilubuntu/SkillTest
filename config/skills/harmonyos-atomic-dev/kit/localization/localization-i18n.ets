/**
 * localization-i18n — 国际化系统信息场景
 * @ohos.i18n 模块获取系统语言、时区、日历等国际化信息
 * 元服务API: i18n 模块在元服务中可用
 */
import i18n from '@ohos.i18n'
import { BusinessError } from '@kit.BasicServicesKit'

@ComponentV2
export struct LocalizationI18n {
  @Local resultText: string = '点击按钮获取系统国际化信息'
  @Local systemLocale: string = '--'
  @Local systemLanguage: string = '--'
  @Local systemRegion: string = '--'
  @Local systemTimezone: string = '--'
  @Local timezoneDisplayName: string = '--'
  @Local calendarType: string = '--'
  @Local firstDayOfWeek: string = '--'
  @Local numberDigit: string = '--'
  @Local is24HourClock: string = '--'
  @Local isRTL: string = '--'
  @Local availableLocales: string = '--'
  @Local phoneNumberFormat: string = '--'

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('国际化 - 系统信息')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20, bottom: 10 })

        Text('i18n.getSystemLocale() / getSystemTimezone() / getCalendar() 等')
          .fontSize(13)
          .fontColor('#666666')
          .width('90%')
          .textAlign(TextAlign.Center)

        // 结果展示
        Column({ space: 8 }) {
          Text(this.resultText)
            .fontSize(13)
            .fontColor(this.resultText.includes('成功') ? '#00B578' :
              (this.resultText.includes('失败') || this.resultText.includes('错误') ? '#E84026' : '#333333'))
            .width('100%')

          // 语言区域信息
          Text('语言与区域')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ top: 4 })

          Row() {
            Text('系统区域设置: ')
              .fontSize(12)
              .fontColor('#999999')
            Text(this.systemLocale)
              .fontSize(12)
              .fontWeight(FontWeight.Medium)
              .layoutWeight(1)
          }
          .width('100%')

          Row() {
            Text('系统语言: ')
              .fontSize(12)
              .fontColor('#999999')
            Text(this.systemLanguage)
              .fontSize(12)
              .fontWeight(FontWeight.Medium)
              .layoutWeight(1)
          }
          .width('100%')

          Row() {
            Text('系统地区: ')
              .fontSize(12)
              .fontColor('#999999')
            Text(this.systemRegion)
              .fontSize(12)
              .fontWeight(FontWeight.Medium)
              .layoutWeight(1)
          }
          .width('100%')

          Row() {
            Text('文字方向 (RTL): ')
              .fontSize(12)
              .fontColor('#999999')
            Text(this.isRTL)
              .fontSize(12)
              .fontWeight(FontWeight.Medium)
              .layoutWeight(1)
          }
          .width('100%')

          // 时区信息
          Text('时区信息')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ top: 4 })

          Row() {
            Text('系统时区: ')
              .fontSize(12)
              .fontColor('#999999')
            Text(this.systemTimezone)
              .fontSize(12)
              .fontWeight(FontWeight.Medium)
              .layoutWeight(1)
          }
          .width('100%')

          Row() {
            Text('时区显示名: ')
              .fontSize(12)
              .fontColor('#999999')
            Text(this.timezoneDisplayName)
              .fontSize(12)
              .fontWeight(FontWeight.Medium)
              .layoutWeight(1)
          }
          .width('100%')

          // 日历信息
          Text('日历与格式')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ top: 4 })

          Row() {
            Text('日历类型: ')
              .fontSize(12)
              .fontColor('#999999')
            Text(this.calendarType)
              .fontSize(12)
              .fontWeight(FontWeight.Medium)
              .layoutWeight(1)
          }
          .width('100%')

          Row() {
            Text('每周首日: ')
              .fontSize(12)
              .fontColor('#999999')
            Text(this.firstDayOfWeek)
              .fontSize(12)
              .fontWeight(FontWeight.Medium)
              .layoutWeight(1)
          }
          .width('100%')

          Row() {
            Text('小数位数: ')
              .fontSize(12)
              .fontColor('#999999')
            Text(this.numberDigit)
              .fontSize(12)
              .fontWeight(FontWeight.Medium)
              .layoutWeight(1)
          }
          .width('100%')

          Row() {
            Text('24小时制: ')
              .fontSize(12)
              .fontColor('#999999')
            Text(this.is24HourClock)
              .fontSize(12)
              .fontWeight(FontWeight.Medium)
              .layoutWeight(1)
          }
          .width('100%')

          // 其他信息
          Text('其他信息')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ top: 4 })

          Row() {
            Text('可用区域(前10): ')
              .fontSize(12)
              .fontColor('#999999')
          }
          .width('100%')
          Text(this.availableLocales)
            .fontSize(11)
            .fontFamily('monospace')
            .fontColor('#333333')
            .width('100%')

          Row() {
            Text('电话号码格式化: ')
              .fontSize(12)
              .fontColor('#999999')
          }
          .width('100%')
          Text(this.phoneNumberFormat)
            .fontSize(11)
            .fontFamily('monospace')
            .fontColor('#333333')
            .width('100%')
        }
        .width('90%')
        .padding(16)
        .backgroundColor('#F5F5F5')
        .borderRadius(12)
        .alignItems(HorizontalAlign.Start)

        // 操作按钮
        Button('获取系统国际化信息')
          .width('90%')
          .backgroundColor('#007DFF')
          .borderRadius(8)
          .onClick(() => this.fetchI18nInfo())

        // 提示信息
        Column() {
          Text('注意事项')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 4 })
          Text('1. i18n 模块在元服务中可正常使用')
            .fontSize(12)
            .fontColor('#00B578')
            .width('100%')
          Text('2. 获取的是系统级别的国际化设置信息')
            .fontSize(12)
            .fontColor('#996600')
            .width('100%')
          Text('3. 配合 intl 模块可实现完整的国际化方案')
            .fontSize(12)
            .fontColor('#996600')
            .width('100%')
          Text('4. 应用内多语言建议配合资源目录 (resources/) 使用')
            .fontSize(12)
            .fontColor('#996600')
            .width('100%')
        }
        .width('90%')
        .backgroundColor('#FFF3CD')
        .borderRadius(8)
        .padding(12)

        // API 说明
        Text('API 说明')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Column({ space: 4 }) {
          Text('import i18n from "@ohos.i18n"')
            .fontSize(12)
            .fontColor('#007DFF')
            .fontFamily('monospace')
          Text('// 系统区域设置')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('i18n.getSystemLocale()    // 如 "zh-Hans-CN"')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('i18n.getSystemLanguage()  // 如 "zh-Hans"')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('i18n.getSystemRegion()    // 如 "CN"')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('// 时区')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('i18n.getSystemTimezone()  // 如 "Asia/Shanghai"')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('// 日历')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('let cal = i18n.getCalendar("zh-Hans", "chinese")')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('cal.firstDayOfWeek // 每周首日')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('')
            .fontSize(8)
          Text('元服务API: i18n 模块在元服务中完全可用')
            .fontSize(12)
            .fontColor('#00B578')
            .fontWeight(FontWeight.Medium)
        }
        .alignItems(HorizontalAlign.Start)
        .margin({ left: 16, bottom: 20 })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
  }

  private fetchI18nInfo(): void {
    try {
      // 语言区域信息
      this.systemLocale = '(原子化服务不支持 getSystemLocale)'
      this.systemLanguage = '(原子化服务不支持 getSystemLanguage)'
      this.systemRegion = '(原子化服务不支持 getSystemRegion)'

      // 判断是否为 RTL 语言
      this.isRTL = '未知'

      // 时区信息
      this.systemTimezone = '(原子化服务不支持 getSystemTimezone)'
      this.timezoneDisplayName = this.systemTimezone

      // 日历信息
      let cal = i18n.getCalendar('zh-Hans', 'gregorian')
      this.calendarType = cal ? 'Gregorian (公历)' : '未知'
      let firstDay: number = cal.getFirstDayOfWeek()
      let dayNames: string[] = ['周日', '周一', '周二', '周三', '周四', '周五', '周六']
      this.firstDayOfWeek = firstDay !== undefined ? `${dayNames[firstDay] ?? firstDay}` : '未知'

      // 数字格式
      try {
        let numberFormat = new Intl.NumberFormat('zh-Hans')
        let resolved = numberFormat.resolvedOptions()
        this.numberDigit = resolved ? `${resolved.minimumFractionDigits ?? 0}` : '未知'
      } catch (e) {
        this.numberDigit = '未知'
      }

      // 24小时制
      this.is24HourClock = '(原子化服务不支持 is24HourClock)'

      // 可用区域列表
      this.availableLocales = '(原子化服务不支持 getSystemLocales)'

      // 电话号码格式化示例
      try {
        let phonenumberfmt = new i18n.PhoneNumberFormat('CN')
        let formatted = phonenumberfmt.format('13800138000')
        this.phoneNumberFormat = `13800138000 -> ${formatted ?? '格式化失败'}`
      } catch (e) {
        this.phoneNumberFormat = '13800138000 -> 格式化不可用'
      }

      this.resultText = '系统国际化信息获取成功'
    } catch (error) {
      const err = error as BusinessError
      this.resultText = `获取失败: [${err.code}] ${err.message}`
    }
  }
}
