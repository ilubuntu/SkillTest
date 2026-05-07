/**
 * swiper-indicator — Swiper 导航点样式
 * 展示 Swiper 组件的导航点指示器样式自定义（DotIndicator）
 * 元服务兼容性：indicator 属性 API 7+ 可用，DotIndicator 自定义 API 8+ 可用
 */
import { LengthMetrics } from '@kit.ArkUI'

@ComponentV2
export struct SwiperIndicator {
  @Local resultText: string = '指示器: 默认圆点'
  @Local eventLog: string = '等待操作...'
  @Local indicatorMode: number = 0
  @Local currentIndex: number = 0

  private readonly colors: string[] = ['#3F51B5', '#009688', '#795548', '#607D8B']
  private readonly indicatorModes: string[] = ['默认圆点', '自定义圆点样式', '隐藏指示器']
  private readonly swiperController: SwiperController = new SwiperController()

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('Swiper 导航点样式')
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

        // 事件日志区
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

        // 指示器模式切换
        Text('指示器模式切换')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Row() {
          ForEach(this.indicatorModes, (mode: string, index: number) => {
            Button(mode)
              .fontSize(11)
              .height(32)
              .backgroundColor(this.indicatorMode === index ? '#007DFF' : '#CCCCCC')
              .margin({ left: 4, right: 4 })
              .onClick(() => {
                try {
                  this.indicatorMode = index
                  this.resultText = `指示器: ${mode}`
                  this.eventLog = `切换模式 → ${mode}`
                } catch (err) {
                  this.eventLog = `错误: ${(err as BusinessError).message}`
                }
              })
          }, (mode: string, index: number) => `${index}`)
        }
        .width('90%')
        .justifyContent(FlexAlign.Center)

        // 默认指示器
        if (this.indicatorMode === 0) {
          Text('默认圆点指示器 (.indicator(true))')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .alignSelf(ItemAlign.Start)
            .margin({ left: 16, top: 8 })

          Swiper() {
            ForEach(this.colors, (color: string, index: number) => {
              Column() {
                Text(`页面 ${index}`)
                  .fontSize(24)
                  .fontColor(Color.White)
                  .fontWeight(FontWeight.Bold)
              }
              .width('90%')
              .height(160)
              .backgroundColor(color)
              .borderRadius(12)
              .justifyContent(FlexAlign.Center)
            }, (color: string, index: number) => `d_${index}`)
          }
          .width('100%')
          .height(180)
          .indicator(true)
          .loop(true)
          .onChange((index: number) => {
            try {
              this.currentIndex = index
              this.eventLog = `默认指示器 → index: ${index}`
            } catch (err) {
              this.eventLog = `错误: ${(err as BusinessError).message}`
            }
          })
        }

        // 自定义指示器样式
        if (this.indicatorMode === 1) {
          Text('自定义圆点样式 (DotIndicator)')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .alignSelf(ItemAlign.Start)
            .margin({ left: 16, top: 8 })

          Swiper() {
            ForEach(this.colors, (color: string, index: number) => {
              Column() {
                Text(`页面 ${index}`)
                  .fontSize(24)
                  .fontColor(Color.White)
                  .fontWeight(FontWeight.Bold)
              }
              .width('90%')
              .height(160)
              .backgroundColor(color)
              .borderRadius(12)
              .justifyContent(FlexAlign.Center)
            }, (color: string, index: number) => `c_${index}`)
          }
          .width('100%')
          .height(180)
          .indicator(
            new DotIndicator()
              .itemWidth(8)
              .itemHeight(8)
              .selectedItemWidth(20)
              .selectedItemHeight(8)
              .color('#CCCCCC')
              .selectedColor('#FF6B00')
          )
          .loop(true)
          .onChange((index: number) => {
            try {
              this.currentIndex = index
              this.eventLog = `自定义指示器 → index: ${index}`
            } catch (err) {
              this.eventLog = `错误: ${(err as BusinessError).message}`
            }
          })
        }

        // 隐藏指示器
        if (this.indicatorMode === 2) {
          Text('隐藏指示器 (.indicator(false))')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .alignSelf(ItemAlign.Start)
            .margin({ left: 16, top: 8 })

          Swiper() {
            ForEach(this.colors, (color: string, index: number) => {
              Column() {
                Text(`页面 ${index}`)
                  .fontSize(24)
                  .fontColor(Color.White)
                  .fontWeight(FontWeight.Bold)
              }
              .width('90%')
              .height(160)
              .backgroundColor(color)
              .borderRadius(12)
              .justifyContent(FlexAlign.Center)
            }, (color: string, index: number) => `h_${index}`)
          }
          .width('100%')
          .height(180)
          .indicator(false)
          .loop(true)
          .onChange((index: number) => {
            try {
              this.currentIndex = index
              this.eventLog = `隐藏指示器 → index: ${index}`
            } catch (err) {
              this.eventLog = `错误: ${(err as BusinessError).message}`
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
          Text('.indicator(boolean | DotIndicator | DigitIndicator)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('.indicator(true) — 默认圆点指示器')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('.indicator(false) — 隐藏指示器')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('new DotIndicator()')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('  .itemWidth / itemHeight — 未选中圆点尺寸')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('  .selectedItemWidth / selectedItemHeight — 选中圆点尺寸')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('  .color / .selectedColor — 未选中/选中颜色')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('元服务兼容: API 7+ indicator(boolean), API 8+ DotIndicator')
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
