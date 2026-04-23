/**
 * file-info-query — 文件信息查询场景
 * fs.statSync / fs.accessSync / fs.lstatSync
 * 元服务API: 从 API version 11 起支持
 */
import { fileIo as fs } from '@kit.CoreFileKit'
import { common } from '@kit.AbilityKit'
import { BusinessError } from '@kit.BasicServicesKit'

@ComponentV2
export struct FileInfoQuery {
  @Local resultText: string = '点击按钮查询文件信息'
  @Local statInfo: string = '--'
  @Local accessResult: string = '--'
  @Local queryPath: string = 'query-test.txt'
  @Local fileExists: boolean = false

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('文件信息查询')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20, bottom: 10 })

        Text('fs.statSync / accessSync / lstatSync')
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

          Text('stat 信息:')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .width('100%')
          Text(this.statInfo)
            .fontSize(12)
            .fontColor('#333333')
            .fontFamily('monospace')
            .width('100%')
            .maxLines(10)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          Text('access 检查:')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .width('100%')
          Text(this.accessResult)
            .fontSize(12)
            .fontColor('#333333')
            .width('100%')
        }
        .width('90%')
        .padding(16)
        .backgroundColor('#F5F5F5')
        .borderRadius(12)
        .alignItems(HorizontalAlign.Start)

        // 参数控制
        Text('查询文件名')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        TextInput({ text: this.queryPath, placeholder: '输入文件名' })
          .width('90%')
          .onChange((value: string) => {
            this.queryPath = value
          })

        // 操作按钮
        Row({ space: 12 }) {
          Button('创建文件')
            .layoutWeight(1)
            .backgroundColor('#007DFF')
            .borderRadius(8)
            .onClick(() => this.doCreateFile())
          Button('stat 查询')
            .layoutWeight(1)
            .backgroundColor('#00B578')
            .borderRadius(8)
            .onClick(() => this.doStat())
        }
        .width('90%')

        Row({ space: 12 }) {
          Button('access 检查')
            .layoutWeight(1)
            .backgroundColor('#FF9800')
            .borderRadius(8)
            .onClick(() => this.doAccess())
          Button('删除文件')
            .layoutWeight(1)
            .backgroundColor('#E84026')
            .borderRadius(8)
            .onClick(() => this.doDelete())
        }
        .width('90%')

        // API 说明
        Text('API 说明')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Column({ space: 4 }) {
          Text('const stat = fs.statSync(path)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('// stat.size / .mode / .mtime / .atime / .ctime')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('const exists = fs.accessSync(path)  // boolean')
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

  private getFullPath(): string {
    const context = getContext(this) as common.Context
    return `${context.filesDir}/${this.queryPath}`
  }

  private doCreateFile(): void {
    try {
      const file = fs.openSync(this.getFullPath(), fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE)
      fs.writeSync(file.fd, 'File info query content.')
      fs.closeSync(file.fd)
      this.fileExists = true
      this.resultText = '文件创建成功'
    } catch (error) {
      const err = error as BusinessError
      this.resultText = `创建失败: [${err.code}] ${err.message}`
    }
  }

  private doStat(): void {
    try {
      const stat = fs.statSync(this.getFullPath())
      this.statInfo =
        `size: ${stat.size} bytes\n` +
        `mode: ${stat.mode}\n` +
        `mtime: ${new Date(stat.mtime * 1000).toLocaleString()}\n` +
        `atime: ${new Date(stat.atime * 1000).toLocaleString()}\n` +
        `isFile: ${stat.isFile()}\n` +
        `isDirectory: ${stat.isDirectory()}`
      this.resultText = 'stat 查询成功'
    } catch (error) {
      const err = error as BusinessError
      this.statInfo = '--'
      this.resultText = `stat 失败: [${err.code}] ${err.message}`
    }
  }

  private doAccess(): void {
    try {
      const exists = fs.accessSync(this.getFullPath())
      this.accessResult = exists ? '文件存在' : '文件不存在'
      this.fileExists = exists
      this.resultText = `access 检查完成: ${this.accessResult}`
    } catch (error) {
      const err = error as BusinessError
      this.accessResult = `错误: [${err.code}] ${err.message}`
      this.resultText = 'access 检查异常'
    }
  }

  private doDelete(): void {
    try {
      fs.unlinkSync(this.getFullPath())
      this.fileExists = false
      this.statInfo = '--'
      this.accessResult = '--'
      this.resultText = '文件删除成功'
    } catch (error) {
      const err = error as BusinessError
      this.resultText = `删除失败: [${err.code}] ${err.message}`
    }
  }
}
