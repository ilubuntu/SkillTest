/**
 * slider-basic — Slider 基本用法
 * 展示 Slider 组件的基本创建、值范围设置、onChange 事件（含 SliderChangeMode）
 * 元服务兼容性：Slider 基础组件 API 7+ 全部可用
 */
@ComponentV2
export struct SliderBasic {
  @Local sliderValue: number = 40
  @Local resultText: string = '当前值: 40'
  @Local eventLog: string = '等待操作...'

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('Slider 基本用法')
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

        // 基本滑动条 (0~100) + SliderChangeMode
        Text('基本滑动条 (0~100) + 事件模式')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Slider({
          value: this.sliderValue,
          min: 0,
          max: 100,
          step: 1,
          style: SliderStyle.OutSet
        })
          .width('90%')
          .onChange((value: number, mode: SliderChangeMode) => {
            try {
              this.sliderValue = Math.round(value)
              const modeStr = mode === SliderChangeMode.Begin ? 'Begin(开始滑动)' :
                mode === SliderChangeMode.Moving ? 'Moving(滑动中)' :
                mode === SliderChangeMode.End ? 'End(结束滑动)' :
                'Click(点击轨道)'
              this.resultText = `当前值: ${this.sliderValue}`
              this.eventLog = `mode: ${modeStr}, value: ${value.toFixed(2)}`
            } catch (err) {
              this.eventLog = `错误: ${(err as BusinessError).message}`
            }
          })

        // 自定义范围滑动条 (0~1 精度)
        Text('自定义范围 (0.0 ~ 1.0)')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Slider({
          value: 0.5,
          min: 0,
          max: 1,
          step: 0.01,
          style: SliderStyle.OutSet
        })
          .width('90%')
          .onChange((value: number) => {
            try {
              this.eventLog = `精度滑动 → value: ${value.toFixed(2)}`
            } catch (err) {
              this.eventLog = `错误: ${(err as BusinessError).message}`
            }
          })

        // 负值范围滑动条
        Text('负值范围 (-50 ~ 50)')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Slider({
          value: 0,
          min: -50,
          max: 50,
          step: 5,
          style: SliderStyle.OutSet
        })
          .width('90%')
          .onChange((value: number) => {
            try {
              this.eventLog = `负值范围 → value: ${value}`
            } catch (err) {
              this.eventLog = `错误: ${(err as BusinessError).message}`
            }
          })

        // SliderChangeMode 说明
        Column() {
          Text('SliderChangeMode 枚举值')
            .fontSize(13)
            .fontWeight(FontWeight.Medium)
            .width('100%')
            .margin({ bottom: 4 })
          Text('Begin(0) — 用户开始滑动')
            .fontSize(12)
            .fontColor('#333333')
            .width('100%')
          Text('Moving(1) — 用户正在滑动')
            .fontSize(12)
            .fontColor('#333333')
            .margin({ top: 2 })
            .width('100%')
          Text('End(2) — 用户结束滑动')
            .fontSize(12)
            .fontColor('#333333')
            .margin({ top: 2 })
            .width('100%')
          Text('Click(3) — 用户点击轨道')
            .fontSize(12)
            .fontColor('#333333')
            .margin({ top: 2 })
            .width('100%')
        }
        .width('90%')
        .backgroundColor('#E3F2FD')
        .borderRadius(8)
        .padding(12)

        // 重置按钮
        Button('重置为默认值')
          .width('90%')
          .height(40)
          .backgroundColor('#007DFF')
          .onClick(() => {
            this.sliderValue = 40
            this.resultText = '当前值: 40'
            this.eventLog = '已重置'
          })

        // API 说明区
        Column() {
          Text('API 说明')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 8 })
          Text('Slider({ value, min, max, step, style })')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('value: number — 当前值 (默认 0)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('min: number — 最小值 (默认 0)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('max: number — 最大值 (默认 100)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('step: number — 步长 (默认 0，连续)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('style: SliderStyle — 样式 (默认 OutSet)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('.onChange((value, mode: SliderChangeMode) => void)')
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
