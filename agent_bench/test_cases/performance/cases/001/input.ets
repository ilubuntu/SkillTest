// ArkTS List组件性能优化参考实现
class MyDataSource implements IDataSource {
  private dataArray: string[] = []
  private listener: DataChangeListener | null = null

  constructor(data: string[]) {
    this.dataArray = data
  }

  totalCount(): number {
    return this.dataArray.length
  }

  getData(index: number): string {
    return this.dataArray[index]
  }

  registerDataChangeListener(listener: DataChangeListener): void {
    this.listener = listener
  }

  unregisterDataChangeListener(listener: DataChangeListener): void {
    this.listener = null
  }
}

@Entry
@Component
struct Index {
  private dataSource: MyDataSource = new MyDataSource([])

  aboutToAppear() {
    let data: string[] = []
    for (let i = 0; i < 1000; i++) {
      data.push(`Item ${i}`)
    }
    this.dataSource = new MyDataSource(data)
  }

  build() {
    List() {
      LazyForEach(this.dataSource, (item: string) => {
        ListItem() {
          Text(item)
            .fontSize(16)
            .padding(10)
        }
        .cachedCount(2)
      })
    }
    .width('100%')
    .height('100%')
  }
}
