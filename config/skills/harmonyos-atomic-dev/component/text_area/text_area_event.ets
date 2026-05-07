/**
 * text_area_event — TextArea 事件处理
 * 展示 TextArea 各类事件：onChange、onFocus、onBlur、onTextSelectionChange
 * 元服务兼容性：基础事件 API 7+，元服务可用
 */

import { BusinessError } from '@kit.BasicServicesKit'

@ComponentV2
export struct TextAreaEvent {
  @Local resultText: string = '等待事件触发...'
  @Local changeCount: number = 0
  @Local focusState: string = '未聚焦'
  @Local selectionInfo: string = '无选区'
  @Local inputText: string = ''

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('TextArea 事件处理')
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

        // 事件状态面板
        Text('事件状态')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Column() {
          Row() {
            Text('onChange 次数:')
              .fontSize(13)
              .fontColor('#666666')
              .width('50%')
            Text(`${this.changeCount}`)
              .fontSize(13)
              .fontWeight(FontWeight.Bold)
              .fontColor('#2196F3')
              .width('50%')
          }
          .width('100%')
          .margin({ bottom: 4 })

          Row() {
            Text('焦点状态:')
              .fontSize(13)
              .fontColor('#666666')
              .width('50%')
            Text(this.focusState)
              .fontSize(13)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.focusState === '已聚焦' ? '#4CAF50' : '#999999')
              .width('50%')
          }
          .width('100%')
          .margin({ bottom: 4 })

          Row() {
            Text('选区信息:')
              .fontSize(13)
              .fontColor('#666666')
              .width('50%')
            Text(this.selectionInfo)
              .fontSize(13)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FF9800')
              .width('50%')
          }
          .width('100%')
        }
        .width('90%')
        .backgroundColor('#FFFFFF')
        .borderRadius(8)
        .padding(12)
        .border({ width: 1, color: '#E0E0E0' })

        // 绑定事件的 TextArea
        Text('输入框（绑定全部事件）')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        TextArea({ placeholder: '在此输入，触发各类事件...', text: this.inputText })
          .width('90%')
          .height(120)
          .onChange((value: string) => {
            try {
              this.changeCount++
              this.inputText = value
              this.resultText = `onChange 触发 #${this.changeCount}\n输入值: "${value}"\n长度: ${value.length}`
            } catch (e) {
              const err = e as BusinessError
              this.resultText = `onChange 异常: code=${err.code}, msg=${err.message}`
            }
          })
          .onFocus(() => {
            this.focusState = '已聚焦'
            this.resultText = 'onFocus: 输入框获得焦点'
          })
          .onBlur(() => {
            this.focusState = '未聚焦'
            this.resultText = 'onBlur: 输入框失去焦点'
          })
          .onTextSelectionChange((selectionStart: number, selectionEnd: number) => {
            this.selectionInfo = `[${selectionStart}, ${selectionEnd})`
            this.resultText = `onTextSelectionChange\n选区: [${selectionStart}, ${selectionEnd})`
          })

        // 操作按钮
        Text('操作')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Row({ space: 8 }) {
          Button('重置计数')
            .fontSize(13)
            .layoutWeight(1)
            .height(36)
            .onClick(() => {
              this.changeCount = 0
              this.selectionInfo = '无选区'
              this.resultText = '已重置所有计数'
            })
          Button('查看状态')
            .fontSize(13)
            .layoutWeight(1)
            .height(36)
            .onClick(() => {
              this.resultText = `onChange: ${this.changeCount}次\n焦点: ${this.focusState}\n选区: ${this.selectionInfo}\n文本: "${this.inputText}"`
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
          Text('.onChange((value: string) => void): 输入内容变化时触发')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('.onFocus(() => void): 获得焦点时触发')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('.onBlur(() => void): 失去焦点时触发')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('.onTextSelectionChange((start, end) => void): 选区变化时触发')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('元服务：基础事件 API 7+ 可用')
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
