/**
 * button-functional — FunctionalButton 场景化按钮
 * 展示 ScenarioFusionKit 中的 FunctionalButton（快速验证手机号、打开设置等场景）
 * 元服务兼容性：从版本 4.1.0(11) 开始支持在元服务中使用
 */
import { FunctionalButton, functionalButtonComponentManager } from '@kit.ScenarioFusionKit'
import { BusinessError } from '@kit.BasicServicesKit'

@ComponentV2
export struct ButtonFunctional {
  @Local resultText: string = '点击场景化按钮触发对应功能'

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('FunctionalButton 场景化按钮')
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

        // 快速验证手机号
        Text('GET_PHONE_NUMBER — 快速验证手机号')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        FunctionalButton({
          params: {
            openType: functionalButtonComponentManager.OpenType.GET_PHONE_NUMBER,
            label: '快速验证手机号',
            styleOption: {
              bgColor: functionalButtonComponentManager.ColorType.DEFAULT,
              size: functionalButtonComponentManager.SizeType.DEFAULT,
              plain: false,
              disabled: false,
              loading: false,
            },
          },
          controller: new functionalButtonComponentManager.FunctionalButtonController()
            .onGetPhoneNumber((err: BusinessError, data: functionalButtonComponentManager.GetPhoneNumberResult) => {
              if (err) {
                this.resultText = `错误: code=${err.code}, msg=${err.message}`
                return
              }
              this.resultText = `获取授权码成功: ${data.code}`
            })
        })

        // 打开设置
        Text('OPEN_SETTING — 打开设置页')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        FunctionalButton({
          params: {
            openType: functionalButtonComponentManager.OpenType.OPEN_SETTING,
            label: '打开设置',
            styleOption: {
              bgColor: functionalButtonComponentManager.ColorType.DEFAULT,
              size: functionalButtonComponentManager.SizeType.DEFAULT,
              plain: false,
              disabled: false,
              loading: false,
            },
          },
          controller: new functionalButtonComponentManager.FunctionalButtonController()
            .onOpenSetting((err: BusinessError, data: functionalButtonComponentManager.OpenSettingResult) => {
              if (err) {
                this.resultText = `错误: code=${err.code}, msg=${err.message}`
                return
              }
              this.resultText = `设置回调: ${JSON.stringify(data)}`
            })
        })

        // 选择头像
        Text('CHOOSE_AVATAR — 选择头像')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        FunctionalButton({
          params: {
            openType: functionalButtonComponentManager.OpenType.CHOOSE_AVATAR,
            label: '选择头像',
            styleOption: {
              bgColor: functionalButtonComponentManager.ColorType.PRIMARY,
              size: functionalButtonComponentManager.SizeType.DEFAULT,
              plain: true,
              disabled: false,
              loading: false,
            },
          },
          controller: new functionalButtonComponentManager.FunctionalButtonController()
            .onChooseAvatar((err: BusinessError, data: functionalButtonComponentManager.ChooseAvatarResult) => {
              if (err) {
                this.resultText = `错误: code=${err.code}, msg=${err.message}`
                return
              }
              this.resultText = `头像选择回调: ${JSON.stringify(data)}`
            })
        })

        // GET_RISK_LEVEL 不可用提示
        Text('GET_RISK_LEVEL — 获取手机号和风险等级')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Column() {
          Text('GET_RISK_LEVEL 在当前 SDK 版本不可用')
            .fontSize(13)
            .fontColor('#FF6B00')
            .fontWeight(FontWeight.Medium)
            .width('100%')
          Text('该 OpenType 需要更高版本 ScenarioFusionKit 支持')
            .fontSize(12)
            .fontColor('#996600')
            .margin({ top: 4 })
            .width('100%')
        }
        .width('90%')
        .backgroundColor('#FFF3CD')
        .borderRadius(8)
        .padding(12)

        // API 说明区
        Column() {
          Text('API 说明')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 8 })
          Text('import { FunctionalButton, functionalButtonComponentManager } from "@kit.ScenarioFusionKit"')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('OpenType: GET_PHONE_NUMBER | OPEN_SETTING | CHOOSE_AVATAR | ...')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('styleOption: bgColor, size, plain, disabled, loading')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('controller 回调须与 OpenType 匹配')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('元服务API: 从版本 4.1.0(11) 开始支持')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('需要配合 functionalButtonComponentManager 使用')
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
