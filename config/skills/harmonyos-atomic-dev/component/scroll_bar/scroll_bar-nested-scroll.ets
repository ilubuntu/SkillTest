/**
 * scroll_bar-nested-scroll — ScrollBar 嵌套滚动
 * 展示 enableNestedScroll 属性，ScrollBar 与嵌套滚动组件联动
 * 元服务兼容性：enableNestedScroll API 14+
 */
import { BusinessError } from '@kit.BasicServicesKit'

@ComponentV2
export struct ScrollBarNestedScroll {
  @Local nestedEnabled: boolean = true
  @Local resultText: string = '嵌套滚动: 已启用'
  @Local eventLog: string = '滚动内层列表，ScrollBar 跟随联动'
  private listScroller: Scroller = new Scroller()
  private outerScroller: Scroller = new Scroller()
  @Local listData: number[] = []

  aboutToAppear(): void {
    try {
      for (let i = 0; i < 20; i++) {
        this.listData.push(i)
      }
      this.resultText = '嵌套滚动: 已启用 (共 20 项)'
    } catch (err) {
      this.eventLog = `初始化错误: ${(err as BusinessError).message}`
    }
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('ScrollBar 嵌套滚动')
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

        // 嵌套滚动演示
        Text('外层 Scroll + 内层 List + ScrollBar')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Stack() {
          Scroll(this.outerScroller) {
            Column() {
              Text('顶部区域（可滚动）')
                .width('100%')
                .height(120)
                .backgroundColor('#0080DC')
                .textAlign(TextAlign.Center)
                .fontColor('#FFFFFF')
                .fontSize(16)
                .borderRadius({ topLeft: 8, topRight: 8 })

              List({ space: 8, scroller: this.listScroller }) {
                ForEach(this.listData,
                  (item: number) => {
                    ListItem() {
                      Text(`内层列表项 ${item + 1}`)
                        .width('100%')
                        .height(56)
                        .backgroundColor('#FFFFFF')
                        .borderRadius(8)
                        .fontSize(14)
                        .textAlign(TextAlign.Center)
                        .shadow({ radius: 1, color: '#10000000', offsetY: 1 })
                    }
                  }, (item: number) => `list_${item}`)
              }
              .scrollBar(BarState.Off)
              .nestedScroll({
                scrollForward: NestedScrollMode.PARENT_FIRST,
                scrollBackward: NestedScrollMode.SELF_FIRST
              })
              .width('100%')
              .height(280)

              Text('底部区域')
                .width('100%')
                .height(60)
                .backgroundColor('#EEEEEE')
                .textAlign(TextAlign.Center)
                .fontSize(14)
            }
            .width('100%')
            .padding({ left: 16, right: 32 })
          }
          .edgeEffect(EdgeEffect.Spring)
          .backgroundColor('#DCDCDC')
          .scrollBar(BarState.Off)
          .width('90%')
          .height(400)
          .borderRadius(8)

          // ScrollBar 绑定到内层 List，启用嵌套滚动
          ScrollBar({
            scroller: this.listScroller,
            direction: ScrollBarDirection.Vertical,
            state: BarState.Auto
          }) {
            Text()
              .width(12)
              .height(60)
              .borderRadius(6)
              .backgroundColor('#007DFF')
          }
          .width(12)
          .position({ right: 8, top: 130 })
          .enableNestedScroll(this.nestedEnabled)
        }
        .width('100%')
        .height(400)

        // 切换嵌套滚动
        Row({ space: 8 }) {
          Button('启用嵌套滚动')
            .fontSize(13)
            .layoutWeight(1)
            .height(36)
            .backgroundColor(this.nestedEnabled ? '#007DFF' : '#CCCCCC')
            .fontColor(this.nestedEnabled ? '#FFFFFF' : '#333333')
            .onClick(() => {
              this.nestedEnabled = true
              this.resultText = '嵌套滚动: 已启用'
              this.eventLog = '滚动内层列表时，ScrollBar 偏移先传给内层再传给外层'
            })
          Button('禁用嵌套滚动')
            .fontSize(13)
            .layoutWeight(1)
            .height(36)
            .backgroundColor(!this.nestedEnabled ? '#007DFF' : '#CCCCCC')
            .fontColor(!this.nestedEnabled ? '#FFFFFF' : '#333333')
            .onClick(() => {
              this.nestedEnabled = false
              this.resultText = '嵌套滚动: 已禁用'
              this.eventLog = 'ScrollBar 不会将滚动偏移传递给绑定组件'
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
          Text('.enableNestedScroll(enabled: Optional<boolean>)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('true — 滚动条偏移先传给内层滚动组件')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('false — 不执行嵌套滚动（默认值）')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('PARALLEL 模式需在 onScrollFrameBegin 自行处理父子顺序')
            .fontSize(12)
            .fontColor('#FF6B00')
            .width('100%')
          Text('WaterFlow SLIDING_WINDOW 模式不支持嵌套滚动')
            .fontSize(12)
            .fontColor('#FF6B00')
            .width('100%')
          Text('元服务兼容: API 14+')
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
