/**
 * select-style — Select 样式定制
 * 展示 selectedOptionBgColor/FontColor、optionBgColor/FontColor、
 * selectedOptionFont、optionFont、font、fontColor 样式属性
 * 元服务兼容性：全部样式属性 元服务 API 11+ 可用
 */
import { BusinessError } from '@kit.BasicServicesKit'

@ComponentV2
export struct SelectStyle {
  @Local resultText: string = 'Select 样式对比展示'
  @Local eventLog: string = '点击 Select 查看样式变化'

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('Select 样式定制')
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

        // 1. 默认样式
        Column() {
          Text('1. 默认样式')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .width('100%')
            .margin({ bottom: 8 })

          Select([
            { value: '默认选项 A' },
            { value: '默认选项 B' },
            { value: '默认选项 C' }
          ])
            .selected(0)
            .value('默认样式')
            .onSelect((index: number, text?: string) => {
              try {
                this.resultText = `[默认] 选中: "${text}"`
                this.eventLog = `默认样式选中: ${text}`
              } catch (e) {
                const err = e as BusinessError
                this.eventLog = `错误: ${err.message}`
              }
            })
        }
        .width('90%')
        .padding(12)
        .backgroundColor('#FFFFFF')
        .borderRadius(8)
        .shadow({ radius: 2, color: '#22000000', offsetX: 0, offsetY: 1 })

        // 2. 自定义选中项背景色 (selectedOptionBgColor)
        Column() {
          Text('2. 自定义选中项背景色 (selectedOptionBgColor)')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .width('100%')
            .margin({ bottom: 8 })

          Select([
            { value: 'Blue 选项 A' },
            { value: 'Blue 选项 B' },
            { value: 'Blue 选项 C' }
          ])
            .selected(0)
            .value('蓝色主题')
            .fontColor('#182431')
            .selectedOptionBgColor('#BBDEFB')
            .selectedOptionFontColor('#1565C0')
            .optionBgColor('#FFFFFF')
            .optionFontColor('#424242')
            .onSelect((index: number, text?: string) => {
              try {
                this.resultText = `[Blue] 选中: "${text}"`
                this.eventLog = `蓝色主题选中: ${text}`
              } catch (e) {
                const err = e as BusinessError
                this.eventLog = `错误: ${err.message}`
              }
            })
        }
        .width('90%')
        .padding(12)
        .backgroundColor('#FFFFFF')
        .borderRadius(8)
        .shadow({ radius: 2, color: '#22000000', offsetX: 0, offsetY: 1 })

        // 3. 自定义选项文本样式 (optionFont)
        Column() {
          Text('3. 自定义选项文本样式 (optionFont / selectedOptionFont)')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .width('100%')
            .margin({ bottom: 8 })

          Select([
            { value: '大号字体选项' },
            { value: '中等字体选项' },
            { value: '加粗选项' }
          ])
            .selected(0)
            .value('字体样式')
            .font({ size: 14, weight: FontWeight.Medium })
            .fontColor('#333333')
            .selectedOptionFont({ size: 18, weight: FontWeight.Bold })
            .selectedOptionFontColor('#D32F2F')
            .optionFont({ size: 14, weight: FontWeight.Normal })
            .optionFontColor('#757575')
            .onSelect((index: number, text?: string) => {
              try {
                this.resultText = `[Font] 选中: "${text}"`
                this.eventLog = `字体样式选中: ${text}`
              } catch (e) {
                const err = e as BusinessError
                this.eventLog = `错误: ${err.message}`
              }
            })
        }
        .width('90%')
        .padding(12)
        .backgroundColor('#FFFFFF')
        .borderRadius(8)
        .shadow({ radius: 2, color: '#22000000', offsetX: 0, offsetY: 1 })

        // 4. 绿色主题完整样式
        Column() {
          Text('4. 完整样式组合（绿色主题）')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .width('100%')
            .margin({ bottom: 8 })

          Select([
            { value: 'Green A' },
            { value: 'Green B' },
            { value: 'Green C' },
            { value: 'Green D' }
          ])
            .selected(0)
            .value('绿色主题')
            .font({ size: 16, weight: FontWeight.Bold })
            .fontColor('#2E7D32')
            .selectedOptionBgColor('#C8E6C9')
            .selectedOptionFontColor('#1B5E20')
            .selectedOptionFont({ size: 16, weight: FontWeight.Bold })
            .optionBgColor('#F1F8E9')
            .optionFontColor('#558B2F')
            .optionFont({ size: 14, weight: FontWeight.Normal })
            .onSelect((index: number, text?: string) => {
              try {
                this.resultText = `[Green] 选中: "${text}" (index: ${index})`
                this.eventLog = '绿色主题选中'
              } catch (e) {
                const err = e as BusinessError
                this.eventLog = `错误: ${err.message}`
              }
            })
        }
        .width('90%')
        .padding(12)
        .backgroundColor('#FFFFFF')
        .borderRadius(8)
        .shadow({ radius: 2, color: '#22000000', offsetX: 0, offsetY: 1 })

        // 5. 暗色主题
        Column() {
          Text('5. 暗色主题')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .width('100%')
            .margin({ bottom: 8 })

          Select([
            { value: 'Dark A' },
            { value: 'Dark B' },
            { value: 'Dark C' }
          ])
            .selected(0)
            .value('暗色主题')
            .font({ size: 16, weight: FontWeight.Medium })
            .fontColor('#E0E0E0')
            .selectedOptionBgColor('#424242')
            .selectedOptionFontColor('#FFD54F')
            .selectedOptionFont({ size: 16, weight: FontWeight.Bold })
            .optionBgColor('#212121')
            .optionFontColor('#BDBDBD')
            .optionFont({ size: 14, weight: FontWeight.Normal })
            .onSelect((index: number, text?: string) => {
              try {
                this.resultText = `[Dark] 选中: "${text}"`
                this.eventLog = '暗色主题选中'
              } catch (e) {
                const err = e as BusinessError
                this.eventLog = `错误: ${err.message}`
              }
            })
        }
        .width('90%')
        .padding(12)
        .backgroundColor('#FFFFFF')
        .borderRadius(8)
        .shadow({ radius: 2, color: '#22000000', offsetX: 0, offsetY: 1 })

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

        // API 说明区
        Column() {
          Text('API 说明')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 8 })
          Text('.selectedOptionBgColor(color) — 选中项背景色')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('.selectedOptionFontColor(color) — 选中项文本颜色')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('.selectedOptionFont({ size, weight }) — 选中项文本样式')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('.optionBgColor(color) — 菜单项背景色')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('.optionFontColor(color) — 菜单项文本颜色')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('.optionFont({ size, weight }) — 菜单项文本样式')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('元服务兼容: 全部样式属性 元服务 API 11+ 可用')
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
