/**
 * video-basic — Video 基础用法
 * 展示视频播放、控制、事件回调
 * 元服务兼容性：Video 组件从 API 11+ 可用，VideoController 同步可用
 */
@ComponentV2
export struct VideoBasic {
  @Local resultLog: string = '等待操作...'
  @Local isPlaying: boolean = false
  @Local currentTime: number = 0
  @Local duration: number = 0
  controller: VideoController = new VideoController()

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('Video 视频播放基础用法')
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

        // ---- 基础视频播放 ----
        Text('1. 基础视频播放')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Video({
          src: 'https://www.example.com/sample.mp4',
          previewUri: '',
          currentProgressRate: PlaybackSpeed.Speed_Forward_1_00_X,
          controller: this.controller
        })
          .width('90%')
          .height(200)
          .autoPlay(false)
          .controls(true)
          .loop(false)
          .muted(false)
          .objectFit(ImageFit.Cover)
          .onPrepared((event?: PreparedInfo) => {
            if (event) {
              this.duration = event.duration
              this.resultLog = `视频准备就绪，时长: ${event.duration}ms`
            }
          })
          .onStart(() => {
            this.isPlaying = true
            this.resultLog = '视频开始播放'
          })
          .onPause(() => {
            this.isPlaying = false
            this.resultLog = '视频暂停'
          })
          .onFinish(() => {
            this.isPlaying = false
            this.resultLog = '视频播放完成'
          })
          .onError(() => {
            this.resultLog = '视频播放出错（示例URL无效）'
          })
          .onUpdate((event?: PlaybackInfo) => {
            if (event) {
              this.currentTime = event.time
            }
          })

        Text('注意：示例使用占位URL，实际播放需要有效视频源')
          .fontSize(12)
          .fontColor('#999999')
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16 })

        // ---- 播放控制按钮 ----
        Text('2. VideoController 控制')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 12 })

        Row({ space: 12 }) {
          Button('播放')
            .fontSize(13)
            .onClick(() => {
              try {
                this.controller.start()
                this.resultLog = '调用 controller.start()'
              } catch (error) {
                this.resultLog = `start 错误: ${(error as BusinessError).message}`
              }
            })
          Button('暂停')
            .fontSize(13)
            .backgroundColor('#FF6B00')
            .onClick(() => {
              try {
                this.controller.pause()
                this.resultLog = '调用 controller.pause()'
              } catch (error) {
                this.resultLog = `pause 错误: ${(error as BusinessError).message}`
              }
            })
          Button('停止')
            .fontSize(13)
            .backgroundColor('#FA2A2D')
            .onClick(() => {
              try {
                this.controller.stop()
                this.resultLog = '调用 controller.stop()'
              } catch (error) {
                this.resultLog = `stop 错误: ${(error as BusinessError).message}`
              }
            })
        }

        Row({ space: 12 }) {
          Button('全屏')
            .fontSize(13)
            .backgroundColor('#9B59B6')
            .onClick(() => {
              try {
                this.controller.requestFullscreen(true)
                this.resultLog = '请求进入全屏'
              } catch (error) {
                this.resultLog = `全屏错误: ${(error as BusinessError).message}`
              }
            })
          Button('退出全屏')
            .fontSize(13)
            .backgroundColor('#666666')
            .onClick(() => {
              try {
                this.controller.exitFullscreen()
                this.resultLog = '退出全屏'
              } catch (error) {
                this.resultLog = `退出全屏错误: ${(error as BusinessError).message}`
              }
            })
          Button('跳转 5s')
            .fontSize(13)
            .backgroundColor('#007DFF')
            .onClick(() => {
              try {
                this.controller.setCurrentTime(5000, SeekMode.Accurate)
                this.resultLog = '跳转到 5000ms'
              } catch (error) {
                this.resultLog = `跳转错误: ${(error as BusinessError).message}`
              }
            })
        }

        // ---- 倍速播放 ----
        Text('3. 播放速度 (PlaybackSpeed)')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 12 })

        Row({ space: 8 }) {
          Text('0.75x').fontSize(12).fontColor('#666666')
          Text('1.0x').fontSize(12).fontColor('#007DFF').fontWeight(FontWeight.Bold)
          Text('1.25x').fontSize(12).fontColor('#666666')
          Text('1.75x').fontSize(12).fontColor('#666666')
          Text('2.0x').fontSize(12).fontColor('#666666')
        }
        .width('90%')
        .justifyContent(FlexAlign.SpaceAround)

        Text('PlaybackSpeed 枚举: Speed_Forward_0_75_X ~ Speed_Forward_2_00_X (API 11+)')
          .fontSize(12)
          .fontColor('#999999')
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16 })

        // ---- 播放状态显示 ----
        Text('4. 播放状态')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 12 })

        Row() {
          Text(`状态: ${this.isPlaying ? '播放中' : '未播放'}`)
            .fontSize(14)
            .fontColor('#333333')
          Text(`  进度: ${this.currentTime}ms`)
            .fontSize(14)
            .fontColor('#666666')
          Text(`  时长: ${this.duration}ms`)
            .fontSize(14)
            .fontColor('#666666')
        }
        .width('90%')
        .padding(12)
        .backgroundColor('#F0F0F0')
        .borderRadius(8)

        // API 说明区
        Column() {
          Text('API 说明')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 8 })
          Text('Video({ src, previewUri?, currentProgressRate?, controller? })')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('.autoPlay(bool) / .controls(bool) / .loop(bool) / .muted(bool)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('.objectFit(ImageFit) — 默认 Cover，不支持 MATRIX')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('VideoController: start/pause/stop/reset/setCurrentTime')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('事件: onPrepared/onStart/onPause/onFinish/onError/onUpdate')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('元服务API: API 11+ | onStop/reset: API 12+')
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
