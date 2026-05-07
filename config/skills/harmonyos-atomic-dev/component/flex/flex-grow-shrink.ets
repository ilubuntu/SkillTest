/**
 * flex-grow-shrink — Flex 自适应拉伸与压缩
 * 展示 flexBasis、flexGrow、flexShrink、alignSelf 属性
 * 元服务兼容性：flexBasis/flexGrow/flexShrink/alignSelf API 7+，元服务 API 11+ 可用
 */
@ComponentV2
export struct FlexGrowShrinkDemo {
  @Local currentScene: string = 'grow'
  @Local resultText: string = '当前场景: flexGrow — 剩余空间分配'

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('Flex 自适应拉伸 (flexGrow/Shrink/Basis)')
          .fontSize(20)
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

        // 场景切换
        Text('切换场景')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Row({ space: 8 }) {
          Button('flexGrow')
            .fontSize(12)
            .width(90)
            .height(36)
            .backgroundColor(this.currentScene === 'grow' ? '#007DFF' : '#CCCCCC')
            .onClick(() => {
              this.currentScene = 'grow'
              this.resultText = '当前场景: flexGrow — 剩余空间分配'
            })
          Button('flexShrink')
            .fontSize(12)
            .width(100)
            .height(36)
            .backgroundColor(this.currentScene === 'shrink' ? '#007DFF' : '#CCCCCC')
            .onClick(() => {
              this.currentScene = 'shrink'
              this.resultText = '当前场景: flexShrink — 空间不足时的压缩比例'
            })
          Button('flexBasis')
            .fontSize(12)
            .width(90)
            .height(36)
            .backgroundColor(this.currentScene === 'basis' ? '#007DFF' : '#CCCCCC')
            .onClick(() => {
              this.currentScene = 'basis'
              this.resultText = '当前场景: flexBasis — 主轴基准尺寸'
            })
        }

        Row({ space: 8 }) {
          Button('alignSelf')
            .fontSize(12)
            .width(90)
            .height(36)
            .backgroundColor(this.currentScene === 'alignSelf' ? '#007DFF' : '#CCCCCC')
            .onClick(() => {
              this.currentScene = 'alignSelf'
              this.resultText = '当前场景: alignSelf — 覆盖容器交叉轴对齐'
            })
        }

        // flexGrow 场景
        if (this.currentScene === 'grow') {
          Text('flexGrow: 剩余空间按比例分配（容器宽度 90%）')
            .fontSize(13)
            .fontWeight(FontWeight.Medium)
            .alignSelf(ItemAlign.Start)
            .margin({ left: 16, top: 8 })

          Flex() {
            Text('flexGrow(2)')
              .flexGrow(2)
              .height(60)
              .backgroundColor(0xF5DEB3)
              .textAlign(TextAlign.Center)
            Text('flexGrow(1)')
              .flexGrow(1)
              .height(60)
              .backgroundColor(0xD2B48C)
              .textAlign(TextAlign.Center)
            Text('no grow')
              .height(60)
              .width(60)
              .backgroundColor(0xF5DEB3)
              .textAlign(TextAlign.Center)
          }
          .width('90%')
          .height(80)
          .padding(10)
          .backgroundColor(0xAFEEEE)
          .borderRadius(8)
        }

        // flexShrink 场景
        if (this.currentScene === 'shrink') {
          Text('flexShrink: 超出空间按比例压缩')
            .fontSize(13)
            .fontWeight(FontWeight.Medium)
            .alignSelf(ItemAlign.Start)
            .margin({ left: 16, top: 8 })

          Flex({ direction: FlexDirection.Row }) {
            Text('flexShrink(0)')
              .flexShrink(0)
              .width('50%')
              .height(60)
              .backgroundColor(0xF5DEB3)
              .textAlign(TextAlign.Center)
            Text('default')
              .width('40%')
              .height(60)
              .backgroundColor(0xD2B48C)
              .textAlign(TextAlign.Center)
            Text('flexShrink(1)')
              .flexShrink(1)
              .width('40%')
              .height(60)
              .backgroundColor(0xF5DEB3)
              .textAlign(TextAlign.Center)
          }
          .width('90%')
          .height(80)
          .padding(10)
          .backgroundColor(0xAFEEEE)
          .borderRadius(8)
        }

        // flexBasis 场景
        if (this.currentScene === 'basis') {
          Text('flexBasis: 设置主轴基准尺寸（覆盖 width/height）')
            .fontSize(13)
            .fontWeight(FontWeight.Medium)
            .alignSelf(ItemAlign.Start)
            .margin({ left: 16, top: 8 })

          Flex() {
            Text('flexBasis(auto)')
              .flexBasis('auto')
              .height(60)
              .backgroundColor(0xF5DEB3)
              .textAlign(TextAlign.Center)
            Text('flexBasis(100)')
              .flexBasis(100)
              .height(60)
              .backgroundColor(0xD2B48C)
              .textAlign(TextAlign.Center)
            Text('flexBasis(auto)\nwidth(40%)')
              .flexBasis('auto')
              .width('40%')
              .height(60)
              .backgroundColor(0xF5DEB3)
              .textAlign(TextAlign.Center)
              .fontSize(10)
          }
          .width('90%')
          .height(80)
          .padding(10)
          .backgroundColor(0xAFEEEE)
          .borderRadius(8)
        }

        // alignSelf 场景
        if (this.currentScene === 'alignSelf') {
          Text('alignSelf: 子元素覆盖容器 alignItems（容器 Center）')
            .fontSize(13)
            .fontWeight(FontWeight.Medium)
            .alignSelf(ItemAlign.Start)
            .margin({ left: 16, top: 8 })

          Flex({ direction: FlexDirection.Row, alignItems: ItemAlign.Center }) {
            Text('no alignSelf')
              .width('25%')
              .height(50)
              .backgroundColor(0xF5DEB3)
              .textAlign(TextAlign.Center)
              .fontSize(10)
            Text('alignSelf(End)')
              .alignSelf(ItemAlign.End)
              .width('25%')
              .height(50)
              .backgroundColor(0xD2B48C)
              .textAlign(TextAlign.Center)
              .fontSize(10)
            Text('no alignSelf')
              .width('25%')
              .height(70)
              .backgroundColor(0xF5DEB3)
              .textAlign(TextAlign.Center)
              .fontSize(10)
            Text('alignSelf(Start)')
              .alignSelf(ItemAlign.Start)
              .width('25%')
              .height(50)
              .backgroundColor(0xD2B48C)
              .textAlign(TextAlign.Center)
              .fontSize(10)
          }
          .width('90%')
          .height(120)
          .padding(10)
          .backgroundColor(0xAFEEEE)
          .borderRadius(8)
        }

        // API 说明区
        Column() {
          Text('API 说明')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 8 })
          Text('.flexBasis(value: number | string)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('  设置主轴基准尺寸，auto 表示使用组件原本大小')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('.flexGrow(value: number)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('  剩余空间分配比例，默认值 0（不参与分配）')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('.flexShrink(value: number)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('  空间不足时的压缩比例，默认值 1')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('.alignSelf(value: ItemAlign)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('  子元素覆盖容器 alignItems 的对齐方式')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('元服务：以上属性均 API 11+ 可用')
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
