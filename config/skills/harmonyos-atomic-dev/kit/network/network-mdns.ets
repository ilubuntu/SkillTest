/**
 * network-mdns — MDNS服务发现场景
 * @kit.NetworkKit mdns 模块 — 局域网服务发现与管理
 * 元服务API: 需连接Wi-Fi，需获取 UIAbilityContext
 */
import { mdns } from '@kit.NetworkKit'
import { common } from '@kit.AbilityKit'
import { BusinessError } from '@kit.BasicServicesKit'

@ComponentV2
export struct NetworkMdns {
  @Local resultText: string = '点击按钮执行MDNS操作'
  @Local discoveryLog: string = '--'
  @Local serviceType: string = '_http._tcp'
  @Local serviceName: string = 'MyAtomicService'
  @Local isDiscovering: boolean = false

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('MDNS服务发现')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20, bottom: 10 })

        Text('mdns.addLocalService() / createDiscoveryService() / startSearchingMDNS()')
          .fontSize(13)
          .fontColor('#666666')
          .width('90%')
          .textAlign(TextAlign.Center)

        // 结果展示
        Column({ space: 8 }) {
          Text('执行结果')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .width('100%')
          Text(this.resultText)
            .fontSize(13)
            .fontColor(this.resultText.includes('成功') ? '#00B578' :
              (this.resultText.includes('失败') || this.resultText.includes('错误') ? '#E84026' : '#333333'))
            .width('100%')
        }
        .width('90%')
        .padding(16)
        .backgroundColor('#F5F5F5')
        .borderRadius(12)
        .alignItems(HorizontalAlign.Start)

        // 发现日志
        Column({ space: 8 }) {
          Row() {
            Text('服务发现日志')
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .layoutWeight(1)
            Text(this.isDiscovering ? '搜索中' : '未搜索')
              .fontSize(12)
              .fontColor(this.isDiscovering ? '#00B578' : '#999999')
          }
          .width('100%')
          Text(this.discoveryLog)
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
        Text('服务类型')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        TextInput({ text: this.serviceType, placeholder: '如 _http._tcp, _print._tcp' })
          .width('90%')
          .onChange((value: string) => {
            this.serviceType = value
          })

        Text('服务名称（注册用）')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        TextInput({ text: this.serviceName, placeholder: '输入本地服务名称' })
          .width('90%')
          .onChange((value: string) => {
            this.serviceName = value
          })

        // 操作按钮
        Row({ space: 12 }) {
          Button('注册服务')
            .layoutWeight(1)
            .backgroundColor('#007DFF')
            .borderRadius(8)
            .onClick(() => this.doAddService())
          Button('移除服务')
            .layoutWeight(1)
            .backgroundColor('#E84026')
            .borderRadius(8)
            .onClick(() => this.doRemoveService())
        }
        .width('90%')

        Row({ space: 12 }) {
          Button('开始发现')
            .layoutWeight(1)
            .backgroundColor('#00B578')
            .borderRadius(8)
            .enabled(!this.isDiscovering)
            .onClick(() => this.doStartDiscovery())
          Button('停止发现')
            .layoutWeight(1)
            .backgroundColor('#999999')
            .borderRadius(8)
            .enabled(this.isDiscovering)
            .onClick(() => this.doStopDiscovery())
        }
        .width('90%')

        // 提示信息
        Column() {
          Text('注意事项')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 4 })
          Text('1. 设备需要连接Wi-Fi才能使用MDNS功能')
            .fontSize(12)
            .fontColor('#996600')
            .width('100%')
          Text('2. 需要获取 UIAbilityContext 上下文')
            .fontSize(12)
            .fontColor('#996600')
            .width('100%')
          Text('3. 服务类型格式: _<service>._<proto>，如 _http._tcp')
            .fontSize(12)
            .fontColor('#996600')
            .width('100%')
          Text('4. MDNS用于局域网服务发现，不涉及互联网通信')
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
          Text('import { mdns } from "@kit.NetworkKit"')
            .fontSize(12)
            .fontColor('#007DFF')
            .fontFamily('monospace')
          Text('// 注册本地服务')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('mdns.addLocalService(context, localServiceInfo)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('mdns.removeLocalService(context, localServiceInfo)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('// 创建服务发现')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('let discovery = mdns.createDiscoveryService(context, type)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('discovery.on("serviceFound", callback)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('discovery.on("serviceLost", callback)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('discovery.startSearchingMDNS()')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('discovery.stopSearchingMDNS()')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('')
            .fontSize(8)
          Text('元服务API: 从 API 8 起支持，需Wi-Fi连接')
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

  private discoveryService: mdns.DiscoveryService | null = null
  private localServiceInfo: mdns.LocalServiceInfo = {
    serviceType: '_http._tcp',
    serviceName: 'MyAtomicService',
    port: 5555,
  }

  private getContext(): common.UIAbilityContext {
    return getContext(this) as common.UIAbilityContext
  }

  private doAddService(): void {
    try {
      this.localServiceInfo = {
        serviceType: this.serviceType,
        serviceName: this.serviceName,
        port: 5555,
      }
      const context = this.getContext()
      mdns.addLocalService(context, this.localServiceInfo).then((data: mdns.LocalServiceInfo) => {
        this.resultText = `注册服务成功: ${data.serviceName}.${data.serviceType}`
      }).catch((err: BusinessError) => {
        this.resultText = `注册服务失败: [${err.code}] ${err.message}`
      })
    } catch (error) {
      const err = error as BusinessError
      this.resultText = `注册异常: [${err.code}] ${err.message}`
    }
  }

  private doRemoveService(): void {
    try {
      const context = this.getContext()
      mdns.removeLocalService(context, this.localServiceInfo).then((data: mdns.LocalServiceInfo) => {
        this.resultText = `移除服务成功: ${data.serviceName}.${data.serviceType}`
      }).catch((err: BusinessError) => {
        this.resultText = `移除服务失败: [${err.code}] ${err.message}`
      })
    } catch (error) {
      const err = error as BusinessError
      this.resultText = `移除异常: [${err.code}] ${err.message}`
    }
  }

  private doStartDiscovery(): void {
    try {
      const context = this.getContext()
      this.discoveryService = mdns.createDiscoveryService(context, this.serviceType)

      this.discoveryService.on('discoveryStart', (data: mdns.DiscoveryEventInfo) => {
        this.discoveryLog = `${this.discoveryLog}\n[开始发现]`
        this.isDiscovering = true
      })

      this.discoveryService.on('serviceFound', (data: mdns.LocalServiceInfo) => {
        this.discoveryLog = `${this.discoveryLog}\n[发现服务] ${data.serviceName}.${data.serviceType}`
        this.resultText = `发现服务: ${data.serviceName}`
      })

      this.discoveryService.on('serviceLost', (data: mdns.LocalServiceInfo) => {
        this.discoveryLog = `${this.discoveryLog}\n[服务丢失] ${data.serviceName}.${data.serviceType}`
      })

      this.discoveryService.on('discoveryStop', (data: mdns.DiscoveryEventInfo) => {
        this.isDiscovering = false
        this.discoveryLog = `${this.discoveryLog}\n[停止发现]`
      })

      this.discoveryService.startSearchingMDNS()
      this.resultText = '开始搜索MDNS服务'
      this.discoveryLog = `[搜索] type=${this.serviceType}`
    } catch (error) {
      const err = error as BusinessError
      this.resultText = `发现异常: [${err.code}] ${err.message}`
    }
  }

  private doStopDiscovery(): void {
    if (!this.discoveryService) {
      return
    }
    try {
      this.discoveryService.stopSearchingMDNS()
      this.resultText = '已停止MDNS服务搜索'
    } catch (error) {
      const err = error as BusinessError
      this.resultText = `停止异常: [${err.code}] ${err.message}`
    }
  }
}
