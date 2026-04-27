/**
 * gesture-pan — 拖拽手势
 * PanGesture 自由拖拽、方向限制拖拽
 */
@ComponentV2
export struct GesturePan {
  @Local offsetX: number = 0
  @Local offsetY: number = 0
  @Local positionX: number = 0
  @Local positionY: number = 0
  @Local statusText: string = '拖拽下方色块自由移动'

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('拖拽手势 PanGesture')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20, bottom: 10 })

        Text(this.statusText)
          .fontSize(14)
          .fontColor('#666666')

        // 自由拖拽区域
        Text('自由拖拽')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Stack() {
          Column() {
            Text('拖我')
              .fontSize(16)
              .fontColor(Color.White)
          }
          .width(80)
          .height(80)
          .justifyContent(FlexAlign.Center)
          .backgroundColor('#007DFF')
          .borderRadius(12)
          .translate({ x: this.offsetX, y: this.offsetY })
          .gesture(
            PanGesture({ fingers: 1, direction: PanDirection.All, distance: 5 })
              .onActionStart(() => {
                this.statusText = '拖拽开始'
              })
              .onActionUpdate((event: GestureEvent | undefined) => {
                if (event) {
                  this.offsetX = this.positionX + event.offsetX
                  this.offsetY = this.positionY + event.offsetY
                  this.statusText = `offset: (${event.offsetX.toFixed(0)}, ${event.offsetY.toFixed(0)})`
                }
              })
              .onActionEnd((event: GestureEvent | undefined) => {
                if (event) {
                  this.positionX = this.positionX + event.offsetX
                  this.positionY = this.positionY + event.offsetY
                }
                this.statusText = '拖拽结束'
              })
          )
        }
        .width('100%')
        .height(250)
        .backgroundColor('#F5F5F5')
        .borderRadius(12)
        .margin({ left: 16, right: 16 })

        // 重置按钮
        Button('重置位置')
          .fontSize(14)
          .height(36)
          .backgroundColor('#999999')
          .onClick(() => {
            this.offsetX = 0
            this.offsetY = 0
            this.positionX = 0
            this.positionY = 0
            this.statusText = '已重置'
          })

        // 方向限制说明
        Text('direction 参数')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 16 })

        Column({ space: 8 }) {
          Text('PanDirection.All — 全方向')
            .fontSize(13).fontColor('#666666')
          Text('PanDirection.Horizontal — 仅水平')
            .fontSize(13).fontColor('#666666')
          Text('PanDirection.Vertical — 仅垂直')
            .fontSize(13).fontColor('#666666')
          Text('PanDirection.Left / Right / Up / Down')
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
