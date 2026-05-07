/**
 * slider-direction — Slider 方向与反转
 * 展示 direction: Axis.Vertical / Axis.Horizontal 和 reverse 属性
 * 元服务兼容性：direction / reverse 均 API 7+ 可用
 */
@ComponentV2
export struct SliderDirection {
  @Local horizontalValue: number = 50
  @Local verticalValue: number = 50
  @Local reverseValue: number = 30
  @Local resultText: string = '滑动查看方向效果'

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('Slider 方向与反转')
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

        // 水平方向（默认）
        Text('水平方向 (Axis.Horizontal，默认)')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Text(`值: ${this.horizontalValue}`)
          .fontSize(12)
          .fontColor('#666666')
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16 })

        Slider({
          value: this.horizontalValue,
          min: 0,
          max: 100,
          step: 1,
          style: SliderStyle.OutSet,
          direction: Axis.Horizontal
        })
          .width('90%')
          .blockColor('#007DFF')
          .trackColor('#D6D6D6')
          .selectedColor('#007DFF')
          .onChange((value: number) => {
            try {
              this.horizontalValue = Math.round(value)
              this.resultText = `水平方向 → 值: ${this.horizontalValue}`
            } catch (err) {
              this.resultText = `错误: ${(err as BusinessError).message}`
            }
          })

        // 垂直方向
        Text('垂直方向 (Axis.Vertical)')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Text(`值: ${this.verticalValue}`)
          .fontSize(12)
          .fontColor('#666666')
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16 })

        Row() {
          Slider({
            value: this.verticalValue,
            min: 0,
            max: 100,
            step: 1,
            style: SliderStyle.OutSet,
            direction: Axis.Vertical
          })
            .height(180)
            .blockColor('#4CAF50')
            .trackColor('#D6D6D6')
            .selectedColor('#4CAF50')
            .onChange((value: number) => {
              try {
                this.verticalValue = Math.round(value)
                this.resultText = `垂直方向 → 值: ${this.verticalValue}`
              } catch (err) {
                this.resultText = `错误: ${(err as BusinessError).message}`
              }
            })

          Slider({
            value: this.verticalValue,
            min: 0,
            max: 100,
            step: 1,
            style: SliderStyle.InSet,
            direction: Axis.Vertical
          })
            .height(180)
            .trackThickness(20)
            .blockColor('#FFFFFF')
            .trackColor('#C8E6C9')
            .selectedColor('#4CAF50')
        }
        .width('90%')
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)
        .backgroundColor('#F5F5F5')
        .borderRadius(8)
        .padding(16)

        // 反转方向
        Text('反转方向 (reverse: true)')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Text(`值: ${this.reverseValue}`)
          .fontSize(12)
          .fontColor('#666666')
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16 })

        Slider({
          value: this.reverseValue,
          min: 0,
          max: 100,
          step: 5,
          style: SliderStyle.OutSet,
          reverse: true
        })
          .width('90%')
          .blockColor('#E91E63')
          .trackColor('#D6D6D6')
          .selectedColor('#E91E63')
          .onChange((value: number) => {
            try {
              this.reverseValue = Math.round(value)
              this.resultText = `反转方向 → 值: ${this.reverseValue}（滑块从右向左）`
            } catch (err) {
              this.resultText = `错误: ${(err as BusinessError).message}`
            }
          })

        // 反转说明
        Column() {
          Text('reverse: true — 滑块从右向左滑动（水平）或从下向上（垂直）')
            .fontSize(12)
            .fontColor('#333333')
            .width('100%')
          Text('direction: Axis.Vertical — 垂直方向滑动')
            .fontSize(12)
            .fontColor('#333333')
            .margin({ top: 4 })
            .width('100%')
          Text('direction + reverse 可组合使用')
            .fontSize(12)
            .fontColor('#333333')
            .margin({ top: 4 })
            .width('100%')
        }
        .width('90%')
        .backgroundColor('#E3F2FD')
        .borderRadius(8)
        .padding(12)

        // 重置按钮
        Button('重置')
          .width('90%')
          .height(40)
          .backgroundColor('#007DFF')
          .onClick(() => {
            this.horizontalValue = 50
            this.verticalValue = 50
            this.reverseValue = 30
            this.resultText = '已重置'
          })

        // API 说明区
        Column() {
          Text('API 说明')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 8 })
          Text('Slider({ ..., direction?: Axis, reverse?: boolean })')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('direction: Axis.Horizontal | Axis.Vertical')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('reverse: boolean — 是否反转滑动方向')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('元服务兼容: API 7+ 全部可用')
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
