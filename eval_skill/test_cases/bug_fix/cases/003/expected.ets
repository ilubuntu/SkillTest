// 修复: 保存定时器ID，在aboutToDisappear中清除
@Entry
@Component
struct Dashboard {
  @State count: number = 0
  @State data: string = '加载中...'
  private timerId: number = -1

  aboutToAppear() {
    this.timerId = setInterval(() => {
      this.count++
      this.data = `已刷新 ${this.count} 次`
    }, 5000)
  }

  aboutToDisappear() {
    if (this.timerId !== -1) {
      clearInterval(this.timerId)
      this.timerId = -1
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
