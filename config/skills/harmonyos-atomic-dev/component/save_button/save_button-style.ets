/**
 * save_button-style — SaveButton 安全控件通用属性样式
 * 展示通过继承安全控件通用属性设置字体、背景、图标颜色等
 * 元服务兼容性：安全控件通用属性从 API version 11 开始支持
 */
import { BusinessError } from '@kit.BasicServicesKit'

@ComponentV2
export struct SaveButtonStyle {
  @Local resultLog: string = '点击保存控件查看样式效果'
  @Local currentFontSize: number = 16
  @Local currentFontColor: string = '#FFFFFF'

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('SaveButton 样式定制')
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

        // 参数控制区 — 字体大小
        Row({ space: 12 }) {
          Text('字体大小:')
            .fontSize(14)
            .fontColor('#666666')
          Button('12fp')
            .fontSize(12).height(32)
            .onClick(() => { this.currentFontSize = 12 })
          Button('16fp')
            .fontSize(12).height(32)
            .onClick(() => { this.currentFontSize = 16 })
          Button('20fp')
            .fontSize(12).height(32)
            .onClick(() => { this.currentFontSize = 20 })
        }
        .width('90%')

        // 字体大小控制
        Text('字体大小控制')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        SaveButton({ icon: SaveIconStyle.FULL_FILLED, text: SaveDescription.SAVE, buttonType: ButtonType.Capsule })
          .fontSize(this.currentFontSize)
          .onClick((event: ClickEvent, result: SaveButtonOnClickResult, error?: BusinessError) => {
            this.handleResult('fontSize=' + this.currentFontSize, result, error)
          })

        // 背景色控制
        Text('背景色设置')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Row({ space: 8 }) {
          SaveButton({ icon: SaveIconStyle.FULL_FILLED, text: SaveDescription.SAVE })
            .backgroundColor('#007DFF')
            .onClick((event: ClickEvent, result: SaveButtonOnClickResult, error?: BusinessError) => {
              this.handleResult('蓝色背景', result, error)
            })

          SaveButton({ icon: SaveIconStyle.FULL_FILLED, text: SaveDescription.SAVE })
            .backgroundColor('#FF6B00')
            .onClick((event: ClickEvent, result: SaveButtonOnClickResult, error?: BusinessError) => {
              this.handleResult('橙色背景', result, error)
            })

          SaveButton({ icon: SaveIconStyle.FULL_FILLED, text: SaveDescription.SAVE })
            .backgroundColor(Color.Green)
            .onClick((event: ClickEvent, result: SaveButtonOnClickResult, error?: BusinessError) => {
              this.handleResult('绿色背景', result, error)
            })
        }

        // 圆角控制
        Text('圆角设置')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Row({ space: 8 }) {
          SaveButton({ icon: SaveIconStyle.FULL_FILLED, text: SaveDescription.DOWNLOAD, buttonType: ButtonType.Capsule })
            .borderRadius(4)
            .onClick((event: ClickEvent, result: SaveButtonOnClickResult, error?: BusinessError) => {
              this.handleResult('borderRadius=4', result, error)
            })

          SaveButton({ icon: SaveIconStyle.FULL_FILLED, text: SaveDescription.DOWNLOAD, buttonType: ButtonType.Capsule })
            .borderRadius(20)
            .onClick((event: ClickEvent, result: SaveButtonOnClickResult, error?: BusinessError) => {
              this.handleResult('borderRadius=20', result, error)
            })
        }

        // 尺寸约束
        Text('尺寸约束 (constraintSize)')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        SaveButton({ icon: SaveIconStyle.FULL_FILLED, text: SaveDescription.SAVE })
          .fontSize(16)
          .constraintSize({ minWidth: 0, maxWidth: 100, minHeight: 0, maxHeight: 40 })
          .onClick((event: ClickEvent, result: SaveButtonOnClickResult, error?: BusinessError) => {
            this.handleResult('constraintSize限制', result, error)
          })

        // 字体样式
        Text('字体粗细')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Row({ space: 8 }) {
          SaveButton({ icon: SaveIconStyle.FULL_FILLED, text: SaveDescription.SAVE })
            .fontWeight(FontWeight.Normal)
            .onClick((event: ClickEvent, result: SaveButtonOnClickResult, error?: BusinessError) => {
              this.handleResult('Normal粗细', result, error)
            })

          SaveButton({ icon: SaveIconStyle.FULL_FILLED, text: SaveDescription.SAVE })
            .fontWeight(FontWeight.Bold)
            .onClick((event: ClickEvent, result: SaveButtonOnClickResult, error?: BusinessError) => {
              this.handleResult('Bold粗细', result, error)
            })
        }

        // 图标颜色
        Text('图标颜色 (iconColor)')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Row({ space: 8 }) {
          SaveButton({ icon: SaveIconStyle.FULL_FILLED, text: SaveDescription.SAVE })
            .iconColor('#FFFFFF')
            .onClick((event: ClickEvent, result: SaveButtonOnClickResult, error?: BusinessError) => {
              this.handleResult('白色图标', result, error)
            })

          SaveButton({ icon: SaveIconStyle.FULL_FILLED, text: SaveDescription.SAVE })
            .backgroundColor('#007DFF')
            .iconColor('#FFD700')
            .onClick((event: ClickEvent, result: SaveButtonOnClickResult, error?: BusinessError) => {
              this.handleResult('金色图标', result, error)
            })
        }

        // API 说明区
        Column() {
          Text('API 说明')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 8 })
          Text('SaveButton 不支持通用属性，仅继承安全控件通用属性:')
            .fontSize(12).fontColor('#666666').width('100%')
          Text('.fontSize(n) .fontColor(color) .fontWeight(w) .fontStyle(s)')
            .fontSize(12).fontColor('#666666').fontFamily('monospace').width('100%')
          Text('.backgroundColor(color) .borderRadius(r) .iconColor(color)')
            .fontSize(12).fontColor('#666666').fontFamily('monospace').width('100%')
          Text('.width(n) .height(n) .size({w,h}) .constraintSize({...})')
            .fontSize(12).fontColor('#666666').fontFamily('monospace').width('100%')
          Text('.padding(n) .margin(n) .enabled(bool)')
            .fontSize(12).fontColor('#666666').fontFamily('monospace').width('100%')
          Text('注意: 背景色alpha低于0x1a会被系统强制调整为0xff')
            .fontSize(12).fontColor('#FF6B00').width('100%')
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

  private handleResult(label: string, result: SaveButtonOnClickResult, error?: BusinessError): void {
    if (result === SaveButtonOnClickResult.SUCCESS) {
      this.resultLog = `[${label}] 授权成功`
    } else {
      this.resultLog = `[${label}] 授权失败: code=${error?.code}, msg=${error?.message}`
    }
  }
}
