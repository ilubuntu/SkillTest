# Security Kit 开发经验

## 一、元服务 API 兼容性清单

### 可用 API

| API | 模块 | 说明 | 备注 |
|-----|------|------|------|
| `cryptoFramework.createMd()` | `@ohos.security.cryptoFramework` | 创建摘要对象 (SHA256/MD5 等) | 可用 |
| `md.update()` / `md.digest()` | `@ohos.security.cryptoFramework` | 更新数据/计算摘要 | 可用 |
| `cryptoFramework.createCipher()` | `@ohos.security.cryptoFramework` | 对称/非对称加密 | 可用 |
| `cryptoFramework.createMac()` | `@ohos.security.cryptoFramework` | HMAC 计算 | 可用 |
| `SymKeyGenerator` | `@ohos.security.cryptoFramework` | 对称密钥生成 | 可用 |
| `AsyKeyGenerator` | `@ohos.security.cryptoFramework` | 非对称密钥生成 | 可用 |
| `KeyAgreement` | `@ohos.security.cryptoFramework` | 密钥协商 | 可用 |
| `verifyAccessToken()` | `@ohos.abilityAccessCtrl` | 验证访问令牌 | 可用 |
| `requestPermissionsFromUser()` | `@ohos.abilityAccessCtrl` | 请求用户授权 | 可用 |

### 不可用/受限 API

| API | 模块 | 说明 | 原因 |
|-----|------|------|------|
| `@ohos.security.huks` | HUKS | 通用密钥管理 | 密钥安全存储部分能力可能可用，视 API 版本而定 |
| `@ohos.security.cert` | cert | 证书创建/验证/解析 | 元服务中受限 |
| `@ohos.security.deviceCertificate` | 设备证书 | 设备证书管理 | 仅系统应用可用 |
| `grantUserGrantedPermission()` | `@ohos.abilityAccessCtrl` | 授权管理接口 | 元服务仅支持基础权限申请 |
| `revokeUserGrantedPermission()` | `@ohos.abilityAccessCtrl` | 撤销权限 | 元服务受限 |
| `@ohos.security.component` | 安全组件 | 安全粘贴/保存 | 部分可用 |

## 二、核心调用方式

### Hash 计算

```typescript
import cryptoFramework from '@ohos.security.cryptoFramework'

// 创建摘要对象
let md = cryptoFramework.createMd('SHA256')

// 更新数据（可多次调用）
let inputBytes = new Uint8Array(Array.from('Hello').map(c => c.charCodeAt(0)))
await md.update({ data: inputBytes })

// 计算最终摘要
let result = await md.digest()
// result.data 为 Uint8Array 类型的哈希值
```

### 支持的哈希算法

```
MD5 / SHA1 / SHA224 / SHA256 / SHA384 / SHA512
```

## 三、编译问题与解决方案

1. **SHA1/MD5 安全性**: SHA1 和 MD5 仅用于兼容场景，不推荐用于安全场景，建议使用 SHA256 或更高。
2. **大数据量处理**: 大数据量建议分块 `update()`，避免内存溢出。
3. **HUKS 可用性不确定**: 密钥安全存储和签名验证部分能力可能可用，需根据 API 版本实际测试。
4. **证书验证**: 元服务无法使用系统证书管理 API，需自行实现或调用云端服务。

## 四、降级处理策略

1. **哈希计算** -- 使用 `cryptoFramework.createMd()` 正常实现，完全可用。
2. **加密解密** -- 使用 `cryptoFramework.createCipher()` 正常实现，支持对称和非对称加密。
3. **密钥管理** -- 使用 `cryptoFramework` 的密钥生成器，基础密钥操作可用。
4. **安全存储** -- HUKS 部分能力可用，可尝试基础密钥操作。如不可用，使用 `cryptoFramework` 结合本地存储。
5. **证书验证** -- 需自行实现验证逻辑或调用云端服务完成。
6. **设备级安全** -- 元服务无法使用，属于系统级能力，无替代方案。
