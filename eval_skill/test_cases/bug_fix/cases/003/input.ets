// Bug: 组件销毁后定时器未清除，导致内存泄漏
@Entry
@Component
struct Dashboard {
  @State count: number = 0
  @State data: string = '加载中...'

  aboutToAppear() {
    setInterval(() => {
      this.count++
      this.data = `已刷新 ${this.count} 次`
    }, 5000)
  }

  build() {
    Column() {
      Text(this.data)
        .fontSize(20)
        .margin(20)
      Text(`计数: ${this.count}`)
        .fontSize(16)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}
