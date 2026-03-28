// 多模态任务：图片+文字组合组件
// 请实现一个商品卡片组件，显示图片、标题和价格

@Entry
@Component
struct GoodsCard {
  build() {
    Column() {
      // 图片占位
      Text('商品图片')

      Column() {
        Text('商品标题')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)

        Text('¥99.00')
          .fontColor('#FF6600')
      }
    }
  }
}
