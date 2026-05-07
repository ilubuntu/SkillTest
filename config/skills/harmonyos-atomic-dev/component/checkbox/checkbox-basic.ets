/**
 * checkbox-basic — Checkbox 复选框基础用法
 * 展示单选、分组、样式自定义
 * 元服务兼容性：Checkbox 从 API 11+ 可用
 */
@ComponentV2
export struct CheckboxBasic {
  @Local resultLog: string = '等待操作...'
  @Local isChecked1: boolean = false
  @Local isChecked2: boolean = true
  @Local isChecked3: boolean = false

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('Checkbox 复选框基础用法')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20, bottom: 10 })

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

        Text('1. 基础复选框')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Row({ space: 12 }) {
          Checkbox()
            .select(this.isChecked1)
            .onChange((value: boolean) => {
              this.isChecked1 = value
              this.resultLog = `Checkbox1: ${value}`
            })
          Text('未选中项')
            .fontSize(14)
        }
        .width('90%')
        .padding({ left: 16 })

        Row({ space: 12 }) {
          Checkbox()
            .select(this.isChecked2)
            .selectedColor('#007DFF')
            .onChange((value: boolean) => {
              this.isChecked2 = value
              this.resultLog = `Checkbox2: ${value}`
            })
          Text('已选中（蓝色）')
            .fontSize(14)
        }
        .width('90%')
        .padding({ left: 16 })

        Text('2. 自定义样式')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 12 })

        Row({ space: 12 }) {
          Checkbox()
            .select(true)
            .selectedColor('#FF6B00')
            .unselectedColor('#E0E0E0')
            .mark({
              strokeColor: '#FFFFFF',
              size: 12
            })
          Text('橙色 + 自定义勾')
            .fontSize(14)
        }
        .width('90%')
        .padding({ left: 16 })

        Row({ space: 12 }) {
          Checkbox()
            .select(true)
            .selectedColor('#9B59B6')
          Text('紫色')
            .fontSize(14)
        }
        .width('90%')
        .padding({ left: 16 })

        Text('3. 带 name/group（配合 CheckboxGroup）')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 12 })

        Row({ space: 12 }) {
          Checkbox({ name: 'item1', group: 'group1' })
            .select(this.isChecked1)
            .onChange((value: boolean) => {
              this.resultLog = `item1: ${value}`
            })
          Text('选项A')
            .fontSize(14)
        }
        .width('90%')
        .padding({ left: 16 })

        Row({ space: 12 }) {
          Checkbox({ name: 'item2', group: 'group1' })
            .select(this.isChecked3)
            .onChange((value: boolean) => {
              this.resultLog = `item2: ${value}`
            })
          Text('选项B')
            .fontSize(14)
        }
        .width('90%')
        .padding({ left: 16 })

        // API 说明区
        Column() {
          Text('API 说明')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 8 })
          Text('Checkbox(options?: CheckboxOptions)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('  name?: string — 名称, group?: string — 分组名')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('.select(bool) — 选中状态，支持 $$ 双向绑定')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('.selectedColor() / .unselectedColor() / .mark(MarkStyle)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('元服务API: API 11+ | shape/contentModifier: API 12+')
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
