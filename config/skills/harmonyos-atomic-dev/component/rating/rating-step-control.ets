/**
 * rating-step-control — Rating 动态步长与星数控制
 * 展示动态调整 stars 和 stepSize 参数对评分的影响
 * 元服务兼容性：stars / stepSize 属性 元服务 API 11+ 可用
 */
@ComponentV2
export struct RatingStepControl {
  @Local currentRating: number = 2.5
  @Local starCount: number = 5
  @Local stepSizeValue: number = 0.5
  @Local resultText: string = '当前评分: 2.5 / 5'
  @Local eventLog: string = '调整星星数量和步长观察变化'

  private starOptions: number[] = [3, 5, 7, 10]
  private stepOptions: number[] = [0.1, 0.5, 1]

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('Rating 步长与星数控制')
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

        // 评分组件展示区
        Column() {
          Text(`评分组件 (${this.starCount} 星, 步长 ${this.stepSizeValue})`)
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .width('100%')
            .margin({ bottom: 8 })

          Rating({ rating: this.currentRating, indicator: false })
            .stars(this.starCount)
            .stepSize(this.stepSizeValue)
            .onChange((value: number) => {
              try {
                this.currentRating = value
                this.resultText = `当前评分: ${value.toFixed(1)} / ${this.starCount}`
                this.eventLog = `onChange: ${value.toFixed(1)}, 步长: ${this.stepSizeValue}`
              } catch (err) {
                this.eventLog = `错误: ${(err as BusinessError).message}`
              }
            })
        }
        .width('90%')
        .padding(16)
        .backgroundColor('#FFFFFF')
        .borderRadius(8)
        .shadow({ radius: 2, color: '#22000000', offsetX: 0, offsetY: 1 })

        // 星星数量控制
        Column() {
          Text('星星数量 (stars)')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .width('100%')
            .margin({ bottom: 8 })

          Row({ space: 8 }) {
            ForEach(this.starOptions, (count: number) => {
              Button(`${count}星`)
                .fontSize(12)
                .height(36)
                .backgroundColor(this.starCount === count ? '#007DFF' : '#E0E0E0')
                .fontColor(this.starCount === count ? '#FFFFFF' : '#333333')
                .onClick(() => {
                  try {
                    this.starCount = count
                    if (this.currentRating > count) {
                      this.currentRating = count
                    }
                    this.resultText = `当前评分: ${this.currentRating.toFixed(1)} / ${count}`
                    this.eventLog = `星星数量调整为 ${count}`
                  } catch (err) {
                    this.eventLog = `错误: ${(err as BusinessError).message}`
                  }
                })
            }, (count: number) => count.toString())
          }
        }
        .width('90%')
        .padding(12)
        .backgroundColor('#FFFFFF')
        .borderRadius(8)
        .shadow({ radius: 2, color: '#22000000', offsetX: 0, offsetY: 1 })

        // 步长控制
        Column() {
          Text('评分步长 (stepSize)')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .width('100%')
            .margin({ bottom: 8 })

          Row({ space: 8 }) {
            ForEach(this.stepOptions, (step: number) => {
              Button(`${step}`)
                .fontSize(12)
                .height(36)
                .backgroundColor(this.stepSizeValue === step ? '#007DFF' : '#E0E0E0')
                .fontColor(this.stepSizeValue === step ? '#FFFFFF' : '#333333')
                .onClick(() => {
                  try {
                    this.stepSizeValue = step
                    this.eventLog = `步长调整为 ${step}，评分粒度: ${step === 1 ? '整星' : step === 0.5 ? '半星' : '精细(0.1)'}`
                  } catch (err) {
                    this.eventLog = `错误: ${(err as BusinessError).message}`
                  }
                })
            }, (step: number) => step.toString())
          }
        }
        .width('90%')
        .padding(12)
        .backgroundColor('#FFFFFF')
        .borderRadius(8)
        .shadow({ radius: 2, color: '#22000000', offsetX: 0, offsetY: 1 })

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

        // API 说明区
        Column() {
          Text('API 说明')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 8 })
          Text('stars(value: number) — 评分总数，默认5，小于等于0按默认值')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('stepSize(value: number) — 步长，默认0.5，范围[0.1, stars]')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('步长=1: 仅整星评分; 步长=0.5: 支持半星; 步长=0.1: 精细评分')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('元服务兼容: stars / stepSize 属性 API 11+ 可用')
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
