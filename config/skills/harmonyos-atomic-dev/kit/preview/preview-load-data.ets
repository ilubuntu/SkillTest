/**
 * preview-load-data — 预览窗口文件切换场景
 * filePreview.loadData(context, file) 在已有预览窗口中加载新文件
 * 元服务API: 从 API version 11 起支持
 */
import { filePreview } from '@kit.PreviewKit'
import { common } from '@kit.AbilityKit'
import { BusinessError } from '@kit.BasicServicesKit'

interface FileTypeItem {
  ext: string
  mime: string
  label: string
}

@ComponentV2
export struct PreviewLoadData {
  @Local resultText: string = '先打开预览，再切换文件'
  @Local currentFileIndex: number = 0
  @Local isPreviewOpen: boolean = false
  @Local loadCount: number = 0

  private fileTypes: Array<FileTypeItem> = [
    { ext: 'txt', mime: 'text/plain', label: '文本文件' } as FileTypeItem,
    { ext: 'html', mime: 'text/html', label: '网页文件' } as FileTypeItem,
    { ext: 'jpg', mime: 'image/jpeg', label: 'JPEG图片' } as FileTypeItem,
    { ext: 'png', mime: 'image/png', label: 'PNG图片' } as FileTypeItem,
    { ext: 'mp4', mime: 'video/mp4', label: 'MP4视频' } as FileTypeItem,
    { ext: 'pdf', mime: 'application/pdf', label: 'PDF文档' } as FileTypeItem
  ]

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('预览窗口文件切换')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20, bottom: 10 })

        Text('filePreview.loadData(context, PreviewInfo) 在已有窗口中切换文件')
          .fontSize(13)
          .fontColor('#666666')
          .width('90%')
          .textAlign(TextAlign.Center)

        // 结果展示
        Column({ space: 8 }) {
          Text('执行结果')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .width('100%')
          Text(this.resultText)
            .fontSize(13)
            .fontColor(this.resultText.includes('成功') ? '#00B578' :
              (this.resultText.includes('失败') || this.resultText.includes('错误') ? '#E84026' : '#333333'))
            .width('100%')
          Row() {
            Text('预览状态: ')
              .fontSize(12)
              .fontColor('#999999')
            Text(this.isPreviewOpen ? '已打开' : '未打开')
              .fontSize(12)
              .fontColor(this.isPreviewOpen ? '#00B578' : '#999999')
          }
          .width('100%')
          Row() {
            Text('切换次数: ')
              .fontSize(12)
              .fontColor('#999999')
            Text(`${this.loadCount}`)
              .fontSize(12)
          }
          .width('100%')
        }
        .width('90%')
        .padding(16)
        .backgroundColor('#F5F5F5')
        .borderRadius(12)
        .alignItems(HorizontalAlign.Start)

        // 文件类型选择
        Text('选择要加载的文件类型')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
          ForEach(this.fileTypes, (item: FileTypeItem, index?: number) => {
            Button(item.label)
              .fontSize(13)
              .height(36)
              .backgroundColor(index === this.currentFileIndex ? '#007DFF' : '#E8E8E8')
              .fontColor(index === this.currentFileIndex ? '#FFFFFF' : '#333333')
              .borderRadius(6)
              .margin({ right: 8, bottom: 8 })
              .onClick(() => {
                if (index !== undefined) {
                  this.currentFileIndex = index
                }
              })
          })
        }
        .width('90%')

        // 操作按钮
        Row({ space: 12 }) {
          Button('打开初始预览')
            .layoutWeight(1)
            .backgroundColor('#007DFF')
            .borderRadius(8)
            .onClick(() => this.openInitialPreview())
        }
        .width('90%')

        Row({ space: 12 }) {
          Button('加载选中文件')
            .layoutWeight(1)
            .backgroundColor('#00B578')
            .borderRadius(8)
            .onClick(() => this.loadSelectedFile())
          Button('关闭预览')
            .layoutWeight(1)
            .backgroundColor('#FF9800')
            .borderRadius(8)
            .onClick(() => this.doClose())
        }
        .width('90%')

        // API 说明
        Text('API 说明')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Column({ space: 4 }) {
          Text('// loadData 仅在预览窗口已打开时有效')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('// 100ms内重复调用无效')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('let fileInfo: filePreview.PreviewInfo = {')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('  title: "new-file.txt",')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('  uri: "file://...",')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('  mimeType: "text/plain"')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('}')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('filePreview.loadData(context, fileInfo)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('')
            .fontSize(8)
          Text('元服务API: 从 API 11 起支持')
            .fontSize(12)
            .fontColor('#00B578')
            .fontWeight(FontWeight.Medium)
          Text('注意: 需先通过openPreview打开窗口, 100ms内重复调用无效')
            .fontSize(12)
            .fontColor('#FF9800')
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

  private getContext(): common.Context {
    return getContext(this) as common.Context
  }

  /**
   * 打开初始预览窗口
   */
  private openInitialPreview(): void {
    try {
      const context = this.getContext()
      const filesDir = context.filesDir
      const currentType = this.fileTypes[this.currentFileIndex]
      const fileInfo: filePreview.PreviewInfo = {
        title: `preview-initial.${currentType.ext}`,
        uri: `file://${filesDir}/preview-initial.${currentType.ext}`,
        mimeType: currentType.mime
      }
      this.resultText = '正在打开预览...'

      filePreview.openPreview(context, fileInfo).then(() => {
        this.resultText = '预览窗口已打开'
        this.isPreviewOpen = true
        this.loadCount = 0
      }).catch((err: BusinessError) => {
        this.resultText = `打开失败: [${err.code}] ${err.message}`
      })
    } catch (error) {
      const err = error as BusinessError
      this.resultText = `操作失败: [${err.code}] ${err.message}`
    }
  }

  /**
   * 在已有预览窗口中加载新文件
   */
  private loadSelectedFile(): void {
    if (!this.isPreviewOpen) {
      this.resultText = '请先打开预览窗口'
      return
    }
    try {
      const context = this.getContext()
      const filesDir = context.filesDir
      const selectedType = this.fileTypes[this.currentFileIndex]
      const fileInfo: filePreview.PreviewInfo = {
        title: `preview-switch.${selectedType.ext}`,
        uri: `file://${filesDir}/preview-switch.${selectedType.ext}`,
        mimeType: selectedType.mime
      }
      this.resultText = '正在切换文件...'

      filePreview.loadData(context, fileInfo).then(() => {
        this.loadCount++
        this.resultText = `成功切换到: ${selectedType.label} (${selectedType.ext})`
      }).catch((err: BusinessError) => {
        this.resultText = `切换失败: [${err.code}] ${err.message}`
      })
    } catch (error) {
      const err = error as BusinessError
      this.resultText = `切换失败: [${err.code}] ${err.message}`
    }
  }

  /**
   * 关闭预览
   */
  private doClose(): void {
    try {
      const context = this.getContext()
      filePreview.closePreview(context).then(() => {
        this.resultText = '预览窗口已关闭'
        this.isPreviewOpen = false
      }).catch((err: BusinessError) => {
        this.resultText = `关闭失败: [${err.code}] ${err.message}`
      })
    } catch (error) {
      const err = error as BusinessError
      this.resultText = `关闭失败: [${err.code}] ${err.message}`
    }
  }
}
