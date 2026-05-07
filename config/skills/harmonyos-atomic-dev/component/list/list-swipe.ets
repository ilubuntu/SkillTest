/**
 * list-swipe — 列表项滑动操作
 * 展示 ListItem swipeAction 属性：左滑/右滑显示操作按钮、删除功能
 * 元服务兼容性：swipeAction API 9+，元服务 API 11+ 可用
 * 注意：ListItemSwipeActionManager (API 21+) 在元服务中可能受限
 */
import { BusinessError } from '@kit.BasicServicesKit'

@ComponentV2
export struct ListSwipe {
  @Local dataList: string[] = ['微信消息', 'QQ消息', '短信通知', '系统更新', '应用商店',
    '邮件提醒', '日历事件', '闹钟提醒', '天气预报', '新闻推送']
  @Local resultText: string = '左滑显示操作按钮，长距离滑动触发删除'
  private scroller: ListScroller = new ListScroller()

  @Builder
  swipeStartAction() {
    Row() {
      Text('标为已读')
        .fontSize(14)
        .fontColor('#FFFFFF')
        .padding({ left: 16, right: 16 })
    }
    .justifyContent(FlexAlign.Center)
    .width(100)
    .height('100%')
    .backgroundColor('#4CAF50')
  }

  @Builder
  swipeEndAction(item: string) {
    Row() {
      Text('删除')
        .fontSize(14)
        .fontColor('#FFFFFF')
        .padding({ left: 16, right: 16 })
        .onClick(() => {
          const index = this.dataList.indexOf(item)
          if (index >= 0) {
            this.dataList = [...this.dataList.slice(0, index), ...this.dataList.slice(index + 1)]
            this.resultText = `已删除: ${item}，剩余 ${this.dataList.length} 项`
          }
        })
    }
    .justifyContent(FlexAlign.Center)
    .width(80)
    .height('100%')
    .backgroundColor('#F44336')
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('列表项滑动操作')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20, bottom: 10 })

        // 结果展示区
        Column() {
          Text(this.resultText)
            .fontSize(14)
            .fontColor('#333333')
            .width('100%')
            .padding(12)
        }
        .width('90%')
        .backgroundColor('#F5F5F5')
        .borderRadius(8)

        // 列表预览
        Text('滑动操作预览 (左滑/右滑)')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        List({ space: 2, scroller: this.scroller }) {
          ForEach(this.dataList, (item: string, index?: number) => {
            ListItem() {
              Row() {
                Text(`${(index ?? 0) + 1}`)
                  .fontSize(14)
                  .fontColor('#FFFFFF')
                  .width(30)
                  .height(30)
                  .textAlign(TextAlign.Center)
                  .borderRadius(15)
                  .backgroundColor('#9C27B0')

                Text(item)
                  .fontSize(15)
                  .margin({ left: 12 })
                  .layoutWeight(1)

                Text('10:30')
                  .fontSize(12)
                  .fontColor('#999999')
              }
              .width('100%')
              .padding({ left: 16, right: 16, top: 14, bottom: 14 })
              .backgroundColor('#FFFFFF')
            }
            .swipeAction({
              start: {
                builder: () => { this.swipeStartAction() }
              },
              end: {
                builder: () => { this.swipeEndAction(item) },
                actionAreaDistance: 56,
                onAction: () => {
                  this.dataList = this.dataList.filter(d => d !== item)
                  this.resultText = `长滑删除: ${item}，剩余 ${this.dataList.length} 项`
                },
                onEnterActionArea: () => {
                  this.resultText = `进入删除区域: ${item}`
                },
                onExitActionArea: () => {
                  this.resultText = `离开删除区域: ${item}`
                }
              },
              edgeEffect: SwipeEdgeEffect.Spring
            })
          }, (item: string) => item)
        }
        .width('90%')
        .height(360)
        .borderRadius(8)
        .backgroundColor('#F5F5F5')

        // 操作按钮
        Text('操作')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Row({ space: 8 }) {
          Button('关闭所有滑动')
            .fontSize(13)
            .width(120)
            .height(36)
            .onClick(() => {
              try {
                this.scroller.closeAllSwipeActions()
                this.resultText = '已关闭所有滑动菜单'
              } catch (error) {
                this.resultText = `错误: ${(error as BusinessError).message}`
              }
            })
          Button('重置列表')
            .fontSize(13)
            .width(100)
            .height(36)
            .onClick(() => {
              this.dataList = ['微信消息', 'QQ消息', '短信通知', '系统更新', '应用商店',
                '邮件提醒', '日历事件', '闹钟提醒', '天气预报', '新闻推送']
              this.resultText = '列表已重置'
            })
        }

        // ListItemSwipeActionManager 限制提示
        Column() {
          Text('ListItemSwipeActionManager (API 21+)')
            .fontSize(13)
            .fontColor('#FF6B00')
            .fontWeight(FontWeight.Medium)
            .width('100%')
          Text('该 API 从 API 21 开始支持在元服务中使用，提供 expand/collapse 编程式控制')
            .fontSize(12)
            .fontColor('#996600')
            .margin({ top: 4 })
            .width('100%')
        }
        .width('90%')
        .backgroundColor('#FFF3CD')
        .borderRadius(8)
        .padding(12)

        // API 说明区
        Column() {
          Text('API 说明')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 8 })
          Text('.swipeAction(value: SwipeActionOptions)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('SwipeActionOptions: { start?, end?, edgeEffect? }')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('SwipeEdgeEffect: Spring(弹性) / None(刚性)')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('actionAreaDistance: 长距滑动删除阈值，默认 56vp')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('ListScroller.closeAllSwipeActions() — 关闭所有滑动菜单')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('元服务：API 11+ 可用')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
        }
        .width('90%')
        .backgroundColor('#FFF9E6')
        .borderRadius(8)
        .padding(12)
        .margin({ top: 8 })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
  }
}
