/**
 * rich_editor-event — RichEditor 事件处理
 * 展示 RichEditor 焦点、选区变化等事件回调
 * 元服务兼容性：API 11+ 可用
 */

import { BusinessError } from '@kit.BasicServicesKit'

@ComponentV2
export struct RichEditorEvent {
  @Local resultText: string = '等待操作...'
  @Local focusCount: number = 0
  @Local blurCount: number = 0
  controller: RichEditorController = new RichEditorController()

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('RichEditor 事件处理')
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

        // 事件计数
        Row({ space: 16 }) {
          Column() {
            Text(`${this.focusCount}`)
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .fontColor('#2196F3')
            Text('获焦次数')
              .fontSize(12)
              .fontColor('#999999')
          }
          .layoutWeight(1)
          .padding(12)
          .backgroundColor('#E3F2FD')
          .borderRadius(8)

          Column() {
            Text(`${this.blurCount}`)
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FF9800')
            Text('失焦次数')
              .fontSize(12)
              .fontColor('#999999')
          }
          .layoutWeight(1)
          .padding(12)
          .backgroundColor('#FFF3E0')
          .borderRadius(8)
        }
        .width('90%')

        // RichEditor 编辑区
        RichEditor({ controller: this.controller })
          .width('90%')
          .height(180)
          .borderWidth(1)
          .borderColor('#CCCCCC')
          .borderRadius(8)
          .padding(12)
          .onReady(() => {
            this.controller.addTextSpan('点击编辑区域触发焦点事件')
            this.resultText = '编辑器就绪，尝试交互'
          })
          .onFocus(() => {
            this.focusCount++
            this.resultText = `获焦事件触发 (第${this.focusCount}次)`
          })
          .onBlur(() => {
            this.blurCount++
            this.resultText = `失焦事件触发 (第${this.blurCount}次)`
          })

        // 操作按钮
        Row({ space: 8 }) {
          Button('添加文本')
            .fontSize(13)
            .layoutWeight(1)
            .height(36)
            .onClick(() => {
              try {
                this.controller.addTextSpan('新增文本段 ')
                this.resultText = '已添加文本'
              } catch (error) {
                const err = error as BusinessError
                this.resultText = `错误: ${err.code} - ${err.message}`
              }
            })
          Button('重置计数')
            .fontSize(13)
            .layoutWeight(1)
            .height(36)
            .onClick(() => {
              this.focusCount = 0
              this.blurCount = 0
              this.resultText = '计数已重置'
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
          Text('.onFocus(() => {}) — 获焦回调')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('.onBlur(() => {}) — 失焦回调')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('.onReady(() => {}) — 组件就绪回调')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('元服务：API 11+ 可用')
            .fontSize(12)
            .fontColor('#999999')
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
