/**
 * camera-picker — 相机选择器拍照/录制
 * cameraPicker.pick() 拉起系统相机进行拍照或视频录制
 * 元服务API: 从API version 12开始支持在元服务中使用
 */
import { cameraPicker } from '@kit.CameraKit'
import { camera } from '@kit.CameraKit'
import { common } from '@kit.AbilityKit'
import { BusinessError } from '@kit.BasicServicesKit'

@ComponentV2
export struct CameraPicker {
  @Local resultText: string = '点击按钮启动相机'
  @Local resultCode: string = '--'
  @Local resultUri: string = '--'
  @Local resultMediaType: string = '--'
  @Local selectedMode: string = 'PHOTO'
  @Local cameraPos: camera.CameraPosition = camera.CameraPosition.CAMERA_POSITION_BACK
  @Local videoDurationLimit: number = 0

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('相机选择器 (Camera Kit)')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20, bottom: 10 })

        Text('cameraPicker.pick() 拉起系统相机拍照/录制')
          .fontSize(13)
          .fontColor('#666666')
          .width('90%')
          .textAlign(TextAlign.Center)

        // 结果展示
        Column({ space: 8 }) {
          Text('拍摄结果')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .width('100%')
          Text(this.resultText)
            .fontSize(13)
            .fontColor(this.resultText.includes('成功') ? '#00B578' :
              (this.resultText.includes('失败') || this.resultText.includes('错误') ? '#E84026' : '#333333'))
            .width('100%')
          Row() {
            Text('结果码: ')
              .fontSize(12)
              .fontColor('#999999')
            Text(this.resultCode)
              .fontSize(12)
              .layoutWeight(1)
          }
          .width('100%')
          Row() {
            Text('媒体类型: ')
              .fontSize(12)
              .fontColor('#999999')
            Text(this.resultMediaType)
              .fontSize(12)
              .layoutWeight(1)
          }
          .width('100%')
          Row() {
            Text('文件URI: ')
              .fontSize(12)
              .fontColor('#999999')
            Text(this.resultUri)
              .fontSize(12)
              .layoutWeight(1)
              .maxLines(3)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .width('100%')
        }
        .width('90%')
        .padding(16)
        .backgroundColor('#F5F5F5')
        .borderRadius(12)
        .alignItems(HorizontalAlign.Start)

        // 参数控制 - 拍照模式
        Text('拍摄模式')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Row({ space: 8 }) {
          Button('拍照')
            .layoutWeight(1)
            .backgroundColor(this.selectedMode === 'PHOTO' ? '#007DFF' : '#CCCCCC')
            .borderRadius(8)
            .onClick(() => { this.selectedMode = 'PHOTO' })
          Button('录制')
            .layoutWeight(1)
            .backgroundColor(this.selectedMode === 'VIDEO' ? '#007DFF' : '#CCCCCC')
            .borderRadius(8)
            .onClick(() => { this.selectedMode = 'VIDEO' })
          Button('拍照+录制')
            .layoutWeight(1)
            .backgroundColor(this.selectedMode === 'BOTH' ? '#007DFF' : '#CCCCCC')
            .borderRadius(8)
            .onClick(() => { this.selectedMode = 'BOTH' })
        }
        .width('90%')

        // 相机位置
        Text('相机位置')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Row({ space: 8 }) {
          Button('后置')
            .layoutWeight(1)
            .backgroundColor(this.cameraPos === camera.CameraPosition.CAMERA_POSITION_BACK ? '#007DFF' : '#CCCCCC')
            .borderRadius(8)
            .onClick(() => { this.cameraPos = camera.CameraPosition.CAMERA_POSITION_BACK })
          Button('前置')
            .layoutWeight(1)
            .backgroundColor(this.cameraPos === camera.CameraPosition.CAMERA_POSITION_FRONT ? '#007DFF' : '#CCCCCC')
            .borderRadius(8)
            .onClick(() => { this.cameraPos = camera.CameraPosition.CAMERA_POSITION_FRONT })
        }
        .width('90%')

        // 录制时长限制
        Text('录制时长限制（秒，0为不限）')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Row({ space: 8 }) {
          Button('不限')
            .layoutWeight(1)
            .backgroundColor(this.videoDurationLimit === 0 ? '#007DFF' : '#CCCCCC')
            .borderRadius(8)
            .onClick(() => { this.videoDurationLimit = 0 })
          Button('10秒')
            .layoutWeight(1)
            .backgroundColor(this.videoDurationLimit === 10 ? '#007DFF' : '#CCCCCC')
            .borderRadius(8)
            .onClick(() => { this.videoDurationLimit = 10 })
          Button('30秒')
            .layoutWeight(1)
            .backgroundColor(this.videoDurationLimit === 30 ? '#007DFF' : '#CCCCCC')
            .borderRadius(8)
            .onClick(() => { this.videoDurationLimit = 30 })
        }
        .width('90%')

        // 操作按钮
        Button('启动相机')
          .width('80%')
          .backgroundColor('#007DFF')
          .borderRadius(8)
          .onClick(() => this.doPick())

        // 提示信息
        Column() {
          Text('注意事项')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 4 })
          Text('1. 必须在UIAbility界面中调用，否则无法启动')
            .fontSize(12)
            .fontColor('#996600')
            .width('100%')
          Text('2. 折叠设备展开态切换到折叠态时，picker被推至后台')
            .fontSize(12)
            .fontColor('#996600')
            .width('100%')
          Text('3. saveUri为空时，resultUri为公共媒体路径')
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
          Text('import { cameraPicker } from "@kit.CameraKit"')
            .fontSize(12)
            .fontColor('#007DFF')
            .fontFamily('monospace')
          Text('import { camera } from "@kit.CameraKit"')
            .fontSize(12)
            .fontColor('#007DFF')
            .fontFamily('monospace')
          Text('cameraPicker.pick(context, mediaTypes, profile)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('PickerMediaType: PHOTO | VIDEO')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('PickerProfile: cameraPosition / saveUri / videoDuration')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('')
            .fontSize(8)
          Text('元服务API: 从API version 12开始支持在元服务中使用')
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

  private doPick(): void {
    try {
      const context = this.getUIContext().getHostContext();
      if (!context) {
        return;
      }
      let mediaTypes: Array<cameraPicker.PickerMediaType> = []

      if (this.selectedMode === 'PHOTO') {
        mediaTypes = [cameraPicker.PickerMediaType.PHOTO]
      } else if (this.selectedMode === 'VIDEO') {
        mediaTypes = [cameraPicker.PickerMediaType.VIDEO]
      } else {
        mediaTypes = [cameraPicker.PickerMediaType.PHOTO, cameraPicker.PickerMediaType.VIDEO]
      }

      let pickerProfile: cameraPicker.PickerProfile = {
        cameraPosition: this.cameraPos,
        videoDuration: this.videoDurationLimit
      }

      this.resultText = '相机启动中...'

      cameraPicker.pick(context, mediaTypes, pickerProfile).then((result: cameraPicker.PickerResult) => {
        this.resultCode = result.resultCode === 0 ? '成功(0)' : '失败(-1)'
        this.resultUri = result.resultUri
        this.resultMediaType = result.mediaType
        if (result.resultCode === 0) {
          this.resultText = `拍摄成功，${result.mediaType === 'photo' ? '照片' : '视频'}已保存`
        } else {
          this.resultText = '拍摄失败或用户取消'
        }
      }).catch((error: BusinessError) => {
        this.resultText = `拍摄失败: [${error.code}] ${error.message}`
      })
    } catch (error) {
      const err = error as BusinessError
      this.resultText = `启动相机异常: [${err.code}] ${err.message}`
    }
  }
}
