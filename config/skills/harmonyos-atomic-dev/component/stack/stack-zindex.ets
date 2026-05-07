/**
 * stack-zindex — Stack Z序控制
 * 展示 zIndex 属性控制子组件显示层级
 * 元服务兼容性：zIndex 通用属性 API 7+，元服务可用
 */
import { BusinessError } from '@kit.BasicServicesKit'

@ComponentV2
export struct StackZindex {
  @Local resultText: string = '点击按钮切换 Z 序'
  @Local mode: number = 0 // 0=默认顺序, 1=zIndex翻转

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('Stack Z序控制')
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

        // 默认顺序预览
        Text('默认顺序（无 zIndex）')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Stack({ alignContent: Alignment.Center }) {
          Column() {
            Text('子元素1 (100x100)')
              .fontSize(11)
              .fontColor('#FFFFFF')
          }
          .width(100)
          .height(100)
          .backgroundColor('#FFD54F')
          .borderRadius(8)
          .justifyContent(FlexAlign.Center)

          Column() {
            Text('子元素2 (150x150)')
              .fontSize(11)
              .fontColor('#FFFFFF')
          }
          .width(150)
          .height(150)
          .backgroundColor('#F06292')
          .borderRadius(8)
          .justifyContent(FlexAlign.Center)

          Column() {
            Text('子元素3 (200x200)')
              .fontSize(11)
              .fontColor('#FFFFFF')
          }
          .width(200)
          .height(200)
          .backgroundColor('#7E57C2')
          .borderRadius(8)
          .justifyContent(FlexAlign.Center)
        }
        .width(240)
        .height(240)
        .backgroundColor('#EDE7F6')
        .borderRadius(12)

        Text('子元素3 最大，完全覆盖子元素1、2')
          .fontSize(12)
          .fontColor('#999999')
          .margin({ top: 4 })

        // zIndex 翻转预览
        Text('zIndex 翻转层级')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Stack({ alignContent: Alignment.Center }) {
          Column() {
            Text('子元素1 (100x100)')
              .fontSize(11)
              .fontColor('#FFFFFF')
          }
          .width(100)
          .height(100)
          .backgroundColor('#FFD54F')
          .borderRadius(8)
          .justifyContent(FlexAlign.Center)
          .zIndex(this.mode === 1 ? 3 : 0)

          Column() {
            Text('子元素2 (150x150)')
              .fontSize(11)
              .fontColor('#FFFFFF')
          }
          .width(150)
          .height(150)
          .backgroundColor('#F06292')
          .borderRadius(8)
          .justifyContent(FlexAlign.Center)
          .zIndex(this.mode === 1 ? 2 : 0)

          Column() {
            Text('子元素3 (200x200)')
              .fontSize(11)
              .fontColor('#FFFFFF')
          }
          .width(200)
          .height(200)
          .backgroundColor('#7E57C2')
          .borderRadius(8)
          .justifyContent(FlexAlign.Center)
          .zIndex(this.mode === 1 ? 1 : 0)
        }
        .width(240)
        .height(240)
        .backgroundColor('#EDE7F6')
        .borderRadius(12)

        if (this.mode === 1) {
          Text('子元素1 zIndex=3 显示在最上层')
            .fontSize(12)
            .fontColor('#4CAF50')
            .margin({ top: 4 })
        }

        // 切换按钮
        Row({ space: 8 }) {
          Button('默认顺序')
            .fontSize(13)
            .layoutWeight(1)
            .height(36)
            .onClick(() => {
              try {
                this.mode = 0
                this.resultText = '默认顺序：后入栈覆盖前入栈，大元素覆盖小元素'
              } catch (error) {
                this.resultText = `错误: ${(error as BusinessError).message}`
              }
            })
          Button('zIndex 翻转')
            .fontSize(13)
            .layoutWeight(1)
            .height(36)
            .onClick(() => {
              try {
                this.mode = 1
                this.resultText = '子元素1 zIndex=3，子元素2 zIndex=2，子元素3 zIndex=1'
              } catch (error) {
                this.resultText = `错误: ${(error as BusinessError).message}`
              }
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
          Text('.zIndex(value: number) — 通用属性')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('zIndex 值越大，显示层级越高')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('默认 zIndex=0，后入栈的子组件在上方')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('当后入栈子元素尺寸更大时，前面的子元素会被完全隐藏')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('元服务：通用属性，无限制')
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
