// 需求分析任务
// 请根据以下需求描述生成对应的ArkTS代码：
// 1. 用户可以添加待办事项
// 2. 用户可以标记事项为已完成
// 3. 用户可以删除事项
// 4. 未完成和已完成的事项分开显示

@Entry
@Component
struct TodoList {
  @State items: TodoItem[] = []
  @State newText: string = ''

  build() {
    Column() {
      Row() {
        TextInput({ placeholder: '添加待办' })
          .onChange((v) => { this.newText = v })
        Button('添加')
          .onClick(() => {
            if (this.newText !== '') {
              this.items.push({ id: Date.now(), text: this.newText, done: false })
              this.newText = ''
            }
          })
      }

      Text('待完成')
      ForEach(this.items.filter((i) => !i.done), (item) => {
        Row() {
          Checkbox()
            .checked(item.done)
            .onChange((v) => { item.done = v })
          Text(item.text)
        }
      })

      Text('已完成')
      ForEach(this.items.filter((i) => i.done), (item) => {
        Row() {
          Checkbox()
            .checked(item.done)
            .onChange((v) => { item.done = v })
          Text(item.text)
          Button('删除')
            .onClick(() => {
              let idx = this.items.indexOf(item)
              if (idx >= 0) this.items.splice(idx, 1)
            })
        }
      })
    }
  }
}

interface TodoItem {
  id: number
  text: string
  done: boolean
}
