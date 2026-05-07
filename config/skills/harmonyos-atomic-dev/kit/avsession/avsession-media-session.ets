/**
 * avsession-media-session — 媒体会话管理场景
 * avSession.createAVSession / setAVMetadata / setAVPlaybackState
 * 元服务API: API 12+ 支持会话创建和元数据设置
 */
import { avSession } from '@kit.AVSessionKit'
import { BusinessError } from '@kit.BasicServicesKit'

@ComponentV2
export struct AvsessionMediaSession {
  @Local resultText: string = '点击按钮创建媒体会话'
  @Local sessionId: string = '--'
  @Local sessionActive: boolean = false
  @Local sessionType: string = 'audio'

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('媒体会话管理')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20, bottom: 10 })

        Text('avSession.createAVSession / setAVMetadata / setAVPlaybackState')
          .fontSize(13)
          .fontColor('#666666')
          .width('90%')
          .textAlign(TextAlign.Center)

        // 结果展示
        Column({ space: 8 }) {
          Text('会话状态')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .width('100%')
          Text(this.resultText)
            .fontSize(13)
            .fontColor(this.sessionActive ? '#00B578' : '#333333')
            .width('100%')
          Row() {
            Text('Session ID: ')
              .fontSize(12)
              .fontColor('#999999')
            Text(this.sessionId)
              .fontSize(12)
              .layoutWeight(1)
          }
          .width('100%')
          Row() {
            Text('状态: ')
              .fontSize(12)
              .fontColor('#999999')
            Text(this.sessionActive ? '已激活' : '未激活')
              .fontSize(12)
              .fontWeight(FontWeight.Medium)
          }
          .width('100%')
        }
        .width('90%')
        .padding(16)
        .backgroundColor('#F5F5F5')
        .borderRadius(12)
        .alignItems(HorizontalAlign.Start)

        // 会话类型选择
        Text('会话类型')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Row({ space: 8 }) {
          Button('audio')
            .layoutWeight(1)
            .backgroundColor(this.sessionType === 'audio' ? '#007DFF' : '#CCCCCC')
            .borderRadius(8)
            .onClick(() => { this.sessionType = 'audio' })
          Button('video')
            .layoutWeight(1)
            .backgroundColor(this.sessionType === 'video' ? '#007DFF' : '#CCCCCC')
            .borderRadius(8)
            .onClick(() => { this.sessionType = 'video' })
        }
        .width('90%')

        // 操作按钮
        Row({ space: 12 }) {
          Button('创建会话')
            .layoutWeight(1)
            .backgroundColor('#007DFF')
            .borderRadius(8)
            .onClick(() => this.createSession())
          Button('激活会话')
            .layoutWeight(1)
            .backgroundColor('#00B578')
            .borderRadius(8)
            .onClick(() => this.activateSession())
        }
        .width('90%')

        Row({ space: 12 }) {
          Button('设置元数据')
            .layoutWeight(1)
            .backgroundColor('#FF9800')
            .borderRadius(8)
            .onClick(() => this.setMetadata())
          Button('销毁会话')
            .layoutWeight(1)
            .backgroundColor('#E84026')
            .borderRadius(8)
            .onClick(() => this.destroySession())
        }
        .width('90%')

        // 提示信息
        Column({ space: 4 }) {
          Text('注意事项')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 4 })
          Text('1. 元服务 API 12+ 支持 createAVSession')
            .fontSize(12)
            .fontColor('#996600')
            .width('100%')
          Text('2. 会话类型: audio / video')
            .fontSize(12)
            .fontColor('#996600')
            .width('100%')
          Text('3. 后台播放需配合长时任务 (backgroundTaskManager)')
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
          Text('import { avSession } from "@kit.AVSessionKit"')
            .fontSize(12)
            .fontColor('#007DFF')
            .fontFamily('monospace')
          Text('// 创建媒体会话')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('let session = await avSession.createAVSession(context, "tag", "audio")')
            .fontSize(12)
            .fontColor('#007DFF')
            .fontFamily('monospace')
          Text('// 设置媒体元数据')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('await session.setAVMetadata({ title: "Song", artist: "Artist" })')
            .fontSize(12)
            .fontColor('#007DFF')
            .fontFamily('monospace')
          Text('// 激活会话')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('await session.activate()')
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

  private async createSession(): Promise<void> {
    try {
      this.resultText = '正在创建会话...'
      const context = getContext(this) as Context
      this.currentSession = await avSession.createAVSession(context, 'demo_session', this.sessionType as avSession.AVSessionType)
      this.sessionId = this.currentSession.sessionId
      this.resultText = `会话创建成功，ID: ${this.sessionId}`
    } catch (error) {
      const err = error as BusinessError
      this.resultText = `创建失败: [${err.code}] ${err.message}`
    }
  }

  private async activateSession(): Promise<void> {
    if (!this.currentSession) {
      this.resultText = '请先创建会话'
      return
    }
    try {
      await this.currentSession.activate()
      this.sessionActive = true
      this.resultText = '会话已激活'
    } catch (error) {
      const err = error as BusinessError
      this.resultText = `激活失败: [${err.code}] ${err.message}`
    }
  }

  private async setMetadata(): Promise<void> {
    if (!this.currentSession) {
      this.resultText = '请先创建会话'
      return
    }
    try {
      const metadata: avSession.AVMetadata = {
        assetId: 'demo_001',
        title: '演示歌曲',
        artist: 'HarmonyOS Demo',
        duration: 180000,
      }
      await this.currentSession.setAVMetadata(metadata)
      this.resultText = '元数据设置成功: 演示歌曲 - HarmonyOS Demo'
    } catch (error) {
      const err = error as BusinessError
      this.resultText = `设置失败: [${err.code}] ${err.message}`
    }
  }

  private async destroySession(): Promise<void> {
    if (!this.currentSession) {
      this.resultText = '无活动会话'
      return
    }
    try {
      await this.currentSession.destroy()
      this.currentSession = null
      this.sessionActive = false
      this.sessionId = '--'
      this.resultText = '会话已销毁'
    } catch (error) {
      const err = error as BusinessError
      this.resultText = `销毁失败: [${err.code}] ${err.message}`
    }
  }
}
