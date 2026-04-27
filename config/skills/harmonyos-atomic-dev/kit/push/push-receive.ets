/**
 * push-receive — 接收推送消息处理
 * 演示推送消息接收机制和数据展示
 * 实际的 Want 参数处理在 EntryAbility.ets 的 onCreate/onNewWant 中
 * 推送消息点击后:
 *   - 首次进入 → onCreate(want) 获取 data
 *   - 进程存在 → onNewWant(want) 获取 data（需 singleton 模式）
 */

/**
 * 接收推送消息的 UI 展示组件
 * 此组件展示接收机制说明和服务端推送 API 参考
 */
@ComponentV2
export struct PushReceive {
  @Local pushData: string = '暂无推送数据'
  @Local pushHistory: string[] = []

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('推送消息接收')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20, bottom: 10 })

        Text('接收推送点击后的 Want 参数数据')
          .fontSize(13)
          .fontColor('#666666')
          .width('90%')
          .textAlign(TextAlign.Center)

        // 当前数据卡片
        Column({ space: 8 }) {
          Text('最新推送数据:')
            .fontSize(13)
            .fontColor('#999999')
            .width('100%')
          Text(this.pushData)
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .width('100%')
            .maxLines(6)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .width('90%')
        .padding(16)
        .backgroundColor('#F5F5F5')
        .borderRadius(12)
        .alignItems(HorizontalAlign.Start)

        // 模拟推送接收
        Button('模拟接收推送数据')
          .width('80%')
          .backgroundColor('#007DFF')
          .borderRadius(8)
          .onClick(() => {
            this.simulatePushReceive()
          })

        // 推送历史
        Text('推送历史')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        if (this.pushHistory.length === 0) {
          Text('暂无推送记录')
            .fontSize(13)
            .fontColor('#999999')
            .margin({ top: 4 })
        } else {
          ForEach(this.pushHistory, (item: string, index: number) => {
            Text(item)
              .fontSize(12)
              .fontColor('#333333')
              .width('90%')
              .padding(8)
              .backgroundColor('#F9F9F9')
              .borderRadius(6)
              .maxLines(3)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }, (item: string, index: number) => `${index}`)
        }

        // 接收机制说明
        Text('接收机制')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Column({ space: 6 }) {
          Text('推送消息点击后的数据获取路径:')
            .fontSize(13)
            .fontWeight(FontWeight.Bold)
          Text('1. 元服务未运行 → EntryAbility.onCreate(want)')
            .fontSize(12)
            .fontColor('#666666')
          Text('   want.parameters 包含 clickAction.data')
            .fontSize(12)
            .fontColor('#666666')
          Text('2. 元服务已在运行 → EntryAbility.onNewWant(want)')
            .fontSize(12)
            .fontColor('#666666')
          Text('   需 launchType 为 singleton 模式')
            .fontSize(12)
            .fontColor('#E84026')
        }
        .width('90%')
        .padding(12)
        .backgroundColor('#FFF8F0')
        .borderRadius(8)
        .alignItems(HorizontalAlign.Start)

        // 服务端推送说明
        Text('服务端推送方式')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Column({ space: 4 }) {
          Text('订阅消息（服务通知）:')
            .fontSize(13)
            .fontWeight(FontWeight.Bold)
          Text('POST /v1/{projectId}/service_notification/send')
            .fontSize(12)
            .fontColor('#007DFF')
            .fontFamily('monospace')
          Text('参数: msgId / appId / toOpenId / templateId / templateParams')
            .fontSize(12)
            .fontColor('#666666')
          Text('')
          Text('服务动态消息:')
            .fontSize(13)
            .fontWeight(FontWeight.Bold)
          Text('POST /v1/{projectId}/service_timeline/send')
            .fontSize(12)
            .fontColor('#007DFF')
            .fontFamily('monospace')
          Text('参数: appId / toOpenId / sceneId / subSceneId / code / content')
            .fontSize(12)
            .fontColor('#666666')
        }
        .width('90%')
        .padding(12)
        .backgroundColor('#F0F5FF')
        .borderRadius(8)
        .alignItems(HorizontalAlign.Start)
        .margin({ bottom: 20 })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
  }

  private simulatePushReceive(): void {
    const now = new Date()
    const mockData = JSON.stringify({
      testKey: 'testValue',
      templateId: '13B6000E24008000',
      timestamp: now.toISOString()
    })
    this.pushData = mockData
    this.pushHistory = [`[${now.toLocaleTimeString()}] ${mockData}`, ...this.pushHistory].slice(0, 10)
  }
}
