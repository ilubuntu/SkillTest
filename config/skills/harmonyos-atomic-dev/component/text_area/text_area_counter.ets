/**
 * text_area_counter — TextArea 字数限制与计数
 * 展示 TextArea maxLength + showCounter 字数统计功能
 * 元服务兼容性：maxLength API 7+，showCounter API 7+，元服务可用
 */

import { BusinessError } from '@kit.BasicServicesKit'

@ComponentV2
export struct TextAreaCounter {
  @Local resultText: string = '输入文本查看计数效果'
  @Local inputText: string = ''
  @Local maxLen: number = 50

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('TextArea 字数限制与计数')
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

        // 带 maxLength + showCounter 的 TextArea
        Text('带字数统计的输入框')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        TextArea({ placeholder: `最多输入 ${this.maxLen} 个字符...`, text: this.inputText })
          .width('90%')
          .height(120)
          .maxLength(this.maxLen)
          .showCounter(true)
          .onChange((value: string) => {
            try {
              this.inputText = value
              const remaining = this.maxLen - value.length
              this.resultText = `已输入: ${value.length}/${this.maxLen}\n剩余: ${remaining} 字符`
            } catch (e) {
              const err = e as BusinessError
              this.resultText = `onChange 异常: code=${err.code}, msg=${err.message}`
            }
          })

        // 不带 showCounter 的 maxLength
        Text('仅限制字数（不显示计数器）')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        TextArea({ placeholder: '最多20字，无计数器显示...' })
          .width('90%')
          .height(80)
          .maxLength(20)

        // maxLength 值切换
        Text('maxLength 设置')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Row({ space: 8 }) {
          Button('20字')
            .fontSize(13)
            .layoutWeight(1)
            .height(36)
            .backgroundColor(this.maxLen === 20 ? '#2196F3' : '#CCCCCC')
            .onClick(() => {
              this.maxLen = 20
              this.inputText = this.inputText.substring(0, 20)
              this.resultText = 'maxLength 已设置为 20'
            })
          Button('50字')
            .fontSize(13)
            .layoutWeight(1)
            .height(36)
            .backgroundColor(this.maxLen === 50 ? '#2196F3' : '#CCCCCC')
            .onClick(() => {
              this.maxLen = 50
              this.resultText = 'maxLength 已设置为 50'
            })
          Button('100字')
            .fontSize(13)
            .layoutWeight(1)
            .height(36)
            .backgroundColor(this.maxLen === 100 ? '#2196F3' : '#CCCCCC')
            .onClick(() => {
              this.maxLen = 100
              this.resultText = 'maxLength 已设置为 100'
            })
          Button('200字')
            .fontSize(13)
            .layoutWeight(1)
            .height(36)
            .backgroundColor(this.maxLen === 200 ? '#2196F3' : '#CCCCCC')
            .onClick(() => {
              this.maxLen = 200
              this.resultText = 'maxLength 已设置为 200'
            })
        }
        .width('90%')

        // 操作按钮
        Row({ space: 8 }) {
          Button('清空')
            .fontSize(13)
            .layoutWeight(1)
            .height(36)
            .onClick(() => {
              this.inputText = ''
              this.resultText = '已清空输入'
            })
          Button('填充到上限')
            .fontSize(13)
            .layoutWeight(1)
            .height(36)
            .onClick(() => {
              this.inputText = '你'.repeat(this.maxLen)
              this.resultText = `已填充 ${this.maxLen} 个字符到上限`
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
          Text('.maxLength(number): 设置最大可输入字符数')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('.showCounter(boolean): 是否显示字数统计，需配合 maxLength')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('注意: maxLength 仅限制输入，超出的内容会被截断')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('元服务：maxLength / showCounter API 7+ 可用')
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
