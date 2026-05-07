/**
 * span-container — ContainerSpan 容器与文本背景样式
 * 展示 ContainerSpan 包裹多个 Span 设置统一背景色和圆角
 * 元服务兼容性：ContainerSpan / textBackgroundStyle 元服务 API 12+ 可用
 */
@ComponentV2
export struct SpanContainer {
  @Local resultText: string = '展示 ContainerSpan 背景样式'
  @Local eventLog: string = 'ContainerSpan 包裹 Span 统一背景'
  @Local bgColor: string = '#4CAF50'

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('ContainerSpan 容器')
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

        // ContainerSpan 基础用法
        Column() {
          Text('统一背景样式:')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .width('100%')
            .margin({ bottom: 8 })

          Text() {
            Span('外层文本 ')
              .fontSize(16)
            ContainerSpan() {
              Span('ContainerSpan')
                .fontSize(16)
                .fontColor(Color.White)
              Span(' 内的多个Span')
                .fontSize(16)
                .fontColor(Color.White)
            }
            .textBackgroundStyle({ color: this.bgColor, radius: 8 })
            Span(' 外层文本')
              .fontSize(16)
          }
          .width('100%')
          .padding(12)
          .borderWidth(1)
          .borderColor('#E0E0E0')
          .borderRadius(4)
        }
        .width('90%')
        .padding(12)
        .backgroundColor('#FFFFFF')
        .borderRadius(8)
        .shadow({ radius: 2, color: '#22000000', offsetX: 0, offsetY: 1 })

        // 多段 ContainerSpan
        Column() {
          Text('多段不同背景:')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .width('100%')
            .margin({ bottom: 8 })

          Text() {
            ContainerSpan() {
              Span('标签一')
                .fontSize(14)
                .fontColor(Color.White)
            }
            .textBackgroundStyle({ color: '#E53935', radius: 4 })
            Span('  ')
            ContainerSpan() {
              Span('标签二')
                .fontSize(14)
                .fontColor(Color.White)
            }
            .textBackgroundStyle({ color: '#1E88E5', radius: 4 })
            Span('  ')
            ContainerSpan() {
              Span('标签三')
                .fontSize(14)
                .fontColor(Color.White)
            }
            .textBackgroundStyle({ color: '#43A047', radius: 4 })
          }
          .width('100%')
          .padding(12)
          .borderWidth(1)
          .borderColor('#E0E0E0')
          .borderRadius(4)
        }
        .width('90%')
        .padding(12)
        .backgroundColor('#FFFFFF')
        .borderRadius(8)
        .shadow({ radius: 2, color: '#22000000', offsetX: 0, offsetY: 1 })

        // 操作按钮
        Column() {
          Text('参数控制')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .width('100%')
            .margin({ bottom: 8 })

          Row({ space: 8 }) {
            Button('绿色背景')
              .fontSize(12)
              .height(36)
              .onClick(() => {
                try {
                  this.bgColor = '#4CAF50'
                  this.resultText = '背景切换为绿色'
                  this.eventLog = 'textBackgroundStyle.color = #4CAF50'
                } catch (err) {
                  this.eventLog = `错误: ${(err as BusinessError).message}`
                }
              })

            Button('蓝色背景')
              .fontSize(12)
              .height(36)
              .onClick(() => {
                try {
                  this.bgColor = '#2196F3'
                  this.resultText = '背景切换为蓝色'
                  this.eventLog = 'textBackgroundStyle.color = #2196F3'
                } catch (err) {
                  this.eventLog = `错误: ${(err as BusinessError).message}`
                }
              })

            Button('红色背景')
              .fontSize(12)
              .height(36)
              .onClick(() => {
                try {
                  this.bgColor = '#F44336'
                  this.resultText = '背景切换为红色'
                  this.eventLog = 'textBackgroundStyle.color = #F44336'
                } catch (err) {
                  this.eventLog = `错误: ${(err as BusinessError).message}`
                }
              })
          }
        }
        .width('90%')
        .padding(12)
        .backgroundColor('#FFFFFF')
        .borderRadius(8)
        .shadow({ radius: 2, color: '#22000000', offsetX: 0, offsetY: 1 })

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
          Text('ContainerSpan() — 容器, 包裹 Span/ImageSpan')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('.textBackgroundStyle({color, radius})')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('统一管理子组件背景色和圆角弧度')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('元服务兼容: ContainerSpan / textBackgroundStyle API 12+ 可用')
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
