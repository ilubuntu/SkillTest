// 修复: 为 @ObservedV2 类中的 fontSize 属性添加 @Trace 修饰
// 页面B：字体调节页面（修复版本）

import { PersistenceV2 } from '@kit.ArkUI'

@ObservedV2
class FontSettings {
  @Trace fontSize: number = 16
}

PersistenceV2.connect(FontSettings, 'fontSettings', () => new FontSettings())

@Component
export struct FontSettingPage {
  @StorageLink('fontSettings') settings: FontSettings = new FontSettings()
  @Consume('pathStack') pathStack: NavPathStack

  build() {
    NavDestination() {
      Column() {
        Column() {
          Text('永远相信美好的事情即将发生')
            .fontSize(this.settings.fontSize)
            .fontColor('#333333')
            .textAlign(TextAlign.Center)
            .padding(24)

          Text('The quick brown fox jumps over the lazy dog')
            .fontSize(this.settings.fontSize)
            .fontColor('#666666')
            .textAlign(TextAlign.Center)
            .padding({ left: 24, right: 24, bottom: 24 })
        }
        .width('100%')
        .backgroundColor('#F7F8FA')
        .justifyContent(FlexAlign.Center)

        Column() {
          Text('字体大小')
            .fontSize(14)
            .fontColor('#999999')
            .width('100%')
            .margin({ bottom: 12 })

          Row() {
            Text('A')
              .fontSize(12)
              .fontColor('#999999')
              .width(20)

            Slider({
              value: this.settings.fontSize,
              min: 12,
              max: 40,
              step: 1,
              style: SliderStyle.OutSet
            })
              .layoutWeight(1)
              .trackColor('#E5E5E5')
              .selectedColor('#007DFF')
              .onChange((value: number) => {
                this.settings.fontSize = value
              })

            Text(`${this.settings.fontSize}`)
              .fontSize(14)
              .fontColor('#333333')
              .width(36)
              .textAlign(TextAlign.End)
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
        }
        .width('100%')
        .padding({ left: 24, right: 24, top: 20, bottom: 40 })
        .backgroundColor('#FFFFFF')
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F7F8FA')
    }
    .title('字体大小设置')
    .titleMode(NavigationTitleMode.Mini)
    .onBackPressed(() => {
      this.pathStack.pop()
      return true
    })
  }
}