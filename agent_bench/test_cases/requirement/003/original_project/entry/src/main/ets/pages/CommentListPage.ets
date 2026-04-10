import { router } from '@kit.ArkUI'

@Entry
@Component
struct CommentListPage {
  build() {
    Column({ space: 16 }) {
      Row() {
        Button('< 返回')
          .fontSize(15)
          .backgroundColor('transparent')
          .fontColor('#333333')
          .onClick(() => {
            router.back()
          })

        Blank()

        Text('评论列表')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)

        Blank()
      }
      .width('100%')

      Column({ space: 12 }) {
        Text('待实现评论列表')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)

        Text('请基于 case.yaml 在当前页面实现评论列表、点赞交互、组件抽象和基础性能优化。')
          .fontSize(14)
          .fontColor('#666666')
          .lineHeight(22)
          .textAlign(TextAlign.Start)
      }
      .width('100%')
      .padding(18)
      .borderRadius(18)
      .backgroundColor('#FFFFFF')
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height('100%')
    .padding(20)
    .backgroundColor('#F5F7FA')
  }
}
