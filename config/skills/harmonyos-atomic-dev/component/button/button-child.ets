/**
 * button-child — Button 子组件用法
 * 展示 Button 作为容器使用，包含图标+文字组合
 * 元服务兼容性：Button 支持包含一个子组件（基础组件能力）
 */
import { BusinessError } from '@kit.BasicServicesKit'

@ComponentV2
export struct ButtonChild {
  @Local resultText: string = '等待操作...'

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('Button 子组件用法')
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

        // 图标+文字按钮
        Text('图标 + 文字组合按钮')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Button({ type: ButtonType.Normal, stateEffect: true }) {
          Row({ space: 8 }) {
            Text('📁')
              .fontSize(18)
            Text('打开文件')
              .fontSize(14)
              .fontColor(Color.White)
          }
          .alignItems(VerticalAlign.Center)
        }
        .width('90%')
        .height(44)
        .borderRadius(8)
        .backgroundColor('#007DFF')
        .onClick(() => {
          this.resultText = '图标+文字按钮被点击'
        })

        // 删除操作按钮
        Text('功能型按钮 — 删除操作')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Button({ type: ButtonType.Normal, stateEffect: true }) {
          Row({ space: 8 }) {
            Text('🗑')
              .fontSize(18)
            Text('删除')
              .fontSize(14)
              .fontColor(Color.White)
          }
          .alignItems(VerticalAlign.Center)
        }
        .width(120)
        .height(44)
        .borderRadius(8)
        .backgroundColor('#E84026')
        .onClick(() => {
          this.resultText = '删除按钮被点击'
        })

        // 确认/取消按钮组
        Text('确认 / 取消按钮组')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Row({ space: 16 }) {
          Button({ type: ButtonType.Normal, stateEffect: true }) {
            Text('取消')
              .fontSize(14)
              .fontColor('#666666')
          }
          .width(120)
          .height(40)
          .borderRadius(8)
          .backgroundColor('#EEEEEE')
          .onClick(() => {
            this.resultText = '取消操作'
          })

          Button({ type: ButtonType.Normal, stateEffect: true }) {
            Text('确认')
              .fontSize(14)
              .fontColor(Color.White)
          }
          .width(120)
          .height(40)
          .borderRadius(8)
          .backgroundColor('#007DFF')
          .onClick(() => {
            this.resultText = '确认操作'
          })
        }

        // 带加载指示的按钮
        Text('带加载状态按钮')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Button({ type: ButtonType.Normal, stateEffect: true }) {
          Row({ space: 8 }) {
            LoadingProgress()
              .width(18)
              .height(18)
              .color(Color.White)
            Text('加载中...')
              .fontSize(14)
              .fontColor(Color.White)
          }
          .alignItems(VerticalAlign.Center)
        }
        .width('90%')
        .height(44)
        .borderRadius(8)
        .backgroundColor('#FF9800')
        .enabled(false)
        .onClick(() => {
          try {
            this.resultText = '加载中按钮不应被点击'
          } catch (err) {
            const e = err as BusinessError
            this.resultText = `错误: ${e.code}`
          }
        })

        // API 说明区
        Column() {
          Text('API 说明')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 8 })
          Text('Button({ type, stateEffect }) { 子组件 }')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('支持包含一个子组件（基础组件或容器组件）')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('常用于 Row { Image + Text } 组合')
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
