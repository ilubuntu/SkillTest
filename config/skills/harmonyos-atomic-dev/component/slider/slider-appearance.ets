/**
 * slider-appearance — Slider 外观自定义
 * 展示 blockColor / trackColor / selectedColor / trackThickness / blockSize 等外观属性
 * 元服务兼容性：外观属性均 API 7+ 可用
 */
@ComponentV2
export struct SliderAppearance {
  @Local resultText: string = '滑动滑块查看自定义效果'
  @Local volumeValue: number = 60
  @Local brightnessValue: number = 50

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('Slider 外观自定义')
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

        // 音量调节场景
        Text('场景: 音量调节')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Row({ space: 12 }) {
          Text('🔇')
            .fontSize(18)
          Slider({
            value: this.volumeValue,
            min: 0,
            max: 100,
            step: 1,
            style: SliderStyle.OutSet
          })
            .layoutWeight(1)
            .blockColor('#007DFF')
            .trackColor('#D6D6D6')
            .selectedColor('#007DFF')
            .onChange((value: number) => {
              try {
                this.volumeValue = Math.round(value)
                const icon = this.volumeValue === 0 ? '🔇' : this.volumeValue < 50 ? '🔉' : '🔊'
                this.resultText = `${icon} 音量: ${this.volumeValue}%`
              } catch (err) {
                this.resultText = `错误: ${(err as BusinessError).message}`
              }
            })
          Text('🔊')
            .fontSize(18)
        }
        .width('90%')

        // 亮度调节场景
        Text('场景: 亮度调节')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Slider({
          value: this.brightnessValue,
          min: 0,
          max: 100,
          step: 1,
          style: SliderStyle.OutSet
        })
          .width('90%')
          .blockColor('#FFB800')
          .trackColor('#3C3C3C')
          .selectedColor('#FFB800')
          .onChange((value: number) => {
            try {
              this.brightnessValue = Math.round(value)
              this.resultText = `亮度: ${this.brightnessValue}%`
            } catch (err) {
              this.resultText = `错误: ${(err as BusinessError).message}`
            }
          })

        // 自定义滑块大小
        Text('自定义滑块大小 (blockSize)')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Slider({
          value: 50,
          min: 0,
          max: 100,
          style: SliderStyle.OutSet
        })
          .width('90%')
          .blockSize({ width: 30, height: 30 })
          .blockColor('#FF6B00')
          .trackColor('#E0E0E0')
          .selectedColor('#FF6B00')

        // 粗轨道样式
        Text('粗轨道样式 (trackThickness)')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Slider({
          value: 70,
          min: 0,
          max: 100,
          style: SliderStyle.InSet
        })
          .width('90%')
          .trackThickness(20)
          .blockColor('#FFFFFF')
          .trackColor('#C8E6C9')
          .selectedColor('#4CAF50')

        // 细轨道样式
        Text('细轨道样式')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Slider({
          value: 30,
          min: 0,
          max: 100,
          style: SliderStyle.OutSet
        })
          .width('90%')
          .trackThickness(4)
          .blockColor('#E91E63')
          .trackColor('#E0E0E0')
          .selectedColor('#E91E63')

        // 圆角轨道
        Text('圆角轨道 (trackBorderRadius)')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Slider({
          value: 45,
          min: 0,
          max: 100,
          style: SliderStyle.NONE
        })
          .width('90%')
          .trackThickness(12)
          .trackColor('#E0E0E0')
          .selectedColor('#9C27B0')
          .trackBorderRadius(6)

        // API 说明区
        Column() {
          Text('API 说明')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 8 })
          Text('.blockColor(color) — 滑块颜色')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('.trackColor(color) — 轨道背景色')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('.selectedColor(color) — 已选中轨道颜色')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('.trackThickness(number) — 轨道厚度 (vp)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('.blockSize({ width, height }) — 滑块尺寸')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('.blockBorderColor(color) — 滑块边框颜色')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('.blockBorderWidth(number) — 滑块边框宽度')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('.trackBorderRadius(number) — 轨道圆角')
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
