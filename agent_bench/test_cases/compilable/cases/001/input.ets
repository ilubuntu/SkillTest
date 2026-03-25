// ArkTS List组件可编译参考实现
@Entry
@Component
struct Index {
  @State dataArray: Array<string> = ['Item 1', 'Item 2', 'Item 3', 'Item 4', 'Item 5']

  build() {
    Column() {
      Text('List Demo')
        .fontSize(24)
        .margin(10)

      List() {
        ForEach(this.dataArray, (item: string, index: number) => {
          ListItem() {
            Text(item)
              .fontSize(16)
              .padding(10)
          }
        })
      }
      .width('100%')
      .height('80%')
    }
    .width('100%')
    .height('100%')
  }
}
