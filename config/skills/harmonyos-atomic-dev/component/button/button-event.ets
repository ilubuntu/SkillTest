/**
 * button-event — Button 事件处理与状态控制
 * 展示 onClick 事件、enable/disable 状态、waiting 等待态
 * 元服务兼容性：onClick / enabled 均可用（基础组件通用属性/事件）
 */
import { BusinessError } from '@kit.BasicServicesKit'

@ComponentV2
export struct ButtonEvent {
  @Local clickCount: number = 0
  @Local isDisabled: boolean = false
  @Local isWaiting: boolean = false
  @Local resultText: string = '等待操作...'
  @Local lastClickTime: string = ''

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('Button 事件与状态')
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

        // 点击计数
        Text('onClick 事件')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Row({ space: 12 }) {
          Column() {
            Text(`${this.clickCount}`)
              .fontSize(32)
              .fontWeight(FontWeight.Bold)
              .fontColor('#007DFF')
            Text('点击次数')
              .fontSize(12)
              .margin({ top: 4 })
          }

          Button('点击计数 +1')
            .type(ButtonType.Normal)
            .borderRadius(8)
            .backgroundColor('#007DFF')
            .onClick(() => {
              try {
                this.clickCount++
                const now = new Date()
                this.lastClickTime = `${now.getHours()}:${now.getMinutes()}:${now.getSeconds()}`
                this.resultText = `第 ${this.clickCount} 次点击，时间: ${this.lastClickTime}`
              } catch (err) {
                const e = err as BusinessError
                this.resultText = `错误: ${e.code} - ${e.message}`
              }
            })

          Button('重置')
            .type(ButtonType.Normal)
            .borderRadius(8)
            .backgroundColor('#999999')
            .onClick(() => {
              this.clickCount = 0
              this.resultText = '已重置'
            })
        }
        .width('90%')
        .justifyContent(FlexAlign.SpaceAround)

        // enable / disable 切换
        Text('enabled / disabled 状态')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Button(this.isDisabled ? '当前: 已禁用' : '当前: 已启用')
          .type(ButtonType.Normal)
          .width('90%')
          .height(40)
          .borderRadius(8)
          .backgroundColor(this.isDisabled ? '#CCCCCC' : '#00B578')
          .fontColor(this.isDisabled ? '#999999' : Color.White)
          .enabled(!this.isDisabled)
          .onClick(() => {
            this.resultText = '按钮被点击（enabled 状态下）'
          })

        Button('切换 enabled / disabled')
          .type(ButtonType.Normal)
          .width('90%')
          .height(40)
          .borderRadius(8)
          .backgroundColor('#FF9800')
          .onClick(() => {
            this.isDisabled = !this.isDisabled
            this.resultText = this.isDisabled ? '按钮已禁用，不可点击' : '按钮已启用，可以点击'
          })

        // waiting 效果（使用定时器模拟）
        Text('waiting 等待态模拟')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Button(this.isWaiting ? '处理中...' : '触发等待态')
          .type(ButtonType.Capsule)
          .width('90%')
          .height(40)
          .backgroundColor(this.isWaiting ? '#FF9800' : '#E84026')
          .enabled(!this.isWaiting)
          .onClick(() => {
            this.isWaiting = true
            this.resultText = '等待中，3秒后恢复...'
            setTimeout(() => {
              this.isWaiting = false
              this.resultText = '等待结束，按钮已恢复'
            }, 3000)
          })

        // API 说明区
        Column() {
          Text('API 说明')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 8 })
          Text('.onClick(() => { ... }) — 点击事件回调')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('.enabled(boolean) — 控制按钮是否可交互')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('waiting: true 时显示转圈等待效果（JS卡片）')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('ArkTS 中通过 enabled + 定时器模拟等待态')
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
