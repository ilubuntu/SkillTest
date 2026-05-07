/**
 * refresh-pull-ratio — 下拉跟手系数控制
 * 展示 pullDownRatio 属性控制下拉跟手灵敏度、pullToRefresh 开关、refreshOffset 偏移量
 * 元服务兼容性：API 12+ 可用
 */
import { BusinessError } from '@kit.BasicServicesKit'

@ComponentV2
export struct RefreshPullRatio {
  @Local isRefreshing: boolean = false
  @Local resultText: string = '等待操作...'
  @Local stateText: string = '状态: Inactive'
  @Local currentRatio: number = 0.5
  @Local pullToRefreshEnabled: boolean = true
  @Local currentOffset: number = 64
  private items: string[] = []

  aboutToAppear(): void {
    for (let i = 0; i < 8; i++) {
      this.items.push(`项目 ${i + 1}`)
    }
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('下拉跟手系数控制')
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
          Text(this.stateText)
            .fontSize(13)
            .fontColor('#666666')
            .width('100%')
            .padding({ left: 12, bottom: 12 })
        }
        .width('90%')
        .backgroundColor('#F5F5F5')
        .borderRadius(8)

        // pullDownRatio 控制
        Text(`下拉跟手系数: ${this.currentRatio.toFixed(2)}`)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Slider({
          value: this.currentRatio,
          min: 0,
          max: 1,
          step: 0.1,
          style: SliderStyle.OutSet
        })
          .width('90%')
          .onChange((value: number) => {
            try {
              this.currentRatio = value
              this.resultText = `pullDownRatio = ${value.toFixed(2)} (0=不跟手, 1=等比跟手)`
            } catch (error) {
              this.resultText = `错误: ${(error as BusinessError).message}`
            }
          })

        // pullToRefresh 开关
        Row({ space: 12 }) {
          Text('pullToRefresh:')
            .fontSize(14)
          Toggle({ type: ToggleType.Switch, isOn: this.pullToRefreshEnabled })
            .onChange((isOn: boolean) => {
              try {
                this.pullToRefreshEnabled = isOn
                this.resultText = `pullToRefresh = ${isOn} (${isOn ? '可触发刷新' : '不可触发刷新'})`
              } catch (error) {
                this.resultText = `错误: ${(error as BusinessError).message}`
              }
            })
        }
        .width('90%')

        // refreshOffset 控制
        Text(`触发偏移量: ${this.currentOffset} vp`)
          .fontSize(14)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16 })

        Row({ space: 8 }) {
          Button('64vp')
            .fontSize(13)
            .layoutWeight(1)
            .height(36)
            .onClick(() => {
              this.currentOffset = 64
              this.resultText = 'refreshOffset = 64vp (默认)'
            })
          Button('96vp')
            .fontSize(13)
            .layoutWeight(1)
            .height(36)
            .onClick(() => {
              this.currentOffset = 96
              this.resultText = 'refreshOffset = 96vp'
            })
          Button('128vp')
            .fontSize(13)
            .layoutWeight(1)
            .height(36)
            .onClick(() => {
              this.currentOffset = 128
              this.resultText = 'refreshOffset = 128vp'
            })
        }
        .width('90%')

        // Refresh 区域
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
          .height(250)
          .alignListItem(ListItemAlign.Center)
          .scrollBar(BarState.Off)
        }
        .width('90%')
        .borderRadius(8)
        .backgroundColor('#F3E5F5')
        .pullDownRatio(this.currentRatio)
        .pullToRefresh(this.pullToRefreshEnabled)
        .refreshOffset(this.currentOffset)
        .onStateChange((state: RefreshStatus) => {
          const stateNames: Record<number, string> = {
            0: 'Inactive', 1: 'Drag', 2: 'OverDrag', 3: 'Refresh', 4: 'Done'
          }
          this.stateText = `状态: ${stateNames[state] ?? state.toString()}`
        })
        .onRefreshing(() => {
          this.resultText = '刷新中...'
          setTimeout(() => {
            this.isRefreshing = false
            this.resultText = '刷新完成'
          }, 1500)
        })

        // API 说明区
        Column() {
          Text('API 说明')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 8 })
          Text('pullDownRatio(ratio) — 下拉跟手系数 (0~1)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('pullToRefresh(bool) — 下拉超过 offset 时是否触发刷新')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('refreshOffset(value) — 触发刷新的下拉偏移量 (vp)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('pullDownRatio=0 禁止下拉，undefined 使用动态系数')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('元服务：以上属性均 API 12+ 可用')
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
