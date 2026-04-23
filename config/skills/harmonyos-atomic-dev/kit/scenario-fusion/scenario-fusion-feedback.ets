/**
 * scenario_fusion_kit-feedback — 反馈与投诉
 * FunctionalButton + OpenType.FEEDBACK — 从 API version 20 起支持
 * 元服务API: 从 API version 20 起支持（元服务专属场景）
 * 回调: onFeedback → void
 */
import { FunctionalButton, functionalButtonComponentManager } from '@kit.ScenarioFusionKit'
import { BusinessError } from '@kit.BasicServicesKit'

@ComponentV2
export struct ScenarioFusionKitFeedback {
  @Local resultText: string = '等待操作'
  @Local buttonLabel: string = '反馈与投诉'

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('反馈与投诉')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20, bottom: 10 })

        Text('FunctionalButton(OpenType.FEEDBACK) — 元服务专属')
          .fontSize(13)
          .fontColor('#666666')
          .width('90%')
          .textAlign(TextAlign.Center)

        // 结果展示
        Column({ space: 8 }) {
          Text('执行结果')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .width('100%')
          Text(this.resultText)
            .fontSize(13)
            .fontColor(this.resultText.includes('成功') ? '#00B578' :
              (this.resultText.includes('失败') || this.resultText.includes('错误') ? '#E84026' : '#333333'))
            .width('100%')
        }
        .width('90%')
        .padding(16)
        .backgroundColor('#F5F5F5')
        .borderRadius(12)
        .alignItems(HorizontalAlign.Start)

        // 参数控制
        Column({ space: 12 }) {
          Row() {
            Text('按钮文字:')
              .fontSize(14)
              .width(80)
            TextInput({ text: this.buttonLabel, placeholder: '按钮文字' })
              .layoutWeight(1)
              .onChange((value: string) => {
                this.buttonLabel = value
              })
          }
          .width('100%')
        }
        .width('90%')
        .padding(12)
        .backgroundColor('#F9F9F9')
        .borderRadius(8)

        // FunctionalButton 组件
        Text('FunctionalButton 组件')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Column() {
          FunctionalButton({
            params: {
              openType: functionalButtonComponentManager.OpenType.FEEDBACK,
              label: this.buttonLabel,
              styleOption: {
                styleConfig: new functionalButtonComponentManager.ButtonConfig()
                  .fontSize(20)
              },
            },
            controller: new functionalButtonComponentManager.FunctionalButtonController()
              .onFeedback((err) => {
                if (err) {
                  this.resultText = `操作失败: [${err.code}] ${err.message}`
                  return
                }
                this.resultText = '成功拉起反馈与投诉页面'
              })
          })
        }
        .width('90%')
        .padding(16)
        .backgroundColor('#FFFFFF')
        .borderRadius(12)
        .shadow({ radius: 4, color: '#1A000000', offsetX: 0, offsetY: 2 })

        // 注意事项
        Column({ space: 8 }) {
          Text('注意事项')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
          Text('1. 仅在元服务中可用，非元服务返回 10008')
            .fontSize(12)
            .fontColor('#666666')
          Text('2. 需先完成开发准备并发布元服务')
            .fontSize(12)
            .fontColor('#666666')
          Text('3. controller 必须使用 onFeedback 回调')
            .fontSize(12)
            .fontColor('#666666')
        }
        .width('90%')
        .padding(12)
        .backgroundColor('#FFF8E1')
        .borderRadius(8)
        .alignItems(HorizontalAlign.Start)

        // API 说明
        Text('API 说明')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Column({ space: 4 }) {
          Text('FunctionalButton({')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('  params: { openType: OpenType.FEEDBACK },')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('  controller: FunctionalButtonController()')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('    .onFeedback((err) => { ... })')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('})')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('')
            .fontSize(8)
          Text('元服务API: 从 API 20 起支持（元服务专属）')
            .fontSize(12)
            .fontColor('#00B578')
            .fontWeight(FontWeight.Medium)
          Text('支持设备: Phone / Tablet')
            .fontSize(12)
            .fontColor('#999999')
        }
        .alignItems(HorizontalAlign.Start)
        .margin({ left: 16, bottom: 20 })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
  }
}
