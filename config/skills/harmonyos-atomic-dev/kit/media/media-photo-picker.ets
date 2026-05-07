/**
 * media-photo-picker — 媒体库资源选择器
 * PhotoViewPicker.select() 选择图片/视频资源
 * 元服务API: 元服务可通过Picker安全访问媒体库，无需申请权限
 */
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { fileIo as fs } from '@kit.CoreFileKit'
import { common } from '@kit.AbilityKit'
import { BusinessError } from '@kit.BasicServicesKit'

@ComponentV2
export struct MediaPhotoPicker {
  @Local resultText: string = '点击按钮选择媒体资源'
  @Local selectedUris: string[] = []
  @Local maxSelect: number = 5
  @Local mimeType: string = 'IMAGE'
  @Local isSelecting: boolean = false

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('媒体库资源选择')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20, bottom: 10 })

        Text('PhotoViewPicker.select() 选择图片/视频')
          .fontSize(13)
          .fontColor('#666666')
          .width('90%')
          .textAlign(TextAlign.Center)

        // 结果展示
        Column({ space: 8 }) {
          Text('选择结果')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .width('100%')
          Text(this.resultText)
            .fontSize(13)
            .fontColor(this.resultText.includes('成功') ? '#00B578' :
              (this.resultText.includes('失败') || this.resultText.includes('错误') ? '#E84026' : '#333333'))
            .width('100%')
          Text(`已选择 ${this.selectedUris.length} 个资源`)
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
        }
        .width('90%')
        .padding(16)
        .backgroundColor('#F5F5F5')
        .borderRadius(12)
        .alignItems(HorizontalAlign.Start)

        // 已选资源列表
        if (this.selectedUris.length > 0) {
          Text('已选资源URI')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .alignSelf(ItemAlign.Start)
            .margin({ left: 16, top: 8 })

          ForEach(this.selectedUris, (uri: string, index: number) => {
            Text(uri)
              .fontSize(11)
              .fontColor('#333333')
              .width('90%')
              .padding(8)
              .backgroundColor('#F9F9F9')
              .borderRadius(6)
              .maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }, (uri: string, index: number) => `${index}_${uri}`)
        }

        // 参数控制
        Text('媒体类型')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Row({ space: 8 }) {
          Button('图片')
            .layoutWeight(1)
            .backgroundColor(this.mimeType === 'IMAGE' ? '#007DFF' : '#CCCCCC')
            .borderRadius(8)
            .onClick(() => { this.mimeType = 'IMAGE' })
          Button('视频')
            .layoutWeight(1)
            .backgroundColor(this.mimeType === 'VIDEO' ? '#007DFF' : '#CCCCCC')
            .borderRadius(8)
            .onClick(() => { this.mimeType = 'VIDEO' })
          Button('图片+视频')
            .layoutWeight(1)
            .backgroundColor(this.mimeType === 'IMAGE_VIDEO' ? '#007DFF' : '#CCCCCC')
            .borderRadius(8)
            .onClick(() => { this.mimeType = 'IMAGE_VIDEO' })
        }
        .width('90%')

        Text(`最大选择数量: ${this.maxSelect}`)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Row({ space: 8 }) {
          Button('1')
            .layoutWeight(1)
            .backgroundColor(this.maxSelect === 1 ? '#007DFF' : '#CCCCCC')
            .borderRadius(8)
            .onClick(() => { this.maxSelect = 1 })
          Button('3')
            .layoutWeight(1)
            .backgroundColor(this.maxSelect === 3 ? '#007DFF' : '#CCCCCC')
            .borderRadius(8)
            .onClick(() => { this.maxSelect = 3 })
          Button('5')
            .layoutWeight(1)
            .backgroundColor(this.maxSelect === 5 ? '#007DFF' : '#CCCCCC')
            .borderRadius(8)
            .onClick(() => { this.maxSelect = 5 })
          Button('9')
            .layoutWeight(1)
            .backgroundColor(this.maxSelect === 9 ? '#007DFF' : '#CCCCCC')
            .borderRadius(8)
            .onClick(() => { this.maxSelect = 9 })
        }
        .width('90%')

        // 操作按钮
        Row({ space: 12 }) {
          Button('选择媒体')
            .layoutWeight(1)
            .backgroundColor('#007DFF')
            .borderRadius(8)
            .enabled(!this.isSelecting)
            .onClick(() => this.doSelect())
          Button('清除结果')
            .layoutWeight(1)
            .backgroundColor('#FF9800')
            .borderRadius(8)
            .onClick(() => this.doClear())
        }
        .width('90%')

        // 提示信息
        Column() {
          Text('注意事项')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 4 })
          Text('1. 通过Picker选择资源无需申请任何权限')
            .fontSize(12)
            .fontColor('#996600')
            .width('100%')
          Text('2. 返回的URI仅具有只读权限，且仅在回调期间有效')
            .fontSize(12)
            .fontColor('#996600')
            .width('100%')
          Text('3. 需通过fs.openSync(uri)获取文件描述符后读取数据')
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
          Text('import photoAccessHelper from "@ohos.file.photoAccessHelper"')
            .fontSize(12)
            .fontColor('#007DFF')
            .fontFamily('monospace')
          Text('new photoAccessHelper.PhotoViewPicker()')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('.select(PhotoSelectOptions) → PhotoSelectResult')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('PhotoViewMIMETypes: IMAGE_TYPE / VIDEO_TYPE / IMAGE_VIDEO_TYPE')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('')
            .fontSize(8)
          Text('元服务API: 通过Picker安全访问，无需权限申请')
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

  private doSelect(): void {
    try {
      let context = getContext(this) as common.Context
      this.isSelecting = true
      this.resultText = '正在打开选择器...'

      let photoSelectOptions = new photoAccessHelper.PhotoSelectOptions()

      if (this.mimeType === 'IMAGE') {
        photoSelectOptions.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE
      } else if (this.mimeType === 'VIDEO') {
        photoSelectOptions.MIMEType = photoAccessHelper.PhotoViewMIMETypes.VIDEO_TYPE
      } else {
        photoSelectOptions.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_VIDEO_TYPE
      }

      photoSelectOptions.maxSelectNumber = this.maxSelect

      let photoViewPicker = new photoAccessHelper.PhotoViewPicker()
      photoViewPicker.select(photoSelectOptions).then((result: photoAccessHelper.PhotoSelectResult) => {
        this.isSelecting = false
        if (result.photoUris && result.photoUris.length > 0) {
          this.selectedUris = result.photoUris
          this.resultText = `选择成功，共 ${result.photoUris.length} 个文件`
        } else {
          this.resultText = '未选择任何资源'
        }
      }).catch((error: BusinessError) => {
        this.isSelecting = false
        this.resultText = `选择失败: [${error.code}] ${error.message}`
      })
    } catch (error) {
      this.isSelecting = false
      const err = error as BusinessError
      this.resultText = `选择异常: [${err.code}] ${err.message}`
    }
  }

  private doClear(): void {
    this.selectedUris = []
    this.resultText = '已清除，点击按钮选择媒体资源'
  }
}
