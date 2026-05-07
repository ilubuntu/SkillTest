/**
 * text_input_controller — TextInput 控制器操作
 * 展示 TextInputController：光标位置、文本选择、停止编辑
 * 元服务兼容性：TextInputController API 8+，元服务 API 11+ 可用
 */

import { BusinessError } from '@kit.BasicServicesKit'

@ComponentV2
export struct TextInputControllerOps {
  @Local resultText: string = '使用按钮控制光标和编辑状态'
  @Local inputText: string = 'Hello HarmonyOS TextInput Controller'
  controller: TextInputController = new TextInputController()

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('TextInput 控制器操作')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20, bottom: 10 })

        // 结果展示区
        Column() {
          Text(this.resultText)
            .fontSize(14)
            .fontColor('#333333')
            .width('100%')
            .padding(12)
        }
        .width('90%')
        .backgroundColor('#F5F5F5')
        .borderRadius(8)

        // 带控制器的 TextInput
        Text('可控输入框')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        TextInput({ placeholder: '输入文本...', text: this.inputText, controller: this.controller })
          .type(InputType.Normal)
          .width('90%')
          .height(48)
          .onChange((value: string) => {
            try {
              this.inputText = value
              this.resultText = `当前文本: "${value}"\n长度: ${value.length}`
            } catch (e) {
              this.resultText = `onChange 异常: ${(e as Error).message}`
            }
          })
          .onTextSelectionChange((start: number, end: number) => {
            this.resultText = `选择范围: [${start}, ${end}]`
          })

        // 光标操作
        Text('光标操作')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Row({ space: 8 }) {
          Button('光标→起始')
            .fontSize(12)
            .layoutWeight(1)
            .height(36)
            .onClick(() => {
              try {
                this.controller.caretPosition(0)
                this.resultText = '光标已移至起始位置(0)'
              } catch (e) {
                const err = e as BusinessError
                this.resultText = `光标操作失败: code=${err.code}, msg=${err.message}`
              }
            })
          Button('光标→末尾')
            .fontSize(12)
            .layoutWeight(1)
            .height(36)
            .onClick(() => {
              try {
                const pos = this.inputText.length
                this.controller.caretPosition(pos)
                this.resultText = `光标已移至末尾(${pos})`
              } catch (e) {
                const err = e as BusinessError
                this.resultText = `光标操作失败: code=${err.code}, msg=${err.message}`
              }
            })
          Button('光标→中间')
            .fontSize(12)
            .layoutWeight(1)
            .height(36)
            .onClick(() => {
              try {
                const pos = Math.floor(this.inputText.length / 2)
                this.controller.caretPosition(pos)
                this.resultText = `光标已移至中间(${pos})`
              } catch (e) {
                const err = e as BusinessError
                this.resultText = `光标操作失败: code=${err.code}, msg=${err.message}`
              }
            })
        }
        .width('90%')

        // 文本选择
        Text('文本选择')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Row({ space: 8 }) {
          Button('全选文本')
            .fontSize(12)
            .layoutWeight(1)
            .height(36)
            .onClick(() => {
              try {
                this.controller.setTextSelection(0, this.inputText.length)
                this.resultText = `已全选: [0, ${this.inputText.length}]`
              } catch (e) {
                const err = e as BusinessError
                this.resultText = `选择操作失败: code=${err.code}, msg=${err.message}`
              }
            })
          Button('选前半段')
            .fontSize(12)
            .layoutWeight(1)
            .height(36)
            .onClick(() => {
              try {
                const half = Math.floor(this.inputText.length / 2)
                this.controller.setTextSelection(0, half)
                this.resultText = `已选前半段: [0, ${half}]`
              } catch (e) {
                const err = e as BusinessError
                this.resultText = `选择操作失败: code=${err.code}, msg=${err.message}`
              }
            })
          Button('停编辑')
            .fontSize(12)
            .layoutWeight(1)
            .height(36)
            .onClick(() => {
              try {
                this.controller.stopEditing()
                this.resultText = '已退出编辑态（收起键盘）'
              } catch (e) {
                const err = e as BusinessError
                this.resultText = `停止编辑失败: code=${err.code}, msg=${err.message}`
              }
            })
        }
        .width('90%')

        // maxLength + caretPosition 属性
        Text('maxLength + caretPosition 属性')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        TextInput({ placeholder: '最多 20 个字符...' })
          .type(InputType.Normal)
          .width('90%')
          .height(48)
          .maxLength(20)
          .caretPosition(0)
          .onChange((value: string) => {
            this.resultText = `输入: "${value}"\n剩余: ${20 - value.length} / 20`
          })

        // inputFilter
        Text('inputFilter 正则过滤')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        TextInput({ placeholder: '仅允许字母和数字...' })
          .type(InputType.Normal)
          .width('90%')
          .height(48)
          .inputFilter('^[a-zA-Z0-9]*$', (err: string) => {
            this.resultText = `被过滤的字符: "${err}"`
          })
          .onChange((value: string) => {
            this.resultText = `[inputFilter] 有效输入: "${value}"`
          })

        // API 说明区
        Column() {
          Text('API 说明')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 8 })
          Text('TextInputController — 控制器，通过 new TextInputController() 创建')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('caretPosition(value: number) — 设置光标位置，0 为起始')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('setTextSelection(start, end) — 设置文本选择区域')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('stopEditing() — 退出编辑态，收起键盘')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('maxLength(value: number) — 最大输入字符数，默认 Infinity')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('caretPosition(value: number) 属性 — 初始光标位置（属性级别）')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('inputFilter(regex, error?) — 正则过滤输入，error 返回被过滤内容')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('元服务：TextInputController 及以上属性均从 API 11+ 可用')
            .fontSize(12)
            .fontColor('#4CAF50')
            .width('100%')
        }
        .width('90%')
        .backgroundColor('#FFF9E6')
        .borderRadius(8)
        .padding(12)
        .margin({ top: 8, bottom: 20 })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
  }
}
