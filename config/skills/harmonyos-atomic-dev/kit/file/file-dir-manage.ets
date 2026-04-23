/**
 * file-dir-manage — 目录管理场景
 * fs.mkdirSync / fs.rmdirSync / fs.listFileSync / fs.renameSync
 * 元服务API: 从 API version 11 起支持
 */
import { fileIo as fs } from '@kit.CoreFileKit'
import { common } from '@kit.AbilityKit'
import { BusinessError } from '@kit.BasicServicesKit'

@ComponentV2
export struct FileDirManage {
  @Local resultText: string = '点击按钮执行目录操作'
  @Local dirPath: string = '--'
  @Local fileList: string = '--'
  @Local dirName: string = 'demo-dir'

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('目录管理')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20, bottom: 10 })

        Text('fs.mkdirSync / rmdirSync / listFileSync')
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
            Text('目录路径: ')
              .fontSize(12)
              .fontColor('#999999')
            Text(this.dirPath)
              .fontSize(12)
              .layoutWeight(1)
              .maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .width('100%')
          Text('文件列表:')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text(this.fileList)
            .fontSize(12)
            .fontColor('#333333')
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
        Text('目录名称')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        TextInput({ text: this.dirName, placeholder: '输入目录名' })
          .width('90%')
          .onChange((value: string) => {
            this.dirName = value
          })

        // 操作按钮
        Row({ space: 12 }) {
          Button('创建目录')
            .layoutWeight(1)
            .backgroundColor('#007DFF')
            .borderRadius(8)
            .onClick(() => this.doMkdir())
          Button('列出文件')
            .layoutWeight(1)
            .backgroundColor('#00B578')
            .borderRadius(8)
            .onClick(() => this.doListFile())
        }
        .width('90%')

        Row({ space: 12 }) {
          Button('创建子文件')
            .layoutWeight(1)
            .backgroundColor('#FF9800')
            .borderRadius(8)
            .onClick(() => this.doCreateSubFile())
          Button('删除目录')
            .layoutWeight(1)
            .backgroundColor('#E84026')
            .borderRadius(8)
            .onClick(() => this.doRmdir())
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
          Text('fs.mkdirSync(path)  // 创建目录')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('fs.rmdirSync(path)  // 删除空目录')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('fs.listFileSync(path)  // 列出子文件')
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

  private doMkdir(): void {
    try {
      const dir = this.getFilesDir()
      this.dirPath = `${dir}/${this.dirName}`
      fs.mkdirSync(this.dirPath)
      this.resultText = '创建目录成功'
    } catch (error) {
      const err = error as BusinessError
      if (err.code === 13900015) {
        this.resultText = '目录已存在'
      } else {
        this.resultText = `创建失败: [${err.code}] ${err.message}`
      }
    }
  }

  private doListFile(): void {
    try {
      const dir = this.getFilesDir()
      const files = fs.listFileSync(dir)
      this.dirPath = dir
      this.fileList = files.join('\n') || '(空)'
      this.resultText = `列出 ${files.length} 个文件/目录`
    } catch (error) {
      const err = error as BusinessError
      this.resultText = `列文件失败: [${err.code}] ${err.message}`
    }
  }

  private doCreateSubFile(): void {
    try {
      const dir = this.getFilesDir()
      const subPath = `${dir}/${this.dirName}/note.txt`
      const file = fs.openSync(subPath, fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE)
      fs.writeSync(file.fd, 'This is a note file.')
      fs.closeSync(file.fd)
      this.resultText = '子文件创建成功'
    } catch (error) {
      const err = error as BusinessError
      this.resultText = `创建子文件失败: [${err.code}] ${err.message}`
    }
  }

  private doRmdir(): void {
    try {
      const dir = this.getFilesDir()
      const targetPath = `${dir}/${this.dirName}`
      // rmdirSync 只能删除空目录，先清理子文件
      const files = fs.listFileSync(targetPath)
      for (const fileName of files) {
        fs.unlinkSync(`${targetPath}/${fileName}`)
      }
      fs.rmdirSync(targetPath)
      this.resultText = '目录删除成功'
      this.fileList = '--'
    } catch (error) {
      const err = error as BusinessError
      this.resultText = `删除失败: [${err.code}] ${err.message}`
    }
  }
}
