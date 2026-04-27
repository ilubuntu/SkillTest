/**
 * gesture-swipe — 滑动手势与触摸事件
 * SwipeGesture 快速滑动、onTouch 原始触摸事件
 */
@ComponentV2
export struct GestureSwipe {
  @Local swipeDirection: string = '快速滑动下方区域'
  @Local swipeSpeed: number = 0
  @Local touchType: string = ''
  @Local touchX: number = 0
  @Local touchY: number = 0

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('滑动手势与触摸事件')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20, bottom: 10 })

        // SwipeGesture
        Text('SwipeGesture 快速滑动')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16 })

        Text(this.swipeDirection)
          .fontSize(14)
          .fontColor('#666666')
        Text(`速度: ${this.swipeSpeed.toFixed(0)} vp/s`)
          .fontSize(14)
          .fontColor('#007DFF')

        Column() {
          Text('在此区域快速滑动')
            .fontSize(16)
            .fontColor('#999999')
        }
        .width('90%')
        .height(150)
        .justifyContent(FlexAlign.Center)
        .backgroundColor('#F0F0F0')
        .borderRadius(12)
        .gesture(
          SwipeGesture({ fingers: 1, direction: SwipeDirection.All, speed: 50 })
            .onAction((event: GestureEvent | undefined) => {
              if (event) {
                this.swipeSpeed = event.speed
                const angle: number = event.angle
                if (angle > -45 && angle < 45) {
                  this.swipeDirection = '向右滑动 →'
                } else if (angle > 45 && angle < 135) {
                  this.swipeDirection = '向下滑动 ↓'
                } else if (angle > -135 && angle < -45) {
                  this.swipeDirection = '向上滑动 ↑'
                } else {
                  this.swipeDirection = '向左滑动 ←'
                }
              }
            })
        )

        // onTouch 原始触摸
        Text('onTouch 原始触摸事件')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 16 })

        Text(`${this.touchType} 位置: (${this.touchX.toFixed(0)}, ${this.touchY.toFixed(0)})`)
          .fontSize(14)
          .fontColor('#FF6B00')

        Column() {
          Text('触摸此区域')
            .fontSize(16)
            .fontColor('#999999')
        }
        .width('90%')
        .height(150)
        .justifyContent(FlexAlign.Center)
        .backgroundColor('#FFF3E0')
        .borderRadius(12)
        .onTouch((event: TouchEvent) => {
          if (event.type === TouchType.Down) {
            this.touchType = '按下 Down'
          } else if (event.type === TouchType.Move) {
            this.touchType = '移动 Move'
          } else if (event.type === TouchType.Up) {
            this.touchType = '抬起 Up'
          }
          if (event.changedTouches.length > 0) {
            this.touchX = event.changedTouches[0].x
            this.touchY = event.changedTouches[0].y
          }
        })

        // 参数说明
        Text('SwipeGesture 参数')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 16 })

        Column({ space: 6 }) {
          Text('fingers — 触发手指数')
            .fontSize(13).fontColor('#666666')
          Text('direction — Horizontal / Vertical / All')
            .fontSize(13).fontColor('#666666')
          Text('speed — 最小速度阈值（vp/s），默认 100')
            .fontSize(13).fontColor('#666666')
        }
        .alignItems(HorizontalAlign.Start)
        .margin({ left: 16 })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
  }
}
