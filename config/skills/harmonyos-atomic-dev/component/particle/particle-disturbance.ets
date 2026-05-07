/**
 * particle-disturbance — 粒子扰动场效果
 * 展示 disturbanceFields 扰动场对粒子运动轨迹的影响
 * 元服务兼容性：disturbanceFields — API 12+
 */
import { BusinessError } from '@kit.BasicServicesKit'

@ComponentV2
export struct ParticleDisturbance {
  @Local resultLog: string = '观察扰动场对粒子运动的影响'
  @Local fieldStrength: number = 10
  @Local fieldFeather: number = 15
  @Local noiseFrequency: number = 15

  private appendLog(msg: string): void {
    const now = new Date()
    const time = `${now.getHours().toString().padStart(2, '0')}:${now.getMinutes().toString().padStart(2, '0')}:${now.getSeconds().toString().padStart(2, '0')}`
    this.resultLog = `[${time}] ${msg}\n${this.resultLog}`
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('Particle 扰动场效果')
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

        // 粒子 + 扰动场
        Text('1. 扰动场干涉粒子运动')
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
                      radius: 5
                    },
                    count: 500,
                    lifetime: 10000,
                    lifetimeRange: 100
                  },
                  emitRate: 10,
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
                        startMillis: 5000,
                        endMillis: 10000,
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
          .disturbanceFields([{
            strength: this.fieldStrength,
            shape: DisturbanceFieldShape.RECT,
            size: { width: 100, height: 100 },
            position: { x: 100, y: 100 },
            feather: this.fieldFeather,
            noiseScale: 10,
            noiseFrequency: this.noiseFrequency,
            noiseAmplitude: 5
          }])
        }
        .width('90%')
        .height(320)
        .alignContent(Alignment.Center)

        // 参数控制区
        Text('2. 扰动场参数调节')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Row({ space: 12 }) {
          Text(`场强: ${this.fieldStrength}`)
            .fontSize(13)
            .fontColor('#666666')
          Button('排斥(10)')
            .fontSize(12)
            .onClick(() => {
              this.fieldStrength = 10
              this.appendLog('场强 → 排斥(10)')
            })
          Button('吸引(-10)')
            .fontSize(12)
            .onClick(() => {
              this.fieldStrength = -10
              this.appendLog('场强 → 吸引(-10)')
            })
          Button('强排斥(30)')
            .fontSize(12)
            .onClick(() => {
              this.fieldStrength = 30
              this.appendLog('场强 → 强排斥(30)')
            })
        }
        .width('90%')
        .justifyContent(FlexAlign.Start)

        Row({ space: 12 }) {
          Text(`羽化值: ${this.fieldFeather}`)
            .fontSize(13)
            .fontColor('#666666')
          Button('+10')
            .fontSize(12)
            .onClick(() => {
              this.fieldFeather = Math.min(this.fieldFeather + 10, 100)
              this.appendLog(`羽化值 → ${this.fieldFeather}`)
            })
          Button('-10')
            .fontSize(12)
            .onClick(() => {
              this.fieldFeather = Math.max(this.fieldFeather - 10, 0)
              this.appendLog(`羽化值 → ${this.fieldFeather}`)
            })
        }
        .width('90%')
        .justifyContent(FlexAlign.Start)

        Row({ space: 12 }) {
          Text(`噪声频率: ${this.noiseFrequency}`)
            .fontSize(13)
            .fontColor('#666666')
          Button('+5')
            .fontSize(12)
            .onClick(() => {
              this.noiseFrequency = Math.min(this.noiseFrequency + 5, 100)
              this.appendLog(`噪声频率 → ${this.noiseFrequency}`)
            })
          Button('-5')
            .fontSize(12)
            .onClick(() => {
              this.noiseFrequency = Math.max(this.noiseFrequency - 5, 1)
              this.appendLog(`噪声频率 → ${this.noiseFrequency}`)
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
          Text('  disturbanceFields(Array<DisturbanceFieldOptions>)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('  DisturbanceFieldOptions.strength — 场强(正排斥/负吸引)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('  DisturbanceFieldOptions.shape — 场形状(RECT/CIRCLE/ELLIPSE)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('  DisturbanceFieldOptions.size/position — 场区域')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('  DisturbanceFieldOptions.feather — 羽化值(0-100)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('  DisturbanceFieldOptions.noiseScale/Frequency/Amplitude')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('元服务API: disturbanceFields 从 API 12+ 可用')
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
