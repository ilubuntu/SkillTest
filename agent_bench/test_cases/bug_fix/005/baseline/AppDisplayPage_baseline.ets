// Bug: AppDisplayPage 存在以下问题：
// 2. ForEach 未指定 keyGenerator 参数，可能导致列表渲染性能问题
// 页面A：应用展示页面

import display from '@ohos.display'
import router from '@ohos.router'
import eventhub from '@ohos.eventhub'

@Entry
@Component
struct AppDisplayPage {
  @State isGridMode: boolean = true
  @State appList: string[] = ['微信', '支付宝', '淘宝', '抖音', '京东', '美团', '滴滴', '携程', '饿了么', '高德地图']

  private modeChangeCallback = (data: { mode: string }) => {
    if (data && data.mode) {
      this.isGridMode = data.mode === 'grid'
    }
  }

  aboutToAppear() {
    // 修复1: 监听的事件名改为 'displayModeChange'
    eventhub.on('displayModeChange', this.modeChangeCallback)
  }

  aboutToDisappear() {
    eventhub.off('displayModeChange', this.modeChangeCallback)
  }

  build() {
    Column() {
      // 标题栏
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
            router.pushUrl({ url: 'baseline/SettingsPage_baseline.ets' })
          })
      }
      .width('100%')
      .height(56)
      .backgroundColor('#FFFFFF')
      .padding({ left: 16, right: 16 })

      // 应用展示区
      if (this.isGridMode) {
        Grid() {
          // 修复2: 为 ForEach 添加 keyGenerator
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
          // 修复2: 为 ForEach 添加 keyGenerator
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
