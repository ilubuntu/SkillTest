
import { router } from '@kit.ArkUI'

type NewsCard = {
  id: string,
  title: string,
  summary: string,
  source: string
}

@Entry
@Component
struct Index {
  private cards: NewsCard[] = [
    { id: 'news_1', title: 'HarmonyOS 新版本发布', summary: '带来更稳定的分布式体验与组件能力。', source: '官方资讯' },
    { id: 'news_2', title: '本地生活服务模板更新', summary: '模板仓新增多个高频业务场景骨架。', source: '行业快报' },
    { id: 'news_3', title: '开发者活动开启报名', summary: '围绕元服务与体验设计展开主题分享。', source: '社区动态' }
  ]

  build() {
    Column({ space: 16 }) {
      Text('今日资讯')
        .width('100%')
        .fontSize(28)
        .fontWeight(FontWeight.Bold)

      ForEach(this.cards, (item: NewsCard) => {
        Column({ space: 8 }) {
          Text(item.title)
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
          Text(item.summary)
            .fontSize(14)
            .fontColor('#666666')
            .lineHeight(21)
          Row() {
            Text(item.source)
              .fontSize(12)
              .fontColor('#999999')
            Blank()
            Text('阅读详情')
              .fontSize(13)
              .fontColor('#0A59F7')
          }
          .width('100%')
        }
        .width('100%')
        .padding(18)
        .backgroundColor('#FFFFFF')
        .borderRadius(18)
        .onClick(() => {
          router.pushUrl({ url: 'pages/ArticleDetailPage', params: item })
        })
      }, (item: NewsCard) => item.id)
    }
    .width('100%')
    .height('100%')
    .padding(20)
    .backgroundColor('#F5F7FA')
  }
}
