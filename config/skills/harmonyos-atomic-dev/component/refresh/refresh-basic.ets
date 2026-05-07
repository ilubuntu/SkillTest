/**
 * refresh-basic — 基础下拉刷新
 * 展示 Refresh 组件默认样式、refreshing 双向绑定、onStateChange、onRefreshing
 * 元服务兼容性：API 11+ 可用
 */
import { BusinessError } from '@kit.BasicServicesKit'

@ComponentV2
export struct RefreshBasic {
  @Local isRefreshing: boolean = false
  @Local resultText: string = '等待操作...'
  @Local stateText: string = '状态: Inactive'
  @Local refreshCount: number = 0
  private items: string[] = []

  aboutToAppear(): void {
    for (let i = 0; i < 10; i++) {
      this.items.push(`列表项 ${i + 1}`)
    }
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('基础下拉刷新')
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
          Text(`已刷新次数: ${this.refreshCount}`)
            .fontSize(13)
            .fontColor('#666666')
            .width('100%')
            .padding({ left: 12, bottom: 12 })
        }
        .width('90%')
        .backgroundColor('#F5F5F5')
        .borderRadius(8)

        // 控制按钮
        Text('手动控制')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Row({ space: 8 }) {
          Button('开始刷新')
            .fontSize(13)
            .layoutWeight(1)
            .height(36)
            .onClick(() => {
              try {
                this.isRefreshing = true
                this.resultText = '手动触发刷新中...'
              } catch (error) {
                this.resultText = `错误: ${(error as BusinessError).message}`
              }
            })
          Button('停止刷新')
            .fontSize(13)
            .layoutWeight(1)
            .height(36)
            .onClick(() => {
              try {
                this.isRefreshing = false
                this.resultText = '手动停止刷新'
              } catch (error) {
                this.resultText = `错误: ${(error as BusinessError).message}`
              }
            })
        }
        .width('90%')

        // Refresh 列表区域
        Text('下拉刷新列表（向下拖拽触发）')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Refresh({ refreshing: $$this.isRefreshing }) {
          List() {
            ForEach(this.items, (item: string) => {
              ListItem() {
                Text(item)
                  .width('100%')
                  .height(60)
                  .fontSize(15)
                  .textAlign(TextAlign.Center)
                  .fontColor('#333333')
                  .backgroundColor(Color.White)
                  .borderRadius(8)
              }
              .margin({ top: 4, bottom: 4 })
            }, (item: string) => item)
          }
          .width('100%')
          .height(300)
          .alignListItem(ListItemAlign.Center)
          .scrollBar(BarState.Off)
        }
        .width('90%')
        .borderRadius(8)
        .backgroundColor('#E3F2FD')
        .onStateChange((state: RefreshStatus) => {
          const stateNames: Record<number, string> = {
            0: 'Inactive',
            1: 'Drag',
            2: 'OverDrag',
            3: 'Refresh',
            4: 'Done'
          }
          this.stateText = `状态: ${stateNames[state] ?? state.toString()}`
          this.resultText = `状态变更 → ${stateNames[state] ?? state.toString()}`
        })
        .onRefreshing(() => {
          this.resultText = '正在刷新，2秒后自动完成...'
          this.refreshCount++
          setTimeout(() => {
            this.isRefreshing = false
            this.resultText = `刷新完成 (第 ${this.refreshCount} 次)`
          }, 2000)
        })

        // API 说明区
        Column() {
          Text('API 说明')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 8 })
          Text('Refresh({ refreshing: $$isRefreshing }) — 创建刷新容器')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('refreshing — 双向绑定刷新状态 (true/false)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('onStateChange(state: RefreshStatus) — 状态变更回调')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('onRefreshing(() => {}) — 进入刷新状态回调')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('RefreshStatus: Inactive=0, Drag=1, OverDrag=2, Refresh=3, Done=4')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('元服务：API 11+ 可用，使用 $$ 双向绑定 refreshing')
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
