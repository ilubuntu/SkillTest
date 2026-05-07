/**
 * refresh-prompt-text — 刷新区域文本提示
 * 展示 promptText 参数设置刷新区域底部自定义文本
 * 元服务兼容性：API 12+ 可用
 */
import { BusinessError } from '@kit.BasicServicesKit'

@ComponentV2
export struct RefreshPromptText {
  @Local isRefreshing: boolean = false
  @Local resultText: string = '等待操作...'
  @Local stateText: string = '状态: Inactive'
  @Local currentPromptText: string = '下拉即可刷新'
  @Local selectedPromptIndex: number = 0
  private items: string[] = []
  private promptOptions: string[] = [
    '下拉即可刷新',
    '松手立即刷新',
    '正在更新数据...',
    'Last updated: just now'
  ]

  aboutToAppear(): void {
    for (let i = 0; i < 6; i++) {
      this.items.push(`内容 ${i + 1}`)
    }
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('刷新区域文本提示')
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
          Text(`当前文本: "${this.currentPromptText}"`)
            .fontSize(13)
            .fontColor('#666666')
            .width('100%')
            .padding({ left: 12, bottom: 12 })
        }
        .width('90%')
        .backgroundColor('#F5F5F5')
        .borderRadius(8)

        // 文本选择控制
        Text('提示文本选择')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Row({ space: 8 }) {
          ForEach(this.promptOptions, (option: string, index: number) => {
            Button(option)
              .fontSize(11)
              .layoutWeight(1)
              .height(36)
              .backgroundColor(index === this.selectedPromptIndex ? '#4CAF50' : '#E0E0E0')
              .fontColor(index === this.selectedPromptIndex ? Color.White : '#333333')
              .onClick(() => {
                try {
                  this.selectedPromptIndex = index as number
                  this.currentPromptText = option
                  this.resultText = `切换提示文本: "${option}"`
                } catch (error) {
                  this.resultText = `错误: ${(error as BusinessError).message}`
                }
              })
          }, (option: string, index: number) => `prompt_${index}`)
        }
        .width('90%')

        // Refresh 区域
        Text('下拉查看文本效果（需 API 12+）')
          .fontSize(13)
          .fontColor('#999999')
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16 })

        Refresh({ refreshing: $$this.isRefreshing, promptText: this.currentPromptText }) {
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
              .margin({ top: 3, bottom: 3 })
            }, (item: string) => item)
          }
          .width('100%')
          .height(260)
          .alignListItem(ListItemAlign.Center)
          .scrollBar(BarState.Off)
        }
        .width('90%')
        .borderRadius(8)
        .backgroundColor('#E8F5E9')
        .pullToRefresh(true)
        .refreshOffset(96)
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
          Text('promptText: ResourceStr — 刷新区域底部自定义文本')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('使用 builder/refreshingContent 时 promptText 不显示')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('设置 promptText 后 refreshOffset 默认值变为 96vp')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('元服务：API 12+ 可用')
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
