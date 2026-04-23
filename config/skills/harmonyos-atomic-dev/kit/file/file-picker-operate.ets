/**
 * file-picker-operate — 文件选择器场景
 * picker.DocumentViewPicker / AudioViewPicker
 * 元服务API: 从 API version 12 起支持
 */
import { picker } from '@kit.CoreFileKit'
import { common } from '@kit.AbilityKit'
import { BusinessError } from '@kit.BasicServicesKit'

@ComponentV2
export struct FilePickerOperate {
  @Local resultText: string = '点击按钮拉起文件选择器'
  @Local selectedUris: string = '--'
  @Local savedUri: string = '--'
  @Local saveContent: string = '通过 Picker 保存的文件内容'

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('文件选择器')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20, bottom: 10 })

        Text('picker.DocumentViewPicker.select / save')
          .fontSize(13)
          .fontColor('#666666')
          .width('90%')
          .textAlign(TextAlign.Center)

        // 结果展示
        Column({ space: 8 }) {
          Text(this.resultText)
            .fontSize(13)
            .fontColor(this.resultText.includes('成功') ? '#00B578' :
              (this.resultText.includes('失败') || this.resultText.includes('取消') ? '#E84026' : '#333333'))
            .width('100%')
          Text('选中的 URI:')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text(this.selectedUris)
            .fontSize(12)
            .fontColor('#333333')
            .fontFamily('monospace')
            .width('100%')
            .maxLines(5)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          Text('保存 URI:')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text(this.savedUri)
            .fontSize(12)
            .fontColor('#333333')
            .fontFamily('monospace')
            .width('100%')
            .maxLines(3)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .width('90%')
        .padding(16)
        .backgroundColor('#F5F5F5')
        .borderRadius(12)
        .alignItems(HorizontalAlign.Start)

        // 参数控制
        Text('保存内容')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        TextInput({ text: this.saveContent, placeholder: '输入保存内容' })
          .width('90%')
          .onChange((value: string) => {
            this.saveContent = value
          })

        // 操作按钮
        Row({ space: 12 }) {
          Button('选择文件')
            .layoutWeight(1)
            .backgroundColor('#007DFF')
            .borderRadius(8)
            .onClick(() => this.doSelect())
          Button('选择并读取')
            .layoutWeight(1)
            .backgroundColor('#00B578')
            .borderRadius(8)
            .onClick(() => this.doSelectAndRead())
        }
        .width('90%')

        Button('保存文件')
          .width('90%')
          .backgroundColor('#FF9800')
          .borderRadius(8)
          .onClick(() => this.doSave())

        // API 说明
        Text('API 说明')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Column({ space: 4 }) {
          Text('import { picker } from "@kit.CoreFileKit"')
            .fontSize(12)
            .fontColor('#007DFF')
            .fontFamily('monospace')
          Text('const docPicker = new picker.DocumentViewPicker(context)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('const uris = await docPicker.select(option)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('const uri = await docPicker.save(saveOpt)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('')
            .fontSize(8)
          Text('元服务API: 从 API 12 起支持')
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

  private getContext(): common.Context {
    return getContext(this) as common.Context
  }

  private async doSelect(): Promise<void> {
    try {
      const context = this.getContext()
      const docPicker = new picker.DocumentViewPicker(context)
      const selectOption = new picker.DocumentSelectOptions()
      const uris = await docPicker.select(selectOption)
      if (uris && uris.length > 0) {
        this.selectedUris = uris.join('\n')
        this.resultText = `选中 ${uris.length} 个文件`
      } else {
        this.resultText = '未选择文件'
      }
    } catch (error) {
      const err = error as BusinessError
      this.resultText = `选择失败: [${err.code}] ${err.message}`
    }
  }

  private async doSelectAndRead(): Promise<void> {
    try {
      const context = this.getContext()
      const docPicker = new picker.DocumentViewPicker(context)
      const selectOption = new picker.DocumentSelectOptions()
      const uris = await docPicker.select(selectOption)
      if (uris && uris.length > 0) {
        this.selectedUris = uris.join('\n')
        this.resultText = `选中 ${uris.length} 个文件，URI 已获取`
      } else {
        this.resultText = '未选择文件'
      }
    } catch (error) {
      const err = error as BusinessError
      this.resultText = `选择失败: [${err.code}] ${err.message}`
    }
  }

  private async doSave(): Promise<void> {
    try {
      const context = this.getContext()
      const docPicker = new picker.DocumentViewPicker(context)
      const saveOption = new picker.DocumentSaveOptions()
      saveOption.newFileNames = ['picker-save.txt']
      const uri = await docPicker.save(saveOption)
      if (uri && uri.length > 0) {
        this.savedUri = uri[0]
        this.resultText = '文件保存路径已获取'
      } else {
        this.resultText = '未选择保存位置'
      }
    } catch (error) {
      const err = error as BusinessError
      this.resultText = `保存失败: [${err.code}] ${err.message}`
    }
  }
}
