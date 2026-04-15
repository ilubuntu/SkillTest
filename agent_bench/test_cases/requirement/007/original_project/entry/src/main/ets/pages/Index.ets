
import { router } from '@kit.ArkUI'

type ProductItem = {
  id: string,
  title: string,
  price: number,
  tag: string
}

@Entry
@Component
struct Index {
  private products: ProductItem[] = [
    { id: 'sku_1', title: '智能手表 Pro', price: 1299, tag: '新品' },
    { id: 'sku_2', title: '降噪耳机 Air', price: 899, tag: '热卖' },
    { id: 'sku_3', title: '便携音箱 Mini', price: 399, tag: '限时优惠' }
  ]

  build() {
    Column({ space: 16 }) {
      Row() {
        Text('精选商品')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
        Blank()
        Button('查看购物车')
          .height(40)
          .onClick(() => {
            router.pushUrl({ url: 'pages/CartPage' })
          })
      }
      .width('100%')

      ForEach(this.products, (item: ProductItem) => {
        Row({ space: 12 }) {
          Column()
            .width(72)
            .height(72)
            .borderRadius(16)
            .backgroundColor('#E8ECF8')

          Column({ space: 6 }) {
            Text(item.title)
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
            Text('￥' + item.price.toString())
              .fontSize(15)
              .fontColor('#D9485F')
            Text(item.tag)
              .fontSize(12)
              .fontColor('#666666')
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)
        }
        .width('100%')
        .padding(16)
        .backgroundColor('#FFFFFF')
        .borderRadius(18)
      }, (item: ProductItem) => item.id)

      Text('当前首页已完成商品浏览，请在此基础上续写购物车与结算链路。')
        .width('100%')
        .fontSize(13)
        .fontColor('#888888')
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .height('100%')
    .padding(20)
    .backgroundColor('#F6F7FB')
  }
}
