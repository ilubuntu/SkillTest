/**
 * camera-save-uri — 自定义保存路径拍照
 * 使用 PickerProfile.saveUri 将拍摄结果保存到应用沙箱指定路径
 * 元服务API: 从API version 12开始支持在元服务中使用
 */
import { cameraPicker } from '@kit.CameraKit'
import { camera } from '@kit.CameraKit'
import { common } from '@kit.AbilityKit'
import { fileIo, fileUri } from '@kit.CoreFileKit'
import { BusinessError } from '@kit.BasicServicesKit'

@ComponentV2
export struct CameraSaveUri {
  @Local resultText: string = '点击按钮启动相机（保存到沙箱）'
  @Local resultCode: string = '--'
  @Local resultUri: string = '--'
  @Local savedFileSize: string = '--'
  @Local cameraPos: camera.CameraPosition = camera.CameraPosition.CAMERA_POSITION_BACK
  @Local pickCount: number = 0

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('自定义保存路径拍照')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20, bottom: 10 })

        Text('通过 PickerProfile.saveUri 将照片保存到应用沙箱')
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
          Row() {
            Text('文件大小: ')
              .fontSize(12)
              .fontColor('#999999')
            Text(this.savedFileSize)
              .fontSize(12)
              .layoutWeight(1)
          }
          .width('100%')
          Row() {
            Text('累计拍摄: ')
              .fontSize(12)
              .fontColor('#999999')
            Text(`${this.pickCount} 次`)
              .fontSize(12)
          }
          .width('100%')
        }
        .width('90%')
        .padding(16)
        .backgroundColor('#F5F5F5')
        .borderRadius(12)
        .alignItems(HorizontalAlign.Start)

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

        // 操作按钮
        Button('拍照并保存到沙箱')
          .width('80%')
          .backgroundColor('#007DFF')
          .borderRadius(8)
          .onClick(() => this.doPickWithSaveUri())

        // saveUri 说明
        Column() {
          Text('saveUri 机制说明')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 4 })
          Text('1. saveUri 指向应用沙箱中已存在且可写的文件')
            .fontSize(12)
            .fontColor('#996600')
            .width('100%')
          Text('2. 系统相机获得该文件的读写权限，拍摄后覆盖写入')
            .fontSize(12)
            .fontColor('#996600')
            .width('100%')
          Text('3. saveUri 有写权限时，resultUri 与 saveUri 相同')
            .fontSize(12)
            .fontColor('#996600')
            .width('100%')
          Text('4. saveUri 无写权限时，无法获取 resultUri')
            .fontSize(12)
            .fontColor('#996600')
            .width('100%')
          Text('5. saveUri 为空时，resultUri 为公共媒体路径')
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
          Text('import { fileIo, fileUri } from "@kit.CoreFileKit"')
            .fontSize(12)
            .fontColor('#007DFF')
            .fontFamily('monospace')
          Text('fileIo.createRandomAccessFileSync(path, CREATE)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('fileUri.getUriFromPath(filePath) → uri')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('PickerProfile.saveUri = uri → 保存到沙箱')
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

  /**
   * 创建沙箱临时文件并获取 URI
   */
  private createSandboxFile(context: common.Context): string {
    let pathDir = context.filesDir
    let fileName = `camera_${new Date().getTime()}.tmp`
    let filePath = `${pathDir}/${fileName}`
    fileIo.createRandomAccessFileSync(filePath, fileIo.OpenMode.CREATE)
    return fileUri.getUriFromPath(filePath)
  }

  /**
   * 使用 saveUri 启动相机拍照
   */
  private doPickWithSaveUri(): void {
    try {
      let context = getContext(this) as common.Context
      let saveUri = this.createSandboxFile(context)

      let pickerProfile: cameraPicker.PickerProfile = {
        cameraPosition: this.cameraPos,
        saveUri: saveUri
      }

      this.resultText = '相机启动中...'

      cameraPicker.pick(context, [cameraPicker.PickerMediaType.PHOTO], pickerProfile)
        .then((result: cameraPicker.PickerResult) => {
          this.resultCode = result.resultCode === 0 ? '成功(0)' : '失败(-1)'
          this.resultUri = result.resultUri
          if (result.resultCode === 0) {
            this.pickCount++
            this.resultText = `拍摄成功，照片已保存到沙箱 (${this.pickCount}次)`
            this.checkFileSize(result.resultUri)
          } else {
            this.resultText = '拍摄失败或用户取消'
            this.savedFileSize = '--'
          }
        })
        .catch((error: BusinessError) => {
          this.resultText = `拍摄失败: [${error.code}] ${error.message}`
          this.savedFileSize = '--'
        })
    } catch (error) {
      const err = error as BusinessError
      this.resultText = `启动相机异常: [${err.code}] ${err.message}`
      this.savedFileSize = '--'
    }
  }

  /**
   * 检查保存文件大小
   */
  private checkFileSize(uri: string): void {
    try {
      let stat = fileIo.statSync(uri)
      this.savedFileSize = stat.size > 0 ? `${(stat.size / 1024).toFixed(1)} KB` : '0 KB'
    } catch (error) {
      this.savedFileSize = '无法读取'
    }
  }
}
