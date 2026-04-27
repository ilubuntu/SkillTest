# HarmonyOS Push Kit 推送服务开发实践

> 基于 app-wiki 查询 + 实际编译验证 | 2026-04-20

## 概述

本文档总结了 HarmonyOS Push Kit 在元服务（Atomic Service）场景下的开发经验，覆盖服务通知订阅请求和推送消息接收处理。

---

## Push Kit 元服务能力矩阵

### 端侧 API（客户端）

| API | 说明 | 元服务支持 |
|-----|------|-----------|
| `serviceNotification.requestSubscribeNotification` | 发起消息订阅请求 | 支持（API 12+） |

### 消息类型

| 类型 | 说明 | 订阅方式 | 推送频次 |
|------|------|---------|---------|
| 一次性订阅消息 | 单次服务环节通知 | 每次需用户授权 | 每授权一次下发一条 |
| 长期订阅消息 | 持续性服务提醒 | 一次授权长期有效 | 按模板限制频次推送 |
| 服务动态消息 | 实时活动状态更新 | 需申请权益+审核 | 按事件状态更新 |

---

## 元服务 Push Kit 特点

### 核心特征

- 订阅类型固定为 `SUBSCRIBE_WITH_HUAWEI_ID`（基于华为账号）
- 推送方式仅基于账号（OpenID），不使用 Token 推送
- 通知渠道为服务通知（锁屏/通知中心/负一屏）
- 支持服务动态消息（需申请权益）

### 前置条件（严格）

1. 在 AGC 开通推送服务
2. 在 AGC「服务通知」中开通并领用订阅模板
3. 元服务通过分类标签和资质认证
4. 服务动态消息需邮件申请权益（atomicservice@huawei.com）

---

## 场景 1：服务通知订阅请求

**文件**: `entry/src/main/ets/push/push-subscribe.ets`（struct: `PushSubscribe`）

### 核心 API

```typescript
import { serviceNotification } from '@kit.PushKit'

const res: serviceNotification.RequestResult =
  await serviceNotification.requestSubscribeNotification(context, entityIds, type)
```

### 参数说明

| 参数 | 类型 | 说明 |
|------|------|------|
| context | UIAbilityContext | 上下文 |
| entityIds | string[] | 模板 ID 数组，最多 3 个 |
| type | SubscribeNotificationType | 固定 `SUBSCRIBE_WITH_HUAWEI_ID` |

### 返回值

`RequestResult.entityResult` 类型为 **`EntityResult[]`**（数组，不是 Record）

```
EntityResult {
  entityId: string     // 模板 ID
  resultCode: ResultCode  // 结果码（枚举）
}

ResultCode 枚举值:
  0 = ACCEPTED   (用户同意)
  1 = REJECTED   (用户拒绝)
  2 = FILTERED   (被过滤)
```

### 完整生命周期示例（推荐）

在 `EntryAbility` 中，建议在 `onForeground` 中调用订阅，确保页面加载完成、可获取 `UIAbilityContext`：

```typescript
import { UIAbility } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { serviceNotification } from '@kit.PushKit';

export default class EntryAbility extends UIAbility {
  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onWindowStageCreate');
    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(0x0000, 'testTag', 'Failed to load the page. Cause: %{public}s', JSON.stringify(err) ?? '');
        return;
      }
      hilog.info(0x0000, 'testTag', 'Succeeded in loading the content.');
    });
  }

  async requestSubscribeNotification() {
    try {
      // entityIds请替换为待订阅的模板ID
      let entityIds: string[] = ['entityId1'];
      let type: serviceNotification.SubscribeNotificationType =
        serviceNotification.SubscribeNotificationType.SUBSCRIBE_WITH_HUAWEI_ID;
      const res: serviceNotification.RequestResult =
        await serviceNotification.requestSubscribeNotification(this.context, entityIds, type);
      hilog.info(0x0000, 'testTag', 'Succeeded in requesting serviceNotification: %{public}s',
        JSON.stringify(res.entityResult));
    } catch (err) {
      let e: BusinessError = err as BusinessError;
      hilog.error(0x0000, 'testTag', 'Failed to request serviceNotification: %{public}d %{public}s', e.code, e.message);
    }
  }

  async onForeground(): Promise<void> {
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onForeground');
    try {
      // 请确保加载页面完成，可以获取UIAbilityContext后调用方法
      await this.requestSubscribeNotification();
    } catch (err) {
      let e: BusinessError = err as BusinessError;
      hilog.error(0x0000, 'testTag', 'Request subscribe notification failed: %{public}d %{public}s', e.code, e.message);
    }
  }
}
```

### 反面示例（禁止使用 pushService）

`pushService` 及其 `getToken()` 等 API **在鸿蒙元服务中不可用**，请勿使用：

```typescript
// ❌ 错误示例，请不要这样写
import { pushService } from '@kit.PushKit';

export default class EntryAbility extends UIAbility {
  private initPushService(): void {
    try {
      pushService.getToken().then((token: string) => {
        // pushService 在元服务中不可用，此写法会导致编译或运行时错误
      }).catch((error: BusinessError) => {
        hilog.error(DOMAIN, TAG, 'Failed to get push token: %{public}s', JSON.stringify(error));
      });
    } catch (e) {
      hilog.error(DOMAIN, TAG, 'Push service init failed');
    }
  }
}
```

### 编译踩坑（重要）

**坑 1**: `entityResult` 类型是 `EntityResult[]` 不是 `Record<string, string>`

```typescript
// 错误写法
Object.entries(res.entityResult).forEach(...)

// 正确写法
for (const item of res.entityResult) {
  const templateId = item.entityId
  const code = item.resultCode  // ResultCode 枚举
}
```

**坑 2**: ArkTS 不支持解构参数 (`arkts-no-destruct-params`)

```typescript
// 错误
([key, value]) => { ... }

// 正确
(item) => { const key = item.entityId; const value = item.resultCode; }
```

**坑 3**: ArkTS 不允许 `any`/`unknown` 类型 (`arkts-no-any-unknown`)

需要使用明确的类型声明。

### 频控规则

- 单设备单元服务：≤ 30次/5分钟
- 超限进入频控，5分钟后重置
- 单次最多订阅 3 个模板
- 一次性模板 ID 和长期模板 ID **不可混用**
- 同标题模板 ID 在一个请求中只保留第一个

---

## 场景 2：推送消息接收处理

**文件**: `entry/src/main/ets/push/push-receive.ets` + `EntryAbility.ets` 修改

### 接收路径

```
推送消息点击 → 系统拉起元服务 → Want 参数携带 clickAction.data
```

| 场景 | 接收回调 | 前提 |
|------|---------|------|
| 元服务未运行 | `onCreate(want)` | 默认 |
| 元服务已在运行 | `onNewWant(want)` | 需 `launchType: singleton` |

### EntryAbility 修改

```typescript
export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    // 首次启动时获取推送数据
    if (want.parameters) {
      const data = want.parameters
      // 处理推送数据
    }
  }

  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    // 进程已存在时获取推送数据（需 singleton 模式）
    if (want.parameters) {
      const data = want.parameters
    }
  }
}
```

### module.json5 配置

推送消息点击默认进入首页，`onNewWant` 需要 singleton 启动模式。当前项目未设置 `launchType`，默认即为 singleton，无需额外配置。

---

## 注意事项汇总

| 项目 | 说明 |
|------|------|
| entityIds 模板 ID | 需替换为 AGC 领用的实际模板 ID，示例中的 ID 仅供测试 |
| 一次性 vs 长期模板 | 不可在一个请求中混用 |
| 同标题模板 | 请求中同标题模板只保留第一个，其余 FILTERED |
| "总是保持以上选择" | HarmonyOS 6.0+ 支持，之后不再弹窗 |
| longTerm 模板 | 仅限政务民生、银行、医疗等公共服务 |
| 服务动态权益 | 需邮件申请（atomicservice@huawei.com），15 个工作日审批 |
| 服务动态 code | 华为支付订单号或前端场景化 Button 获取，24h 内需激活 |
| 频控 | 30次/5分钟，超限频控 |
| 避免在 onCreate 中订阅 | 请确保页面加载完成、可获取 UIAbilityContext 后再调用订阅方法，建议在 `onForeground` 中调用 |
| 不要引入 @ohos.pushservice | 请使用 `@kit.PushKit` 引入 Push Kit |
| 不要使用 pushService | `pushService.getToken()` 等 API 在鸿蒙元服务中不可用，请勿使用 |
| 必须发起消息订阅 | 接入 Push 能力一定需要发起消息订阅，具体推送功能由用户自行实现，可留作 TODO |
