/**
 * menu-context — 右键/长按上下文菜单
 * 展示 bindContextMenu 绑定右键、长按触发菜单
 * 元服务兼容性：bindContextMenu 从 API 11 起支持元服务
 */
import { BusinessError } from '@kit.BasicServicesKit'

@ComponentV2
export struct MenuContext {
  @Local lastAction: string = '等待操作'
  @Local pressCount: number = 0

  @Builder
  ContextMenuBuilder() {
    Menu() {
      MenuItem({ content: '刷新页面' })
        .onClick(() => {
          this.lastAction = '右键菜单: 刷新页面'
        })
      MenuItem({ content: '查看源代码' })
        .onClick(() => {
          this.lastAction = '右键菜单: 查看源代码'
        })
      MenuItemGroup({ header: '操作' }) {
        MenuItem({ content: '复制' })
          .onClick(() => {
            this.lastAction = '右键菜单: 复制'
          })
        MenuItem({ content: '粘贴' })
          .onClick(() => {
            this.lastAction = '右键菜单: 粘贴'
          })
      }
      MenuItem({ content: '属性' })
        .onClick(() => {
          this.lastAction = '右键菜单: 属性'
        })
    }
  }

  @Builder
  LongPressMenuBuilder() {
    Menu() {
      MenuItem({ content: '保存图片' })
        .onClick(() => {
          this.lastAction = '长按菜单: 保存图片'
        })
      MenuItem({ content: '分享图片' })
        .onClick(() => {
          this.lastAction = '长按菜单: 分享图片'
        })
      MenuItem({ content: '设为壁纸' })
        .onClick(() => {
          this.lastAction = '长按菜单: 设为壁纸'
        })
    }
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('右键/长按上下文菜单')
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

        // 场景1: 右键菜单
        Text('右键触发菜单 (ResponseType.RightClick)')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Column() {
          Text('在此区域右键点击')
            .fontSize(16)
            .fontColor('#FFFFFF')
            .padding(20)
        }
        .width('90%')
        .height(120)
        .backgroundColor('#007DFF')
        .borderRadius(12)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .bindContextMenu(this.ContextMenuBuilder, ResponseType.RightClick)

        // 场景2: 长按菜单
        Text('长按触发菜单 (ResponseType.LongPress)')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Column() {
          Text('在此区域长按')
            .fontSize(16)
            .fontColor('#FFFFFF')
            .padding(20)
        }
        .width('90%')
        .height(120)
        .backgroundColor('#FF6B00')
        .borderRadius(12)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .bindContextMenu(this.LongPressMenuBuilder, ResponseType.LongPress)

        // 操作计数
        Text(`菜单操作计数: ${this.pressCount}`)
          .fontSize(14)
          .fontColor('#666666')
          .margin({ top: 8 })

        // API 说明区
        Column() {
          Text('API 说明')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 8 })
          Text('.bindContextMenu(builder, ResponseType.RightClick) — 右键触发')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('.bindContextMenu(builder, ResponseType.LongPress) — 长按触发')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('bindContextMenu 菜单在独立子窗口中弹出')
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
