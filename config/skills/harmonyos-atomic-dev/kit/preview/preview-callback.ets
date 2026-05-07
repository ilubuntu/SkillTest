/**
 * preview-callback — Callback方式调用场景
 * filePreview.openPreview / canPreview / hasDisplayed / closePreview / loadData 的 Callback 重载
 * 元服务API: 从 API version 11 起支持
 */
import { filePreview } from '@kit.PreviewKit'
import { common } from '@kit.AbilityKit'
import { BusinessError } from '@kit.BasicServicesKit'

@ComponentV2
export struct PreviewCallback {
  @Local resultText: string = '使用Callback方式调用预览API'
  @Local operationLog: string = ''
  @Local isPreviewOpen: boolean = false

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('Callback方式调用')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20, bottom: 10 })

        Text('openPreview / canPreview / hasDisplayed / closePreview 的 Callback 重载')
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
        }
        .width('90%')
        .padding(16)
        .backgroundColor('#F5F5F5')
        .borderRadius(12)
        .alignItems(HorizontalAlign.Start)

        // 操作按钮
        Text('Callback API 操作')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Row({ space: 12 }) {
          Button('Callback打开预览')
            .layoutWeight(1)
            .backgroundColor('#007DFF')
            .borderRadius(8)
            .onClick(() => this.callbackOpenPreview())
          Button('Callback检查可预览')
            .layoutWeight(1)
            .backgroundColor('#00B578')
            .borderRadius(8)
            .onClick(() => this.callbackCanPreview())
        }
        .width('90%')

        Row({ space: 12 }) {
          Button('Callback查询窗口')
            .layoutWeight(1)
            .backgroundColor('#9C27B0')
            .borderRadius(8)
            .onClick(() => this.callbackHasDisplayed())
          Button('Callback关闭预览')
            .layoutWeight(1)
            .backgroundColor('#FF9800')
            .borderRadius(8)
            .onClick(() => this.callbackClosePreview())
        }
        .width('90%')

        // 操作日志
        Text('操作日志')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Text(this.operationLog || '暂无日志')
          .fontSize(12)
          .fontColor('#666666')
          .width('90%')
          .padding(12)
          .backgroundColor('#FAFAFA')
          .borderRadius(8)
          .maxLines(10)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        // API 说明
        Text('API 说明')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Column({ space: 4 }) {
          Text('// Callback 重载形式')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('filePreview.openPreview(ctx, info, displayInfo,')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('  (err) => { if(err) handleError() })')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('filePreview.canPreview(ctx, uri,')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('  (err, result) => { ... })')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('filePreview.hasDisplayed(ctx,')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('  (err, result) => { ... })')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('')
            .fontSize(8)
          Text('元服务API: 从 API 11 起支持 (Callback重载)')
            .fontSize(12)
            .fontColor('#00B578')
            .fontWeight(FontWeight.Medium)
          Text('注意: err.code 为 0 或 err 为 undefined 表示成功')
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

  private appendLog(msg: string): void {
    const time = new Date().toLocaleTimeString()
    this.operationLog = `[${time}] ${msg}\n${this.operationLog}`
  }

  /**
   * Callback方式打开预览
   */
  private callbackOpenPreview(): void {
    try {
      const context = this.getContext()
      const filesDir = context.filesDir
      const fileInfo: filePreview.PreviewInfo = {
        title: 'callback-preview.txt',
        uri: `file://${filesDir}/callback-preview.txt`,
        mimeType: 'text/plain'
      }
      this.appendLog('调用 openPreview (callback)...')

      const displayInfo: filePreview.DisplayInfo = {
        x: 100,
        y: 100,
        width: 800,
        height: 800
      } as filePreview.DisplayInfo

      filePreview.openPreview(context, fileInfo, displayInfo, (err: BusinessError) => {
        if (err && err.code) {
          this.resultText = `Callback打开失败: [${err.code}] ${err.message}`
          this.appendLog(`失败: [${err.code}] ${err.message}`)
        } else {
          this.resultText = 'Callback打开预览成功'
          this.isPreviewOpen = true
          this.appendLog('成功打开预览窗口')
        }
      })
    } catch (error) {
      const err = error as BusinessError
      this.resultText = `操作失败: [${err.code}] ${err.message}`
      this.appendLog(`异常: [${err.code}] ${err.message}`)
    }
  }

  /**
   * Callback方式检查可预览性
   */
  private callbackCanPreview(): void {
    try {
      const context = this.getContext()
      const uri = `file://${context.filesDir}/callback-check.txt`
      this.appendLog(`调用 canPreview (callback): ${uri}`)

      filePreview.canPreview(context, uri, (err: BusinessError, result: boolean) => {
        if (err && err.code) {
          this.resultText = `Callback检查失败: [${err.code}] ${err.message}`
          this.appendLog(`失败: [${err.code}] ${err.message}`)
        } else {
          this.resultText = result ? 'Callback检查: 文件可预览' : 'Callback检查: 文件不可预览'
          this.appendLog(`结果: ${result ? '可预览' : '不可预览'}`)
        }
      })
    } catch (error) {
      const err = error as BusinessError
      this.resultText = `检查失败: [${err.code}] ${err.message}`
      this.appendLog(`异常: [${err.code}] ${err.message}`)
    }
  }

  /**
   * Callback方式查询预览窗口状态
   */
  private callbackHasDisplayed(): void {
    try {
      const context = this.getContext()
      this.appendLog('调用 hasDisplayed (callback)...')

      filePreview.hasDisplayed(context, (err: BusinessError, result: boolean) => {
        if (err && err.code) {
          this.resultText = `Callback查询失败: [${err.code}] ${err.message}`
          this.appendLog(`失败: [${err.code}] ${err.message}`)
        } else {
          this.isPreviewOpen = result
          this.resultText = result ? 'Callback查询: 预览窗口已存在' : 'Callback查询: 预览窗口不存在'
          this.appendLog(`结果: ${result ? '窗口已存在' : '窗口不存在'}`)
        }
      })
    } catch (error) {
      const err = error as BusinessError
      this.resultText = `查询失败: [${err.code}] ${err.message}`
      this.appendLog(`异常: [${err.code}] ${err.message}`)
    }
  }

  /**
   * Callback方式关闭预览
   */
  private callbackClosePreview(): void {
    try {
      const context = this.getContext()
      this.appendLog('调用 closePreview (callback)...')

      filePreview.closePreview(context, (err: BusinessError) => {
        if (err && err.code) {
          this.resultText = `Callback关闭失败: [${err.code}] ${err.message}`
          this.appendLog(`失败: [${err.code}] ${err.message}`)
        } else {
          this.resultText = 'Callback关闭预览成功'
          this.isPreviewOpen = false
          this.appendLog('成功关闭预览窗口')
        }
      })
    } catch (error) {
      const err = error as BusinessError
      this.resultText = `关闭失败: [${err.code}] ${err.message}`
      this.appendLog(`异常: [${err.code}] ${err.message}`)
    }
  }
}
