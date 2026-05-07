/**
 * column-nested — Column 嵌套布局
 * 展示 Column 嵌套 Row、Blank 自适应拉伸、layoutWeight 权重分配
 * 元服务兼容性：基础布局能力 API 7+，元服务 API 11+ 可用
 */
@ComponentV2
export struct ColumnNested {
  @Local resultText: string = '展示 Column 嵌套布局场景'
  @Local weightRatio: string = '1:1:1'

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('Column 嵌套布局')
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

        // 场景1：Column + Row 组合
        Text('场景1: Column + Row 经典组合')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Column() {
          // 标题行
          Row() {
            Text('标题文字')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
            Blank()
            Text('更多 >')
              .fontSize(13)
              .fontColor('#007DFF')
          }
          .width('100%')
          .padding({ left: 12, right: 12 })

          // 内容行
          Row({ space: 8 }) {
            Column() {
              Text('卡片A')
                .fontSize(13)
            }
            .layoutWeight(1)
            .height(60)
            .backgroundColor(0xF5DEB3)
            .borderRadius(6)
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)

            Column() {
              Text('卡片B')
                .fontSize(13)
            }
            .layoutWeight(1)
            .height(60)
            .backgroundColor(0xD2B48C)
            .borderRadius(6)
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)

            Column() {
              Text('卡片C')
                .fontSize(13)
            }
            .layoutWeight(1)
            .height(60)
            .backgroundColor(0xF5DEB3)
            .borderRadius(6)
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
          }
          .width('100%')
          .padding({ left: 12, right: 12, top: 8 })
        }
        .width('90%')
        .padding(12)
        .backgroundColor('#FFFFFF')
        .borderRadius(8)
        .shadow({ radius: 2, color: '#33000000', offsetY: 1 })

        // 场景2：Blank 自适应拉伸
        Text('场景2: Blank 自适应拉伸')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Column({ space: 8 }) {
          Row() {
            Text('蓝牙')
              .fontSize(15)
            Blank()
            Toggle({ type: ToggleType.Switch, isOn: true })
              .onChange((isOn: boolean) => {
                this.resultText = `蓝牙开关: ${isOn ? '开启' : '关闭'}`
              })
          }
          .width('100%')
          .padding({ left: 12, right: 12 })
          .height(44)
          .backgroundColor(0xFFFFFF)
          .borderRadius(8)

          Row() {
            Text('Wi-Fi')
              .fontSize(15)
            Blank()
            Toggle({ type: ToggleType.Switch, isOn: false })
              .onChange((isOn: boolean) => {
                this.resultText = `Wi-Fi 开关: ${isOn ? '开启' : '关闭'}`
              })
          }
          .width('100%')
          .padding({ left: 12, right: 12 })
          .height(44)
          .backgroundColor(0xFFFFFF)
          .borderRadius(8)
        }
        .width('90%')
        .padding(8)
        .backgroundColor('#F0F0F0')
        .borderRadius(8)

        // 场景3：layoutWeight 权重分配
        Text('场景3: layoutWeight 权重分配')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Row() {
          Button('1:1:1')
            .fontSize(12)
            .height(32)
            .layoutWeight(1)
            .backgroundColor(this.weightRatio === '1:1:1' ? '#007DFF' : '#CCCCCC')
            .onClick(() => { this.weightRatio = '1:1:1' })
          Button('1:2:1')
            .fontSize(12)
            .height(32)
            .layoutWeight(1)
            .backgroundColor(this.weightRatio === '1:2:1' ? '#007DFF' : '#CCCCCC')
            .onClick(() => { this.weightRatio = '1:2:1' })
          Button('2:5:3')
            .fontSize(12)
            .height(32)
            .layoutWeight(1)
            .backgroundColor(this.weightRatio === '2:5:3' ? '#007DFF' : '#CCCCCC')
            .onClick(() => { this.weightRatio = '2:5:3' })
        }
        .width('90%')

        Row() {
          Column() {
            Text(`${this.getWeights()[0]}`)
              .fontSize(13)
              .fontColor('#333333')
          }
          .layoutWeight(this.getWeights()[0])
          .height(50)
          .backgroundColor(0xF5DEB3)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)

          Column() {
            Text(`${this.getWeights()[1]}`)
              .fontSize(13)
              .fontColor('#333333')
          }
          .layoutWeight(this.getWeights()[1])
          .height(50)
          .backgroundColor(0xD2B48C)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)

          Column() {
            Text(`${this.getWeights()[2]}`)
              .fontSize(13)
              .fontColor('#333333')
          }
          .layoutWeight(this.getWeights()[2])
          .height(50)
          .backgroundColor(0xF5DEB3)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
        }
        .width('90%')
        .border({ width: 1, color: '#DDDDDD' })
        .borderRadius(6)

        // API 说明区
        Column() {
          Text('API 说明')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 8 })
          Text('Column 嵌套 Row 实现复杂布局')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('Blank() — 填充容器主轴方向空白空间')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('.layoutWeight(number) — 按权重分配剩余空间')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('建议减少嵌套层级以优化元服务性能')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('元服务：基础布局能力 API 11+ 可用')
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

  private getWeights(): number[] {
    switch (this.weightRatio) {
      case '1:2:1':
        return [1, 2, 1]
      case '2:5:3':
        return [2, 5, 3]
      default:
        return [1, 1, 1]
    }
  }
}
