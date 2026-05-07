/**
 * preview-open-multi — 多文件预览场景
 * filePreview.openPreview(context, files: Array<PreviewInfo>, index?)
 * 元服务API: 从 API version 12 起支持 (多文件重载)
 */
import { filePreview } from '@kit.PreviewKit'
import { common } from '@kit.AbilityKit'
import { BusinessError } from '@kit.BasicServicesKit'

interface FileTypeInfo {
  ext: string
  mime: string
}

@ComponentV2
export struct PreviewOpenMulti {
  @Local resultText: string = '点击按钮预览多个文件'
  @Local fileCount: number = 3
  @Local selectedIndex: number = 0
  @Local isPreviewOpen: boolean = false

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('多文件预览')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20, bottom: 10 })

        Text('filePreview.openPreview(context, files: Array<PreviewInfo>, index?)')
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
        }
        .width('90%')
        .padding(16)
        .backgroundColor('#F5F5F5')
        .borderRadius(12)
        .alignItems(HorizontalAlign.Start)

        // 参数控制
        Text('预览文件数量')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Row({ space: 12 }) {
          Button('-')
            .width(44)
            .height(44)
            .backgroundColor('#FF9800')
            .borderRadius(8)
            .onClick(() => {
              if (this.fileCount > 1) {
                this.fileCount--
                if (this.selectedIndex >= this.fileCount) {
                  this.selectedIndex = this.fileCount - 1
                }
              }
            })
          Text(`${this.fileCount}`)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .width(40)
            .textAlign(TextAlign.Center)
          Button('+')
            .width(44)
            .height(44)
            .backgroundColor('#007DFF')
            .borderRadius(8)
            .onClick(() => {
              if (this.fileCount < 10) {
                this.fileCount++
              }
            })
        }
        .width('90%')
        .justifyContent(FlexAlign.Center)

        Text(`初始展示文件下标 (0-${this.fileCount - 1})`)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Slider({
          value: this.selectedIndex,
          min: 0,
          max: this.fileCount - 1,
          step: 1
        })
          .width('90%')
          .showTips(true)
          .onChange((value: number) => {
            this.selectedIndex = Math.round(value)
          })

        // 操作按钮
        Row({ space: 12 }) {
          Button('预览多文件')
            .layoutWeight(1)
            .backgroundColor('#007DFF')
            .borderRadius(8)
            .onClick(() => this.openMultiPreview())
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
          Text('// 多文件预览 (不支持2in1设备)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('let files: Array<filePreview.PreviewInfo> = [')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('  { title: "1.txt", uri: "...", mimeType: "text/plain" },')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('  { title: "2.png", uri: "...", mimeType: "image/png" }')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text(']')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('filePreview.openPreview(context, files, index)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('')
            .fontSize(8)
          Text('元服务API: 从 API 12 起支持 (多文件重载)')
            .fontSize(12)
            .fontColor('#00B578')
            .fontWeight(FontWeight.Medium)
          Text('注意: 不支持2in1设备; 1秒内重复调用无效')
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
   * 打开多文件预览
   */
  private openMultiPreview(): void {
    try {
      const context = this.getContext()
      const filesDir = context.filesDir
      const types: Array<FileTypeInfo> = [
        { ext: 'txt', mime: 'text/plain' } as FileTypeInfo,
        { ext: 'html', mime: 'text/html' } as FileTypeInfo,
        { ext: 'jpg', mime: 'image/jpeg' } as FileTypeInfo,
        { ext: 'png', mime: 'image/png' } as FileTypeInfo,
        { ext: 'mp4', mime: 'video/mp4' } as FileTypeInfo,
        { ext: 'pdf', mime: 'application/pdf' } as FileTypeInfo,
        { ext: 'xml', mime: 'text/xml' } as FileTypeInfo,
        { ext: 'gif', mime: 'image/gif' } as FileTypeInfo,
        { ext: 'mp3', mime: 'audio/mpeg' } as FileTypeInfo,
        { ext: 'svg', mime: 'image/svg+xml' } as FileTypeInfo
      ]
      const files: Array<filePreview.PreviewInfo> = []
      for (let i = 0; i < this.fileCount; i++) {
        const t = types[i % types.length]
        files.push({
          title: `preview-${i + 1}.${t.ext}`,
          uri: `file://${filesDir}/preview-${i + 1}.${t.ext}`,
          mimeType: t.mime
        })
      }
      this.resultText = `准备预览 ${files.length} 个文件，初始下标 ${this.selectedIndex}`

      filePreview.openPreview(context, files, this.selectedIndex).then(() => {
        this.resultText = `成功打开 ${files.length} 个文件预览`
        this.isPreviewOpen = true
      }).catch((err: BusinessError) => {
        this.resultText = `预览失败: [${err.code}] ${err.message}`
        this.isPreviewOpen = false
      })
    } catch (error) {
      const err = error as BusinessError
      this.resultText = `操作失败: [${err.code}] ${err.message}`
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
