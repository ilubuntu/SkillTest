@Entry
@Component
struct Index {
  build() {
    Column({ space: 12 }) {
      Text('基础组件需求用例 003')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
      Text('请根据 case.yaml 实现评论列表与点赞交互，重点体现 @ObservedV2 和 @Trace 的最小刷新能力。')
        .fontSize(16)
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .padding(24)
  }
}
