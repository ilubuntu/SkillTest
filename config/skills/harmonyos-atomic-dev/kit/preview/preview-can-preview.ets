/**
 * preview-can-preview — 文件可预览判断场景
 * filePreview.canPreview(context, uri) 判断文件是否可预览
 * 元服务API: 从 API version 11 起支持
 */
import { filePreview } from '@kit.PreviewKit'
import { common } from '@kit.AbilityKit'
import { BusinessError } from '@kit.BasicServicesKit'

interface UriItem {
  label: string
  uri: string
}

@ComponentV2
export struct PreviewCanPreview {
  @Local resultText: string = '输入文件URI后检查是否可预览'
  @Local checkUri: string = ''
  @Local canPreviewResult: string = '--'
  @Local checkHistory: string = ''

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('文件可预览判断')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20, bottom: 10 })

        Text('filePreview.canPreview(context, uri)')
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
            .fontColor(this.resultText.includes('可预览') ? '#00B578' :
              (this.resultText.includes('不可预览') || this.resultText.includes('失败') ? '#E84026' : '#333333'))
            .width('100%')
          Row() {
            Text('检查结果: ')
              .fontSize(12)
              .fontColor('#999999')
            Text(this.canPreviewResult)
              .fontSize(12)
              .fontColor(this.canPreviewResult === '可预览' ? '#00B578' :
                (this.canPreviewResult === '不可预览' ? '#E84026' : '#999999'))
          }
          .width('100%')
        }
        .width('90%')
        .padding(16)
        .backgroundColor('#F5F5F5')
        .borderRadius(12)
        .alignItems(HorizontalAlign.Start)

        // 参数控制
        Text('文件URI')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        TextInput({ text: this.checkUri, placeholder: '输入文件URI (如 file://docs/...)' })
          .width('90%')
          .onChange((value: string) => {
            this.checkUri = value
          })

        // 快捷示例
        Text('快捷示例URI')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
          ForEach([
            { label: 'txt文件', uri: 'file://docs/storage/Users/currentUser/Documents/test.txt' } as UriItem,
            { label: 'png图片', uri: 'file://docs/storage/Users/currentUser/Documents/test.png' } as UriItem,
            { label: 'pdf文档', uri: 'file://docs/storage/Users/currentUser/Documents/test.pdf' } as UriItem,
            { label: 'mp4视频', uri: 'file://docs/storage/Users/currentUser/Documents/test.mp4' } as UriItem
          ], (item: UriItem) => {
            Button(item.label)
              .fontSize(12)
              .height(32)
              .backgroundColor('#E8E8E8')
              .fontColor('#333333')
              .borderRadius(6)
              .margin({ right: 8, bottom: 8 })
              .onClick(() => {
                this.checkUri = item.uri
              })
          })
        }
        .width('90%')

        // 操作按钮
        Row({ space: 12 }) {
          Button('检查可预览性')
            .layoutWeight(1)
            .backgroundColor('#007DFF')
            .borderRadius(8)
            .onClick(() => this.checkCanPreview())
          Button('检查沙箱文件')
            .layoutWeight(1)
            .backgroundColor('#00B578')
            .borderRadius(8)
            .onClick(() => this.checkSandboxFile())
        }
        .width('90%')

        // 历史记录
        if (this.checkHistory) {
          Text('检查历史')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .alignSelf(ItemAlign.Start)
            .margin({ left: 16, top: 8 })

          Text(this.checkHistory)
            .fontSize(12)
            .fontColor('#666666')
            .width('90%')
            .padding(12)
            .backgroundColor('#FAFAFA')
            .borderRadius(8)
            .maxLines(6)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }

        // API 说明
        Text('API 说明')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Column({ space: 4 }) {
          Text('filePreview.canPreview(context, uri)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('  .then((result: boolean) => { ... })')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('// result=true 可预览, result=false 不可预览')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('')
            .fontSize(8)
          Text('元服务API: 从 API 11 起支持')
            .fontSize(12)
            .fontColor('#00B578')
            .fontWeight(FontWeight.Medium)
          Text('注意: 仅检查文件是否存在 + 格式是否支持')
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
   * 检查指定URI是否可预览
   */
  private checkCanPreview(): void {
    if (!this.checkUri) {
      this.resultText = '请先输入文件URI'
      return
    }
    try {
      const context = this.getContext()
      this.resultText = '正在检查...'
      this.canPreviewResult = '检查中'

      filePreview.canPreview(context, this.checkUri).then((result: boolean) => {
        this.canPreviewResult = result ? '可预览' : '不可预览'
        this.resultText = result ? '该文件可以预览' : '该文件不可预览(文件不存在或格式不支持)'
        const time = new Date().toLocaleTimeString()
        this.checkHistory = `[${time}] ${this.checkUri}\n  → ${result ? '可预览' : '不可预览'}\n${this.checkHistory}`
      }).catch((err: BusinessError) => {
        this.canPreviewResult = '检查失败'
        this.resultText = `检查失败: [${err.code}] ${err.message}`
      })
    } catch (error) {
      const err = error as BusinessError
      this.resultText = `检查失败: [${err.code}] ${err.message}`
      this.canPreviewResult = '失败'
    }
  }

  /**
   * 检查应用沙箱内的文件
   */
  private checkSandboxFile(): void {
    try {
      const context = this.getContext()
      const filesDir = context.filesDir
      this.checkUri = `file://${filesDir}/preview-can-check.txt`
      this.resultText = '正在检查沙箱文件...'
      this.canPreviewResult = '检查中'

      filePreview.canPreview(context, this.checkUri).then((result: boolean) => {
        this.canPreviewResult = result ? '可预览' : '不可预览'
        this.resultText = result
          ? '沙箱文件可预览'
          : `沙箱文件不可预览 (路径: ${filesDir}/preview-can-check.txt)`
      }).catch((err: BusinessError) => {
        this.canPreviewResult = '检查失败'
        this.resultText = `检查失败: [${err.code}] ${err.message}`
      })
    } catch (error) {
      const err = error as BusinessError
      this.resultText = `检查失败: [${err.code}] ${err.message}`
      this.canPreviewResult = '失败'
    }
  }
}
