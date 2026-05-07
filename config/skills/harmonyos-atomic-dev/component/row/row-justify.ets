/**
 * row-justify — Row 主轴排列
 * 展示 Row justifyContent 属性：Start、Center、End、SpaceBetween、SpaceAround、SpaceEvenly
 * 元服务兼容性：justifyContent API 8+，元服务 API 11+ 可用
 */
@ComponentV2
export struct RowJustify {
  @Local currentJustify: string = 'Start'
  @Local resultText: string = '当前排列: FlexAlign.Start（默认值）'

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('Row 主轴排列 (justifyContent)')
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

        // 排列预览区
        Text('排列预览（子元素宽度 20%）')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Row() {
          Column().width('20%').height(40).backgroundColor(0xF5DEB3).borderRadius(6)
          Column().width('20%').height(40).backgroundColor(0xD2B48C).borderRadius(6)
          Column().width('20%').height(40).backgroundColor(0xF5DEB3).borderRadius(6)
        }
        .width('90%')
        .height(120)
        .padding(8)
        .border({ width: 1, color: '#DDDDDD' })
        .borderRadius(8)
        .justifyContent(this.getJustifyValue())

        // 排列控制按钮
        Text('切换排列方式')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
          Button('Start')
            .fontSize(12)
            .height(32)
            .margin(4)
            .backgroundColor(this.currentJustify === 'Start' ? '#007DFF' : '#CCCCCC')
            .onClick(() => {
              this.currentJustify = 'Start'
              this.resultText = '当前排列: FlexAlign.Start（首端对齐，默认值）'
            })
          Button('Center')
            .fontSize(12)
            .height(32)
            .margin(4)
            .backgroundColor(this.currentJustify === 'Center' ? '#007DFF' : '#CCCCCC')
            .onClick(() => {
              this.currentJustify = 'Center'
              this.resultText = '当前排列: FlexAlign.Center（中心对齐）'
            })
          Button('End')
            .fontSize(12)
            .height(32)
            .margin(4)
            .backgroundColor(this.currentJustify === 'End' ? '#007DFF' : '#CCCCCC')
            .onClick(() => {
              this.currentJustify = 'End'
              this.resultText = '当前排列: FlexAlign.End（尾部对齐）'
            })
          Button('SpaceBetween')
            .fontSize(12)
            .height(32)
            .margin(4)
            .backgroundColor(this.currentJustify === 'SpaceBetween' ? '#007DFF' : '#CCCCCC')
            .onClick(() => {
              this.currentJustify = 'SpaceBetween'
              this.resultText = '当前排列: FlexAlign.SpaceBetween（两端对齐，中间均分）'
            })
          Button('SpaceAround')
            .fontSize(12)
            .height(32)
            .margin(4)
            .backgroundColor(this.currentJustify === 'SpaceAround' ? '#007DFF' : '#CCCCCC')
            .onClick(() => {
              this.currentJustify = 'SpaceAround'
              this.resultText = '当前排列: FlexAlign.SpaceAround（均匀分布，两端间距为中间一半）'
            })
          Button('SpaceEvenly')
            .fontSize(12)
            .height(32)
            .margin(4)
            .backgroundColor(this.currentJustify === 'SpaceEvenly' ? '#007DFF' : '#CCCCCC')
            .onClick(() => {
              this.currentJustify = 'SpaceEvenly'
              this.resultText = '当前排列: FlexAlign.SpaceEvenly（完全均匀分布）'
            })
        }
        .width('90%')

        // 注意事项
        Column() {
          Text('注意事项')
            .fontSize(13)
            .fontColor('#FF6B00')
            .fontWeight(FontWeight.Medium)
            .width('100%')
          Text('Row 子组件不设置 flexShrink 时默认不压缩，子组件总宽度可超过容器宽度')
            .fontSize(12)
            .fontColor('#996600')
            .margin({ top: 4 })
            .width('100%')
          Text('此时 Center 和 End 会失效，需配合 flexShrink 使用')
            .fontSize(12)
            .fontColor('#996600')
            .margin({ top: 2 })
            .width('100%')
          Text('space 与 SpaceBetween/Around/Evenly 同时设置时 space 不生效')
            .fontSize(12)
            .fontColor('#996600')
            .margin({ top: 2 })
            .width('100%')
        }
        .width('90%')
        .backgroundColor('#FFF3CD')
        .borderRadius(8)
        .padding(12)

        // API 说明区
        Column() {
          Text('API 说明')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 8 })
          Text('.justifyContent(value: FlexAlign)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('FlexAlign.Start — 水平首端对齐（默认值）')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('FlexAlign.Center — 水平中心对齐')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('FlexAlign.End — 水平尾部对齐')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('FlexAlign.SpaceBetween — 两端对齐中间均分')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('FlexAlign.SpaceAround — 均匀分布，两端半间距')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('FlexAlign.SpaceEvenly — 完全均匀分布')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('元服务：API 11+ 可用（justifyContent API 8+）')
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

  private getJustifyValue(): FlexAlign {
    switch (this.currentJustify) {
      case 'Center':
        return FlexAlign.Center
      case 'End':
        return FlexAlign.End
      case 'SpaceBetween':
        return FlexAlign.SpaceBetween
      case 'SpaceAround':
        return FlexAlign.SpaceAround
      case 'SpaceEvenly':
        return FlexAlign.SpaceEvenly
      default:
        return FlexAlign.Start
    }
  }
}
