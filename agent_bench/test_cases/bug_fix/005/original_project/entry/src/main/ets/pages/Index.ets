// 页面A：应用展示页面（已修复）
// 修复内容：
// 1. 使用 eventhub.on 监听事件名 'displayModeChange' 与 SettingsPage 发送的事件名匹配
// 2. ForEach 已指定 keyGenerator 参数，避免列表渲染性能问题
// 3. eventhub.on 订阅后在 aboutToDisappear 中使用 eventhub.off 取消订阅，防止内存泄露

import router from '@ohos.router'
import eventhub from '@ohos.eventhub'

@Entry
@Component
struct Index {
  @State isGridMode: boolean = true
  @State appList: string[] = ['微信', '支付宝', '淘宝', '抖音', '京东', '美团', '滴滴', '携程', '饿了么', '高德地图']

  private displayModeCallback = (data: { mode: string }) => {
    if (data && data.mode) {
      this.isGridMode = data.mode === 'grid'
    }
  }

  aboutToAppear() {
    eventhub.on('displayModeChange', this.displayModeCallback)
  }

  aboutToDisappear() {
    eventhub.off('displayModeChange', this.displayModeCallback)
  }

  build() {
    Column() {
      Row() {
        Text('应用中心')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        Text('☰')
          .fontSize(20)
          .padding({ right: 16 })
          .onClick(() => {
            router.pushUrl({ url: 'pages/SettingsPage' })
          })
      }
      .width('100%')
      .height(56)
      .backgroundColor('#FFFFFF')
      .padding({ left: 16, right: 16 })

      if (this.isGridMode) {
        Grid() {
          ForEach(this.appList, (appName: string, index: number) => {
            GridItem() {
              Column() {
                Text(appName.charAt(0))
                  .fontSize(24)
                  .fontColor('#FFFFFF')
                  .width(48)
                  .height(48)
                  .backgroundColor('#007DFF')
                  .borderRadius(12)
                  .textAlign(TextAlign.Center)

                Text(appName)
                  .fontSize(12)
                  .fontColor('#333333')
                  .margin({ top: 8 })
              }
              .padding(12)
            }
          }, (appName: string, index: number) => `${appName}_${index}`)
        }
        .columnsTemplate('1fr 1fr 1fr 1fr')
        .columnsGap(8)
        .rowsGap(8)
        .padding(16)
        .width('100%')
        .layoutWeight(1)
      } else {
        List() {
          ForEach(this.appList, (appName: string, index: number) => {
            ListItem() {
              Row() {
                Text(appName.charAt(0))
                  .fontSize(20)
                  .fontColor('#FFFFFF')
                  .width(40)
                  .height(40)
                  .backgroundColor('#007DFF')
                  .borderRadius(8)
                  .textAlign(TextAlign.Center)

                Text(appName)
                  .fontSize(16)
                  .fontColor('#333333')
                  .margin({ left: 12 })
                  .layoutWeight(1)
              }
              .width('100%')
              .padding({ left: 16, right: 16, top: 12, bottom: 12 })
            }
          }, (appName: string, index: number) => `${appName}_${index}`)
        }
        .width('100%')
        .layoutWeight(1)
        .backgroundColor('#FFFFFF')
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}