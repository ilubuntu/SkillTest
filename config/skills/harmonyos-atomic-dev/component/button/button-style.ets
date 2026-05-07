/**
 * button-style — Button 样式自定义
 * 展示 borderRadius、fontSize、fontColor、fontWeight、backgroundColor 等样式属性
 * 元服务兼容性：全部样式属性均可用（基础组件通用属性）
 */
@ComponentV2
export struct ButtonStyle {
  @Local currentStyle: string = '默认样式'
  @Local customRadius: number = 8
  @Local customFontSize: number = 16

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('Button 样式自定义')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20, bottom: 10 })

        // 结果展示区
        Column() {
          Text(this.currentStyle)
            .fontSize(14)
            .fontColor('#333333')
            .width('100%')
            .padding(12)
        }
        .width('90%')
        .backgroundColor('#F5F5F5')
        .borderRadius(8)

        // 参数控制区 — 圆角
        Text('边框圆角控制')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Row({ space: 8 }) {
          Button('4')
            .type(ButtonType.Normal)
            .width(50)
            .height(36)
            .borderRadius(4)
            .backgroundColor('#007DFF')
            .onClick(() => { this.customRadius = 4; this.currentStyle = 'borderRadius = 4' })
          Button('12')
            .type(ButtonType.Normal)
            .width(50)
            .height(36)
            .borderRadius(12)
            .backgroundColor('#007DFF')
            .onClick(() => { this.customRadius = 12; this.currentStyle = 'borderRadius = 12' })
          Button('20')
            .type(ButtonType.Normal)
            .width(50)
            .height(36)
            .borderRadius(20)
            .backgroundColor('#007DFF')
            .onClick(() => { this.customRadius = 20; this.currentStyle = 'borderRadius = 20' })
        }
        .width('90%')
        .justifyContent(FlexAlign.SpaceAround)

        // 当前圆角预览
        Button('当前圆角预览')
          .type(ButtonType.Normal)
          .width('90%')
          .height(40)
          .borderRadius(this.customRadius)
          .backgroundColor('#007DFF')

        // 字体大小控制
        Text('字体大小控制')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Row({ space: 8 }) {
          Button('12px')
            .type(ButtonType.Normal)
            .width(60)
            .height(36)
            .borderRadius(8)
            .fontSize(12)
            .backgroundColor('#FF6B00')
            .onClick(() => { this.customFontSize = 12; this.currentStyle = 'fontSize = 12' })
          Button('16px')
            .type(ButtonType.Normal)
            .width(60)
            .height(36)
            .borderRadius(8)
            .fontSize(16)
            .backgroundColor('#FF6B00')
            .onClick(() => { this.customFontSize = 16; this.currentStyle = 'fontSize = 16' })
          Button('22px')
            .type(ButtonType.Normal)
            .width(60)
            .height(36)
            .borderRadius(8)
            .fontSize(22)
            .backgroundColor('#FF6B00')
            .onClick(() => { this.customFontSize = 22; this.currentStyle = 'fontSize = 22' })
        }
        .width('90%')
        .justifyContent(FlexAlign.SpaceAround)

        // 字体颜色和粗细
        Text('字体颜色 + 粗细')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Button('Pink / Bold 800')
          .type(ButtonType.Normal)
          .width('90%')
          .height(40)
          .borderRadius(8)
          .fontSize(16)
          .fontColor(Color.Pink)
          .fontWeight(800)
          .backgroundColor('#333333')
          .onClick(() => { this.currentStyle = 'fontColor=Pink, fontWeight=800' })

        // 背景颜色
        Text('背景颜色')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Row({ space: 12 }) {
          Button('红')
            .width(60)
            .height(40)
            .backgroundColor('#E84026')
            .onClick(() => { this.currentStyle = 'backgroundColor = #E84026' })
          Button('绿')
            .width(60)
            .height(40)
            .backgroundColor('#00B578')
            .onClick(() => { this.currentStyle = 'backgroundColor = #00B578' })
          Button('蓝')
            .width(60)
            .height(40)
            .backgroundColor('#007DFF')
            .onClick(() => { this.currentStyle = 'backgroundColor = #007DFF' })
          Button('橙')
            .width(60)
            .height(40)
            .backgroundColor('#FF9800')
            .onClick(() => { this.currentStyle = 'backgroundColor = #FF9800' })
        }
        .width('90%')
        .justifyContent(FlexAlign.SpaceAround)

        // stateEffect 开关
        Text('stateEffect 点击效果')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Row({ space: 12 }) {
          Button('效果开启')
            .type(ButtonType.Normal)
            .borderRadius(8)
            .backgroundColor('#007DFF')
            .stateEffect(true)
            .onClick(() => { this.currentStyle = 'stateEffect = true（有按压反馈）' })
          Button('效果关闭')
            .type(ButtonType.Normal)
            .borderRadius(8)
            .backgroundColor('#007DFF')
            .stateEffect(false)
            .onClick(() => { this.currentStyle = 'stateEffect = false（无按压反馈）' })
        }

        // API 说明区
        Column() {
          Text('API 说明')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 8 })
          Text('.borderRadius(value) — 设置边框圆角')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('.fontSize(value) — 设置文字大小')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('.fontColor(value) — 设置文字颜色')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('.fontWeight(value) — 设置文字粗细')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('.backgroundColor(value) — 设置背景颜色')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('.stateEffect(boolean) — 是否开启按压效果')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
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
