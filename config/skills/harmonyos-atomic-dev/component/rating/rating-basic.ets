/**
 * rating-basic — Rating 基础创建与评分交互
 * 展示 Rating 组件的基本创建、rating 参数设置、onChange 事件回调
 * 元服务兼容性：Rating(options) / onChange 元服务 API 11+ 可用
 */
@ComponentV2
export struct RatingBasic {
  @Local currentRating: number = 3
  @Local resultText: string = '当前评分: 3.0'
  @Local eventLog: string = '点击星星进行评分'

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('Rating 基础创建')
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
          Text('默认样式 (5星)')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .width('100%')
            .margin({ bottom: 8 })

          Rating({ rating: this.currentRating, indicator: false })
            .stars(5)
            .stepSize(0.5)
            .onChange((value: number) => {
              try {
                this.currentRating = value
                this.resultText = `当前评分: ${value.toFixed(1)}`
                this.eventLog = `onChange 触发，新评分: ${value.toFixed(1)}`
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

        // 参数控制区 — 预设评分
        Column() {
          Text('预设评分')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .width('100%')
            .margin({ bottom: 8 })

          Row({ space: 8 }) {
            Button('0分')
              .fontSize(12)
              .height(36)
              .onClick(() => {
                try {
                  this.currentRating = 0
                  this.resultText = '当前评分: 0.0'
                  this.eventLog = '手动设置为 0 分'
                } catch (err) {
                  this.eventLog = `错误: ${(err as BusinessError).message}`
                }
              })

            Button('2.5分')
              .fontSize(12)
              .height(36)
              .onClick(() => {
                try {
                  this.currentRating = 2.5
                  this.resultText = '当前评分: 2.5'
                  this.eventLog = '手动设置为 2.5 分'
                } catch (err) {
                  this.eventLog = `错误: ${(err as BusinessError).message}`
                }
              })

            Button('4.5分')
              .fontSize(12)
              .height(36)
              .onClick(() => {
                try {
                  this.currentRating = 4.5
                  this.resultText = '当前评分: 4.5'
                  this.eventLog = '手动设置为 4.5 分'
                } catch (err) {
                  this.eventLog = `错误: ${(err as BusinessError).message}`
                }
              })

            Button('满分')
              .fontSize(12)
              .height(36)
              .onClick(() => {
                try {
                  this.currentRating = 5
                  this.resultText = '当前评分: 5.0'
                  this.eventLog = '手动设置为满分'
                } catch (err) {
                  this.eventLog = `错误: ${(err as BusinessError).message}`
                }
              })
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
          Text('Rating(options?: RatingOptions)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('rating: number — 设置并接收评分值，默认0，范围[0, stars]')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('indicator: boolean — 是否为指示器模式，默认false')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('stars(value: number) — 设置评分总数，默认5')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('stepSize(value: number) — 设置操作评级步长，默认0.5，范围[0.1, stars]')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('onChange(callback: (value: number) => void) — 评分变化回调')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('元服务兼容: 以上 API 均在 API 11+ 可用')
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
