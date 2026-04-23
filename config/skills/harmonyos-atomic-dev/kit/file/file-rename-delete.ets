/**
 * file-rename-delete — 文件重命名与删除场景
 * fs.renameSync / fs.unlinkSync / fs.truncateSync
 * 元服务API: 从 API version 11 起支持
 */
import { fileIo as fs } from '@kit.CoreFileKit'
import { common } from '@kit.AbilityKit'
import { BusinessError } from '@kit.BasicServicesKit'

@ComponentV2
export struct FileRenameDelete {
  @Local resultText: string = '点击按钮执行文件操作'
  @Local fileName: string = 'original.txt'
  @Local newName: string = 'renamed.txt'
  @Local currentFiles: string = '--'

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('文件重命名与删除')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20, bottom: 10 })

        Text('fs.renameSync / unlinkSync / truncateSync')
          .fontSize(13)
          .fontColor('#666666')
          .width('90%')
          .textAlign(TextAlign.Center)

        // 结果展示
        Column({ space: 8 }) {
          Text(this.resultText)
            .fontSize(13)
            .fontColor(this.resultText.includes('成功') ? '#00B578' :
              (this.resultText.includes('失败') || this.resultText.includes('不存在') ? '#E84026' : '#333333'))
            .width('100%')
          Text('当前文件:')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text(this.currentFiles)
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
        Text('原文件名')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        TextInput({ text: this.fileName, placeholder: '原文件名' })
          .width('90%')
          .onChange((value: string) => {
            this.fileName = value
          })

        Text('新文件名')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        TextInput({ text: this.newName, placeholder: '新文件名' })
          .width('90%')
          .onChange((value: string) => {
            this.newName = value
          })

        // 操作按钮
        Row({ space: 12 }) {
          Button('创建文件')
            .layoutWeight(1)
            .backgroundColor('#007DFF')
            .borderRadius(8)
            .onClick(() => this.doCreate())
          Button('重命名')
            .layoutWeight(1)
            .backgroundColor('#00B578')
            .borderRadius(8)
            .onClick(() => this.doRename())
        }
        .width('90%')

        Row({ space: 12 }) {
          Button('截断为5字节')
            .layoutWeight(1)
            .backgroundColor('#FF9800')
            .borderRadius(8)
            .onClick(() => this.doTruncate())
          Button('删除文件')
            .layoutWeight(1)
            .backgroundColor('#E84026')
            .borderRadius(8)
            .onClick(() => this.doDelete())
        }
        .width('90%')

        Button('刷新文件列表')
          .width('90%')
          .backgroundColor('#666666')
          .borderRadius(8)
          .onClick(() => this.doRefreshList())

        // API 说明
        Text('API 说明')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Column({ space: 4 }) {
          Text('fs.renameSync(oldPath, newPath)  // 重命名')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('fs.unlinkSync(path)  // 删除文件')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('fs.truncateSync(path, len)  // 截断文件')
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

  private doCreate(): void {
    try {
      const path = `${this.getFilesDir()}/${this.fileName}`
      const file = fs.openSync(path, fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE | fs.OpenMode.TRUNC)
      fs.writeSync(file.fd, 'This is the original file content for rename and delete.')
      fs.closeSync(file.fd)
      this.resultText = '文件创建成功'
      this.doRefreshList()
    } catch (error) {
      const err = error as BusinessError
      this.resultText = `创建失败: [${err.code}] ${err.message}`
    }
  }

  private doRename(): void {
    try {
      const dir = this.getFilesDir()
      const oldPath = `${dir}/${this.fileName}`
      const newPath = `${dir}/${this.newName}`
      fs.renameSync(oldPath, newPath)
      this.fileName = this.newName
      this.resultText = '重命名成功'
      this.doRefreshList()
    } catch (error) {
      const err = error as BusinessError
      this.resultText = `重命名失败: [${err.code}] ${err.message}`
    }
  }

  private doTruncate(): void {
    try {
      const path = `${this.getFilesDir()}/${this.fileName}`
      fs.truncateSync(path, 5)
      this.resultText = '截断成功，文件保留前5字节'
    } catch (error) {
      const err = error as BusinessError
      this.resultText = `截断失败: [${err.code}] ${err.message}`
    }
  }

  private doDelete(): void {
    try {
      const path = `${this.getFilesDir()}/${this.fileName}`
      fs.unlinkSync(path)
      this.resultText = '文件删除成功'
      this.doRefreshList()
    } catch (error) {
      const err = error as BusinessError
      this.resultText = `删除失败: [${err.code}] ${err.message}`
    }
  }

  private doRefreshList(): void {
    try {
      const files = fs.listFileSync(this.getFilesDir())
      this.currentFiles = files.join('\n') || '(空目录)'
    } catch (error) {
      this.currentFiles = '获取文件列表失败'
    }
  }
}
