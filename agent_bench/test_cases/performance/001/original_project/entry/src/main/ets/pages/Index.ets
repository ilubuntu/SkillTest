@Entry
@Component
struct Index {
  build() {
    Column({ space: 12 }) {
      Text('列表与性能用例 001')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
      Text('请根据 case.yaml 实现一万个商品项的高性能列表，重点关注 LazyForEach、IDataSource 和 cachedCount。')
        .fontSize(16)
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .padding(24)
  }
}
