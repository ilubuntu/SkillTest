# AppGallery Kit (StoreKit) 开发经验

## 一、元服务 API 兼容性清单

### 可用 API

| API | 模块 | 说明 | 备注 |
|-----|------|------|------|
| `review.createReviewManager()` | `@kit.StoreKit` | 创建评论管理器 | 文档标注可用，实际受限 |
| `IAP 支付` | `@kit.IAPKit` | 应用内支付 | 可用 |
| `华为支付` | `@kit.PaymentKit` | 华为支付 | 可用 |
| `广告服务` | `@kit.AdsKit` | 广告 | 可用 |

### 不可用/受限 API

| API | 模块 | 说明 | 原因 |
|-----|------|------|------|
| `review.launchReview()` | `@kit.StoreKit` | 应用内评论 | 原子化服务实际不支持 |
| `inAppUpdate` | `@kit.StoreKit` | 应用内更新 | 元服务由系统管理更新 |
| 浮动窗口 | `@kit.StoreKit` | 引导更新/评论的弹窗 | 元服务不支持浮动窗口 |
| 应用内分发 | StoreKit | 推荐和分发其他应用 | 元服务不支持 |
| `downloadInstall` | StoreKit | 下载安装管理 | 元服务不支持安装其他应用 |
| 评论内容获取 | StoreKit | 获取用户评论 | 开发者无法获取，仅 AGC 后台可见 |

## 二、核心调用方式

### 应用内评论（实际不可用）

```typescript
// 文档标注的用法，但原子化服务实际不支持
import { review } from '@kit.StoreKit'

const reviewManager = review.createReviewManager(context)
await reviewManager.launchReview()

// 实际运行结果: "原子化服务不支持应用内评论 (review)"
```

### 可用的替代方案

```typescript
// IAP 支付（可用）
import { iap } from '@kit.IAPKit'
await iap.queryProducts(context, { productType, productIds })

// 华为支付（可用）
import { paymentService } from '@kit.PaymentKit'
```

## 三、编译问题与解决方案

1. **review 模块导入成功但运行失败**: `import { review } from '@kit.StoreKit'` 可以导入，但 `review.createReviewManager()` 在元服务中实际不可用。运行时会直接返回 "原子化服务不支持" 的提示。
2. **应用更新由系统管理**: 元服务不支持应用内主动检测和强制更新，更新由系统统一管理。
3. **不支持动态安装**: 元服务为免安装形态，不支持通过 `downloadInstall` 安装其他应用。

## 四、降级处理策略

1. **应用内评论** -- 元服务不支持 `ReviewManager`。如需引导用户评论，可通过提示文字引导用户到 AppGallery 手动评论。
2. **应用更新** -- 元服务由系统管理更新，无法实现应用内检测和强制更新，无需处理。
3. **应用分发** -- 不支持在元服务内推荐和分发其他应用。
4. **支付相关** -- IAP（`@kit.IAPKit`）和华为支付（`@kit.PaymentKit`）均可用，正常使用即可。
5. **广告** -- 通过 `@kit.AdsKit` 正常接入广告服务。
