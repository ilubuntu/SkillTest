/**
 * swiper-basic — Swiper 基本用法
 * 展示 Swiper 组件的循环播放、自动轮播、interval 间隔设置
 * 元服务兼容性：Swiper 基础组件 API 7+ 全部可用
 */
@ComponentV2
export struct SwiperBasic {
  @Local currentIndex: number = 0
  @Local resultText: string = '当前页: 0'
  @Local eventLog: string = '等待操作...'
  @Local loopEnabled: boolean = true
  @Local autoPlayEnabled: boolean = false
  @Local intervalValue: number = 3000
  @Local durationValue: number = 500

  private readonly colors: string[] = ['#4CAF50', '#2196F3', '#FF9800', '#9C27B0', '#F44336']
  private readonly labels: string[] = ['页面 0', '页面 1', '页面 2', '页面 3', '页面 4']

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('Swiper 基本用法')
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

        // 事件日志区
        Column() {
          Text(this.eventLog)
            .fontSize(12)
            .fontColor('#666666')
            .width('100%')
            .padding(12)
        }
        .width('90%')
        .backgroundColor('#F0F0F0')
        .borderRadius(8)

        // 基础轮播 Swiper
        Text('循环轮播 + onChange')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Swiper() {
          ForEach(this.colors, (color: string, index: number) => {
            Column() {
              Text(this.labels[index])
                .fontSize(28)
                .fontColor(Color.White)
                .fontWeight(FontWeight.Bold)
            }
            .width('90%')
            .height(160)
            .backgroundColor(color)
            .borderRadius(12)
            .justifyContent(FlexAlign.Center)
          }, (color: string, index: number) => `${index}_${color}`)
        }
        .width('100%')
        .height(180)
        .loop(this.loopEnabled)
        .autoPlay(this.autoPlayEnabled)
        .interval(this.intervalValue)
        .duration(this.durationValue)
        .indicator(true)
        .onChange((index: number) => {
          try {
            this.currentIndex = index
            this.resultText = `当前页: ${index}`
            this.eventLog = `onChange → index: ${index}, loop: ${this.loopEnabled}`
          } catch (err) {
            this.eventLog = `错误: ${(err as BusinessError).message}`
          }
        })

        // 参数控制区
        Text('参数控制')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        // loop 开关
        Row() {
          Text('循环播放 (loop):')
            .fontSize(13)
            .fontColor('#333333')
          Text(this.loopEnabled ? '开启' : '关闭')
            .fontSize(13)
            .fontColor(this.loopEnabled ? '#4CAF50' : '#F44336')
            .fontWeight(FontWeight.Medium)
            .margin({ left: 8 })
          Blank()
          Button(this.loopEnabled ? '关闭' : '开启')
            .fontSize(12)
            .height(32)
            .onClick(() => {
              try {
                this.loopEnabled = !this.loopEnabled
                this.eventLog = `loop → ${this.loopEnabled}`
              } catch (err) {
                this.eventLog = `错误: ${(err as BusinessError).message}`
              }
            })
        }
        .width('90%')
        .padding({ left: 12, right: 12 })

        // autoPlay 开关
        Row() {
          Text('自动播放 (autoPlay):')
            .fontSize(13)
            .fontColor('#333333')
          Text(this.autoPlayEnabled ? '开启' : '关闭')
            .fontSize(13)
            .fontColor(this.autoPlayEnabled ? '#4CAF50' : '#F44336')
            .fontWeight(FontWeight.Medium)
            .margin({ left: 8 })
          Blank()
          Button(this.autoPlayEnabled ? '关闭' : '开启')
            .fontSize(12)
            .height(32)
            .onClick(() => {
              try {
                this.autoPlayEnabled = !this.autoPlayEnabled
                this.eventLog = `autoPlay → ${this.autoPlayEnabled}`
              } catch (err) {
                this.eventLog = `错误: ${(err as BusinessError).message}`
              }
            })
        }
        .width('90%')
        .padding({ left: 12, right: 12 })

        // interval 控制
        Row() {
          Text(`间隔 (interval): ${this.intervalValue}ms`)
            .fontSize(13)
            .fontColor('#333333')
          Blank()
          Button('+500')
            .fontSize(12)
            .height(32)
            .margin({ left: 4 })
            .onClick(() => {
              try {
                this.intervalValue = Math.min(this.intervalValue + 500, 10000)
                this.eventLog = `interval → ${this.intervalValue}ms`
              } catch (err) {
                this.eventLog = `错误: ${(err as BusinessError).message}`
              }
            })
          Button('-500')
            .fontSize(12)
            .height(32)
            .margin({ left: 4 })
            .onClick(() => {
              try {
                this.intervalValue = Math.max(this.intervalValue - 500, 500)
                this.eventLog = `interval → ${this.intervalValue}ms`
              } catch (err) {
                this.eventLog = `错误: ${(err as BusinessError).message}`
              }
            })
        }
        .width('90%')
        .padding({ left: 12, right: 12 })

        // duration 控制
        Row() {
          Text(`动画时长 (duration): ${this.durationValue}ms`)
            .fontSize(13)
            .fontColor('#333333')
          Blank()
          Button('+100')
            .fontSize(12)
            .height(32)
            .margin({ left: 4 })
            .onClick(() => {
              try {
                this.durationValue = Math.min(this.durationValue + 100, 2000)
                this.eventLog = `duration → ${this.durationValue}ms`
              } catch (err) {
                this.eventLog = `错误: ${(err as BusinessError).message}`
              }
            })
          Button('-100')
            .fontSize(12)
            .height(32)
            .margin({ left: 4 })
            .onClick(() => {
              try {
                this.durationValue = Math.max(this.durationValue - 100, 100)
                this.eventLog = `duration → ${this.durationValue}ms`
              } catch (err) {
                this.eventLog = `错误: ${(err as BusinessError).message}`
              }
            })
        }
        .width('90%')
        .padding({ left: 12, right: 12 })

        // 重置按钮
        Button('重置为默认值')
          .width('90%')
          .height(40)
          .backgroundColor('#007DFF')
          .onClick(() => {
            try {
              this.loopEnabled = true
              this.autoPlayEnabled = false
              this.intervalValue = 3000
              this.durationValue = 500
              this.currentIndex = 0
              this.resultText = '当前页: 0'
              this.eventLog = '已重置'
            } catch (err) {
              this.eventLog = `错误: ${(err as BusinessError).message}`
            }
          })

        // API 说明区
        Column() {
          Text('API 说明')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 8 })
          Text('Swiper() { ... }')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('.loop(boolean) — 是否循环播放 (默认 true)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('.autoPlay(boolean) — 是否自动轮播 (默认 false)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('.interval(number) — 自动播放间隔 ms (默认 3000)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('.duration(number) — 子组件切换动画时长 ms')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('.indicator(boolean) — 是否显示导航点 (默认 true)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('.onChange((index: number) => void) — 页面切换回调')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('元服务兼容: API 7+ 全部可用')
            .fontSize(12)
            .fontColor('#4CAF50')
            .width('100%')
            .margin({ top: 4 })
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
