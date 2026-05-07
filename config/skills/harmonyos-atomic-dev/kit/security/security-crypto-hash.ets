/**
 * security-crypto-hash — 加密框架 Hash 计算场景
 * @ohos.security.cryptoFramework 模块的 SHA256/MD5 摘要计算
 * 元服务API: cryptoFramework 支持在元服务中使用
 */
import cryptoFramework from '@ohos.security.cryptoFramework'
import { BusinessError } from '@kit.BasicServicesKit'

@ComponentV2
export struct SecurityCryptoHash {
  @Local resultText: string = '点击按钮计算哈希值'
  @Local inputText: string = 'Hello HarmonyOS'
  @Local hashResult: string = '--'
  @Local selectedAlgo: string = 'SHA256'
  @Local isCalculating: boolean = false
  @Local hashHistory: string[] = []

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('加密框架 - Hash计算')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20, bottom: 10 })

        Text('cryptoFramework.createMd() / update() / digest()')
          .fontSize(13)
          .fontColor('#666666')
          .width('90%')
          .textAlign(TextAlign.Center)

        // 结果展示
        Column({ space: 8 }) {
          Text('计算结果')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .width('100%')
          Text(this.isCalculating ? '计算中...' : this.resultText)
            .fontSize(13)
            .fontColor(this.resultText.includes('成功') ? '#00B578' :
              (this.resultText.includes('失败') || this.resultText.includes('错误') ? '#E84026' : '#333333'))
            .width('100%')
          Row() {
            Text('算法: ')
              .fontSize(12)
              .fontColor('#999999')
            Text(this.selectedAlgo)
              .fontSize(12)
              .fontWeight(FontWeight.Medium)
          }
          .width('100%')
          Row() {
            Text('哈希值: ')
              .fontSize(12)
              .fontColor('#999999')
            Scroll() {
              Text(this.hashResult)
                .fontSize(11)
                .fontFamily('monospace')
                .copyOption(CopyOptions.LocalDevice)
            }
            .layoutWeight(1)
            .align(Alignment.Start)
          }
          .width('100%')
          .alignItems(VerticalAlign.Top)
        }
        .width('90%')
        .padding(16)
        .backgroundColor('#F5F5F5')
        .borderRadius(12)
        .alignItems(HorizontalAlign.Start)

        // 输入文本
        Text('输入文本')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        TextInput({ text: this.inputText, placeholder: '输入要计算哈希的文本' })
          .width('90%')
          .onChange((value: string) => {
            this.inputText = value
          })

        // 算法选择
        Text('哈希算法')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Row({ space: 8 }) {
          Button('SHA256')
            .layoutWeight(1)
            .backgroundColor(this.selectedAlgo === 'SHA256' ? '#007DFF' : '#CCCCCC')
            .borderRadius(8)
            .onClick(() => {
              this.selectedAlgo = 'SHA256'
            })
          Button('SHA384')
            .layoutWeight(1)
            .backgroundColor(this.selectedAlgo === 'SHA384' ? '#007DFF' : '#CCCCCC')
            .borderRadius(8)
            .onClick(() => {
              this.selectedAlgo = 'SHA384'
            })
          Button('SHA512')
            .layoutWeight(1)
            .backgroundColor(this.selectedAlgo === 'SHA512' ? '#007DFF' : '#CCCCCC')
            .borderRadius(8)
            .onClick(() => {
              this.selectedAlgo = 'SHA512'
            })
        }
        .width('90%')

        Row({ space: 8 }) {
          Button('MD5')
            .layoutWeight(1)
            .backgroundColor(this.selectedAlgo === 'MD5' ? '#007DFF' : '#CCCCCC')
            .borderRadius(8)
            .onClick(() => {
              this.selectedAlgo = 'MD5'
            })
          Button('SHA1')
            .layoutWeight(1)
            .backgroundColor(this.selectedAlgo === 'SHA1' ? '#007DFF' : '#CCCCCC')
            .borderRadius(8)
            .onClick(() => {
              this.selectedAlgo = 'SHA1'
            })
          Button('')
            .layoutWeight(1)
            .opacity(0)
            .enabled(false)
        }
        .width('90%')

        // 操作按钮
        Row({ space: 12 }) {
          Button('计算哈希')
            .layoutWeight(1)
            .backgroundColor('#007DFF')
            .borderRadius(8)
            .enabled(!this.isCalculating)
            .onClick(() => this.doHash())
          Button('清空历史')
            .layoutWeight(1)
            .backgroundColor('#FF9800')
            .borderRadius(8)
            .onClick(() => {
              this.hashHistory = []
              this.resultText = '历史已清空'
            })
        }
        .width('90%')

        // 历史记录
        if (this.hashHistory.length > 0) {
          Text('计算历史')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .alignSelf(ItemAlign.Start)
            .margin({ left: 16, top: 8 })

          Column({ space: 6 }) {
            ForEach(this.hashHistory, (item: string) => {
              Text(item)
                .fontSize(11)
                .fontFamily('monospace')
                .fontColor('#333333')
                .width('100%')
                .padding(6)
                .backgroundColor('#FFFFFF')
                .borderRadius(4)
                .copyOption(CopyOptions.LocalDevice)
            }, (item: string, index: number) => `${index}`)
          }
          .width('90%')
          .padding(12)
          .backgroundColor('#F5F5F5')
          .borderRadius(8)
          .alignItems(HorizontalAlign.Start)
        }

        // 提示信息
        Column() {
          Text('注意事项')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 4 })
          Text('1. cryptoFramework 在元服务中支持基础加密操作')
            .fontSize(12)
            .fontColor('#996600')
            .width('100%')
          Text('2. 支持算法: MD5 / SHA1 / SHA224 / SHA256 / SHA384 / SHA512')
            .fontSize(12)
            .fontColor('#996600')
            .width('100%')
          Text('3. SHA1 和 MD5 仅用于兼容场景，不推荐用于安全场景')
            .fontSize(12)
            .fontColor('#E84026')
            .width('100%')
          Text('4. 大数据量建议分块 update，避免内存溢出')
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
          Text('import cryptoFramework from "@ohos.security.cryptoFramework"')
            .fontSize(12)
            .fontColor('#007DFF')
            .fontFamily('monospace')
          Text('// 创建摘要对象')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('let md = cryptoFramework.createMd("SHA256")')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('// 更新数据（可多次调用）')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('await md.update({ data: new Uint8Array(...) })')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('// 计算最终摘要')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('let result = await md.digest()')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('')
            .fontSize(8)
          Text('元服务API: cryptoFramework 支持在元服务中使用')
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

  private async doHash(): Promise<void> {
    if (!this.inputText) {
      this.resultText = '请输入要计算哈希的文本'
      return
    }
    this.isCalculating = true
    this.resultText = '计算中...'
    this.hashResult = '--'

    try {
      let md = cryptoFramework.createMd(this.selectedAlgo)
      let inputBytes = new Uint8Array(Array.from(this.inputText).map(c => c.charCodeAt(0)))
      await md.update({ data: inputBytes })
      let digestResult = await md.digest()

      // 将结果转为十六进制字符串
      let hexResult = this.uint8ArrayToHex(digestResult.data)
      this.hashResult = hexResult
      this.resultText = `${this.selectedAlgo} 哈希计算成功`

      // 添加到历史
      let timestamp = new Date().toLocaleTimeString()
      this.hashHistory.unshift(`[${timestamp}] ${this.selectedAlgo}: ${hexResult.substring(0, 32)}...`)
      if (this.hashHistory.length > 10) {
        this.hashHistory.pop()
      }
    } catch (error) {
      const err = error as BusinessError
      this.resultText = `计算失败: [${err.code}] ${err.message}`
      this.hashResult = '--'
    } finally {
      this.isCalculating = false
    }
  }

  private uint8ArrayToHex(arr: Uint8Array): string {
    let hex = ''
    for (let i = 0; i < arr.length; i++) {
      let byte = arr[i].toString(16)
      hex += byte.length === 1 ? '0' + byte : byte
    }
    return hex.toUpperCase()
  }
}
