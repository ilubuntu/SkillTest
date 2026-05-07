/**
 * text_input_style — TextInput 样式自定义
 * 展示 TextInput 样式属性：字体/颜色/对齐/下划线/placeholder/光标/选中底色
 * 元服务兼容性：基础样式属性 API 11+ 可用，下划线/光标风格 API 10+ 元服务 11+
 */

@ComponentV2
export struct TextInputStyle {
  @Local resultText: string = '调整下方控件查看样式效果'
  @Local inputText: string = ''
  @Local fontSizeValue: number = 16
  @Local fontColorValue: string = '#333333'
  @Local placeholderColorValue: string = '#999999'
  @Local caretColorValue: string = '#007DFF'
  @Local textAlignIndex: number = 0
  @Local showUnderlineEnabled: boolean = false

  private textAlignOptions: TextAlign[] = [TextAlign.Start, TextAlign.Center, TextAlign.End]
  private textAlignNames: string[] = ['Start', 'Center', 'End']

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('TextInput 样式自定义')
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

        // 字体大小控制
        Text('字体大小')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Row({ space: 8 }) {
          Button('12fp')
            .fontSize(12)
            .layoutWeight(1)
            .height(32)
            .onClick(() => { this.fontSizeValue = 12 })
          Button('16fp')
            .fontSize(12)
            .layoutWeight(1)
            .height(32)
            .onClick(() => { this.fontSizeValue = 16 })
          Button('20fp')
            .fontSize(12)
            .layoutWeight(1)
            .height(32)
            .onClick(() => { this.fontSizeValue = 20 })
        }
        .width('90%')

        // 字体颜色控制
        Text('字体颜色')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Row({ space: 8 }) {
          Button('深灰')
            .fontSize(12)
            .layoutWeight(1)
            .height(32)
            .backgroundColor('#333333')
            .onClick(() => { this.fontColorValue = '#333333' })
          Button('红色')
            .fontSize(12)
            .layoutWeight(1)
            .height(32)
            .backgroundColor('#E53935')
            .onClick(() => { this.fontColorValue = '#E53935' })
          Button('蓝色')
            .fontSize(12)
            .layoutWeight(1)
            .height(32)
            .backgroundColor('#1E88E5')
            .onClick(() => { this.fontColorValue = '#1E88E5' })
        }
        .width('90%')

        // placeholder 颜色
        Text('placeholder 颜色')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Row({ space: 8 }) {
          Button('灰色')
            .fontSize(12)
            .layoutWeight(1)
            .height(32)
            .onClick(() => { this.placeholderColorValue = '#999999' })
          Button('橙色')
            .fontSize(12)
            .layoutWeight(1)
            .height(32)
            .onClick(() => { this.placeholderColorValue = '#FF9800' })
          Button('绿色')
            .fontSize(12)
            .layoutWeight(1)
            .height(32)
            .onClick(() => { this.placeholderColorValue = '#4CAF50' })
        }
        .width('90%')

        // 光标颜色
        Text('光标颜色')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Row({ space: 8 }) {
          Button('默认蓝')
            .fontSize(12)
            .layoutWeight(1)
            .height(32)
            .onClick(() => { this.caretColorValue = '#007DFF' })
          Button('紫色')
            .fontSize(12)
            .layoutWeight(1)
            .height(32)
            .onClick(() => { this.caretColorValue = '#9C27B0' })
          Button('绿色')
            .fontSize(12)
            .layoutWeight(1)
            .height(32)
            .onClick(() => { this.caretColorValue = '#4CAF50' })
        }
        .width('90%')

        // 文本对齐
        Text('文本对齐')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Row({ space: 8 }) {
          ForEach(this.textAlignNames, (name: string, index: number) => {
            Button(name)
              .fontSize(12)
              .layoutWeight(1)
              .height(32)
              .backgroundColor(this.textAlignIndex === index ? '#007DFF' : '#666666')
              .onClick(() => {
                this.textAlignIndex = index
                this.resultText = `对齐方式: ${name}`
              })
          }, (name: string) => name)
        }
        .width('90%')

        // 下划线开关
        Text('下划线模式')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Row({ space: 8 }) {
          Button(this.showUnderlineEnabled ? '关闭下划线' : '开启下划线')
            .fontSize(13)
            .width('90%')
            .height(36)
            .backgroundColor(this.showUnderlineEnabled ? '#E53935' : '#4CAF50')
            .onClick(() => {
              this.showUnderlineEnabled = !this.showUnderlineEnabled
              this.resultText = `下划线: ${this.showUnderlineEnabled ? '已开启' : '已关闭'}`
            })
        }
        .width('90%')

        // 样式预览
        Text('样式预览')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        TextInput({ placeholder: '在此输入查看样式效果...', text: this.inputText })
          .type(InputType.Normal)
          .width('90%')
          .height(48)
          .fontSize(this.fontSizeValue)
          .fontColor(this.fontColorValue)
          .placeholderColor(this.placeholderColorValue)
          .caretColor(this.caretColorValue)
          .textAlign(this.textAlignOptions[this.textAlignIndex])
          .showUnderline(this.showUnderlineEnabled)
          .selectedBackgroundColor('#33007DFF')
          .placeholderFont({ size: this.fontSizeValue })
          .onChange((value: string) => {
            try {
              this.inputText = value
              this.resultText = `当前样式: ${this.fontSizeValue}fp / ${this.fontColorValue} / ${this.textAlignNames[this.textAlignIndex]}\n输入: "${value}"`
            } catch (e) {
              this.resultText = `onChange 异常: ${(e as Error).message}`
            }
          })

        // API 说明区
        Column() {
          Text('API 说明')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 8 })
          Text('fontSize(value: Length) — 字体大小，number 时 fp 单位，默认 16fp')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('fontColor(value: ResourceColor) — 字体颜色')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('placeholderColor(value: ResourceColor) — placeholder 颜色')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('placeholderFont(value?: Font) — placeholder 字体样式')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('caretColor(value: ResourceColor) — 光标颜色，默认 #007DFF')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('textAlign(value: TextAlign) — 文本水平对齐：Start/Center/End')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('showUnderline(value: boolean) — 下划线模式，默认 false，仅 Normal 类型')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('selectedBackgroundColor(value: ResourceColor) — 选中底板颜色')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('元服务：以上属性均从 API 11+ 可用')
            .fontSize(12)
            .fontColor('#4CAF50')
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
