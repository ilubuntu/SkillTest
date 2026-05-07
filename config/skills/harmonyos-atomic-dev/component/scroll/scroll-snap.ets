/**
 * scroll-snap — 限位滚动模式
 * 展示 scrollSnap(ScrollSnapOptions) 分页对齐：snapAlign + snapPagination
 * 元服务兼容性：scrollSnap 元服务 API 11+ 可用，enablePaging 元服务 API 12+
 */
import { BusinessError } from '@kit.BasicServicesKit'

@ComponentV2
export struct ScrollSnapDemo {
  @Local snapAlign: ScrollSnapAlign = ScrollSnapAlign.START
  @Local snapPagination: number = 200
  @Local resultText: string = '对齐: START | 分页大小: 200vp'
  private scroller: Scroller = new Scroller()

  private buildItems(): number[] {
    const items: number[] = []
    for (let i = 0; i < 16; i++) {
      items.push(i)
    }
    return items
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('限位滚动模式')
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

        // 限位滚动区域
        Text('限位滚动区域（滑动后自动对齐到分页点）')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Scroll(this.scroller) {
          Column({ space: 4 }) {
            ForEach(this.buildItems(),
              (item: number) => {
                Text(`卡片 ${item + 1}`)
                  .width('100%')
                  .height(195)
                  .backgroundColor(item % 4 === 0 ? '#E3F2FD' : item % 4 === 1 ? '#FFF3E0' :
                    item % 4 === 2 ? '#E8F5E9' : '#F3E5F5')
                  .borderRadius(12)
                  .fontSize(18)
                  .fontWeight(FontWeight.Medium)
                  .textAlign(TextAlign.Center)
              }, (item: number) => `card_${item}`)
          }
          .padding(4)
        }
        .scrollable(ScrollDirection.Vertical)
        .scrollBar(BarState.On)
        .edgeEffect(EdgeEffect.Spring)
        .scrollSnap({
          snapAlign: this.snapAlign,
          snapPagination: this.snapPagination,
          enableSnapToStart: true,
          enableSnapToEnd: true
        })
        .width('90%')
        .height(400)
        .borderRadius(8)
        .backgroundColor('#F0F0F0')

        // 对齐方式
        Text('snapAlign 对齐方式')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Row({ space: 8 }) {
          Button('START')
            .fontSize(13)
            .layoutWeight(1)
            .height(36)
            .backgroundColor(this.snapAlign === ScrollSnapAlign.START ? '#007DFF' : '#CCCCCC')
            .onClick(() => {
              this.snapAlign = ScrollSnapAlign.START
              this.updateResult()
            })
          Button('CENTER')
            .fontSize(13)
            .layoutWeight(1)
            .height(36)
            .backgroundColor(this.snapAlign === ScrollSnapAlign.CENTER ? '#007DFF' : '#CCCCCC')
            .onClick(() => {
              this.snapAlign = ScrollSnapAlign.CENTER
              this.updateResult()
            })
          Button('END')
            .fontSize(13)
            .layoutWeight(1)
            .height(36)
            .backgroundColor(this.snapAlign === ScrollSnapAlign.END ? '#007DFF' : '#CCCCCC')
            .onClick(() => {
              this.snapAlign = ScrollSnapAlign.END
              this.updateResult()
            })
        }
        .width('90%')

        // 分页大小
        Text('snapPagination 分页大小（每页高度 vp）')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Row({ space: 8 }) {
          Button('100vp')
            .fontSize(13)
            .layoutWeight(1)
            .height(36)
            .onClick(() => { this.snapPagination = 100; this.updateResult() })
          Button('200vp')
            .fontSize(13)
            .layoutWeight(1)
            .height(36)
            .onClick(() => { this.snapPagination = 200; this.updateResult() })
          Button('300vp')
            .fontSize(13)
            .layoutWeight(1)
            .height(36)
            .onClick(() => { this.snapPagination = 300; this.updateResult() })
        }
        .width('90%')

        // API 说明区
        Column() {
          Text('API 说明')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 8 })
          Text('.scrollSnap(ScrollSnapOptions)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('snapAlign: START | CENTER | END | NONE')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('snapPagination: Dimension(等间距) | Array<Dimension>(自定义分页点)')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('enableSnapToStart/enableSnapToEnd: 首尾自由滑动开关')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('.enablePaging(true) — 翻页模式，与 scrollSnap 同时设置时 scrollSnap 优先')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('元服务：scrollSnap API 11+，enablePaging API 12+')
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
    const alignStr = this.snapAlign === ScrollSnapAlign.START ? 'START' :
      this.snapAlign === ScrollSnapAlign.CENTER ? 'CENTER' :
        this.snapAlign === ScrollSnapAlign.END ? 'END' : 'NONE'
    this.resultText = `对齐: ${alignStr} | 分页大小: ${this.snapPagination}vp`
  }
}
