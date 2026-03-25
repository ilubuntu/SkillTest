// ArkTS List页面工程参考实现
@Entry
@Component
struct Index {
  @State message: string = 'Hello World'
  @State dataArray: string[] = []

  aboutToAppear() {
    // 模拟加载数据
    for (let i = 0; i < 100; i++) {
      this.dataArray.push(`Item ${i}`)
    }
  }

  build() {
    Column() {
      Text(this.message)
        .fontSize(24)
        .margin(10)

      List() {
        ForEach(this.dataArray, (item: string) => {
          ListItem() {
            Text(item)
              .fontSize(16)
              .padding(10)
          }
        })
      }
      .height('100%')
    }
    .width('100%')
    .height('100%')
  }
}
