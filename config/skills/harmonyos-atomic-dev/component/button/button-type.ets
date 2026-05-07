/**
 * button-type — Button 基本类型
 * 展示 Button 类型：Capsule（胶囊）、Circle（圆形）、Normal（普通）
 * 元服务兼容性：全部类型均可用（基础组件，API 8+）
 */
@ComponentV2
export struct ButtonBasicType {
  @Local clickLog: string = '等待点击...'

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('Button 基本类型')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20, bottom: 10 })

        // 结果展示区
        Column() {
          Text(this.clickLog)
            .fontSize(14)
            .fontColor('#333333')
            .width('100%')
            .padding(12)
        }
        .width('90%')
        .backgroundColor('#F5F5F5')
        .borderRadius(8)

        // Capsule 胶囊按钮（默认类型）
        Text('Capsule 胶囊按钮（默认）')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Button('Capsule', { type: ButtonType.Capsule, stateEffect: true })
          .width('90%')
          .height(40)
          .backgroundColor('#007DFF')
          .onClick(() => {
            this.clickLog = 'Capsule 按钮被点击'
          })

        // Circle 圆形按钮
        Text('Circle 圆形按钮')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Button('A', { type: ButtonType.Circle, stateEffect: true })
          .width(60)
          .height(60)
          .backgroundColor('#FF6B00')
          .onClick(() => {
            this.clickLog = 'Circle 按钮被点击'
          })

        // Normal 普通按钮
        Text('Normal 普通按钮')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Button('Normal', { type: ButtonType.Normal, stateEffect: true })
          .width('90%')
          .height(40)
          .borderRadius(8)
          .backgroundColor('#00B578')
          .onClick(() => {
            this.clickLog = 'Normal 按钮被点击'
          })

        // ROUNDED_RECTANGLE 不可用提示
        Text('RoundedRectangle 圆角矩形按钮')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Column() {
          Text('ButtonType.ROUNDED_RECTANGLE 在当前 SDK 版本不可用')
            .fontSize(13)
            .fontColor('#FF6B00')
            .fontWeight(FontWeight.Medium)
            .width('100%')
          Text('该类型需要更高 API 版本支持，可用 Normal + borderRadius(20) 模拟实现')
            .fontSize(12)
            .fontColor('#996600')
            .margin({ top: 4 })
            .width('100%')
        }
        .width('90%')
        .backgroundColor('#FFF3CD')
        .borderRadius(8)
        .padding(12)

        // 用 Normal + borderRadius 模拟圆角矩形
        Button('Normal + borderRadius(20) 模拟')
          .type(ButtonType.Normal)
          .borderRadius(20)
          .width('90%')
          .height(40)
          .backgroundColor('#E84026')
          .onClick(() => {
            this.clickLog = '圆角矩形按钮（Normal 模拟）被点击'
          })

        // API 说明区
        Column() {
          Text('API 说明')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 8 })
          Text('Button(label, options?)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('options.type: Capsule | Circle | Normal')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('options.stateEffect: boolean（是否开启点击效果）')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('Capsule: 圆角=高度/2, 不可修改 borderRadius')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('Circle: 圆形, 不可修改 borderRadius')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('Normal: 默认圆角=0, 支持自定义 borderRadius')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
        }
        .width('90%')
        .backgroundColor('#FFF9E6')
        .borderRadius(8)
        .padding(12)
        .margin({ top: 8 })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
  }
}
