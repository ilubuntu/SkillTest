/**
 * account-kit-login — 华为账号登录
 * HuaweiIDProvider.createLoginWithHuaweiIDRequest + AuthenticationController.executeRequest
 * 元服务API: 从版本 4.1.0(11) 起支持
 */
import { authentication } from '@kit.AccountKit'
import { common } from '@kit.AbilityKit'
import { BusinessError } from '@kit.BasicServicesKit'
import { util } from '@kit.ArkTS'

@ComponentV2
export struct AccountKitLogin {
  @Local resultText: string = '点击下方按钮登录华为账号'
  @Local openId: string = '--'
  @Local unionId: string = '--'
  @Local authCode: string = '--'
  @Local idTokenSnippet: string = '--'
  @Local forceLogin: boolean = true
  @Local isLogging: boolean = false

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('华为账号登录')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20, bottom: 10 })

        Text('HuaweiIDProvider.createLoginWithHuaweiIDRequest')
          .fontSize(13)
          .fontColor('#666666')
          .width('90%')
          .textAlign(TextAlign.Center)

        // 结果展示卡片
        Column({ space: 8 }) {
          Row() {
            Text('OpenID: ')
              .fontSize(14)
              .fontColor('#999999')
            Text(this.openId)
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .layoutWeight(1)
          }
          .width('100%')

          Row() {
            Text('UnionID: ')
              .fontSize(14)
              .fontColor('#999999')
            Text(this.unionId)
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .layoutWeight(1)
          }
          .width('100%')

          Row() {
            Text('AuthCode: ')
              .fontSize(14)
              .fontColor('#999999')
            Text(this.authCode)
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .layoutWeight(1)
          }
          .width('100%')

          Row() {
            Text('ID Token: ')
              .fontSize(14)
              .fontColor('#999999')
            Text(this.idTokenSnippet)
              .fontSize(13)
              .fontColor('#333333')
              .maxLines(3)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .layoutWeight(1)
          }
          .width('100%')

          Text(this.resultText)
            .fontSize(13)
            .fontColor(this.resultText.includes('成功') ? '#00B578' : '#E84026')
            .width('100%')
        }
        .width('90%')
        .padding(16)
        .backgroundColor('#F5F5F5')
        .borderRadius(12)
        .alignItems(HorizontalAlign.Start)

        // 参数控制区
        Text('参数控制')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Row({ space: 12 }) {
          Text('forceLogin:')
            .fontSize(14)
          Toggle({ type: ToggleType.Switch, isOn: this.forceLogin })
            .onChange((isOn: boolean) => {
              this.forceLogin = isOn
            })
          Text(this.forceLogin ? '强制登录' : '非强制')
            .fontSize(13)
            .fontColor('#666666')
        }
        .width('90%')
        .justifyContent(FlexAlign.Start)

        // 操作按钮
        Button(this.isLogging ? '登录中...' : '华为账号登录')
          .width('80%')
          .backgroundColor('#007DFF')
          .borderRadius(8)
          .enabled(!this.isLogging)
          .onClick(() => {
            this.doLogin()
          })

        // API 说明
        Text('API 说明')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Column({ space: 4 }) {
          Text('import { authentication } from "@kit.AccountKit"')
            .fontSize(12)
            .fontColor('#007DFF')
            .fontFamily('monospace')
          Text('const provider = new authentication.HuaweiIDProvider()')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('const req = provider.createLoginWithHuaweiIDRequest()')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('req.forceLogin = true  // 未登录时强制拉起登录页')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('const ctrl = new authentication.AuthenticationController(context)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('ctrl.executeRequest(req, callback)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('')
            .fontSize(8)
          Text('LoginWithHuaweiIDCredential:')
            .fontSize(12)
            .fontColor('#333333')
            .fontWeight(FontWeight.Medium)
          Text('  openID / unionID / authorizationCode / idToken')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
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

  /**
   * 执行华为账号登录
   */
  private doLogin(): void {
    this.isLogging = true
    this.resultText = '正在登录...'
    try {
      const context = getContext(this) as common.Context
      const provider = new authentication.HuaweiIDProvider()
      const loginRequest = provider.createLoginWithHuaweiIDRequest()
      loginRequest.forceLogin = this.forceLogin
      loginRequest.state = util.generateRandomUUID()
      loginRequest.idTokenSignAlgorithm = authentication.IdTokenSignAlgorithm.PS256

      const controller = new authentication.AuthenticationController(context)
      controller.executeRequest(loginRequest, (error: BusinessError<Object>, data) => {
        this.isLogging = false
        if (error) {
          this.resultText = this.getErrorMessage(error.code, error.message)
          return
        }
        const response = data as authentication.LoginWithHuaweiIDResponse
        if (response.state && loginRequest.state !== response.state) {
          this.resultText = 'state 校验失败，可能存在跨站攻击'
          return
        }
        const credential = response.data
        if (credential) {
          this.openId = credential.openID ?? '--'
          this.unionId = credential.unionID ?? '--'
          this.authCode = credential.authorizationCode
            ? `${credential.authorizationCode.substring(0, 20)}...`
            : '--'
          this.idTokenSnippet = credential.idToken
            ? `${credential.idToken.substring(0, 40)}...`
            : '--'
          this.resultText = '登录成功'
        } else {
          this.resultText = '登录成功，但未获取到凭据'
        }
      })
    } catch (error) {
      this.isLogging = false
      this.resultText = `登录异常: ${error.message}`
    }
  }

  /**
   * 根据错误码返回友好提示
   */
  private getErrorMessage(code: number, msg: string): string {
    if (code === 1001502001) {
      return '用户未登录华为账号，请登录后重试'
    } else if (code === 1001502005) {
      return '网络异常，请检查网络状态后重试'
    } else if (code === 1001502012) {
      return '用户取消授权'
    } else if (code === 12300001) {
      return '系统服务异常，请稍后重试'
    } else if (code === 1001500002) {
      return '重复请求，请稍后再试'
    } else if (code === 1001500001) {
      return '应用指纹证书校验失败，请检查签名配置'
    } else if (code === 1001502014) {
      return '应用未申请所需权限'
    }
    return `登录失败: [${code}] ${msg}`
  }
}
