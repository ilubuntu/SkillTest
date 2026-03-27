@Entry
@Component
struct TodoList {
  @State items: string[] = ['学习ArkTS', '写单元测试']

  build() {
    Column() {
      Button('添加任务')
        .onClick(() => {
          this.items = [...this.items, `新任务 ${this.items.length + 1}`]
        })

      List() {
        ForEach(this.items, (item: string, index: number) => {
          ListItem() {
            Row() {
              Text(item).fontSize(16)
              Button('删除')
                .onClick(() => {
                  this.items = this.items.filter((_, i) => i !== index)
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
