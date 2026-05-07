/**
 * stack-overlay — Stack 覆盖层效果
 * 展示 Stack 实现覆盖层场景：图片+文字覆盖、状态标签、操作悬浮栏
 * 元服务兼容性：Stack API 7+，元服务 API 11+ 可用
 */
import { BusinessError } from '@kit.BasicServicesKit'

@ComponentV2
export struct StackOverlay {
  @Local resultText: string = '点击切换覆盖层场景'
  @Local sceneIndex: number = 0

  private scenes: string[] = ['图片文字覆盖', '状态标签', '悬浮操作栏']

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('Stack 覆盖层效果')
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

        // 场景切换按钮
        Row({ space: 8 }) {
          ForEach(this.scenes, (scene: string, index: number) => {
            Button(scene)
              .fontSize(12)
              .layoutWeight(1)
              .height(36)
              .backgroundColor(this.sceneIndex === index ? '#1976D2' : '#E0E0E0')
              .fontColor(this.sceneIndex === index ? '#FFFFFF' : '#333333')
              .onClick(() => {
                try {
                  this.sceneIndex = index as number
                  this.resultText = `当前场景: ${scene}`
                } catch (error) {
                  this.resultText = `错误: ${(error as BusinessError).message}`
                }
              })
          }, (scene: string, index: number) => `scene_${index}`)
        }
        .width('90%')

        // 场景 1：图片 + 文字覆盖
        if (this.sceneIndex === 0) {
          Text('图片文字覆盖')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .alignSelf(ItemAlign.Start)
            .margin({ left: 16, top: 8 })

          Stack({ alignContent: Alignment.Bottom }) {
            // 底层：背景区域
            Column() {}
            .width('100%')
            .height(200)
            .backgroundColor('#1A237E')
            .borderRadius(12)

            // 中层：标题文字
            Column() {
              Text('HarmonyOS 元服务')
                .fontSize(20)
                .fontWeight(FontWeight.Bold)
                .fontColor('#FFFFFF')
                .width('100%')
                .margin({ bottom: 4 })
              Text('Stack 实现图片与文字层叠效果')
                .fontSize(13)
                .fontColor('#B0BEC5')
                .width('100%')
            }
            .width('100%')
            .padding({ left: 16, right: 16, bottom: 16 })
          }
          .width('90%')
          .height(200)
          .borderRadius(12)
        }

        // 场景 2：状态标签
        if (this.sceneIndex === 1) {
          Text('状态标签')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .alignSelf(ItemAlign.Start)
            .margin({ left: 16, top: 8 })

          // 卡片 + 角标
          Stack({ alignContent: Alignment.TopEnd }) {
            // 底层：卡片内容
            Column({ space: 8 }) {
              Text('消息通知')
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .width('100%')
              Text('您有一条新的系统消息，请查看详情。')
                .fontSize(13)
                .fontColor('#666666')
                .width('100%')
              Text('2 分钟前')
                .fontSize(11)
                .fontColor('#999999')
                .width('100%')
            }
            .padding(16)
            .backgroundColor('#FFFFFF')
            .borderRadius(12)
            .width('100%')

            // 顶层：角标
            Column() {
              Text('New')
                .fontSize(10)
                .fontColor('#FFFFFF')
                .fontWeight(FontWeight.Bold)
            }
            .padding({ left: 8, right: 8, top: 4, bottom: 4 })
            .backgroundColor('#F44336')
            .borderRadius(10)
            .margin({ top: 8, right: 8 })
          }
          .width('90%')
          .height(110)
          .borderRadius(12)
          .shadow({ radius: 4, color: '#1A000000', offsetX: 0, offsetY: 2 })
        }

        // 场景 3：悬浮操作栏
        if (this.sceneIndex === 2) {
          Text('悬浮操作栏')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .alignSelf(ItemAlign.Start)
            .margin({ left: 16, top: 8 })

          Stack({ alignContent: Alignment.Bottom }) {
            // 底层：内容区域
            Column({ space: 8 }) {
              Text('内容区域')
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .width('100%')
              ForEach(['列表项 1', '列表项 2', '列表项 3'], (item: string) => {
                Text(item)
                  .fontSize(14)
                  .fontColor('#666666')
                  .width('100%')
                  .padding(10)
                  .backgroundColor('#F5F5F5')
                  .borderRadius(6)
              }, (item: string) => item)
            }
            .padding(16)
            .width('100%')

            // 顶层：底部操作栏
            Row({ space: 8 }) {
              Button('收藏')
                .fontSize(13)
                .layoutWeight(1)
                .height(36)
                .backgroundColor('#FF9800')
              Button('分享')
                .fontSize(13)
                .layoutWeight(1)
                .height(36)
                .backgroundColor('#2196F3')
              Button('下载')
                .fontSize(13)
                .layoutWeight(1)
                .height(36)
                .backgroundColor('#4CAF50')
            }
            .width('100%')
            .padding({ left: 12, right: 12, bottom: 12 })
          }
          .width('90%')
          .height(240)
          .backgroundColor('#FFFFFF')
          .borderRadius(12)
          .shadow({ radius: 4, color: '#1A000000', offsetX: 0, offsetY: 2 })
        }

        // API 说明区
        Column() {
          Text('API 说明')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 8 })
          Text('Stack({ alignContent: Alignment.Bottom }) — 底部对齐')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('Stack({ alignContent: Alignment.TopEnd }) — 右上角对齐')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('典型场景：图片+文字覆盖、角标、悬浮操作栏、广告卡片')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('元服务：Stack 完整可用，无限制')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
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
