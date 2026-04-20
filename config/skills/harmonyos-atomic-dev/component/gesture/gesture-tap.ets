/**
 * gesture-tap — 点击与长按手势
 * TapGesture 单击/双击、LongPressGesture 长按/持续回调
 */
@ComponentV2
export struct GestureTap {
  @Local tapCount: number = 0
  @Local doubleTapCount: number = 0
  @Local longPressCount: number = 0
  @Local statusText: string = '尝试点击或长按下方色块'

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('点击与长按手势')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20, bottom: 10 })

        Text(this.statusText)
          .fontSize(14)
          .fontColor('#666666')
          .width('90%')
          .textAlign(TextAlign.Center)

        // 统计面板
        Row({ space: 24 }) {
          Column() {
            Text(`${this.tapCount}`)
              .fontSize(28)
              .fontWeight(FontWeight.Bold)
              .fontColor('#007DFF')
            Text('单击')
              .fontSize(12)
              .margin({ top: 4 })
          }
          Column() {
            Text(`${this.doubleTapCount}`)
              .fontSize(28)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FF6B00')
            Text('双击')
              .fontSize(12)
              .margin({ top: 4 })
          }
          Column() {
            Text(`${this.longPressCount}`)
              .fontSize(28)
              .fontWeight(FontWeight.Bold)
              .fontColor('#E84026')
            Text('长按')
              .fontSize(12)
              .margin({ top: 4 })
          }
        }
        .margin({ top: 12 })

        // 单击
        Text('单击 TapGesture({ count: 1 })')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 16 })

        Column() {
          Text('单击我')
            .fontSize(18)
            .fontColor(Color.White)
        }
        .width(160)
        .height(80)
        .justifyContent(FlexAlign.Center)
        .backgroundColor('#007DFF')
        .borderRadius(12)
        .gesture(
          TapGesture({ count: 1 })
            .onAction(() => {
              this.tapCount++
              this.statusText = `单击触发，累计 ${this.tapCount} 次`
            })
        )

        // 双击
        Text('双击 TapGesture({ count: 2 })')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 16 })

        Column() {
          Text('双击我')
            .fontSize(18)
            .fontColor(Color.White)
        }
        .width(160)
        .height(80)
        .justifyContent(FlexAlign.Center)
        .backgroundColor('#FF6B00')
        .borderRadius(12)
        .gesture(
          TapGesture({ count: 2 })
            .onAction(() => {
              this.doubleTapCount++
              this.statusText = `双击触发，累计 ${this.doubleTapCount} 次`
            })
        )

        // 长按
        Text('长按 LongPressGesture')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 16 })

        Column() {
          Text('长按我（持续回调）')
            .fontSize(16)
            .fontColor(Color.White)
        }
        .width(200)
        .height(80)
        .justifyContent(FlexAlign.Center)
        .backgroundColor('#E84026')
        .borderRadius(12)
        .gesture(
          LongPressGesture({ fingers: 1, repeat: true, duration: 500 })
            .onAction((event: GestureEvent | undefined) => {
              if (event && event.repeat) {
                this.longPressCount++
                this.statusText = `长按持续触发中，累计 ${this.longPressCount} 次`
              }
            })
            .onActionEnd(() => {
              this.statusText = `长按结束，累计 ${this.longPressCount} 次`
            })
        )
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
  }
}
