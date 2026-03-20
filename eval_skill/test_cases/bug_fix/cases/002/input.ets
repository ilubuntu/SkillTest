// Bug: 直接push修改@State数组，UI不刷新
@Entry
@Component
struct TodoList {
  @State items: string[] = ['学习ArkTS', '写单元测试']

  build() {
    Column() {
      Button('添加任务')
        .onClick(() => {
          this.items.push(`新任务 ${this.items.length + 1}`)
        })

      List() {
        ForEach(this.items, (item: string, index: number) => {
          ListItem() {
            Row() {
              Text(item).fontSize(16)
              Button('删除')
                .onClick(() => {
                  this.items.splice(index, 1)
                })
            }
            .width('100%')
            .justifyContent(FlexAlign.SpaceBetween)
            .padding(12)
          }
        })
      }
    }
    .width('100%')
    .height('100%')
  }
}
