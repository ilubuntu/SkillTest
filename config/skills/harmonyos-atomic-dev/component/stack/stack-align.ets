/**
 * stack-align — Stack 对齐方式
 * 展示 Stack alignContent 参数的 9 种对齐方式
 * 元服务兼容性：alignContent API 7+，元服务 API 11+ 可用
 */

class AlignItem {
  name: string = ''
  value: Alignment = Alignment.Center
}

@ComponentV2
export struct StackAlign {
  @Local resultText: string = '当前对齐: Center'
  @Local currentAlign: Alignment = Alignment.Center

  private alignList: AlignItem[] = []

  aboutToAppear(): void {
    const items: string[] = ['TopStart', 'Top', 'TopEnd', 'Start', 'Center', 'End', 'BottomStart', 'Bottom', 'BottomEnd']
    const values: Alignment[] = [
      Alignment.TopStart, Alignment.Top, Alignment.TopEnd,
      Alignment.Start, Alignment.Center, Alignment.End,
      Alignment.BottomStart, Alignment.Bottom, Alignment.BottomEnd
    ]
    for (let i = 0; i < items.length; i++) {
      const item = new AlignItem()
      item.name = items[i]
      item.value = values[i]
      this.alignList.push(item)
    }
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('Stack 对齐方式')
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

        // 对齐预览
        Text('对齐预览')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Stack({ alignContent: this.currentAlign }) {
          Column() {}
          .width('100%')
          .height('100%')
          .backgroundColor('#BBDEFB')

          Column() {}
          .width('50%')
          .height('50%')
          .backgroundColor('#90CAF9')

          Column() {}
          .width(60)
          .height(60)
          .backgroundColor('#42A5F5')
          .borderRadius(8)
        }
        .width('90%')
        .height(240)
        .backgroundColor('#E3F2FD')
        .borderRadius(12)
        .border({ width: 1, color: '#90CAF9' })

        // 九宫格按钮
        Text('选择对齐方式')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        // 第一行
        Row({ space: 8 }) {
          Button('↖ TopStart')
            .fontSize(11)
            .layoutWeight(1)
            .height(36)
            .backgroundColor(this.currentAlign === Alignment.TopStart ? '#1976D2' : '#E0E0E0')
            .fontColor(this.currentAlign === Alignment.TopStart ? '#FFFFFF' : '#333333')
            .onClick(() => this.selectAlign('TopStart', Alignment.TopStart))
          Button('↑ Top')
            .fontSize(11)
            .layoutWeight(1)
            .height(36)
            .backgroundColor(this.currentAlign === Alignment.Top ? '#1976D2' : '#E0E0E0')
            .fontColor(this.currentAlign === Alignment.Top ? '#FFFFFF' : '#333333')
            .onClick(() => this.selectAlign('Top', Alignment.Top))
          Button('↗ TopEnd')
            .fontSize(11)
            .layoutWeight(1)
            .height(36)
            .backgroundColor(this.currentAlign === Alignment.TopEnd ? '#1976D2' : '#E0E0E0')
            .fontColor(this.currentAlign === Alignment.TopEnd ? '#FFFFFF' : '#333333')
            .onClick(() => this.selectAlign('TopEnd', Alignment.TopEnd))
        }
        .width('90%')

        // 第二行
        Row({ space: 8 }) {
          Button('← Start')
            .fontSize(11)
            .layoutWeight(1)
            .height(36)
            .backgroundColor(this.currentAlign === Alignment.Start ? '#1976D2' : '#E0E0E0')
            .fontColor(this.currentAlign === Alignment.Start ? '#FFFFFF' : '#333333')
            .onClick(() => this.selectAlign('Start', Alignment.Start))
          Button('Center')
            .fontSize(11)
            .layoutWeight(1)
            .height(36)
            .backgroundColor(this.currentAlign === Alignment.Center ? '#1976D2' : '#E0E0E0')
            .fontColor(this.currentAlign === Alignment.Center ? '#FFFFFF' : '#333333')
            .onClick(() => this.selectAlign('Center', Alignment.Center))
          Button('→ End')
            .fontSize(11)
            .layoutWeight(1)
            .height(36)
            .backgroundColor(this.currentAlign === Alignment.End ? '#1976D2' : '#E0E0E0')
            .fontColor(this.currentAlign === Alignment.End ? '#FFFFFF' : '#333333')
            .onClick(() => this.selectAlign('End', Alignment.End))
        }
        .width('90%')

        // 第三行
        Row({ space: 8 }) {
          Button('↙ BottomStart')
            .fontSize(11)
            .layoutWeight(1)
            .height(36)
            .backgroundColor(this.currentAlign === Alignment.BottomStart ? '#1976D2' : '#E0E0E0')
            .fontColor(this.currentAlign === Alignment.BottomStart ? '#FFFFFF' : '#333333')
            .onClick(() => this.selectAlign('BottomStart', Alignment.BottomStart))
          Button('↓ Bottom')
            .fontSize(11)
            .layoutWeight(1)
            .height(36)
            .backgroundColor(this.currentAlign === Alignment.Bottom ? '#1976D2' : '#E0E0E0')
            .fontColor(this.currentAlign === Alignment.Bottom ? '#FFFFFF' : '#333333')
            .onClick(() => this.selectAlign('Bottom', Alignment.Bottom))
          Button('↘ BottomEnd')
            .fontSize(11)
            .layoutWeight(1)
            .height(36)
            .backgroundColor(this.currentAlign === Alignment.BottomEnd ? '#1976D2' : '#E0E0E0')
            .fontColor(this.currentAlign === Alignment.BottomEnd ? '#FFFFFF' : '#333333')
            .onClick(() => this.selectAlign('BottomEnd', Alignment.BottomEnd))
        }
        .width('90%')

        // API 说明区
        Column() {
          Text('API 说明')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 8 })
          Text('Stack({ alignContent: Alignment })')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('.alignContent(value: Alignment) — 属性方式设置')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('Alignment 枚举: TopStart/Top/TopEnd/Start/Center/End/BottomStart/Bottom/BottomEnd')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('默认值: Alignment.Center，非法值按默认值处理')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('元服务：API 7+ 可用')
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

  private selectAlign(name: string, align: Alignment): void {
    this.currentAlign = align
    this.resultText = `当前对齐: ${name}`
  }
}
