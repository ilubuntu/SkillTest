/**
 * toggle-basic — Toggle 基础用法
 * 展示三种类型：Checkbox、Switch、Button，以及样式自定义
 * 元服务兼容性：Toggle 从 API 11+ 可用，switchStyle 从 API 12+ 可用
 */
@ComponentV2
export struct ToggleBasic {
  @Local isOn: boolean = false
  @Local switchOn: boolean = false
  @Local buttonOn: boolean = true
  @Local resultLog: string = '等待操作...'

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('Toggle 开关基础用法')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20, bottom: 10 })

        // 结果展示区
        Column() {
          Text(this.resultLog)
            .fontSize(14)
            .fontColor('#333333')
            .width('100%')
            .padding(12)
        }
        .width('90%')
        .backgroundColor('#F5F5F5')
        .borderRadius(8)

        // ---- Checkbox 类型 ----
        Text('1. Checkbox 勾选框样式')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Text('API 11 开始默认为圆形，尺寸 20x20vp')
          .fontSize(12)
          .fontColor('#999999')
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16 })

        Row({ space: 20 }) {
          Toggle({ type: ToggleType.Checkbox, isOn: this.isOn })
            .onChange((isOn: boolean) => {
              this.isOn = isOn
              this.resultLog = `Checkbox 切换为 ${isOn ? '选中' : '未选中'}`
            })
            .selectedColor('#007DFF')

          Text(this.isOn ? '已选中' : '未选中')
            .fontSize(14)
            .fontColor('#333333')
        }
        .width('90%')
        .padding({ left: 16 })

        // ---- Switch 类型 ----
        Text('2. Switch 开关样式（默认）')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 12 })

        Text('默认尺寸 36x20vp')
          .fontSize(12)
          .fontColor('#999999')
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16 })

        Row({ space: 20 }) {
          Toggle({ type: ToggleType.Switch, isOn: this.switchOn })
            .selectedColor('#00B578')
            .switchPointColor('#FFFFFF')
            .onChange((isOn: boolean) => {
              this.switchOn = isOn
              this.resultLog = `Switch 切换为 ${isOn ? '开启' : '关闭'}`
            })

          Text(this.switchOn ? '已开启' : '已关闭')
            .fontSize(14)
            .fontColor('#333333')
        }
        .width('90%')
        .padding({ left: 16 })

        // ---- Button 类型 ----
        Text('3. Button 状态按钮样式')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 12 })

        Text('默认高度 28vp，可包含子组件')
          .fontSize(12)
          .fontColor('#999999')
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16 })

        Row({ space: 20 }) {
          Toggle({ type: ToggleType.Button, isOn: this.buttonOn }) {
            Text(this.buttonOn ? '已启用' : '已禁用')
              .fontSize(14)
              .fontColor('#FFFFFF')
          }
          .selectedColor('#007DFF')
          .onChange((isOn: boolean) => {
            this.buttonOn = isOn
            this.resultLog = `Button 切换为 ${isOn ? '启用' : '禁用'}`
          })
        }
        .width('90%')
        .padding({ left: 16 })

        // ---- 样式自定义 ----
        Text('4. 自定义颜色')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 12 })

        Row({ space: 20 }) {
          Toggle({ type: ToggleType.Switch, isOn: false })
            .selectedColor('#FF6B00')
            .switchPointColor('#FFEECC')

          Text('橙色开关')
            .fontSize(13)
            .fontColor('#666666')
        }
        .width('90%')
        .padding({ left: 16 })

        Row({ space: 20 }) {
          Toggle({ type: ToggleType.Checkbox, isOn: true })
            .selectedColor('#9B59B6')

          Text('紫色勾选')
            .fontSize(13)
            .fontColor('#666666')
        }
        .width('90%')
        .padding({ left: 16 })

        // ---- SwitchStyle (API 12+) ----
        Text('5. SwitchStyle 高级自定义（API 12+）')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 12 })

        Toggle({ type: ToggleType.Switch, isOn: true })
          .switchStyle({
            pointRadius: 8,
            unselectedColor: '#E0E0E0',
            pointColor: '#FFFFFF',
            trackBorderRadius: 12
          })
          .selectedColor('#007DFF')

        Text('pointRadius: 8, trackBorderRadius: 12, unselectedColor: #E0E0E0')
          .fontSize(12)
          .fontColor('#666666')
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16 })

        // API 说明区
        Column() {
          Text('API 说明')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 8 })
          Text('Toggle(options: ToggleOptions)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('  type: ToggleType — Checkbox(0) | Switch(1) | Button(2)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('  isOn?: boolean — 开关状态，支持 $$ 和 !! 双向绑定')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('.selectedColor(color) — 选中状态背景色')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('.switchPointColor(color) — Switch 滑块颜色')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('.switchStyle(SwitchStyle) — Switch 高级样式 (API 12+)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('.onChange((isOn: boolean) => void) — 状态变化回调')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('元服务API: API 11+ | switchStyle: API 12+ | 卡片: API 9+')
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
