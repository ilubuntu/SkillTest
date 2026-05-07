/**
 * repeat-virtual-scroll — Repeat 虚拟滚动（懒加载）
 * 展示 Repeat 开启 virtualScroll 后与 List 容器配合，实现长列表按需渲染
 * 元服务兼容性：virtualScroll API 12+，元服务 API 12+ 可用
 */
import { BusinessError } from '@kit.BasicServicesKit'

@ComponentV2
export struct RepeatVirtualScroll {
  @Local dataList: string[] = []
  @Local totalCount: number = 50
  @Local resultText: string = '虚拟滚动就绪'

  aboutToAppear(): void {
    for (let i = 0; i < 20; i++) {
      this.dataList.push(`data_${i}`)
    }
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('Repeat 虚拟滚动')
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

        // 参数控制区
        Text('参数控制')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Row({ space: 8 }) {
          Text('totalCount:')
            .fontSize(13)
            .fontColor('#666666')
          Text(`${this.totalCount}`)
            .fontSize(13)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FF6B00')
        }
        .alignSelf(ItemAlign.Start)
        .margin({ left: 16 })

        Row({ space: 8 }) {
          Text('已加载:')
            .fontSize(13)
            .fontColor('#666666')
          Text(`${this.dataList.length}`)
            .fontSize(13)
            .fontWeight(FontWeight.Bold)
            .fontColor('#3498DB')
        }
        .alignSelf(ItemAlign.Start)
        .margin({ left: 16 })

        // 操作按钮
        Row({ space: 8 }) {
          Button('追加10条')
            .fontSize(13)
            .width(90)
            .height(36)
            .onClick(() => {
              try {
                const start = this.dataList.length
                for (let i = 0; i < 10 && this.dataList.length < this.totalCount; i++) {
                  this.dataList.push(`data_${start + i}`)
                }
                this.resultText = `已加载 ${this.dataList.length} / ${this.totalCount} 条`
              } catch (err) {
                const e = err as BusinessError
                this.resultText = `追加失败: ${e.message}`
              }
            })
          Button('设置totalCount=100')
            .fontSize(13)
            .height(36)
            .onClick(() => {
              this.totalCount = 100
              this.resultText = `totalCount 设置为 100，已加载 ${this.dataList.length} 条`
            })
          Button('重置')
            .fontSize(13)
            .width(60)
            .height(36)
            .onClick(() => {
              this.dataList = []
              for (let i = 0; i < 20; i++) {
                this.dataList.push(`data_${i}`)
              }
              this.totalCount = 50
              this.resultText = '已重置'
            })
        }

        // 虚拟滚动列表
        Text('List + Repeat + virtualScroll')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        List({ space: 8 }) {
          Repeat<string>(this.dataList)
            .each((ri: RepeatItem<string>) => {
              ListItem() {
                Row() {
                  Text(`#${ri.index}`)
                    .fontSize(14)
                    .fontColor('#FFFFFF')
                    .width(36)
                    .height(36)
                    .textAlign(TextAlign.Center)
                    .borderRadius(18)
                    .backgroundColor('#3498DB')
                  Text(ri.item)
                    .fontSize(15)
                    .margin({ left: 12 })
                    .layoutWeight(1)
                  Text(`${ri.index % 2 === 0 ? '偶' : '奇'}`)
                    .fontSize(12)
                    .fontColor('#999999')
                }
                .width('100%')
                .padding(12)
                .backgroundColor('#FFFFFF')
                .borderRadius(6)
              }
              .height(60)
            })
            .key((item: string) => item)
            .virtualScroll({ totalCount: this.totalCount })
        }
        .cachedCount(2)
        .width('90%')
        .height(300)
        .border({ width: 1, color: '#E0E0E0' })
        .borderRadius(8)

        // API 说明区
        Column() {
          Text('API 说明')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 8 })
          Text('.virtualScroll(options?: VirtualScrollOptions)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('totalCount: 期望加载的数据总长度，可大于 arr.length')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('必须与 List/Grid/Swiper/WaterFlow 配合使用')
            .fontSize(12)
            .fontColor('#FF6B00')
            .width('100%')
          Text('建议: 容器组件设置 .cachedCount(n) 优化滑动性能')
            .fontSize(12)
            .fontColor('#FF6B00')
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
