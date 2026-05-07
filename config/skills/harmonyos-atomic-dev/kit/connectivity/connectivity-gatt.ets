/**
 * connectivity-gatt — GATT客户端连接与数据读写
 * @ohos.bluetooth.ble 模块的 GATT Client 操作
 * 元服务API: 需申请 ohos.permission.ACCESS_BLUETOOTH (normal级别)
 */
import { ble, constant } from '@kit.ConnectivityKit'
import { BusinessError } from '@kit.BasicServicesKit'

@ComponentV2
export struct ConnectivityGatt {
  @Local resultText: string = '输入远端设备地址后发起GATT连接'
  @Local deviceAddress: string = '11:22:33:AA:BB:FF'
  @Local connectState: string = '未连接'
  @Local serviceList: string = '--'
  @Local charValue: string = '--'
  @Local isConnecting: boolean = false

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('GATT客户端操作')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20, bottom: 10 })

        Text('ble.createGattClientDevice() / connect() / getServices() / readCharacteristicValue() / writeCharacteristicValue()')
          .fontSize(13)
          .fontColor('#666666')
          .width('90%')
          .textAlign(TextAlign.Center)

        // 结果展示
        Column({ space: 8 }) {
          Text('操作结果')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .width('100%')
          Text(this.resultText)
            .fontSize(13)
            .fontColor(this.resultText.includes('成功') ? '#00B578' :
              (this.resultText.includes('失败') || this.resultText.includes('错误') ? '#E84026' : '#333333'))
            .width('100%')
          Row() {
            Text('连接状态: ')
              .fontSize(12)
              .fontColor('#999999')
            Text(this.connectState)
              .fontSize(12)
              .fontColor(this.connectState === '已连接' ? '#00B578' : '#999999')
              .layoutWeight(1)
          }
          .width('100%')
          Row() {
            Text('服务列表: ')
              .fontSize(12)
              .fontColor('#999999')
            Text(this.serviceList)
              .fontSize(12)
              .layoutWeight(1)
              .maxLines(6)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .width('100%')
          Row() {
            Text('特征值: ')
              .fontSize(12)
              .fontColor('#999999')
            Text(this.charValue)
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

        // 参数输入
        Text('远端设备地址 (MAC)')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        TextInput({ text: this.deviceAddress, placeholder: '输入BLE设备MAC地址 (如 11:22:33:AA:BB:FF)' })
          .width('90%')
          .onChange((value: string) => {
            this.deviceAddress = value
          })

        // 连接控制
        Text('连接控制')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Row({ space: 12 }) {
          Button('发起连接')
            .layoutWeight(1)
            .backgroundColor('#007DFF')
            .borderRadius(8)
            .enabled(!this.isConnecting)
            .onClick(() => this.doConnect())
          Button('断开连接')
            .layoutWeight(1)
            .backgroundColor('#FF9800')
            .borderRadius(8)
            .onClick(() => this.doDisconnect())
        }
        .width('90%')

        // 数据操作
        Text('数据操作')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Row({ space: 12 }) {
          Button('发现服务')
            .layoutWeight(1)
            .backgroundColor('#007DFF')
            .borderRadius(8)
            .onClick(() => this.doDiscoverServices())
          Button('读取特征值')
            .layoutWeight(1)
            .backgroundColor('#00B578')
            .borderRadius(8)
            .onClick(() => this.doReadCharacteristic())
          Button('写入特征值')
            .layoutWeight(1)
            .backgroundColor('#666666')
            .borderRadius(8)
            .onClick(() => this.doWriteCharacteristic())
        }
        .width('90%')

        // 注意事项
        Column() {
          Text('注意事项')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 4 })
          Text('1. 需在 module.json5 中声明 ohos.permission.ACCESS_BLUETOOTH 权限')
            .fontSize(12)
            .fontColor('#996600')
            .width('100%')
          Text('2. 连接前需确保蓝牙已开启且目标设备在范围内')
            .fontSize(12)
            .fontColor('#996600')
            .width('100%')
          Text('3. 连接成功后先进行服务发现再读写特征值')
            .fontSize(12)
            .fontColor('#996600')
            .width('100%')
          Text('4. 每个GattClientDevice对应一个远端设备，使用完需close()')
            .fontSize(12)
            .fontColor('#996600')
            .width('100%')
          Text('5. GATT Server端操作 (createGattServer / addService) 同样可用')
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
          Text('import { ble, constant } from "@kit.ConnectivityKit"')
            .fontSize(12)
            .fontColor('#007DFF')
            .fontFamily('monospace')
          Text('// 创建GATT客户端')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('let gattClient = ble.createGattClientDevice(deviceId)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('// 订阅连接状态变化')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('gattClient.on("BLEConnectionStateChange", (state) => { ... })')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('// 发起连接')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('gattClient.connect()')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('// 发现服务')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('gattClient.getServices() // Promise<Array<GattService>>')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('// 读取/写入特征值')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('gattClient.readCharacteristicValue(characteristic)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('gattClient.writeCharacteristicValue(char, writeType, cb)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('// 关闭客户端')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('gattClient.close()')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('')
            .fontSize(8)
          Text('元服务API: 需 ohos.permission.ACCESS_BLUETOOTH (normal级别)')
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

  private gattClient: ble.GattClientDevice | null = null
  private serviceUuid: string = '00001810-0000-1000-8000-00805F9B34FB'
  private characteristicUuid: string = '00001820-0000-1000-8000-00805F9B34FB'
  private descriptorUuid: string = '00002902-0000-1000-8000-00805F9B34FB'

  private doConnect(): void {
    if (!this.deviceAddress) {
      this.resultText = '请输入设备MAC地址'
      return
    }
    try {
      this.gattClient = ble.createGattClientDevice(this.deviceAddress)
      this.isConnecting = true
      this.connectState = '连接中...'
      this.resultText = '正在发起GATT连接...'

      this.gattClient.on('BLEConnectionStateChange', (stateInfo: ble.BLEConnectionChangeState) => {
        let stateStr = ''
        switch (stateInfo.state) {
          case constant.ProfileConnectionState.STATE_DISCONNECTED:
            stateStr = '已断开'
            break
          case constant.ProfileConnectionState.STATE_CONNECTING:
            stateStr = '连接中'
            break
          case constant.ProfileConnectionState.STATE_CONNECTED:
            stateStr = '已连接'
            break
          case constant.ProfileConnectionState.STATE_DISCONNECTING:
            stateStr = '断开中'
            break
          default:
            stateStr = `未知(${stateInfo.state})`
            break
        }
        this.connectState = stateStr
        this.isConnecting = false
        if (stateInfo.state === constant.ProfileConnectionState.STATE_CONNECTED) {
          this.resultText = 'GATT连接成功'
        } else if (stateInfo.state === constant.ProfileConnectionState.STATE_DISCONNECTED) {
          this.resultText = 'GATT连接已断开'
        }
      })

      this.gattClient.connect()
    } catch (error) {
      this.isConnecting = false
      const err = error as BusinessError
      this.resultText = `连接失败: [${err.code}] ${err.message}`
    }
  }

  private doDisconnect(): void {
    if (!this.gattClient) {
      this.resultText = '未创建GATT客户端'
      return
    }
    try {
      this.gattClient.disconnect()
      this.gattClient.off('BLEConnectionStateChange')
      this.gattClient.close()
      this.gattClient = null
      this.connectState = '未连接'
      this.resultText = '已断开GATT连接'
    } catch (error) {
      const err = error as BusinessError
      this.resultText = `断开失败: [${err.code}] ${err.message}`
    }
  }

  private doDiscoverServices(): void {
    if (!this.gattClient) {
      this.resultText = '请先发起GATT连接'
      return
    }
    try {
      this.gattClient.getServices().then((result: Array<ble.GattService>) => {
        let services: string[] = []
        for (let svc of result) {
          services.push(svc.serviceUuid)
        }
        this.serviceList = services.length > 0 ? services.join('\n') : '无服务'
        this.resultText = `服务发现成功: 找到 ${services.length} 个服务`
      }).catch((err: BusinessError) => {
        this.resultText = `服务发现失败: [${err.code}] ${err.message}`
      })
    } catch (error) {
      const err = error as BusinessError
      this.resultText = `服务发现异常: [${err.code}] ${err.message}`
    }
  }

  private buildCharacteristic(): ble.BLECharacteristic {
    let descBuffer = new ArrayBuffer(2)
    let descValue = new Uint8Array(descBuffer)
    descValue[0] = 1
    descValue[1] = 0
    let descriptors: Array<ble.BLEDescriptor> = [{
      serviceUuid: this.serviceUuid,
      characteristicUuid: this.characteristicUuid,
      descriptorUuid: this.descriptorUuid,
      descriptorValue: descBuffer
    }]
    let charBuffer = new ArrayBuffer(2)
    let charValue = new Uint8Array(charBuffer)
    charValue[0] = 0
    charValue[1] = 1
    return {
      serviceUuid: this.serviceUuid,
      characteristicUuid: this.characteristicUuid,
      characteristicValue: charBuffer,
      descriptors: descriptors
    }
  }

  private doReadCharacteristic(): void {
    if (!this.gattClient) {
      this.resultText = '请先发起GATT连接'
      return
    }
    try {
      let characteristic = this.buildCharacteristic()
      this.gattClient.readCharacteristicValue(characteristic).then((outData: ble.BLECharacteristic) => {
        let value = new Uint8Array(outData.characteristicValue)
        let hexValues: string[] = []
        for (let i = 0; i < outData.characteristicValue.byteLength; i++) {
          hexValues.push(value[i].toString(16).padStart(2, '0'))
        }
        this.charValue = hexValues.join(' ')
        this.resultText = '读取特征值成功'
      }).catch((err: BusinessError) => {
        this.resultText = `读取失败: [${err.code}] ${err.message}`
      })
    } catch (error) {
      const err = error as BusinessError
      this.resultText = `读取异常: [${err.code}] ${err.message}`
    }
  }

  private doWriteCharacteristic(): void {
    if (!this.gattClient) {
      this.resultText = '请先发起GATT连接'
      return
    }
    try {
      let characteristic = this.buildCharacteristic()
      this.gattClient.writeCharacteristicValue(characteristic, ble.GattWriteType.WRITE, (err: BusinessError) => {
        if (err) {
          this.resultText = `写入失败: [${err.code}] ${err.message}`
        } else {
          this.resultText = '写入特征值成功'
        }
      })
    } catch (error) {
      const err = error as BusinessError
      this.resultText = `写入异常: [${err.code}] ${err.message}`
    }
  }
}
