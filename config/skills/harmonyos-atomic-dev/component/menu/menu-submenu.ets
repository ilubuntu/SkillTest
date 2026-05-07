/**
 * menu-submenu — 子菜单用法
 * 展示 MenuItem 的 builder 参数实现二级子菜单
 * 元服务兼容性：MenuItem.builder 从 API 11 起支持元服务
 */
import { BusinessError } from '@kit.BasicServicesKit'

@ComponentV2
export struct MenuSubmenu {
  @Local lastAction: string = '等待操作'

  @Builder
  EditSubMenu() {
    Menu() {
      MenuItem({ content: '撤销', labelInfo: 'Ctrl+Z' })
        .onClick(() => {
          this.lastAction = '子菜单: 撤销'
        })
      MenuItem({ content: '重做', labelInfo: 'Ctrl+Y' })
        .onClick(() => {
          this.lastAction = '子菜单: 重做'
        })
      MenuItem({ content: '查找', labelInfo: 'Ctrl+F' })
        .onClick(() => {
          this.lastAction = '子菜单: 查找'
        })
    }
  }

  @Builder
  ShareSubMenu() {
    Menu() {
      MenuItem({ content: '分享到微信' })
        .onClick(() => {
          this.lastAction = '子菜单: 分享到微信'
        })
      MenuItem({ content: '分享到QQ' })
        .onClick(() => {
          this.lastAction = '子菜单: 分享到QQ'
        })
      MenuItem({ content: '复制链接' })
        .onClick(() => {
          this.lastAction = '子菜单: 复制链接'
        })
    }
  }

  @Builder
  MainMenuBuilder() {
    Menu() {
      MenuItem({ content: '新建' })
        .onClick(() => {
          this.lastAction = '主菜单: 新建'
        })
      MenuItem({ content: '打开' })
        .onClick(() => {
          this.lastAction = '主菜单: 打开'
        })
      MenuItem({
        content: '编辑',
        labelInfo: '▶',
        builder: this.EditSubMenu
      })
      MenuItem({
        content: '分享',
        labelInfo: '▶',
        builder: this.ShareSubMenu
      })
      MenuItemGroup({ header: '文件操作' }) {
        MenuItem({ content: '保存', labelInfo: 'Ctrl+S' })
          .onClick(() => {
            this.lastAction = '主菜单: 保存'
          })
        MenuItem({ content: '另存为' })
          .onClick(() => {
            this.lastAction = '主菜单: 另存为'
          })
      }
    }
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('Menu 子菜单用法')
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

        // 触发子菜单
        Text('带子菜单的自定义菜单')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Button('点击弹出带子菜单')
          .width('90%')
          .height(40)
          .backgroundColor('#007DFF')
          .borderRadius(8)
          .bindMenu(this.MainMenuBuilder)

        // 右键/长按子菜单
        Text('右键弹出带子菜单')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Column() {
          Text('右键点击此区域')
            .fontSize(16)
            .fontColor('#FFFFFF')
        }
        .width('90%')
        .height(100)
        .backgroundColor('#6B4C9A')
        .borderRadius(12)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .bindContextMenu(this.MainMenuBuilder, ResponseType.RightClick)

        // API 说明区
        Column() {
          Text('API 说明')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 8 })
          Text('MenuItem({ builder: CustomBuilder }) — 绑定二级子菜单')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('hover 时自动展开子菜单')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('MenuItemGroup 可与子菜单组合使用')
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
