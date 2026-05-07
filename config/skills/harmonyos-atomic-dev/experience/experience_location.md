# Location Kit 开发经验

## 一、元服务 API 兼容性清单

### 可用 API

| API | 模块 | 说明 | 备注 |
|-----|------|------|------|
| `geoLocationManager.getCurrentLocation()` | `@ohos.geoLocationManager` | 获取当前位置（单次） | 需申请位置权限 |
| `geoLocationManager.getLastLocation()` | `@ohos.geoLocationManager` | 获取缓存位置 | 优先 GPS |
| `geoLocationManager.isLocationEnabled()` | `@ohos.geoLocationManager` | 检查定位服务状态 | 可用 |

### 不可用/受限 API

| API | 模块 | 说明 | 原因 |
|-----|------|------|------|
| `on('locationChange')` | `@ohos.geoLocationManager` | 持续定位（位置变化监听） | 元服务中受限 |
| `getAddressesFromLocation()` | `@ohos.geoLocationManager` | 逆地理编码 | 元服务中受限 |
| `getAddressesFromLocationName()` | `@ohos.geoLocationManager` | 地理编码 | 元服务中受限 |
| `on('fenceStatusChange')` | `@ohos.geoLocationManager` | 地理围栏 | 元服务不可用 |
| `on('satelliteStatusChange')` | `@ohos.geoLocationManager` | 卫星状态信息 | 元服务不可用 |
| `LOCATION_IN_BACKGROUND` | 权限 | 后台位置权限 | 元服务不可用 |

## 二、核心调用方式

### 单次定位

```typescript
import geoLocationManager from '@ohos.geoLocationManager'

// 检查定位服务是否开启
let enabled = geoLocationManager.isLocationEnabled()

// 获取当前位置（异步，Promise）
let location = await geoLocationManager.getCurrentLocation()
let lat = location.latitude
let lng = location.longitude
let altitude = location.altitude     // 海拔
let accuracy = location.accuracy     // 精度
let speed = location.speed           // 速度
let direction = location.direction   // 方向
let timestamp = location.timeStamp   // 时间戳

// 获取缓存位置（同步）
let lastLoc = geoLocationManager.getLastLocation()
```

### 权限配置

```json
// module.json5
{
  "requestPermissions": [
    { "name": "ohos.permission.APPROXIMATELY_LOCATION" },
    { "name": "ohos.permission.LOCATION" }
  ]
}
```

## 三、编译问题与解决方案

1. **权限要求**: 精确定位需同时申请 `APPROXIMATELY_LOCATION` 和 `LOCATION` 两个权限，`LOCATION` 为 `user_grant` 类型需运行时动态申请。
2. **异步方法**: `getCurrentLocation()` 返回 Promise，需使用 `await` 或 `.then()` 处理结果。
3. **定位服务状态**: 调用定位前需先通过 `isLocationEnabled()` 检查定位服务是否开启。
4. **持续定位受限**: `on('locationChange')` 在元服务中可能受限，后台定位尤为受限。
5. **地理编码不确定**: `getAddressesFromLocation` / `getAddressesFromLocationName` 需网络支持且在真机验证可用性。

## 四、降级处理策略

1. **单次定位** -- `getCurrentLocation()` 可用，需申请位置权限，满足大多数定位需求。
2. **持续定位** -- 元服务受限，建议使用单次定位 + 定时轮询替代持续监听。
3. **地理编码** -- 可能受限，建议通过服务端地图 API（如华为地图服务）实现地理编码和逆地理编码。
4. **地理围栏** -- 元服务不可用，无替代方案。如需围栏功能建议开发为完整应用。
5. **后台定位** -- 元服务不支持，仅支持前台定位。元服务切到后台后定位能力将被暂停。
