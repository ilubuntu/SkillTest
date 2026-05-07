/**
 * refresh-state-tracking — 状态追踪与偏移量变化
 * 展示 onOffsetChange 实时追踪下拉距离、动态 pullDownRatio、状态机完整流程
 * 元服务兼容性：onStateChange/onRefreshing API 11+，onOffsetChange API 12+
 */
import { BusinessError } from '@kit.BasicServicesKit'

@ComponentV2
export struct RefreshStateTracking {
  @Local isRefreshing: boolean = false
  @Local resultText: string = '等待操作...'
  @Local offsetValue: number = 0
  @Local currentState: string = 'Inactive'
  @Local ratio: number = 1
  @Local maxPullDistance: number = 120
  @Local logEntries: string[] = []
  private items: string[] = []

  aboutToAppear(): void {
    for (let i = 0; i < 6; i++) {
      this.items.push(`卡片 ${i + 1}`)
    }
  }

  private addLog(msg: string): void {
    const time = new Date().toLocaleTimeString()
    this.logEntries = [`[${time}] ${msg}`, ...this.logEntries].slice(0, 20)
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('状态追踪与偏移量')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20, bottom: 10 })

        // 实时状态
        Column() {
          Text(this.resultText)
            .fontSize(14)
            .fontColor('#333333')
            .width('100%')
            .padding(12)
          Row() {
            Text(`状态: ${this.currentState}`)
              .fontSize(13)
              .fontColor('#666666')
              .layoutWeight(1)
            Text(`偏移: ${this.offsetValue.toFixed(1)} vp`)
              .fontSize(13)
              .fontColor('#666666')
              .layoutWeight(1)
          }
          .width('100%')
          .padding({ left: 12, right: 12, bottom: 12 })
          Row() {
            Text(`动态ratio: ${this.ratio.toFixed(3)}`)
              .fontSize(13)
              .fontColor('#666666')
              .layoutWeight(1)
            Text(`最大距离: ${this.maxPullDistance} vp`)
              .fontSize(13)
              .fontColor('#666666')
              .layoutWeight(1)
          }
          .width('100%')
          .padding({ left: 12, right: 12, bottom: 12 })
        }
        .width('90%')
        .backgroundColor('#F5F5F5')
        .borderRadius(8)

        // Refresh 区域（使用动态 pullDownRatio 实现最大下拉距离）
        Refresh({ refreshing: $$this.isRefreshing }) {
          List() {
            ForEach(this.items, (item: string) => {
              ListItem() {
                Text(item)
                  .width('100%')
                  .height(56)
                  .fontSize(15)
                  .textAlign(TextAlign.Center)
                  .fontColor('#333333')
                  .backgroundColor(Color.White)
                  .borderRadius(8)
              }
              .margin({ top: 3, bottom: 3 })
            }, (item: string) => item)
          }
          .width('100%')
          .height(240)
          .alignListItem(ListItemAlign.Center)
          .scrollBar(BarState.Off)
        }
        .width('90%')
        .borderRadius(8)
        .backgroundColor('#E0F7FA')
        .pullDownRatio(this.ratio)
        .pullToRefresh(true)
        .refreshOffset(64)
        .onOffsetChange((value: number) => {
          this.offsetValue = value
          // 动态跟手系数：越接近最大距离，跟手越弱
          this.ratio = 1 - Math.pow(value / this.maxPullDistance, 3)
        })
        .onStateChange((state: RefreshStatus) => {
          const stateMap: Record<number, string> = {
            0: 'Inactive', 1: 'Drag', 2: 'OverDrag', 3: 'Refresh', 4: 'Done'
          }
          this.currentState = stateMap[state] ?? state.toString()
          this.addLog(`状态变更 → ${this.currentState}`)
          this.resultText = `状态: ${this.currentState} | 偏移: ${this.offsetValue.toFixed(1)}vp`
        })
        .onRefreshing(() => {
          this.addLog('进入刷新状态')
          this.resultText = '正在刷新...'
          setTimeout(() => {
            this.isRefreshing = false
            this.addLog('刷新完成')
            this.resultText = '刷新完成'
          }, 2000)
        })

        // 日志区
        Text('状态变更日志')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Column() {
          ForEach(this.logEntries, (entry: string) => {
            Text(entry)
              .fontSize(11)
              .fontColor('#555555')
              .fontFamily('monospace')
              .width('100%')
              .padding(2)
          }, (entry: string, index: number) => `log_${index}`)
        }
        .width('90%')
        .constraintSize({ maxHeight: 120 })
        .backgroundColor('#FAFAFA')
        .borderRadius(8)
        .padding(8)

        // API 说明区
        Column() {
          Text('API 说明')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 8 })
          Text('onOffsetChange((value: number) => {}) — 实时下拉距离 (vp)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('动态 pullDownRatio = 1 - (offset/maxDist)^3 实现最大距离')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('状态流转: Inactive → Drag → OverDrag → Refresh → Done')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('元服务：onStateChange/onRefreshing API 11+, onOffsetChange API 12+')
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
