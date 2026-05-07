/**
 * scroll-bar — 滚动条样式控制
 * 展示 scrollBar(BarState)、scrollBarColor、scrollBarWidth 和 ScrollBar 组件
 * 元服务兼容性：scrollBar/scrollBarColor/scrollBarWidth 元服务 API 11+，ScrollBar 组件元服务 API 11+
 */
import { BusinessError } from '@kit.BasicServicesKit'

@ComponentV2
export struct ScrollBarDemo {
  @Local barState: BarState = BarState.Auto
  @Local barColor: string = '#66182431'
  @Local barWidth: number = 4
  @Local resultText: string = '滚动条: Auto | 颜色: 默认 | 宽度: 4vp'
  private scroller: Scroller = new Scroller()

  private buildItems(): number[] {
    const items: number[] = []
    for (let i = 0; i < 20; i++) {
      items.push(i)
    }
    return items
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('滚动条样式控制')
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

        // ScrollBar 组件演示（带自定义子节点）
        Text('ScrollBar 组件（自定义滑块）')
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
            .margin({ right: 20 })
            .padding(8)
          }
          .scrollBar(BarState.Off)
          .scrollable(ScrollDirection.Vertical)
          .width('90%')
          .height(280)
          .borderRadius(8)
          .backgroundColor('#F0F0F0')

          ScrollBar({
            scroller: this.scroller,
            direction: ScrollBarDirection.Vertical,
            state: this.barState
          }) {
            Text()
              .width(16)
              .height(80)
              .borderRadius(8)
              .backgroundColor(this.barColor === '#66182431' ? '#C0C0C0' : this.barColor)
          }
          .width(16)
          .height('90%')
          .backgroundColor('#F5F5F5')
          .borderRadius(8)
        }
        .width('100%')

        // 滚动条状态控制
        Text('scrollBar 状态（BarState）')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Row({ space: 8 }) {
          Button('Off 隐藏')
            .fontSize(13)
            .layoutWeight(1)
            .height(36)
            .backgroundColor(this.barState === BarState.Off ? '#007DFF' : '#CCCCCC')
            .onClick(() => {
              this.barState = BarState.Off
              this.updateResult()
            })
          Button('Auto 自动')
            .fontSize(13)
            .layoutWeight(1)
            .height(36)
            .backgroundColor(this.barState === BarState.Auto ? '#007DFF' : '#CCCCCC')
            .onClick(() => {
              this.barState = BarState.Auto
              this.updateResult()
            })
          Button('On 常驻')
            .fontSize(13)
            .layoutWeight(1)
            .height(36)
            .backgroundColor(this.barState === BarState.On ? '#007DFF' : '#CCCCCC')
            .onClick(() => {
              this.barState = BarState.On
              this.updateResult()
            })
        }
        .width('90%')

        // 滚动条颜色
        Text('scrollBarColor')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Row({ space: 8 }) {
          Button('默认')
            .fontSize(13)
            .layoutWeight(1)
            .height(36)
            .onClick(() => { this.barColor = '#66182431'; this.updateResult() })
          Button('红色')
            .fontSize(13)
            .layoutWeight(1)
            .height(36)
            .onClick(() => { this.barColor = '#FF0000'; this.updateResult() })
          Button('蓝色')
            .fontSize(13)
            .layoutWeight(1)
            .height(36)
            .onClick(() => { this.barColor = '#0000FF'; this.updateResult() })
          Button('绿色')
            .fontSize(13)
            .layoutWeight(1)
            .height(36)
            .onClick(() => { this.barColor = '#00AA00'; this.updateResult() })
        }
        .width('90%')

        // 滚动条宽度
        Text('scrollBarWidth')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Row({ space: 8 }) {
          Button('2vp')
            .fontSize(13)
            .layoutWeight(1)
            .height(36)
            .onClick(() => { this.barWidth = 2; this.updateResult() })
          Button('4vp')
            .fontSize(13)
            .layoutWeight(1)
            .height(36)
            .onClick(() => { this.barWidth = 4; this.updateResult() })
          Button('8vp')
            .fontSize(13)
            .layoutWeight(1)
            .height(36)
            .onClick(() => { this.barWidth = 8; this.updateResult() })
          Button('16vp')
            .fontSize(13)
            .layoutWeight(1)
            .height(36)
            .onClick(() => { this.barWidth = 16; this.updateResult() })
        }
        .width('90%')

        // API 说明区
        Column() {
          Text('API 说明')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 8 })
          Text('.scrollBar(barState: BarState)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('.scrollBarColor(color: Color | number | string)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('.scrollBarWidth(value: number | string)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('ScrollBar({ scroller, direction, state }) — 独立滚动条组件')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('ScrollBarDirection: Vertical(0) | Horizontal(1)')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('BarState: Off(隐藏) / Auto(自动) / On(常驻)')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('元服务：scrollBar/scrollBarColor/scrollBarWidth API 11+，ScrollBar 组件 API 11+')
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
    const stateStr = this.barState === BarState.Off ? 'Off' :
      this.barState === BarState.Auto ? 'Auto' : 'On'
    const colorStr = this.barColor === '#66182431' ? '默认' : this.barColor
    this.resultText = `滚动条: ${stateStr} | 颜色: ${colorStr} | 宽度: ${this.barWidth}vp`
  }
}
