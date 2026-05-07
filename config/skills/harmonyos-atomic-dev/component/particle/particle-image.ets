/**
 * particle-image — 图片粒子动画
 * 展示 Particle 组件图片粒子 (ParticleType.IMAGE) 的用法
 * 元服务兼容性：ParticleType.IMAGE、ImageParticleParameters — API 11+
 */
import { BusinessError } from '@kit.BasicServicesKit'

@ComponentV2
export struct ParticleImage {
  @Local resultLog: string = '等待操作...'

  private appendLog(msg: string): void {
    const now = new Date()
    const time = `${now.getHours().toString().padStart(2, '0')}:${now.getMinutes().toString().padStart(2, '0')}:${now.getSeconds().toString().padStart(2, '0')}`
    this.resultLog = `[${time}] ${msg}\n${this.resultLog}`
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('Particle 图片粒子动画')
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

        // 图片粒子动画
        Text('1. 图片粒子 (ParticleType.IMAGE)')
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
                    type: ParticleType.IMAGE,
                    config: {
                      src: $r('app.media.startIcon'),
                      size: [20, 20]
                    },
                    count: 100,
                    lifetime: 8000,
                    lifetimeRange: 100
                  },
                  emitRate: 5,
                  shape: ParticleEmitterShape.CIRCLE
                },
                opacity: {
                  range: [1.0, 1.0],
                  updater: {
                    type: ParticleUpdater.CURVE,
                    config: [
                      {
                        from: 0,
                        to: 1.0,
                        startMillis: 0,
                        endMillis: 4000
                      },
                      {
                        from: 1.0,
                        to: 0,
                        startMillis: 4000,
                        endMillis: 8000
                      }
                    ]
                  }
                },
                scale: {
                  range: [0.1, 1.0],
                  updater: {
                    type: ParticleUpdater.CURVE,
                    config: [
                      {
                        from: 0,
                        to: 1.5,
                        startMillis: 0,
                        endMillis: 6000,
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
                      config: [1, 10]
                    }
                  },
                  angle: {
                    range: [0, 360]
                  }
                },
                spin: {
                  range: [0.1, 1.0],
                  updater: {
                    type: ParticleUpdater.CURVE,
                    config: [
                      {
                        from: 0,
                        to: 360,
                        startMillis: 0,
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
        }
        .width('90%')
        .height(320)
        .alignContent(Alignment.Center)

        Row({ space: 12 }) {
          Button('记录日志')
            .fontSize(13)
            .onClick(() => {
              this.appendLog('图片粒子动画运行中')
            })
        }
        .width('90%')
        .justifyContent(FlexAlign.Center)

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
          Text('  ParticleType.IMAGE — 图片粒子类型')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('  ImageParticleParameters.src — 图片资源路径')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('  ImageParticleParameters.size — 图片尺寸 [w, h]')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('  ImageParticleParameters.objectFit — 图片显示模式(可选)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('  ParticleEmitterShape.CIRCLE — 圆形发射器')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('  spin 属性 — 粒子自旋角度动画')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('注意: 图片粒子不支持设置 color 属性')
            .fontSize(12)
            .fontColor('#FF6B00')
            .fontFamily('monospace')
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
