/**
 * checkboxgroup-basic — CheckboxGroup 复选框组基础用法
 * 展示全选控制、分组管理
 * 元服务兼容性：CheckboxGroup 从 API 11+ 可用
 */
@ComponentV2
export struct CheckboxGroupBasic {
  @Local resultLog: string = '等待操作...'
  @Local selectAllValue: boolean = false

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('CheckboxGroup 复选框组')
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

        Text('1. 全选控制')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        // 全选复选框
        Row({ space: 12 }) {
          CheckboxGroup({ group: 'fruits' })
            .selectAll(this.selectAllValue)
            .selectedColor('#007DFF')
            .onChange((status: CheckboxGroupResult) => {
              this.selectAllValue = status.status === SelectStatus.All
              this.resultLog = `全选状态: ${status.status}, 已选: ${JSON.stringify(status.name)}`
            })
          Text('全选/全不选')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
        }
        .width('90%')
        .padding({ left: 16 })

        // 子项
        Row({ space: 12 }) {
          Checkbox({ name: 'apple', group: 'fruits' })
            .selectedColor('#FA2A2D')
          Text('苹果')
            .fontSize(14)
        }
        .width('90%')
        .padding({ left: 32 })

        Row({ space: 12 }) {
          Checkbox({ name: 'banana', group: 'fruits' })
            .selectedColor('#FFEAA7')
          Text('香蕉')
            .fontSize(14)
        }
        .width('90%')
        .padding({ left: 32 })

        Row({ space: 12 }) {
          Checkbox({ name: 'orange', group: 'fruits' })
            .selectedColor('#FF6B00')
          Text('橙子')
            .fontSize(14)
        }
        .width('90%')
        .padding({ left: 32 })

        Text('CheckboxGroup 通过 group 名关联同名 Checkbox')
          .fontSize(12)
          .fontColor('#999999')
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16 })

        // API 说明区
        Column() {
          Text('API 说明')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 8 })
          Text('CheckboxGroup(options?: CheckboxGroupOptions)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('  group?: string — 分组名称，需与 Checkbox.group 一致')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('.selectAll(bool) — 控制全选状态')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('.onChange((status: CheckboxGroupResult) => void)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('CheckboxGroupResult: { status, name[] }')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('元服务API: API 11+')
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
