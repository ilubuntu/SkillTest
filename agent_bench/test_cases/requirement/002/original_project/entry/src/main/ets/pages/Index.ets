@Entry
@Component
struct Index {
  build() {
    Column({ space: 12 }) {
      Text('基础组件需求用例 002')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
      Text('请根据 case.yaml 实现商品详情卡片，重点体现父子组件之间的 @Param 传参与只读展示。')
        .fontSize(16)
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .padding(24)
  }
}
