/**
 * relative_container-bias — RelativeContainer 偏移设置
 * 展示通过不同 alignRules 组合实现组件偏移效果
 * 元服务兼容性：API 11+ 可用
 */

@ComponentV2
export struct RelativeContainerBias {
  @Local resultText: string = '等待操作...'
  @Local alignMode: number = 0

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('RelativeContainer 偏移与对齐')
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
        Text('对齐效果预览')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        if (this.alignMode === 0) {
          // 居中：双锚点
          RelativeContainer() {
            Row() {
              Text('居中')
                .fontSize(14)
                .fontColor('#FFFFFF')
            }
            .width(80)
            .height(80)
            .backgroundColor('#2196F3')
            .borderRadius(8)
            .justifyContent(FlexAlign.Center)
            .alignRules({
              top: { anchor: '__container__', align: VerticalAlign.Top },
              bottom: { anchor: '__container__', align: VerticalAlign.Bottom },
              left: { anchor: '__container__', align: HorizontalAlign.Start },
              right: { anchor: '__container__', align: HorizontalAlign.End }
            })
            .id('centered')
          }
          .width('90%')
          .height(250)
          .backgroundColor('#E8E8E8')
          .borderRadius(12)
        } else if (this.alignMode === 1) {
          // 偏左上：单锚点
          RelativeContainer() {
            Row() {
              Text('左上')
                .fontSize(14)
                .fontColor('#FFFFFF')
            }
            .width(80)
            .height(80)
            .backgroundColor('#FF9800')
            .borderRadius(8)
            .justifyContent(FlexAlign.Center)
            .alignRules({
              top: { anchor: '__container__', align: VerticalAlign.Top },
              left: { anchor: '__container__', align: HorizontalAlign.Start }
            })
            .id('topLeft')
          }
          .width('90%')
          .height(250)
          .backgroundColor('#E8E8E8')
          .borderRadius(12)
        } else {
          // 偏右下：单锚点
          RelativeContainer() {
            Row() {
              Text('右下')
                .fontSize(14)
                .fontColor('#FFFFFF')
            }
            .width(80)
            .height(80)
            .backgroundColor('#4CAF50')
            .borderRadius(8)
            .justifyContent(FlexAlign.Center)
            .alignRules({
              bottom: { anchor: '__container__', align: VerticalAlign.Bottom },
              right: { anchor: '__container__', align: HorizontalAlign.End }
            })
            .id('bottomRight')
          }
          .width('90%')
          .height(250)
          .backgroundColor('#E8E8E8')
          .borderRadius(12)
        }

        // 操作按钮
        Row({ space: 8 }) {
          Button('居中(双锚)')
            .fontSize(13)
            .layoutWeight(1)
            .height(36)
            .onClick(() => {
              this.alignMode = 0
              this.resultText = '同时设置 top+bottom+left+right\n组件自动居中显示\n这是实现居中最推荐的方式'
            })
          Button('左上(单锚)')
            .fontSize(13)
            .layoutWeight(1)
            .height(36)
            .onClick(() => {
              this.alignMode = 1
              this.resultText = '仅设置 top+left\n组件紧贴左上角\n不设置另一方向的锚点时组件靠近已设置锚点'
            })
          Button('右下(单锚)')
            .fontSize(13)
            .layoutWeight(1)
            .height(36)
            .onClick(() => {
              this.alignMode = 2
              this.resultText = '仅设置 bottom+right\n组件紧贴右下角\n适用于浮动按钮等场景'
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
          Text('双方向锚点（如 top+bottom）→ 组件在两锚点间居中')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('单方向锚点（如仅 top）→ 组件靠近已设置的锚点')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('偏移可结合 .offset() 实现微调')
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
