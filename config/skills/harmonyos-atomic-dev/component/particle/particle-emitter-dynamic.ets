/**
 * particle-emitter-dynamic — 发射器动态更新
 * 展示通过 emitter() 属性动态更新发射器位置、速率和窗口大小
 * 元服务兼容性：emitter 属性动态更新 — API 12+
 */
import { BusinessError } from '@kit.BasicServicesKit'

@ComponentV2
export struct ParticleEmitterDynamic {
  @Local resultLog: string = '点击按钮更新发射器参数'
  @Local currentX: number = 60
  @Local currentY: number = 80
  @Local currentEmitRate: number = 100
  @Local currentWidth: number = 200
  @Local currentHeight: number = 200
  @Local emitterProperties: Array<EmitterProperty> = [
    {
      index: 0,
      emitRate: 100,
      position: { x: 60, y: 80 },
      size: { width: 200, height: 200 }
    }
  ]

  private appendLog(msg: string): void {
    const now = new Date()
    const time = `${now.getHours().toString().padStart(2, '0')}:${now.getMinutes().toString().padStart(2, '0')}:${now.getSeconds().toString().padStart(2, '0')}`
    this.resultLog = `[${time}] ${msg}\n${this.resultLog}`
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('Particle 发射器动态更新')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20, bottom: 10 })

        // 结果展示区
        Column() {
          Text(this.resultLog)
            .fontSize(13)
            .fontColor('#333333')
            .width('100%')
            .padding(12)
            .maxLines(10)
        }
        .width('90%')
        .backgroundColor('#F5F5F5')
        .borderRadius(8)
        .alignItems(HorizontalAlign.Start)

        // 粒子动画展示区
        Text('1. 动态发射器位置与速率')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Stack() {
          Text()
            .width(300)
            .height(300)
            .backgroundColor(Color.Black)
            .borderRadius(12)
          Particle({
            particles: [
              {
                emitter: {
                  particle: {
                    type: ParticleType.POINT,
                    config: {
                      radius: 3
                    },
                    count: 400,
                    lifetime: -1
                  },
                  emitRate: 10,
                  position: [0, 0],
                  shape: ParticleEmitterShape.CIRCLE
                },
                color: {
                  range: [Color.Red, Color.Yellow],
                  updater: {
                    type: ParticleUpdater.CURVE,
                    config: [
                      {
                        from: Color.White,
                        to: Color.Pink,
                        startMillis: 0,
                        endMillis: 3000,
                        curve: Curve.EaseIn
                      },
                      {
                        from: Color.Pink,
                        to: Color.Orange,
                        startMillis: 3000,
                        endMillis: 5000,
                        curve: Curve.EaseIn
                      },
                      {
                        from: Color.Orange,
                        to: Color.Pink,
                        startMillis: 5000,
                        endMillis: 8000,
                        curve: Curve.EaseIn
                      }
                    ]
                  }
                }
              }
            ]
          })
          .width(300)
          .height(300)
          .borderRadius(12)
          .emitter(this.emitterProperties)
        }
        .width('90%')
        .height(320)
        .alignContent(Alignment.Center)

        // 位置控制
        Text('2. 发射器位置控制')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Row({ space: 8 }) {
          Text(`X: ${this.currentX}  Y: ${this.currentY}`)
            .fontSize(13)
            .fontColor('#666666')
        }
        .width('90%')
        .justifyContent(FlexAlign.Start)

        Row({ space: 12 }) {
          Button('左上角')
            .fontSize(12)
            .onClick(() => {
              try {
                this.currentX = 30
                this.currentY = 30
                this.emitterProperties = [
                  {
                    index: 0,
                    emitRate: this.currentEmitRate,
                    position: { x: this.currentX, y: this.currentY },
                    size: { width: this.currentWidth, height: this.currentHeight }
                  }
                ]
                this.appendLog('发射器 → 左上角')
              } catch (error) {
                const err = error as BusinessError
                this.appendLog(`错误: code=${err.code}`)
              }
            })
          Button('中心')
            .fontSize(12)
            .onClick(() => {
              try {
                this.currentX = 150
                this.currentY = 150
                this.emitterProperties = [
                  {
                    index: 0,
                    emitRate: this.currentEmitRate,
                    position: { x: this.currentX, y: this.currentY },
                    size: { width: this.currentWidth, height: this.currentHeight }
                  }
                ]
                this.appendLog('发射器 → 中心')
              } catch (error) {
                const err = error as BusinessError
                this.appendLog(`错误: code=${err.code}`)
              }
            })
          Button('右下角')
            .fontSize(12)
            .onClick(() => {
              try {
                this.currentX = 270
                this.currentY = 270
                this.emitterProperties = [
                  {
                    index: 0,
                    emitRate: this.currentEmitRate,
                    position: { x: this.currentX, y: this.currentY },
                    size: { width: this.currentWidth, height: this.currentHeight }
                  }
                ]
                this.appendLog('发射器 → 右下角')
              } catch (error) {
                const err = error as BusinessError
                this.appendLog(`错误: code=${err.code}`)
              }
            })
        }
        .width('90%')
        .justifyContent(FlexAlign.Center)

        // 速率控制
        Text('3. 发射速率控制')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Row({ space: 12 }) {
          Text(`当前速率: ${this.currentEmitRate}/s`)
            .fontSize(13)
            .fontColor('#666666')
          Button('高速(200)')
            .fontSize(12)
            .onClick(() => {
              try {
                this.currentEmitRate = 200
                this.emitterProperties = [
                  {
                    index: 0,
                    emitRate: this.currentEmitRate,
                    position: { x: this.currentX, y: this.currentY },
                    size: { width: this.currentWidth, height: this.currentHeight }
                  }
                ]
                this.appendLog(`发射速率 → ${this.currentEmitRate}/s`)
              } catch (error) {
                const err = error as BusinessError
                this.appendLog(`错误: code=${err.code}`)
              }
            })
          Button('低速(10)')
            .fontSize(12)
            .onClick(() => {
              try {
                this.currentEmitRate = 10
                this.emitterProperties = [
                  {
                    index: 0,
                    emitRate: this.currentEmitRate,
                    position: { x: this.currentX, y: this.currentY },
                    size: { width: this.currentWidth, height: this.currentHeight }
                  }
                ]
                this.appendLog(`发射速率 → ${this.currentEmitRate}/s`)
              } catch (error) {
                const err = error as BusinessError
                this.appendLog(`错误: code=${err.code}`)
              }
            })
        }
        .width('90%')
        .justifyContent(FlexAlign.Start)

        // API 说明区
        Column() {
          Text('API 说明')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 8 })
          Text('可用 API (元服务 API 12+):')
            .fontSize(12)
            .fontColor('#00B578')
            .fontWeight(FontWeight.Medium)
            .width('100%')
          Text('  emitter(Array<EmitterProperty>) — 发射器动态更新')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('  EmitterProperty.index — 指定发射器索引')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('  EmitterProperty.emitRate — 更新发射速率')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('  EmitterProperty.position — 更新发射器位置')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('  EmitterProperty.size — 更新发射窗口大小')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('元服务API: emitter 动态更新从 API 12+ 可用')
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
