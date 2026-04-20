@ComponentV2
export struct ForEachBasic {
  @Local items: string[] = ['Item 1', 'Item 2', 'Item 3']

  build() {
    List({ space: 8 }) {
      //
      ForEach(this.items, (item: string, index: number) => {
        ListItem() {
          Row({ space: 12 }) {
            Text(`${index + 1}`)
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .width(40)

            Text(item)
              .fontSize(16)
              .layoutWeight(1)
          }
          .width('100%')
          .height(60)
          .padding({ left: 16, right: 16 })
          .backgroundColor(Color.White)
        }
      })
    }
    .width('100%')
    .height(300)
  }
}