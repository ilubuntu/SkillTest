/**
 * save_button-event — SaveButton 授权事件处理
 * 展示 onClick 回调中 SaveButtonOnClickResult 的三种结果处理
 * 元服务兼容性：SUCCESS/FAILED 从 API 11 支持; CANCELED_BY_USER 从 API 21 支持
 */
import { BusinessError } from '@kit.BasicServicesKit'

@ComponentV2
export struct SaveButtonEvent {
  @Local resultLog: string = '点击保存控件测试不同授权结果'
  @Local successCount: number = 0
  @Local failCount: number = 0
  @Local lastErrorCode: number = -1
  @Local lastErrorMsg: string = ''
  @Local authStatus: string = '未触发'

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('SaveButton 授权事件处理')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20, bottom: 10 })

        // 结果展示区
        Column() {
          Text(this.resultLog)
            .fontSize(14)
            .fontColor('#333333')
            .width('100%')
            .padding(12)
        }
        .width('90%')
        .backgroundColor('#F5F5F5')
        .borderRadius(8)

        // 授权统计
        Row({ space: 16 }) {
          Column() {
            Text(`${this.successCount}`)
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .fontColor('#00B578')
            Text('授权成功')
              .fontSize(12)
              .fontColor('#666666')
          }
          Column() {
            Text(`${this.failCount}`)
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .fontColor('#E84026')
            Text('授权失败')
              .fontSize(12)
              .fontColor('#666666')
          }
          Column() {
            Text(this.authStatus)
              .fontSize(14)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.authStatus === '已授权' ? '#00B578' :
                this.authStatus === '授权失败' ? '#E84026' : '#999999')
            Text('当前状态')
              .fontSize(12)
              .fontColor('#666666')
          }
        }
        .width('90%')
        .justifyContent(FlexAlign.SpaceAround)
        .padding(12)
        .backgroundColor('#FAFAFA')
        .borderRadius(8)

        // 标准授权处理
        Text('1. 标准授权处理 (SUCCESS / FAILED)')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        SaveButton({ icon: SaveIconStyle.FULL_FILLED, text: SaveDescription.SAVE, buttonType: ButtonType.Capsule })
          .onClick((event: ClickEvent, result: SaveButtonOnClickResult, error?: BusinessError) => {
            this.handleAuthResult(result, error)
          })

        // 错误信息详情
        if (this.lastErrorCode >= 0) {
          Column() {
            Text(`最近错误码: ${this.lastErrorCode}`)
              .fontSize(12).fontColor('#E84026').width('100%')
            Text(`错误信息: ${this.lastErrorMsg}`)
              .fontSize(12).fontColor('#E84026').width('100%')
          }
          .width('90%')
          .padding(8)
          .backgroundColor('#FFF0F0')
          .borderRadius(8)
        }

        // 不同文本描述的授权
        Text('2. 不同场景授权')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Row({ space: 8 }) {
          SaveButton({ icon: SaveIconStyle.FULL_FILLED, text: SaveDescription.SAVE_IMAGE })
            .onClick((event: ClickEvent, result: SaveButtonOnClickResult, error?: BusinessError) => {
              this.handleAuthResult(result, error)
            })

          SaveButton({ icon: SaveIconStyle.FULL_FILLED, text: SaveDescription.DOWNLOAD_FILE })
            .onClick((event: ClickEvent, result: SaveButtonOnClickResult, error?: BusinessError) => {
              this.handleAuthResult(result, error)
            })
        }

        Row({ space: 8 }) {
          SaveButton({ icon: SaveIconStyle.FULL_FILLED, text: SaveDescription.SAVE_TO_GALLERY })
            .onClick((event: ClickEvent, result: SaveButtonOnClickResult, error?: BusinessError) => {
              this.handleAuthResult(result, error)
            })

          SaveButton({ icon: SaveIconStyle.FULL_FILLED, text: SaveDescription.RECEIVE })
            .onClick((event: ClickEvent, result: SaveButtonOnClickResult, error?: BusinessError) => {
              this.handleAuthResult(result, error)
            })
        }

        // 重置统计
        Button('重置统计')
          .fontSize(14)
          .height(36)
          .backgroundColor('#999999')
          .onClick(() => {
            this.successCount = 0
            this.failCount = 0
            this.lastErrorCode = -1
            this.lastErrorMsg = ''
            this.authStatus = '未触发'
            this.resultLog = '统计已重置'
          })

        // API 说明区
        Column() {
          Text('API 说明')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 8 })
          Text('onClick(event, result, error?) — 授权结果回调')
            .fontSize(12).fontColor('#666666').fontFamily('monospace').width('100%')
          Text('result: SaveButtonOnClickResult 枚举:')
            .fontSize(12).fontColor('#666666').width('100%')
          Text('  SUCCESS(0) — 授权成功 (API 11+)')
            .fontSize(12).fontColor('#00B578').fontFamily('monospace').width('100%')
          Text('  TEMPORARY_AUTHORIZATION_FAILED(1) — 授权失败 (API 11+)')
            .fontSize(12).fontColor('#E84026').fontFamily('monospace').width('100%')
          Text('  CANCELED_BY_USER(2) — 用户取消 (API 21+)')
            .fontSize(12).fontColor('#FF6B00').fontFamily('monospace').width('100%')
          Text('授权后10秒内(API19-)或1分钟(API20+)可访问媒体库')
            .fontSize(12).fontColor('#999999').width('100%')
          Text('error.code: 0=成功/用户取消, 1=系统错误, 2=属性设置错误')
            .fontSize(12).fontColor('#999999').fontFamily('monospace').width('100%')
          Text('元服务API: onClick 从 API 11 开始支持')
            .fontSize(12).fontColor('#999999').width('100%')
        }
        .width('90%')
        .backgroundColor('#FFF9E6')
        .borderRadius(8)
        .padding(12)
        .margin({ top: 8 })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
  }

  private handleAuthResult(result: SaveButtonOnClickResult, error?: BusinessError): void {
    if (result === SaveButtonOnClickResult.SUCCESS) {
      this.successCount++
      this.authStatus = '已授权'
      this.resultLog = '授权成功！可在限定时间内访问媒体库特权接口'
      this.lastErrorCode = -1
      this.lastErrorMsg = ''
    } else {
      this.failCount++
      this.authStatus = '授权失败'
      this.lastErrorCode = error?.code ?? -1
      this.lastErrorMsg = error?.message ?? '未知错误'
      this.resultLog = `授权失败: code=${this.lastErrorCode}, msg=${this.lastErrorMsg}`
    }
  }
}
