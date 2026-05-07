/**
 * scroll-edge — 边缘滑动效果
 * 展示 edgeEffect: Spring(弹簧) / Fade(渐隐) / None(无效果) + friction 摩擦系数
 * 元服务兼容性：edgeEffect/friction 元服务 API 11+ 可用
 */
import { BusinessError } from '@kit.BasicServicesKit'

@ComponentV2
export struct ScrollEdge {
  @Local effectType: EdgeEffect = EdgeEffect.Spring
  @Local frictionVal: number = 0.7
  @Local resultText: string = '边缘效果: Spring(弹簧) | 摩擦: 0.7'
  private scroller: Scroller = new Scroller()

  private buildItems(): number[] {
    const items: number[] = []
    for (let i = 0; i < 15; i++) {
      items.push(i)
    }
    return items
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('边缘滑动效果')
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

        // 滚动区域
        Text('滚动区域（尝试滑到边界）')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Scroll(this.scroller) {
          Column({ space: 8 }) {
            ForEach(this.buildItems(),
              (item: number) => {
                Text(`内容项 ${item + 1}`)
                  .width('100%')
                  .height(70)
                  .backgroundColor(item % 3 === 0 ? '#E3F2FD' : item % 3 === 1 ? '#FFF3E0' : '#E8F5E9')
                  .borderRadius(8)
                  .fontSize(15)
                  .textAlign(TextAlign.Center)
              }, (item: number) => `item_${item}`)
          }
          .padding(8)
        }
        .scrollable(ScrollDirection.Vertical)
        .scrollBar(BarState.On)
        .edgeEffect(this.effectType)
        .friction(this.frictionVal)
        .width('90%')
        .height(300)
        .borderRadius(8)
        .backgroundColor('#F0F0F0')

        // 边缘效果选择
        Text('edgeEffect 边缘效果')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Row({ space: 8 }) {
          Button('Spring 弹簧')
            .fontSize(13)
            .layoutWeight(1)
            .height(36)
            .backgroundColor(this.effectType === EdgeEffect.Spring ? '#007DFF' : '#CCCCCC')
            .onClick(() => {
              this.effectType = EdgeEffect.Spring
              this.updateResult()
            })
          Button('Fade 渐隐')
            .fontSize(13)
            .layoutWeight(1)
            .height(36)
            .backgroundColor(this.effectType === EdgeEffect.Fade ? '#007DFF' : '#CCCCCC')
            .onClick(() => {
              this.effectType = EdgeEffect.Fade
              this.updateResult()
            })
          Button('None 无')
            .fontSize(13)
            .layoutWeight(1)
            .height(36)
            .backgroundColor(this.effectType === EdgeEffect.None ? '#007DFF' : '#CCCCCC')
            .onClick(() => {
              this.effectType = EdgeEffect.None
              this.updateResult()
            })
        }
        .width('90%')

        // friction 摩擦系数
        Text('friction 摩擦系数（影响惯性滚动）')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Row({ space: 8 }) {
          Button('0.3')
            .fontSize(13)
            .layoutWeight(1)
            .height(36)
            .onClick(() => { this.frictionVal = 0.3; this.updateResult() })
          Button('0.7')
            .fontSize(13)
            .layoutWeight(1)
            .height(36)
            .onClick(() => { this.frictionVal = 0.7; this.updateResult() })
          Button('1.0')
            .fontSize(13)
            .layoutWeight(1)
            .height(36)
            .onClick(() => { this.frictionVal = 1.0; this.updateResult() })
          Button('2.0')
            .fontSize(13)
            .layoutWeight(1)
            .height(36)
            .onClick(() => { this.frictionVal = 2.0; this.updateResult() })
        }
        .width('90%')

        Text('摩擦系数说明: 值越小惯性越大，值越大滚动阻力越大。默认 0.75（非可穿戴）')
          .fontSize(12)
          .fontColor('#999999')
          .width('90%')
          .margin({ top: 4 })

        // API 说明区
        Column() {
          Text('API 说明')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 8 })
          Text('.edgeEffect(EdgeEffect, options?)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('EdgeEffect.Spring — 弹簧回弹效果（推荐）')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('EdgeEffect.Fade — 边缘渐隐效果')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('EdgeEffect.None — 无边缘效果（默认值）')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('.friction(value: number | Resource) — 默认 0.75')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('friction 范围: (0, +∞)，≤ 0 按默认值处理')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('元服务：edgeEffect/friction API 11+ 可用')
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

  private updateResult(): void {
    const effectStr = this.effectType === EdgeEffect.Spring ? 'Spring(弹簧)' :
      this.effectType === EdgeEffect.Fade ? 'Fade(渐隐)' : 'None(无)'
    this.resultText = `边缘效果: ${effectStr} | 摩擦: ${this.frictionVal}`
  }
}
