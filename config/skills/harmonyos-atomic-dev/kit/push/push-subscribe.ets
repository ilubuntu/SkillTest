/**
 * push-subscribe — 服务通知订阅请求
 * 元服务场景：serviceNotification.requestSubscribeNotification
 * 基于华为账号订阅，type 固定为 SUBSCRIBE_WITH_HUAWEI_ID
 * 前置条件：在 AGC 开通服务通知并领用订阅模板
 */
import { common } from '@kit.AbilityKit'
import { serviceNotification } from '@kit.PushKit'
import { BusinessError } from '@kit.BasicServicesKit'
import { hilog } from '@kit.PerformanceAnalysisKit'

@ComponentV2
export struct PushSubscribe {
  @Local subStatus: string = '等待发起订阅请求'
  @Local subResults: string[] = []
  @Local eventLog: string[] = []

  private context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('服务通知订阅')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20, bottom: 10 })

        Text('requestSubscribeNotification 基于华为账号订阅')
          .fontSize(13)
          .fontColor('#666666')
          .width('90%')
          .textAlign(TextAlign.Center)

        // 状态卡片
        Column({ space: 8 }) {
          Text(this.subStatus)
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .width('100%')
        }
        .width('90%')
        .padding(16)
        .backgroundColor('#F5F5F5')
        .borderRadius(12)
        .alignItems(HorizontalAlign.Start)

        // 订阅结果
        if (this.subResults.length > 0) {
          Text('订阅结果')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .alignSelf(ItemAlign.Start)
            .margin({ left: 16, top: 8 })

          ForEach(this.subResults, (item: string, index: number) => {
            Text(item)
              .fontSize(13)
              .fontColor('#333333')
              .width('90%')
              .padding(10)
              .backgroundColor('#E8F5E9')
              .borderRadius(8)
          }, (item: string, index: number) => `${index}`)
        }

        // 操作按钮
        Text('发起订阅')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Button('订阅一次性消息（单个模板）')
          .width('85%')
          .backgroundColor('#007DFF')
          .borderRadius(8)
          .onClick(() => {
            this.requestSubscribeSingle()
          })

        Button('订阅一次性消息（多个模板）')
          .width('85%')
          .backgroundColor('#FF6B00')
          .borderRadius(8)
          .onClick(() => {
            this.requestSubscribeMultiple()
          })

        Button('订阅长期消息')
          .width('85%')
          .backgroundColor('#00B578')
          .borderRadius(8)
          .onClick(() => {
            this.requestSubscribeLongTerm()
          })

        // 前置条件说明
        Column({ space: 6 }) {
          Text('前置条件:')
            .fontSize(13)
            .fontWeight(FontWeight.Bold)
          Text('1. 在 AGC 开通推送服务')
            .fontSize(12)
            .fontColor('#666666')
          Text('2. 在 AGC「服务通知」中领用订阅模板')
            .fontSize(12)
            .fontColor('#666666')
          Text('3. 元服务通过分类标签和资质认证')
            .fontSize(12)
            .fontColor('#666666')
          Text('4. entityIds 替换为实际领用的模板 ID')
            .fontSize(12)
            .fontColor('#E84026')
        }
        .width('90%')
        .padding(12)
        .backgroundColor('#FFF8F0')
        .borderRadius(8)
        .alignItems(HorizontalAlign.Start)

        // 频控规则
        Column({ space: 4 }) {
          Text('频控规则:')
            .fontSize(13)
            .fontWeight(FontWeight.Bold)
          Text('单设备单元服务 ≤ 30次/5分钟，超限进入频控')
            .fontSize(12)
            .fontColor('#666666')
          Text('单次最多订阅 3 个模板')
            .fontSize(12)
            .fontColor('#666666')
          Text('不可混合使用一次性 + 长期模板 ID')
            .fontSize(12)
            .fontColor('#E84026')
        }
        .width('90%')
        .padding(12)
        .backgroundColor('#FFF0F0')
        .borderRadius(8)
        .alignItems(HorizontalAlign.Start)

        // API 说明
        Text('API 说明')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Column({ space: 4 }) {
          Text('serviceNotification.requestSubscribeNotification(context, entityIds, type)')
            .fontSize(12)
            .fontColor('#007DFF')
            .fontFamily('monospace')
          Text('type: SUBSCRIBE_WITH_HUAWEI_ID（元服务固定值）')
            .fontSize(12)
            .fontColor('#666666')
          Text('返回: RequestResult { entityResult: EntityResult[] }')
            .fontSize(12)
            .fontColor('#666666')
          Text('EntityResult: { entityId: string, resultCode: ResultCode(0/1/2) }')
            .fontSize(12)
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
   * 订阅单个一次性消息模板
   */
  private async requestSubscribeSingle(): Promise<void> {
    this.subStatus = '正在发起订阅请求...'
    this.subResults = []
    try {
      // entityIds 需替换为 AGC 领用的实际模板 ID
      const entityIds: string[] = ['13B6000E24008000']
      const type: serviceNotification.SubscribeNotificationType =
        serviceNotification.SubscribeNotificationType.SUBSCRIBE_WITH_HUAWEI_ID
      const res: serviceNotification.RequestResult =
        await serviceNotification.requestSubscribeNotification(this.context, entityIds, type)
      hilog.info(0x0000, 'PushSubscribe', `Subscribe result: ${JSON.stringify(res.entityResult)}`)
      this.subStatus = '订阅请求完成'
      this.parseResults(res.entityResult)
    } catch (err) {
      const e = err as BusinessError
      hilog.error(0x0000, 'PushSubscribe', `Subscribe failed: ${e.code}, ${e.message}`)
      this.subStatus = `订阅失败: [${e.code}] ${e.message}`
      this.addLog(`错误: [${e.code}] ${e.message}`)
    }
  }

  /**
   * 订阅多个一次性消息模板（最多 3 个）
   */
  private async requestSubscribeMultiple(): Promise<void> {
    this.subStatus = '正在发起多模板订阅请求...'
    this.subResults = []
    try {
      const entityIds: string[] = ['13B6000E24008000', '13B90C82D3802680']
      const type: serviceNotification.SubscribeNotificationType =
        serviceNotification.SubscribeNotificationType.SUBSCRIBE_WITH_HUAWEI_ID
      const res: serviceNotification.RequestResult =
        await serviceNotification.requestSubscribeNotification(this.context, entityIds, type)
      hilog.info(0x0000, 'PushSubscribe', `Multi subscribe result: ${JSON.stringify(res.entityResult)}`)
      this.subStatus = '多模板订阅请求完成'
      this.parseResults(res.entityResult)
    } catch (err) {
      const e = err as BusinessError
      hilog.error(0x0000, 'PushSubscribe', `Multi subscribe failed: ${e.code}, ${e.message}`)
      this.subStatus = `订阅失败: [${e.code}] ${e.message}`
    }
  }

  /**
   * 订阅长期消息模板
   */
  private async requestSubscribeLongTerm(): Promise<void> {
    this.subStatus = '正在发起长期订阅请求...'
    this.subResults = []
    try {
      // 长期订阅模板 ID，需替换为实际的长期模板 ID
      const entityIds: string[] = ['LONG_TERM_TEMPLATE_ID']
      const type: serviceNotification.SubscribeNotificationType =
        serviceNotification.SubscribeNotificationType.SUBSCRIBE_WITH_HUAWEI_ID
      const res: serviceNotification.RequestResult =
        await serviceNotification.requestSubscribeNotification(this.context, entityIds, type)
      hilog.info(0x0000, 'PushSubscribe', `Long term subscribe result: ${JSON.stringify(res.entityResult)}`)
      this.subStatus = '长期订阅请求完成'
      this.parseResults(res.entityResult)
    } catch (err) {
      const e = err as BusinessError
      hilog.error(0x0000, 'PushSubscribe', `Long term subscribe failed: ${e.code}, ${e.message}`)
      this.subStatus = `订阅失败: [${e.code}] ${e.message}`
    }
  }

  /**
   * 解析订阅结果
   * entityResult 类型为 EntityResult[]
   * EntityResult: { entityId: string, resultCode: ResultCode }
   * ResultCode: 0=ACCEPTED, 1=REJECTED, 2=FILTERED
   */
  private parseResults(entityResults: serviceNotification.EntityResult[]): void {
    this.subResults = []
    if (entityResults && entityResults.length > 0) {
      for (const item of entityResults) {
        const templateId = item.entityId ?? '--'
        const code = item.resultCode
        let desc = ''
        if (code === serviceNotification.ResultCode.ACCEPTED) {
          desc = '已同意 (ACCEPTED)'
        } else if (code === serviceNotification.ResultCode.REJECTED) {
          desc = '已拒绝 (REJECTED)'
        } else if (code === serviceNotification.ResultCode.FILTERED) {
          desc = '被过滤 (FILTERED)'
        } else {
          desc = `未知(${code})`
        }
        const line = `模板 ${templateId}: ${desc}`
        this.subResults.push(line)
        this.addLog(line)
      }
    }
  }

  private addLog(msg: string): void {
    const time = new Date().toLocaleTimeString()
    this.eventLog = [`[${time}] ${msg}`, ...this.eventLog].slice(0, 15)
  }
}
