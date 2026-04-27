/**
 * AppLinkingOpen — 元服务 APP Linking: openLink 拉起示例
 *
 * 元服务链接是密文 URL（固定域名 hoas.drcn.agconnect.link），
 * 通过 UIAbilityContext.openLink() 拉起目标元服务。
 * appLinkingOnly=true: 仅限 App Linking，未匹配则抛异常
 * appLinkingOnly=false(默认): 未匹配则走浏览器
 */
import { common } from '@kit.AbilityKit'
import { BusinessError } from '@kit.BasicServicesKit'
import { url } from '@kit.ArkTS'

@ComponentV2
struct AppLinkingOpen {
  @Local inputLink: string = 'https://hoas.drcn.agconnect.link/9P7g'
  @Local resultMsg: string = ''
  @Local appLinkingOnly: boolean = true

  /**
   * 使用 openLink 拉起目标元服务
   * - 匹配到元服务 → 直接打开
   * - 未匹配 → appLinkingOnly=true 抛异常; false 走浏览器
   */
  private openLink(): void {
    let context = this.getUIContext().getHostContext() as common.UIAbilityContext
    let link = this.inputLink.trim()
    if (!link) {
      this.resultMsg = '请输入元服务链接'
      return
    }

    context.openLink(link, { appLinkingOnly: this.appLinkingOnly })
      .then(() => {
        this.resultMsg = '拉起成功'
      })
      .catch((error: BusinessError) => {
        this.resultMsg = `拉起失败 [${error.code}]: ${error.message}`
      })
  }

  /**
   * 解析元服务链接中的 query 参数（演示用，实际在 EntryAbility 中处理）
   */
  private parseLinkParams(): void {
    let link = this.inputLink.trim()
    if (!link) {
      this.resultMsg = '请输入链接'
      return
    }
    try {
      let urlObject = url.URL.parseURL(link)
      let params: string[] = []
      urlObject.params.forEach((value: string, key: string) => {
        params.push(`${key}=${value}`)
      })
      if (params.length === 0) {
        this.resultMsg = `链接无 query 参数\nhost: ${urlObject.host}\npathname: ${urlObject.pathname}`
      } else {
        this.resultMsg = `解析结果:\nhost: ${urlObject.host}\npathname: ${urlObject.pathname}\nparams: ${params.join(', ')}`
      }
    } catch (error) {
      this.resultMsg = 'URL 解析失败，请检查格式'
    }
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        // 标题
        Text('App Linking — openLink 拉起')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)

        Text('元服务链接（密文 URL）通过 openLink 拉起目标元服务，链接有效期 1~90 天')
          .fontSize(13)
          .fontColor('#666666')

        // 链接输入
        TextInput({ text: $$this.inputLink, placeholder: '输入元服务链接' })
          .width('100%')
          .height(48)
          .type(InputType.Normal)

        // appLinkingOnly 开关
        Row({ space: 12 }) {
          Text('appLinkingOnly')
            .fontSize(14)
          Toggle({ type: ToggleType.Switch, isOn: this.appLinkingOnly })
            .onChange((isOn: boolean) => {
              this.appLinkingOnly = isOn
            })
          Text(this.appLinkingOnly ? 'true（仅 App Linking）' : 'false（回退浏览器）')
            .fontSize(12)
            .fontColor('#999999')
        }
        .width('100%')

        // 操作按钮
        Button('拉起元服务')
          .width('100%')
          .onClick(() => this.openLink())

        Button('解析链接参数')
          .width('100%')
          .backgroundColor('#007DFF')
          .onClick(() => this.parseLinkParams())

        // 结果展示
        if (this.resultMsg) {
          Text(this.resultMsg)
            .width('100%')
            .padding(12)
            .fontSize(13)
            .backgroundColor('#F5F5F5')
            .borderRadius(8)
        }

        // 说明
        Column({ space: 8 }) {
          Text('说明:').fontSize(14).fontWeight(FontWeight.Bold)
          Text('• 元服务链接固定域名: hoas.drcn.agconnect.link').fontSize(12).fontColor('#666666')
          Text('• appLinkingOnly=true: 仅 App Linking，未匹配抛异常(16000019)').fontSize(12).fontColor('#666666')
          Text('• appLinkingOnly=false: 未匹配则走浏览器打开').fontSize(12).fontColor('#666666')
          Text('• 链接有效期: 1~90 天，在 AGC 平台创建').fontSize(12).fontColor('#666666')
          Text('• 支持动态参数: ?key=value 拼接到链接末尾').fontSize(12).fontColor('#666666')
          Text('• 支持静态参数: 在 AGC 创建链接时配置').fontSize(12).fontColor('#666666')
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
      }
      .padding(20)
    }
  }
}

export { AppLinkingOpen }
