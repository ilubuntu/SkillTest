/**
 * OpenAtomicService — 元服务 APP Linking: openAtomicService 拉起示例
 *
 * 通过 appId 直接拉起目标元服务，无有效期限制。
 * 被拉起方为系统元服务 → 直接跳转
 * 被拉起方为三方元服务 → 弹窗确认后跳转
 * 关联主体账号组 → 首次弹窗，30天内免弹
 */
import { common, AtomicServiceOptions } from '@kit.AbilityKit'
import { BusinessError } from '@kit.BasicServicesKit'

@ComponentV2
struct OpenAtomicService {
  @Local appId: string = '1234567890'
  @Local targetPath: string = 'pages/Index'
  @Local displayId: number = 0
  @Local resultMsg: string = ''

  /**
   * 通过 openAtomicService 拉起目标元服务
   * - appId: 目标元服务的 appId（必填）
   * - options: displayId + parameters（传递页面路径等自定义数据）
   */
  private launchAtomicService(): void {
    let context = this.getUIContext().getHostContext() as common.UIAbilityContext
    let targetAppId = this.appId.trim()
    if (!targetAppId) {
      this.resultMsg = '请输入目标元服务 appId'
      return
    }

    let openOptions: AtomicServiceOptions = {
      displayId: this.displayId,
      parameters: { 'pagePath': this.targetPath }
    }

    try {
      context.openAtomicService(targetAppId, openOptions)
        .then((result: common.AbilityResult) => {
          this.resultMsg = `拉起成功\nresultCode: ${result.resultCode}`
        })
        .catch((error: BusinessError) => {
          this.resultMsg = `拉起失败 [${error.code}]: ${error.message}`
        })
    } catch (error) {
      let err = error as BusinessError
      this.resultMsg = `参数错误 [${err.code}]: ${err.message}`
    }
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        // 标题
        Text('App Linking — openAtomicService')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)

        Text('通过 appId 直接拉起目标元服务，无有效期限制，常用于元服务间功能扩展')
          .fontSize(13)
          .fontColor('#666666')

        // appId 输入
        Text('目标元服务 appId').fontSize(14).width('100%')
        TextInput({ text: $$this.appId, placeholder: '输入目标元服务的 appId' })
          .width('100%')
          .height(48)
          .type(InputType.Normal)

        // 目标页面路径
        Text('目标页面路径（可选）').fontSize(14).width('100%')
        TextInput({ text: $$this.targetPath, placeholder: '如 pages/Detail' })
          .width('100%')
          .height(48)
          .type(InputType.Normal)

        // displayId
        Text('displayId（默认 0）').fontSize(14).width('100%')
        TextInput({ text: $$this.displayId, placeholder: '0' })
          .width('100%')
          .height(48)
          .type(InputType.Number)

        // 拉起按钮
        Button('拉起元服务')
          .width('100%')
          .onClick(() => this.launchAtomicService())

        // 结果展示
        if (this.resultMsg) {
          Text(this.resultMsg)
            .width('100%')
            .padding(12)
            .fontSize(13)
            .backgroundColor('#F5F5F5')
            .borderRadius(8)
        }

        // 跳转规则说明
        Column({ space: 8 }) {
          Text('跳转规则:').fontSize(14).fontWeight(FontWeight.Bold)
          Text('• 系统应用/元服务 → 元服务: 不弹窗，直接跳转').fontSize(12).fontColor('#666666')
          Text('• 三方应用/元服务 → 系统元服务: 不弹窗，直接跳转').fontSize(12).fontColor('#666666')
          Text('• 三方元服务(非关联主体) → 三方元服务: 每次弹窗确认').fontSize(12).fontColor('#666666')
          Text('• 关联主体账号组: 首次弹窗，30天内免弹').fontSize(12).fontColor('#666666')
          Text('• 三方应用(非关联主体) → 三方元服务: 禁止').fontSize(12).fontColor('#666666')
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
      }
      .padding(20)
    }
  }
}

export { OpenAtomicService }
