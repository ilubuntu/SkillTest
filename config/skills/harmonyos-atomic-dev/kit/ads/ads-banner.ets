/**
 * ads-banner — 横幅广告（Banner Ad）
 * 元服务场景：AutoAdComponent 组件式展示
 * 广告类型 adType: 8，尺寸支持 360*57 和 360*144
 * 元服务无需 OAID 权限
 */
import { advertising, AutoAdComponent } from '@kit.AdsKit'
import { hilog } from '@kit.PerformanceAnalysisKit'

@ComponentV2
export struct AdsBanner {
  @Local visibilityState: Visibility = Visibility.None
  @Local adStatus: string = '等待加载'
  @Local selectedSize: string = '360x57'

  // 360*57 横幅广告请求参数
  private adRequestParams57: advertising.AdRequestParams = {
    adId: 'testw6vs28auh3', // 测试广告位ID
    adType: 8,
    adWidth: 360,
    adHeight: 57
  }

  // 360*144 横幅广告请求参数
  private adRequestParams144: advertising.AdRequestParams = {
    adId: 'testw6vs28auh3',
    adType: 8,
    adWidth: 360,
    adHeight: 144
  }

  private adOptions: advertising.AdOptions = {}
  private adDisplayOptions: advertising.AdDisplayOptions = {
    refreshTime: 30000 // 轮播间隔 30s
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('横幅广告 (Banner)')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20, bottom: 10 })

        Text('AutoAdComponent 组件式展示，元服务无需 OAID')
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
              .fontColor(this.adStatus === '加载失败' ? '#E84026' : '#333333')
          }
          .width('100%')

          Row() {
            Text('尺寸: ')
              .fontSize(14)
              .fontColor('#999999')
            Text(this.selectedSize)
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

        // 尺寸切换
        Text('选择广告尺寸')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Row({ space: 12 }) {
          Button('360 x 57')
            .backgroundColor(this.selectedSize === '360x57' ? '#007DFF' : '#999999')
            .borderRadius(8)
            .onClick(() => {
              this.selectedSize = '360x57'
              this.visibilityState = Visibility.None
              this.adStatus = '等待加载'
            })

          Button('360 x 144')
            .backgroundColor(this.selectedSize === '360x144' ? '#007DFF' : '#999999')
            .borderRadius(8)
            .onClick(() => {
              this.selectedSize = '360x144'
              this.visibilityState = Visibility.None
              this.adStatus = '等待加载'
            })
        }

        // 横幅广告区域
        Stack({ alignContent: Alignment.Bottom }) {
          Row() {
            AutoAdComponent({
              adParam: this.selectedSize === '360x57' ? this.adRequestParams57 : this.adRequestParams144,
              adOptions: this.adOptions,
              displayOptions: this.adDisplayOptions,
              interactionListener: {
                onStatusChanged: (status: string, ad: advertising.Advertisement, data: string) => {
                  switch (status) {
                    case 'onAdOpen':
                      hilog.info(0x0000, 'AdsBanner', 'onAdOpen')
                      this.adStatus = '广告已打开'
                      break
                    case 'onAdClick':
                      hilog.info(0x0000, 'AdsBanner', 'onAdClick')
                      this.adStatus = '广告被点击'
                      break
                    case 'onAdClose':
                      hilog.info(0x0000, 'AdsBanner', 'onAdClose')
                      this.adStatus = '广告已关闭'
                      this.visibilityState = Visibility.None
                      break
                    case 'onAdLoad':
                      hilog.info(0x0000, 'AdsBanner', 'onAdLoad')
                      this.adStatus = '加载成功'
                      this.visibilityState = Visibility.Visible
                      break
                    case 'onAdFail':
                      hilog.error(0x0000, 'AdsBanner', `onAdFail: ${data}`)
                      this.adStatus = '加载失败'
                      this.visibilityState = Visibility.None
                      break
                  }
                }
              }
            })
          }
          .width('100%')
          .aspectRatio(this.selectedSize === '360x57' ? 360 / 57 : 360 / 144)
          .visibility(this.visibilityState)
        }
        .width('100%')

        // API 说明
        Text('API 说明')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Column({ space: 4 }) {
          Text('AutoAdComponent({ adParam, adOptions, displayOptions, interactionListener })')
            .fontSize(12)
            .fontColor('#007DFF')
            .fontFamily('monospace')
          Text('AdRequestParams: adId / adType(8) / adWidth / adHeight')
            .fontSize(12)
            .fontColor('#666666')
          Text('AdDisplayOptions: refreshTime (30000~120000ms)')
            .fontSize(12)
            .fontColor('#666666')
          Text('尺寸限制: 仅支持 360x57 和 360x144')
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
}
