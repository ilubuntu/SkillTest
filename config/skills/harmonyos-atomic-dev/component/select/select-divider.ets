/**
 * select-divider — Select 分割线与自定义菜单项
 * 展示 divider（API 12+）、menuItemContentModifier（API 12+）自定义下拉菜单
 * 元服务兼容性：divider / menuItemContentModifier 元服务 API 12+ 可用
 */
import { BusinessError } from '@kit.BasicServicesKit'

@ComponentV2
export struct SelectDivider {
  @Local resultText: string = 'Select 分割线与自定义菜单'
  @Local eventLog: string = '点击 Select 查看效果'

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('Select 分割线与自定义菜单')
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

        // 1. 默认分割线
        Column() {
          Text('1. 默认分割线（不设置 divider）')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .width('100%')
            .margin({ bottom: 8 })

          Select([
            { value: '默认分割线 A' },
            { value: '默认分割线 B' },
            { value: '默认分割线 C' },
            { value: '默认分割线 D' }
          ])
            .selected(0)
            .value('默认分割线')
            .font({ size: 14, weight: FontWeight.Medium })
            .fontColor('#333333')
            .onSelect((index: number, text?: string) => {
              try {
                this.resultText = `[默认] 选中: "${text}" (index: ${index})`
                this.eventLog = `默认分割线选中: ${text}`
              } catch (e) {
                const err = e as BusinessError
                this.eventLog = `错误: ${err.message}`
              }
            })
        }
        .width('90%')
        .padding(12)
        .backgroundColor('#FFFFFF')
        .borderRadius(8)
        .shadow({ radius: 2, color: '#22000000', offsetX: 0, offsetY: 1 })

        // 2. 自定义分割线样式（API 12+）
        Column() {
          Text('2. 自定义分割线样式 divider()（元服务 API 12+）')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .width('100%')
            .margin({ bottom: 8 })

          Select([
            { value: '蓝色粗分割线 A' },
            { value: '蓝色粗分割线 B' },
            { value: '蓝色粗分割线 C' },
            { value: '蓝色粗分割线 D' }
          ])
            .selected(0)
            .value('自定义分割线')
            .font({ size: 14, weight: FontWeight.Medium })
            .fontColor('#333333')
            .divider({
              strokeWidth: 2,
              color: '#2196F3',
              startMargin: 10,
              endMargin: 10
            })
            .onSelect((index: number, text?: string) => {
              try {
                this.resultText = `[自定义分割线] 选中: "${text}"`
                this.eventLog = `自定义分割线选中: ${text}`
              } catch (e) {
                const err = e as BusinessError
                this.eventLog = `错误: ${err.message}`
              }
            })
        }
        .width('90%')
        .padding(12)
        .backgroundColor('#FFFFFF')
        .borderRadius(8)
        .shadow({ radius: 2, color: '#22000000', offsetX: 0, offsetY: 1 })

        // 3. 无分割线（divider(null)）
        Column() {
          Text('3. 无分割线 divider(null)（元服务 API 12+）')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .width('100%')
            .margin({ bottom: 8 })

          Select([
            { value: '无分割线 A' },
            { value: '无分割线 B' },
            { value: '无分割线 C' }
          ])
            .selected(0)
            .value('无分割线')
            .font({ size: 14, weight: FontWeight.Medium })
            .fontColor('#333333')
            .divider(null)
            .onSelect((index: number, text?: string) => {
              try {
                this.resultText = `[无分割线] 选中: "${text}"`
                this.eventLog = `无分割线选中: ${text}`
              } catch (e) {
                const err = e as BusinessError
                this.eventLog = `错误: ${err.message}`
              }
            })
        }
        .width('90%')
        .padding(12)
        .backgroundColor('#FFFFFF')
        .borderRadius(8)
        .shadow({ radius: 2, color: '#22000000', offsetX: 0, offsetY: 1 })

        // 4. 自定义菜单项内容 menuItemContentModifier（API 12+）
        Column() {
          Text('4. 自定义菜单项 menuItemContentModifier（元服务 API 12+）')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .width('100%')
            .margin({ bottom: 8 })

          Select([
            { value: '自定义项 A' },
            { value: '自定义项 B' },
            { value: '自定义项 C' }
          ])
            .selected(0)
            .value('自定义菜单项')
            .font({ size: 14, weight: FontWeight.Medium })
            .fontColor('#333333')
            .menuItemContentModifier(new MySelectItemModifier())
            .onSelect((index: number, text?: string) => {
              try {
                this.resultText = `[自定义菜单] 选中: "${text}"`
                this.eventLog = `自定义菜单选中: ${text}`
              } catch (e) {
                const err = e as BusinessError
                this.eventLog = `错误: ${err.message}`
              }
            })
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
          Text('.divider({ strokeWidth, color, startMargin, endMargin }) — 自定义分割线')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('.divider(null) — 不显示分割线')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('.menuItemContentModifier(modifier) — 自定义下拉菜单项内容')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('ContentModifier<MenuItemConfiguration> 需实现 applyContent() 方法')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('MenuItemConfiguration: value, icon, selected, index, triggerSelect')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('元服务兼容: divider / menuItemContentModifier 元服务 API 12+ 可用')
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

// 自定义菜单项 Modifier
class MySelectItemModifier implements ContentModifier<MenuItemConfiguration> {
  applyContent(): WrappedBuilder<[MenuItemConfiguration]> {
    return wrapBuilder(selectItemBuilder)
  }
}

@Builder
function selectItemBuilder(config: MenuItemConfiguration) {
  Row() {
    Text(config.value)
      .fontSize(14)
      .fontColor(config.selected ? '#1976D2' : '#666666')
      .fontWeight(config.selected ? FontWeight.Bold : FontWeight.Normal)
      .layoutWeight(1)
    if (config.selected) {
      Text('✓')
        .fontSize(16)
        .fontColor('#1976D2')
        .margin({ left: 8 })
    }
  }
  .width('100%')
  .padding({ left: 16, right: 16, top: 10, bottom: 10 })
  .backgroundColor(config.selected ? '#E3F2FD' : Color.Transparent)
  .borderRadius(4)
  .onClick(() => {
    try {
      config.triggerSelect(config.index, config.value.valueOf().toString())
    } catch (e) {
      // ignore
    }
  })
}
