/**
 * data_panel-basic — DataPanel 数据展示基础用法
 * 展示线性/环形数据面板、颜色、进度
 * 元服务兼容性：DataPanel 从 API 11+ 可用
 */
@ComponentV2
export struct DataPanelBasic {
  @Local resultLog: string = '等待操作...'
  @Local values: number[] = [20, 40, 30]

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('DataPanel 数据面板')
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

        // ---- 环形 ----
        Text('1. Circle 环形数据面板')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        DataPanel({
          values: this.values,
          max: 100,
          type: DataPanelType.Circle
        })
          .width(160)
          .height(160)
          .valueColors(['#007DFF', '#FF6B00', '#00B578'])
          .trackBackgroundColor('#E0E0E0')
          .strokeWidth(16)

        Text('values: [20, 40, 30], max: 100, strokeWidth: 16')
          .fontSize(12)
          .fontColor('#999999')
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16 })

        // ---- 线性 ----
        Text('2. Line 线性数据面板')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 12 })

        DataPanel({
          values: [50, 30, 20],
          max: 100,
          type: DataPanelType.Line
        })
          .width('90%')
          .height(20)
          .valueColors(['#FA2A2D', '#9B59B6', '#FFEAA7'])

        Text('values: [50, 30, 20], type: Line')
          .fontSize(12)
          .fontColor('#999999')
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16 })

        // ---- 关闭特效 ----
        Text('3. closeEffect 关闭特效')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 12 })

        DataPanel({
          values: [75],
          max: 100,
          type: DataPanelType.Circle
        })
          .width(120)
          .height(120)
          .valueColors(['#007DFF'])
          .trackBackgroundColor('#F0F0F0')
          .strokeWidth(12)
          .closeEffect(true)

        Text('closeEffect(true) 关闭加载动画')
          .fontSize(12)
          .fontColor('#999999')
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16 })

        // API 说明区
        Column() {
          Text('API 说明')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 8 })
          Text('DataPanel({ values, max, type })')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('  values: number[] (最多9项), max: number (默认100)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('  type: DataPanelType.Line | DataPanelType.Circle')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('.valueColors(Array<ResourceColor | LinearGradient>)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('.trackBackgroundColor() / .strokeWidth() / .closeEffect()')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('元服务API: API 11+ | contentModifier: API 12+')
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
