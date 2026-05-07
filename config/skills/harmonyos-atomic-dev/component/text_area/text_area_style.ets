/**
 * text_area_style — TextArea 样式设置
 * 展示 TextArea 多态样式（DEFAULT / INLINE）、字体样式、背景色等
 * 元服务兼容性：style 属性 API 10+，元服务 API 11+ 可用
 */

@ComponentV2
export struct TextAreaStyle {
  @Local resultText: string = '切换样式查看效果'
  @Local currentStyle: number = 0 // 0: DEFAULT, 1: INLINE
  @Local fontSize: number = 16
  @Local fontColor: string = '#333333'
  @Local bgColor: string = '#FFFFFF'

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('TextArea 样式设置')
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

        // 样式预览
        Text('样式预览')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        TextArea({ placeholder: '输入文本查看样式效果...', text: '样式预览文本' })
          .width('90%')
          .height(120)
          .style(this.currentStyle === 0 ? TextContentStyle.DEFAULT : TextContentStyle.INLINE)
          .fontSize(this.fontSize)
          .fontColor(this.fontColor)
          .backgroundColor(this.bgColor)
          .onChange((value: string) => {
            this.resultText = `样式模式: ${this.currentStyle === 0 ? 'DEFAULT' : 'INLINE'}\n输入: ${value}`
          })

        // 多态样式切换
        Text('多态样式')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Row({ space: 8 }) {
          Button('DEFAULT')
            .fontSize(13)
            .layoutWeight(1)
            .height(36)
            .backgroundColor(this.currentStyle === 0 ? '#2196F3' : '#CCCCCC')
            .onClick(() => {
              this.currentStyle = 0
              this.resultText = 'DEFAULT 风格：编辑态和非编辑态样式无区别'
            })
          Button('INLINE')
            .fontSize(13)
            .layoutWeight(1)
            .height(36)
            .backgroundColor(this.currentStyle === 1 ? '#2196F3' : '#CCCCCC')
            .onClick(() => {
              this.currentStyle = 1
              this.resultText = 'INLINE 风格：编辑态和非编辑态样式有明显区分'
            })
        }
        .width('90%')

        // 字体大小控制
        Text(`字体大小: ${this.fontSize}fp`)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Row({ space: 8 }) {
          Button('12fp')
            .fontSize(13)
            .layoutWeight(1)
            .height(36)
            .onClick(() => { this.fontSize = 12 })
          Button('16fp')
            .fontSize(13)
            .layoutWeight(1)
            .height(36)
            .onClick(() => { this.fontSize = 16 })
          Button('20fp')
            .fontSize(13)
            .layoutWeight(1)
            .height(36)
            .onClick(() => { this.fontSize = 20 })
          Button('24fp')
            .fontSize(13)
            .layoutWeight(1)
            .height(36)
            .onClick(() => { this.fontSize = 24 })
        }
        .width('90%')

        // 字体颜色
        Text('字体颜色')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Row({ space: 8 }) {
          Column()
            .width(36)
            .height(36)
            .backgroundColor('#333333')
            .borderRadius(18)
            .border({ width: this.fontColor === '#333333' ? 3 : 0, color: this.fontColor === '#333333' ? '#2196F3' : '#333333' })
            .onClick(() => { this.fontColor = '#333333' })
          Column()
            .width(36)
            .height(36)
            .backgroundColor('#E53935')
            .borderRadius(18)
            .border({ width: this.fontColor === '#E53935' ? 3 : 0, color: '#2196F3' })
            .onClick(() => { this.fontColor = '#E53935' })
          Column()
            .width(36)
            .height(36)
            .backgroundColor('#1E88E5')
            .borderRadius(18)
            .border({ width: this.fontColor === '#1E88E5' ? 3 : 0, color: '#2196F3' })
            .onClick(() => { this.fontColor = '#1E88E5' })
          Column()
            .width(36)
            .height(36)
            .backgroundColor('#43A047')
            .borderRadius(18)
            .border({ width: this.fontColor === '#43A047' ? 3 : 0, color: '#2196F3' })
            .onClick(() => { this.fontColor = '#43A047' })
        }
        .width('90%')
        .justifyContent(FlexAlign.Start)

        // 背景颜色
        Text('背景颜色')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Row({ space: 8 }) {
          Button('白色')
            .fontSize(13)
            .layoutWeight(1)
            .height(36)
            .onClick(() => { this.bgColor = '#FFFFFF' })
          Button('浅灰')
            .fontSize(13)
            .layoutWeight(1)
            .height(36)
            .onClick(() => { this.bgColor = '#F5F5F5' })
          Button('浅黄')
            .fontSize(13)
            .layoutWeight(1)
            .height(36)
            .onClick(() => { this.bgColor = '#FFFDE7' })
          Button('浅蓝')
            .fontSize(13)
            .layoutWeight(1)
            .height(36)
            .onClick(() => { this.bgColor = '#E3F2FD' })
        }
        .width('90%')

        // API 说明区
        Column() {
          Text('API 说明')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 8 })
          Text('.style(TextContentStyle): DEFAULT(默认) | INLINE(内联)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('.fontSize(number): 设置文本大小')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('.fontColor(Color): 设置文本颜色')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('.backgroundColor(Color): 设置背景颜色')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('元服务：style 属性 API 10+ 可用')
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
