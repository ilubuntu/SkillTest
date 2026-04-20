/**
 * account-kit-avatar-nickname — 通过接口方式获取华为账号头像昵称
 * HuaweiIDProvider.createAuthorizationWithHuaweiIDRequest
 * scopes: ['profile'] + supportAtomicService: true
 * 元服务API: 从版本 5.0.0(12) 起支持
 */
import { authentication } from '@kit.AccountKit'
import { common } from '@kit.AbilityKit'
import { BusinessError } from '@kit.BasicServicesKit'
import { util } from '@kit.ArkTS'

@ComponentV2
export struct AccountKitAvatarNickname {
  @Local resultText: string = '点击下方按钮获取头像昵称'
  @Local avatarUri: string = '--'
  @Local nickName: string = '--'
  @Local authCode: string = '--'
  @Local isFetching: boolean = false
  @Local authScopes: string = '--'

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('获取头像昵称')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20, bottom: 10 })

        Text('AuthorizationWithHuaweiIDRequest + scopes: profile')
          .fontSize(13)
          .fontColor('#666666')
          .width('90%')
          .textAlign(TextAlign.Center)

        // 头像展示区
        Column({ space: 12 }) {
          if (this.avatarUri !== '--' && this.avatarUri.length > 0) {
            Image(this.avatarUri)
              .width(80)
              .height(80)
              .borderRadius(40)
              .alt('/common/placeholder.png')
              .autoResize(true)
          } else {
            Column() {
              Text('头像')
                .fontSize(14)
                .fontColor('#CCCCCC')
            }
            .width(80)
            .height(80)
            .borderRadius(40)
            .backgroundColor('#F0F0F0')
            .justifyContent(FlexAlign.Center)
          }

          Row() {
            Text('昵称: ')
              .fontSize(14)
              .fontColor('#999999')
            Text(this.nickName)
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .layoutWeight(1)
          }
          .width('100%')

          Row() {
            Text('头像URI: ')
              .fontSize(14)
              .fontColor('#999999')
            Text(this.avatarUri)
              .fontSize(13)
              .fontColor('#333333')
              .maxLines(3)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .layoutWeight(1)
          }
          .width('100%')

          Row() {
            Text('AuthCode: ')
              .fontSize(14)
              .fontColor('#999999')
            Text(this.authCode)
              .fontSize(13)
              .fontColor('#333333')
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
        .alignItems(HorizontalAlign.Center)

        // 说明卡片
        Column({ space: 6 }) {
          Text('元服务关键参数')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor('#333333')
          Text('1. scopes 必须传 ["profile"]')
            .fontSize(13)
            .fontColor('#8C6D1F')
          Text('2. supportAtomicService 必须设为 true')
            .fontSize(13)
            .fontColor('#8C6D1F')
          Text('3. permissions 传 ["serviceauthcode"] 获取 Authorization Code（服务端场景需要）')
            .fontSize(13)
            .fontColor('#8C6D1F')
          Text('4. 未设置昵称时默认返回绑定的匿名手机号/邮箱')
            .fontSize(13)
            .fontColor('#8C6D1F')
        }
        .width('90%')
        .padding(12)
        .backgroundColor('#FFFBE6')
        .borderRadius(10)
        .borderWidth(1)
        .borderColor('#FFE58F')
        .alignItems(HorizontalAlign.Start)

        // 操作按钮
        Button(this.isFetching ? '获取中...' : '获取头像昵称')
          .width('80%')
          .backgroundColor('#007DFF')
          .borderRadius(8)
          .enabled(!this.isFetching)
          .onClick(() => {
            this.fetchAvatarNickname()
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
          Text('import { util } from "@kit.ArkTS"')
            .fontSize(12)
            .fontColor('#007DFF')
            .fontFamily('monospace')
          Text('import { common } from "@kit.AbilityKit"')
            .fontSize(12)
            .fontColor('#007DFF')
            .fontFamily('monospace')
          Text('import { BusinessError } from "@kit.BasicServicesKit"')
            .fontSize(12)
            .fontColor('#007DFF')
            .fontFamily('monospace')
          Text('')
            .fontSize(8)
          Text('const provider = new authentication.HuaweiIDProvider()')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('const req = provider.createAuthorizationWithHuaweiIDRequest()')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('req.scopes = ["profile"]  // 获取头像昵称的 scope')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('req.supportAtomicService = true  // 元服务必须设置')
            .fontSize(12)
            .fontColor('#E84026')
            .fontFamily('monospace')
          Text('req.permissions = ["serviceauthcode"]')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('req.forceAuthorization = true')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('req.state = util.generateRandomUUID()')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('')
            .fontSize(8)
          Text('AuthorizationWithHuaweiIDCredential:')
            .fontSize(12)
            .fontColor('#333333')
            .fontWeight(FontWeight.Medium)
          Text('  avatarUri: string  // 头像下载地址')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('  nickName: string   // 用户昵称')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('  authorizationCode  // 用于服务端换取 Access Token')
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
   * 获取头像昵称
   */
  private fetchAvatarNickname(): void {
    this.isFetching = true
    this.resultText = '正在请求头像昵称...'
    try {
      const context = getContext(this) as common.Context
      const provider = new authentication.HuaweiIDProvider()
      const authRequest = provider.createAuthorizationWithHuaweiIDRequest()
      authRequest.scopes = ['profile']
      authRequest.supportAtomicService = true
      authRequest.permissions = ['serviceauthcode']
      authRequest.forceAuthorization = true
      authRequest.state = util.generateRandomUUID()
      authRequest.idTokenSignAlgorithm = authentication.IdTokenSignAlgorithm.PS256

      const controller = new authentication.AuthenticationController(context)
      controller.executeRequest(authRequest, (error: BusinessError<Object>, data) => {
        this.isFetching = false
        if (error) {
          this.resultText = this.getErrorMessage(error.code, error.message)
          return
        }
        const response = data as authentication.AuthorizationWithHuaweiIDResponse
        if (response.state && authRequest.state !== response.state) {
          this.resultText = 'state 校验失败，可能存在跨站攻击'
          return
        }
        const credential = response.data
        if (credential) {
          this.avatarUri = credential.avatarUri ?? '--'
          this.nickName = credential.nickName ?? '--'
          this.authCode = credential.authorizationCode
            ? `${credential.authorizationCode.substring(0, 20)}...`
            : '--'
          this.authScopes = credential.authorizedScopes
            ? credential.authorizedScopes.join(', ')
            : '--'
          this.resultText = '获取头像昵称成功'
        } else {
          this.resultText = '授权成功，但未获取到凭据'
        }
      })
    } catch (error) {
      this.isFetching = false
      this.resultText = `获取异常: ${error.message}`
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
      return '应用指纹证书校验失败，请检查签名配置'
    } else if (code === 1001502014) {
      return '应用未申请所需权限'
    } else if (code === 1001500003) {
      return '不支持该 scopes 或 permissions'
    }
    return `获取失败: [${code}] ${msg}`
  }
}
