/**
 * progress-dynamic — Progress 动态值更新场景
 * 模拟下载/安装进度条，通过定时器和按钮驱动进度值变化
 * 元服务兼容性：Progress .value() 动态更新 API 7+ 可用
 */
@ComponentV2
export struct ProgressDynamic {
  @Local downloadProgress: number = 0
  @Local resultText: string = '点击"开始下载"模拟下载进度'
  @Local eventLog: string = '等待操作...'
  @Local isDownloading: boolean = false
  private timerId: number = -1

  // Linear + Capsule 垂直方向展示
  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('Progress 动态更新')
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

        // 场景 1：下载进度模拟 (Linear)
        Text('下载进度模拟 (Linear)')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Progress({ value: this.downloadProgress, total: 100, type: ProgressType.Linear })
          .width('90%')
          .height(24)
          .color('#4CAF50')
          .backgroundColor('#E0E0E0')

        Text(`${this.downloadProgress}%`)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')

        // 操作按钮
        Row({ space: 8 }) {
          Button(this.isDownloading ? '暂停' : '开始下载')
            .width(120)
            .height(40)
            .fontSize(14)
            .backgroundColor(this.isDownloading ? '#FF9800' : '#4CAF50')
            .onClick(() => {
              try {
                if (this.isDownloading) {
                  this.pauseDownload()
                } else {
                  this.startDownload()
                }
              } catch (err) {
                this.eventLog = `错误: ${(err as BusinessError).message}`
              }
            })

          Button('重置')
            .width(80)
            .height(40)
            .fontSize(14)
            .backgroundColor('#FF6B6B')
            .onClick(() => {
              this.resetDownload()
            })
        }

        // 场景 2：环形进度 (Ring)
        Text('环形进度 (Ring)')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Row({ space: 20 }) {
          Column({ space: 4 }) {
            Progress({ value: this.downloadProgress, total: 100, type: ProgressType.Ring })
              .width(80)
              .height(80)
              .color('#2196F3')
              .style({ strokeWidth: 8 })
            Text('Ring')
              .fontSize(12)
              .fontColor('#666666')
          }

          Column({ space: 4 }) {
            Progress({ value: this.downloadProgress, total: 100, type: ProgressType.ScaleRing })
              .width(80)
              .height(80)
              .color('#FF9800')
              .backgroundColor('#FFF3E0')
              .style({ strokeWidth: 8, scaleCount: 20, scaleWidth: 3 })
            Text('ScaleRing')
              .fontSize(12)
              .fontColor('#666666')
          }

          Column({ space: 4 }) {
            Progress({ value: this.downloadProgress, total: 100, type: ProgressType.Eclipse })
              .width(80)
              .height(80)
              .color('#E91E63')
            Text('Eclipse')
              .fontSize(12)
              .fontColor('#666666')
          }
        }

        // 场景 3：Capsule 垂直方向
        Text('Capsule 垂直方向')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Progress({ value: this.downloadProgress, total: 100, type: ProgressType.Capsule })
          .width(50)
          .height(150)
          .color('#9C27B0')
          .backgroundColor('#F3E5F5')

        // 事件日志区
        Column() {
          Text(this.eventLog)
            .fontSize(12)
            .fontColor('#666666')
            .width('100%')
            .padding(12)
        }
        .width('90%')
        .backgroundColor('#F0F0F0')
        .borderRadius(8)

        // API 说明区
        Column() {
          Text('API 说明')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 8 })
          Text('Progress({ value, total, type }).value(number)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('通过 @Local 绑定 value 实现动态更新')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('Linear: height > width 时自适应垂直显示')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('Capsule: height > width 时自适应垂直显示')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('元服务兼容: API 7+ 全部可用')
            .fontSize(12)
            .fontColor('#4CAF50')
            .width('100%')
            .margin({ top: 4 })
        }
        .width('90%')
        .backgroundColor('#FFF9E6')
        .borderRadius(8)
        .padding(12)
        .margin({ top: 8, bottom: 20 })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
  }

  private startDownload(): void {
    this.isDownloading = true
    this.resultText = `下载中... ${this.downloadProgress}%`
    this.eventLog = '下载开始'
    this.timerId = setInterval(() => {
      try {
        if (this.downloadProgress >= 100) {
          this.pauseDownload()
          this.resultText = '下载完成！'
          this.eventLog = '下载已完成 → 100%'
          return
        }
        const increment = Math.floor(Math.random() * 5) + 1
        this.downloadProgress = Math.min(100, this.downloadProgress + increment)
        this.resultText = `下载中... ${this.downloadProgress}%`
      } catch (err) {
        this.eventLog = `错误: ${(err as BusinessError).message}`
        this.pauseDownload()
      }
    }, 200) as number
  }

  private pauseDownload(): void {
    this.isDownloading = false
    if (this.timerId !== -1) {
      clearInterval(this.timerId)
      this.timerId = -1
    }
    this.eventLog = `已暂停 → ${this.downloadProgress}%`
  }

  private resetDownload(): void {
    this.pauseDownload()
    this.downloadProgress = 0
    this.resultText = '点击"开始下载"模拟下载进度'
    this.eventLog = '已重置'
  }
}
