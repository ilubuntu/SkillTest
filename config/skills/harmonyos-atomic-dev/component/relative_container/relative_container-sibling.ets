/**
 * relative_container-sibling — RelativeContainer 兄弟锚定
 * 展示子组件以其他兄弟组件为锚点进行对齐
 * 元服务兼容性：API 11+ 可用
 */

@ComponentV2
export struct RelativeContainerSibling {
  @Local resultText: string = '等待操作...'
  @Local showThird: boolean = false

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('RelativeContainer 兄弟锚定')
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

        // 布局预览
        Text('兄弟对齐预览')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        RelativeContainer() {
          // 基准组件 - 左侧
          Row() {
            Text('基准A')
              .fontSize(14)
              .fontColor('#FFFFFF')
          }
          .width(100)
          .height(100)
          .backgroundColor('#2196F3')
          .borderRadius(8)
          .justifyContent(FlexAlign.Center)
          .alignRules({
            top: { anchor: '__container__', align: VerticalAlign.Top },
            left: { anchor: '__container__', align: HorizontalAlign.Start }
          })
          .id('baseA')

          // 兄弟锚定 - B 在 A 右侧
          Row() {
            Text('B在A右')
              .fontSize(14)
              .fontColor('#FFFFFF')
          }
          .width(100)
          .height(100)
          .backgroundColor('#4CAF50')
          .borderRadius(8)
          .justifyContent(FlexAlign.Center)
          .alignRules({
            left: { anchor: 'baseA', align: HorizontalAlign.End },
            top: { anchor: 'baseA', align: VerticalAlign.Top }
          })
          .id('baseB')

          // 兄弟锚定 - C 在 B 下方
          if (this.showThird) {
            Row() {
              Text('C在B下')
                .fontSize(14)
                .fontColor('#FFFFFF')
            }
            .width(100)
            .height(100)
            .backgroundColor('#FF9800')
            .borderRadius(8)
            .justifyContent(FlexAlign.Center)
            .alignRules({
              top: { anchor: 'baseB', align: VerticalAlign.Bottom },
              left: { anchor: 'baseB', align: HorizontalAlign.Start }
            })
            .id('baseC')
          }
        }
        .width('90%')
        .height(300)
        .backgroundColor('#E8E8E8')
        .borderRadius(12)

        // 操作按钮
        Row({ space: 8 }) {
          Button('显示C')
            .fontSize(13)
            .layoutWeight(1)
            .height(36)
            .onClick(() => {
              this.showThird = true
              this.resultText = 'C 以 B 为锚点：top=B.Bottom, left=B.Start\n形成链式依赖：A → B → C'
            })
          Button('隐藏C')
            .fontSize(13)
            .layoutWeight(1)
            .height(36)
            .onClick(() => {
              this.showThird = false
              this.resultText = '仅显示 A 和 B\nB 以 A 为锚点：left=A.End, top=A.Top'
            })
          Button('说明')
            .fontSize(13)
            .layoutWeight(1)
            .height(36)
            .onClick(() => {
              this.resultText = '兄弟锚定要点：\n' +
                '1. 锚点为兄弟组件的 id 字符串\n' +
                '2. 避免循环依赖（A→B→A）\n' +
                '3. 链式依赖（A→B→C）是允许的'
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
          Text('.alignRules({ left: { anchor: "兄弟id", align: HorizontalAlign.End } })')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('锚点可引用兄弟组件 id，实现组件间对齐')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('支持链式依赖，禁止循环依赖')
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
        .margin({ top: 8, bottom: 20 })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
  }
}
