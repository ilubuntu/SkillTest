/**
 * list-lanes — 多列布局
 * 展示 List lanes 属性：固定列数 / LengthConstrain 自适应列数
 * 展示 alignListItem 交叉轴对齐方式
 * 元服务兼容性：lanes API 9+，alignListItem API 9+，元服务 API 11+ 可用
 */
@ComponentV2
export struct ListLanes {
  @Local laneCount: number = 1
  @Local alignMode: ListItemAlign = ListItemAlign.Start
  @Local resultText: string = '列数: 1 | 对齐: Start'

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('多列布局')
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
          ForEach([
            '华为', '小米', '苹果', '三星', 'OPPO', 'vivo',
            '荣耀', '一加', '魅族', '中兴', '联想', '努比亚'
          ], (item: string, index?: number) => {
            ListItem() {
              Column() {
                Text(`${(index ?? 0) + 1}`)
                  .fontSize(18)
                  .fontColor('#FFFFFF')
                  .textAlign(TextAlign.Center)
                Text(item)
                  .fontSize(14)
                  .textAlign(TextAlign.Center)
                  .margin({ top: 4 })
              }
              .width('100%')
              .height(80)
              .justifyContent(FlexAlign.Center)
              .backgroundColor('#FFFFFF')
              .borderRadius(8)
              .padding(8)
            }
          }, (item: string) => item)
        }
        .lanes(this.laneCount)
        .alignListItem(this.alignMode)
        .width('90%')
        .height(300)
        .borderRadius(8)
        .backgroundColor('#F0F0F0')
        .padding(8)

        // 列数控制
        Text('列数')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Row({ space: 8 }) {
          Button('1列')
            .fontSize(13)
            .width(60)
            .height(36)
            .onClick(() => {
              this.laneCount = 1
              this.updateResult()
            })
          Button('2列')
            .fontSize(13)
            .width(60)
            .height(36)
            .onClick(() => {
              this.laneCount = 2
              this.updateResult()
            })
          Button('3列')
            .fontSize(13)
            .width(60)
            .height(36)
            .onClick(() => {
              this.laneCount = 3
              this.updateResult()
            })
          Button('4列')
            .fontSize(13)
            .width(60)
            .height(36)
            .onClick(() => {
              this.laneCount = 4
              this.updateResult()
            })
        }

        // 对齐方式
        Text('交叉轴对齐')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Row({ space: 8 }) {
          Button('Start')
            .fontSize(13)
            .width(70)
            .height(36)
            .onClick(() => {
              this.alignMode = ListItemAlign.Start
              this.updateResult()
            })
          Button('Center')
            .fontSize(13)
            .width(70)
            .height(36)
            .onClick(() => {
              this.alignMode = ListItemAlign.Center
              this.updateResult()
            })
          Button('End')
            .fontSize(13)
            .width(70)
            .height(36)
            .onClick(() => {
              this.alignMode = ListItemAlign.End
              this.updateResult()
            })
        }

        // API 说明区
        Column() {
          Text('API 说明')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 8 })
          Text('.lanes(value: number | LengthConstrain)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('.alignListItem(align: ListItemAlign)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('lanes: 交叉轴排列的列表项数量，默认 1')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('LengthConstrain: { minLength, maxLength } 自适应列数')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('alignListItem: Start(默认) / Center / End')
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

  private updateResult(): void {
    const alignStr = this.alignMode === ListItemAlign.Start ? 'Start' :
      this.alignMode === ListItemAlign.Center ? 'Center' : 'End'
    this.resultText = `列数: ${this.laneCount} | 对齐: ${alignStr}`
  }
}
