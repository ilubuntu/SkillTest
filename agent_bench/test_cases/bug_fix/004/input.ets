// Bug: @ObservedV2 类中字体大小属性缺少 @Trace 修饰
// 导致 PersistentStorage 持久化的对象属性变更时，预览区字体大小和大小数字文本不刷新

import { PersistentStorage } from '@kit.ArkUI'

@ObservedV2
class FontSettings {
  fontSize: number = 16   // 缺少 @Trace，属性变更不会触发 UI 更新
}

PersistentStorage.persistProp('fontSettings', new FontSettings())

@Entry
@Component
struct FontPreviewPage {
  @StorageLink('fontSettings') settings: FontSettings = new FontSettings()

  build() {
    Column() {
      // 功能标题区
      Row() {
        Text('字体预览')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
      }
      .width('100%')
      .height(56)
      .backgroundColor('#FFFFFF')
      .padding({ left: 16, right: 16 })

      // 预览区域
      Column() {
        Text('永远相信美好的事情即将发生')
          .fontSize(this.settings.fontSize)   // 绑定 PersistentStorage，但不会刷新
          .fontColor('#333333')
          .textAlign(TextAlign.Center)
          .padding(24)

        Text('The quick brown fox jumps over the lazy dog')
          .fontSize(this.settings.fontSize)   // 同上，不会刷新
          .fontColor('#666666')
          .textAlign(TextAlign.Center)
          .padding({ left: 24, right: 24, bottom: 24 })
      }
      .width('100%')
      .layoutWeight(1)
      .backgroundColor('#F7F8FA')
      .justifyContent(FlexAlign.Center)

      // 字体调节区域
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
              this.settings.fontSize = value  // 修改属性，但无 @Trace 故不触发刷新
            })

          Text(`${this.settings.fontSize}`)   // 不会刷新
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
}
