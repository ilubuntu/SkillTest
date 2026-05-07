# Device Kit 开发经验

## 一、元服务 API 兼容性清单

### 可用 API

| API | 模块 | 元服务起始版本 | 说明 | 备注 |
|-----|------|----------------|------|------|
| `deviceInfo.deviceType` | `@ohos.deviceInfo` | API 6 | 设备类型 | phone/tablet/2in1/tv/wearable/car |
| `deviceInfo.brand` | `@ohos.deviceInfo` | API 11 | 设备品牌 | 无需权限，同步获取 |
| `deviceInfo.productModel` | `@ohos.deviceInfo` | API 11 | 设备认证型号 | 如 "NOH-AN00" |
| `deviceInfo.osFullName` | `@ohos.deviceInfo` | API 11 | 系统完整版本 | 如 "HarmonyOS-5.0.0.1(Canary1)" |
| `deviceInfo.sdkApiVersion` | `@ohos.deviceInfo` | API 14 | SDK API 版本号 | number 类型 |
| `display.getDefaultDisplaySync()` | `@ohos.display` | API 7 | 同步获取默认屏幕信息 | 推荐，直接返回 |
| `display.getDisplayByIdSync()` | `@ohos.display` | API 12 | 根据 displayId 获取 Display | 元服务 API 12+ |
| `display.getAllDisplays()` | `@ohos.display` | API 12 | 获取所有屏幕信息 | callback/Promise 均支持 |
| `display.on('add|remove|change')` | `@ohos.display` | API 12 | 监听屏幕插拔变化 | 元服务 API 12+ |
| `display.isFoldable()` | `@ohos.display` | API 12 | 判断设备是否可折叠 | 元服务 API 12+ |
| `display.getFoldStatus()` | `@ohos.display` | API 12 | 获取折叠状态 | 元服务 API 12+ |
| `display.getFoldDisplayMode()` | `@ohos.display` | API 12 | 获取折叠显示模式 | 元服务 API 12+ |
| `display.getCutoutInfo()` | `@ohos.display` | API 12 | 获取刘海/挖孔屏信息 | 元服务 API 12+ |

### 不可用 API（编译错误 11706010）

以下字段在编译时会报 `can't support atomicservice application` 错误：

| API | 模块 | 原因 | 替代方案 |
|-----|------|------|----------|
| `deviceInfo.majorVersion` | `@ohos.deviceInfo` | 元服务不支持 | 从 `osFullName` 字符串解析 |
| `deviceInfo.seniorVersion` | `@ohos.deviceInfo` | 元服务不支持 | 从 `osFullName` 字符串解析 |
| `deviceInfo.featureVersion` | `@ohos.deviceInfo` | 元服务不支持 | 从 `osFullName` 字符串解析 |
| `deviceInfo.buildVersion` | `@ohos.deviceInfo` | 元服务不支持 | 从 `osFullName` 字符串解析 |
| `deviceInfo.osReleaseType` | `@ohos.deviceInfo` | 元服务不支持 | 从 `osFullName` 末尾括号内容判断 |
| `deviceInfo.ODID` | `@ohos.deviceInfo` | 元服务不支持 | 应用级 UUID 存储到首选项 |
| `deviceInfo.distributionOSName` | `@ohos.deviceInfo` | 元服务不支持 | 使用 `osFullName` |
| `deviceInfo.distributionOSVersion` | `@ohos.deviceInfo` | 元服务不支持 | 从 `osFullName` 解析 |
| `deviceInfo.distributionOSApiVersion` | `@ohos.deviceInfo` | 元服务不支持 | 使用 `sdkApiVersion` |
| `deviceInfo.serial` | `@ohos.deviceInfo` | 需系统权限 | 无替代 |
| `deviceInfo.udid` | `@ohos.deviceInfo` | 需系统权限 | 无替代 |
| `deviceInfo.manufacture` | `@ohos.deviceInfo` | 元服务不支持 | 使用 `brand` |
| `deviceInfo.productSeries` | `@ohos.deviceInfo` | 元服务不支持 | 无替代 |
| `deviceInfo.marketName` | `@ohos.deviceInfo` | 元服务不支持 | 无替代 |
| `deviceInfo.displayVersion` | `@ohos.deviceInfo` | 元服务不支持 | 使用 `osFullName` |
| `deviceInfo.buildType` | `@ohos.deviceInfo` | 元服务不支持 | 无替代 |
| `deviceInfo.hardwareModel` | `@ohos.deviceInfo` | 元服务不支持 | 使用 `productModel` |
| `batteryInfo.*` | `@ohos.batteryInfo` | 元服务受限 | 通过后台服务下发 |
| `thermalManager.*` | `@ohos.thermalManager` | 元服务受限 | 无替代 |
| `@ohos.settings` | `@ohos.settings` | 元服务不支持 | 引导用户到系统设置 |
| `@ohos.usbManager` | `@ohos.usbManager` | 元服务不支持 | 无替代 |

## 二、核心调用方式

### 设备信息查询

```typescript
import deviceInfo from '@ohos.deviceInfo'

// 元服务可用字段（同步API，无需权限）
let brand = deviceInfo.brand              // 品牌 "HUAWEI" (API 11+)
let model = deviceInfo.productModel       // 型号 "NOH-AN00" (API 11+)
let type = deviceInfo.deviceType          // 类型 "phone"/"tablet"/"2in1" 等
let osVersion = deviceInfo.osFullName     // "HarmonyOS-5.0.0.1(Canary1)" (API 11+)
let sdkVersion = deviceInfo.sdkApiVersion // 12 (API 14+)
```

### 版本号解析（替代不可用的 majorVersion 等）

`osFullName` 格式为 `"HarmonyOS-x.x.x.x(Type)"` 或 `"OpenHarmony-x.x.x.x"`：

```typescript
function parseVersion(osFullName: string): number[] {
  const parts = osFullName.split('-')
  if (parts.length < 2) return [0, 0, 0, 0]
  const versionPart = parts[1].split('(')[0].trim()
  return versionPart.split('.').map(v => parseInt(v) || 0)
}

// "HarmonyOS-5.0.0.1(Canary1)" => [5, 0, 0, 1]
const [major, senior, feature, build] = parseVersion(deviceInfo.osFullName)
```

### 屏幕显示信息查询

```typescript
import display from '@ohos.display'

// 同步获取默认屏幕（推荐）
let d = display.getDefaultDisplaySync()
let width = d.width           // 屏幕宽度(vp)
let height = d.height         // 屏幕高度(vp)
let dpi = d.densityDPI        // DPI
let density = d.densityPixels // 密度
let orientation = d.orientation // 屏幕方向 (0=竖屏, 1=横屏)
let refreshRate = d.refreshRate // 刷新率

// 物理像素 = vp * density
let physicalWidth = Math.round(d.width * d.densityPixels)
```

## 三、编译问题与解决方案

### 问题 1: 版本号属性编译失败

**错误**: `11706010 can't support atomicservice application` — 访问 `deviceInfo.majorVersion` 等版本号属性时触发。

**原因**: `majorVersion`/`seniorVersion`/`featureVersion`/`buildVersion` 虽然在 API 文档中列出，但在元服务编译中不被支持。

**解决**: 从 `osFullName` 字符串手动解析版本号，参见上方"版本号解析"章节。

### 问题 2: ODID 编译失败

**错误**: `11706010` — 访问 `deviceInfo.ODID` 时触发。

**原因**: 尽管 API 文档标注 ODID 从 API 12 开始支持，但元服务编译仍拒绝该字段。

**解决**: 使用应用级 UUID 存储到 `@ohos.data.preferences` 作为设备标识替代。

### 问题 3: distributionOS* 字段编译失败

**错误**: `11706010` — 访问 `deviceInfo.distributionOSName` 等发行版字段时触发。

**解决**: 使用 `osFullName` 和 `sdkApiVersion` 替代。

### 问题 4: 属性名差异

`deviceInfo.manufacture`（注意拼写）在元服务中不支持，应使用 `brand` 替代。`productModel` 可用但 `marketName` 不可用。

### 问题 5: 异步 display API

在原子化服务中，异步的 `getDefaultDisplay()` 方法可能受限，建议使用同步的 `getDefaultDisplaySync()`。

## 四、降级处理策略

| 需求 | 不可用API | 替代方案 |
|------|-----------|----------|
| 版本号解析 | `majorVersion` 等 4 个字段 | 从 `osFullName` 字符串解析 |
| 设备唯一标识 | `serial`/`udid`/`ODID` | 应用级 UUID 存储到 preferences |
| 广告追踪 | -- | `identifier.getOAID()` (元服务可用) |
| 制造商信息 | `manufacture` | 使用 `brand` |
| 市场名称 | `marketName` | 使用 `productModel` |
| 发行版信息 | `distributionOS*` | 使用 `osFullName` + `sdkApiVersion` |
| 电池信息 | `batteryInfo.*` | 通过后台服务下发设备状态 |
| 热管理 | `thermalManager.*` | 代码做性能优化避免过热 |
| 系统设置 | `@ohos.settings` | 引导用户到系统设置页面手动调整 |
| 屏幕信息 | `getDefaultDisplay()` 异步 | 使用 `getDefaultDisplaySync()` 同步方法 |
