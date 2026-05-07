# Connectivity Kit 元服务开发经验

## 一、API 可用性清单

### 可用 API（元服务支持）

| 模块 | 导入方式 | 核心接口 | 权限要求 |
|------|---------|---------|---------|
| @ohos.bluetooth.access | `import { access } from '@kit.ConnectivityKit'` | getState / enableBluetooth / disableBluetooth / on('stateChange') | ohos.permission.ACCESS_BLUETOOTH (normal) |
| @ohos.bluetooth.connection | `import { connection } from '@kit.ConnectivityKit'` | startBluetoothDiscovery / stopBluetoothDiscovery / getRemoteDeviceName / pairDevice / getPairedDevices / on('bluetoothDeviceFind') | ohos.permission.ACCESS_BLUETOOTH (normal) |
| @ohos.bluetooth.ble | `import { ble } from '@kit.ConnectivityKit'` | startAdvertising / stopAdvertising / startBLEScan / stopBLEScan / createGattClientDevice / createGattServer / on('BLEDeviceFind') | ohos.permission.ACCESS_BLUETOOTH (normal) |
| @ohos.bluetooth.constant | `import { constant } from '@kit.ConnectivityKit'` | ProfileConnectionState / BluetoothState 等枚举常量 | 无 |

**判断依据**: `raw/harmonyos-atomic-service/guide/` 目录下有对应的蓝牙开发指南（蓝牙设置开发指导、广播开发指导、通用属性协议开发指导），且使用的权限 `ACCESS_BLUETOOTH` 为 normal 级别，元服务可声明。

**重要修正**: 之前认为所有 Connectivity Kit API 在元服务中不可用是错误的。实际上蓝牙基础功能（access/ble/gatt/connection）在元服务中可用，只需申请 normal 级别的 ACCESS_BLUETOOTH 权限。

### 不可用 API（元服务不支持）

| 模块 | 原因 |
|------|------|
| @ohos.bluetooth.socket | 无原子服务指南，SPP/RFCOMM 串口通信需要更高权限 |
| @ohos.bluetooth.a2dp | 蓝牙音频协议，系统级管理，无原子服务指南 |
| @ohos.bluetooth.hfp | 免提协议，系统级管理 |
| @ohos.bluetooth.hid | 人机接口协议，系统级管理 |
| @ohos.bluetooth.map | 消息访问协议，系统级管理 |
| @ohos.bluetooth.pan | 个人区域网络，系统级管理 |
| @ohos.nfc.controller | 需要 ohos.permission.MANAGE_SECURE_SETTINGS (system级) |
| @ohos.nfc.tag | 需要系统级 NFC 权限 |
| @ohos.nfc.cardEmulation | 需要系统级卡模拟权限 |
| @ohos.nfc.connectedTag | 需要系统级权限 |
| @ohos.wifiManager | 需要 SET_WIFI_INFO / MANAGE_WIFI_CONNECTION (system级) |
| @ohos.wifiManagerExt | 需要系统级权限 |

## 二、各场景核心调用方式

### 2.1 蓝牙开关与状态监听

```typescript
import { access } from '@kit.ConnectivityKit'

// 获取蓝牙状态 (同步)
let state: access.BluetoothState = access.getState()

// 开启/关闭蓝牙
access.enableBluetooth()
access.disableBluetooth()

// 监听状态变化
access.on('stateChange', (data: access.BluetoothState) => {
  console.info(`Bluetooth state: ${data}`)
})
```

**BluetoothState 枚举**: STATE_OFF(0), STATE_TURNING_ON(1), STATE_ON(2), STATE_TURNING_OFF(3), STATE_BLE_TURNING_ON(4), STATE_BLE_ON(5)

### 2.2 设备发现与配对

```typescript
import { connection } from '@kit.ConnectivityKit'

// 订阅设备发现事件
connection.on('bluetoothDeviceFind', (data: Array<string>) => {
  let mac = data[0]
  let name = connection.getRemoteDeviceName(mac)
})

// 开始/停止扫描
connection.startBluetoothDiscovery()
connection.stopBluetoothDiscovery()

// 获取已配对设备
let paired: Array<string> = connection.getPairedDevices()

// 配对设备
connection.pairDevice(deviceId)
```

**注意**: `connection` 从 `@kit.ConnectivityKit` 导入，不是 `@ohos.net.connection`（网络连接模块）。

### 2.3 BLE 广播

```typescript
import { ble } from '@kit.ConnectivityKit'

let setting: ble.AdvertiseSetting = {
  interval: 160,  // 最小160ms
  txPower: 0,
  connectable: true,
}
let advData: ble.AdvertiseData = {
  serviceUuids: ['00001888-0000-1000-8000-00805f9b34fb'],
  manufactureData: [{ manufactureId: 4567, manufactureValue: buffer }],
}
ble.startAdvertising(setting, advData, advResponse)
ble.stopAdvertising()
```

### 2.4 BLE 扫描

```typescript
import { ble } from '@kit.ConnectivityKit'

// 先订阅再扫描
ble.on('BLEDeviceFind', (data: Array<ble.ScanResult>) => {
  // data[0].deviceId 获取设备地址
})
let scanFilter: ble.ScanFilter = { manufactureId: 4567 }
let scanOptions: ble.ScanOptions = {
  interval: 0,
  dutyMode: ble.ScanDuty.SCAN_MODE_LOW_POWER,
  matchMode: ble.MatchMode.MATCH_MODE_AGGRESSIVE,
}
ble.startBLEScan([scanFilter], scanOptions)
ble.stopBLEScan()
ble.off('BLEDeviceFind')  // 停止后取消订阅
```

### 2.5 GATT 客户端操作

```typescript
import { ble, constant } from '@kit.ConnectivityKit'

let gattClient = ble.createGattClientDevice(deviceId)

// 订阅连接状态
gattClient.on('BLEConnectionStateChange', (stateInfo: ble.BLEConnectionChangeState) => {
  // stateInfo.state: STATE_DISCONNECTED / CONNECTING / CONNECTED / DISCONNECTING
})

gattClient.connect()
gattClient.getServices()  // Promise<Array<GattService>>

// 构造特征值
let characteristic: ble.BLECharacteristic = {
  serviceUuid: '...',
  characteristicUuid: '...',
  characteristicValue: buffer,
  descriptors: [...]
}
gattClient.readCharacteristicValue(characteristic)
gattClient.writeCharacteristicValue(characteristic, ble.GattWriteType.WRITE, callback)

// 使用完毕
gattClient.disconnect()
gattClient.close()
```

## 三、编译过程注意事项

1. **模块导入**: 所有蓝牙 API 统一从 `@kit.ConnectivityKit` 导入（access、connection、ble、constant），不要从 `@ohos.bluetooth.*` 单独导入
2. **connection 命名冲突**: `@kit.ConnectivityKit` 的 `connection`（蓝牙连接管理）和 `@ohos.net.connection`（网络连接管理）名称相同，同一文件中不能同时导入
3. **类型安全**: `access.BluetoothState` 枚举可直接用于 switch-case，`constant.ProfileConnectionState` 用于 GATT 连接状态判断
4. **编译通过**: Connectivity Kit 的蓝牙 API 在 SDK 中默认可用，无需额外配置依赖

## 四、降级处理策略

对于元服务中不可用的 Connectivity API，推荐以下降级方案：

| 场景 | 不可用 API | 替代方案 |
|------|-----------|---------|
| 近距离数据传输 | BLE Socket (SPP) | 使用 BLE GATT 读写特征值实现数据通信 |
| 蓝牙音频控制 | A2DP / HFP | 引导用户使用系统蓝牙设置 |
| WiFi 网络管理 | wifiManager | 引导用户在系统设置中配置 WiFi |
| NFC 标签操作 | nfc.tag / nfc.controller | 建议开发为完整应用 |
| 设备间通信 | SPP Socket | 通过云端 HTTP/WebSocket 中转 |
| 物联网设备控制 | 多种受限 | 对于重度蓝牙依赖场景，建议开发完整应用 |
