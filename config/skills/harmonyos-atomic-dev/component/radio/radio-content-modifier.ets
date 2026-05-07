/**
 * radio-content-modifier — Radio 自定义内容 (contentModifier)
 * 展示 contentModifier 实现完全自定义 Radio 外观和行为
 * 元服务兼容性：contentModifier / RadioConfiguration 元服务 API 12+ 可用
 */
class MyRadioModifier implements ContentModifier<RadioConfiguration> {
  selectedColor: ResourceColor = Color.Blue
  label: string = ''

  constructor(color: ResourceColor, text: string) {
    this.selectedColor = color
    this.label = text
  }

  applyContent(): WrappedBuilder<[RadioConfiguration]> {
    return wrapBuilder(buildRadioContent)
  }
}

@Builder
function buildRadioContent(config: RadioConfiguration) {
  Row({ space: 12 }) {
    Stack() {
      Circle({ width: 40, height: 40 })
        .fill(config.checked ? (config.contentModifier as MyRadioModifier).selectedColor : '#F5F5F5')
        .stroke(config.checked ? (config.contentModifier as MyRadioModifier).selectedColor : '#CCCCCC')
        .strokeWidth(2)
      if (config.checked) {
        Text('✓')
          .fontSize(18)
          .fontColor('#FFFFFF')
          .fontWeight(FontWeight.Bold)
      }
    }
    .width(40)
    .height(40)
    Column({ space: 4 }) {
      Text((config.contentModifier as MyRadioModifier).label)
        .fontSize(16)
        .fontColor(config.checked ? '#333333' : '#999999')
        .fontWeight(config.checked ? FontWeight.Bold : FontWeight.Normal)
      Text(config.value)
        .fontSize(12)
        .fontColor('#999999')
    }
    .alignItems(HorizontalAlign.Start)
    .layoutWeight(1)

    Text(config.checked ? '已选择' : '未选择')
      .fontSize(12)
      .fontColor(config.checked ? '#4CAF50' : '#CCCCCC')
  }
  .width('100%')
  .padding(12)
  .borderRadius(8)
  .backgroundColor(config.checked ? '#F0F7FF' : '#FFFFFF')
  .border({
    width: config.checked ? 2 : 1,
    color: config.checked ? '#2196F3' : '#E0E0E0',
    style: BorderStyle.Solid,
    radius: 8
  })
  .onClick(() => {
    try {
      config.triggerChange(!config.checked)
    } catch (err) {
      console.error('Radio triggerChange error: ' + (err as BusinessError).message)
    }
  })
}

@ComponentV2
export struct RadioContentModifier {
  @Local resultText: string = 'contentModifier 自定义 Radio'
  @Local eventLog: string = '点击卡片式 Radio 切换选中状态'

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('Radio 自定义内容')
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

        // 卡片式 Radio 选择
        Column() {
          Text('场景: 卡片式单选')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .width('100%')
            .margin({ bottom: 12 })

          Column({ space: 10 }) {
            Radio({ value: 'basic', group: 'modifierGroup' })
              .contentModifier(new MyRadioModifier('#2196F3', '基础套餐'))
              .checked(true)
              .width('100%')
              .height(70)
              .onChange((isChecked: boolean) => {
                try {
                  if (isChecked) {
                    this.resultText = '已选择: 基础套餐'
                    this.eventLog = 'onChange(true) → 基础套餐选中'
                  }
                } catch (err) {
                  this.eventLog = `错误: ${(err as BusinessError).message}`
                }
              })

            Radio({ value: 'standard', group: 'modifierGroup' })
              .contentModifier(new MyRadioModifier('#4CAF50', '标准套餐'))
              .checked(false)
              .width('100%')
              .height(70)
              .onChange((isChecked: boolean) => {
                try {
                  if (isChecked) {
                    this.resultText = '已选择: 标准套餐'
                    this.eventLog = 'onChange(true) → 标准套餐选中'
                  }
                } catch (err) {
                  this.eventLog = `错误: ${(err as BusinessError).message}`
                }
              })

            Radio({ value: 'premium', group: 'modifierGroup' })
              .contentModifier(new MyRadioModifier('#FF9800', '高级套餐'))
              .checked(false)
              .width('100%')
              .height(70)
              .onChange((isChecked: boolean) => {
                try {
                  if (isChecked) {
                    this.resultText = '已选择: 高级套餐'
                    this.eventLog = 'onChange(true) → 高级套餐选中'
                  }
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
          Text('contentModifier(modifier: ContentModifier<RadioConfiguration>)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('RadioConfiguration.value: string — 单选框的值')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('RadioConfiguration.checked: boolean — 选中状态')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('RadioConfiguration.triggerChange(bool) — 触发状态变化')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('需自定义 class 实现 ContentModifier<RadioConfiguration> 接口')
            .fontSize(12)
            .fontColor('#FF6B6B')
            .fontFamily('monospace')
            .width('100%')
            .margin({ top: 4 })
          Text('元服务兼容: contentModifier / RadioConfiguration API 12+ 可用')
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
