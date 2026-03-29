@Entry
@Component
struct Dashboard {
  @State count: number = 0
  @State data: string = '加载中...'
  private timer: number = -1

  aboutToAppear() {
    this.timer = setInterval(() => {
      this.count++
      this.data = `已刷新 ${this.count} 次`
    }, 5000)
  }

  aboutToDisappear() {
    if (this.timer !== -1) {
      clearInterval(this.timer)
      this.timer = -1
    }
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