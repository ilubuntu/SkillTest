@Entry
@Component
struct Index {
  build() {
    Column({ space: 12 }) {
      Text('列表与性能用例 003')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
      Text('请根据 case.yaml 实现可展开订单列表，重点关注 @ObservedV2、@Trace 与单项局部刷新。')
        .fontSize(16)
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .padding(24)
  }
}
