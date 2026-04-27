/**
 * payment-request — 华为支付（实物商品）
 * 元服务场景：paymentService.requestPayment 拉起收银台
 * 用于实物商品支付（酒店、出行、充值缴费等）
 * 数字商品请使用 IAP Kit（iap 模块）
 */
import { common } from '@kit.AbilityKit'
import { paymentService } from '@kit.PaymentKit'
import { BusinessError } from '@kit.BasicServicesKit'

@ComponentV2
export struct PaymentRequest {
  @Local payStatus: string = '点击按钮发起支付'
  @Local eventLog: string[] = []

  private context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('华为支付 (Payment)')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20, bottom: 10 })

        Text('paymentService.requestPayment 拉起收银台，用于实物商品')
          .fontSize(13)
          .fontColor('#666666')
          .width('90%')
          .textAlign(TextAlign.Center)

        // 状态卡片
        Column({ space: 8 }) {
          Text(this.payStatus)
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .width('100%')
        }
        .width('90%')
        .padding(16)
        .backgroundColor('#F5F5F5')
        .borderRadius(12)
        .alignItems(HorizontalAlign.Start)

        // 操作按钮
        Text('发起支付')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Button('基础支付（Promise）')
          .width('85%')
          .backgroundColor('#007DFF')
          .borderRadius(8)
          .onClick(() => {
            this.requestPaymentPromise()
          })

        Button('通用收银台（返回 PayResult）')
          .width('85%')
          .backgroundColor('#FF6B00')
          .borderRadius(8)
          .onClick(() => {
            this.requestPaymentWithResult()
          })

        // 适用场景说明
        Column({ space: 6 }) {
          Text('Payment Kit 适用场景:')
            .fontSize(13)
            .fontWeight(FontWeight.Bold)
          Text('- 实物商品购买（酒店、出行、充值缴费等）')
            .fontSize(12)
            .fontColor('#666666')
          Text('- 不支持虚拟商品，虚拟商品用 IAP Kit')
            .fontSize(12)
            .fontColor('#E84026')
          Text('- orderStr 由商户服务端生成（含 prepay_id、签名等）')
            .fontSize(12)
            .fontColor('#666666')
          Text('- 元服务开发方式与传统应用相同')
            .fontSize(12)
            .fontColor('#666666')
        }
        .width('90%')
        .padding(12)
        .backgroundColor('#FFF8F0')
        .borderRadius(8)
        .alignItems(HorizontalAlign.Start)

        // 事件日志
        Text('事件日志')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        if (this.eventLog.length === 0) {
          Text('暂无事件记录')
            .fontSize(13)
            .fontColor('#999999')
            .margin({ top: 4 })
        } else {
          ForEach(this.eventLog, (item: string, index: number) => {
            Text(item)
              .fontSize(12)
              .fontColor('#333333')
              .width('90%')
              .padding(8)
              .backgroundColor('#F9F9F9')
              .borderRadius(6)
              .maxLines(3)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }, (item: string, index: number) => `${index}`)
        }

        // API 说明
        Text('API 说明')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Column({ space: 4 }) {
          Text('paymentService.requestPayment(context, orderStr)')
            .fontSize(12)
            .fontColor('#007DFF')
            .fontFamily('monospace')
          Text('paymentService.requestPayment(context, orderStr, merchantType)')
            .fontSize(12)
            .fontColor('#007DFF')
            .fontFamily('monospace')
          Text('orderStr: JSON 字符串（app_id/merc_no/prepay_id/sign 等）')
            .fontSize(12)
            .fontColor('#666666')
          Text('PayResult: selectedPaymentType / clientToken / nextStep')
            .fontSize(12)
            .fontColor('#666666')
          Text('')
          Text('错误码:')
            .fontSize(12)
            .fontWeight(FontWeight.Bold)
          Text('1001930000: 用户取消 | 1001930001: 支付失败')
            .fontSize(11)
            .fontColor('#666666')
          Text('1001930002: 交易已处理 | 1001930011: 网络错误')
            .fontSize(11)
            .fontColor('#666666')
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
   * 基础支付 — Promise 方式
   * orderStr 由商户服务端调用华为支付 API 生成
   */
  private requestPaymentPromise(): void {
    this.payStatus = '正在拉起收银台...'
    // orderStr 应由商户服务端生成，此处仅为示例结构
    const orderStr = '{"app_id":"***","merc_no":"***","prepay_id":"test_prepay_id","timestamp":"1680259863114","noncestr":"test_noncestr","sign":"test_sign","auth_id":"test_auth_id"}'
    paymentService.requestPayment(this.context, orderStr)
      .then(() => {
        this.payStatus = '支付成功'
        this.addLog('支付成功（用户完成支付）')
      })
      .catch((error: BusinessError) => {
        if (error.code === 1001930000) {
          this.payStatus = '用户取消支付'
        } else {
          this.payStatus = `支付失败: [${error.code}] ${error.message}`
        }
        this.addLog(`支付结果: [${error.code}] ${error.message}`)
      })
  }

  /**
   * 通用收银台 — 返回 PayResult
   * 适用于需要获取用户选择的支付方式等信息的场景
   */
  private requestPaymentWithResult(): void {
    this.payStatus = '正在拉起通用收银台...'
    const orderStr = '{"nextAction":"L","linkUrl":"https://example.com/pay","scheme":"","clientToken":"test_token"}'
    paymentService.requestPayment(this.context, orderStr, 'AP')
      .then((payResult: paymentService.PayResult) => {
        this.payStatus = `支付成功: ${payResult.selectedPaymentType ?? 'default'}`
        this.addLog(`PayResult: type=${payResult.selectedPaymentType}, clientToken=${payResult.clientToken}`)
      })
      .catch((error: BusinessError) => {
        if (error.code === 1001930000) {
          this.payStatus = '用户取消支付'
        } else {
          this.payStatus = `支付失败: [${error.code}] ${error.message}`
        }
        this.addLog(`支付结果: [${error.code}] ${error.message}`)
      })
  }

  private addLog(msg: string): void {
    const time = new Date().toLocaleTimeString()
    this.eventLog = [`[${time}] ${msg}`, ...this.eventLog].slice(0, 15)
  }
}
