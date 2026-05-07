/**
 * menu-item-style — MenuItem 样式自定义
 * 展示 MenuItem 的 selected、selectIcon、contentFont、contentFontColor、labelFont、labelFontColor 属性
 * 元服务兼容性：所有 MenuItem 样式属性均从 API 11 起支持元服务
 */
import { BusinessError } from '@kit.BasicServicesKit'

@ComponentV2
export struct MenuItemStyle {
  @Local lastAction: string = '等待操作'
  @Local isSelectedA: boolean = false
  @Local isSelectedB: boolean = true
  @Local isSelectedC: boolean = false
  @Local fontColorMode: number = 0

  @Builder
  StyledMenuBuilder() {
    Menu() {
      MenuItem({ content: '默认样式菜单项' })
        .onClick(() => {
          this.lastAction = '点击: 默认样式'
        })

      MenuItem({ content: '自定义字体颜色', labelInfo: 'Ctrl+X' })
        .contentFontColor(this.fontColorMode === 0 ? '#E5000000' :
        this.fontColorMode === 1 ? '#007DFF' : '#FF0000')
        .labelFontColor(this.fontColorMode === 0 ? '#99000000' : '#00B578')
        .onClick(() => {
          this.lastAction = '点击: 自定义字体颜色'
        })

      MenuItem({ content: '自定义字体大小', labelInfo: 'F1' })
        .contentFont({ size: 18, weight: FontWeight.Bold })
        .labelFont({ size: 10 })
        .onClick(() => {
          this.lastAction = '点击: 自定义字体大小'
        })

      MenuItem({ content: '可选菜单项 A' })
        .selectIcon(true)
        .selected(this.isSelectedA)
        .onChange((selected: boolean) => {
          this.isSelectedA = selected
          this.lastAction = `菜单项A: ${selected ? '已选中' : '已取消'}`
        })

      MenuItem({ content: '可选菜单项 B' })
        .selectIcon(true)
        .selected(this.isSelectedB)
        .onChange((selected: boolean) => {
          this.isSelectedB = selected
          this.lastAction = `菜单项B: ${selected ? '已选中' : '已取消'}`
        })

      MenuItem({ content: '可选菜单项 C' })
        .selectIcon(true)
        .selected(this.isSelectedC)
        .onChange((selected: boolean) => {
          this.isSelectedC = selected
          this.lastAction = `菜单项C: ${selected ? '已选中' : '已取消'}`
        })

      MenuItem({ content: '禁用菜单项' })
        .enabled(false)
    }
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('MenuItem 样式自定义')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20, bottom: 10 })

        // 结果展示区
        Column() {
          Text(this.lastAction)
            .fontSize(14)
            .fontColor('#333333')
            .width('100%')
            .padding(12)
        }
        .width('90%')
        .backgroundColor('#F5F5F5')
        .borderRadius(8)

        // 触发菜单
        Button('点击查看样式化菜单')
          .width('90%')
          .height(40)
          .backgroundColor('#007DFF')
          .borderRadius(8)
          .bindMenu(this.StyledMenuBuilder)

        // 字体颜色切换
        Text('切换字体颜色模式')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Row({ space: 8 }) {
          Button('默认')
            .type(ButtonType.Normal)
            .width(60)
            .height(36)
            .borderRadius(8)
            .backgroundColor(this.fontColorMode === 0 ? '#007DFF' : '#CCCCCC')
            .fontColor(this.fontColorMode === 0 ? '#FFFFFF' : '#333333')
            .onClick(() => {
              try {
                this.fontColorMode = 0
                this.lastAction = '字体颜色: 默认'
              } catch (err) {
                let e = err as BusinessError
                this.lastAction = `错误: ${e.code}`
              }
            })
          Button('蓝色主题')
            .type(ButtonType.Normal)
            .width(80)
            .height(36)
            .borderRadius(8)
            .backgroundColor(this.fontColorMode === 1 ? '#007DFF' : '#CCCCCC')
            .fontColor(this.fontColorMode === 1 ? '#FFFFFF' : '#333333')
            .onClick(() => {
              this.fontColorMode = 1
              this.lastAction = '字体颜色: 蓝色主题'
            })
          Button('红色主题')
            .type(ButtonType.Normal)
            .width(80)
            .height(36)
            .borderRadius(8)
            .backgroundColor(this.fontColorMode === 2 ? '#FF0000' : '#CCCCCC')
            .fontColor(this.fontColorMode === 2 ? '#FFFFFF' : '#333333')
            .onClick(() => {
              this.fontColorMode = 2
              this.lastAction = '字体颜色: 红色主题'
            })
        }
        .width('90%')
        .justifyContent(FlexAlign.SpaceAround)

        // 选中状态展示
        Text('选中状态')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Row({ space: 12 }) {
          Text(`A: ${this.isSelectedA ? '✓' : '✗'}`).fontSize(14).fontColor(this.isSelectedA ? '#00B578' : '#999999')
          Text(`B: ${this.isSelectedB ? '✓' : '✗'}`).fontSize(14).fontColor(this.isSelectedB ? '#00B578' : '#999999')
          Text(`C: ${this.isSelectedC ? '✓' : '✗'}`).fontSize(14).fontColor(this.isSelectedC ? '#00B578' : '#999999')
        }

        // API 说明区
        Column() {
          Text('API 说明')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 8 })
          Text('.selected(boolean) — 设置选中状态，支持双向绑定')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('.selectIcon(boolean|ResourceStr) — 显示选中图标')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('.contentFont(Font) — 内容字体样式')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('.contentFontColor(ResourceColor) — 内容字体颜色')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('.labelFont(Font) — 标签字体样式')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('.labelFontColor(ResourceColor) — 标签字体颜色')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('.onChange(callback) — 选中状态变化回调')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('元服务支持: API 11+')
            .fontSize(12)
            .fontColor('#999999')
            .fontFamily('monospace')
            .width('100%')
        }
        .width('90%')
        .backgroundColor('#FFF9E6')
        .borderRadius(8)
        .padding(12)
        .margin({ top: 8 })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
  }
}
