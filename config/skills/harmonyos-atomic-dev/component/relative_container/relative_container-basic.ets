/**
 * relative_container-basic — RelativeContainer 基础相对布局
 * 展示 RelativeContainer 基本用法：子组件使用 __container__ 锚点对齐到容器
 * 元服务兼容性：API 11+ 可用
 */

@ComponentV2
export struct RelativeContainerBasic {
  @Local resultText: string = '等待操作...'

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('RelativeContainer 基础相对布局')
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
        Text('布局预览')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        RelativeContainer() {
          // 左上角
          Row() {
            Text('左上')
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
            left: { anchor: '__container__', align: HorizontalAlign.Start }
          })
          .id('box1')

          // 右上角
          Row() {
            Text('右上')
              .fontSize(14)
              .fontColor('#FFFFFF')
          }
          .width(80)
          .height(80)
          .backgroundColor('#4CAF50')
          .borderRadius(8)
          .justifyContent(FlexAlign.Center)
          .alignRules({
            top: { anchor: '__container__', align: VerticalAlign.Top },
            right: { anchor: '__container__', align: HorizontalAlign.End }
          })
          .id('box2')

          // 居中
          Row() {
            Text('居中')
              .fontSize(14)
              .fontColor('#FFFFFF')
          }
          .width(80)
          .height(80)
          .backgroundColor('#FF9800')
          .borderRadius(8)
          .justifyContent(FlexAlign.Center)
          .alignRules({
            center: { anchor: '__container__', align: VerticalAlign.Center },
            middle: { anchor: '__container__', align: HorizontalAlign.Center }
          })
          .id('box3')

          // 左下角
          Row() {
            Text('左下')
              .fontSize(14)
              .fontColor('#FFFFFF')
          }
          .width(80)
          .height(80)
          .backgroundColor('#9C27B0')
          .borderRadius(8)
          .justifyContent(FlexAlign.Center)
          .alignRules({
            bottom: { anchor: '__container__', align: VerticalAlign.Bottom },
            left: { anchor: '__container__', align: HorizontalAlign.Start }
          })
          .id('box4')

          // 右下角
          Row() {
            Text('右下')
              .fontSize(14)
              .fontColor('#FFFFFF')
          }
          .width(80)
          .height(80)
          .backgroundColor('#F44336')
          .borderRadius(8)
          .justifyContent(FlexAlign.Center)
          .alignRules({
            bottom: { anchor: '__container__', align: VerticalAlign.Bottom },
            right: { anchor: '__container__', align: HorizontalAlign.End }
          })
          .id('box5')
        }
        .width('90%')
        .height(300)
        .backgroundColor('#E8E8E8')
        .borderRadius(12)

        // 操作按钮
        Button('查看对齐规则')
          .width('90%')
          .height(40)
          .onClick(() => {
            this.resultText = '5个子组件分别对齐到容器四角和中心\n' +
              'box1: top+left → 左上角\n' +
              'box2: top+right → 右上角\n' +
              'box3: center+middle → 正中心\n' +
              'box4: bottom+left → 左下角\n' +
              'box5: bottom+right → 右下角\n' +
              '锚点均为 __container__（容器自身）'
          })

        // API 说明区
        Column() {
          Text('API 说明')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 8 })
          Text('RelativeContainer()')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('子组件通过 .alignRules() 设置对齐规则')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('锚点 __container__ 代表容器自身')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('每个子组件必须设置 .id() 用于兄弟锚定')
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
