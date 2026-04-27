/**
 * ads-interstitial — 插屏广告（Interstitial Ad）
 * 元服务场景：AdLoader.loadAd + advertising.showAd
 * 广告类型 adType: 12
 * 需订阅 PPS_INTERSTITIAL_STATUS_CHANGED 事件
 * 元服务无需 OAID 权限
 */
import { common } from '@kit.AbilityKit'
import { advertising } from '@kit.AdsKit'
import { hilog } from '@kit.PerformanceAnalysisKit'
import { BusinessError, commonEventManager } from '@kit.BasicServicesKit'

const KEY_INTERSTITIAL_STATUS = 'interstitial_ad_status'

@ComponentV2
export struct AdsInterstitial {
  @Local adStatus: string = '点击按钮加载广告'
  @Local eventLog: string[] = []

  private context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext
  private subscriber: commonEventManager.CommonEventSubscriber | null = null

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('插屏广告 (Interstitial)')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20, bottom: 10 })

        Text('AdLoader.loadAd + showAd，需订阅公共事件')
          .fontSize(13)
          .fontColor('#666666')
          .width('90%')
          .textAlign(TextAlign.Center)

        // 状态卡片
        Column({ space: 8 }) {
          Text(this.adStatus)
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
        Button('加载并展示插屏广告')
          .width('80%')
          .backgroundColor('#007DFF')
          .borderRadius(8)
          .onClick(() => {
            this.loadAndShowAd()
          })

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
          Text('AdRequestParams: adId / adType(12)')
            .fontSize(12)
            .fontColor('#666666')
          Text('事件: PPS_INTERSTITIAL_STATUS_CHANGED')
            .fontSize(12)
            .fontColor('#666666')
          Text('状态: onAdOpen / onAdClick / onAdClose / onVideoPlayBegin / onVideoPlayEnd')
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
   * 注册插屏广告事件订阅
   */
  private registerPPSReceiver(): void {
    if (this.subscriber) {
      this.unRegisterPPSReceiver()
    }
    const subscribeInfo: commonEventManager.CommonEventSubscribeInfo = {
      events: ['com.huawei.hms.pps.action.PPS_INTERSTITIAL_STATUS_CHANGED'],
      publisherBundleName: 'com.huawei.hms.adsservice'
    }
    commonEventManager.createSubscriber(subscribeInfo,
      (err: BusinessError, commonEventSubscriber: commonEventManager.CommonEventSubscriber) => {
        if (err) {
          hilog.error(0x0000, 'AdsInterstitial', `Failed to create subscriber: ${err.message}`)
          return
        }
        this.subscriber = commonEventSubscriber
        commonEventManager.subscribe(this.subscriber,
          (err: BusinessError, commonEventData: commonEventManager.CommonEventData) => {
            if (err) {
              hilog.error(0x0000, 'AdsInterstitial', `Subscribe error: ${err.message}`)
            } else {
              const status: string = commonEventData?.parameters?.[KEY_INTERSTITIAL_STATUS]
              this.addLog(`事件: ${status}`)
              this.adStatus = `插屏广告: ${status}`
              if (status === 'onAdClose') {
                this.unRegisterPPSReceiver()
              }
            }
          })
      })
  }

  /**
   * 取消订阅
   */
  private unRegisterPPSReceiver(): void {
    if (!this.subscriber) {
      return
    }
    commonEventManager.unsubscribe(this.subscriber, (err: BusinessError) => {
      if (err) {
        hilog.error(0x0000, 'AdsInterstitial', `Unsubscribe error: ${err.message}`)
      } else {
        this.subscriber = null
      }
    })
  }

  /**
   * 加载并展示插屏广告
   */
  private loadAndShowAd(): void {
    this.adStatus = '正在加载广告...'
    const adLoadListener: advertising.AdLoadListener = {
      onAdLoadFailure: (errorCode: number, errorMsg: string) => {
        hilog.error(0x0000, 'AdsInterstitial', `Load failed: ${errorCode}, ${errorMsg}`)
        this.adStatus = `加载失败: ${errorMsg}`
      },
      onAdLoadSuccess: (ads: Array<advertising.Advertisement>) => {
        hilog.info(0x0000, 'AdsInterstitial', 'Load success')
        this.adStatus = '加载成功，展示中...'
        try {
          this.registerPPSReceiver()
          const adDisplayOptions: advertising.AdDisplayOptions = {
            mute: true
          }
          advertising.showAd(ads[0], adDisplayOptions, this.context)
        } catch (e) {
          hilog.error(0x0000, 'AdsInterstitial', `Show failed: ${(e as Error).message}`)
          this.adStatus = `展示失败: ${(e as Error).message}`
        }
      }
    }
    const adRequestParams: advertising.AdRequestParams = {
      adId: 'testb4znbuh3n2', // 测试广告位ID
      adType: 12
    }
    const adOptions: advertising.AdOptions = {}
    const adLoader: advertising.AdLoader = new advertising.AdLoader(this.context)
    try {
      adLoader.loadAd(adRequestParams, adOptions, adLoadListener)
    } catch (e) {
      hilog.error(0x0000, 'AdsInterstitial', `Load exception: ${(e as Error).message}`)
      this.adStatus = `加载异常: ${(e as Error).message}`
    }
  }

  private addLog(msg: string): void {
    const time = new Date().toLocaleTimeString()
    this.eventLog = [`[${time}] ${msg}`, ...this.eventLog].slice(0, 10)
  }
}
