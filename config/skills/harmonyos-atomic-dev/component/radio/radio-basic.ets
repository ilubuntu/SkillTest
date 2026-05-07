/**
 * radio-basic — Radio 基础创建与选中状态
 * 展示 Radio 组件的基本创建、group 分组单选、checked 状态控制
 * 元服务兼容性：Radio(options) / checked 属性 元服务 API 11+ 可用
 */
@ComponentV2
export struct RadioBasic {
  @Local radioChecked1: boolean = true
  @Local radioChecked2: boolean = false
  @Local radioChecked3: boolean = false
  @Local resultText: string = '当前选中: Ringing'
  @Local eventLog: string = '点击 Radio 切换选中状态'

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('Radio 基础创建')
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

        // 单选框展示区
        Row({ space: 30 }) {
          Column({ space: 8 }) {
            Radio({ value: 'Ringing', group: 'soundMode' })
              .checked(this.radioChecked1)
              .height(50)
              .width(50)
              .onChange((isChecked: boolean) => {
                try {
                  if (isChecked) {
                    this.radioChecked1 = true
                    this.radioChecked2 = false
                    this.radioChecked3 = false
                    this.resultText = '当前选中: Ringing'
                    this.eventLog = '切换到响铃模式'
                  }
                } catch (err) {
                  this.eventLog = `错误: ${(err as BusinessError).message}`
                }
              })
            Text('Ringing')
              .fontSize(13)
          }

          Column({ space: 8 }) {
            Radio({ value: 'Vibration', group: 'soundMode' })
              .checked(this.radioChecked2)
              .height(50)
              .width(50)
              .onChange((isChecked: boolean) => {
                try {
                  if (isChecked) {
                    this.radioChecked1 = false
                    this.radioChecked2 = true
                    this.radioChecked3 = false
                    this.resultText = '当前选中: Vibration'
                    this.eventLog = '切换到振动模式'
                  }
                } catch (err) {
                  this.eventLog = `错误: ${(err as BusinessError).message}`
                }
              })
            Text('Vibration')
              .fontSize(13)
          }

          Column({ space: 8 }) {
            Radio({ value: 'Silent', group: 'soundMode' })
              .checked(this.radioChecked3)
              .height(50)
              .width(50)
              .onChange((isChecked: boolean) => {
                try {
                  if (isChecked) {
                    this.radioChecked1 = false
                    this.radioChecked2 = false
                    this.radioChecked3 = true
                    this.resultText = '当前选中: Silent'
                    this.eventLog = '切换到静音模式'
                  }
                } catch (err) {
                  this.eventLog = `错误: ${(err as BusinessError).message}`
                }
              })
            Text('Silent')
              .fontSize(13)
          }
        }
        .justifyContent(FlexAlign.Center)
        .width('90%')
        .padding(16)
        .backgroundColor('#FFFFFF')
        .borderRadius(8)
        .shadow({ radius: 2, color: '#22000000', offsetX: 0, offsetY: 1 })

        // 参数控制区
        Column() {
          Text('手动切换选中')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .width('100%')
            .margin({ bottom: 8 })

          Row({ space: 8 }) {
            Button('选中 Ringing')
              .fontSize(12)
              .height(36)
              .onClick(() => {
                try {
                  this.radioChecked1 = true
                  this.radioChecked2 = false
                  this.radioChecked3 = false
                  this.resultText = '当前选中: Ringing'
                  this.eventLog = '手动切换到 Ringing'
                } catch (err) {
                  this.eventLog = `错误: ${(err as BusinessError).message}`
                }
              })

            Button('选中 Vibration')
              .fontSize(12)
              .height(36)
              .onClick(() => {
                try {
                  this.radioChecked1 = false
                  this.radioChecked2 = true
                  this.radioChecked3 = false
                  this.resultText = '当前选中: Vibration'
                  this.eventLog = '手动切换到 Vibration'
                } catch (err) {
                  this.eventLog = `错误: ${(err as BusinessError).message}`
                }
              })

            Button('选中 Silent')
              .fontSize(12)
              .height(36)
              .onClick(() => {
                try {
                  this.radioChecked1 = false
                  this.radioChecked2 = false
                  this.radioChecked3 = true
                  this.resultText = '当前选中: Silent'
                  this.eventLog = '手动切换到 Silent'
                } catch (err) {
                  this.eventLog = `错误: ${(err as BusinessError).message}`
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
          Text('Radio(options: RadioOptions)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('RadioOptions.value: string — 单选框的值')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('RadioOptions.group: string — 所属群组，同组仅一个可选中')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('checked(value: boolean) — 设置选中状态，默认 false')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('元服务兼容: Radio / value / group / checked API 11+ 可用')
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
