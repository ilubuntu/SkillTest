// 修复: 为 @ObservedV2 类中的 fontSize 属性添加 @Trace 修饰
// 页面A：设置页面（修复版本）

import { PersistenceV2 } from '@kit.ArkUI'
import router from '@ohos.router'

@ObservedV2
class FontSettings {
  @Trace fontSize: number = 16   // 添加 @Trace，属性变更时精准通知依赖该属性的 UI 节点
}

PersistenceV2.connect(FontSettings, 'fontSettings', () => new FontSettings())

@Entry
@Component
struct SettingsPage {
  @StorageLink('fontSettings') settings: FontSettings = new FontSettings()

  build() {
    Column() {
      // 标题栏
      Row() {
        Text('设置')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
      }
      .width('100%')
      .height(56)
      .backgroundColor('#FFFFFF')
      .padding({ left: 16, right: 16 })

      // 设置列表
      List() {
        ListItem() {
          Row() {
            Text('字体大小')
              .fontSize(16)
              .fontColor('#333333')
              .layoutWeight(1)

            Text('设置')
              .fontSize(this.settings.fontSize)   // 添加 @Trace 后正确刷新
              .fontColor('#007DFF')

            Text(' >')
              .fontSize(14)
              .fontColor('#CCCCCC')
          }
          .width('100%')
          .padding({ left: 20, right: 20, top: 16, bottom: 16 })
          .onClick(() => {
            router.pushUrl({ url: 'enhanced/FontSettingPage_enhanced.ets' })
          })
        }

        ListItem() {
          Row() {
            Text('其他设置项1')
              .fontSize(16)
              .fontColor('#333333')
            Text(' >')
              .fontSize(14)
              .fontColor('#CCCCCC')
          }
          .width('100%')
          .padding({ left: 20, right: 20, top: 16, bottom: 16 })
        }

        ListItem() {
          Row() {
            Text('其他设置项2')
              .fontSize(16)
              .fontColor('#333333')
            Text(' >')
              .fontSize(14)
              .fontColor('#CCCCCC')
          }
          .width('100%')
          .padding({ left: 20, right: 20, top: 16, bottom: 16 })
        }
      }
      .width('100%')
      .layoutWeight(1)
      .backgroundColor('#FFFFFF')

      // 底部预览区
      Column() {
        Text('预览文本')
          .fontSize(this.settings.fontSize)   // 添加 @Trace 后正确刷新
          .fontColor('#333333')
          .textAlign(TextAlign.Center)
          .padding(16)

        Text(`当前字体大小: ${this.settings.fontSize}`)   // 正确刷新
          .fontSize(12)
          .fontColor('#666666')
          .textAlign(TextAlign.Center)
      }
      .width('100%')
      .padding({ top: 20, bottom: 20 })
      .backgroundColor('#F7F8FA')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F7F8FA')
  }
}
