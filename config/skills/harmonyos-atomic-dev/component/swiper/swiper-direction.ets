/**
 * swiper-direction — Swiper 轮播方向
 * 展示 Swiper 组件的水平和垂直方向轮播
 * 元服务兼容性：vertical 属性 API 7+ 可用
 */
@ComponentV2
export struct SwiperDirection {
  @Local isVertical: boolean = false
  @Local resultText: string = '方向: 水平'
  @Local eventLog: string = '等待操作...'

  private readonly colors: string[] = ['#E91E63', '#00BCD4', '#8BC34A', '#FF5722']

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('Swiper 轮播方向')
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

        // 方向切换按钮
        Row() {
          Button('水平方向')
            .fontSize(13)
            .height(36)
            .backgroundColor(this.isVertical ? '#CCCCCC' : '#007DFF')
            .onClick(() => {
              try {
                this.isVertical = false
                this.resultText = '方向: 水平'
                this.eventLog = '切换为水平轮播'
              } catch (err) {
                this.eventLog = `错误: ${(err as BusinessError).message}`
              }
            })
          Button('垂直方向')
            .fontSize(13)
            .height(36)
            .backgroundColor(this.isVertical ? '#007DFF' : '#CCCCCC')
            .margin({ left: 12 })
            .onClick(() => {
              try {
                this.isVertical = true
                this.resultText = '方向: 垂直'
                this.eventLog = '切换为垂直轮播'
              } catch (err) {
                this.eventLog = `错误: ${(err as BusinessError).message}`
              }
            })
        }
        .width('90%')
        .justifyContent(FlexAlign.Center)

        // 水平 Swiper
        Text('水平轮播 (.vertical(false))')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Swiper() {
          ForEach(this.colors, (color: string, index: number) => {
            Column() {
              Text(`水平 ${index}`)
                .fontSize(24)
                .fontColor(Color.White)
                .fontWeight(FontWeight.Bold)
            }
            .width('90%')
            .height(140)
            .backgroundColor(color)
            .borderRadius(12)
            .justifyContent(FlexAlign.Center)
          }, (color: string, index: number) => `h_${index}`)
        }
        .width('100%')
        .height(160)
        .indicator(true)
        .loop(true)
        .autoPlay(true)
        .interval(3000)
        .vertical(false)
        .onChange((index: number) => {
          try {
            this.eventLog = `水平轮播 → index: ${index}`
          } catch (err) {
            this.eventLog = `错误: ${(err as BusinessError).message}`
          }
        })

        // 垂直 Swiper
        Text('垂直轮播 (.vertical(true))')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Swiper() {
          ForEach(this.colors, (color: string, index: number) => {
            Column() {
              Text(`垂直 ${index}`)
                .fontSize(24)
                .fontColor(Color.White)
                .fontWeight(FontWeight.Bold)
            }
            .width('90%')
            .height(140)
            .backgroundColor(color)
            .borderRadius(12)
            .justifyContent(FlexAlign.Center)
          }, (color: string, index: number) => `v_${index}`)
        }
        .width('100%')
        .height(160)
        .indicator(true)
        .loop(true)
        .autoPlay(true)
        .interval(3000)
        .vertical(true)
        .onChange((index: number) => {
          try {
            this.eventLog = `垂直轮播 → index: ${index}`
          } catch (err) {
            this.eventLog = `错误: ${(err as BusinessError).message}`
          }
        })

        // API 说明区
        Column() {
          Text('API 说明')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 8 })
          Text('.vertical(boolean) — 是否纵向滑动 (默认 false)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('vertical=false: 水平方向轮播 (默认)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('vertical=true: 垂直方向轮播，指示器自动调整为纵向')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('元服务兼容: API 7+ 可用')
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
