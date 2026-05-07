/**
 * progress-style — Progress 样式自定义
 * 展示 color、backgroundColor、style({strokeWidth, scaleCount, scaleWidth}) 等样式属性
 * 元服务兼容性：Progress 样式属性 API 7+ 全部可用
 */
@ComponentV2
export struct ProgressStyleCustom {
  @Local progressValue: number = 60
  @Local resultText: string = '当前进度: 60 / 100'
  @Local eventLog: string = '展示样式自定义'

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('Progress 样式自定义')
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

        // 进度控制按钮
        Row({ space: 8 }) {
          Button('-10')
            .width(60)
            .height(36)
            .fontSize(13)
            .onClick(() => {
              try {
                this.progressValue = Math.max(0, this.progressValue - 10)
                this.resultText = `当前进度: ${this.progressValue} / 100`
                this.eventLog = `进度 → ${this.progressValue}%`
              } catch (err) {
                this.eventLog = `错误: ${(err as BusinessError).message}`
              }
            })
          Button('+10')
            .width(60)
            .height(36)
            .fontSize(13)
            .onClick(() => {
              try {
                this.progressValue = Math.min(100, this.progressValue + 10)
                this.resultText = `当前进度: ${this.progressValue} / 100`
                this.eventLog = `进度 → ${this.progressValue}%`
              } catch (err) {
                this.eventLog = `错误: ${(err as BusinessError).message}`
              }
            })
        }

        // 1. Linear — 颜色自定义
        Text('Linear — 前景色 + 背景色')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Progress({ value: this.progressValue, total: 100, type: ProgressType.Linear })
          .width('90%')
          .height(20)
          .color('#FF6B6B')
          .backgroundColor('#FFE0E0')

        // 2. Ring — strokeWidth 对比
        Text('Ring — strokeWidth 对比 (5 / 12 / 20)')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Row({ space: 20 }) {
          Progress({ value: this.progressValue, total: 100, type: ProgressType.Ring })
            .width(80)
            .height(80)
            .style({ strokeWidth: 5 })
            .color('#4CAF50')

          Progress({ value: this.progressValue, total: 100, type: ProgressType.Ring })
            .width(80)
            .height(80)
            .style({ strokeWidth: 12 })
            .color('#2196F3')

          Progress({ value: this.progressValue, total: 100, type: ProgressType.Ring })
            .width(80)
            .height(80)
            .style({ strokeWidth: 20 })
            .color('#FF9800')
        }

        // 3. ScaleRing — scaleCount + scaleWidth
        Text('ScaleRing — 刻度数量(10/30/60) + 刻度宽度')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Row({ space: 20 }) {
          Progress({ value: this.progressValue, total: 100, type: ProgressType.ScaleRing })
            .width(80)
            .height(80)
            .color('#9C27B0')
            .backgroundColor('#F3E5F5')
            .style({ strokeWidth: 8, scaleCount: 10, scaleWidth: 3 })

          Progress({ value: this.progressValue, total: 100, type: ProgressType.ScaleRing })
            .width(80)
            .height(80)
            .color('#9C27B0')
            .backgroundColor('#F3E5F5')
            .style({ strokeWidth: 8, scaleCount: 30, scaleWidth: 3 })

          Progress({ value: this.progressValue, total: 100, type: ProgressType.ScaleRing })
            .width(80)
            .height(80)
            .color('#9C27B0')
            .backgroundColor('#F3E5F5')
            .style({ strokeWidth: 8, scaleCount: 60, scaleWidth: 2 })
        }

        // 4. Eclipse — 不同颜色
        Text('Eclipse — 不同前景色')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Row({ space: 20 }) {
          Progress({ value: this.progressValue, total: 100, type: ProgressType.Eclipse })
            .width(80)
            .height(80)
            .color('#E91E63')

          Progress({ value: this.progressValue, total: 100, type: ProgressType.Eclipse })
            .width(80)
            .height(80)
            .color('#00BCD4')

          Progress({ value: this.progressValue, total: 100, type: ProgressType.Eclipse })
            .width(80)
            .height(80)
            .color('#8BC34A')
        }

        // 5. Capsule — 背景色搭配
        Text('Capsule — 背景色搭配')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Progress({ value: this.progressValue, total: 100, type: ProgressType.Capsule })
          .width('90%')
          .height(40)
          .color('#4CAF50')
          .backgroundColor('#E8F5E9')

        Progress({ value: this.progressValue, total: 100, type: ProgressType.Capsule })
          .width('90%')
          .height(40)
          .color('#FF5722')
          .backgroundColor('#FBE9E7')

        // 事件日志
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
          Text('.color(value: ResourceColor) — 前景色')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('.backgroundColor(value: ResourceColor) — 背景色')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('.style({ strokeWidth, scaleCount, scaleWidth })')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('  strokeWidth: Length — 进度条宽度')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('  scaleCount: number — 刻度数量 (ScaleRing)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('  scaleWidth: Length — 刻度宽度 (ScaleRing)')
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
}
