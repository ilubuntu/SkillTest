/**
 * scroll_bar-direction — ScrollBar 方向控制
 * 展示 Vertical / Horizontal 两种方向的 ScrollBar
 * 元服务兼容性：ScrollBarDirection API 11+
 */
import { BusinessError } from '@kit.BasicServicesKit'

@ComponentV2
export struct ScrollBarDirectionCtrl {
  @Local resultText: string = '垂直滚动条 + 水平滚动条'
  @Local eventLog: string = '分别演示垂直和水平方向的 ScrollBar'
  private vScroller: Scroller = new Scroller()
  private hScroller: Scroller = new Scroller()

  private buildItems(count: number): number[] {
    const items: number[] = []
    for (let i = 0; i < count; i++) {
      items.push(i)
    }
    return items
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('ScrollBar 方向控制')
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

        // 事件日志
        Column() {
          Text(this.eventLog)
            .fontSize(12)
            .fontColor('#666666')
            .width('100%')
            .padding(12)
        }
        .width('90%')
        .backgroundColor('#F0F0F0')
        .borderRadius(8)

        // 垂直 ScrollBar
        Text('垂直方向 (Vertical)')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Stack({ alignContent: Alignment.End }) {
          Scroll(this.vScroller) {
            Column({ space: 6 }) {
              ForEach(this.buildItems(15),
                (item: number) => {
                  Text(`垂直项 ${item + 1}`)
                    .width('100%')
                    .height(44)
                    .backgroundColor('#E1F5FE')
                    .borderRadius(6)
                    .fontSize(14)
                    .textAlign(TextAlign.Center)
                }, (item: number) => `v_${item}`)
            }
            .margin({ right: 20 })
            .padding(8)
          }
          .scrollBar(BarState.Off)
          .scrollable(ScrollDirection.Vertical)
          .width('90%')
          .height(200)
          .borderRadius(8)
          .backgroundColor('#F5F5F5')

          ScrollBar({
            scroller: this.vScroller,
            direction: ScrollBarDirection.Vertical,
            state: BarState.On
          }) {
            Text()
              .width(12)
              .height(50)
              .borderRadius(6)
              .backgroundColor('#42A5F5')
          }
          .width(12)
          .backgroundColor('#E3F2FD')
          .borderRadius(6)
        }
        .width('100%')

        // 水平 ScrollBar
        Text('水平方向 (Horizontal)')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Column() {
          Scroll(this.hScroller) {
            Row({ space: 8 }) {
              ForEach(this.buildItems(15),
                (item: number) => {
                  Text(`横${item + 1}`)
                    .width(80)
                    .height(80)
                    .backgroundColor('#FCE4EC')
                    .borderRadius(8)
                    .fontSize(13)
                    .textAlign(TextAlign.Center)
                }, (item: number) => `h_${item}`)
            }
            .padding(8)
          }
          .scrollBar(BarState.Off)
          .scrollable(ScrollDirection.Horizontal)
          .width('90%')
          .height(96)
          .borderRadius(8)
          .backgroundColor('#F5F5F5')

          ScrollBar({
            scroller: this.hScroller,
            direction: ScrollBarDirection.Horizontal,
            state: BarState.On
          }) {
            Text()
              .width(60)
              .height(8)
              .borderRadius(4)
              .backgroundColor('#EC407A')
          }
          .height(8)
          .width('90%')
          .backgroundColor('#FCE4EC')
          .borderRadius(4)
          .margin({ top: 4 })
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)

        // 控制按钮
        Row({ space: 8 }) {
          Button('V→顶部')
            .fontSize(13)
            .layoutWeight(1)
            .height(36)
            .onClick(() => {
              try {
                this.vScroller.scrollToIndex(0)
                this.eventLog = '垂直滚动条 → 顶部'
              } catch (err) {
                this.eventLog = `错误: ${(err as BusinessError).message}`
              }
            })
          Button('V→底部')
            .fontSize(13)
            .layoutWeight(1)
            .height(36)
            .onClick(() => {
              try {
                this.vScroller.scrollEdge(Edge.Bottom)
                this.eventLog = '垂直滚动条 → 底部'
              } catch (err) {
                this.eventLog = `错误: ${(err as BusinessError).message}`
              }
            })
          Button('H→左侧')
            .fontSize(13)
            .layoutWeight(1)
            .height(36)
            .onClick(() => {
              try {
                this.hScroller.scrollToIndex(0)
                this.eventLog = '水平滚动条 → 左侧'
              } catch (err) {
                this.eventLog = `错误: ${(err as BusinessError).message}`
              }
            })
          Button('H→右侧')
            .fontSize(13)
            .layoutWeight(1)
            .height(36)
            .onClick(() => {
              try {
                this.hScroller.scrollEdge(Edge.End)
                this.eventLog = '水平滚动条 → 右侧'
              } catch (err) {
                this.eventLog = `错误: ${(err as BusinessError).message}`
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
          Text('ScrollBarDirection.Vertical(0) — 纵向滚动条')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('ScrollBarDirection.Horizontal(1) — 横向滚动条')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('注意: ScrollBar 与可滚动组件方向必须一致才能联动')
            .fontSize(12)
            .fontColor('#FF6B00')
            .width('100%')
          Text('注意: ScrollBar 主轴方向建议设置明确大小')
            .fontSize(12)
            .fontColor('#FF6B00')
            .width('100%')
          Text('元服务兼容: API 11+')
            .fontSize(12)
            .fontColor('#4CAF50')
            .width('100%')
            .margin({ top: 4 })
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
