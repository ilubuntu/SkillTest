/**
 * menu-basic — Menu 基础用法
 * 展示 bindMenu 绑定默认样式菜单、自定义 Menu+MenuItem+MenuItemGroup 菜单
 * 元服务兼容性：bindMenu / Menu / MenuItem / MenuItemGroup 均从 API 11 起支持元服务
 */
import { BusinessError } from '@kit.BasicServicesKit'

@ComponentV2
export struct MenuBasic {
  @Local lastAction: string = '等待操作'
  @Local menuItemSelected: boolean = false

  @Builder
  CustomMenuBuilder() {
    Menu() {
      MenuItem({ content: '复制', labelInfo: 'Ctrl+C' })
        .onClick(() => {
          this.lastAction = '点击: 复制'
        })
      MenuItem({ content: '粘贴', labelInfo: 'Ctrl+V' })
        .onClick(() => {
          this.lastAction = '点击: 粘贴'
        })
      MenuItem({ content: '剪切' })
        .enabled(false)
        .onClick(() => {
          this.lastAction = '点击: 剪切（已禁用）'
        })
      MenuItemGroup({ header: '编辑操作' }) {
        MenuItem({ content: '全选' })
          .selectIcon(true)
          .selected(this.menuItemSelected)
          .onChange((selected: boolean) => {
            this.menuItemSelected = selected
            this.lastAction = `全选状态: ${selected ? '选中' : '取消'}`
          })
        MenuItem({ content: '查找替换' })
          .onClick(() => {
            this.lastAction = '点击: 查找替换'
          })
      }
      MenuItemGroup({ header: '其他', footer: '更多操作即将推出' }) {
        MenuItem({ content: '分享' })
          .onClick(() => {
            this.lastAction = '点击: 分享'
          })
        MenuItem({ content: '设置' })
          .onClick(() => {
            this.lastAction = '点击: 设置'
          })
      }
    }
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('Menu 菜单基础用法')
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

        // 场景1: bindMenu 默认样式菜单
        Text('bindMenu 默认样式菜单')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Button('点击弹出默认菜单')
          .width('90%')
          .height(40)
          .backgroundColor('#007DFF')
          .borderRadius(8)
          .bindMenu([
            {
              value: '菜单项1',
              action: () => {
                try {
                  this.lastAction = '默认菜单: 菜单项1'
                } catch (err) {
                  let e = err as BusinessError
                  this.lastAction = `错误: ${e.code} - ${e.message}`
                }
              }
            },
            {
              value: '菜单项2',
              action: () => {
                this.lastAction = '默认菜单: 菜单项2'
              }
            },
            {
              value: '菜单项3',
              action: () => {
                this.lastAction = '默认菜单: 菜单项3'
              }
            }
          ])

        // 场景2: bindMenu 自定义 Builder 菜单
        Text('bindMenu 自定义 Builder 菜单')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Button('点击弹出自定义菜单')
          .width('90%')
          .height(40)
          .backgroundColor('#FF6B00')
          .borderRadius(8)
          .bindMenu(this.CustomMenuBuilder)

        // API 说明区
        Column() {
          Text('API 说明')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 8 })
          Text('.bindMenu(MenuElement[]) — 绑定默认样式菜单')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('.bindMenu(CustomBuilder) — 绑定自定义菜单内容')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('Menu { MenuItem MenuItemGroup } — 自定义菜单结构')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('MenuItemGroup({ header, footer }) — 菜单项分组')
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
