/**
 * AppLinkingReceive — 元服务 APP Linking: 链接接收与解析示例
 *
 * 演示被拉起方如何处理传入的元服务链接：
 * 1. want.uri → 元服务链接地址
 * 2. want.parameters → 静态自定义参数（如 pagePath、navRouterName）
 * 3. want.parameters.orgScanCode → 普通链接二维码码值（需 5.1.1+）
 *
 * 实际开发中这些代码应放在 EntryAbility 的 onCreate/onNewWant 中，
 * 此组件通过 UI 模拟演示接收端的处理逻辑。
 */
import { Want } from '@kit.AbilityKit'
import { url } from '@kit.ArkTS'

@ComponentV2
struct AppLinkingReceive {
  @Local simulateUri: string = 'https://hoas.drcn.agconnect.link/9P7g?action=showall'
  @Local simulateScanCode: string = 'https://www.example.com/programs?type=vip'
  @Local pagePath: string = ''
  @Local navRouterName: string = ''
  @Local subPackageName: string = ''
  @Local parsedAction: string = ''
  @Local parsedResult: string = ''

  /**
   * 模拟解析 want.uri（元服务链接）
   * 实际代码在 EntryAbility.onCreate / onNewWant 中
   */
  private parseUri(): void {
    let uri = this.simulateUri.trim()
    if (!uri) {
      this.parsedResult = '请输入 URI'
      return
    }
    try {
      let urlObject = url.URL.parseURL(uri)
      let action = urlObject.params.get('action')
      this.parsedAction = action || '(无)'
      let lines: string[] = [
        `host: ${urlObject.host}`,
        `pathname: ${urlObject.pathname}`,
        `action: ${this.parsedAction}`
      ]
      urlObject.params.forEach((value: string, key: string) => {
        lines.push(`  ${key} = ${value}`)
      })
      this.parsedResult = lines.join('\n')
    } catch (error) {
      this.parsedResult = 'URI 解析失败'
    }
  }

  /**
   * 模拟解析静态自定义参数（want.parameters）
   */
  private parseStaticParams(): void {
    let lines: string[] = []
    if (this.pagePath) {
      lines.push(`pagePath: ${this.pagePath}`)
    }
    if (this.navRouterName) {
      lines.push(`navRouterName: ${this.navRouterName}`)
    }
    if (this.subPackageName) {
      lines.push(`subPackageName: ${this.subPackageName}`)
    }
    if (lines.length === 0) {
      this.parsedResult = '未配置静态参数'
    } else {
      this.parsedResult = '静态自定义参数:\n' + lines.join('\n')
    }
  }

  /**
   * 模拟解析普通链接二维码码值（orgScanCode）
   */
  private parseScanCode(): void {
    let code = this.simulateScanCode.trim()
    if (!code) {
      this.parsedResult = '请输入码值'
      return
    }
    try {
      let urlObject = url.URL.parseURL(code)
      let lines: string[] = [
        `码值 host: ${urlObject.host}`,
        `码值 pathname: ${urlObject.pathname}`
      ]
      urlObject.params.forEach((value: string, key: string) => {
        lines.push(`  ${key} = ${value}`)
      })
      this.parsedResult = lines.join('\n')
    } catch (error) {
      this.parsedResult = '码值解析失败'
    }
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        // 标题
        Text('App Linking — 链接接收与解析')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)

        Text('演示被拉起方如何处理元服务链接、静态参数和二维码码值')
          .fontSize(13)
          .fontColor('#666666')

        // 1. URI 解析
        Text('1. want.uri 解析（动态参数）').fontSize(15).fontWeight(FontWeight.Medium).width('100%')
        TextInput({ text: $$this.simulateUri, placeholder: '输入元服务链接' })
          .width('100%')
          .height(48)
        Button('解析 URI')
          .width('100%')
          .onClick(() => this.parseUri())

        // 2. 静态参数解析
        Divider().margin({ top: 8, bottom: 8 })
        Text('2. want.parameters 静态参数').fontSize(15).fontWeight(FontWeight.Medium).width('100%')
        Text('pagePath（router 跳转页面路径）').fontSize(12).width('100%')
        TextInput({ text: $$this.pagePath, placeholder: '如 pages/SubPage' })
          .width('100%')
          .height(40)
        Text('navRouterName（Navigation 路由名）').fontSize(12).width('100%')
        TextInput({ text: $$this.navRouterName, placeholder: '如 ProductList' })
          .width('100%')
          .height(40)
        Text('subPackageName（子包名，可选）').fontSize(12).width('100%')
        TextInput({ text: $$this.subPackageName, placeholder: '如 library' })
          .width('100%')
          .height(40)
        Button('解析静态参数')
          .width('100%')
          .onClick(() => this.parseStaticParams())

        // 3. 二维码码值解析
        Divider().margin({ top: 8, bottom: 8 })
        Text('3. orgScanCode 解析（普通链接二维码, 5.1.1+）').fontSize(15).fontWeight(FontWeight.Medium).width('100%')
        TextInput({ text: $$this.simulateScanCode, placeholder: '输入二维码码值 URL' })
          .width('100%')
          .height(48)
        Button('解析码值')
          .width('100%')
          .onClick(() => this.parseScanCode())

        // 结果
        if (this.parsedResult) {
          Text('解析结果:').fontSize(14).fontWeight(FontWeight.Medium).width('100%')
          Text(this.parsedResult)
            .width('100%')
            .padding(12)
            .fontSize(13)
            .backgroundColor('#F5F5F5')
            .borderRadius(8)
        }

        // 代码参考
        Divider().margin({ top: 8, bottom: 8 })
        Column({ space: 6 }) {
          Text('EntryAbility 代码参考:').fontSize(14).fontWeight(FontWeight.Bold)
          Text('// onCreate / onNewWant 中:').fontSize(12).fontColor('#666666')
          Text('let uri = want?.uri;').fontSize(12).fontColor('#666666').fontFamily('monospace')
          Text('let urlObj = url.URL.parseURL(uri);').fontSize(12).fontColor('#666666').fontFamily('monospace')
          Text('let action = urlObj.params.get("action");').fontSize(12).fontColor('#666666').fontFamily('monospace')
          Text('let pagePath = want.parameters?.["pagePath"];').fontSize(12).fontColor('#666666').fontFamily('monospace')
          Text('let scanCode = want.parameters?.orgScanCode;').fontSize(12).fontColor('#666666').fontFamily('monospace')
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
      }
      .padding(20)
    }
  }
}

export { AppLinkingReceive }
