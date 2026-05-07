/**
 * preview-open-single — 单文件预览场景
 * filePreview.openPreview(context, file, displayInfo?) 单文件打开预览
 * 元服务API: 从 API version 11 起支持
 */
import { filePreview } from '@kit.PreviewKit'
import { common } from '@kit.AbilityKit'
import { BusinessError } from '@kit.BasicServicesKit'

@ComponentV2
export struct PreviewOpenSingle {
  @Local resultText: string = '选择文件后点击预览'
  @Local fileTitle: string = 'preview-test.txt'
  @Local fileUri: string = ''
  @Local mimeType: string = 'text/plain'
  @Local isPreviewOpen: boolean = false

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('单文件预览')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20, bottom: 10 })

        Text('filePreview.openPreview(context, PreviewInfo, DisplayInfo?)')
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
        Text('文件标题')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        TextInput({ text: this.fileTitle, placeholder: '输入文件标题' })
          .width('90%')
          .onChange((value: string) => {
            this.fileTitle = value
          })

        Text('文件URI')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        TextInput({ text: this.fileUri, placeholder: '输入文件URI (如 file://docs/...)' })
          .width('90%')
          .onChange((value: string) => {
            this.fileUri = value
          })

        Text('MIME类型')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        TextInput({ text: this.mimeType, placeholder: '如 text/plain, image/png' })
          .width('90%')
          .onChange((value: string) => {
            this.mimeType = value
          })

        // 操作按钮
        Row({ space: 12 }) {
          Button('创建文件并预览')
            .layoutWeight(1)
            .backgroundColor('#007DFF')
            .borderRadius(8)
            .onClick(() => this.createAndPreview())
          Button('检查预览状态')
            .layoutWeight(1)
            .backgroundColor('#00B578')
            .borderRadius(8)
            .onClick(() => this.checkPreviewStatus())
        }
        .width('90%')

        Row({ space: 12 }) {
          Button('关闭预览')
            .layoutWeight(1)
            .backgroundColor('#FF9800')
            .borderRadius(8)
            .onClick(() => this.closePreview())
        }
        .width('90%')

        // API 说明
        Text('API 说明')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Column({ space: 4 }) {
          Text('import { filePreview } from "@kit.PreviewKit"')
            .fontSize(12)
            .fontColor('#007DFF')
            .fontFamily('monospace')
          Text('// 构建预览信息')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('let info: filePreview.PreviewInfo = {')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('  title: "文件名", uri: "file://...",')
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
          Text('// 打开预览 (1秒内重复调用无效)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('filePreview.openPreview(context, info)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('')
            .fontSize(8)
          Text('元服务API: 从 API 11 起支持')
            .fontSize(12)
            .fontColor('#00B578')
            .fontWeight(FontWeight.Medium)
          Text('注意: 预览窗口为单例，1秒内重复调用无效')
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
   * 创建临时文件并打开预览
   */
  private createAndPreview(): void {
    try {
      const context = this.getContext()
      // 使用应用沙箱内的文件路径
      const filesDir = context.filesDir
      this.fileUri = `file://${filesDir}/${this.fileTitle}`
      this.resultText = `准备预览: ${this.fileUri}`

      const fileInfo: filePreview.PreviewInfo = {
        title: this.fileTitle,
        uri: this.fileUri,
        mimeType: this.mimeType
      }

      filePreview.openPreview(context, fileInfo).then(() => {
        this.resultText = '预览成功打开'
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
   * 检查预览窗口状态
   */
  private checkPreviewStatus(): void {
    try {
      const context = this.getContext()
      filePreview.hasDisplayed(context).then((result: boolean) => {
        this.isPreviewOpen = result
        this.resultText = result ? '预览窗口已存在' : '预览窗口不存在'
      }).catch((err: BusinessError) => {
        this.resultText = `查询失败: [${err.code}] ${err.message}`
      })
    } catch (error) {
      const err = error as BusinessError
      this.resultText = `查询失败: [${err.code}] ${err.message}`
    }
  }

  /**
   * 关闭预览窗口
   */
  private closePreview(): void {
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
