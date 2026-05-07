/**
 * slider-step-tips — Slider 步长与提示
 * 展示 showSteps / showTips / step 等属性的用法
 * 元服务兼容性：showSteps / showTips / step 均 API 7+ 可用
 */
@ComponentV2
export struct SliderStepTips {
  @Local resultText: string = '滑动查看步长和提示效果'
  @Local stepValue: number = 0
  @Local continuousValue: number = 50

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('Slider 步长与提示')
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

        // 连续模式 (step=0)
        Text('连续模式 (step=0，默认)')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Slider({
          value: this.continuousValue,
          min: 0,
          max: 100,
          step: 0,
          style: SliderStyle.OutSet
        })
          .width('90%')
          .showTips(false)
          .onChange((value: number) => {
            try {
              this.continuousValue = Math.round(value)
              this.resultText = `连续值: ${value.toFixed(1)}`
            } catch (err) {
              this.resultText = `错误: ${(err as BusinessError).message}`
            }
          })

        // 步长 10
        Text('步长=10 + showSteps(true)')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Slider({
          value: this.stepValue,
          min: 0,
          max: 100,
          step: 10,
          style: SliderStyle.OutSet
        })
          .width('90%')
          .showSteps(true)
          .showTips(true)
          .stepColor('#007DFF')
          .onChange((value: number) => {
            try {
              this.stepValue = Math.round(value)
              this.resultText = `步长模式 → 值: ${this.stepValue} (步长10)`
            } catch (err) {
              this.resultText = `错误: ${(err as BusinessError).message}`
            }
          })

        // 步长 25
        Text('步长=25 + showTips(true)')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Slider({
          value: 50,
          min: 0,
          max: 100,
          step: 25,
          style: SliderStyle.OutSet
        })
          .width('90%')
          .showSteps(true)
          .showTips(true)
          .onChange((value: number) => {
            try {
              this.resultText = `大步长模式 → 值: ${Math.round(value)} (步长25)`
            } catch (err) {
              this.resultText = `错误: ${(err as BusinessError).message}`
            }
          })

        // 不显示步长刻度
        Text('步长=20 + 不显示刻度')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Slider({
          value: 40,
          min: 0,
          max: 100,
          step: 20,
          style: SliderStyle.OutSet
        })
          .width('90%')
          .showSteps(false)
          .showTips(false)
          .onChange((value: number) => {
            try {
              this.resultText = `隐藏刻度 → 值: ${Math.round(value)}`
            } catch (err) {
              this.resultText = `错误: ${(err as BusinessError).message}`
            }
          })

        // showTips 气泡提示
        Text('showTips 气泡提示说明')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Column() {
          Text('showTips(true): 滑动时在滑块上方显示气泡，显示当前值')
            .fontSize(12)
            .fontColor('#333333')
            .width('100%')
          Text('showSteps(true): 在轨道上显示步长刻度线')
            .fontSize(12)
            .fontColor('#333333')
            .margin({ top: 4 })
            .width('100%')
          Text('stepColor: 可自定义刻度线颜色')
            .fontSize(12)
            .fontColor('#333333')
            .margin({ top: 4 })
            .width('100%')
        }
        .width('90%')
        .backgroundColor('#E8F5E9')
        .borderRadius(8)
        .padding(12)

        // 重置按钮
        Button('重置步长模式')
          .width('90%')
          .height(40)
          .backgroundColor('#007DFF')
          .onClick(() => {
            this.stepValue = 0
            this.continuousValue = 50
            this.resultText = '已重置'
          })

        // API 说明区
        Column() {
          Text('API 说明')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 8 })
          Text('step: number — 滑动步长 (默认 0，连续)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('.showSteps(boolean) — 是否显示步长刻度')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('.showTips(boolean) — 是否显示气泡提示')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('.stepColor(color) — 刻度线颜色')
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
