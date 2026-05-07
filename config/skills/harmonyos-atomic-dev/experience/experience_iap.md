# IAP Kit 开发经验

## 一、元服务 API 兼容性清单

### 可用 API

| API | 模块 | 说明 | 备注 |
|-----|------|------|------|
| `iap.queryEnvironmentStatus()` | `@kit.IAPKit` | 查询 IAP 环境状态 | 可用 |
| `iap.queryProducts()` | `@kit.IAPKit` | 查询商品信息 | 可用 |
| `iap.createPurchase()` | `@kit.IAPKit` | 拉起收银台发起购买 | 可用 |
| `iap.finishPurchase()` | `@kit.IAPKit` | 确认发货 | 消耗型商品必须调用 |
| `iap.ProductType` | `@kit.IAPKit` | 商品类型枚举 | CONSUMABLE/NONCONSUMABLE/AUTORENEWABLE |

### 不可用/受限 API

| API | 模块 | 说明 | 原因 |
|-----|------|------|------|
| `import iap from '@ohos.iap'` | `@ohos.iap` | 旧模块路径 | 元服务中应使用 `@kit.IAPKit` |

## 二、核心调用方式

### IAP 完整流程

```typescript
import { iap } from '@kit.IAPKit'
import { common } from '@kit.AbilityKit'

let context = this.getUIContext().getHostContext() as common.UIAbilityContext

// 1. 检查 IAP 环境
await iap.queryEnvironmentStatus(context)

// 2. 查询商品
let parameter: iap.QueryProductsParameter = {
  productType: iap.ProductType.CONSUMABLE,
  productIds: ['com.example.product1']
}
let products: iap.Product[] = await iap.queryProducts(context, parameter)

// 3. 发起购买
let purchaseParam: iap.PurchaseParameter = {
  productId: 'com.example.product1',
  productType: iap.ProductType.CONSUMABLE,
  developerPayload: 'test_developer_payload'
}
let result: iap.CreatePurchaseResult = await iap.createPurchase(context, purchaseParam)

// 4. 服务端验证 purchaseData（生产环境必须）

// 5. 确认发货（消耗型商品必须调用）
await iap.finishPurchase(context, {
  productType: iap.ProductType.CONSUMABLE,
  purchaseToken: result.purchaseToken,
  purchaseOrderId: result.purchaseOrderId
})
```

### 商品类型

```typescript
iap.ProductType.CONSUMABLE      // 消耗型 (0)
iap.ProductType.NONCONSUMABLE   // 非消耗型 (1)
iap.ProductType.AUTORENEWABLE   // 自动续期订阅 (2)
```

### 关键错误码

```
1001860000: 用户取消
1001860001: 系统内部错误
1001860050: 未登录华为账号
1001860051: 已拥有该商品
1001860054: 地区不支持 IAP
```

## 三、编译问题与解决方案

1. **模块路径至关重要**: 元服务中必须使用 `import { iap } from '@kit.IAPKit'` 而非 `import iap from '@ohos.iap'`。使用错误的模块路径会导致编译或运行时错误。
2. **商品 ID 配置**: 商品 ID 必须在 AppGallery Connect 的 IAP 商品管理中预先配置，否则 `queryProducts` 返回空列表。
3. **context 获取**: 需要使用 `this.getUIContext().getHostContext() as common.UIAbilityContext` 获取正确的上下文。
4. **finishPurchase 必须**: 消耗型商品购买成功后必须调用 `finishPurchase` 确认发货，否则无法再次购买同一商品。
5. **服务端验证**: 生产环境中 `purchaseData` 必须发送到服务端验证，不能仅依赖客户端结果。

## 四、降级处理策略

1. **模块路径** -- 统一使用 `@kit.IAPKit` 路径导入，确保元服务中可用。
2. **实物商品** -- IAP 仅支持数字商品支付，实物商品请使用 Payment Kit（`paymentService` 模块）。
3. **环境检查** -- 购买前务必调用 `queryEnvironmentStatus` 检查 IAP 环境是否可用。
4. **错误处理** -- 对 `1001860000`（用户取消）等常见错误码进行友好提示。
5. **未登录处理** -- 错误码 `1001860050` 表示未登录华为账号，引导用户登录后重试。
