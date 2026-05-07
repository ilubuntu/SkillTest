/**
 * scroll-event — 滚动事件回调
 * 展示 onScrollFrameBegin、onScrollEdge、onScrollStart、onScrollStop 事件
 * 元服务兼容性：onScrollFrameBegin/onScrollEdge/onScrollStart/onScrollStop 元服务 API 11+
 */
import { BusinessError } from '@kit.BasicServicesKit'

@ComponentV2
export struct ScrollEventDemo {
  @Local resultText: string = '等待滚动事件...'
  @Local eventLog: string = ''
  @Local eventCount: number = 0
  private scroller: Scroller = new Scroller()
  private maxLogs: number = 8

  private buildItems(): number[] {
    const items: number[] = []
    for (let i = 0; i < 25; i++) {
      items.push(i)
    }
    return items
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('滚动事件回调')
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

        // 事件日志区
        Text(`事件日志（累计 ${this.eventCount} 个事件）`)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Scroll() {
          Column() {
            Text(this.eventLog || '暂无事件，请滑动上方区域触发')
              .fontSize(12)
              .fontColor('#555555')
              .fontFamily('monospace')
              .width('100%')
              .padding(8)
          }
        }
        .width('90%')
        .height(120)
        .borderRadius(8)
        .backgroundColor('#FAFAFA')

        // 清除日志按钮
        Row({ space: 8 }) {
          Button('清除日志')
            .fontSize(13)
            .layoutWeight(1)
            .height(36)
            .onClick(() => {
              this.eventLog = ''
              this.eventCount = 0
              this.resultText = '日志已清除'
            })
        }
        .width('90%')

        // 滚动区域（带事件绑定）
        Text('滚动区域（滑动触发事件）')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Scroll(this.scroller) {
          Column({ space: 6 }) {
            ForEach(this.buildItems(),
              (item: number) => {
                Text(`内容 ${item + 1}`)
                  .width('100%')
                  .height(60)
                  .backgroundColor(item % 3 === 0 ? '#E3F2FD' : item % 3 === 1 ? '#FFF3E0' : '#E8F5E9')
                  .borderRadius(6)
                  .fontSize(14)
                  .textAlign(TextAlign.Center)
              }, (item: number) => `item_${item}`)
          }
          .padding(8)
        }
        .scrollable(ScrollDirection.Vertical)
        .scrollBar(BarState.On)
        .edgeEffect(EdgeEffect.Spring)
        .width('90%')
        .height(280)
        .borderRadius(8)
        .backgroundColor('#F0F0F0')
        // 事件绑定
        .onScrollStart(() => {
          this.eventCount++
          this.resultText = 'onScrollStart — 滚动开始'
          this.appendLog(`[${this.eventCount}] onScrollStart 触发`)
        })
        .onScrollStop(() => {
          this.eventCount++
          this.resultText = 'onScrollStop — 滚动停止'
          this.appendLog(`[${this.eventCount}] onScrollStop 触发`)
        })
        .onScrollEdge((side: Edge) => {
          this.eventCount++
          const sideStr = side === Edge.Top ? 'Top' : side === Edge.Bottom ? 'Bottom' :
            side === Edge.Start ? 'Start' : 'End'
          this.resultText = `onScrollEdge — 到达边缘: ${sideStr}`
          this.appendLog(`[${this.eventCount}] onScrollEdge → ${sideStr}`)
        })
        .onScrollFrameBegin((offset: number, state: ScrollState) => {
          if (Math.abs(offset) > 5) {
            this.eventCount++
            const stateStr = state === ScrollState.Idle ? 'Idle' :
              state === ScrollState.Scroll ? 'Scroll' : 'Fling'
            this.appendLog(`[${this.eventCount}] frame offset=${offset.toFixed(1)} state=${stateStr}`)
            this.resultText = `onScrollFrameBegin offset=${offset.toFixed(1)} state=${stateStr}`
          }
          return { offsetRemain: offset }
        })

        // API 说明区
        Column() {
          Text('API 说明')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 8 })
          Text('.onScrollStart(() => {}) — 滚动开始')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('.onScrollStop(() => {}) — 滚动停止')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('.onScrollEdge((side: Edge) => {}) — 到达边缘')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('.onScrollFrameBegin((offset, state) => { offsetRemain })')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('ScrollState: Idle(0) | Scroll(1) | Fling(2)')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('onScrollFrameBegin 返回 { offsetRemain } 控制实际滚动量')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('元服务：以上事件 API 11+ 可用')
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

  private appendLog(log: string): void {
    const logs = this.eventLog ? this.eventLog.split('\n') : []
    logs.push(log)
    if (logs.length > this.maxLogs) {
      logs.splice(0, logs.length - this.maxLogs)
    }
    this.eventLog = logs.join('\n')
  }
}
