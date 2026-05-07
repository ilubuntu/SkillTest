/**
 * water_flow-basic — WaterFlow 瀑布流基础用法
 * 展示瀑布流布局、多列、间距控制、滚动事件
 * 元服务兼容性：WaterFlow 从 API 11+ 可用，sections/cachedCount 从 API 12+ 可用
 */
@ComponentV2
export struct WaterFlowBasic {
  @Local resultLog: string = '等待操作...'
  @Local itemCount: number = 20
  @Local colors: string[] = ['#FF6B6B', '#4ECDC4', '#45B7D1', '#96CEB4', '#FFEAA7', '#DDA0DD', '#98D8C8', '#F7DC6F']
  @Local items1: number[] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19]
  @Local items2: number[] = [100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114]

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('WaterFlow 瀑布流基础用法')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20, bottom: 10 })

        // 结果展示区
        Column() {
          Text(this.resultLog)
            .fontSize(14)
            .fontColor('#333333')
            .width('100%')
            .padding(12)
        }
        .width('90%')
        .backgroundColor('#F5F5F5')
        .borderRadius(8)

        // ---- 多列瀑布流 ----
        Text('1. 双列瀑布流')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        WaterFlow() {
          ForEach(this.items1, (item: number) => {
            FlowItem() {
              Column() {
                Text(`Item ${item + 1}`)
                  .fontSize(14)
                  .fontColor('#FFFFFF')
                  .fontWeight(FontWeight.Medium)
              }
              .width('100%')
              .height(item % 3 === 0 ? 120 : item % 3 === 1 ? 80 : 160)
              .backgroundColor(this.colors[item % this.colors.length])
              .borderRadius(8)
              .justifyContent(FlexAlign.Center)
            }
          }, (item: number) => item.toString())
        }
        .columnsTemplate('1fr 1fr')
        .columnsGap(10)
        .rowsGap(10)
        .width('90%')
        .height(300)
        .onReachEnd(() => {
          this.resultLog = '已滚动到底部'
        })

        Text('columnsTemplate: 1fr 1fr（两列等宽）')
          .fontSize(12)
          .fontColor('#999999')
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16 })

        // ---- 三列瀑布流 ----
        Text('2. 三列不等宽瀑布流')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 12 })

        WaterFlow() {
          ForEach(this.items2, (item: number) => {
            FlowItem() {
              Column() {
                Text(`${item - 99}`)
                  .fontSize(16)
                  .fontColor('#FFFFFF')
              }
              .width('100%')
              .height(item % 4 === 0 ? 60 : item % 4 === 1 ? 100 : item % 4 === 2 ? 80 : 140)
              .backgroundColor(this.colors[(item - 100) % this.colors.length])
              .borderRadius(6)
              .justifyContent(FlexAlign.Center)
            }
          }, (item: number) => item.toString())
        }
        .columnsTemplate('1fr 2fr 1fr')
        .columnsGap(8)
        .rowsGap(8)
        .width('90%')
        .height(250)

        Text('columnsTemplate: 1fr 2fr 1fr（中间列更宽）')
          .fontSize(12)
          .fontColor('#999999')
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16 })

        // ---- 操作按钮 ----
        Row({ space: 12 }) {
          Button('增加项')
            .fontSize(13)
            .onClick(() => {
              this.itemCount += 5
              this.resultLog = `itemCount: ${this.itemCount}`
            })
          Button('减少项')
            .fontSize(13)
            .backgroundColor('#FF6B00')
            .onClick(() => {
              this.itemCount = Math.max(5, this.itemCount - 5)
              this.resultLog = `itemCount: ${this.itemCount}`
            })
        }

        // API 说明区
        Column() {
          Text('API 说明')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 8 })
          Text('WaterFlow(options?) — options: footer/scroller/sections/layoutMode')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('.columnsTemplate(string) — 列模板，如 "1fr 1fr" "1fr 2fr 1fr"')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('.rowsTemplate(string) — 行模板（横向瀑布流时使用）')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('.columnsGap / .rowsGap — 列间距/行间距')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('.cachedCount(number) — 缓存数量 (API 12+)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('FlowItem — 瀑布流子项容器')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('元服务API: API 11+ | sections/layoutMode: API 12+')
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
