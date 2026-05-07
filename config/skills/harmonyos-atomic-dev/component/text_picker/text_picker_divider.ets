/**
 * text_picker_divider — TextPicker 分割线、渐隐效果、循环滚动
 * 展示 divider / gradientHeight / canLoop 属性
 * 元服务兼容性：divider/gradientHeight API 12+，canLoop API 11+
 */
@ComponentV2
export struct TextPickerDivider {
  @Local resultText: string = '当前选中: --'
  @Local eventLog: string = '等待操作...'
  @Local isLoop: boolean = true
  @Local showDivider: boolean = true
  @Local gradientHeightValue: number = 36

  private fruits: string[] = ['apple1', 'orange2', 'peach3', 'grape4', 'banana5']

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('分割线 / 渐隐 / 循环')
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

        // 参数控制区
        Text('参数控制')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        // 循环滚动开关
        Row() {
          Text('循环滚动')
            .fontSize(14)
            .margin({ right: 12 })
          Toggle({ type: ToggleType.Switch, isOn: this.isLoop })
            .onChange((isOn: boolean) => {
              this.isLoop = isOn
              this.eventLog = `canLoop = ${isOn}`
            })
        }
        .width('90%')

        // 分割线开关
        Row() {
          Text('显示分割线')
            .fontSize(14)
            .margin({ right: 12 })
          Toggle({ type: ToggleType.Switch, isOn: this.showDivider })
            .onChange((isOn: boolean) => {
              this.showDivider = isOn
              this.eventLog = `divider = ${isOn ? '默认样式' : 'null'}`
            })
        }
        .width('90%')

        // 渐隐高度选择
        Text('渐隐高度')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 4 })

        Row({ space: 8 }) {
          Button('0vp')
            .fontSize(12)
            .height(36)
            .backgroundColor(this.gradientHeightValue === 0 ? '#007DFF' : '#CCCCCC')
            .onClick(() => {
              this.gradientHeightValue = 0
              this.eventLog = 'gradientHeight = 0 (无渐隐)'
            })
          Button('36vp')
            .fontSize(12)
            .height(36)
            .backgroundColor(this.gradientHeightValue === 36 ? '#007DFF' : '#CCCCCC')
            .onClick(() => {
              this.gradientHeightValue = 36
              this.eventLog = 'gradientHeight = 36 (默认)'
            })
          Button('60vp')
            .fontSize(12)
            .height(36)
            .backgroundColor(this.gradientHeightValue === 60 ? '#007DFF' : '#CCCCCC')
            .onClick(() => {
              this.gradientHeightValue = 60
              this.eventLog = 'gradientHeight = 60'
            })
          Button('100vp')
            .fontSize(12)
            .height(36)
            .backgroundColor(this.gradientHeightValue === 100 ? '#007DFF' : '#CCCCCC')
            .onClick(() => {
              this.gradientHeightValue = 100
              this.eventLog = 'gradientHeight = 100'
            })
        }

        // 选择器展示
        TextPicker({ range: this.fruits, selected: 1 })
          .canLoop(this.isLoop)
          .divider(this.showDivider ? {
            strokeWidth: 2,
            color: '#33000000',
            startMargin: 0,
            endMargin: 0
          } as DividerOptions : null)
          .gradientHeight(this.gradientHeightValue)
          .disappearTextStyle({ color: Color.Red, font: { size: 15, weight: FontWeight.Lighter } })
          .textStyle({ color: Color.Black, font: { size: 20, weight: FontWeight.Normal } })
          .selectedTextStyle({ color: Color.Blue, font: { size: 30, weight: FontWeight.Bolder } })
          .onChange((value: string | string[], index: number | number[]) => {
            try {
              const v = value as string
              const i = index as number
              this.resultText = `当前选中: ${v} (索引 ${i})`
              this.eventLog = `onChange → value: ${v}, index: ${i}`
            } catch (err) {
              this.eventLog = `错误: ${(err as BusinessError).message}`
            }
          })

        // DividerOptions 说明
        Column() {
          Text('DividerOptions 说明')
            .fontSize(13)
            .fontWeight(FontWeight.Medium)
            .width('100%')
            .margin({ bottom: 4 })
          Text('strokeWidth: 分割线宽度 (默认 2px)')
            .fontSize(12)
            .fontColor('#333333')
            .width('100%')
          Text('startMargin: 左侧间距 (默认 0)')
            .fontSize(12)
            .fontColor('#333333')
            .margin({ top: 2 })
            .width('100%')
          Text('endMargin: 右侧间距 (默认 0)')
            .fontSize(12)
            .fontColor('#333333')
            .margin({ top: 2 })
            .width('100%')
          Text('color: 分割线颜色 (默认 #33000000)')
            .fontSize(12)
            .fontColor('#333333')
            .margin({ top: 2 })
            .width('100%')
          Text('divider(null) 可隐藏分割线')
            .fontSize(12)
            .fontColor('#333333')
            .margin({ top: 2 })
            .width('100%')
        }
        .width('90%')
        .backgroundColor('#E3F2FD')
        .borderRadius(8)
        .padding(12)

        // API 说明区
        Column() {
          Text('API 说明')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 8 })
          Text('.canLoop(boolean) — 是否循环滚动 (API 11+)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('.divider(DividerOptions | null) — 分割线样式 (API 12+)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('.gradientHeight(Dimension) — 渐隐高度 (API 12+)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('canLoop 元服务兼容: API 11+')
            .fontSize(12)
            .fontColor('#4CAF50')
            .width('100%')
            .margin({ top: 4 })
          Text('divider / gradientHeight 元服务兼容: API 12+')
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
