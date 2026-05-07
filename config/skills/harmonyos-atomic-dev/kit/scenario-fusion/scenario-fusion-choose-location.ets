/**
 * scenario_fusion_kit-choose-location — 地图选点
 * FunctionalButton + OpenType.CHOOSE_LOCATION — 从 API version 12 起支持
 * 元服务API: 从 API version 12 起支持
 * 回调: onChooseLocation → ChooseLocationResult { locationName, latitude, longitude, ... }
 */
import { FunctionalButton, functionalButtonComponentManager } from '@kit.ScenarioFusionKit'
import { BusinessError } from '@kit.BasicServicesKit'

@ComponentV2
export struct ScenarioFusionKitChooseLocation {
  @Local resultText: string = '等待操作'
  @Local locationInfo: string = '--'
  @Local buttonLabel: string = '地图选点'

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('地图选点')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20, bottom: 10 })

        Text('FunctionalButton(OpenType.CHOOSE_LOCATION) → onChooseLocation')
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
          Scroll() {
            Text(this.locationInfo)
              .fontSize(12)
              .fontColor('#666666')
              .width('100%')
          }
          .width('100%')
          .height(100)
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
        Column() {
          FunctionalButton({
            params: {
              openType: functionalButtonComponentManager.OpenType.CHOOSE_LOCATION,
              label: this.buttonLabel,
              styleOption: {
                styleConfig: new functionalButtonComponentManager.ButtonConfig()
                  .fontSize(20)
              },
            },
            controller: new functionalButtonComponentManager.FunctionalButtonController()
              .onChooseLocation((err, data) => {
                if (err) {
                  this.resultText = `选点失败: [${err.code}] ${err.message}`
                  this.locationInfo = '--'
                  return
                }
                this.resultText = '地图选点成功'
                this.locationInfo =
                  `名称: ${data.name ?? ''}\n` +
                  `地址: ${data.address ?? ''}\n` +
                  `纬度: ${data.latitude ?? 0}\n` +
                  `经度: ${data.longitude ?? 0}`
              })
          })
        }
        .width('90%')
        .padding(16)
        .backgroundColor('#FFFFFF')
        .borderRadius(12)
        .shadow({ radius: 4, color: '#1A000000', offsetX: 0, offsetY: 2 })

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
          Text('  params: { openType: OpenType.CHOOSE_LOCATION },')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('  controller: FunctionalButtonController()')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('    .onChooseLocation((err, data) => {')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('      // data: { name, address,')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('      //   latitude, longitude }')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('    })')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('})')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('')
            .fontSize(8)
          Text('元服务API: 从 API 12 起支持')
            .fontSize(12)
            .fontColor('#00B578')
            .fontWeight(FontWeight.Medium)
          Text('支持设备: Phone / Tablet / 2in1(13.1+)')
            .fontSize(12)
            .fontColor('#999999')
          Text('模拟器: 不支持')
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
