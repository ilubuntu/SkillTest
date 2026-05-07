/**
 * list-basic — 基础垂直列表
 * 展示 List + ListItem + ForEach 基础用法、space 参数、动态增删
 * 元服务兼容性：List API 7+，ListItem API 10+，元服务 API 11+ 可用
 */
@ComponentV2
export struct ListBasic {
  @Local dataList: string[] = ['北京', '上海', '广州', '深圳', '杭州', '成都', '武汉', '南京']
  @Local resultText: string = '列表项数: 8'
  @Local currentSpace: number = 10

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('基础垂直列表')
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
        Text('列表预览')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        List({ space: this.currentSpace }) {
          ForEach(this.dataList, (item: string, index?: number) => {
            ListItem() {
              Row() {
                Text(`${(index ?? 0) + 1}`)
                  .fontSize(16)
                  .fontColor('#FFFFFF')
                  .width(32)
                  .height(32)
                  .textAlign(TextAlign.Center)
                  .borderRadius(16)
                  .backgroundColor('#4CAF50')

                Text(item)
                  .fontSize(16)
                  .margin({ left: 12 })
                  .layoutWeight(1)

                Text('>')
                  .fontSize(14)
                  .fontColor('#999999')
              }
              .width('100%')
              .padding({ left: 16, right: 16, top: 12, bottom: 12 })
              .backgroundColor('#FFFFFF')
              .borderRadius(8)
            }
          }, (item: string, index?: number) => `${item}_${index}`)
        }
        .width('90%')
        .height(320)
        .borderRadius(8)
        .backgroundColor('#F0F0F0')
        .padding(8)

        // 操作按钮
        Text('操作')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Row({ space: 8 }) {
          Button('添加项')
            .fontSize(13)
            .width(80)
            .height(36)
            .onClick(() => {
              const cities = ['西安', '重庆', '天津', '苏州', '长沙', '郑州']
              const newItem = cities[this.dataList.length % cities.length]
              this.dataList = [...this.dataList, newItem]
              this.resultText = `添加成功，当前 ${this.dataList.length} 项`
            })
          Button('删除末项')
            .fontSize(13)
            .width(80)
            .height(36)
            .onClick(() => {
              if (this.dataList.length > 0) {
                this.dataList = this.dataList.slice(0, -1)
                this.resultText = `删除成功，当前 ${this.dataList.length} 项`
              } else {
                this.resultText = '列表已空'
              }
            })
          Button('重置')
            .fontSize(13)
            .width(80)
            .height(36)
            .onClick(() => {
              this.dataList = ['北京', '上海', '广州', '深圳', '杭州', '成都', '武汉', '南京']
              this.resultText = '列表已重置，共 8 项'
            })
        }

        // 间距控制
        Text('列表间距')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Row({ space: 8 }) {
          Button('0')
            .fontSize(13)
            .width(50)
            .height(36)
            .onClick(() => { this.currentSpace = 0 })
          Button('10')
            .fontSize(13)
            .width(50)
            .height(36)
            .onClick(() => { this.currentSpace = 10 })
          Button('20')
            .fontSize(13)
            .width(50)
            .height(36)
            .onClick(() => { this.currentSpace = 20 })
        }

        // API 说明区
        Column() {
          Text('API 说明')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 8 })
          Text('List({ space?: number, initialIndex?: number, scroller?: ListScroller })')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('ListItem() — 列表项容器，只能包含单个子组件')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('ForEach(data, itemGenerator, keyGenerator) — 循环渲染')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('space: 列表项主轴间距，默认 0')
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
