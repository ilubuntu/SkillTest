/**
 * ads-reward — 激励广告（Reward Ad）
 * 元服务场景：AdLoader.loadAd + advertising.showAd
 * 广告类型 adType: 7
 * 需订阅 PPS_REWARD_STATUS_CHANGED 事件
 * 支持 customData / userId 服务端验证
 * 元服务无需 OAID 权限
 */
import { common } from '@kit.AbilityKit'
import { advertising } from '@kit.AdsKit'
import { hilog } from '@kit.PerformanceAnalysisKit'
import { BusinessError, commonEventManager } from '@kit.BasicServicesKit'

const KEY_REWARD_STATUS = 'reward_ad_status'
const KEY_REWARD_DATA = 'reward_ad_data'

@ComponentV2
export struct AdsReward {
  @Local adStatus: string = '点击按钮加载广告'
  @Local rewardInfo: string = '--'
  @Local eventLog: string[] = []

  private context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext
  private subscriber: commonEventManager.CommonEventSubscriber | null = null

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('激励广告 (Reward)')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20, bottom: 10 })

        Text('用户观看视频获得奖励，需订阅 PPS_REWARD_STATUS_CHANGED')
          .fontSize(13)
          .fontColor('#666666')
          .width('90%')
          .textAlign(TextAlign.Center)

        // 状态卡片
        Column({ space: 8 }) {
          Row() {
            Text('状态: ')
              .fontSize(14)
              .fontColor('#999999')
            Text(this.adStatus)
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .layoutWeight(1)
          }
          .width('100%')

          Row() {
            Text('奖励: ')
              .fontSize(14)
              .fontColor('#999999')
            Text(this.rewardInfo)
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor('#00B578')
              .layoutWeight(1)
          }
          .width('100%')
        }
        .width('90%')
        .padding(16)
        .backgroundColor('#F5F5F5')
        .borderRadius(12)
        .alignItems(HorizontalAlign.Start)

        // 操作按钮
        Row({ space: 12 }) {
          Button('加载激励广告')
            .backgroundColor('#007DFF')
            .borderRadius(8)
            .onClick(() => {
              this.loadAndShowAd(false)
            })

          Button('带自定义数据')
            .backgroundColor('#FF6B00')
            .borderRadius(8)
            .onClick(() => {
              this.loadAndShowAd(true)
            })
        }

        // 奖励说明
        Column({ space: 4 }) {
          Text('激励广告流程:')
            .fontSize(13)
            .fontWeight(FontWeight.Medium)
          Text('1. 加载广告 → 2. 注册事件订阅 → 3. 展示广告')
            .fontSize(12)
            .fontColor('#666666')
          Text('4. 用户观看完成 → 5. 触发 onAdReward → 6. 发放奖励')
            .fontSize(12)
            .fontColor('#666666')
          Text('支持 S2S 服务端验证回调（需在鲸鸿动能配置 URL）')
            .fontSize(12)
            .fontColor('#E84026')
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
              .maxLines(2)
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
          Text('adLoader.loadAd(adRequestParams, adOptions, adLoadListener)')
            .fontSize(12)
            .fontColor('#007DFF')
            .fontFamily('monospace')
          Text('advertising.showAd(ad, adDisplayOptions, context)')
            .fontSize(12)
            .fontColor('#007DFF')
            .fontFamily('monospace')
          Text('AdRequestParams: adId / adType(7)')
            .fontSize(12)
            .fontColor('#666666')
          Text('AdDisplayOptions: mute / customData / userId')
            .fontSize(12)
            .fontColor('#666666')
          Text('事件: PPS_REWARD_STATUS_CHANGED')
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
   * 注册激励广告事件订阅
   */
  private registerPPSReceiver(): void {
    if (this.subscriber) {
      this.unRegisterPPSReceiver()
    }
    const subscribeInfo: commonEventManager.CommonEventSubscribeInfo = {
      events: ['com.huawei.hms.pps.action.PPS_REWARD_STATUS_CHANGED'],
      publisherBundleName: 'com.huawei.hms.adsservice'
    }
    commonEventManager.createSubscriber(subscribeInfo,
      (err: BusinessError, commonEventSubscriber: commonEventManager.CommonEventSubscriber) => {
        if (err) {
          hilog.error(0x0000, 'AdsReward', `Failed to create subscriber: ${err.message}`)
          return
        }
        this.subscriber = commonEventSubscriber
        commonEventManager.subscribe(this.subscriber,
          (err: BusinessError, commonEventData: commonEventManager.CommonEventData) => {
            if (err) {
              hilog.error(0x0000, 'AdsReward', `Subscribe error: ${err.message}`)
            } else {
              const status: string = commonEventData?.parameters?.[KEY_REWARD_STATUS]
              this.addLog(`事件: ${status}`)
              this.adStatus = `激励广告: ${status}`
              switch (status) {
                case 'onAdClose':
                  this.unRegisterPPSReceiver()
                  break
                case 'onAdReward':
                  const rewardData: Record<string, string | number> =
                    commonEventData?.parameters?.[KEY_REWARD_DATA]
                  if (rewardData) {
                    const rewardType = rewardData.rewardType as string ?? '--'
                    const rewardAmount = rewardData.rewardAmount as number ?? 0
                    this.rewardInfo = `${rewardType} x${rewardAmount}`
                    this.addLog(`奖励: ${rewardType} x${rewardAmount}`)
                  }
                  break
              }
            }
          })
      })
  }

  private unRegisterPPSReceiver(): void {
    if (!this.subscriber) {
      return
    }
    commonEventManager.unsubscribe(this.subscriber, (err: BusinessError) => {
      if (!err) {
        this.subscriber = null
      }
    })
  }

  /**
   * 加载并展示激励广告
   */
  private loadAndShowAd(withCustomData: boolean): void {
    this.adStatus = '正在加载广告...'
    this.rewardInfo = '--'
    const adLoadListener: advertising.AdLoadListener = {
      onAdLoadFailure: (errorCode: number, errorMsg: string) => {
        hilog.error(0x0000, 'AdsReward', `Load failed: ${errorCode}, ${errorMsg}`)
        this.adStatus = `加载失败: ${errorMsg}`
      },
      onAdLoadSuccess: (ads: Array<advertising.Advertisement>) => {
        hilog.info(0x0000, 'AdsReward', 'Load success')
        this.adStatus = '加载成功，展示中...'
        try {
          this.registerPPSReceiver()
          const adDisplayOptions: advertising.AdDisplayOptions = {
            mute: true
          }
          if (withCustomData) {
            adDisplayOptions.customData = 'CUSTOM_DATA'
            adDisplayOptions.userId = '1234567'
          }
          advertising.showAd(ads[0], adDisplayOptions, this.context)
        } catch (e) {
          hilog.error(0x0000, 'AdsReward', `Show failed: ${(e as Error).message}`)
          this.adStatus = `展示失败: ${(e as Error).message}`
        }
      }
    }
    const adRequestParams: advertising.AdRequestParams = {
      adId: 'testx9dtjwj8hp', // 测试广告位ID
      adType: 7
    }
    const adOptions: advertising.AdOptions = {}
    const adLoader: advertising.AdLoader = new advertising.AdLoader(this.context)
    try {
      adLoader.loadAd(adRequestParams, adOptions, adLoadListener)
    } catch (e) {
      hilog.error(0x0000, 'AdsReward', `Load exception: ${(e as Error).message}`)
      this.adStatus = `加载异常: ${(e as Error).message}`
    }
  }

  private addLog(msg: string): void {
    const time = new Date().toLocaleTimeString()
    this.eventLog = [`[${time}] ${msg}`, ...this.eventLog].slice(0, 15)
  }
}
