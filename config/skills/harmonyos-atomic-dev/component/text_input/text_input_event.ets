/**
 * text_input_event — TextInput 事件处理
 * 展示 TextInput 事件回调：onChange / onSubmit / onEditChange / onCopy / onCut / onPaste / onTextSelectionChange
 * 元服务兼容性：基础事件 API 11+ 可用
 */

@ComponentV2
export struct TextInputEvent {
  @Local resultText: string = '输入内容触发各类事件'
  @Local inputText: string = ''
  @Local isEditing: boolean = false
  @Local eventLog: string = ''

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('TextInput 事件处理')
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

        // 事件日志
        Text('事件日志')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Scroll() {
          Text(this.eventLog)
            .fontSize(11)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
            .padding(8)
        }
        .width('90%')
        .height(120)
        .backgroundColor('#FAFAFA')
        .borderRadius(8)

        // 带完整事件的 TextInput
        Text('综合事件输入框')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        TextInput({ placeholder: '输入、提交、复制、粘贴触发事件...' })
          .type(InputType.Normal)
          .width('90%')
          .height(48)
          .enterKeyType(EnterKeyType.Done)
          .onChange((value: string) => {
            try {
              this.inputText = value
              this.addLog(`[onChange] "${value}"`)
              this.resultText = `输入内容: "${value}"\n长度: ${value.length}`
            } catch (e) {
              this.addLog(`[onChange ERROR] ${(e as Error).message}`)
            }
          })
          .onSubmit((enterKey: EnterKeyType) => {
            try {
              this.addLog(`[onSubmit] enterKey=${enterKey}`)
              this.resultText = `提交内容: "${this.inputText}"\n回车键类型: ${enterKey}`
            } catch (e) {
              this.addLog(`[onSubmit ERROR] ${(e as Error).message}`)
            }
          })
          .onEditChange((isEditing: boolean) => {
            this.isEditing = isEditing
            this.addLog(`[onEditChange] isEditing=${isEditing}`)
          })
          .onCopy((value: string) => {
            this.addLog(`[onCopy] "${value}"`)
            this.resultText = `复制内容: "${value}"`
          })
          .onCut((value: string) => {
            this.addLog(`[onCut] "${value}"`)
            this.resultText = `剪切内容: "${value}"`
          })
          .onPaste((value: string) => {
            try {
              this.addLog(`[onPaste] "${value}"`)
              this.resultText = `粘贴内容: "${value}"`
            } catch (e) {
              this.addLog(`[onPaste ERROR] ${(e as Error).message}`)
            }
          })
          .onTextSelectionChange((selectionStart: number, selectionEnd: number) => {
            this.addLog(`[onTextSelectionChange] [${selectionStart}, ${selectionEnd}]`)
          })

        // 回车键类型切换
        Text('回车键类型切换')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        TextInput({ placeholder: '注意键盘回车键样式...' })
          .type(InputType.Normal)
          .width('90%')
          .height(48)
          .enterKeyType(EnterKeyType.Search)
          .onSubmit((enterKey: EnterKeyType) => {
            this.addLog(`[Search onSubmit] key=${enterKey}`)
            this.resultText = `搜索提交: "${this.inputText}"`
          })

        // 操作按钮
        Row({ space: 8 }) {
          Button('清空日志')
            .fontSize(13)
            .layoutWeight(1)
            .height(36)
            .onClick(() => {
              this.eventLog = ''
              this.resultText = '日志已清空'
            })
          Button('编辑状态')
            .fontSize(13)
            .layoutWeight(1)
            .height(36)
            .onClick(() => {
              this.resultText = `当前编辑状态: ${this.isEditing ? '编辑中' : '非编辑'}`
            })
        }
        .width('90%')

        // API 说明区
        Column() {
          Text('API 说明')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 8 })
          Text('onChange(callback) — 输入内容变化时触发')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('onSubmit(callback) — 按下回车键触发')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('onEditChange(callback: boolean) — 输入状态变化（有无光标）')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('onCopy(callback: string) — 复制操作触发')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('onCut(callback: string) — 剪切操作触发')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('onPaste(callback: string) — 粘贴操作触发')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('onTextSelectionChange(start, end) — 选择/光标位置变化')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('enterKeyType(EnterKeyType) — 回车键类型：Go/Search/Send/Next/Done (API 11+)')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('元服务：以上事件均从 API 11+ 可用')
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

  private addLog(msg: string): void {
    const time = new Date().toLocaleTimeString()
    this.eventLog = `[${time}] ${msg}\n${this.eventLog}`
  }
}
