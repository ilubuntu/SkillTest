/**
 * button-save — SaveButton 安全保存控件
 * 展示安全控件的保存按钮，用于获取媒体库临时授权
 * 元服务兼容性：从 API version 11 开始支持在元服务中使用
 */
import { BusinessError } from '@kit.BasicServicesKit'

@ComponentV2
export struct ButtonSave {
  @Local resultText: string = '点击下方保存控件触发授权'
  @Local authResult: string = '未授权'

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('SaveButton 安全保存控件')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20, bottom: 10 })

        // 结果展示区
        Column() {
          Text(this.resultText)
            .fontSize(14)
            .fontColor('#333333')
            .width('100%')
            .padding(12)
        }
        .width('90%')
        .backgroundColor('#F5F5F5')
        .borderRadius(8)

        // 授权状态
        Row({ space: 8 }) {
          Text('授权状态:')
            .fontSize(14)
            .fontColor('#666666')
          Text(this.authResult)
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.authResult === '授权成功' ? '#00B578' :
              this.authResult === '授权失败' ? '#E84026' : '#999999')
        }

        // 默认保存按钮
        Text('默认保存按钮（图标 + 文字 + 背景）')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        SaveButton()
          .onClick((event: ClickEvent, result: SaveButtonOnClickResult, error?: BusinessError) => {
            this.handleSaveClick(result, error)
          })

        // 仅图标
        Text('仅图标保存按钮')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        SaveButton({ icon: SaveIconStyle.FULL_FILLED, buttonType: ButtonType.Capsule })
          .onClick((event: ClickEvent, result: SaveButtonOnClickResult, error?: BusinessError) => {
            this.handleSaveClick(result, error)
          })

        // 图标 + 文字 + 自定义类型
        Text('图标 + 文字 + 胶囊背景')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        SaveButton({
          icon: SaveIconStyle.FULL_FILLED,
          text: SaveDescription.SAVE,
          buttonType: ButtonType.Capsule
        })
          .onClick((event: ClickEvent, result: SaveButtonOnClickResult, error?: BusinessError) => {
            this.handleSaveClick(result, error)
          })

        // 下载文件按钮
        Text('下载文件类型')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        SaveButton({
          icon: SaveIconStyle.LINES,
          text: SaveDescription.DOWNLOAD_FILE,
          buttonType: ButtonType.Capsule
        })
          .onClick((event: ClickEvent, result: SaveButtonOnClickResult, error?: BusinessError) => {
            this.handleSaveClick(result, error)
          })

        // API 说明区
        Column() {
          Text('API 说明')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 8 })
          Text('SaveButton() — 默认创建（图标+文字+背景）')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('SaveButton({ icon, text, buttonType })')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('icon: SaveIconStyle.FULL_FILLED | LINES')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('text: DOWNLOAD | SAVE | SAVE_IMAGE | DOWNLOAD_FILE | ...')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('onClick(event, result, error?) — result 为授权结果')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('授权后 10 秒内（API19-）或 1 分钟（API20+）可访问媒体库')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('不支持通用属性，仅继承安全控件通用属性')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('元服务API: 从 API version 11 开始支持')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
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

  private handleSaveClick(result: SaveButtonOnClickResult, error?: BusinessError): void {
    if (result === SaveButtonOnClickResult.SUCCESS) {
      this.authResult = '授权成功'
      this.resultText = '保存控件授权成功，可在限定时间内访问媒体库'
    } else {
      this.authResult = '授权失败'
      this.resultText = `授权失败: code=${error?.code}, msg=${error?.message}`
    }
  }
}
