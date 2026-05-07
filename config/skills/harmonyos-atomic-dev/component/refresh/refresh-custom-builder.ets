/**
 * refresh-custom-builder — 自定义刷新区域 (builder)
 * 展示通过 builder 参数自定义刷新区域显示内容
 * 元服务兼容性：API 11+ 可用
 */
import { BusinessError } from '@kit.BasicServicesKit'

@ComponentV2
export struct RefreshCustomBuilder {
  @Local isRefreshing: boolean = false
  @Local resultText: string = '等待操作...'
  @Local stateText: string = '状态: Inactive'
  @Local refreshOffset: number = 0
  private items: string[] = []

  aboutToAppear(): void {
    for (let i = 0; i < 8; i++) {
      this.items.push(`数据项 ${i + 1}`)
    }
  }

  @Builder
  customRefreshComponent() {
    Stack() {
      Row() {
        LoadingProgress()
          .width(28)
          .height(28)
          .color('#FF6B35')
        Text(this.isRefreshing ? '正在刷新...' : '下拉刷新')
          .fontSize(14)
          .fontColor('#FF6B35')
          .margin({ left: 12 })
      }
      .alignItems(VerticalAlign.Center)
    }
    .align(Alignment.Center)
    .clip(true)
    .constraintSize({ minHeight: 32 })
    .width('100%')
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('自定义刷新区域 (builder)')
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
          Text(`下拉偏移: ${this.refreshOffset.toFixed(1)} vp`)
            .fontSize(13)
            .fontColor('#666666')
            .width('100%')
            .padding({ left: 12, bottom: 12 })
        }
        .width('90%')
        .backgroundColor('#F5F5F5')
        .borderRadius(8)

        // 手动控制
        Row({ space: 8 }) {
          Button('触发刷新')
            .fontSize(13)
            .layoutWeight(1)
            .height(36)
            .onClick(() => {
              try {
                this.isRefreshing = true
                this.resultText = '手动触发自定义刷新...'
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
                this.resultText = '手动停止'
              } catch (error) {
                this.resultText = `错误: ${(error as BusinessError).message}`
              }
            })
        }
        .width('90%')

        // Refresh 区域
        Refresh({ refreshing: $$this.isRefreshing, builder: this.customRefreshComponent() }) {
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
          .height(280)
          .alignListItem(ListItemAlign.Center)
          .scrollBar(BarState.Off)
        }
        .width('90%')
        .borderRadius(8)
        .backgroundColor('#FFF3E0')
        .onStateChange((state: RefreshStatus) => {
          const stateNames: Record<number, string> = {
            0: 'Inactive', 1: 'Drag', 2: 'OverDrag', 3: 'Refresh', 4: 'Done'
          }
          this.stateText = `状态: ${stateNames[state] ?? state.toString()}`
        })
        .onRefreshing(() => {
          this.resultText = '自定义刷新中...'
          setTimeout(() => {
            this.isRefreshing = false
            this.resultText = '自定义刷新完成'
          }, 2000)
        })
        .onOffsetChange((value: number) => {
          this.refreshOffset = value
        })

        // API 说明区
        Column() {
          Text('API 说明')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 8 })
          Text('builder: CustomBuilder — 自定义刷新区域显示内容')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('建议设置 constraintSize({ minHeight: 32 }) 防止高度塌陷')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('自定义组件高度限制: API 10 及之前 ≤64vp，API 11+ 无限制')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('元服务：API 11+ 可用，建议 API 12+ 使用 refreshingContent 替代')
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
