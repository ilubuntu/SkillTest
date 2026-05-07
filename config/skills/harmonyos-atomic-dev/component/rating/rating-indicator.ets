/**
 * rating-indicator — Rating 指示器模式
 * 展示 Rating 组件的 indicator 属性，作为只读评分展示
 * 元服务兼容性：indicator 属性 元服务 API 11+ 可用
 */
@ComponentV2
export struct RatingIndicator {
  @Local isIndicator: boolean = true
  @Local displayRating: number = 3.5
  @Local resultText: string = '当前模式: 指示器 (只读)'
  @Local eventLog: string = '切换模式查看交互/只读差异'

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('Rating 指示器模式')
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
          Text('评分展示')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .width('100%')
            .margin({ bottom: 8 })

          Rating({ rating: this.displayRating, indicator: this.isIndicator })
            .stars(5)
            .stepSize(0.5)
            .onChange((value: number) => {
              try {
                this.displayRating = value
                this.eventLog = `评分变化: ${value.toFixed(1)} (仅交互模式下可触发)`
              } catch (err) {
                this.eventLog = `错误: ${(err as BusinessError).message}`
              }
            })

          Text(`评分值: ${this.displayRating.toFixed(1)} / 5.0`)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FF6D00')
            .margin({ top: 8 })
        }
        .width('90%')
        .padding(16)
        .backgroundColor('#FFFFFF')
        .borderRadius(8)
        .shadow({ radius: 2, color: '#22000000', offsetX: 0, offsetY: 1 })

        // 模式切换区
        Column() {
          Text('模式切换')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .width('100%')
            .margin({ bottom: 8 })

          Row({ space: 8 }) {
            Button('指示器模式')
              .fontSize(12)
              .height(36)
              .backgroundColor(this.isIndicator ? '#007DFF' : '#E0E0E0')
              .fontColor(this.isIndicator ? '#FFFFFF' : '#333333')
              .onClick(() => {
                try {
                  this.isIndicator = true
                  this.resultText = '当前模式: 指示器 (只读)'
                  this.eventLog = '切换到指示器模式，用户不可操作'
                } catch (err) {
                  this.eventLog = `错误: ${(err as BusinessError).message}`
                }
              })

            Button('交互模式')
              .fontSize(12)
              .height(36)
              .backgroundColor(!this.isIndicator ? '#007DFF' : '#E0E0E0')
              .fontColor(!this.isIndicator ? '#FFFFFF' : '#333333')
              .onClick(() => {
                try {
                  this.isIndicator = false
                  this.resultText = '当前模式: 交互 (可评分)'
                  this.eventLog = '切换到交互模式，用户可点击评分'
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

        // 预设评分值
        Column() {
          Text('调整评分值 (指示器模式下展示)')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .width('100%')
            .margin({ bottom: 8 })

          Row({ space: 8 }) {
            Button('1.0')
              .fontSize(12)
              .height(36)
              .onClick(() => {
                try {
                  this.displayRating = 1
                  this.eventLog = '设置评分值: 1.0'
                } catch (err) {
                  this.eventLog = `错误: ${(err as BusinessError).message}`
                }
              })

            Button('2.5')
              .fontSize(12)
              .height(36)
              .onClick(() => {
                try {
                  this.displayRating = 2.5
                  this.eventLog = '设置评分值: 2.5'
                } catch (err) {
                  this.eventLog = `错误: ${(err as BusinessError).message}`
                }
              })

            Button('4.0')
              .fontSize(12)
              .height(36)
              .onClick(() => {
                try {
                  this.displayRating = 4
                  this.eventLog = '设置评分值: 4.0'
                } catch (err) {
                  this.eventLog = `错误: ${(err as BusinessError).message}`
                }
              })

            Button('5.0')
              .fontSize(12)
              .height(36)
              .onClick(() => {
                try {
                  this.displayRating = 5
                  this.eventLog = '设置评分值: 5.0'
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
          Text('Rating({ rating, indicator })')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('indicator: boolean — true=指示器(只读)，false=可交互')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('indicator=true时: 默认高度12.0vp, 宽度=高度*stars')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('indicator=false时: 默认高度28.0vp, 宽度=高度*stars')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('元服务兼容: indicator 属性 API 11+ 可用')
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
