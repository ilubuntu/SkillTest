/**
 * file-read-write — 文件读写场景
 * fs.openSync / fs.writeSync / fs.readSync / fs.closeSync
 * 元服务API: 从 API version 11 起支持
 */
import { fileIo as fs } from '@kit.CoreFileKit'
import { common } from '@kit.AbilityKit'
import { BusinessError } from '@kit.BasicServicesKit'
import { util } from '@kit.ArkTS'

@ComponentV2
export struct FileReadWrite {
  @Local resultText: string = '点击按钮执行文件读写操作'
  @Local fileContent: string = '--'
  @Local filePath: string = '--'
  @Local writeContent: string = 'Hello HarmonyOS 元服务!'
  @Local isOpen: boolean = false
  @Local fd: number = -1

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('文件读写')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20, bottom: 10 })

        Text('fs.openSync / writeSync / readSync / closeSync')
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
            Text('文件路径: ')
              .fontSize(12)
              .fontColor('#999999')
            Text(this.filePath)
              .fontSize(12)
              .layoutWeight(1)
              .maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .width('100%')
          Row() {
            Text('文件内容: ')
              .fontSize(12)
              .fontColor('#999999')
            Text(this.fileContent)
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

        // 参数控制
        Text('写入内容')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        TextInput({ text: this.writeContent, placeholder: '输入要写入的内容' })
          .width('90%')
          .onChange((value: string) => {
            this.writeContent = value
          })

        // 操作按钮
        Row({ space: 12 }) {
          Button('创建并写入')
            .layoutWeight(1)
            .backgroundColor('#007DFF')
            .borderRadius(8)
            .onClick(() => this.doWrite())
          Button('读取内容')
            .layoutWeight(1)
            .backgroundColor('#00B578')
            .borderRadius(8)
            .onClick(() => this.doRead())
        }
        .width('90%')

        Row({ space: 12 }) {
          Button('追加写入')
            .layoutWeight(1)
            .backgroundColor('#FF9800')
            .borderRadius(8)
            .onClick(() => this.doAppend())
          Button('关闭并清理')
            .layoutWeight(1)
            .backgroundColor('#999999')
            .borderRadius(8)
            .onClick(() => this.doCleanup())
        }
        .width('90%')

        // API 说明
        Text('API 说明')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Column({ space: 4 }) {
          Text('import { fileIo as fs } from "@kit.CoreFileKit"')
            .fontSize(12)
            .fontColor('#007DFF')
            .fontFamily('monospace')
          Text('// 打开文件（创建 | 读写）')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('const file = fs.openSync(path, fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('// 写入数据')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('fs.writeSync(file.fd, "content")')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('// 读取数据')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('const buf = new ArrayBuffer(1024)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('fs.readSync(file.fd, buf)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('// 关闭文件')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('fs.closeSync(file.fd)')
            .fontSize(12)
            .fontColor('#666666')
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

  private getFilesDir(): string {
    const context = getContext(this) as common.Context
    return context.filesDir
  }

  /**
   * 创建文件并写入内容
   */
  private doWrite(): void {
    try {
      const dir = this.getFilesDir()
      this.filePath = `${dir}/readwrite-demo.txt`
      const file = fs.openSync(this.filePath, fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE | fs.OpenMode.TRUNC)
      this.fd = file.fd
      const writeLen = fs.writeSync(this.fd, this.writeContent)
      this.resultText = `写入成功，写入 ${writeLen} 字节`
      this.fileContent = '--'
      this.isOpen = true
    } catch (error) {
      const err = error as BusinessError
      this.resultText = `写入失败: [${err.code}] ${err.message}`
    }
  }

  /**
   * 读取文件内容
   */
  private doRead(): void {
    try {
      const dir = this.getFilesDir()
      this.filePath = `${dir}/readwrite-demo.txt`
      let fd: number
      if (this.isOpen && this.fd >= 0) {
        fd = this.fd
      } else {
        const file = fs.openSync(this.filePath, fs.OpenMode.READ_ONLY)
        fd = file.fd
      }
      const buf = new ArrayBuffer(4096)
      const readLen = fs.readSync(fd, buf)
      const textDecoder = util.TextDecoder.create('utf-8')
      this.fileContent = textDecoder.decodeToString(new Uint8Array(buf, 0, readLen))
      this.resultText = `读取成功，共 ${readLen} 字节`
      if (!this.isOpen || this.fd < 0) {
        fs.closeSync(fd)
      }
    } catch (error) {
      const err = error as BusinessError
      this.resultText = `读取失败: [${err.code}] ${err.message}`
    }
  }

  /**
   * 追加写入
   */
  private doAppend(): void {
    try {
      const dir = this.getFilesDir()
      this.filePath = `${dir}/readwrite-demo.txt`
      const file = fs.openSync(this.filePath, fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE | fs.OpenMode.APPEND)
      const writeLen = fs.writeSync(file.fd, `\n${this.writeContent}`)
      this.resultText = `追加成功，写入 ${writeLen} 字节`
      fs.closeSync(file.fd)
    } catch (error) {
      const err = error as BusinessError
      this.resultText = `追加失败: [${err.code}] ${err.message}`
    }
  }

  /**
   * 关闭文件并清理
   */
  private doCleanup(): void {
    try {
      if (this.isOpen && this.fd >= 0) {
        fs.closeSync(this.fd)
        this.isOpen = false
        this.fd = -1
      }
      this.resultText = '文件已关闭'
    } catch (error) {
      const err = error as BusinessError
      this.resultText = `关闭失败: [${err.code}] ${err.message}`
    }
  }
}
