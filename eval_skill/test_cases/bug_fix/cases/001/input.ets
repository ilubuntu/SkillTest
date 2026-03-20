// Bug: 使用ForEach渲染大量数据，快速滑动时崩溃
@Entry
@Component
struct ItemList {
  @State items: string[] = []

  aboutToAppear() {
    for (let i = 0; i < 10000; i++) {
      this.items.push(`Item ${i}`)
    }
  }

  build() {
    List() {
      ForEach(this.items, (item: string) => {
        ListItem() {
          Text(item)
            .fontSize(16)
            .padding(12)
        }
      })
    }
    .width('100%')
    .height('100%')
  }
}
