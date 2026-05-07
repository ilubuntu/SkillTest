/**
 * panel-basic — Panel 可滑动面板基础用法
 * 展示三种面板类型 (Foldable / Minibar / Temporary)、mode 切换、拖拽条控制、高度自定义
 * 元服务兼容性：Panel 从 API 7+ 可用，核心属性均支持
 */
import { BusinessError } from '@kit.BasicServicesKit'

@ComponentV2
export struct PanelBasic {
  @Local resultLog: string = '等待操作...'
  @Local panelModeValue: PanelMode = PanelMode.Half
  @Local dragBarVisible: boolean = true
  @Local halfHeightValue: number = 300
  @Local fullHeightValue: number = 500
  @Local miniHeightValue: number = 48
  @Local currentModeText: string = 'Half'

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('Panel 可滑动面板')
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

        // ---- 1. Foldable 面板（三段式） ----
        Text('1. Foldable 三段式面板')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Text('支持 Mini / Half / Full 三种尺寸切换，内容永久展示')
          .fontSize(12)
          .fontColor('#666666')
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16 })

        Button('显示 Foldable 面板')
          .width('80%')
          .onClick(() => {
            try {
              this.resultLog = 'Foldable 面板已弹出，可拖拽切换尺寸'
            } catch (err) {
              const e = err as BusinessError
              this.resultLog = `错误: ${e.code} - ${e.message}`
            }
          })

        Panel(undefined) {
          Column({ space: 12 }) {
            Text('Foldable 面板内容')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
            Text('支持 Mini / Half / Full 三种尺寸')
              .fontSize(14)
              .fontColor('#666666')
            Text('拖拽顶部横条可切换尺寸')
              .fontSize(14)
              .fontColor('#999999')
          }
          .width('100%')
          .padding(16)
          .alignItems(HorizontalAlign.Center)
        }
        .type(PanelType.Foldable)
        .mode(PanelMode.Half)
        .dragBar(true)
        .halfHeight(300)
        .fullHeight(500)
        .miniHeight(48)
        .onChange((width: number, height: number, mode: PanelMode) => {
          const modeStr = mode === PanelMode.Mini ? 'Mini' : mode === PanelMode.Half ? 'Half' : 'Full'
          this.currentModeText = modeStr
          this.resultLog = `Foldable 面板变化: ${modeStr}, 宽=${width}, 高=${height}`
        })

        // ---- 2. Minibar 面板 ----
        Text('2. Minibar 面板')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 12 })

        Text('提供 minibar 和类全屏展示切换效果')
          .fontSize(12)
          .fontColor('#666666')
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16 })

        Button('显示 Minibar 面板')
          .width('80%')
          .onClick(() => {
            try {
              this.resultLog = 'Minibar 面板已弹出'
            } catch (err) {
              const e = err as BusinessError
              this.resultLog = `错误: ${e.code} - ${e.message}`
            }
          })

        Panel(undefined) {
          Column({ space: 12 }) {
            Text('Minibar 面板内容')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
            Text('提供 minibar 和全屏两种展示状态')
              .fontSize(14)
              .fontColor('#666666')
          }
          .width('100%')
          .padding(16)
          .alignItems(HorizontalAlign.Center)
        }
        .type(PanelType.Minibar)
        .mode(PanelMode.Mini)
        .dragBar(true)
        .onChange((width: number, height: number, mode: PanelMode) => {
          const modeStr = mode === PanelMode.Mini ? 'Mini' : mode === PanelMode.Half ? 'Half' : 'Full'
          this.resultLog = `Minibar 面板变化: ${modeStr}, 宽=${width}, 高=${height}`
        })

        // ---- 3. Temporary 面板 ----
        Text('3. Temporary 临时面板')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 12 })

        Text('临时展示内容，提供 Half / Full 两种尺寸')
          .fontSize(12)
          .fontColor('#666666')
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16 })

        Button('显示 Temporary 面板')
          .width('80%')
          .onClick(() => {
            try {
              this.resultLog = 'Temporary 面板已弹出'
            } catch (err) {
              const e = err as BusinessError
              this.resultLog = `错误: ${e.code} - ${e.message}`
            }
          })

        Panel(undefined) {
          Column({ space: 12 }) {
            Text('Temporary 面板内容')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
            Text('仅支持 Half 和 Full 两种尺寸')
              .fontSize(14)
              .fontColor('#666666')
            Text('Mini 模式对 Temporary 类型不生效')
              .fontSize(14)
              .fontColor('#FF6B00')
          }
          .width('100%')
          .padding(16)
          .alignItems(HorizontalAlign.Center)
        }
        .type(PanelType.Temporary)
        .mode(PanelMode.Half)
        .dragBar(true)
        .halfHeight(300)
        .fullHeight(500)
        .onChange((width: number, height: number, mode: PanelMode) => {
          const modeStr = mode === PanelMode.Mini ? 'Mini' : mode === PanelMode.Half ? 'Half' : 'Full'
          this.resultLog = `Temporary 面板变化: ${modeStr}, 宽=${width}, 高=${height}`
        })

        // ---- 4. dragBar 控制与高度自定义 ----
        Text('4. dragBar 控制与高度自定义')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 12 })

        // 参数控制区
        Row({ space: 12 }) {
          Button(this.dragBarVisible ? '隐藏 dragBar' : '显示 dragBar')
            .fontSize(12)
            .onClick(() => {
              this.dragBarVisible = !this.dragBarVisible
              this.resultLog = `dragBar: ${this.dragBarVisible ? '可见' : '隐藏'}`
            })
          Button(`halfHeight: ${this.halfHeightValue}`)
            .fontSize(12)
            .backgroundColor('#FF6B00')
            .onClick(() => {
              this.halfHeightValue = this.halfHeightValue === 300 ? 400 : 300
              this.resultLog = `halfHeight 已调整为 ${this.halfHeightValue}`
            })
        }
        .width('90%')
        .justifyContent(FlexAlign.Center)

        Panel(undefined) {
          Column({ space: 12 }) {
            Text('自定义高度面板')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
            Text(`dragBar: ${this.dragBarVisible ? '可见' : '隐藏'}`)
              .fontSize(14)
              .fontColor('#666666')
            Text(`halfHeight: ${this.halfHeightValue}, fullHeight: ${this.fullHeightValue}`)
              .fontSize(14)
              .fontColor('#666666')
          }
          .width('100%')
          .padding(16)
          .alignItems(HorizontalAlign.Center)
        }
        .type(PanelType.Foldable)
        .mode(PanelMode.Half)
        .dragBar(this.dragBarVisible)
        .halfHeight(this.halfHeightValue)
        .fullHeight(this.fullHeightValue)
        .miniHeight(this.miniHeightValue)
        .onChange((width: number, height: number, mode: PanelMode) => {
          const modeStr = mode === PanelMode.Mini ? 'Mini' : mode === PanelMode.Half ? 'Half' : 'Full'
          this.resultLog = `自定义面板变化: ${modeStr}, 高度=${height}`
        })

        // ---- 5. 面板内嵌交互内容 ----
        Text('5. 面板内嵌交互内容')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 12 })

        Button('显示内容面板')
          .width('80%')
          .onClick(() => {
            try {
              this.resultLog = '内容面板已弹出，可在面板内操作'
            } catch (err) {
              const e = err as BusinessError
              this.resultLog = `错误: ${e.code} - ${e.message}`
            }
          })

        Panel(undefined) {
          Column({ space: 16 }) {
            Text('操作面板')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)

            Row({ space: 8 }) {
              ForEach(['选项A', '选项B', '选项C'], (item: string) => {
                Button(item)
                  .fontSize(12)
                  .layoutWeight(1)
                  .onClick(() => {
                    this.resultLog = `已选择: ${item}`
                  })
              }, (item: string) => item)
            }
            .width('100%')

            Text('面板可承载任意组件内容')
              .fontSize(12)
              .fontColor('#999999')
          }
          .width('100%')
          .padding(16)
          .alignItems(HorizontalAlign.Center)
        }
        .type(PanelType.Foldable)
        .mode(PanelMode.Full)
        .dragBar(true)
        .halfHeight(300)
        .fullHeight(500)
        .onChange((width: number, height: number, mode: PanelMode) => {
          const modeStr = mode === PanelMode.Mini ? 'Mini' : mode === PanelMode.Half ? 'Half' : 'Full'
          this.resultLog = `内容面板变化: ${modeStr}`
        })

        // API 说明区
        Column() {
          Text('API 说明')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 8 })
          Text('Panel() — 创建可滑动面板')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('  .type(PanelType) — Foldable | Minibar | Temporary')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('  .mode(PanelMode) — Mini | Half | Full')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('  .dragBar(boolean) — 是否显示拖拽条')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('  .halfHeight(Length) — Half 模式高度')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('  .fullHeight(Length) — Full 模式高度')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('  .miniHeight(Length) — Mini 模式高度')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('  .onChange(callback) — 尺寸变化回调')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('元服务API: API 7+ 完全可用')
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
