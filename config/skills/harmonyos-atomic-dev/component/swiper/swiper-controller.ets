/**
 * swiper-controller — Swiper 控制器切换
 * 展示 SwiperController 的 showNext / showPrevious / changeIndex 方法
 * 元服务兼容性：SwiperController API 7+ 可用
 */
@ComponentV2
export struct SwiperControllerOps {
  @Local currentIndex: number = 0
  @Local targetIndex: number = 0
  @Local resultText: string = '当前页: 0'
  @Local eventLog: string = '等待操作...'

  private readonly swiperController: SwiperController = new SwiperController()
  private readonly colors: string[] = ['#F44336', '#E91E63', '#9C27B0', '#3F51B5', '#009688']

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('Swiper 控制器切换')
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

        // Swiper 绑定控制器
        Text('Swiper(controller) — 绑定控制器')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Swiper(this.swiperController) {
          ForEach(this.colors, (color: string, index: number) => {
            Column() {
              Text(`${index}`)
                .fontSize(40)
                .fontColor(Color.White)
                .fontWeight(FontWeight.Bold)
            }
            .width('90%')
            .height(160)
            .backgroundColor(color)
            .borderRadius(12)
            .justifyContent(FlexAlign.Center)
          }, (color: string, index: number) => `ctrl_${index}`)
        }
        .width('100%')
        .height(180)
        .indicator(true)
        .loop(false)
        .onChange((index: number) => {
          try {
            this.currentIndex = index
            this.resultText = `当前页: ${index}`
            this.eventLog = `onChange → index: ${index}`
          } catch (err) {
            this.eventLog = `错误: ${(err as BusinessError).message}`
          }
        })

        // showNext / showPrevious 按钮
        Text('控制器方法')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Row({ space: 12 }) {
          Button('showPrevious')
            .fontSize(13)
            .height(36)
            .onClick(() => {
              try {
                this.swiperController.showPrevious()
                this.eventLog = 'controller.showPrevious() 已调用'
              } catch (err) {
                this.eventLog = `错误: ${(err as BusinessError).message}`
              }
            })
          Button('showNext')
            .fontSize(13)
            .height(36)
            .onClick(() => {
              try {
                this.swiperController.showNext()
                this.eventLog = 'controller.showNext() 已调用'
              } catch (err) {
                this.eventLog = `错误: ${(err as BusinessError).message}`
              }
            })
        }
        .width('90%')
        .justifyContent(FlexAlign.Center)

        // changeIndex
        Text('跳转指定页 (changeIndex)')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Row({ space: 8 }) {
          Text('目标页:')
            .fontSize(13)
            .fontColor('#333333')
          Button(`${this.targetIndex}`)
            .fontSize(13)
            .height(32)
            .width(40)
            .onClick(() => {
              try {
                this.targetIndex = (this.targetIndex + 1) % this.colors.length
              } catch (err) {
                this.eventLog = `错误: ${(err as BusinessError).message}`
              }
            })
          Button(`跳转到 ${this.targetIndex}`)
            .fontSize(13)
            .height(32)
            .backgroundColor('#FF9800')
            .onClick(() => {
              try {
                this.swiperController.changeIndex(this.targetIndex)
                this.eventLog = `controller.changeIndex(${this.targetIndex}) 已调用`
              } catch (err) {
                this.eventLog = `错误: ${(err as BusinessError).message}`
              }
            })
        }
        .width('90%')
        .justifyContent(FlexAlign.Center)

        // 快捷跳转按钮
        Row({ space: 8 }) {
          ForEach(this.colors, (color: string, index: number) => {
            Button(`${index}`)
              .fontSize(13)
              .height(32)
              .width(40)
              .backgroundColor(this.currentIndex === index ? '#007DFF' : '#CCCCCC')
              .onClick(() => {
                try {
                  this.swiperController.changeIndex(index)
                  this.eventLog = `快捷跳转 → changeIndex(${index})`
                } catch (err) {
                  this.eventLog = `错误: ${(err as BusinessError).message}`
                }
              })
          }, (color: string, index: number) => `quick_${index}`)
        }
        .width('90%')
        .justifyContent(FlexAlign.Center)

        // 重置按钮
        Button('重置到第 0 页')
          .width('90%')
          .height(40)
          .backgroundColor('#007DFF')
          .onClick(() => {
            try {
              this.swiperController.changeIndex(0)
              this.targetIndex = 0
              this.resultText = '当前页: 0'
              this.eventLog = '已重置到第 0 页'
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
          Text('const controller = new SwiperController()')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('Swiper(controller) { ... } — 绑定控制器')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('controller.showNext() — 切换到后一页')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('controller.showPrevious() — 切换到前一页')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('controller.changeIndex(index) — 跳转到指定页')
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
