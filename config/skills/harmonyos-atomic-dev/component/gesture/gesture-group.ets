/**
 * gesture-group — 组合手势
 * GestureGroup Sequence/Parallel/Exclusive 三种模式对比
 */
@ComponentV2
export struct GestureGroupDemo {
  @Local serialLog: string = '串行：长按后拖拽'
  @Local parallelTapCount: number = 0
  @Local parallelDoubleTapCount: number = 0
  @Local exclusiveResult: string = '互斥：单击 vs 双击'
  @Local serialOffsetX: number = 0
  @Local serialOffsetY: number = 0
  @Local serialBaseX: number = 0
  @Local serialBaseY: number = 0

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('组合手势 GestureGroup')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20, bottom: 10 })

        // Serial 串行：长按 → 拖拽
        Text('GestureMode.Sequence — 串行')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16 })

        Text(this.serialLog)
          .fontSize(13)
          .fontColor('#666666')

        Stack() {
          Column() {
            Text('长按后可拖拽')
              .fontSize(14)
              .fontColor(Color.White)
          }
          .width(100)
          .height(100)
          .justifyContent(FlexAlign.Center)
          .backgroundColor('#007DFF')
          .borderRadius(12)
          .translate({ x: this.serialOffsetX, y: this.serialOffsetY })
        }
        .width('100%')
        .height(200)
        .backgroundColor('#F0F0F0')
        .borderRadius(12)
        .margin({ left: 16, right: 16 })
        .gesture(
          GestureGroup(GestureMode.Sequence,
            LongPressGesture({ duration: 500 })
              .onAction(() => {
                this.serialLog = '长按成功，现在可以拖拽'
              }),
            PanGesture()
              .onActionUpdate((event: GestureEvent | undefined) => {
                if (event) {
                  this.serialOffsetX = this.serialBaseX + event.offsetX
                  this.serialOffsetY = this.serialBaseY + event.offsetY
                  this.serialLog = `串行拖拽中: (${event.offsetX.toFixed(0)}, ${event.offsetY.toFixed(0)})`
                }
              })
              .onActionEnd((event: GestureEvent | undefined) => {
                if (event) {
                  this.serialBaseX = this.serialBaseX + event.offsetX
                  this.serialBaseY = this.serialBaseY + event.offsetY
                }
                this.serialLog = '串行拖拽结束'
              })
          )
        )

        // Parallel 并行
        Text('GestureMode.Parallel — 并行')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 16 })

        Row({ space: 24 }) {
          Text(`单击: ${this.parallelTapCount}`)
            .fontSize(14)
          Text(`双击: ${this.parallelDoubleTapCount}`)
            .fontSize(14)
        }

        Column() {
          Text('单击 + 双击并行互不干扰')
            .fontSize(16)
            .fontColor(Color.White)
        }
        .width(200)
        .height(80)
        .justifyContent(FlexAlign.Center)
        .backgroundColor('#FF6B00')
        .borderRadius(12)
        .gesture(
          GestureGroup(GestureMode.Parallel,
            TapGesture({ count: 1 })
              .onAction(() => {
                this.parallelTapCount++
              }),
            TapGesture({ count: 2 })
              .onAction(() => {
                this.parallelDoubleTapCount++
              })
          )
        )

        // Exclusive 互斥
        Text('GestureMode.Exclusive — 互斥')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 16 })

        Text(this.exclusiveResult)
          .fontSize(13)
          .fontColor('#666666')

        Column() {
          Text('单击 或 双击（互斥，先识别到的生效）')
            .fontSize(14)
            .fontColor(Color.White)
        }
        .width(280)
        .height(80)
        .justifyContent(FlexAlign.Center)
        .backgroundColor('#E84026')
        .borderRadius(12)
        .gesture(
          GestureGroup(GestureMode.Exclusive,
            TapGesture({ count: 2 })
              .onAction(() => {
                this.exclusiveResult = '互斥：双击胜出'
              }),
            TapGesture({ count: 1 })
              .onAction(() => {
                this.exclusiveResult = '互斥：单击胜出'
              })
          )
        )

        // 模式对比表
        Text('三种模式对比')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 16 })

        Column({ space: 6 }) {
          Text('Sequence — 按顺序识别，前一个失败才尝试下一个')
            .fontSize(13).fontColor('#666666')
          Text('Parallel — 所有手势同时识别，互不干扰')
            .fontSize(13).fontColor('#666666')
          Text('Exclusive — 同时识别，最先完成的胜出')
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
