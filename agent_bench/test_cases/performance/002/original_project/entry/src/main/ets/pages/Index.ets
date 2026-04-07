@Entry
@Component
struct Index {
  build() {
    Column({ space: 12 }) {
      Text('列表与性能用例 002')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
      Text('请根据 case.yaml 实现联系人分组索引列表，重点关注 ListItemGroup、scrollToIndex 与索引高亮。')
        .fontSize(16)
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .padding(24)
  }
}
