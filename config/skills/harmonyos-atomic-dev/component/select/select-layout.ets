/**
 * select-layout — Select 布局与对齐
 * 展示 space、arrowPosition、menuAlign、optionWidth、optionHeight、controlSize
 * 元服务兼容性：space/arrowPosition/menuAlign 元服务 API 11+；
 *              optionWidth/optionHeight/controlSize/menuBackgroundColor 元服务 API 12+
 */
import { BusinessError } from '@kit.BasicServicesKit'

@ComponentV2
export struct SelectLayout {
  @Local currentSpace: number = 8
  @Local resultText: string = 'Select 布局属性对比展示'
  @Local eventLog: string = '点击 Select 查看布局效果'

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('Select 布局与对齐')
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

        // 1. space 间距控制
        Column() {
          Text('1. space 文本与箭头间距')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .width('100%')
            .margin({ bottom: 8 })

          Row({ space: 16 }) {
            Column() {
              Select([
                { value: '间距 8（默认）' },
                { value: '选项 B' },
                { value: '选项 C' }
              ])
                .selected(0)
                .value('space=8')
                .space(8)
                .onSelect((index: number, text?: string) => {
                  try {
                    this.resultText = `[space=8] 选中: "${text}"`
                    this.eventLog = `间距8选中: ${text}`
                  } catch (e) {
                    const err = e as BusinessError
                    this.eventLog = `错误: ${err.message}`
                  }
                })
              Text('space(8)')
                .fontSize(11)
                .fontColor('#999999')
                .margin({ top: 4 })
            }

            Column() {
              Select([
                { value: '间距 20' },
                { value: '选项 B' },
                { value: '选项 C' }
              ])
                .selected(0)
                .value('space=20')
                .space(20)
                .onSelect((index: number, text?: string) => {
                  try {
                    this.resultText = `[space=20] 选中: "${text}"`
                    this.eventLog = `间距20选中: ${text}`
                  } catch (e) {
                    const err = e as BusinessError
                    this.eventLog = `错误: ${err.message}`
                  }
                })
              Text('space(20)')
                .fontSize(11)
                .fontColor('#999999')
                .margin({ top: 4 })
            }
          }
          .justifyContent(FlexAlign.Center)
        }
        .width('90%')
        .padding(12)
        .backgroundColor('#FFFFFF')
        .borderRadius(8)
        .shadow({ radius: 2, color: '#22000000', offsetX: 0, offsetY: 1 })

        // 2. arrowPosition 箭头位置
        Column() {
          Text('2. arrowPosition 箭头位置')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .width('100%')
            .margin({ bottom: 8 })

          Row({ space: 16 }) {
            Column() {
              Select([
                { value: 'END 文字前箭后' },
                { value: '选项 B' }
              ])
                .selected(0)
                .value('END')
                .arrowPosition(ArrowPosition.END)
                .onSelect((index: number, text?: string) => {
                  try {
                    this.resultText = `[END] 选中: "${text}"`
                  } catch (e) {
                    const err = e as BusinessError
                    this.resultText = `错误: ${err.message}`
                  }
                })
              Text('ArrowPosition.END')
                .fontSize(11)
                .fontColor('#999999')
                .margin({ top: 4 })
            }

            Column() {
              Select([
                { value: 'START 箭前文字后' },
                { value: '选项 B' }
              ])
                .selected(0)
                .value('START')
                .arrowPosition(ArrowPosition.START)
                .onSelect((index: number, text?: string) => {
                  try {
                    this.resultText = `[START] 选中: "${text}"`
                  } catch (e) {
                    const err = e as BusinessError
                    this.resultText = `错误: ${err.message}`
                  }
                })
              Text('ArrowPosition.START')
                .fontSize(11)
                .fontColor('#999999')
                .margin({ top: 4 })
            }
          }
          .justifyContent(FlexAlign.Center)
        }
        .width('90%')
        .padding(12)
        .backgroundColor('#FFFFFF')
        .borderRadius(8)
        .shadow({ radius: 2, color: '#22000000', offsetX: 0, offsetY: 1 })

        // 3. menuAlign 菜单对齐
        Column() {
          Text('3. menuAlign 下拉菜单对齐方式')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .width('100%')
            .margin({ bottom: 8 })

          Row({ space: 10 }) {
            Column() {
              Select([{ value: 'START对齐' }, { value: 'B' }, { value: 'C' }])
                .selected(0)
                .value('START')
                .menuAlign(MenuAlignType.START)
                .onSelect((index: number, text?: string) => {
                  try {
                    this.resultText = `[START对齐] 选中: "${text}"`
                  } catch (e) {
                    const err = e as BusinessError
                    this.resultText = `错误: ${err.message}`
                  }
                })
              Text('START')
                .fontSize(11)
                .fontColor('#999999')
                .margin({ top: 4 })
            }

            Column() {
              Select([{ value: 'CENTER对齐' }, { value: 'B' }, { value: 'C' }])
                .selected(0)
                .value('CENTER')
                .menuAlign(MenuAlignType.CENTER)
                .onSelect((index: number, text?: string) => {
                  try {
                    this.resultText = `[CENTER对齐] 选中: "${text}"`
                  } catch (e) {
                    const err = e as BusinessError
                    this.resultText = `错误: ${err.message}`
                  }
                })
              Text('CENTER')
                .fontSize(11)
                .fontColor('#999999')
                .margin({ top: 4 })
            }

            Column() {
              Select([{ value: 'END对齐' }, { value: 'B' }, { value: 'C' }])
                .selected(0)
                .value('END')
                .menuAlign(MenuAlignType.END)
                .onSelect((index: number, text?: string) => {
                  try {
                    this.resultText = `[END对齐] 选中: "${text}"`
                  } catch (e) {
                    const err = e as BusinessError
                    this.resultText = `错误: ${err.message}`
                  }
                })
              Text('END')
                .fontSize(11)
                .fontColor('#999999')
                .margin({ top: 4 })
            }
          }
          .justifyContent(FlexAlign.Center)
        }
        .width('90%')
        .padding(12)
        .backgroundColor('#FFFFFF')
        .borderRadius(8)
        .shadow({ radius: 2, color: '#22000000', offsetX: 0, offsetY: 1 })

        // 4. optionWidth / optionHeight（元服务 API 12+）
        Column() {
          Text('4. optionWidth / optionHeight（元服务 API 12+）')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .width('100%')
            .margin({ bottom: 8 })

          Select([
            { value: '自定义宽度选项 A' },
            { value: '自定义宽度选项 B' },
            { value: '自定义宽度选项 C' },
            { value: '自定义宽度选项 D' }
          ])
            .selected(0)
            .value('自定义尺寸')
            .optionWidth(200)
            .optionHeight(150)
            .font({ size: 14, weight: FontWeight.Medium })
            .fontColor('#333333')
            .onSelect((index: number, text?: string) => {
              try {
                this.resultText = `[自定义尺寸] 选中: "${text}"`
                this.eventLog = `自定义尺寸选中: ${text}`
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

        // 5. menuBackgroundColor / menuBackgroundBlurStyle（元服务 API 12+）
        Column() {
          Text('5. menuBackgroundColor（元服务 API 12+）')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .width('100%')
            .margin({ bottom: 8 })

          Select([
            { value: '半透明背景 A' },
            { value: '半透明背景 B' },
            { value: '半透明背景 C' }
          ])
            .selected(0)
            .value('菜单背景色')
            .menuBackgroundColor('#E8F5E9')
            .selectedOptionBgColor('#C8E6C9')
            .selectedOptionFontColor('#2E7D32')
            .optionBgColor(Color.Transparent)
            .onSelect((index: number, text?: string) => {
              try {
                this.resultText = `[菜单背景] 选中: "${text}"`
                this.eventLog = `菜单背景选中: ${text}`
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
          Text('.space(value) — 文本与箭头间距，默认 8（元服务 API 11+）')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('.arrowPosition(END|START) — 箭头位置，默认 END（元服务 API 11+）')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('.menuAlign(START|CENTER|END, offset?) — 菜单对齐（元服务 API 11+）')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('.optionWidth(width) — 菜单项宽度（元服务 API 12+）')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('.optionHeight(height) — 菜单最大高度（元服务 API 12+）')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('.menuBackgroundColor(color) — 菜单背景色（元服务 API 12+）')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('元服务兼容: space/arrowPosition/menuAlign API 11+，optionWidth/Height/backgroundColor API 12+')
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
