/**
 * image-event — 图片交互事件场景
 * 加载状态、点击计数、双击缩放、长按、拖拽
 */
@ComponentV2
export struct ImageEvent {
  @Local loadStatus: string = '等待加载...'
  @Local imageScale: number = 1.0
  @Local clickCount: number = 0

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('图片交互事件')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20, bottom: 10 })

        Text(`状态: ${this.loadStatus}`)
          .fontSize(14)
          .fontColor('#666666')
        Text(`点击次数: ${this.clickCount}`)
          .fontSize(14)
          .fontColor('#666666')

        // 网络图片 + 加载回调 + 双击缩放
        Image('https://img1.baidu.com/it/u=1407750889,3441968730&fm=253&fmt=auto&app=138&f=JPEG')
          .width(250 * this.imageScale)
          .height(180 * this.imageScale)
          .alt($r('app.media.icon'))
          .objectFit(ImageFit.Cover)
          .interpolation(ImageInterpolation.High)
          .animation({ duration: 300 })
          .onComplete(() => {
            this.loadStatus = '加载完成'
          })
          .onError(() => {
            this.loadStatus = '加载失败，显示占位图'
          })
          .onClick(() => {
            this.clickCount++
          })
          .gesture(
            GestureGroup(GestureMode.Exclusive,
              LongPressGesture()
                .onAction(() => {
                  this.loadStatus = '长按触发'
                }),
              TapGesture({ count: 2 })
                .onAction(() => {
                  this.imageScale = this.imageScale === 1.0 ? 1.5 : 1.0
                  this.loadStatus = `双击缩放: ${this.imageScale}x`
                })
            )
          )

        // 手势交互
        Text('手势交互')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 16 })

        Row({ space: 16 }) {
          Image($r('app.media.icon'))
            .width(80)
            .height(80)
            .objectFit(ImageFit.Cover)
            .clip(true)
            .borderRadius(10)
            .gesture(
              PanGesture()
                .onActionStart(() => {
                  this.loadStatus = '拖拽开始'
                })
                .onActionEnd(() => {
                  this.loadStatus = '拖拽结束'
                })
            )

          Image($r('app.media.startIcon'))
            .width(80)
            .height(80)
            .objectFit(ImageFit.Cover)
            .clip(true)
            .borderRadius(10)
            .gesture(
              PinchGesture()
                .onActionStart(() => {
                  this.loadStatus = '捏合手势开始'
                })
            )
        }
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
  }
}
