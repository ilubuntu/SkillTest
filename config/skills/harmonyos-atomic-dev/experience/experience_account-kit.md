# Account Kit 开发经验

## 能力概述

Account Kit（华为账号服务）为元服务提供华为账号登录、授权、用户信息获取等能力。核心模块为 `authentication`，从 `@kit.AccountKit` 导入。

## 元服务 API 兼容性清单

### 支持（元服务 API）

| API | 元服务起始版本 | 说明 |
|-----|---------------|------|
| `HuaweiIDProvider` | 4.1.0(11) | 认证服务 Provider，创建各类请求对象 |
| `createLoginWithHuaweiIDRequest()` | 4.1.0(11) | 创建登录请求 |
| `LoginWithHuaweiIDRequest` | 4.1.0(11) | 登录请求对象，含 forceLogin / state / nonce / idTokenSignAlgorithm |
| `LoginWithHuaweiIDResponse` | 4.1.0(11) | 登录响应，含 state 字段 |
| `LoginWithHuaweiIDCredential` | 4.1.0(11) | 登录凭据：openID / unionID / authorizationCode / idToken |
| `IdTokenSignAlgorithm` | 4.1.0(11) | ID Token 签名算法枚举：PS256 / RS256 |
| `AuthenticationController` | 4.1.0(11) | 执行请求的 Controller，构造时需传入 context |
| `executeRequest(callback)` | 4.1.0(11) | callback 异步执行请求 |
| `executeRequest(): Promise` | 4.1.0(11) | Promise 异步执行请求 |
| `AuthenticationRequest` | 4.1.0(11) | 请求父类 |
| `AuthenticationResponse` | 4.1.0(11) | 响应父类 |
| `AuthenticationProvider` | 4.1.0(11) | Provider 父类 |
| `AuthenticationErrorCode` | 4.1.0(11) | 错误码枚举 |
| `createAuthorizationWithHuaweiIDRequest()` | 5.0.0(12) | 创建授权请求 |
| `AuthorizationWithHuaweiIDRequest` | 5.0.0(12) | 授权请求，含 scopes / permissions / supportAtomicService |
| `AuthorizationWithHuaweiIDResponse` | 5.0.0(12) | 授权响应 |
| `AuthorizationWithHuaweiIDCredential` | 5.0.0(12) | 授权凭据：avatarUri / nickName / authorizedScopes |
| `createCancelAuthorizationRequest()` | 5.0.0(12) | 创建取消授权请求 |
| `CancelAuthorizationRequest` | 5.0.0(12) | 取消授权请求 |
| `CancelAuthorizationResponse` | 5.0.0(12) | 取消授权响应 |
| `getHuaweiIDState()` | 5.0.0(12) | 获取登录状态（不依赖网络） |
| `IdType` | 5.0.0(12) | ID 类型枚举：UNION_ID / OPEN_ID / USER_ID |
| `State` | 5.0.0(12) | 登录状态枚举：UNLOGGED_IN / AUTHORIZED / UNAUTHORIZED |
| `StateRequest` / `StateResult` | 5.0.0(12) | 登录状态请求/结果 |

### 不支持（无元服务 API 标记）

| API | 说明 |
|-----|------|
| `getMobileNumberConsistency()` | 手机号一致性校验，无元服务 API 标记，仅普通应用可用 |
| `credential.email` | 邮箱字段，编译报错 `can't support atomicservice application` |

## 核心调用方式

### 登录

```typescript
import { authentication } from '@kit.AccountKit'
import { common } from '@kit.AbilityKit'
import { BusinessError } from '@kit.BasicServicesKit'
import { util } from '@kit.ArkTS'

const context = getContext(this) as common.Context
const provider = new authentication.HuaweiIDProvider()
const loginRequest = provider.createLoginWithHuaweiIDRequest()
loginRequest.forceLogin = true
loginRequest.state = util.generateRandomUUID()
loginRequest.idTokenSignAlgorithm = authentication.IdTokenSignAlgorithm.PS256

const controller = new authentication.AuthenticationController(context)
controller.executeRequest(loginRequest, (error: BusinessError<Object>, data) => {
  if (error) { return }
  const response = data as authentication.LoginWithHuaweiIDResponse
  const credential = response.data
  // credential.openID / unionID / authorizationCode / idToken
})
```

### 授权（获取头像昵称等）

```typescript
import { authentication } from '@kit.AccountKit'
import { common } from '@kit.AbilityKit'
import { BusinessError } from '@kit.BasicServicesKit'
import { util } from '@kit.ArkTS'

const provider = new authentication.HuaweiIDProvider()
const context = getContext(this) as common.Context
const controller = new authentication.AuthenticationController(context)

const authRequest = provider.createAuthorizationWithHuaweiIDRequest()
authRequest.scopes = ['openid', 'profile']
authRequest.permissions = ['idtoken', 'serviceauthcode']
authRequest.forceAuthorization = true
authRequest.state = util.generateRandomUUID()
authRequest.idTokenSignAlgorithm = authentication.IdTokenSignAlgorithm.PS256

controller.executeRequest(authRequest, (error: BusinessError<Object>, data) => {
  if (error) { return }
  const response = data as authentication.AuthorizationWithHuaweiIDResponse
  const credential = response.data
  // credential.avatarUri / nickName / authorizedScopes
})
```

### 取消授权

```typescript
import { authentication } from '@kit.AccountKit'
import { common } from '@kit.AbilityKit'
import { BusinessError } from '@kit.BasicServicesKit'
import { util } from '@kit.ArkTS'

const context = getContext(this) as common.Context
const provider = new authentication.HuaweiIDProvider()
const controller = new authentication.AuthenticationController(context)

const cancelRequest = provider.createCancelAuthorizationRequest()
cancelRequest.state = util.generateRandomUUID()
controller.executeRequest(cancelRequest, (error: BusinessError<Object>, data) => {
  if (error) { return }
  const response = data as authentication.CancelAuthorizationResponse
  // 验证 response.state 与 cancelRequest.state 一致
})
```

### 查询登录状态

```typescript
import { authentication } from '@kit.AccountKit'
import { BusinessError } from '@kit.BasicServicesKit'

const provider = new authentication.HuaweiIDProvider()
const stateRequest: authentication.StateRequest = {
  idType: authentication.IdType.UNION_ID,
  idValue: '<unionID>'
}
provider.getHuaweiIDState(stateRequest).then((result: authentication.StateResult) => {
  // result.state: UNLOGGED_IN / AUTHORIZED / UNAUTHORIZED
}).catch((error: BusinessError) => {
  // 错误处理
})
```

### 获取头像昵称（元服务专用）

元服务获取头像昵称的关键差异：**必须设置 `supportAtomicService = true`**，且 `scopes` 传 `['profile']`。

```typescript
import { authentication } from '@kit.AccountKit'
import { common } from '@kit.AbilityKit'
import { BusinessError } from '@kit.BasicServicesKit'
import { util } from '@kit.ArkTS'

const context = getContext(this) as common.Context
const provider = new authentication.HuaweiIDProvider()
const controller = new authentication.AuthenticationController(context)

const authRequest = provider.createAuthorizationWithHuaweiIDRequest()
authRequest.scopes = ['profile']              // 获取头像昵称的 scope
authRequest.supportAtomicService = true       // 元服务必须设置为 true
authRequest.permissions = ['serviceauthcode'] // 获取 Authorization Code（服务端场景需要）
authRequest.forceAuthorization = true
authRequest.state = util.generateRandomUUID()
authRequest.idTokenSignAlgorithm = authentication.IdTokenSignAlgorithm.PS256

controller.executeRequest(authRequest, (error: BusinessError<Object>, data) => {
  if (error) { return }
  const response = data as authentication.AuthorizationWithHuaweiIDResponse
  // 校验 state 防跨站攻击
  if (response.state && authRequest.state !== response.state) { return }

  const credential = response.data
  const avatarUri = credential?.avatarUri    // 头像下载地址，可直接用于 Image 组件
  const nickName = credential?.nickName      // 用户昵称（未设置时返回绑定的匿名手机号/邮箱）
  const authCode = credential?.authorizationCode // 用于服务端换取 Access Token
})
```

**注意事项**:
- `avatarUri` 是头像下载 URL，可直接传给 `Image(avatarUri)` 组件显示
- 未设置昵称时，`nickName` 默认返回华为账号绑定的匿名手机号或邮箱
- 如需服务端获取头像昵称，可通过 `authorizationCode` 换取 `Access Token`，再调用 REST API

## 关键参数说明

| 参数 | 说明 |
|------|------|
| `forceLogin` | true 时未登录强制拉起登录页 |
| `state` | 建议用 `util.generateRandomUUID()` 生成，响应时校验防跨站攻击 |
| `idTokenSignAlgorithm` | 默认 PS256，更安全；可选 RS256 兼容性更好 |
| `scopes` | openid（默认）/ profile（头像昵称）/ phone（手机号） |
| `permissions` | idtoken / serviceauthcode |
| `supportAtomicService` | 元服务获取头像昵称时**必须**设为 `true`，否则 `scopes: ['profile']` 无法生效 |

## 编译问题与解决

### 问题 1: `email` 字段不支持元服务

**错误**: `11706010 can't support atomicservice application. 'email' can't support atomicservice application.`

**原因**: `AuthorizationWithHuaweiIDCredential.email` 虽然存在于 API 定义中，但在元服务编译时会被拦截。

**解决**: 移除所有对 `credential.email` 的访问。同理，使用 `AuthorizationWithHuaweiIDCredential` 的其他字段时也需确认元服务兼容性。

### 问题 2: getContext 弃用警告

**警告**: `'getContext' has been deprecated.`

**说明**: 这是已有代码的警告，不影响编译。Account Kit 的 `AuthenticationController` 构造需要传入 `common.Context`，通过 `getContext(this) as common.Context` 获取。

### 问题 3: AuthenticationController 需要 UIContext

API 文档示例中使用 `this.getUIContext().getHostContext()`，但在 `@ComponentV2` struct 中需使用 `getContext(this) as common.Context` 传入。两种方式均可正常编译运行。

## 降级处理策略

对于不支持元服务的 API（如 `getMobileNumberConsistency`），采用 UI 骨架 + 黄色提示卡片方案：

1. 保留完整 UI 结构（结果展示区、操作按钮、API 说明）
2. 按钮置灰（`enabled(false)`），背景色改为灰色
3. 添加黄色警告卡片说明限制原因
4. 保留 API 说明供开发者参考

## 常见错误码

| 错误码 | 含义 | 处理建议 |
|--------|------|---------|
| 1001500001 | 指纹证书校验失败 | 检查 module.json5 的 Client ID、使用手动签名 |
| 1001500002 | 重复请求 | 应用无需处理，实现点击防抖即可 |
| 1001502001 | 用户未登录 | 提示登录后重试 |
| 1001502003 | 参数无效 | 检查参数类型和格式 |
| 1001502005 | 网络异常 | 提示检查网络 |
| 1001502012 | 用户取消 | 无需特殊处理 |
| 1001502014 | 未申请权限 | 检查 scope/permission 配置，权限生效最长需 25 小时 |

## 注意事项

1. **大小写敏感**: OpenID / UnionID / GroupUnionID 严格区分大小写
2. **权限生效延迟**: 权限申请后最迟 25 小时生效，修改 `versionCode` 可触发生效
3. **指纹证书生效**: 配置公钥指纹 10 分钟后需修改 `versionCode` 触发生效
4. **调试/发布证书切换**: 需升级元服务版本号
5. **state 校验**: 每次请求都应生成并校验 state 防止跨站攻击
