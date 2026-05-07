/**
 * stack-basic — Stack 基础层叠
 * 展示 Stack 组件基本用法：子组件按顺序入栈、后入栈覆盖前入栈
 * 元服务兼容性：Stack API 7+，元服务 API 11+ 可用
 */

@ComponentV2
export struct StackBasic {
  @Local resultText: string = '等待操作...'
  @Local layerCount: number = 3

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('Stack 基础层叠')
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

        // Stack 层叠预览
        Text('层叠预览')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Stack() {
          // 底层 - 最大
          Column() {
            Text('底层 (Layer 1)')
              .fontSize(14)
              .fontColor('#FFFFFF')
          }
          .width(260)
          .height(260)
          .backgroundColor('#2196F3')
          .borderRadius(12)
          .justifyContent(FlexAlign.Center)

          // 中间层
          if (this.layerCount >= 2) {
            Column() {
              Text('中层 (Layer 2)')
                .fontSize(14)
                .fontColor('#FFFFFF')
            }
            .width(180)
            .height(180)
            .backgroundColor('#4CAF50')
            .borderRadius(12)
            .justifyContent(FlexAlign.Center)
          }

          // 顶层 - 最小
          if (this.layerCount >= 3) {
            Column() {
              Text('顶层 (Layer 3)')
                .fontSize(14)
                .fontColor('#FFFFFF')
            }
            .width(100)
            .height(100)
            .backgroundColor('#FF9800')
            .borderRadius(12)
            .justifyContent(FlexAlign.Center)
          }
        }
        .width(300)
        .height(300)
        .backgroundColor('#E0E0E0')
        .borderRadius(12)

        // 层数控制
        Text('层数控制')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Row({ space: 8 }) {
          Button('1 层')
            .fontSize(13)
            .layoutWeight(1)
            .height(36)
            .onClick(() => {
              this.layerCount = 1
              this.resultText = '仅显示底层，无覆盖效果'
            })
          Button('2 层')
            .fontSize(13)
            .layoutWeight(1)
            .height(36)
            .onClick(() => {
              this.layerCount = 2
              this.resultText = '中层覆盖在底层上方'
            })
          Button('3 层')
            .fontSize(13)
            .layoutWeight(1)
            .height(36)
            .onClick(() => {
              this.layerCount = 3
              this.resultText = '顶层覆盖中层，中层覆盖底层'
            })
        }
        .width('90%')

        // API 说明区
        Column() {
          Text('API 说明')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 8 })
          Text('Stack(value?: { alignContent?: Alignment })')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('子组件按顺序入栈，后入栈的覆盖先入栈的')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('默认对齐方式: Alignment.Center')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('元服务：API 7+ 可用，无限制')
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
