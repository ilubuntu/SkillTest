/**
 * file-text-operate — 文本文件操作场景
 * fs.readTextSync / fs.writeSync (文本读写)
 * 元服务API: 从 API version 11 起支持
 */
import { fileIo as fs } from '@kit.CoreFileKit'
import { common } from '@kit.AbilityKit'
import { BusinessError } from '@kit.BasicServicesKit'

@ComponentV2
export struct FileTextOperate {
  @Local resultText: string = '点击按钮执行文本操作'
  @Local textContent: string = '--'
  @Local inputText: string = '第一行: HarmonyOS\n第二行: 元服务开发\n第三行: 文件操作'
  @Local lineCount: number = 0
  @Local encoding: string = 'utf-8'

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('文本文件操作')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20, bottom: 10 })

        Text('fs.readTextSync / writeSync (文本读写)')
          .fontSize(13)
          .fontColor('#666666')
          .width('90%')
          .textAlign(TextAlign.Center)

        // 结果展示
        Column({ space: 8 }) {
          Text(this.resultText)
            .fontSize(13)
            .fontColor(this.resultText.includes('成功') ? '#00B578' :
              (this.resultText.includes('失败') ? '#E84026' : '#333333'))
            .width('100%')
          Text(`行数: ${this.lineCount}`)
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('文件内容:')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text(this.textContent)
            .fontSize(12)
            .fontColor('#333333')
            .fontFamily('monospace')
            .width('100%')
            .maxLines(10)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .width('90%')
        .padding(16)
        .backgroundColor('#F5F5F5')
        .borderRadius(12)
        .alignItems(HorizontalAlign.Start)

        // 参数控制
        Text('文本内容')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        TextArea({ text: this.inputText, placeholder: '输入多行文本' })
          .width('90%')
          .height(120)
          .onChange((value: string) => {
            this.inputText = value
          })

        // 操作按钮
        Row({ space: 12 }) {
          Button('写入文本')
            .layoutWeight(1)
            .backgroundColor('#007DFF')
            .borderRadius(8)
            .onClick(() => this.doWriteText())
          Button('读取文本')
            .layoutWeight(1)
            .backgroundColor('#00B578')
            .borderRadius(8)
            .onClick(() => this.doReadText())
        }
        .width('90%')

        // API 说明
        Text('API 说明')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Column({ space: 4 }) {
          Text('fs.readTextSync(path, { encoding: "utf-8" })')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('// readTextSync 一次性读取整个文本文件')
            .fontSize(12)
            .fontColor('#999999')
            .fontFamily('monospace')
          Text('// 适合小文件场景，大文件请用 read + 流式处理')
            .fontSize(12)
            .fontColor('#999999')
            .fontFamily('monospace')
          Text('')
            .fontSize(8)
          Text('元服务API: 从 API 11 起支持')
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

  private getFilePath(): string {
    const context = getContext(this) as common.Context
    return `${context.filesDir}/text-demo.txt`
  }

  private doWriteText(): void {
    try {
      const file = fs.openSync(this.getFilePath(), fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE | fs.OpenMode.TRUNC)
      fs.writeSync(file.fd, this.inputText)
      fs.closeSync(file.fd)
      this.resultText = '文本写入成功'
      this.lineCount = this.inputText.split('\n').length
    } catch (error) {
      const err = error as BusinessError
      this.resultText = `写入失败: [${err.code}] ${err.message}`
    }
  }

  private doReadText(): void {
    try {
      const content = fs.readTextSync(this.getFilePath(), { encoding: 'utf-8' })
      this.textContent = content
      this.lineCount = content.split('\n').length
      this.resultText = `文本读取成功，共 ${content.length} 字符`
    } catch (error) {
      const err = error as BusinessError
      this.resultText = `读取失败: [${err.code}] ${err.message}`
      this.textContent = '--'
    }
  }
}
