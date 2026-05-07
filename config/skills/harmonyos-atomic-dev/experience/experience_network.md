# Network 网络能力开发经验

## 一、元服务网络 API 兼容性清单

### 可用 API

| 模块 | 导入方式 | 权限 | 说明 |
|------|---------|------|------|
| HTTP 数据请求 | `import http from '@ohos.net.http'` | `ohos.permission.INTERNET` | 支持 GET/POST/OPTIONS/HEAD/PUT/DELETE/TRACE/CONNECT |
| WebSocket 连接 | `import webSocket from '@ohos.net.webSocket'` | `ohos.permission.INTERNET` | 双向通信，仅支持 wss:// 协议 |
| 网络连接管理 | `import connection from '@ohos.net.connection'` | `ohos.permission.GET_NETWORK_INFO` | 网络状态查询、能力检测、状态监听 |
| MDNS 管理 | `import { mdns } from '@kit.NetworkKit'` | 需连接 Wi-Fi | 局域网服务发现与管理 |

### 不可用 / 受限 API

| 模块 | 限制说明 |
|------|---------|
| `@ohos.net.socket` (TCP/UDP/TLS Socket) | 元服务不支持原始 Socket 连接 |
| `connection.getConnectionProperties()` | 元服务不支持，编译报错 `can't support atomicservice application` |
| `ConnectionProperties.linkAddresses` | 元服务不支持 |
| `ConnectionProperties.ifName` / `dnsAddresses` | 属性不存在，元服务中 ConnectionProperties 类型精简 |
| `@ohos.net.sharing` (网络共享) | 元服务不支持 |
| `@ohos.net.policy` (网络策略) | 元服务不支持 |
| `@ohos.net.netFirewall` (网络防火墙) | 元服务不支持 |
| `@ohos.net.boost` (网络加速) | API 20+，元服务中受限 |

## 二、各场景核心调用方式

### 2.1 HTTP 数据请求

```typescript
import http from '@ohos.net.http'
import { BusinessError } from '@kit.BasicServicesKit'

let httpRequest = http.createHttp()
httpRequest.on('headersReceive', (header: Object) => { /* 响应头回调 */ })

httpRequest.request('https://example.com/api', {
  method: http.RequestMethod.GET,
  header: { 'Content-Type': 'application/json' },
  expectDataType: http.HttpDataType.STRING,
  connectTimeout: 60000,
  readTimeout: 60000,
}, (err: BusinessError, data: http.HttpResponse) => {
  // data.responseCode / data.result / data.header
  httpRequest.destroy() // 不可复用，用完必须销毁
})
```

**关键点**：
- 每个 HttpRequest 对象对应一个请求任务，不可复用
- 使用完毕必须调用 `destroy()` 销毁
- `on('headersReceive')` 比 `request` 回调先返回

### 2.2 WebSocket 连接

```typescript
import webSocket from '@ohos.net.webSocket'
import { BusinessError } from '@kit.BasicServicesKit'

let ws = webSocket.createWebSocket()
ws.on('open', (err: BusinessError, value: Object) => { ws.send("Hello") })
ws.on('message', (err: BusinessError, value: string | ArrayBuffer) => { /* 收到消息 */ })
ws.on('close', (err: BusinessError, value: webSocket.CloseResult) => { /* 关闭回调 */ })
ws.on('error', (err: BusinessError) => { /* 错误回调 */ })
ws.connect('wss://example.com')
```

**关键点**：
- 域名仅支持 `wss://` 协议，不支持 `ws://`
- `on('message')` 回调中 value 类型为 `string | ArrayBuffer`
- 连接生命周期：connect → on('open') → send → on('message') → close → on('close')

### 2.3 网络连接管理

```typescript
import connection from '@ohos.net.connection'
import { BusinessError } from '@kit.BasicServicesKit'

// 查询默认网络
connection.getDefaultNet((err: BusinessError, data: connection.NetHandle) => {
  // data.netId

  // 查询网络能力
  connection.getNetCapabilities(data, (err: BusinessError, caps: connection.NetCapabilities) => {
    // caps.bearerTypes: number[] — 网络类型
    // caps.networkCap: connection.NetCap[] — 网络能力（枚举数组，需 as number 转换）
  })
})

// 网络状态监听
let netConn = connection.createNetConnection()
netConn.on('netAvailable', (data: connection.NetHandle) => { /* 网络可用 */ })
netConn.on('netLost', (data: connection.NetHandle) => { /* 网络丢失 */ })
netConn.on('netUnavailable', () => { /* 网络不可用 */ })
netConn.register((err: BusinessError) => { /* 注册监听 */ })
// 注销：netConn.unregister()
```

**关键点**：
- `NetCapabilities.networkCap` 类型为 `NetCap[]`（枚举数组），不是 `number[]`，需要 `.map(c => c as number)` 转换
- `getConnectionProperties()` 在元服务中不可用
- `NetBearType` 常见值：0=蜂窝, 1=Wi-Fi, 3=以太网
- `NetCap` 常见值：12=INTERNET, 15=NOT_VPN, 16=VALIDATED

### 2.4 MDNS 管理

```typescript
import { mdns } from '@kit.NetworkKit'
import { common } from '@kit.AbilityKit'

let context = getContext(this) as common.UIAbilityContext

// 注册本地服务
let localServiceInfo: mdns.LocalServiceInfo = {
  serviceType: '_http._tcp',
  serviceName: 'MyService',
  port: 5555,
}
mdns.addLocalService(context, localServiceInfo)
mdns.removeLocalService(context, localServiceInfo)

// 发现服务
let discoveryService = mdns.createDiscoveryService(context, '_http._tcp')
discoveryService.on('serviceFound', (data: mdns.LocalServiceInfo) => { /* 发现服务 */ })
discoveryService.on('serviceLost', (data: mdns.LocalServiceInfo) => { /* 服务丢失 */ })
discoveryService.startSearchingMDNS()
discoveryService.stopSearchingMDNS()
```

**关键点**：
- 需要获取 `UIAbilityContext`
- 设备需连接 Wi-Fi
- `DiscoveryEventInfo` 类型中没有 `serviceType` 属性
- 服务类型格式：`_<service>._<proto>`（如 `_http._tcp`、`_print._tcp`）

## 三、域名管控

元服务网络请求受域名管控约束：

| 服务器类型 | 协议要求 | 端口规则 |
|-----------|---------|---------|
| httpRequest | `https://` | 配置端口则仅限该端口；不配端口则不允许带端口（含默认443） |
| webSocket | `wss://` | 不需要配端口，默认允许所有端口 |
| download | `https://` | 同 httpRequest |
| upload | `https://` | 同 httpRequest |

**限制**：
- 不支持 IP 地址或 localhost
- 单项域名最多 200 个
- 每自然月修改配额 50 次
- 开发阶段可开启「开发中元服务豁免管控」跳过校验

## 四、编译问题与解决方案

### 问题 1：`getConnectionProperties` 不可用

**错误**：`can't support atomicservice application`

**原因**：`connection.getConnectionProperties()` 在元服务中不可用

**解决**：移除该调用，仅使用 `getDefaultNet()` + `getNetCapabilities()` 查询网络信息，用 `netHandle.netId` 展示基本信息

### 问题 2：`NetCap[]` 类型不匹配 `number[]`

**错误**：`Argument of type 'NetCap[] | undefined' is not assignable to parameter of type 'number[]'`

**原因**：`NetCapabilities.networkCap` 返回 `NetCap[]`（枚举数组），而非 `number[]`

**解决**：使用 `.map((c: connection.NetCap) => c as number)` 进行类型转换，并增加 undefined 检查

### 问题 3：`DiscoveryEventInfo.serviceType` 不存在

**错误**：`Property 'serviceType' does not exist on type 'DiscoveryEventInfo'`

**原因**：元服务中 `DiscoveryEventInfo` 类型不包含 `serviceType` 属性

**解决**：移除对 `data.serviceType` 的引用，使用外部变量记录服务类型

### 问题 4：`ConnectionProperties` 属性缺失

**错误**：`Property 'ifName'/'dnsAddresses' does not exist on type 'ConnectionProperties'`

**原因**：元服务中 `ConnectionProperties` 类型被精简，仅包含有限属性

**解决**：不使用 `ConnectionProperties` 的细粒度属性查询

## 五、降级处理策略

对于元服务不支持的 Socket 等底层网络能力：
- **TCP/UDP 需求** → 使用 HTTP 请求（`@ohos.net.http`）替代
- **实时通信需求** → 使用 WebSocket（`@ohos.net.webSocket`）替代
- **网络诊断需求** → 仅可使用 `connection.getNetCapabilities()` 查询网络能力
- **不支持的 API** → 在 UI 中以黄色提示卡片说明限制，保留代码骨架供参考
