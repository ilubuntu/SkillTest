/**
 * scroll-direction — 滚动方向控制
 * 展示 ScrollDirection.Vertical / Horizontal / None 三种方向
 * 元服务兼容性：Vertical/Horizontal/None 元服务 API 11+ 可用，Free 需 API 20+
 */
import { BusinessError } from '@kit.BasicServicesKit'

@ComponentV2
export struct ScrollDirectionDemo {
  @Local scrollDir: ScrollDirection = ScrollDirection.Vertical
  @Local resultText: string = '当前方向: Vertical（纵向）'
  private vScroller: Scroller = new Scroller()
  private hScroller: Scroller = new Scroller()

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
        Text('滚动方向控制')
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

        // 方向切换按钮
        Text('滚动方向选择')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Row({ space: 8 }) {
          Button('Vertical')
            .fontSize(13)
            .layoutWeight(1)
            .height(36)
            .backgroundColor(this.scrollDir === ScrollDirection.Vertical ? '#007DFF' : '#CCCCCC')
            .onClick(() => {
              this.scrollDir = ScrollDirection.Vertical
              this.resultText = '当前方向: Vertical（纵向滚动）'
            })
          Button('Horizontal')
            .fontSize(13)
            .layoutWeight(1)
            .height(36)
            .backgroundColor(this.scrollDir === ScrollDirection.Horizontal ? '#007DFF' : '#CCCCCC')
            .onClick(() => {
              this.scrollDir = ScrollDirection.Horizontal
              this.resultText = '当前方向: Horizontal（横向滚动）'
            })
          Button('None')
            .fontSize(13)
            .layoutWeight(1)
            .height(36)
            .backgroundColor(this.scrollDir === ScrollDirection.None ? '#007DFF' : '#CCCCCC')
            .onClick(() => {
              this.scrollDir = ScrollDirection.None
              this.resultText = '当前方向: None（禁止滚动）'
            })
        }
        .width('90%')

        // 垂直滚动演示
        if (this.scrollDir === ScrollDirection.Vertical) {
          Text('纵向滚动内容')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .alignSelf(ItemAlign.Start)
            .margin({ left: 16, top: 8 })

          Scroll(this.vScroller) {
            Column({ space: 8 }) {
              ForEach(this.buildItems(),
                (item: number) => {
                  Text(`纵向项 ${item + 1}`)
                    .width('100%')
                    .height(60)
                    .backgroundColor(item % 2 === 0 ? '#E3F2FD' : '#FFF3E0')
                    .borderRadius(8)
                    .fontSize(14)
                    .textAlign(TextAlign.Center)
                }, (item: number) => `v_${item}`)
            }
            .padding(8)
          }
          .scrollable(ScrollDirection.Vertical)
          .scrollBar(BarState.Auto)
          .edgeEffect(EdgeEffect.Spring)
          .width('90%')
          .height(250)
          .borderRadius(8)
          .backgroundColor('#F0F0F0')
        }

        // 水平滚动演示
        if (this.scrollDir === ScrollDirection.Horizontal) {
          Text('横向滚动内容')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .alignSelf(ItemAlign.Start)
            .margin({ left: 16, top: 8 })

          Scroll(this.hScroller) {
            Row({ space: 8 }) {
              ForEach(this.buildItems(),
                (item: number) => {
                  Text(`横${item + 1}`)
                    .width(120)
                    .height(180)
                    .backgroundColor(item % 3 === 0 ? '#E3F2FD' : item % 3 === 1 ? '#FFF3E0' : '#E8F5E9')
                    .borderRadius(8)
                    .fontSize(14)
                    .textAlign(TextAlign.Center)
                }, (item: number) => `h_${item}`)
            }
            .padding(8)
          }
          .scrollable(ScrollDirection.Horizontal)
          .scrollBar(BarState.Auto)
          .edgeEffect(EdgeEffect.Spring)
          .width('90%')
          .height(220)
          .borderRadius(8)
          .backgroundColor('#F0F0F0')
        }

        // None 禁止滚动提示
        if (this.scrollDir === ScrollDirection.None) {
          Scroll(new Scroller()) {
            Column({ space: 8 }) {
              ForEach(this.buildItems(),
                (item: number) => {
                  Text(`不可滚动项 ${item + 1}`)
                    .width('100%')
                    .height(60)
                    .backgroundColor('#F5F5F5')
                    .borderRadius(8)
                    .fontSize(14)
                    .textAlign(TextAlign.Center)
                }, (item: number) => `n_${item}`)
            }
            .padding(8)
          }
          .scrollable(ScrollDirection.None)
          .width('90%')
          .height(200)
          .borderRadius(8)
          .backgroundColor('#F0F0F0')
        }

        // Free 方向不支持提示
        Column() {
          Text('ScrollDirection.FREE（自由滚动）在元服务中不可用')
            .fontSize(13)
            .fontColor('#FF6B00')
            .fontWeight(FontWeight.Medium)
            .width('100%')
          Text('FREE 自由滚动需 API 20+，元服务 API 20+ 才可用。如需双向滚动，可考虑嵌套 Scroll 组件实现。')
            .fontSize(12)
            .fontColor('#996600')
            .margin({ top: 4 })
            .width('100%')
        }
        .width('90%')
        .backgroundColor('#FFF3CD')
        .borderRadius(8)
        .padding(12)

        // API 说明区
        Column() {
          Text('API 说明')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 8 })
          Text('.scrollable(ScrollDirection)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('Vertical(0): 纵向 | Horizontal(1): 横向 | None(3): 禁止')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('FREE(4): 自由滚动 — 元服务 API 20+')
            .fontSize(12)
            .fontColor('#FF6B00')
            .width('100%')
          Text('修改 scrollable 值会重置滚动偏移量')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('元服务：Vertical/Horizontal/None API 11+ 可用')
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
