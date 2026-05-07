/**
 * counter-basic — Counter 计数器基础用法
 * 展示增加/减少按钮、计数控制
 * 元服务兼容性：Counter 从 API 11+ 可用，无不可用 API
 */
@ComponentV2
export struct CounterBasic {
  @Local count: number = 0
  @Local resultLog: string = '等待操作...'

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('Counter 计数器基础用法')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20, bottom: 10 })

        Column() {
          Text(this.resultLog)
            .fontSize(14)
            .fontColor('#333333')
            .width('100%')
            .padding(12)
        }
        .width('90%')
        .backgroundColor('#F5F5F5')
        .borderRadius(8)

        Text('1. 基础计数器')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Counter() {
          Text(`${this.count}`)
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333333')
        }
        .enableInc(this.count < 10)
        .enableDec(this.count > 0)
        .onInc(() => {
          this.count++
          this.resultLog = `+1, 当前: ${this.count}`
        })
        .onDec(() => {
          this.count--
          this.resultLog = `-1, 当前: ${this.count}`
        })

        Text('enableInc: count < 10, enableDec: count > 0')
          .fontSize(12)
          .fontColor('#999999')
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16 })

        Text('2. 重置')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 12 })

        Button('重置计数')
          .fontSize(13)
          .backgroundColor('#999999')
          .onClick(() => {
            this.count = 0
            this.resultLog = '已重置为 0'
          })

        // API 说明区
        Column() {
          Text('API 说明')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 8 })
          Text('Counter() — 包含子组件的计数器容器')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('.enableInc(bool) — 启用增加按钮')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('.enableDec(bool) — 启用减少按钮')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('.onInc(() => void) — 点击增加回调')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('.onDec(() => void) — 点击减少回调')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('元服务API: API 11+ | 无不可用 API')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
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
