@Entry
@Component
struct Index {
  build() {
    Column({ space: 12 }) {
      Text('基础组件需求用例 001')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
      Text('请根据 case.yaml 实现快捷登录页，包含账号输入、密码输入、密码显隐和登录按钮状态联动。')
        .fontSize(16)
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .padding(24)
  }
}
