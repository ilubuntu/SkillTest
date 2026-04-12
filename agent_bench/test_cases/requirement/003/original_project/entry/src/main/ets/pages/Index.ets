import { router } from '@kit.ArkUI'

@Entry
@Component
struct Index {
  build() {
    Column({ space: 18 }) {
      Column({ space: 10 }) {
        Text('社区评论')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)

        Text('查看最新评论、参与互动，并进入评论列表页面完成点赞体验开发。')
          .fontSize(15)
          .fontColor('#666666')
          .lineHeight(22)
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      Column({ space: 12 }) {
        Row({ space: 12 }) {
          Text('热议话题')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
          Blank()
          Text('128 条评论')
            .fontSize(13)
            .fontColor('#888888')
        }
        .width('100%')

        Text('产品体验、交互细节与性能优化等讨论正在进行中，点击下方入口查看完整评论列表。')
          .fontSize(14)
          .fontColor('#666666')
          .lineHeight(21)

        Row({ space: 12 }) {
          AvatarCircle({ text: 'U' })
          Column({ space: 4 }) {
            Text('最近互动')
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
            Text('“希望点赞反馈更明显，长列表滚动也要保持顺滑。”')
              .fontSize(13)
              .fontColor('#666666')
              .maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)
        }
        .width('100%')
      }
      .width('100%')
      .padding(18)
      .borderRadius(20)
      .backgroundColor('#FFFFFF')

      Button('进入评论列表')
        .width('100%')
        .height(52)
        .fontSize(17)
        .fontWeight(FontWeight.Medium)
        .onClick(() => {
          router.pushUrl({ url: 'pages/CommentListPage' })
        })

      Text('当前首页作为评论列表入口页，评论内容与点赞交互在新页面中展示。')
        .width('100%')
        .fontSize(13)
        .fontColor('#888888')
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .padding(20)
    .backgroundColor('#F5F7FA')
  }
}

@Component
struct AvatarCircle {
  @Prop text: string

  build() {
    Row() {
      Text(this.text)
        .fontSize(15)
        .fontColor('#FFFFFF')
        .fontWeight(FontWeight.Bold)
    }
    .width(40)
    .height(40)
    .borderRadius(20)
    .justifyContent(FlexAlign.Center)
    .backgroundColor('#5B6CFF')
  }
}
