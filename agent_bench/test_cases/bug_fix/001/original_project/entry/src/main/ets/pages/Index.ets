import { promptAction, router } from '@kit.ArkUI'
import { Goods, GoodsStore } from '../common/GoodsStore'

interface DetailResultParams {
  saved?: boolean
  goods?: Goods
  changeToken?: number
}

// ============================================================
// MainPage - 商品列表页
// ============================================================
@Entry
@Component
struct MainPage {
  @State goodsList: Goods[] = []
  @State isLoading: boolean = false
  private lastHandledToken: number = 0

  aboutToAppear() {
    this.loadGoods()
  }

  handleReturnParams() {
    const params = router.getParams() as DetailResultParams | undefined
    if (!params || params.saved !== true || !params.changeToken) {
      return
    }

    if (params.changeToken === this.lastHandledToken) {
      return
    }

    this.lastHandledToken = params.changeToken
    const returnedGoods = params.goods
    if (!returnedGoods) {
      return
    }

    const targetId = returnedGoods.id
    const existingIndex = this.goodsList.findIndex((item: Goods) => item.id === targetId)
    if (existingIndex !== -1) {
      const nextGoodsList: Goods[] = this.goodsList.slice()
      nextGoodsList[existingIndex] = returnedGoods
      this.goodsList = nextGoodsList
      promptAction.showToast({ message: '商品已更新' })
      return
    }

    this.goodsList = [returnedGoods, ...this.goodsList]
    promptAction.showToast({ message: '商品已新增' })
  }

  loadGoods() {
    this.isLoading = true
    this.goodsList = GoodsStore.list()
    this.isLoading = false
  }

  build() {
    Stack({ alignContent: Alignment.Top }) {
      if (this.isLoading) {
        LoadingProgress()
          .width(50)
          .height(50)
      } else {
        List() {
          ForEach(this.goodsList, (goods: Goods) => {
            ListItem() {
              GoodsCard({ goods: goods })
            }
            .swipeAction({
              end: this.editButton(goods.id)
            })
          }, (goods: Goods) => goods.id.toString())
        }
        .cachedCount(10)
        .listDirection(Axis.Vertical)
        .divider({ strokeWidth: 1, color: '#eee' })
      }

      Button() {
        Text('+')
          .fontSize(30)
          .fontWeight(FontWeight.Bold)
      }
      .width(60)
      .height(60)
      .borderRadius(30)
      .backgroundColor('#1890ff')
      .shadow({
        radius: 10,
        color: 'rgba(0,0,0,0.2)',
        offsetX: 0,
        offsetY: 4
      })
      .position({ x: '80%', y: '85%' })
      .onClick(() => {
        router.pushUrl({ url: 'pages/DetailPage', params: { id: -1, from: 'MainPage' } })
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#f5f5f5')
  }

  @Builder
  editButton(goodsId: number) {
    Button('编辑')
      .width(80)
      .height(40)
      .backgroundColor('#1890ff')
      .onClick(() => {
        router.pushUrl({ url: 'pages/DetailPage', params: { id: goodsId, from: 'MainPage' } })
      })
  }
}

@Component
struct GoodsCard {
  @Prop goods: Goods

  build() {
    Row() {
      Column() {
        Text(this.goods.name)
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .margin({ bottom: 8 })

        Text(`¥ ${this.goods.price.toFixed(2)}`)
          .fontSize(16)
          .fontColor('#fa5a4a')
      }
      .alignItems(HorizontalAlign.Start)

      Blank()

      Text('>')
        .fontSize(20)
        .fontColor('#999')
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#fff')
    .borderRadius(12)
  }
}
