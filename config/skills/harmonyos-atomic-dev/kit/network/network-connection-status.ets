/**
 * network-connection-status — 网络连接管理场景
 * @ohos.net.connection 模块 — 网络状态查询、能力检测
 * 元服务API: 需申请 ohos.permission.GET_NETWORK_INFO
 */
import connection from '@ohos.net.connection'
import { BusinessError } from '@kit.BasicServicesKit'

@ComponentV2
export struct NetworkConnectionStatus {
  @Local resultText: string = '点击按钮查询网络状态'
  @Local netType: string = '--'
  @Local netCapabilities: string = '--'
  @Local connectionProperties: string = '--'
  @Local isMonitoring: boolean = false
  @Local monitorLog: string = '--'

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('网络连接管理')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20, bottom: 10 })

        Text('connection.getDefaultNet() / getNetCapabilities() / createNetConnection()')
          .fontSize(13)
          .fontColor('#666666')
          .width('90%')
          .textAlign(TextAlign.Center)

        // 结果展示
        Column({ space: 8 }) {
          Text('查询结果')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .width('100%')
          Text(this.resultText)
            .fontSize(13)
            .fontColor(this.resultText.includes('成功') ? '#00B578' :
              (this.resultText.includes('失败') || this.resultText.includes('错误') ? '#E84026' : '#333333'))
            .width('100%')
          Row() {
            Text('网络类型: ')
              .fontSize(12)
              .fontColor('#999999')
            Text(this.netType)
              .fontSize(12)
              .layoutWeight(1)
          }
          .width('100%')
          Row() {
            Text('网络能力: ')
              .fontSize(12)
              .fontColor('#999999')
            Text(this.netCapabilities)
              .fontSize(12)
              .layoutWeight(1)
              .maxLines(4)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .width('100%')
          Row() {
            Text('连接信息: ')
              .fontSize(12)
              .fontColor('#999999')
            Text(this.connectionProperties)
              .fontSize(12)
              .layoutWeight(1)
              .maxLines(4)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .width('100%')
        }
        .width('90%')
        .padding(16)
        .backgroundColor('#F5F5F5')
        .borderRadius(12)
        .alignItems(HorizontalAlign.Start)

        // 网络监听日志
        Column({ space: 8 }) {
          Row() {
            Text('网络状态监听')
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .layoutWeight(1)
            Text(this.isMonitoring ? '监听中' : '未监听')
              .fontSize(12)
              .fontColor(this.isMonitoring ? '#00B578' : '#999999')
          }
          .width('100%')
          Text(this.monitorLog)
            .fontSize(12)
            .fontColor('#333333')
            .width('100%')
            .maxLines(8)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .width('90%')
        .padding(16)
        .backgroundColor('#F5F5F5')
        .borderRadius(12)
        .alignItems(HorizontalAlign.Start)

        // 操作按钮
        Row({ space: 12 }) {
          Button('查询默认网络')
            .layoutWeight(1)
            .backgroundColor('#007DFF')
            .borderRadius(8)
            .onClick(() => this.doQueryDefaultNet())
          Button('查询网络能力')
            .layoutWeight(1)
            .backgroundColor('#00B578')
            .borderRadius(8)
            .onClick(() => this.doQueryCapabilities())
        }
        .width('90%')

        Row({ space: 12 }) {
          Button('开始监听')
            .layoutWeight(1)
            .backgroundColor('#FF9800')
            .borderRadius(8)
            .enabled(!this.isMonitoring)
            .onClick(() => this.doStartMonitor())
          Button('停止监听')
            .layoutWeight(1)
            .backgroundColor('#999999')
            .borderRadius(8)
            .enabled(this.isMonitoring)
            .onClick(() => this.doStopMonitor())
        }
        .width('90%')

        // 提示信息
        Column() {
          Text('注意事项')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 4 })
          Text('1. 需在 module.json5 中声明 ohos.permission.GET_NETWORK_INFO 权限')
            .fontSize(12)
            .fontColor('#996600')
            .width('100%')
          Text('2. 大部分 API 为异步调用，支持 callback 和 Promise 两种方式')
            .fontSize(12)
            .fontColor('#996600')
            .width('100%')
          Text('3. 网络类型包括: 蜂窝(0)、Wi-Fi(1)、以太网(3)')
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
          Text('import connection from "@ohos.net.connection"')
            .fontSize(12)
            .fontColor('#007DFF')
            .fontFamily('monospace')
          Text('// 获取默认网络')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('connection.getDefaultNet(callback)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('// 查询网络能力')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('connection.getNetCapabilities(netHandle, callback)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('// 创建网络监听对象')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('let conn = connection.createNetConnection()')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('conn.on("netAvailable", callback)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('conn.on("netLost", callback)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('conn.register(callback)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('conn.unregister(callback)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('')
            .fontSize(8)
          Text('元服务API: 需 ohos.permission.GET_NETWORK_INFO')
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

  private netConn: connection.NetConnection | null = null

  private parseBearerType(bearerTypes: number[]): string {
    const typeMap: Record<number, string> = {
      0: '蜂窝网络',
      1: 'Wi-Fi',
      3: '以太网',
    }
    return bearerTypes.map(t => typeMap[t] || `未知(${t})`).join(', ')
  }

  private parseNetCap(caps: number[]): string {
    const capMap: Record<number, string> = {
      0: 'MMS(彩信)',
      11: 'NOT_METERED(免计费)',
      12: 'INTERNET(互联网)',
      15: 'NOT_VPN(非VPN)',
      16: 'VALIDATED(已验证)',
    }
    return caps.map(c => capMap[c] || `${c}`).join(', ')
  }

  private doQueryDefaultNet(): void {
    try {
      connection.getDefaultNet((err: BusinessError, data: connection.NetHandle) => {
        if (!err && data) {
          this.resultText = `获取默认网络成功, netId: ${data.netId}`
          this.doQueryNetCapabilities(data)
        } else {
          this.resultText = `获取默认网络失败: [${err?.code}] ${err?.message}`
        }
      })
    } catch (error) {
      const err = error as BusinessError
      this.resultText = `查询异常: [${err.code}] ${err.message}`
    }
  }

  private doQueryCapabilities(): void {
    this.doQueryDefaultNet()
  }

  private doQueryNetCapabilities(netHandle: connection.NetHandle): void {
    connection.getNetCapabilities(netHandle, (err: BusinessError, data: connection.NetCapabilities) => {
      if (!err && data) {
        this.netType = this.parseBearerType(data.bearerTypes)
        if (data.networkCap) {
          const capNumbers: number[] = data.networkCap.map((c: connection.NetCap) => c as number)
          this.netCapabilities = this.parseNetCap(capNumbers)
        }
        this.resultText = '网络能力查询成功'
        this.connectionProperties = `netId: ${netHandle.netId}`
      } else {
        this.resultText = `查询网络能力失败: [${err?.code}] ${err?.message}`
      }
    })
  }

  private doStartMonitor(): void {
    try {
      this.netConn = connection.createNetConnection()
      const timestamp = (): string => {
        const now = new Date()
        return `${now.getHours().toString().padStart(2, '0')}:${now.getMinutes().toString().padStart(2, '0')}:${now.getSeconds().toString().padStart(2, '0')}`
      }

      this.netConn.on('netAvailable', (data: connection.NetHandle) => {
        this.monitorLog = `${this.monitorLog}\n[${timestamp()}] 网络可用 netId=${data.netId}`
        this.isMonitoring = true
      })

      this.netConn.on('netLost', (data: connection.NetHandle) => {
        this.monitorLog = `${this.monitorLog}\n[${timestamp()}] 网络丢失 netId=${data.netId}`
      })

      this.netConn.on('netUnavailable', () => {
        this.monitorLog = `${this.monitorLog}\n[${timestamp()}] 网络不可用`
      })

      this.netConn.register((err: BusinessError) => {
        if (!err) {
          this.isMonitoring = true
          this.monitorLog = `[${timestamp()}] 开始监听网络状态`
          this.resultText = '网络监听已注册'
        } else {
          this.resultText = `注册监听失败: [${err.code}] ${err.message}`
        }
      })
    } catch (error) {
      const err = error as BusinessError
      this.resultText = `监听异常: [${err.code}] ${err.message}`
    }
  }

  private doStopMonitor(): void {
    if (!this.netConn) {
      return
    }
    try {
      this.netConn.unregister((err: BusinessError) => {
        if (!err) {
          this.isMonitoring = false
          this.resultText = '网络监听已注销'
        } else {
          this.resultText = `注销监听失败: [${err.code}] ${err.message}`
        }
      })
    } catch (error) {
      const err = error as BusinessError
      this.resultText = `注销异常: [${err.code}] ${err.message}`
    }
  }
}
