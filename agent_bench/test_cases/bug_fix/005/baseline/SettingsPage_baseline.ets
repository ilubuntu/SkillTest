// Bug: 未正确使用 EventHub 进行组件间通信
// 页面B：显示模式设置页

import router from '@ohos.router'
import eventhub from '@ohos.eventhub'

@Entry
@Component
struct SettingsPage {
  @State isGridMode: boolean = true
  @State isListMode: boolean = false

  @StorageLink('displayMode') storedGridMode: boolean = true

  aboutToAppear(): void {
    this.isGridMode = this.storedGridMode
    this.isListMode = !this.storedGridMode
  }

  build() {
    Column() {
      // 标题栏
      Row() {
        Text('< 返回')
          .fontSize(16)
          .fontColor('#007DFF')
          .onClick(() => {
            router.back()
          })

        Text('显示设置')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        Text('')
          .width(50)
      }
      .width('100%')
      .height(56)
      .backgroundColor('#FFFFFF')
      .padding({ left: 16, right: 16 })

      // 设置列表
      List() {
        ListItem() {
          Row() {
            Text('网格形式')
              .fontSize(16)
              .fontColor('#333333')
              .layoutWeight(1)

            Checkbox()
              .select(this.isGridMode)
              .onChange((value: boolean) => {
                if (value) {
                  this.isGridMode = true
                  this.isListMode = false
                  this.storedGridMode = true
                  // Bug: 使用 eventhub.emit 发送事件，但 AppDisplayPage 未正确监听
                  eventhub.emit('displayModeChange', { mode: 'grid' })
                }
              })
          }
          .width('100%')
          .padding({ left: 20, right: 20, top: 16, bottom: 16 })
        }

        ListItem() {
          Row() {
            Text('列表形式')
              .fontSize(16)
              .fontColor('#333333')
              .layoutWeight(1)

            Checkbox()
              .select(this.isListMode)
              .onChange((value: boolean) => {
                if (value) {
                  this.isGridMode = false
                  this.isListMode = true
                  this.storedGridMode = false
                  eventhub.emit('displayModeChange', { mode: 'list' })
                }
              })
          }
          .width('100%')
          .padding({ left: 20, right: 20, top: 16, bottom: 16 })
        }
      }
      .width('100%')
      .layoutWeight(1)
      .backgroundColor('#FFFFFF')

      // 说明
      Text('选择显示形式后，应用中心将自动切换展示效果')
        .fontSize(12)
        .fontColor('#999999')
        .textAlign(TextAlign.Center)
        .padding(16)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}
