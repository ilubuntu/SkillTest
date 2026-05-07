/**
 * progress-type — Progress 五种类型展示
 * 展示 Linear、Ring、ScaleRing、Eclipse、Capsule 五种进度条类型
 * 元服务兼容性：Progress 基础组件 API 7+ 全部可用
 */
@ComponentV2
export struct ProgressAllType {
  @Local progressValue: number = 40
  @Local resultText: string = '当前进度: 40 / 100'
  @Local eventLog: string = '展示五种 ProgressType'

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('Progress 类型展示')
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

        // 参数控制区
        Column() {
          Text(`进度值: ${this.progressValue}`)
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .width('100%')
            .margin({ bottom: 8 })

          Row({ space: 8 }) {
            Button('-10')
              .width(60)
              .height(36)
              .fontSize(13)
              .onClick(() => {
                try {
                  this.progressValue = Math.max(0, this.progressValue - 10)
                  this.resultText = `当前进度: ${this.progressValue} / 100`
                  this.eventLog = `进度减少 → ${this.progressValue}`
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
                  this.eventLog = `进度增加 → ${this.progressValue}`
                } catch (err) {
                  this.eventLog = `错误: ${(err as BusinessError).message}`
                }
              })
            Button('重置')
              .width(60)
              .height(36)
              .fontSize(13)
              .backgroundColor('#FF6B6B')
              .onClick(() => {
                this.progressValue = 40
                this.resultText = '当前进度: 40 / 100'
                this.eventLog = '已重置'
              })
          }
        }
        .width('90%')
        .padding(12)
        .backgroundColor('#FFFFFF')
        .borderRadius(8)
        .shadow({ radius: 2, color: '#22000000', offsetX: 0, offsetY: 1 })

        // 1. Linear 线性样式
        Text('1. ProgressType.Linear (线性进度条)')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Progress({ value: this.progressValue, total: 100, type: ProgressType.Linear })
          .width('90%')
          .height(20)
          .color('#007DFF')
          .backgroundColor('#E0E0E0')

        // 2. Ring 环形无刻度样式
        Text('2. ProgressType.Ring (环形无刻度)')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Progress({ value: this.progressValue, total: 100, type: ProgressType.Ring })
          .width(80)
          .height(80)
          .color('#007DFF')
          .style({ strokeWidth: 10 })

        // 3. ScaleRing 环形有刻度样式
        Text('3. ProgressType.ScaleRing (环形有刻度)')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Progress({ value: this.progressValue, total: 100, type: ProgressType.ScaleRing })
          .width(80)
          .height(80)
          .color('#007DFF')
          .backgroundColor('#F5F5F5')
          .style({ strokeWidth: 10, scaleCount: 20, scaleWidth: 3 })

        // 4. Eclipse 圆形样式
        Text('4. ProgressType.Eclipse (月食形)')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Progress({ value: this.progressValue, total: 100, type: ProgressType.Eclipse })
          .width(80)
          .height(80)
          .color('#007DFF')

        // 5. Capsule 胶囊样式
        Text('5. ProgressType.Capsule (胶囊形)')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Progress({ value: this.progressValue, total: 100, type: ProgressType.Capsule })
          .width('90%')
          .height(30)
          .color('#007DFF')
          .backgroundColor('#E0E0E0')

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
          Text('Progress({ value, total, type })')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('value: number — 当前进度值')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('total: number — 总进度值 (默认 100)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('type: ProgressType — 进度条类型')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('  Linear / Ring / ScaleRing / Eclipse / Capsule')
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
