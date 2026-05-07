/**
 * flex-align — Flex 交叉轴对齐
 * 展示 FlexOptions.alignItems 属性：Auto、Start、Center、End、Stretch、Baseline
 * 元服务兼容性：alignItems API 7+，元服务 API 11+ 可用
 */
@ComponentV2
export struct FlexAlignDemo {
  @Local currentAlign: string = 'Start'
  @Local resultText: string = '当前对齐: ItemAlign.Start（交叉轴首部对齐，默认值）'

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('Flex 交叉轴对齐 (alignItems)')
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

        // 交叉轴对齐预览（不同高度子元素）
        Text('对齐预览（子元素高度不同）')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Flex({ alignItems: this.getAlignValue() }) {
          Text('1').width('33%').height(30).backgroundColor(0xF5DEB3).textAlign(TextAlign.Center)
          Text('2').width('33%').height(40).backgroundColor(0xD2B48C).textAlign(TextAlign.Center)
          Text('3').width('33%').height(50).backgroundColor(0xF5DEB3).textAlign(TextAlign.Center)
        }
        .size({ width: '90%', height: 80 })
        .padding(10)
        .backgroundColor(0xAFEEEE)
        .borderRadius(8)

        // 对齐控制按钮
        Text('切换交叉轴对齐方式')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Row({ space: 8 }) {
          Button('Auto')
            .fontSize(12)
            .width(65)
            .height(36)
            .backgroundColor(this.currentAlign === 'Auto' ? '#007DFF' : '#CCCCCC')
            .onClick(() => {
              this.currentAlign = 'Auto'
              this.resultText = '当前对齐: ItemAlign.Auto（使用容器默认配置）'
            })
          Button('Start')
            .fontSize(12)
            .width(65)
            .height(36)
            .backgroundColor(this.currentAlign === 'Start' ? '#007DFF' : '#CCCCCC')
            .onClick(() => {
              this.currentAlign = 'Start'
              this.resultText = '当前对齐: ItemAlign.Start（交叉轴首部对齐，默认值）'
            })
          Button('Center')
            .fontSize(12)
            .width(70)
            .height(36)
            .backgroundColor(this.currentAlign === 'Center' ? '#007DFF' : '#CCCCCC')
            .onClick(() => {
              this.currentAlign = 'Center'
              this.resultText = '当前对齐: ItemAlign.Center（交叉轴居中对齐）'
            })
        }

        Row({ space: 8 }) {
          Button('End')
            .fontSize(12)
            .width(65)
            .height(36)
            .backgroundColor(this.currentAlign === 'End' ? '#007DFF' : '#CCCCCC')
            .onClick(() => {
              this.currentAlign = 'End'
              this.resultText = '当前对齐: ItemAlign.End（交叉轴尾部对齐）'
            })
          Button('Stretch')
            .fontSize(12)
            .width(80)
            .height(36)
            .backgroundColor(this.currentAlign === 'Stretch' ? '#007DFF' : '#CCCCCC')
            .onClick(() => {
              this.currentAlign = 'Stretch'
              this.resultText = '当前对齐: ItemAlign.Stretch（交叉轴拉伸填充）'
            })
          Button('Baseline')
            .fontSize(12)
            .width(80)
            .height(36)
            .backgroundColor(this.currentAlign === 'Baseline' ? '#007DFF' : '#CCCCCC')
            .onClick(() => {
              this.currentAlign = 'Baseline'
              this.resultText = '当前对齐: ItemAlign.Baseline（文本基线对齐）'
            })
        }

        // Stretch 效果说明
        Text('Stretch 效果：不设高度时子元素拉伸到容器高度')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Flex({ alignItems: this.getAlignValue() }) {
          Text('1').width('33%').backgroundColor(0xAFEEEE).textAlign(TextAlign.Center)
          Text('2').width('33%').backgroundColor(0x00CED1).textAlign(TextAlign.Center)
          Text('3').width('33%').backgroundColor(0xAFEEEE).textAlign(TextAlign.Center)
        }
        .size({ width: '90%', height: 80 })
        .padding(10)
        .backgroundColor(0xAFEEEE)
        .borderRadius(8)

        // API 说明区
        Column() {
          Text('API 说明')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 8 })
          Text('FlexOptions.alignItems?: ItemAlign')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('ItemAlign.Auto — 使用容器默认配置')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('ItemAlign.Start — 交叉轴首部对齐（默认值）')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('ItemAlign.Center — 交叉轴居中对齐')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('ItemAlign.End — 交叉轴尾部对齐')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('ItemAlign.Stretch — 交叉轴拉伸填充（未设尺寸时拉伸到容器尺寸）')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('ItemAlign.Baseline — 文本基线对齐')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('子元素 alignSelf 属性可覆盖容器 alignItems 设置')
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

  private getAlignValue(): ItemAlign {
    if (this.currentAlign === 'Auto') {
      return ItemAlign.Auto
    } else if (this.currentAlign === 'Center') {
      return ItemAlign.Center
    } else if (this.currentAlign === 'End') {
      return ItemAlign.End
    } else if (this.currentAlign === 'Stretch') {
      return ItemAlign.Stretch
    } else if (this.currentAlign === 'Baseline') {
      return ItemAlign.Baseline
    }
    return ItemAlign.Start
  }
}
