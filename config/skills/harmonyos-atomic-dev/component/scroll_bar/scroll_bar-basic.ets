/**
 * scroll_bar-basic — ScrollBar 组件基础用法
 * 展示 ScrollBar 独立组件与 Scroll 配合使用，带自定义子节点滑块
 * 元服务兼容性：ScrollBar 组件 API 11+
 */
import { BusinessError } from '@kit.BasicServicesKit'

@ComponentV2
export struct ScrollBarBasic {
  @Local resultText: string = 'ScrollBar 基础用法 — 垂直滚动条'
  @Local eventLog: string = '滑动列表查看滚动条联动效果'
  @Local scrollOffset: number = 0
  private scroller: Scroller = new Scroller()
  private readonly itemCount: number = 20

  private buildItems(): number[] {
    const items: number[] = []
    for (let i = 0; i < this.itemCount; i++) {
      items.push(i)
    }
    return items
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('ScrollBar 基础用法')
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

        // ScrollBar 与 Scroll 联动演示
        Text('自定义滑块样式（带子节点）')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Stack({ alignContent: Alignment.End }) {
          Scroll(this.scroller) {
            Column({ space: 6 }) {
              ForEach(this.buildItems(),
                (item: number) => {
                  Text(`列表项 ${item + 1}`)
                    .width('100%')
                    .height(50)
                    .backgroundColor(item % 2 === 0 ? '#E3F2FD' : '#FFF3E0')
                    .borderRadius(6)
                    .fontSize(14)
                    .textAlign(TextAlign.Center)
                }, (item: number) => `item_${item}`)
            }
            .margin({ right: 24 })
            .padding(8)
          }
          .scrollBar(BarState.Off)
          .scrollable(ScrollDirection.Vertical)
          .width('90%')
          .height(280)
          .borderRadius(8)
          .backgroundColor('#F0F0F0')
          .onScroll(() => {
            try {
              const offset = this.scroller.currentOffset()
              this.scrollOffset = offset.xOffset + offset.yOffset
              this.eventLog = `滚动偏移: y=${offset.yOffset.toFixed(0)}`
            } catch (err) {
              this.eventLog = `错误: ${(err as BusinessError).message}`
            }
          })

          // ScrollBar 组件（带自定义子节点）
          ScrollBar({
            scroller: this.scroller,
            direction: ScrollBarDirection.Vertical,
            state: BarState.Auto
          }) {
            Text()
              .width(16)
              .height(80)
              .borderRadius(8)
              .backgroundColor('#C0C0C0')
          }
          .width(16)
          .backgroundColor('#EDEDED')
          .borderRadius(8)
        }
        .width('100%')

        // 滚动控制按钮
        Text('Scroller 控制')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Row({ space: 8 }) {
          Button('滚动到顶部')
            .fontSize(13)
            .layoutWeight(1)
            .height(36)
            .onClick(() => {
              try {
                this.scroller.scrollToIndex(0)
                this.eventLog = '已滚动到顶部'
              } catch (err) {
                this.eventLog = `错误: ${(err as BusinessError).message}`
              }
            })
          Button('滚动到底部')
            .fontSize(13)
            .layoutWeight(1)
            .height(36)
            .onClick(() => {
              try {
                this.scroller.scrollEdge(Edge.Bottom)
                this.eventLog = '已滚动到底部'
              } catch (err) {
                this.eventLog = `错误: ${(err as BusinessError).message}`
              }
            })
          Button('下一页')
            .fontSize(13)
            .layoutWeight(1)
            .height(36)
            .onClick(() => {
              try {
                this.scroller.scrollPage({ next: true })
                this.eventLog = '已翻到下一页'
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
          Text('ScrollBar({ scroller, direction, state })')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('scroller: Scroller — 与可滚动组件绑定的控制器')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('direction: ScrollBarDirection — Vertical(0) | Horizontal(1)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('state: BarState — Off(隐藏) | Auto(自动) | On(常驻)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('子节点: 自定义滑块外观（宽/高/颜色/圆角）')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('注意: ScrollBar 主轴不设大小时，使用父组件 maxSize')
            .fontSize(12)
            .fontColor('#FF6B00')
            .width('100%')
          Text('元服务兼容: API 11+ 全部可用')
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
