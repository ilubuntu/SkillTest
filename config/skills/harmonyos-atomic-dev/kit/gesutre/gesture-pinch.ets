/**
 * gesture-pinch — 捏合与旋转手势
 * PinchGesture 缩放、RotationGesture 旋转
 */
@ComponentV2
export struct GesturePinch {
  @Local imageScale: number = 1.0
  @Local imageAngle: number = 0
  @Local pinchScale: number = 1.0
  @Local rotateAngle: number = 0
  @Local statusText: string = '对下方图片使用双指捏合/旋转'

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('捏合与旋转手势')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20, bottom: 10 })

        Text(this.statusText)
          .fontSize(14)
          .fontColor('#666666')

        Row({ space: 24 }) {
          Column() {
            Text(`${this.imageScale.toFixed(2)}x`)
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor('#007DFF')
            Text('缩放')
              .fontSize(12)
              .margin({ top: 4 })
          }
          Column() {
            Text(`${this.imageAngle.toFixed(1)}°`)
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FF6B00')
            Text('旋转')
              .fontSize(12)
              .margin({ top: 4 })
          }
        }

        // 可捏合缩放 + 旋转的图片
        Stack() {
          Image($r('app.media.startIcon'))
            .width(160)
            .height(160)
            .objectFit(ImageFit.Cover)
            .scale({ x: this.imageScale, y: this.imageScale })
            .rotate({ angle: this.imageAngle })
        }
        .width('100%')
        .height(300)
        .gesture(
          GestureGroup(GestureMode.Parallel,
            PinchGesture({ fingers: 2 })
              .onActionStart(() => {
                this.statusText = '捏合开始'
              })
              .onActionUpdate((event: GestureEvent | undefined) => {
                if (event) {
                  this.imageScale = this.pinchScale * event.scale
                  this.statusText = `缩放: ${event.scale.toFixed(2)}x`
                }
              })
              .onActionEnd(() => {
                this.pinchScale = this.imageScale
                this.statusText = '捏合结束'
              }),
            RotationGesture({ fingers: 2 })
              .onActionStart(() => {
                this.statusText = '旋转开始'
              })
              .onActionUpdate((event: GestureEvent | undefined) => {
                if (event) {
                  this.imageAngle = this.rotateAngle + event.angle
                  this.statusText = `旋转角度: ${event.angle.toFixed(1)}°`
                }
              })
              .onActionEnd(() => {
                this.rotateAngle = this.imageAngle
                this.statusText = '旋转结束'
              })
          )
        )

        // 重置按钮
        Button('重置')
          .fontSize(14)
          .height(36)
          .backgroundColor('#999999')
          .onClick(() => {
            this.imageScale = 1.0
            this.imageAngle = 0
            this.pinchScale = 1.0
            this.rotateAngle = 0
            this.statusText = '已重置'
          })

        // 参数说明
        Text('参数说明')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 16 })

        Column({ space: 6 }) {
          Text('PinchGesture({ fingers: 2 })')
            .fontSize(13).fontColor('#666666')
          Text('  event.scale — 缩放倍数')
            .fontSize(13).fontColor('#666666')
          Text('  event.pinchCenterX/Y — 捏合中心点')
            .fontSize(13).fontColor('#666666')
          Text('RotationGesture({ fingers: 2 })')
            .fontSize(13).fontColor('#666666')
          Text('  event.angle — 旋转角度（弧度转角度需 * 180 / π）')
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
