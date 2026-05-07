/**
 * button-progress — ProgressButton 进度按钮
 * 展示带下载进度的文本按钮，支持自定义颜色和圆角
 * 元服务兼容性：从 API version 11 开始支持在元服务中使用
 */
import { ProgressButton } from '@kit.ArkUI'

@ComponentV2
export struct ButtonProgress {
  @Local progressIndex: number = 0
  @Local textState: string = '下载'
  @Local buttonWidth: number = 200
  @Local isRunning: boolean = false
  @Local enableState: boolean = true
  @Local resultText: string = '点击按钮开始模拟下载'
  @Local timerId: number = -1

  startProgress(): void {
    if (this.isRunning && this.progressIndex < 100) {
      this.textState = '继续'
    }
    this.isRunning = !this.isRunning
    if (this.isRunning) {
      this.resultText = '下载进行中...'
      this.timerId = setInterval(() => {
        if (this.isRunning) {
          if (this.progressIndex >= 100) {
            clearInterval(this.timerId)
          } else {
            this.progressIndex++
            if (this.progressIndex >= 100) {
              this.textState = '已完成'
              this.enableState = false
              this.isRunning = false
              this.resultText = '下载完成!'
            }
          }
        } else {
          clearInterval(this.timerId)
        }
      }, 50) as number
    } else {
      this.resultText = '已暂停'
      if (this.timerId !== -1) {
        clearInterval(this.timerId)
      }
    }
  }

  resetProgress(): void {
    if (this.timerId !== -1) {
      clearInterval(this.timerId)
    }
    this.progressIndex = 0
    this.textState = '下载'
    this.isRunning = false
    this.enableState = true
    this.resultText = '已重置，点击按钮重新开始'
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('ProgressButton 进度按钮')
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

        // 进度展示
        Row({ space: 24 }) {
          Column() {
            Text(`${this.progressIndex}%`)
              .fontSize(28)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.progressIndex >= 100 ? '#00B578' : '#007DFF')
            Text('当前进度')
              .fontSize(12)
              .margin({ top: 4 })
          }
          Column() {
            Text(this.enableState ? '可点击' : '已完成')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.enableState ? '#FF9800' : '#00B578')
            Text('按钮状态')
              .fontSize(12)
              .margin({ top: 4 })
          }
        }
        .margin({ top: 8 })

        // 进度按钮
        Text('默认样式进度按钮')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        ProgressButton({
          progress: this.progressIndex,
          progressButtonWidth: this.buttonWidth,
          content: this.textState,
          enable: this.enableState,
          clickCallback: () => {
            this.startProgress()
          }
        })

        // 宽度控制
        Text('按钮宽度控制')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Row({ space: 8 }) {
          Button('120vp')
            .type(ButtonType.Normal)
            .borderRadius(8)
            .backgroundColor('#007DFF')
            .fontSize(12)
            .onClick(() => { this.buttonWidth = 120 })
          Button('200vp')
            .type(ButtonType.Normal)
            .borderRadius(8)
            .backgroundColor('#007DFF')
            .fontSize(12)
            .onClick(() => { this.buttonWidth = 200 })
          Button('300vp')
            .type(ButtonType.Normal)
            .borderRadius(8)
            .backgroundColor('#007DFF')
            .fontSize(12)
            .onClick(() => { this.buttonWidth = 300 })
        }

        // 重置按钮
        Button('重置下载')
          .type(ButtonType.Normal)
          .width('90%')
          .height(40)
          .borderRadius(8)
          .backgroundColor('#E84026')
          .onClick(() => {
            this.resetProgress()
          })

        // API 说明区
        Column() {
          Text('API 说明')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 8 })
          Text('import { ProgressButton } from "@kit.ArkUI"')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('ProgressButton({ progress, content, enable, clickCallback, ... })')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('progress: [0,100]  content: 按钮文本  enable: 是否可点击')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('progressButtonWidth: >= 44vp  clickCallback: 点击回调')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('不支持通用属性和通用事件')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('元服务API: 从 API version 11 开始支持')
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
