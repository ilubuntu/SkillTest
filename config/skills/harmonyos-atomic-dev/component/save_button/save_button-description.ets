/**
 * save_button-description — SaveDescription 文本描述枚举
 * 展示所有可用的文本描述选项
 * 元服务兼容性：API 11+ 支持 DOWNLOAD~CONTINUE_TO_RECEIVE; API 12+ 支持图库相关; API 18+ 支持 SAVE_ALL
 */
import { BusinessError } from '@kit.BasicServicesKit'

@ComponentV2
export struct SaveButtonDescription {
  @Local resultLog: string = '点击不同文本描述的保存控件'
  @Local selectedDesc: string = '未选择'

  // API 11+ 可用的描述
  private descListApi11: SaveDescription[] = [
    SaveDescription.DOWNLOAD,
    SaveDescription.DOWNLOAD_FILE,
    SaveDescription.SAVE,
    SaveDescription.SAVE_IMAGE,
    SaveDescription.SAVE_FILE,
    SaveDescription.DOWNLOAD_AND_SHARE,
    SaveDescription.RECEIVE,
    SaveDescription.CONTINUE_TO_RECEIVE
  ]

  private descNamesApi11: string[] = [
    'DOWNLOAD(下载)',
    'DOWNLOAD_FILE(下载文件)',
    'SAVE(保存)',
    'SAVE_IMAGE(保存图片)',
    'SAVE_FILE(保存文件)',
    'DOWNLOAD_AND_SHARE(下载分享)',
    'RECEIVE(接收)',
    'CONTINUE_TO_RECEIVE(继续接收)'
  ]

  // API 12+ 可用的图库描述
  private descListApi12: SaveDescription[] = [
    SaveDescription.SAVE_TO_GALLERY,
    SaveDescription.EXPORT_TO_GALLERY,
    SaveDescription.QUICK_SAVE_TO_GALLERY,
    SaveDescription.RESAVE_TO_GALLERY
  ]

  private descNamesApi12: string[] = [
    'SAVE_TO_GALLERY(保存至图库)',
    'EXPORT_TO_GALLERY(导出)',
    'QUICK_SAVE_TO_GALLERY(快速保存图片)',
    'RESAVE_TO_GALLERY(重新保存)'
  ]

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('SaveButton 文本描述')
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

        Text(`当前选中: ${this.selectedDesc}`)
          .fontSize(14)
          .fontColor('#666666')

        // API 11+ 基础描述
        Text('API 11+ 基础文本描述')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        ForEach(this.descListApi11, (desc: SaveDescription, index?: number) => {
          Column() {
            Text(this.descNamesApi11[index ?? 0])
              .fontSize(12)
              .fontColor('#666666')
              .alignSelf(ItemAlign.Start)
              .margin({ left: 4 })
            SaveButton({ icon: SaveIconStyle.FULL_FILLED, text: desc, buttonType: ButtonType.Capsule })
              .onClick((event: ClickEvent, result: SaveButtonOnClickResult, error?: BusinessError) => {
                this.selectedDesc = this.descNamesApi11[index ?? 0]
                this.handleResult(result, error)
              })
          }
          .width('90%')
          .alignItems(HorizontalAlign.Center)
          .margin({ top: 4 })
        }, (desc: SaveDescription, index?: number) => `${index}`)

        // API 12+ 图库描述
        Text('API 12+ 图库相关描述')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 16 })

        ForEach(this.descListApi12, (desc: SaveDescription, index?: number) => {
          Column() {
            Text(this.descNamesApi12[index ?? 0])
              .fontSize(12)
              .fontColor('#666666')
              .alignSelf(ItemAlign.Start)
              .margin({ left: 4 })
            SaveButton({ icon: SaveIconStyle.FULL_FILLED, text: desc, buttonType: ButtonType.Capsule })
              .onClick((event: ClickEvent, result: SaveButtonOnClickResult, error?: BusinessError) => {
                this.selectedDesc = this.descNamesApi12[index ?? 0]
                this.handleResult(result, error)
              })
          }
          .width('90%')
          .alignItems(HorizontalAlign.Center)
          .margin({ top: 4 })
        }, (desc: SaveDescription, index?: number) => `${index}`)

        // API 18+ SAVE_ALL
        Text('API 18+ 全部保存描述')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 16 })

        Column() {
          Text('SAVE_ALL(全部保存)')
            .fontSize(12)
            .fontColor('#666666')
            .alignSelf(ItemAlign.Start)
            .margin({ left: 4 })
          SaveButton({ icon: SaveIconStyle.FULL_FILLED, text: SaveDescription.SAVE_ALL, buttonType: ButtonType.Capsule })
            .onClick((event: ClickEvent, result: SaveButtonOnClickResult, error?: BusinessError) => {
              this.selectedDesc = 'SAVE_ALL(全部保存)'
              this.handleResult(result, error)
            })
        }
        .width('90%')
        .alignItems(HorizontalAlign.Center)
        .margin({ top: 4 })

        // API 说明区
        Column() {
          Text('API 说明')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 8 })
          Text('SaveDescription 共 13 种文本描述:')
            .fontSize(12).fontColor('#666666').width('100%')
          Text('API 11+: DOWNLOAD(0) ~ CONTINUE_TO_RECEIVE(7)')
            .fontSize(12).fontColor('#666666').fontFamily('monospace').width('100%')
          Text('API 12+: SAVE_TO_GALLERY(8) ~ RESAVE_TO_GALLERY(11)')
            .fontSize(12).fontColor('#666666').fontFamily('monospace').width('100%')
          Text('API 18+: SAVE_ALL(12)')
            .fontSize(12).fontColor('#666666').fontFamily('monospace').width('100%')
          Text('元服务兼容性: 与 API 版本一致')
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

  private handleResult(result: SaveButtonOnClickResult, error?: BusinessError): void {
    if (result === SaveButtonOnClickResult.SUCCESS) {
      this.resultLog = '授权成功，可在限定时间内访问媒体库'
    } else {
      this.resultLog = `授权失败: code=${error?.code}, msg=${error?.message}`
    }
  }
}
