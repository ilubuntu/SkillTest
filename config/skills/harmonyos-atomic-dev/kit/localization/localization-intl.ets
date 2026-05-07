/**
 * localization-intl — 国际化格式化场景
 * @ohos.intl 模块的数字格式化、日期时间格式化、排序等
 * 元服务API: intl 模块在元服务中可用
 */
import intl from '@ohos.intl'
import { BusinessError } from '@kit.BasicServicesKit'

@ComponentV2
export struct LocalizationIntl {
  @Local resultText: string = '点击按钮执行格式化演示'
  @Local numberInput: string = '1234567.89'
  @Local dateInput: string = '2026-04-21'
  @Local selectedLocale: string = 'zh-Hans-CN'

  // 格式化结果
  @Local formattedNumberZh: string = '--'
  @Local formattedNumberEn: string = '--'
  @Local formattedNumberJa: string = '--'
  @Local formattedCurrencyZh: string = '--'
  @Local formattedCurrencyEn: string = '--'
  @Local formattedPercentZh: string = '--'
  @Local formattedDateZh: string = '--'
  @Local formattedDateEn: string = '--'
  @Local formattedTimeZh: string = '--'
  @Local formattedRelativeTime: string = '--'
  @Local collatorResult: string = '--'
  @Local pluralRules: string = '--'

  // 自定义格式化
  @Local customNumberResult: string = '--'
  @Local customDateResult: string = '--'

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('国际化 - 格式化')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20, bottom: 10 })

        Text('intl.NumberFormat / DateTimeFormat / Collator / PluralRules')
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

          // 数字格式化
          Text('数字格式化 (NumberFormat)')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ top: 4 })

          Row() {
            Text('中文: ')
              .fontSize(12)
              .fontColor('#999999')
            Text(this.formattedNumberZh)
              .fontSize(12)
              .fontWeight(FontWeight.Medium)
              .layoutWeight(1)
          }
          .width('100%')

          Row() {
            Text('英文: ')
              .fontSize(12)
              .fontColor('#999999')
            Text(this.formattedNumberEn)
              .fontSize(12)
              .fontWeight(FontWeight.Medium)
              .layoutWeight(1)
          }
          .width('100%')

          Row() {
            Text('日文: ')
              .fontSize(12)
              .fontColor('#999999')
            Text(this.formattedNumberJa)
              .fontSize(12)
              .fontWeight(FontWeight.Medium)
              .layoutWeight(1)
          }
          .width('100%')

          // 货币格式化
          Text('货币格式化')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ top: 4 })

          Row() {
            Text('CNY (中文): ')
              .fontSize(12)
              .fontColor('#999999')
            Text(this.formattedCurrencyZh)
              .fontSize(12)
              .fontWeight(FontWeight.Medium)
              .layoutWeight(1)
          }
          .width('100%')

          Row() {
            Text('USD (英文): ')
              .fontSize(12)
              .fontColor('#999999')
            Text(this.formattedCurrencyEn)
              .fontSize(12)
              .fontWeight(FontWeight.Medium)
              .layoutWeight(1)
          }
          .width('100%')

          // 百分比格式化
          Text('百分比格式化')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ top: 4 })

          Row() {
            Text('中文: ')
              .fontSize(12)
              .fontColor('#999999')
            Text(this.formattedPercentZh)
              .fontSize(12)
              .fontWeight(FontWeight.Medium)
              .layoutWeight(1)
          }
          .width('100%')

          // 日期格式化
          Text('日期格式化 (DateTimeFormat)')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ top: 4 })

          Row() {
            Text('中文完整: ')
              .fontSize(12)
              .fontColor('#999999')
            Text(this.formattedDateZh)
              .fontSize(12)
              .fontWeight(FontWeight.Medium)
              .layoutWeight(1)
          }
          .width('100%')

          Row() {
            Text('英文完整: ')
              .fontSize(12)
              .fontColor('#999999')
            Text(this.formattedDateEn)
              .fontSize(12)
              .fontWeight(FontWeight.Medium)
              .layoutWeight(1)
          }
          .width('100%')

          Row() {
            Text('时间: ')
              .fontSize(12)
              .fontColor('#999999')
            Text(this.formattedTimeZh)
              .fontSize(12)
              .fontWeight(FontWeight.Medium)
              .layoutWeight(1)
          }
          .width('100%')

          // 相对时间
          Text('相对时间格式化')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ top: 4 })

          Text(this.formattedRelativeTime)
            .fontSize(12)
            .fontColor('#333333')
            .width('100%')

          // 排序比较
          Text('字符串排序 (Collator)')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ top: 4 })

          Text(this.collatorResult)
            .fontSize(12)
            .fontColor('#333333')
            .width('100%')

          // 复数规则
          Text('复数规则 (PluralRules)')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ top: 4 })

          Text(this.pluralRules)
            .fontSize(12)
            .fontColor('#333333')
            .width('100%')

          // 自定义格式化结果
          Text('自定义格式化')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ top: 4 })

          Row() {
            Text('自定义数字: ')
              .fontSize(12)
              .fontColor('#999999')
            Text(this.customNumberResult)
              .fontSize(12)
              .fontWeight(FontWeight.Medium)
              .layoutWeight(1)
          }
          .width('100%')

          Row() {
            Text('自定义日期: ')
              .fontSize(12)
              .fontColor('#999999')
            Text(this.customDateResult)
              .fontSize(12)
              .fontWeight(FontWeight.Medium)
              .layoutWeight(1)
          }
          .width('100%')
        }
        .width('90%')
        .padding(16)
        .backgroundColor('#F5F5F5')
        .borderRadius(12)
        .alignItems(HorizontalAlign.Start)

        // 自定义输入
        Text('自定义数字')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        TextInput({ text: this.numberInput, placeholder: '输入数字' })
          .width('90%')
          .type(InputType.Number)
          .onChange((value: string) => {
            this.numberInput = value
          })

        Text('自定义日期 (YYYY-MM-DD)')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        TextInput({ text: this.dateInput, placeholder: '输入日期 (YYYY-MM-DD)' })
          .width('90%')
          .onChange((value: string) => {
            this.dateInput = value
          })

        // 操作按钮
        Row({ space: 12 }) {
          Button('全部格式化')
            .layoutWeight(1)
            .backgroundColor('#007DFF')
            .borderRadius(8)
            .onClick(() => this.doFormatAll())
          Button('自定义格式化')
            .layoutWeight(1)
            .backgroundColor('#00B578')
            .borderRadius(8)
            .onClick(() => this.doCustomFormat())
        }
        .width('90%')

        // 提示信息
        Column() {
          Text('注意事项')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 4 })
          Text('1. intl 模块在元服务中可正常使用')
            .fontSize(12)
            .fontColor('#00B578')
            .width('100%')
          Text('2. 支持 NumberFormat / DateTimeFormat / Collator / PluralRules')
            .fontSize(12)
            .fontColor('#996600')
            .width('100%')
          Text('3. 货币格式化需指定有效货币代码 (ISO 4217)')
            .fontSize(12)
            .fontColor('#996600')
            .width('100%')
          Text('4. 配合 i18n 模块获取系统 locale 自动适配格式')
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
          Text('import intl from "@ohos.intl"')
            .fontSize(12)
            .fontColor('#007DFF')
            .fontFamily('monospace')
          Text('// 数字格式化')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('let nf = new intl.NumberFormat("zh-Hans-CN")')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('nf.format(1234567.89)  // "1,234,567.89"')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('// 货币格式化')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('let cf = new intl.NumberFormat("zh-Hans-CN",')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('  { style: "currency", currency: "CNY" })')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('// 日期格式化')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('let df = new intl.DateTimeFormat("zh-Hans-CN",')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('  { dateStyle: "full", timeStyle: "medium" })')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('// 排序比较')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('let coll = new intl.Collator("zh-Hans-CN")')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('coll.compare("a", "b")  // -1')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('')
            .fontSize(8)
          Text('元服务API: intl 模块在元服务中完全可用')
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

  private doFormatAll(): void {
    try {
      const num = 1234567.89
      const now = new Date()

      // 数字格式化 - 不同语言
      let nfZh = new intl.NumberFormat('zh-Hans-CN')
      this.formattedNumberZh = nfZh.format(num)

      let nfEn = new intl.NumberFormat('en-US')
      this.formattedNumberEn = nfEn.format(num)

      let nfJa = new intl.NumberFormat('ja-JP')
      this.formattedNumberJa = nfJa.format(num)

      // 货币格式化
      let cfZh = new intl.NumberFormat('zh-Hans-CN', { style: 'currency', currency: 'CNY' })
      this.formattedCurrencyZh = cfZh.format(num)

      let cfEn = new intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' })
      this.formattedCurrencyEn = cfEn.format(num)

      // 百分比格式化
      let pfZh = new intl.NumberFormat('zh-Hans-CN', { style: 'percent', maximumFractionDigits: 2 })
      this.formattedPercentZh = pfZh.format(0.8567)

      // 日期格式化
      let dfZh = new intl.DateTimeFormat('zh-Hans-CN', { dateStyle: 'full', timeStyle: 'medium' })
      this.formattedDateZh = dfZh.format(now)

      let dfEn = new intl.DateTimeFormat('en-US', { dateStyle: 'full', timeStyle: 'medium' })
      this.formattedDateEn = dfEn.format(now)

      // 仅时间
      let tfZh = new intl.DateTimeFormat('zh-Hans-CN', { timeStyle: 'long' })
      this.formattedTimeZh = tfZh.format(now)

      // 相对时间格式化
      let rtLines: string[] = []
      try {
        let rt1 = new intl.RelativeTimeFormat('zh-Hans-CN', { numeric: 'auto' })
        rtLines.push(rt1.format(-1, 'day'))    // 昨天
        rtLines.push(rt1.format(2, 'hour'))    // 2小时后
        rtLines.push(rt1.format(-3, 'month'))  // 3个月前
      } catch (e) {
        rtLines.push('RelativeTimeFormat 不可用')
      }
      this.formattedRelativeTime = rtLines.join(' | ')

      // Collator 排序比较
      let coll = new intl.Collator('zh-Hans-CN')
      let words = ['苹果', '香蕉', '樱桃', '葡萄', '橙子']
      words.sort((a, b) => coll.compare(a, b))
      this.collatorResult = `排序结果: ${words.join(' < ')}`

      // PluralRules 复数规则
      let prLines: string[] = []
      try {
        let pr = new intl.PluralRules('en-US')
        prLines.push(`0 -> ${pr.select(0)}`)
        prLines.push(`1 -> ${pr.select(1)}`)
        prLines.push(`2 -> ${pr.select(2)}`)
        prLines.push(`5 -> ${pr.select(5)}`)
      } catch (e) {
        prLines.push('PluralRules 不可用')
      }
      this.pluralRules = prLines.join(' | ')

      this.resultText = '格式化演示完成'
    } catch (error) {
      const err = error as BusinessError
      this.resultText = `格式化失败: [${err.code}] ${err.message}`
    }
  }

  private doCustomFormat(): void {
    try {
      let num = parseFloat(this.numberInput)
      if (isNaN(num)) {
        this.resultText = '请输入有效数字'
        return
      }

      // 自定义数字格式化
      let nfZh = new intl.NumberFormat('zh-Hans-CN', {
        style: 'decimal',
        minimumFractionDigits: 2,
        maximumFractionDigits: 4,
        useGrouping: true
      })
      this.customNumberResult = nfZh.format(num)

      // 自定义日期格式化
      let dateStr = this.dateInput.trim()
      let dateParts = dateStr.split('-')
      if (dateParts.length === 3) {
        let year = parseInt(dateParts[0])
        let month = parseInt(dateParts[1]) - 1
        let day = parseInt(dateParts[2])
        let customDate = new Date(year, month, day)

        let dfZh = new intl.DateTimeFormat('zh-Hans-CN', {
          year: 'numeric',
          month: 'long',
          day: 'numeric',
          weekday: 'long'
        })
        this.customDateResult = dfZh.format(customDate)

        // 英文格式
        let dfEn = new intl.DateTimeFormat('en-US', {
          year: 'numeric',
          month: 'long',
          day: 'numeric',
          weekday: 'long'
        })
        this.customDateResult += '\n' + dfEn.format(customDate)
      } else {
        this.customDateResult = '日期格式无效，请使用 YYYY-MM-DD'
      }

      this.resultText = '自定义格式化完成'
    } catch (error) {
      const err = error as BusinessError
      this.resultText = `自定义格式化失败: [${err.code}] ${err.message}`
    }
  }
}
