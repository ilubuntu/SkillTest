/**
 * slider-style — Slider 样式对比
 * 展示 SliderStyle.OutSet / InSet / None 三种样式
 * 元服务兼容性：三种样式均 API 7+ 可用
 */
@ComponentV2
export struct SliderStyleDemo {
  @Local outSetValue: number = 40
  @Local inSetValue: number = 60
  @Local noneSetValue: number = 80
  @Local resultText: string = '滑动任意滑块查看值变化'

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('Slider 样式对比')
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

        // OutSet 样式（滑块在轨道上方）
        Text('SliderStyle.OutSet（滑块在轨道外）')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Text(`值: ${this.outSetValue}`)
          .fontSize(12)
          .fontColor('#666666')
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16 })

        Slider({
          value: this.outSetValue,
          min: 0,
          max: 100,
          step: 1,
          style: SliderStyle.OutSet
        })
          .width('90%')
          .onChange((value: number) => {
            try {
              this.outSetValue = Math.round(value)
              this.resultText = `OutSet 值: ${this.outSetValue}\n滑块中心与滑轨端点对齐`
            } catch (err) {
              this.resultText = `错误: ${(err as BusinessError).message}`
            }
          })

        // InSet 样式（滑块在轨道内部）
        Text('SliderStyle.InSet（滑块在轨道内）')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Text(`值: ${this.inSetValue}`)
          .fontSize(12)
          .fontColor('#666666')
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16 })

        Slider({
          value: this.inSetValue,
          min: 0,
          max: 100,
          step: 1,
          style: SliderStyle.InSet
        })
          .width('90%')
          .trackThickness(30)
          .onChange((value: number) => {
            try {
              this.inSetValue = Math.round(value)
              this.resultText = `InSet 值: ${this.inSetValue}\n滑块与滑轨中心对齐`
            } catch (err) {
              this.resultText = `错误: ${(err as BusinessError).message}`
            }
          })

        // None 样式（无滑块）
        Text('SliderStyle.NONE（无滑块）')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Text(`值: ${this.noneSetValue}`)
          .fontSize(12)
          .fontColor('#666666')
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16 })

        Slider({
          value: this.noneSetValue,
          min: 0,
          max: 100,
          step: 1,
          style: SliderStyle.NONE
        })
          .width('90%')
          .trackThickness(8)
          .onChange((value: number) => {
            try {
              this.noneSetValue = Math.round(value)
              this.resultText = `None 值: ${this.noneSetValue}\n无滑块，仅显示进度轨道`
            } catch (err) {
              this.resultText = `错误: ${(err as BusinessError).message}`
            }
          })

        // 对齐方式说明
        Text('对齐方式说明')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Column() {
          Text('OutSet: 滑块中心与滑轨端点对齐')
            .fontSize(12)
            .fontColor('#333333')
            .width('100%')
          Text('InSet: 滑块与滑轨中心对齐（距端点半轨道高度）')
            .fontSize(12)
            .fontColor('#333333')
            .margin({ top: 4 })
            .width('100%')
          Text('None: 无滑块，适用于纯进度指示场景')
            .fontSize(12)
            .fontColor('#333333')
            .margin({ top: 4 })
            .width('100%')
        }
        .width('90%')
        .backgroundColor('#E3F2FD')
        .borderRadius(8)
        .padding(12)

        // API 说明区
        Column() {
          Text('API 说明')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 8 })
          Text('SliderStyle.OutSet — 滑块在滑轨上方（默认）')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('SliderStyle.InSet — 滑块在滑轨内部')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('SliderStyle.NONE — 无滑块')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('.trackThickness(number) — 轨道厚度')
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
