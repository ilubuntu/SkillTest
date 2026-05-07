/**
 * avsession-playback-control — 播放状态与控制命令场景
 * setAVPlaybackState / on('play') / on('pause') / on('seek') / on('setSpeed') /
 * on('setLoopMode') / on('toggleFavorite') / on('fastForward') / on('rewind')
 * 元服务API: API 12+ 支持播放状态设置和控制命令注册
 */
import { avSession } from '@kit.AVSessionKit'
import { BusinessError } from '@kit.BasicServicesKit'

@ComponentV2
export struct AvsessionPlaybackControl {
  @Local resultText: string = '请先创建并激活会话'
  @Local playState: string = '无会话'
  @Local currentSpeed: number = 1.0
  @Local currentLoopMode: number = 0
  @Local isFavorite: boolean = false
  @Local currentPosition: number = 0
  @Local sessionActive: boolean = false

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('播放状态与控制命令')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20, bottom: 10 })

        Text('setAVPlaybackState / on 控制命令注册')
          .fontSize(13)
          .fontColor('#666666')
          .width('90%')
          .textAlign(TextAlign.Center)

        // 状态展示
        Column({ space: 8 }) {
          Text('播放状态')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .width('100%')
          Text(this.resultText)
            .fontSize(13)
            .fontColor(this.sessionActive ? '#00B578' : '#333333')
            .width('100%')
          Row() {
            Text('播放: ')
              .fontSize(12)
              .fontColor('#999999')
            Text(this.playState)
              .fontSize(12)
              .fontWeight(FontWeight.Medium)
          }
          .width('100%')
          Row() {
            Text('速度: ')
              .fontSize(12)
              .fontColor('#999999')
            Text(`${this.currentSpeed}x`)
              .fontSize(12)
          }
          .width('100%')
          Row() {
            Text('位置: ')
              .fontSize(12)
              .fontColor('#999999')
            Text(`${this.currentPosition}ms`)
              .fontSize(12)
          }
          .width('100%')
          Row() {
            Text('收藏: ')
              .fontSize(12)
              .fontColor('#999999')
            Text(this.isFavorite ? '已收藏' : '未收藏')
              .fontSize(12)
          }
          .width('100%')
        }
        .width('90%')
        .padding(16)
        .backgroundColor('#F5F5F5')
        .borderRadius(12)
        .alignItems(HorizontalAlign.Start)

        // 循环模式选择
        Text('循环模式')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Row({ space: 6 }) {
          Button('顺序')
            .layoutWeight(1)
            .fontSize(12)
            .backgroundColor(this.currentLoopMode === 0 ? '#007DFF' : '#CCCCCC')
            .borderRadius(8)
            .onClick(() => this.updateLoopMode(0))
          Button('单曲')
            .layoutWeight(1)
            .fontSize(12)
            .backgroundColor(this.currentLoopMode === 1 ? '#007DFF' : '#CCCCCC')
            .borderRadius(8)
            .onClick(() => this.updateLoopMode(1))
          Button('列表')
            .layoutWeight(1)
            .fontSize(12)
            .backgroundColor(this.currentLoopMode === 2 ? '#007DFF' : '#CCCCCC')
            .borderRadius(8)
            .onClick(() => this.updateLoopMode(2))
          Button('随机')
            .layoutWeight(1)
            .fontSize(12)
            .backgroundColor(this.currentLoopMode === 3 ? '#007DFF' : '#CCCCCC')
            .borderRadius(8)
            .onClick(() => this.updateLoopMode(3))
        }
        .width('90%')

        // 操作按钮
        Button('初始化会话并注册控制命令')
          .width('90%')
          .backgroundColor('#007DFF')
          .borderRadius(8)
          .onClick(() => this.initSession())

        Row({ space: 12 }) {
          Button('播放')
            .layoutWeight(1)
            .backgroundColor('#00B578')
            .borderRadius(8)
            .onClick(() => this.updatePlayState(avSession.PlaybackState.PLAYBACK_STATE_PLAY))
          Button('暂停')
            .layoutWeight(1)
            .backgroundColor('#FF9800')
            .borderRadius(8)
            .onClick(() => this.updatePlayState(avSession.PlaybackState.PLAYBACK_STATE_PAUSE))
        }
        .width('90%')

        Row({ space: 12 }) {
          Button('快进')
            .layoutWeight(1)
            .backgroundColor('#6C63FF')
            .borderRadius(8)
            .onClick(() => this.simulateFastForward())
          Button('快退')
            .layoutWeight(1)
            .backgroundColor('#6C63FF')
            .borderRadius(8)
            .onClick(() => this.simulateRewind())
          Button('收藏切换')
            .layoutWeight(1)
            .backgroundColor(this.isFavorite ? '#E84026' : '#CCCCCC')
            .borderRadius(8)
            .onClick(() => this.toggleFavorite())
        }
        .width('90%')

        // 提示信息
        Column({ space: 4 }) {
          Text('注意事项')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 4 })
          Text('1. 元服务 API 12+ 支持 setAVPlaybackState')
            .fontSize(12)
            .fontColor('#996600')
            .width('100%')
          Text('2. on 控制命令需在 activate 前注册')
            .fontSize(12)
            .fontColor('#996600')
            .width('100%')
          Text('3. 不支持的命令用 off 注销，播控中心自动置灰')
            .fontSize(12)
            .fontColor('#996600')
            .width('100%')
        }
        .width('90%')
        .backgroundColor('#FFF3CD')
        .borderRadius(8)
        .padding(12)

        // API 说明
        Text('API 说明')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Column({ space: 4 }) {
          Text('// 设置播放状态')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('let state: avSession.AVPlaybackState = {')
            .fontSize(12)
            .fontColor('#007DFF')
            .fontFamily('monospace')
          Text('  state: avSession.PlaybackState.PLAYBACK_STATE_PLAY,')
            .fontSize(12)
            .fontColor('#007DFF')
            .fontFamily('monospace')
          Text('  speed: 1.0,')
            .fontSize(12)
            .fontColor('#007DFF')
            .fontFamily('monospace')
          Text('  position: { elapsedTime: 1000, updateTime: Date.now() },')
            .fontSize(12)
            .fontColor('#007DFF')
            .fontFamily('monospace')
          Text('  loopMode: avSession.LoopMode.LOOP_MODE_SINGLE,')
            .fontSize(12)
            .fontColor('#007DFF')
            .fontFamily('monospace')
          Text('  isFavorite: false')
            .fontSize(12)
            .fontColor('#007DFF')
            .fontFamily('monospace')
          Text('}')
            .fontSize(12)
            .fontColor('#007DFF')
            .fontFamily('monospace')
          Text('await session.setAVPlaybackState(state)')
            .fontSize(12)
            .fontColor('#007DFF')
            .fontFamily('monospace')
          Text('')
            .fontSize(8)
          Text('// 注册控制命令回调')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text("session.on('play', () => { /* 播放逻辑 */ })")
            .fontSize(12)
            .fontColor('#007DFF')
            .fontFamily('monospace')
          Text("session.on('seek', (pos) => { /* 跳转逻辑 */ })")
            .fontSize(12)
            .fontColor('#007DFF')
            .fontFamily('monospace')
        }
        .alignItems(HorizontalAlign.Start)
        .margin({ left: 16, bottom: 20 })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
  }

  private currentSession: avSession.AVSession | null = null
  private readonly loopModes: avSession.LoopMode[] = [
    avSession.LoopMode.LOOP_MODE_SEQUENCE,
    avSession.LoopMode.LOOP_MODE_SINGLE,
    avSession.LoopMode.LOOP_MODE_LIST,
    avSession.LoopMode.LOOP_MODE_SHUFFLE,
  ]

  private async initSession(): Promise<void> {
    try {
      this.resultText = '正在初始化会话...'
      const context = getContext(this) as Context

      this.currentSession = await avSession.createAVSession(context, 'playback_ctrl_session', 'audio')

      // 注册控制命令 (必须在 activate 之前)
      this.registerControlCommands()

      // 设置初始元数据
      const metadata: avSession.AVMetadata = {
        assetId: 'ctrl_001',
        title: '播放控制演示',
        artist: 'AVSession Demo',
        duration: 300000,
        // skipIntervals 元服务不支持 SkipIntervals 枚举
      }
      await this.currentSession.setAVMetadata(metadata)

      // 设置初始播放状态
      const playbackState: avSession.AVPlaybackState = {
        state: avSession.PlaybackState.PLAYBACK_STATE_PAUSE,
        speed: this.currentSpeed,
        position: { elapsedTime: 0, updateTime: Date.now() },
        bufferedTime: 300000,
        loopMode: this.loopModes[this.currentLoopMode],
        isFavorite: this.isFavorite,
      }
      await this.currentSession.setAVPlaybackState(playbackState)

      // 激活会话
      await this.currentSession.activate()
      this.sessionActive = true
      this.playState = '已暂停'
      this.resultText = '会话已创建并激活，控制命令已注册'
    } catch (error) {
      const err = error as BusinessError
      this.resultText = `初始化失败: [${err.code}] ${err.message}`
    }
  }

  private registerControlCommands(): void {
    if (!this.currentSession) {
      return
    }
    const session = this.currentSession

    session.on('play', () => {
      this.playState = '播放中'
      this.resultText = '收到 play 命令'
      this.updatePlaybackStateInternal(avSession.PlaybackState.PLAYBACK_STATE_PLAY)
    })

    session.on('pause', () => {
      this.playState = '已暂停'
      this.resultText = '收到 pause 命令'
      this.updatePlaybackStateInternal(avSession.PlaybackState.PLAYBACK_STATE_PAUSE)
    })

    session.on('stop', () => {
      this.playState = '已停止'
      this.resultText = '收到 stop 命令'
      this.updatePlaybackStateInternal(avSession.PlaybackState.PLAYBACK_STATE_STOP)
    })

    session.on('playNext', () => {
      this.resultText = '收到 playNext 命令'
    })

    session.on('playPrevious', () => {
      this.resultText = '收到 playPrevious 命令'
    })

    session.on('seek', (position: number) => {
      this.currentPosition = position
      this.resultText = `收到 seek 命令: ${position}ms`
      const state: avSession.AVPlaybackState = {
        state: avSession.PlaybackState.PLAYBACK_STATE_PLAY,
        position: { elapsedTime: position, updateTime: Date.now() },
      }
      session.setAVPlaybackState(state).catch((err: BusinessError) => {
        this.resultText = `seek 状态更新失败: [${err.code}]`
      })
    })

    session.on('setSpeed', (speed: number) => {
      this.currentSpeed = speed
      this.resultText = `收到 setSpeed 命令: ${speed}x`
      const state: avSession.AVPlaybackState = { speed }
      session.setAVPlaybackState(state).catch((err: BusinessError) => {
        this.resultText = `speed 状态更新失败: [${err.code}]`
      })
    })

    session.on('setLoopMode', (mode: avSession.LoopMode) => {
      if (mode === avSession.LoopMode.LOOP_MODE_SINGLE) {
        this.currentLoopMode = 1
      } else if (mode === avSession.LoopMode.LOOP_MODE_LIST) {
        this.currentLoopMode = 2
      } else if (mode === avSession.LoopMode.LOOP_MODE_SHUFFLE) {
        this.currentLoopMode = 3
      } else {
        this.currentLoopMode = 0
      }
      this.resultText = `收到 setLoopMode 命令: ${mode}`
      const state: avSession.AVPlaybackState = { loopMode: mode }
      session.setAVPlaybackState(state).catch((err: BusinessError) => {
        this.resultText = `loopMode 状态更新失败: [${err.code}]`
      })
    })

    session.on('toggleFavorite', () => {
      this.isFavorite = !this.isFavorite
      this.resultText = `收到 toggleFavorite: ${this.isFavorite ? '已收藏' : '取消收藏'}`
      const state: avSession.AVPlaybackState = { isFavorite: this.isFavorite }
      session.setAVPlaybackState(state).catch((err: BusinessError) => {
        this.resultText = `favorite 状态更新失败: [${err.code}]`
      })
    })

    session.on('fastForward', (time?: number) => {
      const delta = time ?? 10000
      this.currentPosition = Math.min(this.currentPosition + delta, 300000)
      this.resultText = `收到 fastForward: +${delta}ms`
      const state: avSession.AVPlaybackState = {
        position: { elapsedTime: this.currentPosition, updateTime: Date.now() },
      }
      session.setAVPlaybackState(state).catch((err: BusinessError) => {
        this.resultText = `快进状态更新失败: [${err.code}]`
      })
    })

    session.on('rewind', (time?: number) => {
      const delta = time ?? 10000
      this.currentPosition = Math.max(this.currentPosition - delta, 0)
      this.resultText = `收到 rewind: -${delta}ms`
      const state: avSession.AVPlaybackState = {
        position: { elapsedTime: this.currentPosition, updateTime: Date.now() },
      }
      session.setAVPlaybackState(state).catch((err: BusinessError) => {
        this.resultText = `快退状态更新失败: [${err.code}]`
      })
    })
  }

  private async updatePlaybackStateInternal(state: avSession.PlaybackState): Promise<void> {
    if (!this.currentSession) {
      return
    }
    try {
      const playbackState: avSession.AVPlaybackState = {
        state,
        speed: this.currentSpeed,
        position: { elapsedTime: this.currentPosition, updateTime: Date.now() },
        loopMode: this.loopModes[this.currentLoopMode],
        isFavorite: this.isFavorite,
      }
      await this.currentSession.setAVPlaybackState(playbackState)
    } catch (error) {
      const err = error as BusinessError
      this.resultText = `状态更新失败: [${err.code}] ${err.message}`
    }
  }

  private async updatePlayState(state: avSession.PlaybackState): Promise<void> {
    if (!this.currentSession || !this.sessionActive) {
      this.resultText = '请先初始化会话'
      return
    }
    if (state === avSession.PlaybackState.PLAYBACK_STATE_PLAY) {
      this.playState = '播放中'
    } else if (state === avSession.PlaybackState.PLAYBACK_STATE_PAUSE) {
      this.playState = '已暂停'
    } else if (state === avSession.PlaybackState.PLAYBACK_STATE_STOP) {
      this.playState = '已停止'
    } else {
      this.playState = '未知'
    }
    await this.updatePlaybackStateInternal(state)
  }

  private simulateFastForward(): void {
    this.currentPosition = Math.min(this.currentPosition + 10000, 300000)
    this.resultText = `模拟快进: 位置 ${this.currentPosition}ms`
    this.updatePlaybackStateInternal(avSession.PlaybackState.PLAYBACK_STATE_PLAY)
  }

  private simulateRewind(): void {
    this.currentPosition = Math.max(this.currentPosition - 10000, 0)
    this.resultText = `模拟快退: 位置 ${this.currentPosition}ms`
    this.updatePlaybackStateInternal(avSession.PlaybackState.PLAYBACK_STATE_PLAY)
  }

  private async toggleFavorite(): Promise<void> {
    this.isFavorite = !this.isFavorite
    this.resultText = this.isFavorite ? '已收藏' : '取消收藏'
    await this.updatePlaybackStateInternal(avSession.PlaybackState.PLAYBACK_STATE_PLAY)
  }

  private async updateLoopMode(modeIndex: number): Promise<void> {
    this.currentLoopMode = modeIndex
    if (!this.currentSession || !this.sessionActive) {
      this.resultText = '请先初始化会话'
      return
    }
    await this.updatePlaybackStateInternal(avSession.PlaybackState.PLAYBACK_STATE_PLAY)
    this.resultText = `循环模式已切换`
  }
}
