/**
 * rich_editor-controller — RichEditor 控制器操作
 * 展示 RichEditorController 的添加文本段、选区设置等操作
 * 元服务兼容性：API 11+ 可用
 */

import { BusinessError } from '@kit.BasicServicesKit'

@ComponentV2
export struct RichEditorControllerOps {
  @Local resultText: string = '等待操作...'
  @Local spanCount: number = 0
  controller: RichEditorController = new RichEditorController()

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('RichEditor 控制器操作')
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

        // 计数区
        Row() {
          Column() {
            Text(`${this.spanCount}`)
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .fontColor('#2196F3')
            Text('文本段数')
              .fontSize(12)
              .fontColor('#999999')
          }
          .layoutWeight(1)
          .padding(12)
          .backgroundColor('#E3F2FD')
          .borderRadius(8)
        }
        .width('90%')

        // RichEditor 编辑区
        Text('编辑区（先点击按钮添加文本）')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        RichEditor({ controller: this.controller })
          .width('90%')
          .height(180)
          .borderWidth(1)
          .borderColor('#CCCCCC')
          .borderRadius(8)
          .padding(12)
          .onReady(() => {
            this.resultText = '编辑器就绪'
          })

        // 添加操作
        Text('添加操作')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Row({ space: 8 }) {
          Button('追加普通文本')
            .fontSize(13)
            .layoutWeight(1)
            .height(36)
            .onClick(() => {
              try {
                this.controller.addTextSpan(`第${this.spanCount + 1}段文本 `)
                this.spanCount++
                this.resultText = `添加第${this.spanCount}段普通文本`
              } catch (error) {
                const err = error as BusinessError
                this.resultText = `错误: ${err.code} - ${err.message}`
              }
            })
          Button('追加样式文本')
            .fontSize(13)
            .layoutWeight(1)
            .height(36)
            .onClick(() => {
              try {
                const colors: string[] = ['#FF0000', '#2196F3', '#4CAF50', '#FF9800', '#9C27B0']
                const colorIdx: number = this.spanCount % colors.length
                this.controller.addTextSpan(`样式段${this.spanCount + 1} `, {
                  style: {
                    fontColor: colors[colorIdx],
                    fontSize: 18,
                    fontWeight: FontWeight.Bold
                  }
                })
                this.spanCount++
                this.resultText = `添加第${this.spanCount}段彩色文本`
              } catch (error) {
                const err = error as BusinessError
                this.resultText = `错误: ${err.code} - ${err.message}`
              }
            })
        }
        .width('90%')

        // 管理操作
        Text('管理操作')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Row({ space: 8 }) {
          Button('全选文本')
            .fontSize(13)
            .layoutWeight(1)
            .height(36)
            .onClick(() => {
              try {
                this.controller.setSelection(0, -1)
                this.resultText = '已全选文本'
              } catch (error) {
                const err = error as BusinessError
                this.resultText = `错误: ${err.code} - ${err.message}`
              }
            })
          Button('获取选区')
            .fontSize(13)
            .layoutWeight(1)
            .height(36)
            .onClick(() => {
              try {
                const selection: RichEditorSelection = this.controller.getSelection()
                this.resultText = `选区信息已获取，含 ${selection.spans.length} 个span`
              } catch (error) {
                const err = error as BusinessError
                this.resultText = `错误: ${err.code} - ${err.message}`
              }
            })
          Button('清空重置')
            .fontSize(13)
            .layoutWeight(1)
            .height(36)
            .onClick(() => {
              this.controller = new RichEditorController()
              this.spanCount = 0
              this.resultText = '已清空重置'
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
          Text('controller.addTextSpan(text, options?) — 添加文本段')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('controller.setSelection(start, end) — 设置选区')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('controller.getSelection() — 获取当前选区')
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
