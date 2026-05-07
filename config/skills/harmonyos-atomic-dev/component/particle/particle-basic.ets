/**
 * particle-basic — 圆点粒子基础动画
 * 展示 Particle 组件圆点粒子 (ParticleType.POINT) 的基础用法
 * 元服务兼容性：Particle 接口、ParticleType.POINT、颜色/透明度/缩放属性 — API 11+
 */
import { BusinessError } from '@kit.BasicServicesKit'

@ComponentV2
export struct ParticleBasic {
  @Local resultLog: string = '等待操作...'
  @Local particleRadius: number = 5
  @Local particleCount: number = 200
  @Local emitRate: number = 10
  @Local lifetime: number = 5000

  private appendLog(msg: string): void {
    const now = new Date()
    const time = `${now.getHours().toString().padStart(2, '0')}:${now.getMinutes().toString().padStart(2, '0')}:${now.getSeconds().toString().padStart(2, '0')}`
    this.resultLog = `[${time}] ${msg}\n${this.resultLog}`
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('Particle 圆点粒子基础')
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
        Text('1. 圆点粒子动画效果')
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
                      radius: this.particleRadius
                    },
                    count: this.particleCount,
                    lifetime: this.lifetime,
                    lifetimeRange: 100
                  },
                  emitRate: this.emitRate,
                  position: [0, 0],
                  shape: ParticleEmitterShape.RECTANGLE
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
                      }
                    ]
                  }
                },
                opacity: {
                  range: [0.0, 1.0],
                  updater: {
                    type: ParticleUpdater.CURVE,
                    config: [
                      {
                        from: 0.0,
                        to: 1.0,
                        startMillis: 0,
                        endMillis: 3000,
                        curve: Curve.EaseIn
                      },
                      {
                        from: 1.0,
                        to: 0.0,
                        startMillis: 3000,
                        endMillis: 5000,
                        curve: Curve.EaseIn
                      }
                    ]
                  }
                },
                scale: {
                  range: [0.0, 0.0],
                  updater: {
                    type: ParticleUpdater.CURVE,
                    config: [
                      {
                        from: 0.0,
                        to: 0.5,
                        startMillis: 0,
                        endMillis: 3000,
                        curve: Curve.EaseIn
                      }
                    ]
                  }
                },
                acceleration: {
                  speed: {
                    range: [3, 9],
                    updater: {
                      type: ParticleUpdater.RANDOM,
                      config: [1, 20]
                    }
                  },
                  angle: {
                    range: [90, 90]
                  }
                }
              }
            ]
          })
          .width(300)
          .height(300)
          .borderRadius(12)
        }
        .width('90%')
        .height(320)
        .alignContent(Alignment.Center)

        // 参数控制区
        Text('2. 参数调节')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Row({ space: 12 }) {
          Text(`半径: ${this.particleRadius}vp`)
            .fontSize(13)
            .fontColor('#666666')
          Button('+1')
            .fontSize(12)
            .onClick(() => {
              this.particleRadius = Math.min(this.particleRadius + 1, 30)
              this.appendLog(`半径 → ${this.particleRadius}`)
            })
          Button('-1')
            .fontSize(12)
            .onClick(() => {
              this.particleRadius = Math.max(this.particleRadius - 1, 1)
              this.appendLog(`半径 → ${this.particleRadius}`)
            })
        }
        .width('90%')
        .justifyContent(FlexAlign.Start)

        Row({ space: 12 }) {
          Text(`数量: ${this.particleCount}`)
            .fontSize(13)
            .fontColor('#666666')
          Button('+50')
            .fontSize(12)
            .onClick(() => {
              this.particleCount = Math.min(this.particleCount + 50, 2000)
              this.appendLog(`数量 → ${this.particleCount}`)
            })
          Button('-50')
            .fontSize(12)
            .onClick(() => {
              this.particleCount = Math.max(this.particleCount - 50, 10)
              this.appendLog(`数量 → ${this.particleCount}`)
            })
        }
        .width('90%')
        .justifyContent(FlexAlign.Start)

        Row({ space: 12 }) {
          Text(`发射速率: ${this.emitRate}/s`)
            .fontSize(13)
            .fontColor('#666666')
          Button('+5')
            .fontSize(12)
            .onClick(() => {
              this.emitRate = Math.min(this.emitRate + 5, 500)
              this.appendLog(`发射速率 → ${this.emitRate}/s`)
            })
          Button('-5')
            .fontSize(12)
            .onClick(() => {
              this.emitRate = Math.max(this.emitRate - 5, 1)
              this.appendLog(`发射速率 → ${this.emitRate}/s`)
            })
        }
        .width('90%')
        .justifyContent(FlexAlign.Start)

        Row({ space: 12 }) {
          Text(`生命周期: ${this.lifetime}ms`)
            .fontSize(13)
            .fontColor('#666666')
          Button('+1000')
            .fontSize(12)
            .onClick(() => {
              this.lifetime = Math.min(this.lifetime + 1000, 30000)
              this.appendLog(`生命周期 → ${this.lifetime}ms`)
            })
          Button('-1000')
            .fontSize(12)
            .onClick(() => {
              this.lifetime = Math.max(this.lifetime - 1000, 500)
              this.appendLog(`生命周期 → ${this.lifetime}ms`)
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
          Text('可用 API (元服务 API 11+):')
            .fontSize(12)
            .fontColor('#00B578')
            .fontWeight(FontWeight.Medium)
            .width('100%')
          Text('  Particle(particles) — 粒子动画组件')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('  ParticleType.POINT — 圆点粒子')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('  PointParticleParameters.radius — 粒子半径')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('  EmitterOptions — 发射器配置(emitRate/shape/position)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('  ParticleUpdater.CURVE — 曲线动画更新')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('  ParticleUpdater.RANDOM — 随机变化更新')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('  color/opacity/scale/acceleration — 粒子属性动画')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('元服务API: Particle 接口及基础属性从 API 11+ 可用')
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
