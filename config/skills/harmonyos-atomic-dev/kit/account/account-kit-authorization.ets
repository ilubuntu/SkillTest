/**
 * account-kit-authorization — 华为账号授权
 * HuaweiIDProvider.createAuthorizationWithHuaweiIDRequest
 * 元服务API: 从版本 5.0.0(12) 起支持
 */
import { authentication } from '@kit.AccountKit'
import { common } from '@kit.AbilityKit'
import { BusinessError } from '@kit.BasicServicesKit'
import { util } from '@kit.ArkTS'

@ComponentV2
export struct AccountKitAuthorization {
  @Local resultText: string = '点击下方按钮请求用户授权'
  @Local authOpenId: string = '--'
  @Local authUnionId: string = '--'
  @Local authAvatarUri: string = '--'
  @Local authNickName: string = '--'
  @Local authScopes: string = '--'
  @Local isAuthorizing: boolean = false
  @Local selectedScopes: string[] = ['openid']

  private readonly SCOPE_OPTIONS: string[] = ['openid', 'profile']

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('华为账号授权')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20, bottom: 10 })

        Text('HuaweiIDProvider.createAuthorizationWithHuaweiIDRequest')
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
            Text(this.authOpenId)
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .layoutWeight(1)
          }
          .width('100%')

          Row() {
            Text('昵称: ')
              .fontSize(14)
              .fontColor('#999999')
            Text(this.authNickName)
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .layoutWeight(1)
          }
          .width('100%')

          Row() {
            Text('头像URI: ')
              .fontSize(14)
              .fontColor('#999999')
            Text(this.authAvatarUri)
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .layoutWeight(1)
          }
          .width('100%')

          Row() {
            Text('授权Scopes: ')
              .fontSize(14)
              .fontColor('#999999')
            Text(this.authScopes)
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
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
        Text('Scopes 选择')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Row({ space: 8 }) {
          ForEach(this.SCOPE_OPTIONS, (scope: string) => {
            Button(scope)
              .fontSize(13)
              .height(36)
              .backgroundColor(this.selectedScopes.includes(scope) ? '#007DFF' : '#CCCCCC')
              .borderRadius(8)
              .onClick(() => {
                this.toggleScope(scope)
              })
          }, (scope: string) => scope)
        }

        // 操作按钮
        Button(this.isAuthorizing ? '授权中...' : '请求授权')
          .width('80%')
          .backgroundColor('#FF6B00')
          .borderRadius(8)
          .enabled(!this.isAuthorizing)
          .onClick(() => {
            this.doAuthorize()
          })

        // API 说明
        Text('API 说明')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Column({ space: 4 }) {
          Text('createAuthorizationWithHuaweiIDRequest()')
            .fontSize(12)
            .fontColor('#007DFF')
            .fontFamily('monospace')
          Text('AuthorizationWithHuaweiIDRequest:')
            .fontSize(12)
            .fontColor('#333333')
            .fontWeight(FontWeight.Medium)
          Text('  scopes / permissions / forceAuthorization')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('  state / nonce / idTokenSignAlgorithm')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('  supportAtomicService: boolean (元服务专用)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('')
            .fontSize(8)
          Text('AuthorizationWithHuaweiIDCredential:')
            .fontSize(12)
            .fontColor('#333333')
            .fontWeight(FontWeight.Medium)
          Text('  openID / unionID / authorizationCode / idToken')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('  avatarUri / nickName / authorizedScopes')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('')
            .fontSize(8)
          Text('元服务API: 从版本 5.0.0(12) 起支持')
            .fontSize(12)
            .fontColor('#E84026')
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
   * 切换 scope 选项
   */
  private toggleScope(scope: string): void {
    if (this.selectedScopes.includes(scope)) {
      if (scope === 'openid') {
        return // openid 为默认值，不可移除
      }
      this.selectedScopes = this.selectedScopes.filter((s: string) => s !== scope)
    } else {
      this.selectedScopes = [...this.selectedScopes, scope]
    }
  }

  /**
   * 执行授权请求
   */
  private doAuthorize(): void {
    this.isAuthorizing = true
    this.resultText = '正在请求授权...'
    try {
      const context = getContext(this) as common.Context
      const provider = new authentication.HuaweiIDProvider()
      const authRequest = provider.createAuthorizationWithHuaweiIDRequest()
      authRequest.scopes = [...this.selectedScopes]
      authRequest.permissions = ['idtoken', 'serviceauthcode']
      authRequest.forceAuthorization = true
      authRequest.state = util.generateRandomUUID()
      authRequest.idTokenSignAlgorithm = authentication.IdTokenSignAlgorithm.PS256

      const controller = new authentication.AuthenticationController(context)
      controller.executeRequest(authRequest, (error: BusinessError<Object>, data) => {
        this.isAuthorizing = false
        if (error) {
          this.resultText = this.getErrorMessage(error.code, error.message)
          return
        }
        const response = data as authentication.AuthorizationWithHuaweiIDResponse
        if (response.state && authRequest.state !== response.state) {
          this.resultText = 'state 校验失败'
          return
        }
        const credential = response.data
        if (credential) {
          this.authOpenId = credential.openID ?? '--'
          this.authUnionId = credential.unionID ?? '--'
          this.authAvatarUri = credential.avatarUri ?? '--'
          this.authNickName = credential.nickName ?? '--'
          this.authScopes = credential.authorizedScopes
            ? credential.authorizedScopes.join(', ')
            : '--'
          this.resultText = '授权成功'
        } else {
          this.resultText = '授权成功，但未获取到凭据'
        }
      })
    } catch (error) {
      this.isAuthorizing = false
      this.resultText = `授权异常: ${error.message}`
    }
  }

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
      return '应用指纹证书校验失败'
    } else if (code === 1001502014) {
      return '应用未申请所需 scopes 或 permissions'
    } else if (code === 1001500003) {
      return '不支持该 scopes 或 permissions'
    }
    return `授权失败: [${code}] ${msg}`
  }
}
