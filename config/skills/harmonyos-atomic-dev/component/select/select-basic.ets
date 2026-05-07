/**
 * select-basic — Select 基础下拉选择
 * 展示 Select(options)、selected、value、font/fontColor、onSelect 事件
 * 元服务兼容性：Select / SelectOption / selected / value / font / fontColor / onSelect 元服务 API 11+ 可用
 */
import { BusinessError } from '@kit.BasicServicesKit'

@ComponentV2
export struct SelectBasic {
  @Local selectedIndex: number = 0
  @Local selectValue: string = '请选择'
  @Local resultText: string = '点击下拉菜单选择选项'
  @Local eventLog: string = '等待选择事件...'

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('Select 基础下拉选择')
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

        // 基础 Select
        Column() {
          Text('1. 基础下拉选择')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .width('100%')
            .margin({ bottom: 8 })

          Select([
            { value: '选项一' },
            { value: '选项二' },
            { value: '选项三' },
            { value: '选项四' }
          ])
            .selected(this.selectedIndex)
            .value(this.selectValue)
            .font({ size: 16, weight: 500 })
            .fontColor('#182431')
            .onSelect((index: number, text?: string) => {
              try {
                this.selectedIndex = index
                if (text) {
                  this.selectValue = text
                }
                this.resultText = `[onSelect] 选中索引: ${index}, 值: "${text}"`
                this.eventLog = `选择成功: 第${index + 1}项 "${text}"`
              } catch (e) {
                const err = e as BusinessError
                this.resultText = `onSelect 异常: code=${err.code}, ${err.message}`
              }
            })
        }
        .width('90%')
        .padding(12)
        .backgroundColor('#FFFFFF')
        .borderRadius(8)
        .shadow({ radius: 2, color: '#22000000', offsetX: 0, offsetY: 1 })

        // 带 icon 的 Select
        Column() {
          Text('2. 纯文本下拉选择（多选项对比）')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .width('100%')
            .margin({ bottom: 8 })

          Select([
            { value: '相册' },
            { value: '相机' },
            { value: '文件' }
          ])
            .selected(0)
            .value('选择来源')
            .font({ size: 16, weight: FontWeight.Medium })
            .fontColor('#333333')
            .selectedOptionBgColor('#E3F2FD')
            .selectedOptionFontColor('#1976D2')
            .optionBgColor('#FFFFFF')
            .optionFontColor('#666666')
            .onSelect((index: number, text?: string) => {
              try {
                this.resultText = `[纯文本] 选中: "${text}" (索引: ${index})`
                this.eventLog = `纯文本选择: ${text}`
              } catch (e) {
                const err = e as BusinessError
                this.resultText = `异常: code=${err.code}, ${err.message}`
              }
            })
        }
        .width('90%')
        .padding(12)
        .backgroundColor('#FFFFFF')
        .borderRadius(8)
        .shadow({ radius: 2, color: '#22000000', offsetX: 0, offsetY: 1 })

        // 参数控制区
        Column() {
          Text('手动控制选中项')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .width('100%')
            .margin({ bottom: 8 })

          Row({ space: 8 }) {
            Button('选中第一项')
              .fontSize(12)
              .height(36)
              .onClick(() => {
                try {
                  this.selectedIndex = 0
                  this.selectValue = '选项一'
                  this.eventLog = '手动选中第一项'
                } catch (e) {
                  const err = e as BusinessError
                  this.eventLog = `错误: ${err.message}`
                }
              })
            Button('选中第三项')
              .fontSize(12)
              .height(36)
              .onClick(() => {
                try {
                  this.selectedIndex = 2
                  this.selectValue = '选项三'
                  this.eventLog = '手动选中第三项'
                } catch (e) {
                  const err = e as BusinessError
                  this.eventLog = `错误: ${err.message}`
                }
              })
            Button('重置')
              .fontSize(12)
              .height(36)
              .onClick(() => {
                try {
                  this.selectedIndex = -1
                  this.selectValue = '请选择'
                  this.resultText = '已重置选择'
                  this.eventLog = '已重置'
                } catch (e) {
                  const err = e as BusinessError
                  this.eventLog = `错误: ${err.message}`
                }
              })
          }
        }
        .width('90%')
        .padding(12)
        .backgroundColor('#FFFFFF')
        .borderRadius(8)
        .shadow({ radius: 2, color: '#22000000', offsetX: 0, offsetY: 1 })

        // 事件日志区
        Column() {
          Text(this.eventLog)
            .fontSize(12)
            .fontColor('#666666')
            .width('100%')
            .padding(12)
        }
        .width('90%')
        .backgroundColor('#F0F0F0')
        .borderRadius(8)

        // API 说明区
        Column() {
          Text('API 说明')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 8 })
          Text('Select(options: Array<SelectOption>)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('SelectOption { value: ResourceStr, icon?: ResourceStr }')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('.selected(index) — 设置初始选中项索引，-1 为不选中')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('.value(text) — 设置下拉按钮显示文本')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('.font({ size, weight }) — 设置按钮文本样式')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('.fontColor(color) — 设置按钮文本颜色')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('.onSelect((index, value) => {}) — 选中项回调')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('元服务兼容: Select 全部基础 API 元服务 API 11+ 可用')
            .fontSize(12)
            .fontColor('#4CAF50')
            .width('100%')
            .margin({ top: 4 })
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
