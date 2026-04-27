/**
 * gesture-swipe-delete — 左滑删除卡片
 * PanGesture 水平拖拽 + translate 偏移 + 状态管理
 */
interface CardItem {
  id: number
  title: string
  desc: string
  color: string
}

@ComponentV2
export struct GestureSwipeDelete {
  @Local cards: CardItem[] = [
    { id: 1, title: '系统通知', desc: '您有3条未读消息', color: '#007DFF' },
    { id: 2, title: '日程提醒', desc: '下午2:00 项目评审会议', color: '#FF6B00' },
    { id: 3, title: '运动达标', desc: '今日步数已达到10000步', color: '#4CAF50' },
    { id: 4, title: '应用更新', desc: 'MapKit有新版本可用', color: '#9C27B0' },
    { id: 5, title: '支付成功', desc: '订单已支付 ¥128.00', color: '#F44336' },
  ]
  @Local offsetXs: number[] = [0, 0, 0, 0, 0]
  @Local statusText: string = '左滑卡片查看删除操作'

  private readonly DELETE_THRESHOLD: number = -120
  private readonly SNAP_THRESHOLD: number = -60

  private getCardIndex(id: number): number {
    for (let i = 0; i < this.cards.length; i++) {
      if (this.cards[i].id === id) {
        return i
      }
    }
    return -1
  }

  private resetAllOffsets() {
    this.offsetXs = this.cards.map(() => 0)
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('左滑删除卡片')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20, bottom: 10 })

        Text(this.statusText)
          .fontSize(14)
          .fontColor('#666666')

        // 重置按钮
        Button('重置卡片')
          .fontSize(14)
          .height(36)
          .backgroundColor('#999999')
          .onClick(() => {
            this.cards = [
              { id: 1, title: '系统通知', desc: '您有3条未读消息', color: '#007DFF' },
              { id: 2, title: '日程提醒', desc: '下午2:00 项目评审会议', color: '#FF6B00' },
              { id: 3, title: '运动达标', desc: '今日步数已达到10000步', color: '#4CAF50' },
              { id: 4, title: '应用更新', desc: 'MapKit有新版本可用', color: '#9C27B0' },
              { id: 5, title: '支付成功', desc: '订单已支付 ¥128.00', color: '#F44336' },
            ]
            this.offsetXs = [0, 0, 0, 0, 0]
            this.statusText = '已重置'
          })

        // 卡片列表
        ForEach(this.cards, (card: CardItem) => {
          Stack({ alignContent: Alignment.End }) {
            // 底层：删除按钮
            Button('删除')
              .fontSize(16)
              .fontColor(Color.White)
              .backgroundColor('#F44336')
              .borderRadius(12)
              .width(100)
              .height('100%')
              .onClick(() => {
                const idx: number = this.getCardIndex(card.id)
                this.cards.splice(idx, 1)
                this.offsetXs.splice(idx, 1)
                this.statusText = `已删除「${card.title}」`
              })

            // 上层：卡片内容
            Row({ space: 12 }) {
              Column() {
                Text(card.title.charAt(0))
                  .fontSize(20)
                  .fontColor(Color.White)
                  .fontWeight(FontWeight.Bold)
              }
              .width(44)
              .height(44)
              .justifyContent(FlexAlign.Center)
              .borderRadius(22)
              .backgroundColor(card.color)

              Column({ space: 4 }) {
                Text(card.title)
                  .fontSize(16)
                  .fontWeight(FontWeight.Medium)
                Text(card.desc)
                  .fontSize(13)
                  .fontColor('#999999')
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 12, bottom: 12 })
            .backgroundColor(Color.White)
            .borderRadius(12)
            .shadow({ radius: 4, color: '#1A000000', offsetX: 0, offsetY: 2 })
            .translate({
              x: this.offsetXs[this.getCardIndex(card.id)] !== undefined ?
                this.offsetXs[this.getCardIndex(card.id)] : 0
            })
            .gesture(
              PanGesture({ fingers: 1, direction: PanDirection.Horizontal, distance: 5 })
                .onActionStart(() => {
                  // 收起其他卡片
                  this.resetAllOffsets()
                })
                .onActionUpdate((event: GestureEvent | undefined) => {
                  if (event) {
                    const idx: number = this.getCardIndex(card.id)
                    if (idx >= 0) {
                      const newOffset: number = Math.min(0, Math.max(-160, event.offsetX))
                      const offsets: number[] = [...this.offsetXs]
                      offsets[idx] = newOffset
                      this.offsetXs = offsets
                    }
                  }
                })
                .onActionEnd((event: GestureEvent | undefined) => {
                  if (event) {
                    const idx: number = this.getCardIndex(card.id)
                    if (idx >= 0) {
                      const offsets: number[] = [...this.offsetXs]
                      if (event.offsetX < this.SNAP_THRESHOLD) {
                        offsets[idx] = this.DELETE_THRESHOLD
                        this.statusText = `「${card.title}」可删除，点击红色按钮确认`
                      } else {
                        offsets[idx] = 0
                        this.statusText = '左滑卡片查看删除操作'
                      }
                      this.offsetXs = offsets
                    }
                  }
                })
            )
          }
          .width('90%')
          .height(68)
          .borderRadius(12)
        }, (card: CardItem) => card.id.toString())

        // 使用说明
        Text('实现说明')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 16 })

        Column({ space: 6 }) {
          Text('PanGesture Horizontal — 仅水平方向拖拽')
            .fontSize(13).fontColor('#666666')
          Text('translate({ x }) — 控制卡片偏移露出删除按钮')
            .fontSize(13).fontColor('#666666')
          Text('Stack + alignContent(End) — 底层放删除按钮')
            .fontSize(13).fontColor('#666666')
          Text('SNAP_THRESHOLD — 超过阈值自动吸附到删除位')
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
