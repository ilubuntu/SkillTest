/**
 * list-style — 卡片样式
 * 展示 ListItemGroupStyle.CARD / ListItemStyle.CARD 卡片样式
 * 展示 ListItem selected/selectable 选中状态
 * 元服务兼容性：ListItemStyle API 10+，ListItemGroupStyle API 10+，元服务 API 11+ 可用
 */
@ComponentV2
export struct ListStyle {
  @Local useCardStyle: boolean = true
  @Local selectedIndex: number = -1
  @Local resultText: string = '卡片样式: 开启 | 点击列表项选中'

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('卡片样式与选中')
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

        // 列表预览
        Text('卡片样式列表')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        List({ space: this.useCardStyle ? 12 : 2, initialIndex: 0 }) {
          // 分组1
          ListItemGroup({
            style: this.useCardStyle ? ListItemGroupStyle.CARD : ListItemGroupStyle.NONE,
            header: this.groupTitle('常用功能'),
            space: 0
          }) {
            ForEach(['扫一扫', '收付款', '卡包', '出行'], (item: string, index?: number) => {
              ListItem({
                style: this.useCardStyle ? ListItemStyle.CARD : ListItemStyle.NONE
              }) {
                Row() {
                  Text(`${(index ?? 0) + 1}`)
                    .fontSize(16)
                    .fontColor('#FFFFFF')
                    .width(32)
                    .height(32)
                    .textAlign(TextAlign.Center)
                    .borderRadius(16)
                    .backgroundColor('#2196F3')

                  Text(item)
                    .fontSize(15)
                    .margin({ left: 12 })
                    .layoutWeight(1)

                  if ((index ?? 0) === this.selectedIndex) {
                    Text('✓')
                      .fontSize(16)
                      .fontColor('#4CAF50')
                  }
                }
                .width('100%')
                .padding({ left: 16, right: 16, top: 12, bottom: 12 })
              }
              .selectable(true)
              .selected((index ?? 0) === this.selectedIndex)
              .onClick(() => {
                this.selectedIndex = index ?? -1
                this.resultText = `已选中: ${item} (index: ${index})`
              })
            }, (item: string) => item)
          }
          .divider({ strokeWidth: 0.5, color: '#E0E0E0', startMargin: 60, endMargin: 16 })

          // 分组2
          ListItemGroup({
            style: this.useCardStyle ? ListItemGroupStyle.CARD : ListItemGroupStyle.NONE,
            header: this.groupTitle('最近使用'),
            space: 0
          }) {
            ForEach(['转账', '理财产品', '生活缴费', '城市服务', '公益'], (item: string, index?: number) => {
              ListItem({
                style: this.useCardStyle ? ListItemStyle.CARD : ListItemStyle.NONE
              }) {
                Row() {
                  Text(`${(index ?? 0) + 5}`)
                    .fontSize(16)
                    .fontColor('#FFFFFF')
                    .width(32)
                    .height(32)
                    .textAlign(TextAlign.Center)
                    .borderRadius(16)
                    .backgroundColor('#FF9800')

                  Text(item)
                    .fontSize(15)
                    .margin({ left: 12 })
                    .layoutWeight(1)

                  if (((index ?? 0) + 5) === this.selectedIndex) {
                    Text('✓')
                      .fontSize(16)
                      .fontColor('#4CAF50')
                  }
                }
                .width('100%')
                .padding({ left: 16, right: 16, top: 12, bottom: 12 })
              }
              .selectable(true)
              .selected((index ?? 0) + 5 === this.selectedIndex)
              .onClick(() => {
                this.selectedIndex = (index ?? 0) + 5
                this.resultText = `已选中: ${item} (index: ${(index ?? 0) + 5})`
              })
            }, (item: string) => item)
          }
          .divider({ strokeWidth: 0.5, color: '#E0E0E0', startMargin: 60, endMargin: 16 })
        }
        .multiSelectable(false)
        .width('90%')
        .height(400)
        .backgroundColor('#F0F0F0')
        .padding(4)

        // 样式切换
        Text('样式切换')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Row({ space: 8 }) {
          Button('卡片样式')
            .fontSize(13)
            .width(90)
            .height(36)
            .onClick(() => {
              this.useCardStyle = true
              this.resultText = '卡片样式: 开启'
            })
          Button('普通样式')
            .fontSize(13)
            .width(90)
            .height(36)
            .onClick(() => {
              this.useCardStyle = false
              this.resultText = '卡片样式: 关闭'
            })
        }

        // API 说明区
        Column() {
          Text('API 说明')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 8 })
          Text('ListItemGroupStyle: NONE(0) / CARD(1)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('ListItemStyle: NONE(0) / CARD(1)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('.selectable(value: boolean) — 设置是否可框选')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('.selected(value: boolean) — 设置选中状态')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('CARD 样式自动添加圆角和阴影效果')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('元服务：API 11+ 可用')
            .fontSize(12)
            .fontColor('#999999')
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

  @Builder
  groupTitle(text: string) {
    Text(text)
      .fontSize(16)
      .fontWeight(FontWeight.Bold)
      .fontColor('#333333')
      .width('100%')
      .padding({ left: 16, top: 10, bottom: 6 })
  }
}
