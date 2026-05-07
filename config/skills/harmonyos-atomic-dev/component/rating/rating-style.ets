/**
 * rating-style — Rating 自定义星级样式
 * 展示 Rating 组件的 starStyle 属性，自定义星级图片
 * 元服务兼容性：starStyle 属性 元服务 API 11+ 可用
 * 注意: starStyle 支持本地图片和网络图片，暂不支持 PixelMap
 */
@ComponentV2
export struct RatingStyle {
  @Local currentRating: number = 3
  @Local useCustomStyle: boolean = false
  @Local resultText: string = '当前样式: 默认星级'
  @Local eventLog: string = '切换样式查看自定义效果'

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('Rating 星级样式')
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

        // 默认样式
        Column() {
          Text('默认星级样式')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .width('100%')
            .margin({ bottom: 8 })

          Rating({ rating: this.currentRating, indicator: false })
            .stars(5)
            .stepSize(0.5)
            .onChange((value: number) => {
              try {
                this.currentRating = value
                this.eventLog = `默认样式评分变化: ${value.toFixed(1)}`
              } catch (err) {
                this.eventLog = `错误: ${(err as BusinessError).message}`
              }
            })
        }
        .width('90%')
        .padding(16)
        .backgroundColor('#FFFFFF')
        .borderRadius(8)
        .shadow({ radius: 2, color: '#22000000', offsetX: 0, offsetY: 1 })

        // 自定义样式 (使用网络图片)
        Column() {
          Text('自定义星级样式 (网络图片)')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .width('100%')
            .margin({ bottom: 8 })

          Rating({ rating: this.currentRating, indicator: false })
            .stars(5)
            .stepSize(0.5)
            .starStyle({
              foregroundUri: 'https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/58/v3/ev6Q2JI6RpilJSxKwmV7Tg/zh-cn_image_0000002557105365.gif',
              backgroundUri: '',
              secondaryUri: ''
            })
            .onChange((value: number) => {
              try {
                this.currentRating = value
                this.eventLog = `自定义样式评分变化: ${value.toFixed(1)}`
              } catch (err) {
                this.eventLog = `错误: ${(err as BusinessError).message}`
              }
            })
        }
        .width('90%')
        .padding(16)
        .backgroundColor('#FFFFFF')
        .borderRadius(8)
        .shadow({ radius: 2, color: '#22000000', offsetX: 0, offsetY: 1 })

        // 样式说明
        Column() {
          Text('starStyle 参数说明')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .width('100%')
            .margin({ bottom: 8 })

          Text('• backgroundUri: ResourceStr — 未选中的星级图片路径')
            .fontSize(12)
            .fontColor('#666666')
            .width('100%')
          Text('• foregroundUri: ResourceStr — 选中的星级图片路径')
            .fontSize(12)
            .fontColor('#666666')
            .width('100%')
          Text('• secondaryUri?: ResourceStr — 部分选中的星级图片路径')
            .fontSize(12)
            .fontColor('#666666')
            .width('100%')
          Text('• 空字符串/undefined 时使用系统默认图源')
            .fontSize(12)
            .fontColor('#666666')
            .width('100%')
          Text('• 建议宽高: width = height * stars (保持方形)')
            .fontSize(12)
            .fontColor('#666666')
            .width('100%')
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
          Text('starStyle(options: StarStyleOptions)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('支持加载本地图片和网络图片，暂不支持 PixelMap')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('图片加载方式为异步，暂不支持同步加载')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('图片路径错误时将保持上次结果，首次错误则不显示')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('元服务兼容: starStyle 属性 API 11+ 可用')
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
