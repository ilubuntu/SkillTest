/**
 * save_button-basic — SaveButton 基础创建方式
 * 展示默认构造和带参数构造的不同组合
 * 元服务兼容性：从 API version 11 开始支持在元服务中使用
 */
import { BusinessError } from '@kit.BasicServicesKit'

@ComponentV2
export struct SaveButtonBasic {
  @Local resultLog: string = '点击保存控件观察不同创建方式的效果'
  @Local clickCount: number = 0

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('SaveButton 基础创建')
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

        Text(`点击次数: ${this.clickCount}`)
          .fontSize(14)
          .fontColor('#666666')

        // 1. 默认构造
        Text('1. 默认构造 SaveButton()')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        SaveButton()
          .onClick((event: ClickEvent, result: SaveButtonOnClickResult, error?: BusinessError) => {
            this.handleClick('默认构造', result, error)
          })

        // 2. 仅图标
        Text('2. 仅图标 (FULL_FILLED + Capsule)')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        SaveButton({ icon: SaveIconStyle.FULL_FILLED, buttonType: ButtonType.Capsule })
          .onClick((event: ClickEvent, result: SaveButtonOnClickResult, error?: BusinessError) => {
            this.handleClick('仅图标', result, error)
          })

        // 3. 仅文字
        Text('3. 仅文字 (SAVE + Normal)')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        SaveButton({ text: SaveDescription.SAVE, buttonType: ButtonType.Normal })
          .onClick((event: ClickEvent, result: SaveButtonOnClickResult, error?: BusinessError) => {
            this.handleClick('仅文字', result, error)
          })

        // 4. 图标 + 文字
        Text('4. 图标 + 文字 (FULL_FILLED + DOWNLOAD + Capsule)')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        SaveButton({
          icon: SaveIconStyle.FULL_FILLED,
          text: SaveDescription.DOWNLOAD,
          buttonType: ButtonType.Capsule
        })
          .onClick((event: ClickEvent, result: SaveButtonOnClickResult, error?: BusinessError) => {
            this.handleClick('图标+文字', result, error)
          })

        // 5. 线条图标
        Text('5. 线条图标 (LINES + SAVE_IMAGE + Circle)')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        SaveButton({
          icon: SaveIconStyle.LINES,
          text: SaveDescription.SAVE_IMAGE,
          buttonType: ButtonType.Circle
        })
          .onClick((event: ClickEvent, result: SaveButtonOnClickResult, error?: BusinessError) => {
            this.handleClick('线条图标', result, error)
          })

        // 6. 不传 buttonType（默认 Capsule）
        Text('6. 不传 buttonType（默认 Capsule）')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        SaveButton({ icon: SaveIconStyle.FULL_FILLED, text: SaveDescription.SAVE_FILE })
          .onClick((event: ClickEvent, result: SaveButtonOnClickResult, error?: BusinessError) => {
            this.handleClick('默认ButtonType', result, error)
          })

        // API 说明区
        Column() {
          Text('API 说明')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 8 })
          Text('SaveButton() — 默认创建图标+文字+背景')
            .fontSize(12).fontColor('#666666').fontFamily('monospace').width('100%')
          Text('SaveButton({ icon?, text?, buttonType? })')
            .fontSize(12).fontColor('#666666').fontFamily('monospace').width('100%')
          Text('icon: SaveIconStyle.FULL_FILLED(填充) | LINES(线条)')
            .fontSize(12).fontColor('#666666').fontFamily('monospace').width('100%')
          Text('text: SaveDescription 枚举（DOWNLOAD/SAVE/SAVE_IMAGE...）')
            .fontSize(12).fontColor('#666666').fontFamily('monospace').width('100%')
          Text('buttonType: ButtonType.Capsule | Circle | Normal')
            .fontSize(12).fontColor('#666666').fontFamily('monospace').width('100%')
          Text('icon/text 至少传一个，否则使用默认样式')
            .fontSize(12).fontColor('#999999').fontFamily('monospace').width('100%')
          Text('icon、text、buttonType 不支持动态修改')
            .fontSize(12).fontColor('#999999').fontFamily('monospace').width('100%')
          Text('元服务API: 从 API version 11 开始支持')
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

  private handleClick(label: string, result: SaveButtonOnClickResult, error?: BusinessError): void {
    this.clickCount++
    if (result === SaveButtonOnClickResult.SUCCESS) {
      this.resultLog = `[${label}] 授权成功 (第${this.clickCount}次点击)`
    } else {
      this.resultLog = `[${label}] 授权失败: code=${error?.code}, msg=${error?.message}`
    }
  }
}
