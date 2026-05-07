/**
 * connectivity-ble-advertising — BLE广播与扫描
 * @ohos.bluetooth.ble 模块的广播发送与BLE扫描
 * 元服务API: 需申请 ohos.permission.ACCESS_BLUETOOTH (normal级别)
 */
import { ble } from '@kit.ConnectivityKit'
import { BusinessError } from '@kit.BasicServicesKit'

@ComponentV2
export struct ConnectivityBleAdvertising {
  @Local resultText: string = '点击按钮控制BLE广播或扫描'
  @Local isAdvertising: boolean = false
  @Local isScanning: boolean = false
  @Local scanResults: string = '--'
  @Local advInterval: string = '160'
  @Local scanCount: number = 0

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('BLE广播与扫描')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20, bottom: 10 })

        Text('ble.startAdvertising() / stopAdvertising() / startBLEScan() / stopBLEScan()')
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
            Text('广播状态: ')
              .fontSize(12)
              .fontColor('#999999')
            Text(this.isAdvertising ? '广播中' : '未广播')
              .fontSize(12)
              .fontColor(this.isAdvertising ? '#00B578' : '#999999')
          }
          .width('100%')
          Row() {
            Text('扫描状态: ')
              .fontSize(12)
              .fontColor('#999999')
            Text(this.isScanning ? '扫描中' : '未扫描')
              .fontSize(12)
              .fontColor(this.isScanning ? '#00B578' : '#999999')
          }
          .width('100%')
          Row() {
            Text('扫描计数: ')
              .fontSize(12)
              .fontColor('#999999')
            Text(`${this.scanCount}`)
              .fontSize(12)
              .layoutWeight(1)
          }
          .width('100%')
          Row() {
            Text('扫描结果: ')
              .fontSize(12)
              .fontColor('#999999')
            Text(this.scanResults)
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

        // 广播参数
        Text('广播间隔 (ms)')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        TextInput({ text: this.advInterval, placeholder: '广播间隔，最小160ms' })
          .width('90%')
          .type(InputType.Number)
          .onChange((value: string) => {
            this.advInterval = value
          })

        // 广播控制按钮
        Text('广播控制')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Row({ space: 12 }) {
          Button('开始广播')
            .layoutWeight(1)
            .backgroundColor('#007DFF')
            .borderRadius(8)
            .enabled(!this.isAdvertising)
            .onClick(() => this.startAdvertising())
          Button('停止广播')
            .layoutWeight(1)
            .backgroundColor('#FF9800')
            .borderRadius(8)
            .enabled(this.isAdvertising)
            .onClick(() => this.stopAdvertising())
        }
        .width('90%')

        // 扫描控制按钮
        Text('BLE扫描控制')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Row({ space: 12 }) {
          Button('开始扫描')
            .layoutWeight(1)
            .backgroundColor('#007DFF')
            .borderRadius(8)
            .enabled(!this.isScanning)
            .onClick(() => this.startScan())
          Button('停止扫描')
            .layoutWeight(1)
            .backgroundColor('#FF9800')
            .borderRadius(8)
            .enabled(this.isScanning)
            .onClick(() => this.stopScan())
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
          Text('2. 广播间隔最小 160ms，范围 160 - 16777215')
            .fontSize(12)
            .fontColor('#996600')
            .width('100%')
          Text('3. 扫描需先订阅 BLEDeviceFind 事件再调用 startBLEScan')
            .fontSize(12)
            .fontColor('#996600')
            .width('100%')
          Text('4. 停止扫描后需调用 off("BLEDeviceFind") 取消订阅')
            .fontSize(12)
            .fontColor('#996600')
            .width('100%')
          Text('5. 实际使用需在真机上测试，模拟器无蓝牙硬件')
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
          Text('import { ble } from "@kit.ConnectivityKit"')
            .fontSize(12)
            .fontColor('#007DFF')
            .fontFamily('monospace')
          Text('// 构造广播参数')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('let setting: ble.AdvertiseSetting = {')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('  interval: 160, txPower: 0, connectable: true')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('}')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('let advData: ble.AdvertiseData = { ... }')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('ble.startAdvertising(setting, advData, advResponse)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('ble.stopAdvertising()')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('')
            .fontSize(8)
          Text('// BLE扫描')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('ble.on("BLEDeviceFind", (data: Array<ble.ScanResult>) => { ... })')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('ble.startBLEScan(filters, options)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('ble.stopBLEScan()')
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

  private startAdvertising(): void {
    try {
      let manufactureValueBuffer = new Uint8Array(4)
      manufactureValueBuffer[0] = 1
      manufactureValueBuffer[1] = 2
      manufactureValueBuffer[2] = 3
      manufactureValueBuffer[3] = 4

      let serviceValueBuffer = new Uint8Array(4)
      serviceValueBuffer[0] = 4
      serviceValueBuffer[1] = 6
      serviceValueBuffer[2] = 7
      serviceValueBuffer[3] = 8

      let interval = parseInt(this.advInterval) || 160
      let setting: ble.AdvertiseSetting = {
        interval: interval,
        txPower: 0,
        connectable: true,
      }
      let manufactureDataUnit: ble.ManufactureData = {
        manufactureId: 4567,
        manufactureValue: manufactureValueBuffer.buffer
      }
      let serviceDataUnit: ble.ServiceData = {
        serviceUuid: '00001888-0000-1000-8000-00805f9b34fb',
        serviceValue: serviceValueBuffer.buffer
      }
      let advData: ble.AdvertiseData = {
        serviceUuids: ['00001888-0000-1000-8000-00805f9b34fb'],
        manufactureData: [manufactureDataUnit],
        serviceData: [serviceDataUnit],
      }
      let advResponse: ble.AdvertiseData = {
        serviceUuids: ['00001888-0000-1000-8000-00805f9b34fb'],
        manufactureData: [manufactureDataUnit],
        serviceData: [serviceDataUnit],
      }
      ble.startAdvertising(setting, advData, advResponse)
      this.isAdvertising = true
      this.resultText = '开始广播成功'
    } catch (error) {
      const err = error as BusinessError
      this.resultText = `广播失败: [${err.code}] ${err.message}`
    }
  }

  private stopAdvertising(): void {
    try {
      ble.stopAdvertising()
      this.isAdvertising = false
      this.resultText = '停止广播成功'
    } catch (error) {
      const err = error as BusinessError
      this.resultText = `停止失败: [${err.code}] ${err.message}`
    }
  }

  private startScan(): void {
    try {
      ble.on('BLEDeviceFind', (data: Array<ble.ScanResult>) => {
        if (data.length > 0) {
          this.scanCount += data.length
          let devices: string[] = []
          for (let i = 0; i < data.length; i++) {
            devices.push(`${data[i].deviceId}`)
          }
          this.scanResults = devices.join('\n')
          this.resultText = `发现 ${data.length} 个BLE设备`
        }
      })
      let scanFilter: ble.ScanFilter = {
        manufactureId: 4567,
      }
      let scanOptions: ble.ScanOptions = {
        interval: 0,
        dutyMode: ble.ScanDuty.SCAN_MODE_LOW_POWER,
        matchMode: ble.MatchMode.MATCH_MODE_AGGRESSIVE
      }
      ble.startBLEScan([scanFilter], scanOptions)
      this.isScanning = true
      this.scanCount = 0
      this.resultText = 'BLE扫描已开始'
    } catch (error) {
      const err = error as BusinessError
      this.resultText = `扫描失败: [${err.code}] ${err.message}`
    }
  }

  private stopScan(): void {
    try {
      ble.stopBLEScan()
    } catch (error) {
      // ignore stop scan error
    }
    try {
      ble.off('BLEDeviceFind')
    } catch (error) {
      // ignore unsubscribe error
    }
    this.isScanning = false
    this.resultText = 'BLE扫描已停止'
  }
}
