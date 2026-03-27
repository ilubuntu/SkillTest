class ItemDataSource implements IDataSource {
  private dataArray: string[] = []

  totalCount(): number {
    return this.dataArray.length
  }

  getData(index: number): string {
    return this.dataArray[index]
  }

  pushData(item: string): void {
    this.dataArray.push(item)
  }

  pushAllItems(items: string[]): void {
    this.dataArray.push(...items)
  }
}

@Entry
@Component
struct ItemList {
  private dataSource: ItemDataSource = new ItemDataSource()
  private timerId: number = -1

  aboutToAppear() {
    const items: string[] = []
    for (let i = 0; i < 10000; i++) {
      items.push(`Item ${i}`)
    }
    this.dataSource.pushAllItems(items)
  }

  aboutToDisappear() {
    if (this.timerId !== -1) {
      clearInterval(this.timerId)
      this.timerId = -1
    }
  }

  build() {
    List() {
      LazyForEach(this.dataSource, (item: string) => {
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