/**
 * scroll-nested — 嵌套滚动
 * 展示 Scroll 嵌套 List 的滚动联动：nestedScroll 属性方式
 * 元服务兼容性：nestedScroll 元服务 API 11+ 可用
 */
import { BusinessError } from '@kit.BasicServicesKit'

@ComponentV2
export struct ScrollNested {
  @Local resultText: string = '嵌套滚动联动演示（上下滑动试试）'
  @Local listItems: number[] = []
  @Local scrollOffset: string = ''

  private outerScroller: Scroller = new Scroller()
  private listScroller: Scroller = new Scroller()

  aboutToAppear(): void {
    for (let i = 0; i < 20; i++) {
      this.listItems.push(i)
    }
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('嵌套滚动联动')
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
          Text(this.scrollOffset)
            .fontSize(12)
            .fontColor('#888888')
            .width('100%')
            .padding({ left: 12, bottom: 12 })
        }
        .width('90%')
        .backgroundColor('#F5F5F5')
        .borderRadius(8)

        // 嵌套滚动演示区
        Text('外层 Scroll + 内层 List（nestedScroll 方式）')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Scroll(this.outerScroller) {
          Column() {
            // 顶部区域
            Text('Scroll 顶部区域（高度 40%）')
              .width('100%')
              .height(160)
              .backgroundColor('#0080DC')
              .fontColor('#FFFFFF')
              .fontSize(16)
              .textAlign(TextAlign.Center)
              .borderRadius({ topLeft: 12, topRight: 12 })

            // 内层 List
            List({ space: 8, scroller: this.listScroller }) {
              ForEach(this.listItems,
                (item: number) => {
                  ListItem() {
                    Text(`List Item ${item + 1}`)
                      .width('100%')
                      .height(60)
                      .backgroundColor(Color.White)
                      .borderRadius(8)
                      .fontSize(15)
                      .textAlign(TextAlign.Center)
                  }
                }, (item: number) => `list_${item}`)
            }
            .width('100%')
            .height(300)
            .scrollBar(BarState.Off)
            .edgeEffect(EdgeEffect.Spring)
            .nestedScroll({
              scrollForward: NestedScrollMode.PARENT_FIRST,
              scrollBackward: NestedScrollMode.SELF_FIRST
            })

            // 底部区域
            Text('Scroll 底部区域')
              .width('100%')
              .height(100)
              .backgroundColor('#FF9800')
              .fontColor('#FFFFFF')
              .fontSize(16)
              .textAlign(TextAlign.Center)
              .borderRadius({ bottomLeft: 12, bottomRight: 12 })
          }
        }
        .edgeEffect(EdgeEffect.Spring)
        .scrollBar(BarState.Off)
        .width('90%')
        .height(460)
        .borderRadius(12)
        .backgroundColor('#DCDCDC')

        // 滚动模式说明
        Text('nestedScroll 模式说明')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Column() {
          Text('scrollForward: PARENT_FIRST')
            .fontSize(13)
            .fontColor('#333333')
            .width('100%')
          Text('→ 向下滚动时，先滚外层 Scroll，外层到底后再滚内层 List')
            .fontSize(12)
            .fontColor('#666666')
            .margin({ top: 4, bottom: 8 })
            .width('100%')
          Text('scrollBackward: SELF_FIRST')
            .fontSize(13)
            .fontColor('#333333')
            .width('100%')
          Text('→ 向上滚动时，先滚内层 List，内层到顶后再滚外层 Scroll')
            .fontSize(12)
            .fontColor('#666666')
            .margin({ top: 4 })
            .width('100%')
        }
        .width('90%')
        .backgroundColor('#E8F5E9')
        .borderRadius(8)
        .padding(12)

        // API 说明区
        Column() {
          Text('API 说明')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 8 })
          Text('.nestedScroll(NestedScrollOptions)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('scrollForward: SELF_ONLY / SELF_FIRST / PARENT_FIRST / PARALLEL')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('scrollBackward: SELF_ONLY / SELF_FIRST / PARENT_FIRST / PARALLEL')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('推荐: scrollForward=PARENT_FIRST, scrollBackward=SELF_FIRST')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('元服务：nestedScroll API 11+ 可用')
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
