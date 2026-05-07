/**
 * relative_container-barrier — RelativeContainer 屏障
 * 展示 barrier 屏障功能：作为一组组件的边界锚点
 * 元服务兼容性：API 12+ 可用
 */

@ComponentV2
export struct RelativeContainerBarrier {
  @Local resultText: string = '等待操作...'
  @Local showThird: boolean = false

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('RelativeContainer 屏障')
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
        Text('屏障布局预览')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        RelativeContainer() {
          // 左上组件A
          Row() {
            Text('A')
              .fontSize(16)
              .fontColor('#FFFFFF')
              .fontWeight(FontWeight.Bold)
          }
          .width(80)
          .height(60)
          .backgroundColor('#2196F3')
          .borderRadius(8)
          .justifyContent(FlexAlign.Center)
          .alignRules({
            top: { anchor: '__container__', align: VerticalAlign.Top },
            left: { anchor: '__container__', align: HorizontalAlign.Start }
          })
          .id('compA')

          // 右上组件B
          Row() {
            Text('B')
              .fontSize(16)
              .fontColor('#FFFFFF')
              .fontWeight(FontWeight.Bold)
          }
          .width(80)
          .height(60)
          .backgroundColor('#4CAF50')
          .borderRadius(8)
          .justifyContent(FlexAlign.Center)
          .alignRules({
            top: { anchor: '__container__', align: VerticalAlign.Top },
            left: { anchor: 'compA', align: HorizontalAlign.End }
          })
          .id('compB')

          // 屏障右侧的组件C
          Row() {
            Text('C(屏障右)')
              .fontSize(12)
              .fontColor('#FFFFFF')
          }
          .width(100)
          .height(60)
          .backgroundColor('#FF9800')
          .borderRadius(8)
          .justifyContent(FlexAlign.Center)
          .alignRules({
            left: { anchor: 'rightBarrier', align: HorizontalAlign.End },
            top: { anchor: '__container__', align: VerticalAlign.Top }
          })
          .id('compC')

          // 屏障底部的组件D
          if (this.showThird) {
            Row() {
              Text('D(屏障下)')
                .fontSize(12)
                .fontColor('#FFFFFF')
            }
            .width(100)
            .height(60)
            .backgroundColor('#9C27B0')
            .borderRadius(8)
            .justifyContent(FlexAlign.Center)
            .alignRules({
              top: { anchor: 'bottomBarrier', align: VerticalAlign.Bottom },
              middle: { anchor: '__container__', align: HorizontalAlign.Center }
            })
            .id('compD')
          }
        }
        .barrier([
          { id: 'rightBarrier', direction: BarrierDirection.RIGHT, referencedId: ['compA', 'compB'] },
          { id: 'bottomBarrier', direction: BarrierDirection.BOTTOM, referencedId: ['compA', 'compB'] }
        ])
        .width('90%')
        .height(300)
        .backgroundColor('#E8E8E8')
        .borderRadius(12)

        // 操作按钮
        Row({ space: 8 }) {
          Button('显示D')
            .fontSize(13)
            .layoutWeight(1)
            .height(36)
            .onClick(() => {
              this.showThird = true
              this.resultText = 'D 使用 bottomBarrier 作为顶部锚点\n' +
                '屏障自动计算 A、B 的最大底部边界'
            })
          Button('隐藏D')
            .fontSize(13)
            .layoutWeight(1)
            .height(36)
            .onClick(() => {
              this.showThird = false
              this.resultText = 'C 使用 rightBarrier 作为左侧锚点\n' +
                '屏障自动计算 A、B 的最大右边界'
            })
          Button('说明')
            .fontSize(13)
            .layoutWeight(1)
            .height(36)
            .onClick(() => {
              this.resultText = '屏障方向：\n' +
                'LEFT=0, RIGHT=1, TOP=2, BOTTOM=3\n' +
                '屏障自动根据 referencedId 中组件的位置\n' +
                '计算最左/最右/最上/最下边界'
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
          Text('.barrier([{ id, direction, referencedId: [...] }])')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('direction: BarrierDirection.LEFT/RIGHT/TOP/BOTTOM')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('referencedId: 参与计算边界的组件 id 列表')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('元服务：API 12+ 可用')
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
