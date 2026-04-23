/**
 * file-stream-operate — 文件流操作场景
 * fs.createStream / createReadStream / createWriteStream
 * ⚠️ fs.createStream/fdopenStream 在元服务中 API 20+ 支持
 *     createReadStream/createWriteStream 在元服务中 API 20+ 支持
 *     当前 SDK 22 可用，但为高版本 API，展示 UI 骨架 + 说明
 */
import { fileIo as fs } from '@kit.CoreFileKit'
import { common } from '@kit.AbilityKit'
import { BusinessError } from '@kit.BasicServicesKit'
import { util } from '@kit.ArkTS'

@ComponentV2
export struct FileStreamOperate {
  @Local resultText: string = '文件流操作需要 API 20+ 元服务支持'
  @Local streamContent: string = '--'
  @Local writeData: string = '流式写入的数据内容'

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('文件流操作')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20, bottom: 10 })

        Text('fs.createStream / createReadStream / createWriteStream')
          .fontSize(13)
          .fontColor('#666666')
          .width('90%')
          .textAlign(TextAlign.Center)

        // 提示卡片
        Column({ space: 8 }) {
          Row({ space: 8 }) {
            Text('ℹ️')
              .fontSize(18)
            Text('版本要求')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor('#1565C0')
          }
          Text('以下 API 在元服务中需要 API 20+:')
            .fontSize(13)
            .fontColor('#1565C0')
            .width('100%')
          Text('• fs.createStream() / createStreamSync()  — API 20+')
            .fontSize(12)
            .fontColor('#0D47A1')
            .fontFamily('monospace')
          Text('• fs.fdopenStream() / fdopenStreamSync()  — API 20+')
            .fontSize(12)
            .fontColor('#0D47A1')
            .fontFamily('monospace')
          Text('• fs.createReadStream()  — API 12 (非元服务), 20+ (元服务)')
            .fontSize(12)
            .fontColor('#0D47A1')
            .fontFamily('monospace')
          Text('• fs.createWriteStream()  — API 12 (非元服务), 20+ (元服务)')
            .fontSize(12)
            .fontColor('#0D47A1')
            .fontFamily('monospace')
          Text('')
            .fontSize(8)
          Text('当前 SDK 版本 API 22，可正常使用')
            .fontSize(12)
            .fontColor('#333333')
            .fontWeight(FontWeight.Medium)
        }
        .width('90%')
        .padding(16)
        .backgroundColor('#E3F2FD')
        .borderRadius(12)
        .border({ width: 1, color: '#64B5F6' })
        .alignItems(HorizontalAlign.Start)

        // 结果展示
        Column({ space: 8 }) {
          Text(this.resultText)
            .fontSize(13)
            .fontColor(this.resultText.includes('成功') ? '#00B578' :
              (this.resultText.includes('失败') ? '#E84026' : '#333333'))
            .width('100%')
          Text(this.streamContent)
            .fontSize(12)
            .fontColor('#333333')
            .fontFamily('monospace')
            .width('100%')
            .maxLines(8)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .width('90%')
        .padding(16)
        .backgroundColor('#F5F5F5')
        .borderRadius(12)
        .alignItems(HorizontalAlign.Start)

        // 参数控制
        Text('写入内容')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        TextInput({ text: this.writeData, placeholder: '流式写入内容' })
          .width('90%')
          .onChange((value: string) => {
            this.writeData = value
          })

        // 操作按钮
        Row({ space: 12 }) {
          Button('流式写入')
            .layoutWeight(1)
            .backgroundColor('#007DFF')
            .borderRadius(8)
            .onClick(() => this.doStreamWrite())
          Button('流式读取')
            .layoutWeight(1)
            .backgroundColor('#00B578')
            .borderRadius(8)
            .onClick(() => this.doStreamRead())
        }
        .width('90%')

        // API 说明
        Text('API 说明')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Column({ space: 4 }) {
          Text('const ws = fs.createStreamSync(path, "w+")')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('ws.writeSync("data")')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('ws.closeSync()')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('')
            .fontSize(8)
          Text('元服务API: 从 API 20 起支持 (当前 SDK 22 可用)')
            .fontSize(12)
            .fontColor('#1565C0')
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

  private getFilePath(): string {
    const context = getContext(this) as common.Context
    return `${context.filesDir}/stream-demo.txt`
  }

  private doStreamWrite(): void {
    try {
      const stream = fs.createStreamSync(this.getFilePath(), 'w+')
      stream.writeSync(this.writeData)
      stream.closeSync()
      this.resultText = '流式写入成功'
      this.streamContent = '--'
    } catch (error) {
      const err = error as BusinessError
      this.resultText = `流式写入失败: [${err.code}] ${err.message}`
    }
  }

  private doStreamRead(): void {
    try {
      const stream = fs.createStreamSync(this.getFilePath(), 'r')
      const buf = new ArrayBuffer(4096)
      const readLen = stream.readSync(buf)
      const decoder = util.TextDecoder.create('utf-8')
      this.streamContent = decoder.decodeToString(new Uint8Array(buf, 0, readLen))
      stream.closeSync()
      this.resultText = `流式读取成功，共 ${readLen} 字节`
    } catch (error) {
      const err = error as BusinessError
      this.resultText = `流式读取失败: [${err.code}] ${err.message}`
    }
  }
}
