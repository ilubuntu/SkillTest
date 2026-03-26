import { IDataSource, DataChangeListener } from '@ohos.data.dataSource'

class BasicDataSource implements IDataSource {
  private listeners: DataChangeListener[] = []
  private dataArray: string[] = []

  totalCount(): number {
    return this.dataArray.length
  }

  getData(index: number): string {
    return this.dataArray[index]
  }

  registerDataChangeListener(listener: DataChangeListener): void {
    if (this.listeners.indexOf(listener) < 0) {
      this.listeners.push(listener)
    }
  }

  unregisterDataChangeListener(listener: DataChangeListener): void {
    const pos = this.listeners.indexOf(listener)
    if (pos >= 0) {
      this.listeners.splice(pos, 1)
    }
  }

  pushData(data: string): void {
    this.dataArray.push(data)
    this.listeners.forEach(listener => {
      listener.onDataAdd(this.dataArray.length - 1)
    })
  }
}

@Entry
@Component
struct ItemList {
  @State items: BasicDataSource = new BasicDataSource()

  aboutToAppear() {
    for (let i = 0; i < 10000; i++) {
      this.items.pushData(`Item ${i}`)
    }
  }

  build() {
    List() {
      LazyForEach(this.items, (item: string) => {
        ListItem() {
          Text(item)
            .fontSize(16)
            .padding(12)
        }
      }, (item: string) => item)
      .cachedCount(10)
    }
    .width('100%')
    .height('100%')
  }
}