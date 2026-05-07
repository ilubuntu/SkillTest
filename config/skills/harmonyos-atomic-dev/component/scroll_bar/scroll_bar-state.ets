/**
 * scroll_bar-state — ScrollBar 状态切换
 * 展示 BarState.Off / Auto / On 三种状态动态切换
 * 元服务兼容性：ScrollBar 组件 + BarState API 11+
 */
import { BusinessError } from '@kit.BasicServicesKit'

@ComponentV2
export struct ScrollBarState {
  @Local barState: BarState = BarState.Auto
  @Local resultText: string = '当前状态: Auto（自动显示/隐藏）'
  @Local eventLog: string = '点击按钮切换滚动条状态'
  private scroller: Scroller = new Scroller()

  private buildItems(): number[] {
    const items: number[] = []
    for (let i = 0; i < 25; i++) {
      items.push(i)
    }
    return items
  }

  private updateState(state: BarState): void {
    try {
      this.barState = state
      const stateStr = state === BarState.Off ? 'Off（隐藏）' :
        state === BarState.Auto ? 'Auto（自动）' : 'On（常驻显示）'
      this.resultText = `当前状态: ${stateStr}`
      this.eventLog = `已切换 BarState 为 ${stateStr}`
    } catch (err) {
      this.eventLog = `错误: ${(err as BusinessError).message}`
    }
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('ScrollBar 状态切换')
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

        // ScrollBar 状态演示
        Text('垂直滚动条 — 状态实时切换')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Stack({ alignContent: Alignment.End }) {
          Scroll(this.scroller) {
            Column({ space: 6 }) {
              ForEach(this.buildItems(),
                (item: number) => {
                  Text(`第 ${item + 1} 项`)
                    .width('100%')
                    .height(48)
                    .backgroundColor(item % 3 === 0 ? '#E8F5E9' :
                      item % 3 === 1 ? '#F3E5F5' : '#FFF8E1')
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
          .height(250)
          .borderRadius(8)
          .backgroundColor('#F5F5F5')

          ScrollBar({
            scroller: this.scroller,
            direction: ScrollBarDirection.Vertical,
            state: this.barState
          }) {
            Text()
              .width(14)
              .height(60)
              .borderRadius(7)
              .backgroundColor('#5C6BC0')
          }
          .width(14)
          .backgroundColor('#E8EAF6')
          .borderRadius(7)
        }
        .width('100%')

        // BarState 切换按钮
        Text('BarState 切换')
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
            .fontColor(this.barState === BarState.Off ? '#FFFFFF' : '#333333')
            .onClick(() => this.updateState(BarState.Off))
          Button('Auto 自动')
            .fontSize(13)
            .layoutWeight(1)
            .height(36)
            .backgroundColor(this.barState === BarState.Auto ? '#007DFF' : '#CCCCCC')
            .fontColor(this.barState === BarState.Auto ? '#FFFFFF' : '#333333')
            .onClick(() => this.updateState(BarState.Auto))
          Button('On 常驻')
            .fontSize(13)
            .layoutWeight(1)
            .height(36)
            .backgroundColor(this.barState === BarState.On ? '#007DFF' : '#CCCCCC')
            .fontColor(this.barState === BarState.On ? '#FFFFFF' : '#333333')
            .onClick(() => this.updateState(BarState.On))
        }
        .width('90%')

        // API 说明区
        Column() {
          Text('API 说明')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 8 })
          Text('BarState.Off — 滚动条始终隐藏')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('BarState.Auto — 滚动时显示，停止后自动隐藏')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('BarState.On — 滚动条始终显示')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('注意: ScrollBar 内部通过 opacity 控制显隐，设置 opacity 属性不生效')
            .fontSize(12)
            .fontColor('#FF6B00')
            .width('100%')
          Text('元服务兼容: BarState API 11+')
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
