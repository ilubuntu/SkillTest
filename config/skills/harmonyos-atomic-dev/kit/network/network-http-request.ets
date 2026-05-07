/**
 * network-http-request — HTTP数据请求场景
 * @ohos.net.http 模块的 GET / POST 请求
 * 元服务API: 需申请 ohos.permission.INTERNET，需配置服务器域名
 */
import http from '@ohos.net.http'
import { BusinessError } from '@kit.BasicServicesKit'

@ComponentV2
export struct NetworkHttpRequest {
  @Local resultText: string = '点击按钮发起HTTP请求'
  @Local responseCode: number = -1
  @Local responseHeader: string = '--'
  @Local responseBody: string = '--'
  @Local requestUrl: string = 'https://httpbin.org/get'
  @Local requestMethod: http.RequestMethod = http.RequestMethod.GET
  @Local isLoading: boolean = false

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('HTTP数据请求')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20, bottom: 10 })

        Text('http.createHttp() / request() / on("headersReceive") / destroy()')
          .fontSize(13)
          .fontColor('#666666')
          .width('90%')
          .textAlign(TextAlign.Center)

        // 结果展示
        Column({ space: 8 }) {
          Text('请求结果')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .width('100%')
          Text(this.isLoading ? '请求中...' : this.resultText)
            .fontSize(13)
            .fontColor(this.resultText.includes('成功') ? '#00B578' :
              (this.resultText.includes('失败') || this.resultText.includes('错误') ? '#E84026' : '#333333'))
            .width('100%')
          Row() {
            Text('状态码: ')
              .fontSize(12)
              .fontColor('#999999')
            Text(this.responseCode >= 0 ? `${this.responseCode}` : '--')
              .fontSize(12)
              .layoutWeight(1)
          }
          .width('100%')
          Row() {
            Text('响应头: ')
              .fontSize(12)
              .fontColor('#999999')
            Text(this.responseHeader)
              .fontSize(12)
              .layoutWeight(1)
              .maxLines(3)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .width('100%')
          Row() {
            Text('响应体: ')
              .fontSize(12)
              .fontColor('#999999')
            Text(this.responseBody)
              .fontSize(12)
              .layoutWeight(1)
              .maxLines(6)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .width('100%')
        }
        .width('90%')
        .padding(16)
        .backgroundColor('#F5F5F5')
        .borderRadius(12)
        .alignItems(HorizontalAlign.Start)

        // 参数控制
        Text('请求URL')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        TextInput({ text: this.requestUrl, placeholder: '输入请求URL（需在服务器域名白名单内）' })
          .width('90%')
          .onChange((value: string) => {
            this.requestUrl = value
          })

        Text('请求方法')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Row({ space: 8 }) {
          Button('GET')
            .layoutWeight(1)
            .backgroundColor(this.requestMethod === http.RequestMethod.GET ? '#007DFF' : '#CCCCCC')
            .borderRadius(8)
            .onClick(() => {
              this.requestMethod = http.RequestMethod.GET
            })
          Button('POST')
            .layoutWeight(1)
            .backgroundColor(this.requestMethod === http.RequestMethod.POST ? '#007DFF' : '#CCCCCC')
            .borderRadius(8)
            .onClick(() => {
              this.requestMethod = http.RequestMethod.POST
            })
        }
        .width('90%')

        // 操作按钮
        Row({ space: 12 }) {
          Button('发起请求')
            .layoutWeight(1)
            .backgroundColor('#007DFF')
            .borderRadius(8)
            .enabled(!this.isLoading)
            .onClick(() => this.doRequest())
          Button('取消请求')
            .layoutWeight(1)
            .backgroundColor('#FF9800')
            .borderRadius(8)
            .onClick(() => this.doCancel())
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
          Text('2. 需在 AppGallery Connect 配置服务器域名（仅支持 HTTPS）')
            .fontSize(12)
            .fontColor('#996600')
            .width('100%')
          Text('3. 每个 HttpRequest 对象对应一个请求任务，不可复用')
            .fontSize(12)
            .fontColor('#996600')
            .width('100%')
          Text('4. 开发阶段可开启"开发中元服务豁免管控"跳过域名校验')
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
          Text('import http from "@ohos.net.http"')
            .fontSize(12)
            .fontColor('#007DFF')
            .fontFamily('monospace')
          Text('// 创建请求对象（不可复用）')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('let httpRequest = http.createHttp()')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('// 订阅响应头事件')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('httpRequest.on("headersReceive", (header) => { ... })')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('// 发起请求')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('httpRequest.request(url, options, callback)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('// 销毁请求')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('httpRequest.destroy()')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('')
            .fontSize(8)
          Text('元服务API: 需 ohos.permission.INTERNET，需配置服务器域名')
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

  private httpRequest: http.HttpRequest | null = null

  private doRequest(): void {
    if (!this.requestUrl) {
      this.resultText = '请输入请求URL'
      return
    }
    this.isLoading = true
    this.resultText = '请求中...'
    this.responseCode = -1
    this.responseHeader = '--'
    this.responseBody = '--'

    try {
      this.httpRequest = http.createHttp()
      this.httpRequest.on('headersReceive', (header: Object) => {
        this.responseHeader = JSON.stringify(header)
      })

      const options: http.HttpRequestOptions = {
        method: this.requestMethod,
        header: { 'Content-Type': 'application/json' },
        expectDataType: http.HttpDataType.STRING,
        connectTimeout: 30000,
        readTimeout: 30000,
      }

      if (this.requestMethod === http.RequestMethod.POST) {
        options.extraData = JSON.stringify({ message: 'Hello from HarmonyOS Atomic Service' })
      }

      this.httpRequest.request(this.requestUrl, options, (err: BusinessError, data: http.HttpResponse) => {
        this.isLoading = false
        if (!err) {
          this.responseCode = data.responseCode
          this.responseBody = typeof data.result === 'string' ? data.result : JSON.stringify(data.result)
          if (data.header) {
            this.responseHeader = JSON.stringify(data.header)
          }
          this.resultText = `请求成功，状态码: ${data.responseCode}`
        } else {
          this.resultText = `请求失败: [${err.code}] ${err.message}`
        }
        this.doCleanup()
      })
    } catch (error) {
      this.isLoading = false
      const err = error as BusinessError
      this.resultText = `请求异常: [${err.code}] ${err.message}`
    }
  }

  private doCancel(): void {
    this.doCleanup()
    this.isLoading = false
    this.resultText = '请求已取消'
  }

  private doCleanup(): void {
    if (this.httpRequest) {
      try {
        this.httpRequest.off('headersReceive')
        this.httpRequest.destroy()
      } catch (e) {
        // ignore
      }
      this.httpRequest = null
    }
  }
}
