# HarmonyOS Payment Kit 支付服务开发实践

> 基于 app-wiki 查询 + 实际编译验证 | 2026-04-20

## 概述

本文档总结了 HarmonyOS 支付相关 Kit 在元服务（Atomic Service）场景下的开发经验，覆盖实物商品支付（Payment Kit）和数字商品应用内支付（IAP Kit）。

---

## 元服务支付能力矩阵

元服务支付分为两套 Kit，分别对应不同商品类型：

| 维度 | Payment Kit（实物商品） | IAP Kit（数字商品） |
|------|------------------------|-------------------|
| 模块 | `paymentService` | `iap` |
| 导入 | `@kit.PaymentKit` | `@kit.IAPKit` |
| 商品类型 | 酒店、出行、充值缴费等实物 | 消耗型、非消耗型、订阅型 |
| 核心API | `requestPayment` | `createPurchase` / `queryProducts` / `finishPurchase` |
| 元服务支持 | 支持，开发方式与传统应用相同 | 支持，开发方式与传统应用相同 |

---

## 场景 1：Payment Kit — 实物商品支付

> 当前元服务接入仅支持商户基础支付场景。

**文件**: `entry/src/main/ets/payment/payment-request.ets`（struct: `PaymentRequest`）

### 核心 API

```typescript
import { paymentService } from '@kit.PaymentKit'

// 基础支付（Promise 无返回值）
paymentService.requestPayment(context, orderStr)

// 通用收银台（返回 PayResult）
paymentService.requestPayment(context, orderStr, merchantType)
```

### 参数说明

| 参数 | 类型 | 说明 |
|------|------|------|
| context | UIAbilityContext | 上下文，需通过 `common` 接入（`import { common } from '@kit.AbilityKit'`），不传会报 **401 参数错误** |
| orderStr | string | JSON 字符串，由商户服务端生成 |
| merchantType | string | 商户类型（如 'AP'） |

### orderStr 结构

orderStr 是由商户服务端调用华为支付 API 生成后返回给前端的，包含以下关键字段：

```json
{
  "app_id": "***",
  "merc_no": "***",
  "prepay_id": "***",
  "timestamp": "1680259863114",
  "noncestr": "test_noncestr",
  "sign": "***",
  "auth_id": "***"
}
```

通用收银台模式的 orderStr 结构：

```json
{
  "nextAction": "L",
  "linkUrl": "https://example.com/pay",
  "scheme": "",
  "clientToken": "test_token"
}
```

### PayResult 返回值

```typescript
interface PayResult {
  selectedPaymentType?: string  // 用户选择的支付方式
  clientToken?: string          // 客户端 token
  nextStep?: string             // 下一步操作
}
```

### 注意事项

- **orderStr 必须由服务端生成**，前端不应自行拼接
- 元服务场景下的开发方式与传统应用相同
- 不支持虚拟商品，虚拟商品需使用 IAP Kit

---

## 场景 2：IAP Kit — 数字商品应用内支付

**文件**: `entry/src/main/ets/payment/iap-purchase.ets`（struct: `IapPurchase`）

### 核心 API

```typescript
import { iap } from '@kit.IAPKit'

// 查询环境状态
iap.queryEnvironmentStatus(context)

// 查询商品信息
iap.queryProducts(context, { productType, productIds })

// 发起购买
iap.createPurchase(context, { productId, productType, developerPayload })

// 确认发货（消耗型必须调用）
iap.finishPurchase(context, { productType, purchaseToken, purchaseOrderId })
```

### 商品类型

| 枚举值 | 常量 | 说明 |
|--------|------|------|
| 0 | `iap.ProductType.CONSUMABLE` | 消耗型（如游戏币） |
| 1 | `iap.ProductType.NONCONSUMABLE` | 非消耗型（如永久道具） |
| 2 | `iap.ProductType.AUTORENEWABLE` | 自动续期订阅 |
| 3 | `iap.ProductType.NONRENEWABLE` | 非自动续期订阅 |

### 查询商品参数

```typescript
interface QueryProductsParameter {
  productType: iap.ProductType
  productIds: string[]  // 商品 ID 数组
}
```

### 购买参数

```typescript
interface PurchaseParameter {
  productId: string
  productType: iap.ProductType
  developerPayload?: string  // 开发者自定义数据
}
```

### 购买结果

```typescript
interface CreatePurchaseResult {
  purchaseData?: string  // 购买数据，需发到服务端验证
}
```

### IAP 支付流程

```
1. queryEnvironmentStatus — 检查 IAP 环境是否正常
2. queryProducts — 根据 productType 和 productIds 查询商品信息
3. createPurchase — 拉起收银台，用户完成支付
4. 服务端验证 — 将 purchaseData 发送到服务端验证
5. finishPurchase — 验证通过后确认发货（消耗型商品必须调用）
```

### 编译验证

**无编译错误**，两份代码首次编译即通过。主要注意点：

- `iap.ProductType` 枚举需正确使用常量名（如 `CONSUMABLE` 而非数字）
- `queryProducts` 返回 `Product[]` 数组，需判空
- `createPurchase` 返回 `CreatePurchaseResult`，其中 `purchaseData` 可能为空

---

## 导入模块汇总

```typescript
// 实物商品支付
import { paymentService } from '@kit.PaymentKit'
import { common } from '@kit.AbilityKit'
import { BusinessError } from '@kit.BasicServicesKit'

// 数字商品 IAP
import { iap } from '@kit.IAPKit'
import { common } from '@kit.AbilityKit'
import { BusinessError } from '@kit.BasicServicesKit'
```

---

## 注意事项汇总

| 项目 | 说明 |
|------|------|
| 实物 vs 数字 | 实物用 Payment Kit，数字用 IAP Kit，不可混用 |
| 元服务限制 | 当前元服务接入仅支持商户基础支付场景 |
| context 必传 | 需通过 `common` 接入 UIAbilityContext，不传会报 401 参数错误 |
| orderStr 来源 | 必须由商户服务端生成，前端仅传递 |
| IAP 环境检查 | 购买前建议调用 queryEnvironmentStatus 检查 |
| 商品 ID | 需替换为 AGC 配置的实际商品 ID |
| 消耗型确认 | 消耗型商品购买后必须调用 finishPurchase |
| purchaseData 验证 | 需发送到服务端验证，不可仅前端判断 |
| 元服务开发 | 两套 Kit 在元服务场景下开发方式与传统应用相同 |
