/**
 * list-direction — 列表布局方向
 * 展示 List listDirection 属性：垂直/水平布局切换
 * 元服务兼容性：listDirection API 7+，元服务 API 11+ 可用
 */
@ComponentV2
export struct ListDirection {
  @Local isVertical: boolean = true
  @Local resultText: string = '当前方向: 垂直 (Axis.Vertical)'

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('列表布局方向')
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

        // 列表预览
        Text('列表预览')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        List({ space: 8 }) {
          ForEach(['新闻', '音乐', '视频', '阅读', '购物', '旅行', '美食', '运动'],
            (item: string, index?: number) => {
              ListItem() {
                Column() {
                  Text(`${(index ?? 0) + 1}`)
                    .fontSize(20)
                    .fontColor('#FFFFFF')
                    .width(40)
                    .height(40)
                    .textAlign(TextAlign.Center)
                    .borderRadius(20)
                    .backgroundColor('#2196F3')

                  Text(item)
                    .fontSize(14)
                    .margin({ top: 6 })
                }
                .justifyContent(FlexAlign.Center)
                .alignItems(HorizontalAlign.Center)
                .width(this.isVertical ? '100%' : 100)
                .height(this.isVertical ? 80 : 120)
                .padding(8)
                .backgroundColor('#FFFFFF')
                .borderRadius(8)
              }
            }, (item: string) => item)
        }
        .listDirection(this.isVertical ? Axis.Vertical : Axis.Horizontal)
        .width('90%')
        .height(this.isVertical ? 320 : 160)
        .borderRadius(8)
        .backgroundColor('#F0F0F0')
        .padding(8)

        // 方向控制
        Text('切换方向')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Row({ space: 8 }) {
          Button('垂直')
            .fontSize(13)
            .width(80)
            .height(36)
            .onClick(() => {
              this.isVertical = true
              this.resultText = '当前方向: 垂直 (Axis.Vertical)'
            })
          Button('水平')
            .fontSize(13)
            .width(80)
            .height(36)
            .onClick(() => {
              this.isVertical = false
              this.resultText = '当前方向: 水平 (Axis.Horizontal)'
            })
        }

        // API 说明区
        Column() {
          Text('API 说明')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 8 })
          Text('.listDirection(axis: Axis)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('Axis.Vertical — 主轴垂直，垂直滚动（默认）')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('Axis.Horizontal — 主轴水平，水平滚动')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('元服务：API 11+ 可用')
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
