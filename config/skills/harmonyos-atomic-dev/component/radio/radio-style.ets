/**
 * radio-style — Radio 样式定制
 * 展示 radioStyle 属性设置选中/非选中状态的颜色样式
 * 元服务兼容性：radioStyle / RadioStyle 元服务 API 11+ 可用
 */
@ComponentV2
export struct RadioStyle {
  @Local resultText: string = 'Radio 样式对比展示'
  @Local eventLog: string = '点击 Radio 查看样式变化'

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('Radio 样式定制')
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

        // 1. 默认样式
        Column() {
          Text('1. 默认样式')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .width('100%')
            .margin({ bottom: 8 })

          Row({ space: 24 }) {
            Column({ space: 4 }) {
              Radio({ value: 'Default1', group: 'styleDefault' })
                .checked(true)
                .height(50)
                .width(50)
              Text('选中')
                .fontSize(12)
            }
            Column({ space: 4 }) {
              Radio({ value: 'Default2', group: 'styleDefault' })
                .checked(false)
                .height(50)
                .width(50)
              Text('未选中')
                .fontSize(12)
            }
          }
          .justifyContent(FlexAlign.Center)
        }
        .width('90%')
        .padding(12)
        .backgroundColor('#FFFFFF')
        .borderRadius(8)
        .shadow({ radius: 2, color: '#22000000', offsetX: 0, offsetY: 1 })

        // 2. 自定义选中底板色 (checkedBackgroundColor)
        Column() {
          Text('2. 自定义选中底板色 (checkedBackgroundColor)')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .width('100%')
            .margin({ bottom: 8 })

          Row({ space: 24 }) {
            Column({ space: 4 }) {
              Radio({ value: 'Pink1', group: 'stylePink' })
                .checked(true)
                .height(50)
                .width(50)
                .radioStyle({ checkedBackgroundColor: Color.Pink })
                .onChange((isChecked: boolean) => {
                  this.eventLog = `Pink 选中状态: ${isChecked}`
                })
              Text('Pink')
                .fontSize(12)
            }
            Column({ space: 4 }) {
              Radio({ value: 'Pink2', group: 'stylePink' })
                .checked(false)
                .height(50)
                .width(50)
                .radioStyle({ checkedBackgroundColor: Color.Pink })
                .onChange((isChecked: boolean) => {
                  this.eventLog = `Pink 选中状态: ${isChecked}`
                })
              Text('Pink')
                .fontSize(12)
            }
          }
          .justifyContent(FlexAlign.Center)
        }
        .width('90%')
        .padding(12)
        .backgroundColor('#FFFFFF')
        .borderRadius(8)
        .shadow({ radius: 2, color: '#22000000', offsetX: 0, offsetY: 1 })

        // 3. 自定义未选中描边色 (uncheckedBorderColor)
        Column() {
          Text('3. 自定义未选中描边色 (uncheckedBorderColor)')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .width('100%')
            .margin({ bottom: 8 })

          Row({ space: 24 }) {
            Column({ space: 4 }) {
              Radio({ value: 'Border1', group: 'styleBorder' })
                .checked(true)
                .height(50)
                .width(50)
                .radioStyle({ uncheckedBorderColor: '#FF6B6B' })
                .onChange((isChecked: boolean) => {
                  this.eventLog = `Border 选中: ${isChecked}`
                })
              Text('选中')
                .fontSize(12)
            }
            Column({ space: 4 }) {
              Radio({ value: 'Border2', group: 'styleBorder' })
                .checked(false)
                .height(50)
                .width(50)
                .radioStyle({ uncheckedBorderColor: '#FF6B6B' })
                .onChange((isChecked: boolean) => {
                  this.eventLog = `Border 选中: ${isChecked}`
                })
              Text('未选中')
                .fontSize(12)
            }
          }
          .justifyContent(FlexAlign.Center)
        }
        .width('90%')
        .padding(12)
        .backgroundColor('#FFFFFF')
        .borderRadius(8)
        .shadow({ radius: 2, color: '#22000000', offsetX: 0, offsetY: 1 })

        // 4. 自定义内部指示器颜色 (indicatorColor)
        Column() {
          Text('4. 自定义指示器颜色 (indicatorColor)')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .width('100%')
            .margin({ bottom: 8 })

          Row({ space: 24 }) {
            Column({ space: 4 }) {
              Radio({ value: 'Indicator1', group: 'styleIndicator' })
                .checked(true)
                .height(50)
                .width(50)
                .radioStyle({
                  checkedBackgroundColor: '#2196F3',
                  indicatorColor: '#FFFFFF'
                })
                .onChange((isChecked: boolean) => {
                  this.eventLog = `Indicator 选中: ${isChecked}`
                })
              Text('白指示器')
                .fontSize(12)
            }
            Column({ space: 4 }) {
              Radio({ value: 'Indicator2', group: 'styleIndicator' })
                .checked(false)
                .height(50)
                .width(50)
                .radioStyle({
                  checkedBackgroundColor: '#2196F3',
                  indicatorColor: '#FFFFFF'
                })
                .onChange((isChecked: boolean) => {
                  this.eventLog = `Indicator 选中: ${isChecked}`
                })
              Text('未选中')
                .fontSize(12)
            }
          }
          .justifyContent(FlexAlign.Center)
        }
        .width('90%')
        .padding(12)
        .backgroundColor('#FFFFFF')
        .borderRadius(8)
        .shadow({ radius: 2, color: '#22000000', offsetX: 0, offsetY: 1 })

        // 5. 完整样式组合
        Column() {
          Text('5. 完整样式组合')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .width('100%')
            .margin({ bottom: 8 })

          Row({ space: 16 }) {
            Column({ space: 4 }) {
              Radio({ value: 'Full1', group: 'styleFull' })
                .checked(true)
                .height(50)
                .width(50)
                .radioStyle({
                  checkedBackgroundColor: '#4CAF50',
                  uncheckedBorderColor: '#A5D6A7',
                  indicatorColor: '#FFFFFF'
                })
                .onChange((isChecked: boolean) => {
                  try {
                    this.resultText = `完整样式 Radio1: ${isChecked}`
                    this.eventLog = 'Green 主题选中'
                  } catch (err) {
                    this.eventLog = `错误: ${(err as BusinessError).message}`
                  }
                })
              Text('Green')
                .fontSize(12)
            }
            Column({ space: 4 }) {
              Radio({ value: 'Full2', group: 'styleFull' })
                .checked(false)
                .height(50)
                .width(50)
                .radioStyle({
                  checkedBackgroundColor: '#FF9800',
                  uncheckedBorderColor: '#FFE0B2',
                  indicatorColor: '#FFFFFF'
                })
                .onChange((isChecked: boolean) => {
                  try {
                    this.resultText = `完整样式 Radio2: ${isChecked}`
                    this.eventLog = 'Orange 主题选中'
                  } catch (err) {
                    this.eventLog = `错误: ${(err as BusinessError).message}`
                  }
                })
              Text('Orange')
                .fontSize(12)
            }
          }
          .justifyContent(FlexAlign.Center)
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
          Text('radioStyle(value?: RadioStyle)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('RadioStyle.checkedBackgroundColor: 选中底板色')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('RadioStyle.uncheckedBorderColor: 未选中描边色')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('RadioStyle.indicatorColor: 选中时内部指示器颜色')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('元服务兼容: radioStyle / RadioStyle API 11+ 可用')
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
