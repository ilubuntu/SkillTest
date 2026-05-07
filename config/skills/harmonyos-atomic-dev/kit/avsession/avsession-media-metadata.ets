/**
 * avsession-media-metadata — 扩展元数据场景
 * AVMetadata 扩展字段: lyric / singleLyricText / avQueueName / avQueueId /
 * avQueueImage / displayTags / skipIntervals / previousAssetId / nextAssetId
 * 元服务API: API 12+ 支持 AVMetadata 全量字段
 */
import { avSession } from '@kit.AVSessionKit'
import { BusinessError } from '@kit.BasicServicesKit'

@ComponentV2
export struct AvsessionMediaMetadata {
  @Local resultText: string = '请先创建会话'
  @Local currentTitle: string = '春江花月夜'
  @Local currentArtist: string = '传统民乐'
  @Local currentLyric: string = '[00:00.00]春江潮水连海平\n[00:05.00]海上明月共潮生'
  @Local queueName: string = '古典音乐精选'
  @Local hasQueueInfo: boolean = false
  @Local hasLyrics: boolean = false
  @Local hasDisplayTag: boolean = false
  @Local sessionActive: boolean = false

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('扩展元数据')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20, bottom: 10 })

        Text('AVMetadata: lyrics / queue / displayTags / skipIntervals')
          .fontSize(13)
          .fontColor('#666666')
          .width('90%')
          .textAlign(TextAlign.Center)

        // 状态展示
        Column({ space: 8 }) {
          Text('元数据状态')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .width('100%')
          Text(this.resultText)
            .fontSize(13)
            .fontColor(this.sessionActive ? '#00B578' : '#333333')
            .width('100%')
          Row() {
            Text('歌词: ')
              .fontSize(12)
              .fontColor('#999999')
            Text(this.hasLyrics ? '已设置' : '未设置')
              .fontSize(12)
          }
          .width('100%')
          Row() {
            Text('歌单: ')
              .fontSize(12)
              .fontColor('#999999')
            Text(this.hasQueueInfo ? this.queueName : '未设置')
              .fontSize(12)
          }
          .width('100%')
          Row() {
            Text('金标: ')
              .fontSize(12)
              .fontColor('#999999')
            Text(this.hasDisplayTag ? 'Audio Vivid' : '未设置')
              .fontSize(12)
          }
          .width('100%')
        }
        .width('90%')
        .padding(16)
        .backgroundColor('#F5F5F5')
        .borderRadius(12)
        .alignItems(HorizontalAlign.Start)

        // 参数控制区
        Text('媒体信息')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Column({ space: 8 }) {
          Row() {
            Text('标题: ')
              .fontSize(13)
              .width(50)
            TextInput({ text: this.currentTitle, placeholder: '歌曲标题' })
              .layoutWeight(1)
              .fontSize(13)
              .onChange((v: string) => { this.currentTitle = v })
          }
          .width('100%')

          Row() {
            Text('艺术家: ')
              .fontSize(13)
              .width(50)
            TextInput({ text: this.currentArtist, placeholder: '艺术家' })
              .layoutWeight(1)
              .fontSize(13)
              .onChange((v: string) => { this.currentArtist = v })
          }
          .width('100%')

          Row() {
            Text('歌单名: ')
              .fontSize(13)
              .width(50)
            TextInput({ text: this.queueName, placeholder: '歌单名称' })
              .layoutWeight(1)
              .fontSize(13)
              .onChange((v: string) => { this.queueName = v })
          }
          .width('100%')
        }
        .width('90%')
        .padding(12)
        .backgroundColor('#F8F8F8')
        .borderRadius(8)

        // 歌词输入
        Text('LRC 歌词内容')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        TextArea({ text: this.currentLyric, placeholder: '[mm:ss.xx]歌词内容' })
          .width('90%')
          .height(100)
          .fontSize(12)
          .fontFamily('monospace')
          .onChange((v: string) => { this.currentLyric = v })

        // 操作按钮
        Button('创建会话')
          .width('90%')
          .backgroundColor('#007DFF')
          .borderRadius(8)
          .onClick(() => this.createSession())

        Row({ space: 12 }) {
          Button('设置基础元数据')
            .layoutWeight(1)
            .backgroundColor('#00B578')
            .borderRadius(8)
            .fontSize(13)
            .onClick(() => this.setBasicMetadata())
          Button('设置歌单信息')
            .layoutWeight(1)
            .backgroundColor('#FF9800')
            .borderRadius(8)
            .fontSize(13)
            .onClick(() => this.setQueueMetadata())
        }
        .width('90%')

        Row({ space: 12 }) {
          Button('设置歌词')
            .layoutWeight(1)
            .backgroundColor('#6C63FF')
            .borderRadius(8)
            .fontSize(13)
            .onClick(() => this.setLyricsMetadata())
          Button('设置完整元数据')
            .layoutWeight(1)
            .backgroundColor('#E84026')
            .borderRadius(8)
            .fontSize(13)
            .onClick(() => this.setFullMetadata())
        }
        .width('90%')

        // 提示信息
        Column({ space: 4 }) {
          Text('注意事项')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 4 })
          Text('1. 元服务 API 12+ 支持 AVMetadata 全量字段')
            .fontSize(12)
            .fontColor('#996600')
            .width('100%')
          Text('2. LRC 歌词格式: [mm:ss.xx]歌词内容, 用 \\r\\n 分隔')
            .fontSize(12)
            .fontColor('#996600')
            .width('100%')
          Text('3. 歌单字段: avQueueName / avQueueId / avQueueImage')
            .fontSize(12)
            .fontColor('#996600')
            .width('100%')
          Text('4. displayTags / skipIntervals 元服务中不可用')
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
          Text('// 设置歌词')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text("let metadata: avSession.AVMetadata = {")
            .fontSize(12)
            .fontColor('#007DFF')
            .fontFamily('monospace')
          Text("  assetId: '001', title: 'Song',")
            .fontSize(12)
            .fontColor('#007DFF')
            .fontFamily('monospace')
          Text("  lyric: '[00:25.44]歌词\\r\\n[00:26.44]歌词',")
            .fontSize(12)
            .fontColor('#007DFF')
            .fontFamily('monospace')
          Text("  singleLyricText: '当前歌词行'")
            .fontSize(12)
            .fontColor('#007DFF')
            .fontFamily('monospace')
          Text('}')
            .fontSize(12)
            .fontColor('#007DFF')
            .fontFamily('monospace')
          Text('')
            .fontSize(8)
          Text('// 设置歌单信息')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text("  avQueueName: '我的歌单',")
            .fontSize(12)
            .fontColor('#007DFF')
            .fontFamily('monospace')
          Text("  avQueueId: 'queue_001',")
            .fontSize(12)
            .fontColor('#007DFF')
            .fontFamily('monospace')
          Text('')
            .fontSize(8)
          Text('// displayTags / skipIntervals 元服务不支持')
            .fontSize(12)
            .fontColor('#996600')
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
      this.currentSession = await avSession.createAVSession(context, 'metadata_session', 'audio')

      const metadata: avSession.AVMetadata = {
        assetId: 'meta_001',
        title: this.currentTitle,
        artist: this.currentArtist,
        duration: 240000,
        mediaImage: 'https://example.com/cover.jpg',
      }
      await this.currentSession.setAVMetadata(metadata)
      await this.currentSession.activate()
      this.sessionActive = true
      this.resultText = '会话已创建并激活'
    } catch (error) {
      const err = error as BusinessError
      this.resultText = `创建失败: [${err.code}] ${err.message}`
    }
  }

  private async setBasicMetadata(): Promise<void> {
    if (!this.currentSession) {
      this.resultText = '请先创建会话'
      return
    }
    try {
      const metadata: avSession.AVMetadata = {
        assetId: 'basic_001',
        title: this.currentTitle,
        artist: this.currentArtist,
        album: '古典音乐专辑',
        writer: '张若虚',
        composer: '古曲',
        duration: 240000,
        mediaImage: 'https://example.com/cover.jpg',
        subtitle: '春江花月夜',
        description: '中国传统名曲',
        previousAssetId: 'basic_000',
        nextAssetId: 'basic_002',
        // skipIntervals 元服务不支持 SkipIntervals 枚举
      }
      await this.currentSession.setAVMetadata(metadata)
      this.resultText = '基础元数据设置成功'
    } catch (error) {
      const err = error as BusinessError
      this.resultText = `设置失败: [${err.code}] ${err.message}`
    }
  }

  private async setQueueMetadata(): Promise<void> {
    if (!this.currentSession) {
      this.resultText = '请先创建会话'
      return
    }
    try {
      const metadata: avSession.AVMetadata = {
        assetId: 'queue_001',
        title: this.currentTitle,
        artist: this.currentArtist,
        duration: 240000,
        avQueueName: this.queueName,
        avQueueId: 'queue_classic_001',
        avQueueImage: 'https://example.com/playlist_cover.jpg',
      }
      await this.currentSession.setAVMetadata(metadata)
      this.hasQueueInfo = true
      this.resultText = `歌单信息设置成功: ${this.queueName}`
    } catch (error) {
      const err = error as BusinessError
      this.resultText = `设置失败: [${err.code}] ${err.message}`
    }
  }

  private async setLyricsMetadata(): Promise<void> {
    if (!this.currentSession) {
      this.resultText = '请先创建会话'
      return
    }
    try {
      const metadata: avSession.AVMetadata = {
        assetId: 'lyric_001',
        title: this.currentTitle,
        artist: this.currentArtist,
        duration: 240000,
        lyric: this.currentLyric,
        singleLyricText: '春江潮水连海平',
      }
      await this.currentSession.setAVMetadata(metadata)
      this.hasLyrics = true
      this.resultText = '歌词元数据设置成功'
    } catch (error) {
      const err = error as BusinessError
      this.resultText = `设置失败: [${err.code}] ${err.message}`
    }
  }

  private async setFullMetadata(): Promise<void> {
    if (!this.currentSession) {
      this.resultText = '请先创建会话'
      return
    }
    try {
      const metadata: avSession.AVMetadata = {
        assetId: 'full_001',
        title: this.currentTitle,
        artist: this.currentArtist,
        album: '古典音乐专辑',
        writer: '张若虚',
        composer: '古曲',
        duration: 240000,
        mediaImage: 'https://example.com/cover.jpg',
        subtitle: '春江花月夜',
        description: '中国传统名曲',
        lyric: this.currentLyric,
        singleLyricText: '春江潮水连海平',
        previousAssetId: 'full_000',
        nextAssetId: 'full_002',
        avQueueName: this.queueName,
        avQueueId: 'queue_classic_001',
        avQueueImage: 'https://example.com/playlist_cover.jpg',
        // displayTags 元服务不支持 DisplayTag 枚举
        // skipIntervals 元服务不支持 SkipIntervals 枚举
      }
      await this.currentSession.setAVMetadata(metadata)
      this.hasLyrics = true
      this.hasQueueInfo = true
      this.resultText = '完整元数据设置成功 (含歌词/歌单)'
    } catch (error) {
      const err = error as BusinessError
      this.resultText = `设置失败: [${err.code}] ${err.message}`
    }
  }
}
