/**
 * ads-native — 原生广告（Native Ad）
 * 元服务场景：AdLoader.loadAdWithMultiSlots + AdComponent 组件式展示
 * 广告类型 adType: 3
 * 支持信息流（width:100%, height自适应）和插图（312x284vp）
 * 元服务无需 OAID 权限
 */
import { common } from '@kit.AbilityKit'
import { AdComponent, advertising } from '@kit.AdsKit'
import { hilog } from '@kit.PerformanceAnalysisKit'

@ComponentV2
export struct AdsNative {
  @Local ads: advertising.Advertisement[] = []
  @Local adStatus: string = '点击按钮加载广告'
  @Local visibilityState: Visibility = Visibility.None
  @Local adStyle: string = 'infeed' // 'infeed' | 'card'

  private context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('原生广告 (Native)')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20, bottom: 10 })

        Text('AdComponent 组件式展示，支持信息流和插图样式')
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
            Text('样式: ')
              .fontSize(14)
              .fontColor('#999999')
            Text(this.adStyle === 'infeed' ? '信息流' : '插图')
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
          }
          .width('100%')
        }
        .width('90%')
        .padding(16)
        .backgroundColor('#F5F5F5')
        .borderRadius(12)
        .alignItems(HorizontalAlign.Start)

        // 样式选择
        Row({ space: 12 }) {
          Button('信息流样式')
            .backgroundColor(this.adStyle === 'infeed' ? '#007DFF' : '#999999')
            .borderRadius(8)
            .onClick(() => {
              this.adStyle = 'infeed'
              this.visibilityState = Visibility.None
            })

          Button('插图样式')
            .backgroundColor(this.adStyle === 'card' ? '#007DFF' : '#999999')
            .borderRadius(8)
            .onClick(() => {
              this.adStyle = 'card'
              this.visibilityState = Visibility.None
            })
        }

        // 加载按钮
        Button('加载原生广告')
          .width('80%')
          .backgroundColor('#FF6B00')
          .borderRadius(8)
          .onClick(() => {
            this.loadAd()
          })

        // 广告展示区域
        if (this.ads.length > 0 && this.visibilityState === Visibility.Visible) {
          if (this.adStyle === 'infeed') {
            this.buildInFeedAd(this.ads[0])
          } else {
            this.buildCardAd(this.ads[0])
          }
        }

        // API 说明
        Text('API 说明')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Column({ space: 4 }) {
          Text('adLoader.loadAdWithMultiSlots(adRequestParams[], adOptions, listener)')
            .fontSize(12)
            .fontColor('#007DFF')
            .fontFamily('monospace')
          Text('AdComponent({ ads, displayOptions, interactionListener })')
            .fontSize(12)
            .fontColor('#007DFF')
            .fontFamily('monospace')
          Text('AdRequestParams: adId / adType(3) / enableDirectReturnVideoAd')
            .fontSize(12)
            .fontColor('#666666')
          Text('信息流: width=100%, height 自适应')
            .fontSize(12)
            .fontColor('#666666')
          Text('插图: width=312vp, height=284vp')
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

  @Builder
  buildInFeedAd(ad: advertising.Advertisement): void {
    Row() {
      AdComponent({
        ads: [ad],
        displayOptions: {
          mute: true
        },
        interactionListener: {
          onStatusChanged: (status: string, ad: advertising.Advertisement, data: string) => {
            this.handleAdStatus(status)
          }
        }
      })
        .width('100%')
    }
    .width('90%')
    .padding({ left: 16, right: 16 })
    .visibility(this.visibilityState)
  }

  @Builder
  buildCardAd(ad: advertising.Advertisement): void {
    Row() {
      AdComponent({
        ads: [ad],
        displayOptions: {
          mute: true
        },
        interactionListener: {
          onStatusChanged: (status: string, ad: advertising.Advertisement, data: string) => {
            this.handleAdStatus(status)
          }
        }
      })
        .width(312)
        .height(284)
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
    .visibility(this.visibilityState)
  }

  private handleAdStatus(status: string): void {
    switch (status) {
      case 'onAdOpen':
        hilog.info(0x0000, 'AdsNative', 'onAdOpen')
        break
      case 'onAdClick':
        hilog.info(0x0000, 'AdsNative', 'onAdClick')
        break
      case 'onAdClose':
        hilog.info(0x0000, 'AdsNative', 'onAdClose')
        this.visibilityState = Visibility.None
        this.adStatus = '广告已关闭'
        break
      case 'onAdFail':
        hilog.error(0x0000, 'AdsNative', 'onAdFail')
        this.visibilityState = Visibility.None
        this.adStatus = '广告加载失败'
        break
    }
  }

  /**
   * 加载原生广告
   */
  private loadAd(): void {
    this.adStatus = '正在加载...'
    this.visibilityState = Visibility.None
    const adRequestParamsArray: advertising.AdRequestParams[] = [
      {
        adId: 'testb4znbuh3n2', // 测试广告位ID（原生广告测试位）
        adType: 3,
        enableDirectReturnVideoAd: true
      }
    ]
    const adOptions: advertising.AdOptions = {}
    const multiSlotsAdLoaderListener: advertising.MultiSlotsAdLoadListener = {
      onAdLoadFailure: (errorCode: number, errorMsg: string) => {
        hilog.error(0x0000, 'AdsNative', `Load failed: ${errorCode}, ${errorMsg}`)
        this.adStatus = `加载失败: ${errorMsg}`
      },
      onAdLoadSuccess: (ads: Map<string, Array<advertising.Advertisement>>) => {
        hilog.info(0x0000, 'AdsNative', 'Load success')
        const returnAds: advertising.Advertisement[] = []
        ads.forEach((adsArray) => returnAds.push(...adsArray))
        this.ads = returnAds
        this.visibilityState = Visibility.Visible
        this.adStatus = `加载成功 (${returnAds.length} 条)`
      }
    }
    const adLoader: advertising.AdLoader = new advertising.AdLoader(this.context)
    try {
      adLoader.loadAdWithMultiSlots(adRequestParamsArray, adOptions, multiSlotsAdLoaderListener)
    } catch (e) {
      hilog.error(0x0000, 'AdsNative', `Load exception: ${(e as Error).message}`)
      this.adStatus = `加载异常: ${(e as Error).message}`
    }
  }
}
