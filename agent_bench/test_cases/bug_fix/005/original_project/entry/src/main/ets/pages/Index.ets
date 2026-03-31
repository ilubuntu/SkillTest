import { prompt, router } from '@kit.ArkUI'

interface Goods {
  id: number
  name: string
  price: number
}

interface DetailResultParams {
  saved?: boolean
  goods?: Goods
  changeToken?: number
}

interface GoodsRepository {
  query(table: string): Goods[]
  queryOne(table: string, id: number): Goods
  update(table: string, data: Goods): Promise<void>
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
  query(table: string): Goods[] {
    return GOODS_SOURCE
  }

  queryOne(table: string, id: number): Goods {
    const list: Goods[] = GOODS_SOURCE
    const matched = list.find((goods: Goods) => goods.id === id)
    return matched ? matched : DEFAULT_GOODS
  }

  update(table: string, data: Goods): Promise<void> {
    return new Promise((resolve) => {
      setTimeout(() => {
        console.info(`DB.update: ${JSON.stringify(data)}`)
        resolve()
      }, 500)
    })
  }
}

const DB: GoodsRepository = new MockGoodsRepository()

class GoodsDataSource implements IDataSource {
  private goodsList: Goods[] = []
  private listeners: DataChangeListener[] = []

  constructor(goodsList: Goods[]) {
    this.goodsList = goodsList
  }

  totalCount(): number {
    return this.goodsList.length
  }

  getData(index: number): Goods {
    return this.goodsList[index]
  }

  registerDataChangeListener(listener: DataChangeListener): void {
    if (this.listeners.indexOf(listener) < 0) {
      this.listeners.push(listener)
    }
  }

  unregisterDataChangeListener(listener: DataChangeListener): void {
    const idx = this.listeners.indexOf(listener)
    if (idx >= 0) {
      this.listeners.splice(idx, 1)
    }
  }

  updateData(index: number, data: Goods): void {
    this.goodsList[index] = data
    this.listeners.forEach(listener => {
      listener.onDataChange(index)
    })
  }

  addData(index: number, data: Goods): void {
    this.goodsList.splice(index, 0, data)
    this.listeners.forEach(listener => {
      listener.onDataAdd(index)
    })
  }

  deleteData(index: number): void {
    this.goodsList.splice(index, 1)
    this.listeners.forEach(listener => {
      listener.onDataDelete(index)
    })
  }
}

@Entry
@Component
struct Index {
  @State goodsList: Goods[] = []
  @State isLoading: boolean = false
  private dataSource: GoodsDataSource = new GoodsDataSource([])
  private lastHandledToken: number = 0

  aboutToAppear() {
    this.loadGoods()
  }

  onPageShow() {
    this.handleReturnParams()
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
      this.dataSource.updateData(existingIndex, returnedGoods)
      this.goodsList = this.goodsList.map((item, idx) => idx === existingIndex ? returnedGoods : item)
      prompt.showToast({ message: '商品已更新' })
      return
    }

    this.goodsList = [returnedGoods, ...this.goodsList]
    this.dataSource.addData(0, returnedGoods)
    prompt.showToast({ message: '商品已新增' })
  }

  loadGoods() {
    this.isLoading = true
    this.goodsList = DB.query('goods')
    this.dataSource = new GoodsDataSource(this.goodsList)
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
          LazyForEach(this.dataSource, (goods: Goods) => {
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
        router.pushUrl({ url: 'pages/DetailPage', params: { id: -1, from: 'Index' } })
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
        router.pushUrl({ url: 'pages/DetailPage', params: { id: goodsId, from: 'Index' } })
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
