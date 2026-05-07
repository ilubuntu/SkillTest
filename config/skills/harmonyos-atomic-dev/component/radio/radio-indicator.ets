/**
 * radio-indicator — Radio 指示器样式
 * 展示 indicatorType (TICK/DOT/CUSTOM) 和 indicatorBuilder 自定义选中样式
 * 元服务兼容性：indicatorType / indicatorBuilder / RadioIndicatorType 元服务 API 12+ 可用
 */
@ComponentV2
export struct RadioIndicator {
  @Local resultText: string = 'Radio 指示器样式对比'
  @Local eventLog: string = '点击 Radio 切换选中状态'

  @Builder
  indicatorBuilder() {
    Text('✓')
      .fontSize(20)
      .fontColor('#FFFFFF')
      .fontWeight(FontWeight.Bold)
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('Radio 指示器样式')
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

        // 1. TICK 指示器 (API 12+ 默认)
        Column() {
          Text('1. TICK 指示器 (API 12+ 默认样式)')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .width('100%')
            .margin({ bottom: 8 })

          Row({ space: 24 }) {
            Column({ space: 4 }) {
              Radio({ value: 'Tick1', group: 'indicatorTick', indicatorType: RadioIndicatorType.TICK })
                .checked(true)
                .height(50)
                .width(50)
                .onChange((isChecked: boolean) => {
                  try {
                    this.eventLog = `TICK Radio1: ${isChecked}`
                    this.resultText = `TICK 组 - Radio1 ${isChecked ? '选中' : '未选中'}`
                  } catch (err) {
                    this.eventLog = `错误: ${(err as BusinessError).message}`
                  }
                })
              Text('选中')
                .fontSize(12)
            }
            Column({ space: 4 }) {
              Radio({ value: 'Tick2', group: 'indicatorTick', indicatorType: RadioIndicatorType.TICK })
                .checked(false)
                .height(50)
                .width(50)
                .onChange((isChecked: boolean) => {
                  try {
                    this.eventLog = `TICK Radio2: ${isChecked}`
                    this.resultText = `TICK 组 - Radio2 ${isChecked ? '选中' : '未选中'}`
                  } catch (err) {
                    this.eventLog = `错误: ${(err as BusinessError).message}`
                  }
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

        // 2. DOT 指示器 (API 8-11 默认)
        Column() {
          Text('2. DOT 指示器 (API 8~11 默认样式)')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .width('100%')
            .margin({ bottom: 8 })

          Row({ space: 24 }) {
            Column({ space: 4 }) {
              Radio({ value: 'Dot1', group: 'indicatorDot', indicatorType: RadioIndicatorType.DOT })
                .checked(true)
                .height(50)
                .width(50)
                .onChange((isChecked: boolean) => {
                  try {
                    this.eventLog = `DOT Radio1: ${isChecked}`
                    this.resultText = `DOT 组 - Radio1 ${isChecked ? '选中' : '未选中'}`
                  } catch (err) {
                    this.eventLog = `错误: ${(err as BusinessError).message}`
                  }
                })
              Text('选中')
                .fontSize(12)
            }
            Column({ space: 4 }) {
              Radio({ value: 'Dot2', group: 'indicatorDot', indicatorType: RadioIndicatorType.DOT })
                .checked(false)
                .height(50)
                .width(50)
                .onChange((isChecked: boolean) => {
                  try {
                    this.eventLog = `DOT Radio2: ${isChecked}`
                    this.resultText = `DOT 组 - Radio2 ${isChecked ? '选中' : '未选中'}`
                  } catch (err) {
                    this.eventLog = `错误: ${(err as BusinessError).message}`
                  }
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

        // 3. CUSTOM 指示器
        Column() {
          Text('3. CUSTOM 自定义指示器')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .width('100%')
            .margin({ bottom: 8 })

          Row({ space: 24 }) {
            Column({ space: 4 }) {
              Radio({
                value: 'Custom1',
                group: 'indicatorCustom',
                indicatorType: RadioIndicatorType.CUSTOM,
                indicatorBuilder: () => { this.indicatorBuilder() }
              })
                .checked(true)
                .height(50)
                .width(50)
                .onChange((isChecked: boolean) => {
                  try {
                    this.eventLog = `CUSTOM Radio1: ${isChecked}`
                    this.resultText = `CUSTOM 组 - Radio1 ${isChecked ? '选中' : '未选中'}`
                  } catch (err) {
                    this.eventLog = `错误: ${(err as BusinessError).message}`
                  }
                })
              Text('选中')
                .fontSize(12)
            }
            Column({ space: 4 }) {
              Radio({
                value: 'Custom2',
                group: 'indicatorCustom',
                indicatorType: RadioIndicatorType.CUSTOM,
                indicatorBuilder: () => { this.indicatorBuilder() }
              })
                .checked(false)
                .height(50)
                .width(50)
                .onChange((isChecked: boolean) => {
                  try {
                    this.eventLog = `CUSTOM Radio2: ${isChecked}`
                    this.resultText = `CUSTOM 组 - Radio2 ${isChecked ? '选中' : '未选中'}`
                  } catch (err) {
                    this.eventLog = `错误: ${(err as BusinessError).message}`
                  }
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

        // 4. CUSTOM + radioStyle 组合
        Column() {
          Text('4. CUSTOM 指示器 + 样式组合')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .width('100%')
            .margin({ bottom: 8 })

          Row({ space: 24 }) {
            Column({ space: 4 }) {
              Radio({
                value: 'Combo1',
                group: 'indicatorCombo',
                indicatorType: RadioIndicatorType.CUSTOM,
                indicatorBuilder: () => { this.indicatorBuilder() }
              })
                .checked(true)
                .height(50)
                .width(50)
                .radioStyle({
                  checkedBackgroundColor: '#9C27B0',
                  uncheckedBorderColor: '#CE93D8',
                  indicatorColor: '#FFFFFF'
                })
                .onChange((isChecked: boolean) => {
                  try {
                    this.eventLog = `Combo Radio1: ${isChecked}`
                    this.resultText = `Combo 组 - Radio1 ${isChecked ? '选中' : '未选中'}`
                  } catch (err) {
                    this.eventLog = `错误: ${(err as BusinessError).message}`
                  }
                })
              Text('选中')
                .fontSize(12)
            }
            Column({ space: 4 }) {
              Radio({
                value: 'Combo2',
                group: 'indicatorCombo',
                indicatorType: RadioIndicatorType.CUSTOM,
                indicatorBuilder: () => { this.indicatorBuilder() }
              })
                .checked(false)
                .height(50)
                .width(50)
                .radioStyle({
                  checkedBackgroundColor: '#9C27B0',
                  uncheckedBorderColor: '#CE93D8',
                  indicatorColor: '#FFFFFF'
                })
                .onChange((isChecked: boolean) => {
                  try {
                    this.eventLog = `Combo Radio2: ${isChecked}`
                    this.resultText = `Combo 组 - Radio2 ${isChecked ? '选中' : '未选中'}`
                  } catch (err) {
                    this.eventLog = `错误: ${(err as BusinessError).message}`
                  }
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
          Text('indicatorType: RadioIndicatorType 枚举')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('  TICK (0) — 系统默认 TICK 图标 (API 12+ 默认)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('  DOT (1) — 系统默认 DOT 图标 (API 8~11 默认)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('  CUSTOM (2) — indicatorBuilder 自定义内容')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('indicatorBuilder: CustomBuilder — 自定义选中指示器组件')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('注意: CUSTOM 模式下 indicatorColor 不生效')
            .fontSize(12)
            .fontColor('#FF6B6B')
            .fontFamily('monospace')
            .width('100%')
            .margin({ top: 4 })
          Text('元服务兼容: indicatorType / indicatorBuilder API 12+ 可用')
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
