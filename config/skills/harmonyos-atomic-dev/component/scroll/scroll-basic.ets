/**
 * scroll-basic — 基础垂直滚动 + Scroller 控制
 * 展示 Scroll 组件基本用法、Scroller 控制器：scrollTo、scrollEdge、scrollPage、scrollBy、currentOffset、isAtEnd
 * 元服务兼容性：Scroll API 7+，元服务 API 11+ 可用
 */
import { BusinessError } from '@kit.BasicServicesKit'

@ComponentV2
export struct ScrollBasic {
  @Local resultText: string = '等待操作...'
  @Local offsetInfo: string = '偏移: (0, 0)'
  @Local isBottom: boolean = false
  private scroller: Scroller = new Scroller()
  private items: number[] = []

  aboutToAppear(): void {
    for (let i = 0; i < 20; i++) {
      this.items.push(i)
    }
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('基础垂直滚动')
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
          Text(this.offsetInfo)
            .fontSize(13)
            .fontColor('#666666')
            .width('100%')
            .padding({ left: 12, bottom: 12 })
          Text(`是否到底: ${this.isBottom ? '是' : '否'}`)
            .fontSize(13)
            .fontColor('#666666')
            .width('100%')
            .padding({ left: 12, bottom: 12 })
        }
        .width('90%')
        .backgroundColor('#F5F5F5')
        .borderRadius(8)

        // 滚动内容区域
        Text('滚动内容（20 项）')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Scroll(this.scroller) {
          Column({ space: 8 }) {
            ForEach(this.items,
              (item: number) => {
                Text(`内容项 ${item + 1}`)
                  .width('100%')
                  .height(80)
                  .backgroundColor(item % 3 === 0 ? '#E3F2FD' : item % 3 === 1 ? '#FFF3E0' : '#E8F5E9')
                  .borderRadius(8)
                  .fontSize(15)
                  .textAlign(TextAlign.Center)
                  .fontColor('#333333')
              }, (item: number) => `item_${item}`)
          }
          .padding(8)
        }
        .scrollable(ScrollDirection.Vertical)
        .scrollBar(BarState.On)
        .scrollBarColor('#999999')
        .scrollBarWidth(4)
        .edgeEffect(EdgeEffect.Spring)
        .width('90%')
        .height(300)
        .borderRadius(8)
        .backgroundColor('#F0F0F0')

        // Scroller 控制按钮
        Text('Scroller 滚动控制')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        // 第一行：scrollBy
        Row({ space: 8 }) {
          Button('下移 200vp')
            .fontSize(13)
            .layoutWeight(1)
            .height(36)
            .onClick(() => {
              try {
                this.scroller.scrollBy(0, 200)
                this.updateOffset()
                this.resultText = 'scrollBy(0, 200) 向下移动 200vp'
              } catch (error) {
                this.resultText = `错误: ${(error as BusinessError).message}`
              }
            })
          Button('上移 200vp')
            .fontSize(13)
            .layoutWeight(1)
            .height(36)
            .onClick(() => {
              try {
                this.scroller.scrollBy(0, -200)
                this.updateOffset()
                this.resultText = 'scrollBy(0, -200) 向上移动 200vp'
              } catch (error) {
                this.resultText = `错误: ${(error as BusinessError).message}`
              }
            })
        }
        .width('90%')

        // 第二行：scrollTo
        Row({ space: 8 }) {
          Button('到 500vp')
            .fontSize(13)
            .layoutWeight(1)
            .height(36)
            .onClick(() => {
              try {
                this.scroller.scrollTo({ xOffset: 0, yOffset: 500 })
                this.updateOffset()
                this.resultText = 'scrollTo(0, 500) 滑动到 500vp 位置'
              } catch (error) {
                this.resultText = `错误: ${(error as BusinessError).message}`
              }
            })
          Button('到 1000vp')
            .fontSize(13)
            .layoutWeight(1)
            .height(36)
            .onClick(() => {
              try {
                this.scroller.scrollTo({ xOffset: 0, yOffset: 1000, animation: true })
                this.updateOffset()
                this.resultText = 'scrollTo(0, 1000) 带动画滑动到 1000vp'
              } catch (error) {
                this.resultText = `错误: ${(error as BusinessError).message}`
              }
            })
        }
        .width('90%')

        // 第三行：scrollEdge / scrollPage
        Row({ space: 8 }) {
          Button('回顶部')
            .fontSize(13)
            .layoutWeight(1)
            .height(36)
            .onClick(() => {
              try {
                this.scroller.scrollEdge(Edge.Top)
                this.updateOffset()
                this.resultText = 'scrollEdge(Top) 回到顶部'
              } catch (error) {
                this.resultText = `错误: ${(error as BusinessError).message}`
              }
            })
          Button('到底部')
            .fontSize(13)
            .layoutWeight(1)
            .height(36)
            .onClick(() => {
              try {
                this.scroller.scrollEdge(Edge.Bottom)
                this.updateOffset()
                this.resultText = 'scrollEdge(Bottom) 滚到底部'
              } catch (error) {
                this.resultText = `错误: ${(error as BusinessError).message}`
              }
            })
        }
        .width('90%')

        // 第四行：scrollPage
        Row({ space: 8 }) {
          Button('下一页')
            .fontSize(13)
            .layoutWeight(1)
            .height(36)
            .onClick(() => {
              try {
                this.scroller.scrollPage({ next: true })
                this.updateOffset()
                this.resultText = 'scrollPage(next: true) 翻到下一页'
              } catch (error) {
                this.resultText = `错误: ${(error as BusinessError).message}`
              }
            })
          Button('上一页')
            .fontSize(13)
            .layoutWeight(1)
            .height(36)
            .onClick(() => {
              try {
                this.scroller.scrollPage({ next: false })
                this.updateOffset()
                this.resultText = 'scrollPage(next: false) 翻到上一页'
              } catch (error) {
                this.resultText = `错误: ${(error as BusinessError).message}`
              }
            })
        }
        .width('90%')

        // 第五行：currentOffset / isAtEnd
        Row({ space: 8 }) {
          Button('获取偏移')
            .fontSize(13)
            .layoutWeight(1)
            .height(36)
            .onClick(() => {
              this.updateOffset()
              this.resultText = '已获取当前偏移量'
            })
          Button('是否到底')
            .fontSize(13)
            .layoutWeight(1)
            .height(36)
            .onClick(() => {
              try {
                this.isBottom = this.scroller.isAtEnd()
                this.resultText = `isAtEnd(): ${this.isBottom}`
              } catch (error) {
                this.resultText = `错误: ${(error as BusinessError).message}`
              }
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
          Text('Scroll(scroller?: Scroller) — 创建滚动容器')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('scroller.scrollTo({ xOffset, yOffset, animation? })')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('scroller.scrollEdge(Edge.Top/Bottom)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('scroller.scrollPage({ next: boolean })')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('scroller.scrollBy(dx, dy) — 相对滑动距离')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('scroller.currentOffset() → { xOffset, yOffset }')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('scroller.isAtEnd() → boolean')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('元服务：API 11+ 可用，animation 参数支持 boolean/ScrollAnimationOptions')
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

  private updateOffset(): void {
    try {
      const offset = this.scroller.currentOffset()
      this.offsetInfo = `偏移: (${offset.xOffset.toFixed(1)}, ${offset.yOffset.toFixed(1)}) vp`
    } catch (error) {
      this.offsetInfo = `获取偏移失败: ${(error as BusinessError).message}`
    }
  }
}
