@Entry
@Component
struct Index {
  build() {
    Column({ space: 12 }) {
      Text('基础组件需求用例 004')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
      Text('请根据 case.yaml 实现注册表单实时校验，重点关注 @Computed 派生校验结果与按钮联动。')
        .fontSize(16)
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .padding(24)
  }
}
