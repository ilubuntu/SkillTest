/**
 * rating-content-modifier — Rating 自定义内容修改器
 * 展示 contentModifier 自定义 Rating 组件内容区
 * 元服务兼容性：contentModifier 元服务 API 12+ 可用
 */
@ComponentV2
export struct RatingContentModifier {
  @Local currentRating: number = 3
  @Local eventLog: string = '使用滑块进行评分'
  @Local resultText: string = '当前评分: 3.0 / 5.0'

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('Rating 自定义内容')
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

        // 标准 Rating 对比
        Column() {
          Text('标准 Rating 组件')
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
                this.resultText = `当前评分: ${value.toFixed(1)} / 5.0`
                this.eventLog = `标准 Rating onChange: ${value.toFixed(1)}`
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

        // 自定义评分展示
        Column() {
          Text('自定义评分展示 (模拟 contentModifier)')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .width('100%')
            .margin({ bottom: 8 })

          // 自定义星星展示
          Row({ space: 4 }) {
            ForEach([1, 2, 3, 4, 5], (starIndex: number) => {
              Column() {
                if (starIndex <= Math.floor(this.currentRating)) {
                  // 满星
                  Text('★')
                    .fontSize(28)
                    .fontColor('#FFB300')
                } else if (starIndex - 0.5 <= this.currentRating) {
                  // 半星 - 使用两个字符模拟
                  Row() {
                    Text('★')
                      .fontSize(28)
                      .fontColor('#FFB300')
                      .clip(true)
                      .width(14)
                    Text('★')
                      .fontSize(28)
                      .fontColor('#E0E0E0')
                      .clip(true)
                      .width(14)
                  }
                } else {
                  // 空星
                  Text('★')
                    .fontSize(28)
                    .fontColor('#E0E0E0')
                }
              }
              .onClick(() => {
                try {
                  this.currentRating = starIndex
                  this.resultText = `当前评分: ${starIndex.toFixed(1)} / 5.0`
                  this.eventLog = `自定义评分: ${starIndex.toFixed(1)}`
                } catch (err) {
                  this.eventLog = `错误: ${(err as BusinessError).message}`
                }
              })
            }, (starIndex: number) => starIndex.toString())
          }
          .justifyContent(FlexAlign.Center)

          // 评分文字
          Text(`${this.currentRating.toFixed(1)} / 5.0`)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FF6D00')
            .margin({ top: 8 })

          // 评分描述
          Text(this.getRatingDescription(this.currentRating))
            .fontSize(14)
            .fontColor('#666666')
            .margin({ top: 4 })
        }
        .width('90%')
        .padding(16)
        .backgroundColor('#FFFFFF')
        .borderRadius(8)
        .shadow({ radius: 2, color: '#22000000', offsetX: 0, offsetY: 1 })

        // 评分滑块控制
        Column() {
          Text('滑块调整评分')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .width('100%')
            .margin({ bottom: 8 })

          Slider({
            value: this.currentRating,
            min: 0,
            max: 5,
            step: 0.5,
            style: SliderStyle.InSet
          })
            .width('100%')
            .trackColor('#E0E0E0')
            .selectedColor('#FFB300')
            .blockColor('#FF6D00')
            .onChange((value: number) => {
              try {
                this.currentRating = value
                this.resultText = `当前评分: ${value.toFixed(1)} / 5.0`
                this.eventLog = `滑块调整评分: ${value.toFixed(1)}`
              } catch (err) {
                this.eventLog = `错误: ${(err as BusinessError).message}`
              }
            })
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
          Text('contentModifier(modifier: ContentModifier<RatingConfiguration>)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('RatingConfiguration 包含:')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('  rating: number — 评分值')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('  indicator: boolean — 是否指示器')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('  stars: number — 星级总数')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('  stepSize: number — 评分步长')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('  triggerChange: Callback<number> — 触发评分变化')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('元服务兼容: contentModifier API 12+ 可用')
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

  private getRatingDescription(rating: number): string {
    if (rating <= 1) {
      return '非常不满意'
    } else if (rating <= 2) {
      return '不太满意'
    } else if (rating <= 3) {
      return '一般'
    } else if (rating <= 4) {
      return '比较满意'
    } else {
      return '非常满意'
    }
  }
}
