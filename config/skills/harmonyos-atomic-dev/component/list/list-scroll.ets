/**
 * list-scroll — 滚动控制
 * 展示 List scrollBar 属性、cachedCount 预加载、Scroller 滚动控制
 * 元服务兼容性：scrollBar API 7+，cachedCount API 9+，元服务 API 11+ 可用
 */
import { BusinessError } from '@kit.BasicServicesKit'

@ComponentV2
export struct ListScroll {
  @Local barState: BarState = BarState.Auto
  @Local cachedCount: number = 5
  @Local resultText: string = '滚动条: Auto | 缓存数: 5'
  private scroller: ListScroller = new ListScroller()
  private itemCount: number = 50

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('滚动控制')
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

        // 列表预览
        Text(`50项列表 (cachedCount: ${this.cachedCount})`)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        List({ space: 8, scroller: this.scroller }) {
          ForEach(this.generateItems(),
            (item: number) => {
              ListItem() {
                Row() {
                  Text(`#${item + 1}`)
                    .fontSize(14)
                    .fontColor('#FFFFFF')
                    .width(36)
                    .height(36)
                    .textAlign(TextAlign.Center)
                    .borderRadius(18)
                    .backgroundColor(item < 10 ? '#4CAF50' : item < 30 ? '#2196F3' : '#FF9800')

                  Text(`列表项 ${item + 1}`)
                    .fontSize(15)
                    .margin({ left: 12 })
                    .layoutWeight(1)
                }
                .width('100%')
                .padding({ left: 16, right: 16, top: 12, bottom: 12 })
                .backgroundColor('#FFFFFF')
                .borderRadius(8)
              }
            }, (item: number) => `item_${item}`)
        }
        .scrollBar(this.barState)
        .cachedCount(this.cachedCount)
        .width('90%')
        .height(320)
        .borderRadius(8)
        .backgroundColor('#F0F0F0')
        .padding(8)

        // 滚动条控制
        Text('滚动条模式')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Row({ space: 8 }) {
          Button('Off')
            .fontSize(13)
            .width(60)
            .height(36)
            .onClick(() => {
              this.barState = BarState.Off
              this.updateResult()
            })
          Button('Auto')
            .fontSize(13)
            .width(60)
            .height(36)
            .onClick(() => {
              this.barState = BarState.Auto
              this.updateResult()
            })
          Button('On')
            .fontSize(13)
            .width(60)
            .height(36)
            .onClick(() => {
              this.barState = BarState.On
              this.updateResult()
            })
        }

        // 缓存数控制
        Text('cachedCount 预加载')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Row({ space: 8 }) {
          Button('0')
            .fontSize(13)
            .width(50)
            .height(36)
            .onClick(() => { this.cachedCount = 0; this.updateResult() })
          Button('5')
            .fontSize(13)
            .width(50)
            .height(36)
            .onClick(() => { this.cachedCount = 5; this.updateResult() })
          Button('10')
            .fontSize(13)
            .width(50)
            .height(36)
            .onClick(() => { this.cachedCount = 10; this.updateResult() })
        }

        // Scroller 控制
        Text('Scroller 滚动控制')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Row({ space: 8 }) {
          Button('到顶部')
            .fontSize(13)
            .width(70)
            .height(36)
            .onClick(() => {
              try {
                this.scroller.scrollToIndex(0)
                this.resultText = '已滚动到顶部'
              } catch (error) {
                this.resultText = `错误: ${(error as BusinessError).message}`
              }
            })
          Button('到底部')
            .fontSize(13)
            .width(70)
            .height(36)
            .onClick(() => {
              try {
                this.scroller.scrollToIndex(this.itemCount - 1)
                this.resultText = '已滚动到底部'
              } catch (error) {
                this.resultText = `错误: ${(error as BusinessError).message}`
              }
            })
          Button('到第20项')
            .fontSize(13)
            .width(70)
            .height(36)
            .onClick(() => {
              try {
                this.scroller.scrollToIndex(19)
                this.resultText = '已滚动到第 20 项'
              } catch (error) {
                this.resultText = `错误: ${(error as BusinessError).message}`
              }
            })
        }

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
          Text('.cachedCount(value: number)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('ListScroller.scrollToIndex(index) — 滚动到指定项')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('BarState: Off(隐藏) / Auto(按需) / On(常驻)')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('cachedCount: 预加载的列表项数，提升滑动流畅度')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('元服务：API 11+ 可用')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
        }
        .width('90%')
        .backgroundColor('#FFF9E6')
        .borderRadius(8)
        .padding(12)
        .margin({ top: 8 })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
  }

  private updateResult(): void {
    const barStr = this.barState === BarState.Off ? 'Off' :
      this.barState === BarState.Auto ? 'Auto' : 'On'
    this.resultText = `滚动条: ${barStr} | 缓存数: ${this.cachedCount}`
  }

  private generateItems(): number[] {
    const items: number[] = []
    for (let i = 0; i < this.itemCount; i++) {
      items.push(i)
    }
    return items
  }
}
