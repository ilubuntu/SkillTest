export interface Goods {
  id: number
  name: string
  price: number
}

const DEFAULT_GOODS: Goods = { id: -1, name: '', price: 0 }

const GOODS_SOURCE: Goods[] = [
  { id: 1, name: 'iPhone 15 Pro', price: 8999 },
  { id: 2, name: 'iPad Air', price: 4599 },
  { id: 3, name: 'MacBook Pro', price: 12999 },
  { id: 4, name: 'AirPods Pro', price: 1899 },
  { id: 5, name: 'Apple Watch', price: 2999 }
]

export class GoodsStore {
  private static clone(goods: Goods): Goods {
    return {
      id: goods.id,
      name: goods.name,
      price: goods.price
    }
  }

  static list(): Goods[] {
    return GOODS_SOURCE.map((goods: Goods) => GoodsStore.clone(goods))
  }

  static getById(id: number): Goods {
    const matched = GOODS_SOURCE.find((goods: Goods) => goods.id === id)
    return matched ? GoodsStore.clone(matched) : GoodsStore.clone(DEFAULT_GOODS)
  }

  static save(data: Goods): Goods {
    const index = GOODS_SOURCE.findIndex((goods: Goods) => goods.id === data.id)
    const savedGoods: Goods = GoodsStore.clone(data)

    if (index === -1) {
      GOODS_SOURCE.unshift(savedGoods)
      return GoodsStore.clone(savedGoods)
    }

    GOODS_SOURCE[index] = savedGoods
    return GoodsStore.clone(savedGoods)
  }
}
