/**
 * list-group — 分组列表
 * 展示 ListItemGroup 用法：header/footer、divider、sticky 吸顶/吸底
 * 元服务兼容性：ListItemGroup API 9+，sticky API 9+，元服务 API 11+ 可用
 */
interface GroupData {
  title: string
  items: string[]
}

@ComponentV2
export struct ListGroup {
  @Local resultText: string = '分组列表: 4 个分组 | Sticky: Header'
  @Local stickyMode: StickyStyle = StickyStyle.Header
  private groups: GroupData[] = [
    { title: 'A', items: ['Alice', 'Amy', 'Anna'] },
    { title: 'B', items: ['Bob', 'Bill', 'Bella'] },
    { title: 'C', items: ['Charlie', 'Chris', 'Clara', 'Cindy'] },
    { title: 'D', items: ['David', 'Diana', 'Daniel'] },
    { title: 'E', items: ['Emily', 'Eric', 'Eva'] },
  ]

  @Builder
  groupHeader(text: string) {
    Text(text)
      .fontSize(18)
      .fontWeight(FontWeight.Bold)
      .fontColor('#FFFFFF')
      .width('100%')
      .padding({ left: 16, top: 8, bottom: 8 })
      .backgroundColor('#3F51B5')
  }

  @Builder
  groupFooter(count: number) {
    Text(`共 ${count} 人`)
      .fontSize(13)
      .fontColor('#666666')
      .width('100%')
      .textAlign(TextAlign.End)
      .padding({ right: 16, top: 6, bottom: 6 })
      .backgroundColor('#E8EAF6')
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('分组列表')
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
        Text('分组列表预览')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        List({ space: 12 }) {
          ForEach(this.groups, (group: GroupData) => {
            ListItemGroup({
              header: this.groupHeader(group.title),
              footer: this.groupFooter(group.items.length),
              space: 0
            }) {
              ForEach(group.items, (name: string, index?: number) => {
                ListItem() {
                  Row() {
                    Text(name.charAt(0))
                      .fontSize(18)
                      .fontColor('#FFFFFF')
                      .width(36)
                      .height(36)
                      .textAlign(TextAlign.Center)
                      .borderRadius(18)
                      .backgroundColor('#FF5722')

                    Column() {
                      Text(name)
                        .fontSize(16)
                      Text(`联系人 #${(index ?? 0) + 1}`)
                        .fontSize(12)
                        .fontColor('#999999')
                    }
                    .alignItems(HorizontalAlign.Start)
                    .margin({ left: 12 })
                    .layoutWeight(1)
                  }
                  .width('100%')
                  .padding({ left: 16, right: 16, top: 10, bottom: 10 })
                  .backgroundColor('#FFFFFF')
                }
              }, (name: string) => name)
            }
            .divider({ strokeWidth: 0.5, color: '#E0E0E0', startMargin: 64, endMargin: 16 })
          }, (group: GroupData) => group.title)
        }
        .sticky(this.stickyMode)
        .scrollBar(BarState.Auto)
        .width('90%')
        .height(380)
        .borderRadius(8)
        .backgroundColor('#EEEEEE')

        // Sticky 控制
        Text('Sticky 吸顶/吸底')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Row({ space: 8 }) {
          Button('None')
            .fontSize(13)
            .width(65)
            .height(36)
            .onClick(() => {
              this.stickyMode = StickyStyle.None
              this.resultText = '分组列表 | Sticky: 无'
            })
          Button('Header')
            .fontSize(13)
            .width(65)
            .height(36)
            .onClick(() => {
              this.stickyMode = StickyStyle.Header
              this.resultText = '分组列表 | Sticky: 吸顶'
            })
          Button('Footer')
            .fontSize(13)
            .width(65)
            .height(36)
            .onClick(() => {
              this.stickyMode = StickyStyle.Footer
              this.resultText = '分组列表 | Sticky: 吸底'
            })
          Button('Both')
            .fontSize(13)
            .width(65)
            .height(36)
            .onClick(() => {
              this.stickyMode = StickyStyle.Header | StickyStyle.Footer
              this.resultText = '分组列表 | Sticky: 吸顶+吸底'
            })
        }

        // API 说明区
        Column() {
          Text('API 说明')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 8 })
          Text('ListItemGroup({ header?, footer?, space?, style? })')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('.sticky(stickyStyle: StickyStyle) — 设置吸顶/吸底')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('header/footer: CustomBuilder 类型')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('StickyStyle: None / Header / Footer (可组合)')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('ListItemGroup 宽度默认充满 List 组件')
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
}
