/**
 * avsession-cast-picker — 投播设备选择场景
 * AVCastPickerHelper / AVCastPicker 组件
 * 元服务API: API 14+ 支持投播设备选择
 */
import { avSession } from '@kit.AVSessionKit'
import { BusinessError } from '@kit.BasicServicesKit'

@ComponentV2
export struct AvsessionCastPicker {
  @Local resultText: string = '点击按钮拉起投播设备选择'
  @Local castState: string = '未连接'
  @Local deviceName: string = '--'
  @Local isCasting: boolean = false
  @Local sessionType: string = 'audio'

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('投播设备选择')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20, bottom: 10 })

        Text('AVCastPickerHelper / AVCastPicker — 拉起投播设备选择')
          .fontSize(13)
          .fontColor('#666666')
          .width('90%')
          .textAlign(TextAlign.Center)

        // 结果展示
        Column({ space: 8 }) {
          Text('投播状态')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .width('100%')
          Text(this.resultText)
            .fontSize(13)
            .fontColor(this.castState === '已连接' ? '#00B578' :
              (this.castState === '连接失败' ? '#E84026' : '#333333'))
            .width('100%')
          Row() {
            Text('状态: ')
              .fontSize(12)
              .fontColor('#999999')
            Text(this.castState)
              .fontSize(12)
              .fontWeight(FontWeight.Medium)
          }
          .width('100%')
          Row() {
            Text('设备: ')
              .fontSize(12)
              .fontColor('#999999')
            Text(this.deviceName)
              .fontSize(12)
          }
          .width('100%')
        }
        .width('90%')
        .padding(16)
        .backgroundColor('#F5F5F5')
        .borderRadius(12)
        .alignItems(HorizontalAlign.Start)

        // 操作按钮
        Button('选择投播设备')
          .width('90%')
          .backgroundColor('#007DFF')
          .borderRadius(8)
          .onClick(() => this.startCastPicker())

        Button('停止投播')
          .width('90%')
          .backgroundColor('#FF9800')
          .borderRadius(8)
          .enabled(this.isCasting)
          .onClick(() => this.stopCast())

        // 提示信息
        Column({ space: 4 }) {
          Text('注意事项')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 4 })
          Text('1. 元服务 API 14+ 支持 AVCastPickerHelper')
            .fontSize(12)
            .fontColor('#996600')
            .width('100%')
          Text('2. 投播需要设备在同一网络下')
            .fontSize(12)
            .fontColor('#996600')
            .width('100%')
          Text('3. 导入: import { avSession } from "@kit.AVSessionKit"')
            .fontSize(12)
            .fontColor('#996600')
            .width('100%')
        }
        .width('90%')
        .backgroundColor('#FFF3CD')
        .borderRadius(8)
        .padding(12)

        // API 说明
        Text('API 说明')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Column({ space: 4 }) {
          Text('// 创建投播选择器')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('let picker = new avSession.AVCastPickerHelper(context)')
            .fontSize(12)
            .fontColor('#007DFF')
            .fontFamily('monospace')
          Text('// 拉起半模态设备选择')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('picker.select((err, device) => { ... })')
            .fontSize(12)
            .fontColor('#007DFF')
            .fontFamily('monospace')
          Text('')
            .fontSize(8)
          Text('元服务API: API 14+ 支持 AVCastPickerHelper')
            .fontSize(12)
            .fontColor('#00B578')
            .fontWeight(FontWeight.Medium)
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

  private async startCastPicker(): Promise<void> {
    try {
      this.resultText = '正在拉起设备选择...'
      const context = getContext(this) as Context
      const picker = new avSession.AVCastPickerHelper(context)
      const options: avSession.AVCastPickerOptions = {
        sessionType: this.sessionType as avSession.AVSessionType,
      }
      await picker.select(options)
      this.isCasting = true
      this.castState = '已选择设备'
      this.resultText = '投播设备选择成功'
    } catch (error) {
      const err = error as BusinessError
      this.resultText = `选择失败: [${err.code}] ${err.message}`
      this.castState = '连接失败'
    }
  }

  private stopCast(): void {
    this.isCasting = false
    this.castState = '未连接'
    this.deviceName = '--'
    this.resultText = '投播已停止'
  }
}
