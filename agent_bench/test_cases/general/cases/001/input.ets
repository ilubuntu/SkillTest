// 通用ArkTS代码任务
// 请实现一个简单的计数器组件，包含增加和减少按钮

@Entry
@Component
struct Index {
  @State count: number = 0

  build() {
    Column() {
      Text(`${this.count}`)
        .fontSize(50)

      Row() {
        Button('+1')
          .onClick(() => {
            this.count++
          })

        Button('-1')
          .onClick(() => {
            this.count--
          })
      }
    }
  }
}
