/**
 * ads-roll — 贴片广告（Roll Ad）
 * 元服务场景：AdLoader.loadAd + AdComponent 组件式展示
 * 广告类型 adType: 60
 * 支持前贴/中贴/后贴，需设置 totalDuration
 * 支持横竖屏切换、倒计时、VIP 跳过
 * 元服务无需 OAID 权限
 */
import { common } from '@kit.AbilityKit'
import { AdComponent, advertising } from '@kit.AdsKit'
import { window } from '@kit.ArkUI'
import { hilog } from '@kit.PerformanceAnalysisKit'
import { BusinessError } from '@kit.BasicServicesKit'

@ComponentV2
export struct AdsRoll {
  @Local ads: advertising.Advertisement[] = []
  @Local adStatus: string = '点击按钮加载贴片广告'
  @Local countDownText: string = ''
  @Local rollPlayState: number = 1
  @Local isPlayVideo: boolean = false
  @Local ratio: number = 16 / 9

  private adDisplayOptions: advertising.AdDisplayOptions = {
    mute: true
  }
  private playedAdSize: number = 0
  private countDownTxtPlaceholder: string = '%d | VIP免广告'
  private context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('贴片广告 (Roll)')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20, bottom: 10 })

        Text('AdComponent 组件式展示，支持前/中/后贴，横竖屏切换')
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
            Text('倒计时: ')
              .fontSize(14)
              .fontColor('#999999')
            Text(this.countDownText || '--')
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

        // 操作按钮
        Button('加载前贴广告')
          .width('80%')
          .backgroundColor('#007DFF')
          .borderRadius(8)
          .onClick(() => {
            this.loadAd()
          })

        // 广告模拟展示区域（简化版，不使用真实 Video）
        if (this.ads.length > 0 && !this.isPlayVideo) {
          Stack({ alignContent: Alignment.TopEnd }) {
            AdComponent({
              ads: [...this.ads],
              rollPlayState: this.rollPlayState,
              displayOptions: this.adDisplayOptions,
              interactionListener: {
                onStatusChanged: (status: string, ad: advertising.Advertisement, data: string) => {
                  switch (status) {
                    case 'onAdFail':
                      hilog.error(0x0000, 'AdsRoll', 'onAdFail')
                      this.adStatus = '广告加载失败，播放正片'
                      this.isPlayVideo = true
                      break
                    case 'onPortrait':
                      hilog.info(0x0000, 'AdsRoll', 'onPortrait — 切换竖屏')
                      this.ratio = 16 / 9
                      this.setWindowPreferredOrientation(window.Orientation.PORTRAIT)
                      this.setWindowSystemBar(['status', 'navigation'])
                      break
                    case 'onLandscape':
                      hilog.info(0x0000, 'AdsRoll', 'onLandscape — 切换横屏')
                      this.ratio = -1
                      this.setWindowPreferredOrientation(window.Orientation.LANDSCAPE)
                      this.setWindowSystemBar([])
                      break
                    case 'onMediaProgress':
                      hilog.info(0x0000, 'AdsRoll', 'onMediaProgress')
                      break
                    case 'onMediaComplete':
                      hilog.info(0x0000, 'AdsRoll', 'onMediaComplete')
                      this.playedAdSize++
                      this.adStatus = `广告播放完成 (${this.playedAdSize}/${this.ads.length})`
                      if (this.playedAdSize === this.ads.length) {
                        this.isPlayVideo = true
                        this.adStatus = '所有广告播放完成'
                      }
                      break
                    case 'onMediaCountdown':
                      hilog.info(0x0000, 'AdsRoll', 'onMediaCountdown')
                      const parseData: Record<string, Object> = this.safeParseData(data)
                      this.countDownText =
                        this.countDownTxtPlaceholder.replace('%d', String(parseData.countdownTime))
                      break
                    case 'onBackClicked':
                      hilog.info(0x0000, 'AdsRoll', 'onBackClicked')
                      this.getUIContext().getRouter().back()
                      break
                  }
                }
              }
            })
              .visibility(!this.isPlayVideo ? Visibility.Visible : Visibility.None)
              .width('100%')
              .height(200)

            Text(this.countDownText)
              .fontSize(10)
              .lineHeight(10)
              .maxLines(1)
              .textAlign(TextAlign.Center)
              .fontColor(Color.White)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .backgroundColor('#66000000')
              .border({ radius: 25 })
              .padding(4)
              .margin(8)
              .height(16)
              .onClick(() => {
                this.isPlayVideo = true
                this.adStatus = 'VIP 跳过广告'
              })
              .visibility(this.countDownText ? Visibility.Visible : Visibility.None)
          }
          .width('90%')
          .borderRadius(8)
          .clip(true)
        }

        if (this.isPlayVideo) {
          Column() {
            Text('正片播放区域')
              .fontSize(16)
              .fontColor('#333333')
            Text('（此处应为 Video 组件）')
              .fontSize(12)
              .fontColor('#999999')
          }
          .width('90%')
          .height(200)
          .backgroundColor('#000000')
          .borderRadius(8)
          .justifyContent(FlexAlign.Center)
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
          Text('AdComponent({ ads, rollPlayState, displayOptions, interactionListener })')
            .fontSize(12)
            .fontColor('#007DFF')
            .fontFamily('monospace')
          Text('AdRequestParams: adId / adType(60) / isPreload')
            .fontSize(12)
            .fontColor('#666666')
          Text('AdOptions: totalDuration (必填，贴片展示时长)')
            .fontSize(12)
            .fontColor('#666666')
          Text('回调: onAdFail / onPortrait / onLandscape / onMediaComplete / onMediaCountdown / onBackClicked')
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
   * 加载贴片广告
   */
  private loadAd(): void {
    this.adStatus = '正在加载...'
    this.isPlayVideo = false
    this.countDownText = ''
    this.playedAdSize = 0

    const adLoadListener: advertising.AdLoadListener = {
      onAdLoadFailure: (errorCode: number, errorMsg: string) => {
        hilog.error(0x0000, 'AdsRoll', `Load failed: ${errorCode}, ${errorMsg}`)
        this.adStatus = `加载失败: ${errorMsg}`
      },
      onAdLoadSuccess: (ads: Array<advertising.Advertisement>) => {
        hilog.info(0x0000, 'AdsRoll', 'Load success')
        this.ads = ads
        this.adStatus = `加载成功 (${ads.length} 条)`
      }
    }
    const adRequestParams: advertising.AdRequestParams = {
      adId: 'testy3cglm3pj0', // 测试广告位ID
      adType: 60,
      isPreload: false
    }
    // 贴片广告必填 totalDuration
    const adOptions: advertising.AdOptions = {
      totalDuration: 30
    }
    const adLoader: advertising.AdLoader = new advertising.AdLoader(this.context)
    try {
      adLoader.loadAd(adRequestParams, adOptions, adLoadListener)
    } catch (e) {
      hilog.error(0x0000, 'AdsRoll', `Load exception: ${(e as Error).message}`)
      this.adStatus = `加载异常: ${(e as Error).message}`
    }
  }

  private async setWindowPreferredOrientation(orientation: Orientation): Promise<void> {
    try {
      const win: window.Window = await window.getLastWindow(this.context)
      await win.setPreferredOrientation(orientation)
    } catch (e) {
      hilog.error(0x0000, 'AdsRoll', `Set orientation failed: ${(e as Error).message}`)
    }
  }

  private async setWindowSystemBar(names: Array<'status' | 'navigation'>): Promise<void> {
    try {
      const win: window.Window = await window.getLastWindow(this.context)
      await win.setWindowSystemBarEnable(names)
    } catch (e) {
      hilog.error(0x0000, 'AdsRoll', `Set system bar failed: ${(e as Error).message}`)
    }
  }

  private safeParseData(data: string): Record<string, Object> {
    try {
      if (typeof data === 'string') {
        return JSON.parse(data)
      }
      return JSON.parse(JSON.stringify(data))
    } catch (e) {
      hilog.error(0x0000, 'AdsRoll', `Parse data failed`)
    }
    return {}
  }
}
