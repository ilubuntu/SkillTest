import { prompt, router } from '@kit.ArkUI'

interface Goods {
  id: number
  name: string
  price: number
}

interface GoodsRepository {
  queryOne(table: string, id: number): Goods
  update(table: string, data: Goods): Promise<void>
}

interface DetailPageParams {
  id: number
  from?: string
}

interface DetailBackParams {
  saved: boolean
  goods?: Goods
  changeToken?: number
}

const DEFAULT_GOODS: Goods = { id: -1, name: '', price: 0 }
const GOODS_SOURCE: Goods[] = [
  { id: 1, name: 'iPhone 15 Pro', price: 8999 },
  { id: 2, name: 'iPad Air', price: 4599 },
  { id: 3, name: 'MacBook Pro', price: 12999 },
  { id: 4, name: 'AirPods Pro', price: 1899 },
  { id: 5, name: 'Apple Watch', price: 2999 }
]

class MockGoodsRepository implements GoodsRepository {
  queryOne(table: string, id: number): Goods {
    const matched = GOODS_SOURCE.find((goods: Goods) => goods.id === id)
    return matched ? matched : DEFAULT_GOODS
  }

  update(table: string, data: Goods): Promise<void> {
    return new Promise((resolve, reject) => {
      setTimeout(() => {
        if (!data.name || data.price <= 0) {
          reject(new Error('Invalid data'))
          return
        }
        console.info(`DB.update: ${JSON.stringify(data)}`)
        resolve()
      }, 500)
    })
  }
}

const DB: GoodsRepository = new MockGoodsRepository()

@Entry
@Component
struct DetailPage {
  @State editName: string = ''
  @State editPrice: string = ''
  @State isLoading: boolean = false
  @State isSaving: boolean = false
  private goodsId: number = -1

  aboutToAppear() {
    const params = router.getParams() as DetailPageParams | undefined
    if (!params) {
      prompt.showToast({ message: '参数错误' })
      router.back({ params: { saved: false } })
      return
    }
    this.goodsId = params.id

    if (this.goodsId !== -1) {
      this.loadGoods()
    }
  }

  private async loadGoods() {
    this.isLoading = true
    const goods = DB.queryOne('goods', this.goodsId)
    this.editName = goods.name
    this.editPrice = goods.price.toString()
    this.isLoading = false
  }

  build() {
    Column() {
      Row() {
        Button('< 返回')
          .fontSize(16)
          .backgroundColor('transparent')
          .fontColor('#333')
          .onClick(() => {
            const backParams: DetailBackParams = { saved: false }
            router.back({ params: backParams })
          })

        Text(this.goodsId === -1 ? '新增商品' : '编辑商品')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)

        Blank()
      }
      .width('100%')
      .padding(16)
      .backgroundColor('#fff')

      Divider()

      if (this.isLoading) {
        LoadingProgress()
          .width(48)
          .height(48)
          .margin({ top: 40 })
      } else {
        Column() {
          Column({ space: 8 }) {
            Text('商品名称')
              .fontSize(14)
              .fontColor('#666')
              .alignSelf(ItemAlign.Start)

            TextInput({ placeholder: '请输入商品名称', text: this.editName })
              .width('100%')
              .height(50)
              .backgroundColor('#f5f5f5')
              .borderRadius(8)
              .onChange((val) => {
                this.editName = val
              })
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)
          .margin({ top: 20 })

          Column({ space: 8 }) {
            Text('商品价格')
              .fontSize(14)
              .fontColor('#666')
              .alignSelf(ItemAlign.Start)

            TextInput({ placeholder: '请输入价格', text: this.editPrice })
              .width('100%')
              .height(50)
              .backgroundColor('#f5f5f5')
              .borderRadius(8)
              .type(InputType.Number)
              .onChange((val) => {
                this.editPrice = val
              })
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)
          .margin({ top: 20 })

          Button(this.isSaving ? '保存中...' : '保存')
            .width('100%')
            .height(50)
            .backgroundColor(this.isSaving ? '#ccc' : '#1890ff')
            .fontColor('#fff')
            .borderRadius(25)
            .margin({ top: 40 })
            .enabled(!this.isSaving)
            .onClick(() => {
              this.saveGoods()
            })
        }
        .width('90%')
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#fff')
  }

  async saveGoods() {
    const name = this.editName.trim()
    const price = Number(this.editPrice)
    if (!name || Number.isNaN(price) || price <= 0) {
      prompt.showToast({ message: '请填写有效的商品名称和价格' })
      return
    }

    this.isSaving = true

    const savedGoods: Goods = {
      id: this.goodsId === -1 ? Date.now() : this.goodsId,
      name: name,
      price: price
    }
    const changeToken = Date.now()
    const backParams: DetailBackParams = {
      saved: true,
      goods: savedGoods,
      changeToken: changeToken
    }

    try {
      await DB.update('goods', savedGoods)
      router.back({ params: backParams })
    } catch (err) {
      prompt.showToast({ message: '保存失败' })
      this.isSaving = false
    }
  }
}
