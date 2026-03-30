class BasicDataSource implements IDataSource {
  private listeners: DataChangeListener[] = []

  registerDataChangeListener(listener: DataChangeListener): void {
    this.listeners.push(listener)
  }

  unregisterDataChangeListener(listener: DataChangeListener): void {
    const index = this.listeners.indexOf(listener)
    if (index >= 0) {
      this.listeners.splice(index, 1)
    }
  }

  notifyDataReload(): void {
    this.listeners.forEach(listener => listener.onDataReloaded())
  }

  notifyDataAdd(index: number): void {
    this.listeners.forEach(listener => listener.onDataAdd(index))
  }

  notifyDataChange(index: number): void {
    this.listeners.forEach(listener => listener.onDataChange(index))
  }

  notifyDataDelete(index: number): void {
    this.listeners.forEach(listener => listener.onDataDelete(index))
  }

  totalCount(): number {
    return 0
  }

  getData(index: number): any {
    return undefined
  }
}

class ItemDataSource extends BasicDataSource {
  private items: string[] = []

  constructor() {
    super()
    for (let i = 0; i < 10000; i++) {
      this.items.push(`Item ${i}`)
    }
  }

  totalCount(): number {
    return this.items.length
  }

  getData(index: number): string {
    return this.items[index]
  }
}

@Entry
@Component
struct ItemList {
  @State items: ItemDataSource = new ItemDataSource()

  build() {
    List() {
      LazyForEach(this.items, (item: string) => {
        ListItem() {
          Text(item)
            .fontSize(16)
            .padding(12)
        }
      }, (item: string) => item)
    }
    .width('100%')
    .height('100%')
    .cachedCount(10)
  }
}