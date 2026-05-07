/**
 * divider-basic — Divider 分隔线基础用法
 * 展示水平/垂直分隔线、颜色/粗细/端点样式自定义
 * 元服务兼容性：Divider 从 API 7+ 可用，属性均支持
 */
@ComponentV2
export struct DividerBasic {
  @Local dividerColor: string = '#3C3C3C'
  @Local strokeWidth: number = 1
  @Local isVertical: boolean = false
  @Local lineCapStyle: LineCapStyle = LineCapStyle.Butt
  @Local resultLog: string = '等待操作...'

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('Divider 分隔线基础用法')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20, bottom: 10 })

        // 结果展示区
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

        // ---- 1. 基础水平分隔线 ----
        Text('1. 埞础水平分隔线')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Column() {
          Text('上方内容')
            .fontSize(14)
            .width('100%')
            .padding(8)
          Divider()
          Text('下方内容')
            .fontSize(14)
            .width('100%')
            .padding(8)
        }
        .width('85%')
        .backgroundColor('#FFFFFF')
        .borderRadius(8)
        .padding(12)

        // ---- 2. 垂直分隔线 ----
        Text('2. 垂直分隔线')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 12 })

        Row({ space: 0 }) {
          Text('左侧')
            .fontSize(14)
            .padding(8)
          Divider()
            .vertical(true)
            .height(40)
          Text('中间')
            .fontSize(14)
            .padding(8)
          Divider()
            .vertical(true)
            .height(40)
          Text('右侧')
            .fontSize(14)
            .padding(8)
        }
        .width('85%')
        .justifyContent(FlexAlign.Center)
        .backgroundColor('#FFFFFF')
        .borderRadius(8)
        .padding(12)

        // ---- 3. 自定义颜色和粗细 ----
        Text('3. 自定义颜色和粗细')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 12 })

        // 参数控制区
        Row({ space: 12 }) {
          Button(`粗细: ${this.strokeWidth}vp`)
            .fontSize(12)
            .onClick(() => {
              this.strokeWidth = this.strokeWidth >= 5 ? 1 : this.strokeWidth + 1
              this.resultLog = `strokeWidth = ${this.strokeWidth}vp`
            })
          Button(this.isVertical ? '切换水平' : '切换垂直')
            .fontSize(12)
            .backgroundColor('#FF6B00')
            .onClick(() => {
              this.isVertical = !this.isVertical
              this.resultLog = `方向: ${this.isVertical ? '垂直' : '水平'}`
            })
        }
        .width('90%')
        .justifyContent(FlexAlign.Center)

        Row({ space: 8 }) {
          Button('黑色')
            .fontSize(11)
            .backgroundColor('#3C3C3C')
            .onClick(() => { this.dividerColor = '#3C3C3C' })
          Button('红色')
            .fontSize(11)
            .backgroundColor('#FA2A2D')
            .onClick(() => { this.dividerColor = '#FA2A2D' })
          Button('蓝色')
            .fontSize(11)
            .backgroundColor('#007DFF')
            .onClick(() => { this.dividerColor = '#007DFF' })
          Button('灰色')
            .fontSize(11)
            .backgroundColor('#CCCCCC')
            .onClick(() => { this.dividerColor = '#CCCCCC' })
        }
        .width('90%')
        .justifyContent(FlexAlign.Center)

        Column() {
          if (this.isVertical) {
            Row() {
              Text('内容 A')
                .fontSize(14)
                .padding(8)
              Divider()
                .vertical(true)
                .height(40)
                .color(this.dividerColor)
                .strokeWidth(this.strokeWidth)
              Text('内容 B')
                .fontSize(14)
                .padding(8)
            }
            .width('100%')
            .justifyContent(FlexAlign.Center)
          } else {
            Column() {
              Text('上方区域')
                .fontSize(14)
                .width('100%')
                .padding(8)
              Divider()
                .color(this.dividerColor)
                .strokeWidth(this.strokeWidth)
              Text('下方区域')
                .fontSize(14)
                .width('100%')
                .padding(8)
            }
            .width('100%')
          }
        }
        .width('85%')
        .backgroundColor('#FFFFFF')
        .borderRadius(8)
        .padding(12)

        // ---- 4. lineCap 端点样式 ----
        Text('4. lineCap 端点样式')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 12 })

        Row({ space: 12 }) {
          Button('Butt')
            .fontSize(12)
            .backgroundColor(this.lineCapStyle === LineCapStyle.Butt ? '#007DFF' : '#999999')
            .onClick(() => {
              this.lineCapStyle = LineCapStyle.Butt
              this.resultLog = 'LineCapStyle.Butt — 平行端点'
            })
          Button('Round')
            .fontSize(12)
            .backgroundColor(this.lineCapStyle === LineCapStyle.Round ? '#007DFF' : '#999999')
            .onClick(() => {
              this.lineCapStyle = LineCapStyle.Round
              this.resultLog = 'LineCapStyle.Round — 半圆端点'
            })
          Button('Square')
            .fontSize(12)
            .backgroundColor(this.lineCapStyle === LineCapStyle.Square ? '#007DFF' : '#999999')
            .onClick(() => {
              this.lineCapStyle = LineCapStyle.Square
              this.resultLog = 'LineCapStyle.Square — 半方端点'
            })
        }
        .width('90%')
        .justifyContent(FlexAlign.Center)

        Column() {
          Divider()
            .color('#FA2A2D')
            .strokeWidth(4)
            .lineCap(this.lineCapStyle)
          Text(`当前: ${this.lineCapStyle === LineCapStyle.Butt ? 'Butt' : this.lineCapStyle === LineCapStyle.Round ? 'Round' : 'Square'}`)
            .fontSize(12)
            .fontColor('#666666')
            .margin({ top: 4 })
        }
        .width('85%')
        .backgroundColor('#FFFFFF')
        .borderRadius(8)
        .padding(12)

        // ---- 5. 实际应用场景 ----
        Text('5. 实际应用场景')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 12 })

        // 列表分隔
        Column() {
          Row() {
            Text('设置项 1')
              .fontSize(14)
              .layoutWeight(1)
            Text('>')
              .fontSize(14)
              .fontColor('#999999')
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 12, bottom: 12 })

          Divider().color('#F0F0F0').strokeWidth(0.5)

          Row() {
            Text('设置项 2')
              .fontSize(14)
              .layoutWeight(1)
            Text('>')
              .fontSize(14)
              .fontColor('#999999')
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 12, bottom: 12 })

          Divider().color('#F0F0F0').strokeWidth(0.5)

          Row() {
            Text('设置项 3')
              .fontSize(14)
              .layoutWeight(1)
            Text('>')
              .fontSize(14)
              .fontColor('#999999')
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 12, bottom: 12 })
        }
        .width('85%')
        .backgroundColor('#FFFFFF')
        .borderRadius(8)
        .clip(true)

        // 带缩进的分隔线
        Column() {
          Text('带缩进的分隔线:')
            .fontSize(12)
            .fontColor('#666666')
            .margin({ bottom: 4 })
          Divider()
            .color('#E0E0E0')
            .strokeWidth(1)
            .margin({ left: 24, right: 24 })
        }
        .width('85%')
        .padding(12)

        // API 说明区
        Column() {
          Text('API 说明')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 8 })
          Text('Divider() — 创建分隔线')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('  .vertical(bool) — 是否垂直，默认 false')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('  .color(ResourceColor) — 分隔线颜色')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('  .strokeWidth(Length) — 分隔线粗细')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('  .lineCap(LineCapStyle) — Butt | Round | Square')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('元服务API: API 7+ 完全可用')
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
