/**
 * curves-basic — Curves 动画曲线基础用法
 * 展示 Curve 预设枚举 + curves 弹簧曲线
 * 元服务兼容性：Curve 预设枚举可用，curves.springCurve/springMotion 可用
 * 注意：curves.cubicBezier 不支持元服务
 */
import { curves } from '@kit.ArkUI'

@ComponentV2
export struct CurvesBasic {
  @Local resultLog: string = '点击按钮查看曲线效果'
  @Local offsetX1: number = 0
  @Local offsetX2: number = 0
  @Local offsetX3: number = 0
  @Local offsetX4: number = 0
  @Local offsetX5: number = 0
  @Local running: boolean = false

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('Curves 动画曲线')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20, bottom: 10 })

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

        Text('1. Curve 预设枚举 + curves 弹簧曲线')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Button('播放动画')
          .fontSize(13)
          .onClick(() => {
            this.running = !this.running
            const target = this.running ? 200 : 0
            this.resultLog = `动画${this.running ? '播放' : '回退'}`
            animateTo({ duration: 1000, curve: Curve.EaseInOut }, () => { this.offsetX1 = target })
            animateTo({ duration: 1000, curve: Curve.Linear }, () => { this.offsetX2 = target })
            animateTo({ duration: 1000, curve: Curve.FastOutSlowIn }, () => { this.offsetX3 = target })
            animateTo({ duration: 1000, curve: curves.springMotion(0.555, 0, 0) }, () => { this.offsetX4 = target })
            animateTo({ duration: 1000, curve: curves.springCurve(1, 1, 1, 1) }, () => { this.offsetX5 = target })
          })

        // EaseInOut
        Column() {
          Row() {
            Text('Curve.EaseInOut')
              .fontSize(12)
              .fontColor('#FFFFFF')
              .padding(4)
          }
          .backgroundColor('#007DFF')
          .borderRadius(4)
          .translate({ x: this.offsetX1 })
        }
        .width('90%')
        .height(30)

        // Linear
        Column() {
          Row() {
            Text('Curve.Linear')
              .fontSize(12)
              .fontColor('#FFFFFF')
              .padding(4)
          }
          .backgroundColor('#FF6B00')
          .borderRadius(4)
          .translate({ x: this.offsetX2 })
        }
        .width('90%')
        .height(30)

        // FastOutSlowIn
        Column() {
          Row() {
            Text('Curve.FastOutSlowIn')
              .fontSize(12)
              .fontColor('#FFFFFF')
              .padding(4)
          }
          .backgroundColor('#00B578')
          .borderRadius(4)
          .translate({ x: this.offsetX3 })
        }
        .width('90%')
        .height(30)

        // springMotion
        Column() {
          Row() {
            Text('curves.springMotion')
              .fontSize(12)
              .fontColor('#FFFFFF')
              .padding(4)
          }
          .backgroundColor('#9B59B6')
          .borderRadius(4)
          .translate({ x: this.offsetX4 })
        }
        .width('90%')
        .height(30)

        // springCurve
        Column() {
          Row() {
            Text('curves.springCurve')
              .fontSize(12)
              .fontColor('#FFFFFF')
              .padding(4)
          }
          .backgroundColor('#FA2A2D')
          .borderRadius(4)
          .translate({ x: this.offsetX5 })
        }
        .width('90%')
        .height(30)

        // API 说明区
        Column() {
          Text('API 说明')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 8 })
          Text('Curve 预设枚举 (直接使用):')
            .fontSize(12)
            .fontColor('#007DFF')
            .fontWeight(FontWeight.Medium)
            .width('100%')
          Text('  Linear / Ease / EaseIn / EaseOut / EaseInOut')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('  FastOutSlowIn / LinearOutSlowIn / FastOutLinearIn / Spring')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('curves 弹簧曲线 (import { curves } from "@kit.ArkUI"):')
            .fontSize(12)
            .fontColor('#007DFF')
            .fontWeight(FontWeight.Medium)
            .width('100%')
          Text('  curves.springCurve(velocity, mass, stiffness, damping)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('  curves.springMotion(mass, stiffness, damping)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('元服务不支持: curves.cubicBezier')
            .fontSize(12)
            .fontColor('#FF6B00')
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
