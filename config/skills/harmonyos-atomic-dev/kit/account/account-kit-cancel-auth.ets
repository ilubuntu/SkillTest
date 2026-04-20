/**
 * account-kit-cancel-auth — 取消华为账号授权
 * HuaweiIDProvider.createCancelAuthorizationRequest
 * 元服务API: 从版本 5.0.0(12) 起支持
 */
import { authentication } from '@kit.AccountKit'
import { common } from '@kit.AbilityKit'
import { BusinessError } from '@kit.BasicServicesKit'
import { util } from '@kit.ArkTS'

@ComponentV2
export struct AccountKitCancelAuth {
  @Local resultText: string = '点击下方按钮取消华为账号授权'
  @Local cancelState: string = '--'
  @Local isCanceling: boolean = false

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('取消华为账号授权')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20, bottom: 10 })

        Text('HuaweiIDProvider.createCancelAuthorizationRequest')
          .fontSize(13)
          .fontColor('#666666')
          .width('90%')
          .textAlign(TextAlign.Center)

        // 结果展示卡片
        Column({ space: 8 }) {
          Row() {
            Text('响应 State: ')
              .fontSize(14)
              .fontColor('#999999')
            Text(this.cancelState)
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .maxLines(2)
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

        // 操作按钮
        Text('操作')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Button(this.isCanceling ? '取消中...' : '取消授权')
          .width('80%')
          .backgroundColor('#E84026')
          .borderRadius(8)
          .enabled(!this.isCanceling)
          .onClick(() => {
            this.doCancelAuthorization()
          })

        // API 说明
        Text('API 说明')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Column({ space: 4 }) {
          Text('createCancelAuthorizationRequest()')
            .fontSize(12)
            .fontColor('#007DFF')
            .fontFamily('monospace')
          Text('CancelAuthorizationRequest:')
            .fontSize(12)
            .fontColor('#333333')
            .fontWeight(FontWeight.Medium)
          Text('  state: string (util.generateRandomUUID())')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('')
            .fontSize(8)
          Text('CancelAuthorizationResponse:')
            .fontSize(12)
            .fontColor('#333333')
            .fontWeight(FontWeight.Medium)
          Text('  state: string (用于校验防止跨站攻击)')
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
   * 执行取消授权
   */
  private doCancelAuthorization(): void {
    this.isCanceling = true
    this.resultText = '正在取消授权...'
    try {
      const context = getContext(this) as common.Context
      const provider = new authentication.HuaweiIDProvider()
      const cancelRequest = provider.createCancelAuthorizationRequest()
      cancelRequest.state = util.generateRandomUUID()

      const controller = new authentication.AuthenticationController(context)
      controller.executeRequest(cancelRequest, (error: BusinessError<Object>, data) => {
        this.isCanceling = false
        if (error) {
          this.resultText = this.getErrorMessage(error.code, error.message)
          return
        }
        const response = data as authentication.CancelAuthorizationResponse
        if (response.state && cancelRequest.state !== response.state) {
          this.resultText = 'state 校验失败'
          return
        }
        this.cancelState = response.state ?? '--'
        this.resultText = '取消授权成功'
      })
    } catch (error) {
      this.isCanceling = false
      this.resultText = `取消授权异常: ${error.message}`
    }
  }

  private getErrorMessage(code: number, msg: string): string {
    if (code === 1001502001) {
      return '用户未登录华为账号'
    } else if (code === 1001502005) {
      return '网络异常，请检查网络状态后重试'
    } else if (code === 1001502012) {
      return '用户取消操作'
    } else if (code === 12300001) {
      return '系统服务异常，请稍后重试'
    } else if (code === 1001500002) {
      return '重复请求'
    }
    return `取消授权失败: [${code}] ${msg}`
  }
}
