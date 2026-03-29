// 修复: 使用LazyForEach + IDataSource实现懒加载
class ItemDataSource implements IDataSource {
  private items: string[] = []
  private listeners: DataChangeListener[] = []

  constructor(items: string[]) {
    this.items = items
  }

  totalCount(): number {
    return this.items.length
  }

  getData(index: number): string {
    return this.items[index]
  }

  registerDataChangeListener(listener: DataChangeListener): void {
    this.listeners.push(listener)
  }

  unregisterDataChangeListener(listener: DataChangeListener): void {
    const idx = this.listeners.indexOf(listener)
    if (idx >= 0) {
      this.listeners.splice(idx, 1)
    }
  }
}

@Entry
@Component
struct ItemList {
  private dataSource: ItemDataSource = new ItemDataSource([])

  aboutToAppear() {
    let items: string[] = []
    for (let i = 0; i < 10000; i++) {
      items.push(`Item ${i}`)
    }
    this.dataSource = new ItemDataSource(items)
  }

  build() {
    List() {
      LazyForEach(this.dataSource, (item: string) => {
        ListItem() {
          Text(item)
            .fontSize(16)
            .padding(12)
        }
      })
    }
    .cachedCount(20)
    .width('100%')
    .height('100%')
  }
}
