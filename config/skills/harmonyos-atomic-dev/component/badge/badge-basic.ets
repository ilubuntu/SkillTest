/**
 * badge-basic — Badge 基础用法
 * 展示数字标记、文本标记、不同位置、样式自定义
 * 元服务兼容性：Badge(BadgeParamWithNumber) / Badge(BadgeParamWithString) 均从 API 11+ 可用
 */
@ComponentV2
export struct BadgeBasic {
  @Local badgeCount: number = 1
  @Local maxCount: number = 99
  @Local badgeVisible: boolean = true
  @Local resultLog: string = '等待操作...'

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('Badge 徽标基础用法')
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

        // ---- 数字标记 ----
        Text('1. 数字标记 (BadgeParamWithNumber)')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        // 参数控制区
        Row({ space: 12 }) {
          Button(`count: ${this.badgeCount}`)
            .fontSize(13)
            .onClick(() => {
              this.badgeCount = this.badgeCount + 1
              this.resultLog = `count 变为 ${this.badgeCount}`
            })
          Button('重置')
            .fontSize(13)
            .backgroundColor('#999999')
            .onClick(() => {
              this.badgeCount = 0
              this.resultLog = 'count 重置为 0'
            })
          Button(this.badgeVisible ? '隐藏' : '显示')
            .fontSize(13)
            .backgroundColor(this.badgeVisible ? '#FF6B00' : '#00B578')
            .onClick(() => {
              this.badgeVisible = !this.badgeVisible
              this.resultLog = `visible = ${this.badgeVisible}`
            })
        }
        .width('90%')
        .justifyContent(FlexAlign.Center)

        // 数字标记 - RightTop
        Text('RightTop（右上角，默认）')
          .fontSize(13)
          .fontColor('#666666')
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16 })

        if (this.badgeVisible && this.badgeCount > 0) {
          Badge({
            count: this.badgeCount,
            maxCount: this.maxCount,
            position: BadgePosition.RightTop,
            style: { badgeSize: 16, badgeColor: '#FA2A2D' }
          }) {
            Row() {
              Text('消息')
                .fontSize(16)
                .fontColor('#FFFFFF')
            }
            .width(120)
            .height(50)
            .backgroundColor('#007DFF')
            .borderRadius(8)
            .justifyContent(FlexAlign.Center)
          }
        } else {
          Row() {
            Text('消息（标记隐藏）')
              .fontSize(16)
              .fontColor('#FFFFFF')
          }
          .width(120)
          .height(50)
          .backgroundColor('#007DFF')
          .borderRadius(8)
          .justifyContent(FlexAlign.Center)
        }

        // 数字标记 - 超过 maxCount
        Text('超过 maxCount 显示 99+')
          .fontSize(13)
          .fontColor('#666666')
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16 })

        Badge({
          count: 150,
          maxCount: 99,
          position: BadgePosition.RightTop,
          style: { badgeSize: 20, badgeColor: '#FF6B00', fontSize: 12 }
        }) {
          Row() {
            Text('通知')
              .fontSize(16)
              .fontColor('#FFFFFF')
          }
          .width(120)
          .height(50)
          .backgroundColor('#46B1E3')
          .borderRadius(8)
          .justifyContent(FlexAlign.Center)
        }

        // ---- 文本标记 ----
        Text('2. 文本标记 (BadgeParamWithString)')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 12 })

        Badge({
          value: 'NEW',
          position: BadgePosition.Right,
          style: { badgeSize: 20, badgeColor: '#00B578', fontSize: 10 }
        }) {
          Row() {
            Text('功能入口')
              .fontSize(16)
              .fontColor('#333333')
          }
          .width(120)
          .height(50)
          .backgroundColor('#F0F0F0')
          .borderRadius(8)
          .justifyContent(FlexAlign.Center)
        }

        Badge({
          value: 'Hot',
          position: BadgePosition.Left,
          style: { badgeSize: 22, badgeColor: '#FA2A2D', fontSize: 11 }
        }) {
          Row() {
            Text('热门推荐')
              .fontSize(16)
              .fontColor('#333333')
          }
          .width(120)
          .height(50)
          .backgroundColor('#F0F0F0')
          .borderRadius(8)
          .justifyContent(FlexAlign.Center)
        }

        // ---- 样式自定义 ----
        Text('3. 样式自定义')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 12 })

        // 自定义颜色和大小
        Badge({
          count: 5,
          position: BadgePosition.RightTop,
          style: {
            badgeSize: 24,
            badgeColor: '#9B59B6',
            fontSize: 14,
            fontWeight: FontWeight.Bold
          }
        }) {
          Row() {
            Text('紫色大标记')
              .fontSize(16)
              .fontColor('#FFFFFF')
          }
          .width(120)
          .height(50)
          .backgroundColor('#2C3E50')
          .borderRadius(8)
          .justifyContent(FlexAlign.Center)
        }

        // 带描边
        Badge({
          count: 8,
          position: BadgePosition.RightTop,
          style: {
            badgeSize: 20,
            badgeColor: '#FFFFFF',
            fontSize: 12,
            borderColor: '#FF6B00',
            borderWidth: 2
          }
        }) {
          Row() {
            Text('描边标记')
              .fontSize(16)
              .fontColor('#333333')
          }
          .width(120)
          .height(50)
          .backgroundColor('#E8E8E8')
          .borderRadius(8)
          .justifyContent(FlexAlign.Center)
        }

        // ---- 圆点标记 ----
        Text('4. 圆点标记（count <= 0 时自动变为圆点）')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 12 })

        // 用字符串创建圆点效果
        Badge({
          value: '',
          position: BadgePosition.RightTop,
          style: { badgeSize: 8, badgeColor: '#FA2A2D' }
        }) {
          Row() {
            Text('圆点提醒')
              .fontSize(16)
              .fontColor('#333333')
          }
          .width(120)
          .height(50)
          .backgroundColor('#F0F0F0')
          .borderRadius(8)
          .justifyContent(FlexAlign.Center)
        }

        // API 说明区
        Column() {
          Text('API 说明')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 8 })
          Text('Badge(value: BadgeParamWithNumber)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('  count: number — 消息数，<=0 时不显示')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('  maxCount?: number — 最大消息数，默认99，超过显示 maxCount+')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('  position?: BadgePosition — RightTop | Right | Left')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('  style: BadgeStyle — badgeSize/badgeColor/fontSize/fontWeight')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('Badge(value: BadgeParamWithString)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('  value: ResourceStr — 提示文本')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('元服务API: API 11+ | 卡片能力: API 9+')
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
