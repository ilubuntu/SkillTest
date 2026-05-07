/**
 * text_area_basic — TextArea 基础输入
 * 展示 TextArea 多行文本框基本用法：创建、placeholder、text、自动换行
 * 元服务兼容性：TextArea API 7+，元服务 API 11+ 可用
 */

@ComponentV2
export struct TextAreaBasic {
  @Local resultText: string = '等待输入...'
  @Local inputText: string = ''

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('TextArea 基础输入')
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

        // 基础 TextArea
        Text('基础多行输入')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        TextArea({ placeholder: '请输入多行文本内容...', text: this.inputText })
          .width('90%')
          .height(120)
          .onChange((value: string) => {
            try {
              this.inputText = value
              this.resultText = `当前输入: "${value}"\n长度: ${value.length} 字符`
            } catch (e) {
              this.resultText = `onChange 异常: ${(e as Error).message}`
            }
          })

        // 带 placeholder 颜色
        Text('自定义 placeholder 颜色')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        TextArea({ placeholder: '灰色提示文本...' })
          .width('90%')
          .height(80)
          .placeholderColor('#999999')

        // 预填充文本
        Text('预填充文本')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        TextArea({ text: '这是一段预填充的多行文本内容。\n第二行内容。', placeholder: '请输入...' })
          .width('90%')
          .height(100)

        // 操作按钮
        Text('操作')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Row({ space: 8 }) {
          Button('清空输入')
            .fontSize(13)
            .layoutWeight(1)
            .height(36)
            .onClick(() => {
              this.inputText = ''
              this.resultText = '已清空输入'
            })
          Button('查看当前值')
            .fontSize(13)
            .layoutWeight(1)
            .height(36)
            .onClick(() => {
              this.resultText = `当前值: "${this.inputText}"\n长度: ${this.inputText.length}`
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
          Text('TextArea(value?: {placeholder?: ResourceStr, text?: ResourceStr, controller?: TextAreaController})')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('placeholder: 无输入时的提示文本')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('text: 输入框的文本内容')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('onChange(callback): 输入内容变化时触发')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('placeholderColor(color): 提示文本颜色')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('元服务：API 7+ 可用，基础能力无限制')
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
