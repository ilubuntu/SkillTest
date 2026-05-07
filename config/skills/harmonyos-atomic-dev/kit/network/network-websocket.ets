/**
 * network-websocket — WebSocket连接场景
 * @ohos.net.webSocket 模块的双向通信
 * 元服务API: 需申请 ohos.permission.INTERNET，域名仅支持 wss:// 协议
 */
import webSocket from '@ohos.net.webSocket'
import { BusinessError } from '@kit.BasicServicesKit'

@ComponentV2
export struct NetworkWebsocket {
  @Local resultText: string = '点击按钮发起WebSocket连接'
  @Local connectionStatus: string = '未连接'
  @Local messages: string = '--'
  @Local sendContent: string = 'Hello Server!'
  @Local wsUrl: string = 'wss://echo.websocket.org'
  @Local isConnected: boolean = false

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('WebSocket连接')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20, bottom: 10 })

        Text('webSocket.createWebSocket() / connect() / send() / close()')
          .fontSize(13)
          .fontColor('#666666')
          .width('90%')
          .textAlign(TextAlign.Center)

        // 连接状态
        Column({ space: 8 }) {
          Text('连接状态')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .width('100%')
          Text(this.connectionStatus)
            .fontSize(13)
            .fontColor(this.isConnected ? '#00B578' : '#E84026')
            .width('100%')
          Text(this.resultText)
            .fontSize(13)
            .fontColor(this.resultText.includes('失败') || this.resultText.includes('错误') ? '#E84026' : '#333333')
            .width('100%')
        }
        .width('90%')
        .padding(16)
        .backgroundColor('#F5F5F5')
        .borderRadius(12)
        .alignItems(HorizontalAlign.Start)

        // 消息展示
        Column({ space: 8 }) {
          Text('收发消息记录')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .width('100%')
          Text(this.messages)
            .fontSize(12)
            .fontColor('#333333')
            .width('100%')
            .maxLines(10)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .width('90%')
        .padding(16)
        .backgroundColor('#F5F5F5')
        .borderRadius(12)
        .alignItems(HorizontalAlign.Start)

        // 参数控制
        Text('服务器地址')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        TextInput({ text: this.wsUrl, placeholder: '输入WebSocket服务器地址（仅支持wss://）' })
          .width('90%')
          .enabled(!this.isConnected)
          .onChange((value: string) => {
            this.wsUrl = value
          })

        Text('发送内容')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        TextInput({ text: this.sendContent, placeholder: '输入要发送的内容' })
          .width('90%')
          .onChange((value: string) => {
            this.sendContent = value
          })

        // 操作按钮
        Row({ space: 12 }) {
          Button('连接')
            .layoutWeight(1)
            .backgroundColor('#007DFF')
            .borderRadius(8)
            .enabled(!this.isConnected)
            .onClick(() => this.doConnect())
          Button('发送')
            .layoutWeight(1)
            .backgroundColor('#00B578')
            .borderRadius(8)
            .enabled(this.isConnected)
            .onClick(() => this.doSend())
          Button('断开')
            .layoutWeight(1)
            .backgroundColor('#E84026')
            .borderRadius(8)
            .enabled(this.isConnected)
            .onClick(() => this.doClose())
        }
        .width('90%')

        // 提示信息
        Column() {
          Text('注意事项')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 4 })
          Text('1. 需在 module.json5 中声明 ohos.permission.INTERNET 权限')
            .fontSize(12)
            .fontColor('#996600')
            .width('100%')
          Text('2. 域名仅支持 wss:// 协议，不支持 ws://')
            .fontSize(12)
            .fontColor('#996600')
            .width('100%')
          Text('3. webSocket 域名不需要配置端口，默认允许所有端口')
            .fontSize(12)
            .fontColor('#996600')
            .width('100%')
          Text('4. 连接生命周期: connect → on("open") → send → on("message") → close → on("close")')
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
          Text('import webSocket from "@ohos.net.webSocket"')
            .fontSize(12)
            .fontColor('#007DFF')
            .fontFamily('monospace')
          Text('let ws = webSocket.createWebSocket()')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('ws.on("open", (err, value) => { ... })')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('ws.on("message", (err, value) => { ... })')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('ws.on("close", (err, value) => { ... })')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('ws.on("error", (err) => { ... })')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('ws.connect(url)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('ws.send(data)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('ws.close()')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('')
            .fontSize(8)
          Text('元服务API: 需 ohos.permission.INTERNET，域名仅 wss://')
            .fontSize(12)
            .fontColor('#00B578')
            .fontWeight(FontWeight.Medium)
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

  private ws: webSocket.WebSocket | null = null

  private doConnect(): void {
    if (!this.wsUrl) {
      this.resultText = '请输入WebSocket服务器地址'
      return
    }
    this.resultText = '正在连接...'
    this.messages = '--'

    try {
      this.ws = webSocket.createWebSocket()

      this.ws.on('open', (err: BusinessError, value: Object) => {
        if (!err) {
          this.isConnected = true
          this.connectionStatus = '已连接'
          this.resultText = 'WebSocket连接已建立'
        } else {
          this.resultText = `连接打开回调错误: [${err.code}] ${err.message}`
        }
      })

      this.ws.on('message', (err: BusinessError, value: string | ArrayBuffer) => {
        if (!err) {
          const msg = typeof value === 'string' ? value : `[ArrayBuffer: ${(value as ArrayBuffer).byteLength} bytes]`
          this.messages = this.messages === '--' ? `[recv] ${msg}` : `${this.messages}\n[recv] ${msg}`
          this.resultText = '收到服务器消息'
        }
      })

      this.ws.on('close', (err: BusinessError, value: webSocket.CloseResult) => {
        this.isConnected = false
        this.connectionStatus = '已断开'
        this.resultText = `连接已关闭, code: ${value.code}, reason: ${value.reason}`
      })

      this.ws.on('error', (err: BusinessError) => {
        this.resultText = `连接错误: [${err.code}] ${err.message}`
        this.isConnected = false
        this.connectionStatus = '连接错误'
      })

      this.ws.connect(this.wsUrl, (err: BusinessError, value: boolean) => {
        if (err) {
          this.resultText = `连接失败: [${err.code}] ${err.message}`
          this.connectionStatus = '连接失败'
        }
      })
    } catch (error) {
      const err = error as BusinessError
      this.resultText = `连接异常: [${err.code}] ${err.message}`
    }
  }

  private doSend(): void {
    if (!this.ws || !this.isConnected) {
      this.resultText = '请先建立连接'
      return
    }
    try {
      this.ws.send(this.sendContent, (err: BusinessError, value: boolean) => {
        if (!err) {
          this.messages = this.messages === '--' ? `[send] ${this.sendContent}` :
            `${this.messages}\n[send] ${this.sendContent}`
          this.resultText = '消息发送成功'
        } else {
          this.resultText = `发送失败: [${err.code}] ${err.message}`
        }
      })
    } catch (error) {
      const err = error as BusinessError
      this.resultText = `发送异常: [${err.code}] ${err.message}`
    }
  }

  private doClose(): void {
    if (!this.ws) {
      return
    }
    try {
      this.ws.close((err: BusinessError, value: boolean) => {
        if (!err) {
          this.resultText = '断开连接成功'
        } else {
          this.resultText = `断开失败: [${err.code}] ${err.message}`
        }
      })
    } catch (error) {
      const err = error as BusinessError
      this.resultText = `断开异常: [${err.code}] ${err.message}`
    }
  }
}
