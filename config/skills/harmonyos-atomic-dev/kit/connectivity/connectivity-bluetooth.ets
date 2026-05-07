/**
 * connectivity-bluetooth — 蓝牙设置与设备发现
 * @ohos.bluetooth.access / connection 模块
 * 元服务API: 需申请 ohos.permission.ACCESS_BLUETOOTH (normal级别)
 */
import { access, connection } from '@kit.ConnectivityKit'
import { BusinessError } from '@kit.BasicServicesKit'

@ComponentV2
export struct ConnectivityBluetooth {
  @Local btState: string = '未知'
  @Local resultText: string = '点击按钮查询蓝牙状态'
  @Local stateLog: string = '--'
  @Local discoveredDevices: string = '--'
  @Local pairedDevices: string = '--'

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('蓝牙设置与设备发现')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20, bottom: 10 })

        Text('access.getState() / enableBluetooth() / disableBluetooth() / connection.startBluetoothDiscovery()')
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
            Text('蓝牙状态: ')
              .fontSize(12)
              .fontColor('#999999')
            Text(this.btState)
              .fontSize(12)
              .layoutWeight(1)
          }
          .width('100%')
          Row() {
            Text('状态变更: ')
              .fontSize(12)
              .fontColor('#999999')
            Text(this.stateLog)
              .fontSize(12)
              .layoutWeight(1)
              .maxLines(4)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .width('100%')
          Row() {
            Text('发现设备: ')
              .fontSize(12)
              .fontColor('#999999')
            Text(this.discoveredDevices)
              .fontSize(12)
              .layoutWeight(1)
              .maxLines(4)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .width('100%')
          Row() {
            Text('已配对: ')
              .fontSize(12)
              .fontColor('#999999')
            Text(this.pairedDevices)
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

        // 蓝牙开关控制
        Text('蓝牙开关控制')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Row({ space: 12 }) {
          Button('查询状态')
            .layoutWeight(1)
            .backgroundColor('#007DFF')
            .borderRadius(8)
            .onClick(() => this.queryState())
          Button('开启蓝牙')
            .layoutWeight(1)
            .backgroundColor('#00B578')
            .borderRadius(8)
            .onClick(() => this.enableBt())
          Button('关闭蓝牙')
            .layoutWeight(1)
            .backgroundColor('#FF9800')
            .borderRadius(8)
            .onClick(() => this.disableBt())
        }
        .width('90%')

        // 设备发现与配对
        Text('设备发现与配对')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Row({ space: 12 }) {
          Button('开始扫描')
            .layoutWeight(1)
            .backgroundColor('#007DFF')
            .borderRadius(8)
            .onClick(() => this.startDiscovery())
          Button('停止扫描')
            .layoutWeight(1)
            .backgroundColor('#FF9800')
            .borderRadius(8)
            .onClick(() => this.stopDiscovery())
          Button('配对列表')
            .layoutWeight(1)
            .backgroundColor('#666666')
            .borderRadius(8)
            .onClick(() => this.getPairedDevices())
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
          Text('2. 需在运行时通过 requestPermissionsFromUser 请求用户授权')
            .fontSize(12)
            .fontColor('#996600')
            .width('100%')
          Text('3. 设备发现和配对操作需要蓝牙已开启')
            .fontSize(12)
            .fontColor('#996600')
            .width('100%')
          Text('4. 元服务中蓝牙 API 均通过 @kit.ConnectivityKit 导入')
            .fontSize(12)
            .fontColor('#996600')
            .width('100%')
          Text('5. A2DP / HFP / HID / MAP 等高级蓝牙协议在元服务中不可用')
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
          Text('import { access, connection } from "@kit.ConnectivityKit"')
            .fontSize(12)
            .fontColor('#007DFF')
            .fontFamily('monospace')
          Text('// 获取蓝牙开关状态')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('let state: access.BluetoothState = access.getState()')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('// 开启/关闭蓝牙')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('access.enableBluetooth() / access.disableBluetooth()')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('// 监听蓝牙状态变化')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('access.on("stateChange", (data: access.BluetoothState) => { ... })')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('// 设备发现')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('connection.startBluetoothDiscovery()')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('// 获取远端设备名称 / 配对')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('connection.getRemoteDeviceName(deviceId)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('connection.pairDevice(deviceId)')
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

  private queryState(): void {
    try {
      let state: access.BluetoothState = access.getState()
      this.btState = this.stateToString(state)
      this.resultText = `查询成功: 蓝牙状态 = ${this.btState}`
    } catch (error) {
      const err = error as BusinessError
      this.resultText = `查询失败: [${err.code}] ${err.message}`
    }
  }

  private enableBt(): void {
    try {
      access.enableBluetooth()
      this.resultText = '已发送开启蓝牙请求'
    } catch (error) {
      const err = error as BusinessError
      this.resultText = `开启失败: [${err.code}] ${err.message}`
    }
  }

  private disableBt(): void {
    try {
      access.disableBluetooth()
      this.resultText = '已发送关闭蓝牙请求'
    } catch (error) {
      const err = error as BusinessError
      this.resultText = `关闭失败: [${err.code}] ${err.message}`
    }
  }

  private startDiscovery(): void {
    try {
      connection.on('bluetoothDeviceFind', (data: Array<string>) => {
        this.discoveredDevices = data.join(', ')
        if (data.length > 0) {
          try {
            let name: string = connection.getRemoteDeviceName(data[0])
            this.stateLog = `发现设备: ${data[0]} (${name})`
          } catch (e) {
            this.stateLog = `发现设备: ${data[0]}`
          }
        }
      })
      connection.startBluetoothDiscovery()
      this.resultText = '已开始设备扫描'
    } catch (error) {
      const err = error as BusinessError
      this.resultText = `扫描失败: [${err.code}] ${err.message}`
    }
  }

  private stopDiscovery(): void {
    try {
      connection.stopBluetoothDiscovery()
      try {
        connection.off('bluetoothDeviceFind')
      } catch (e) {
        // ignore unsubscribe error
      }
      this.resultText = '已停止设备扫描'
    } catch (error) {
      const err = error as BusinessError
      this.resultText = `停止失败: [${err.code}] ${err.message}`
    }
  }

  private getPairedDevices(): void {
    try {
      let devices: Array<string> = connection.getPairedDevices()
      this.pairedDevices = devices.length > 0 ? devices.join(', ') : '无配对设备'
      this.resultText = `查询成功: ${devices.length} 个配对设备`
    } catch (error) {
      const err = error as BusinessError
      this.resultText = `查询失败: [${err.code}] ${err.message}`
    }
  }

  private stateToString(state: access.BluetoothState): string {
    switch (state) {
      case access.BluetoothState.STATE_OFF:
        return '关闭 (STATE_OFF)'
      case access.BluetoothState.STATE_TURNING_ON:
        return '正在开启 (STATE_TURNING_ON)'
      case access.BluetoothState.STATE_ON:
        return '已开启 (STATE_ON)'
      case access.BluetoothState.STATE_TURNING_OFF:
        return '正在关闭 (STATE_TURNING_OFF)'
      case access.BluetoothState.STATE_BLE_TURNING_ON:
        return 'BLE开启中'
      case access.BluetoothState.STATE_BLE_ON:
        return 'BLE已开启'
      default:
        return `未知 (${state})`
    }
  }
}
