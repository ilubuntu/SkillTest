/**
 * button-segment — SegmentButton 分段按钮
 * 展示页签类分段按钮和胶囊类分段按钮（单选/多选）
 * 元服务兼容性：从 API version 12 开始支持在元服务中使用
 *
 * 注意: SegmentButton 是 V1 组件，selectedIndexes 使用 @Link 装饰器，
 * 因此本组件整体使用 V1 @Component 以兼容 @Link 数据绑定。
 */
import {
  SegmentButton,
  SegmentButtonOptions,
  ItemRestriction,
  SegmentButtonTextItem
} from '@kit.ArkUI'

@Component
export struct ButtonSegment {
  @State tabSelectedIndexes: number[] = [0]
  @State singleSelectedIndexes: number[] = [0]
  @State multiSelectedIndexes: number[] = [0, 1]
  @State resultText: string = '点击分段按钮切换选中'

  // 页签类分段按钮选项
  @State tabOptions: SegmentButtonOptions = SegmentButtonOptions.tab({
    buttons: [{ text: '页签1' }, { text: '页签2' }, { text: '页签3' }] as ItemRestriction<SegmentButtonTextItem>,
  })

  // 胶囊类单选分段按钮选项
  @State capsuleSingleOptions: SegmentButtonOptions = SegmentButtonOptions.capsule({
    buttons: [{ text: '选项A' }, { text: '选项B' }, { text: '选项C' }],
    multiply: false,
  })

  // 胶囊类多选分段按钮选项
  @State capsuleMultiOptions: SegmentButtonOptions = SegmentButtonOptions.capsule({
    buttons: [{ text: '阅读' }, { text: '音乐' }, { text: '运动' }, { text: '旅行' }],
    multiply: true,
  })

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('SegmentButton 分段按钮')
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

        // 页签类分段按钮
        Text('页签类分段按钮（Tab）')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        SegmentButton({
          options: this.tabOptions,
          selectedIndexes: this.tabSelectedIndexes,
        })
          .width('90%')

        // 胶囊类单选分段按钮
        Text('胶囊类单选分段按钮（Capsule Single）')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        SegmentButton({
          options: this.capsuleSingleOptions,
          selectedIndexes: this.singleSelectedIndexes,
        })
          .width('90%')

        // 胶囊类多选分段按钮
        Text('胶囊类多选分段按钮（Capsule Multi）')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        SegmentButton({
          options: this.capsuleMultiOptions,
          selectedIndexes: this.multiSelectedIndexes,
        })
          .width('90%')

        // 选中状态展示
        Text(`Tab: [${this.tabSelectedIndexes.join(',')}]  ` +
          `单选: [${this.singleSelectedIndexes.join(',')}]  ` +
          `多选: [${this.multiSelectedIndexes.join(',')}]`)
          .fontSize(12)
          .fontColor('#999999')
          .width('90%')
          .textAlign(TextAlign.Center)

        // API 说明区
        Column() {
          Text('API 说明')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 8 })
          Text('import { SegmentButton, SegmentButtonOptions } from "@kit.ArkUI"')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('SegmentButtonOptions.tab({ buttons }) — 页签类')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('SegmentButtonOptions.capsule({ buttons, multiply }) — 胶囊类')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('buttons: 支持 2~5 个按钮（纯文本/纯图标/图标+文本）')
            .fontSize(12)
            .fontColor('#666666')
            .width('100%')
          Text('注意: SegmentButton 为 V1 组件，本页面使用 V1 @Component')
            .fontSize(12)
            .fontColor('#FF6B00')
            .width('100%')
          Text('元服务API: 从 API version 12 开始支持')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
        }
        .width('90%')
        .backgroundColor('#FFF9E6')
        .borderRadius(8)
        .padding(12)
        .margin({ top: 8 })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
  }
}
