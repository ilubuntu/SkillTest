# HarmonyOS Ads Kit 广告服务开发实践

> 基于 app-wiki 查询 + 实际编译验证 | 2026-04-17

## 概述

本文档总结了 HarmonyOS Ads Kit 在元服务（Atomic Service）场景下的开发经验，包含 5 个可编译通过的实例，覆盖横幅广告、插屏广告、激励广告、原生广告、贴片广告五种广告形式。

---

## Ads Kit 能力矩阵

### 广告类型总览

| 广告形式 | adType | 展示方式 | 展示组件 | 需事件订阅 | 应用场景 |
|---------|--------|---------|---------|-----------|---------|
| 横幅广告 | 8 | AutoAdComponent 组件式 | AutoAdComponent | 否 | 页面顶部/底部固定位置 |
| 插屏广告 | 12 | advertising.showAd | 全屏弹窗 | 是 (PPS_INTERSTITIAL) | 页面跳转、暂停时 |
| 激励广告 | 7 | advertising.showAd | 全屏视频 | 是 (PPS_REWARD) | 游戏奖励、获取道具 |
| 原生广告 | 3 | AdComponent 组件式 | AdComponent | 否 | 信息流、插图嵌入 |
| 贴片广告 | 60 | AdComponent 组件式 | AdComponent | 否 | 视频前/中/后贴 |

### 展示方式分类

| 方式 | 广告类型 | 说明 |
|------|---------|------|
| **组件式** AutoAdComponent | 横幅广告 | 自动请求+展示一体化组件 |
| **组件式** AdComponent | 原生广告、贴片广告 | 需先 AdLoader 加载，再通过组件展示 |
| **接口式** advertising.showAd | 激励广告、插屏广告 | 需先 AdLoader 加载，调用 showAd 弹出全屏 |

---

## 元服务 vs 普通应用差异

### 权限差异（关键）

| 项目 | 普通应用 | 元服务 |
|------|---------|--------|
| `ohos.permission.INTERNET` | 需要 | 需要 |
| `ohos.permission.APP_TRACKING_CONSENT` | 需要 | **不需要** |
| OAID 获取 | 需要 | **不需要** |
| 代码复杂度 | 需要权限请求 + OAID | **大幅简化** |

### 权限配置（module.json5）

在模块的 `module.json5` 中添加网络权限：

```json
{
  "module": {
    "requestPermissions": [
      {
        "name": "ohos.permission.INTERNET"
      }
    ]
  }
}
```

### 代码差异示例

```typescript
// 普通应用 — 需要权限请求 + OAID
import { abilityAccessCtrl } from '@kit.AbilityKit'
import { identifier } from '@kit.AdsKit'
// 需要先请求权限，再获取 OAID
const oaid = await identifier.getOAID()
const adRequestParams = { adId: 'xxx', adType: 8, oaid: oaid }

// 元服务 — 直接请求，无需 OAID
import { advertising } from '@kit.AdsKit'
const adRequestParams = { adId: 'xxx', adType: 8 }
```

---

## 场景 1：横幅广告（Banner）

**文件**: `entry/src/main/ets/ads/ads-banner.ets`（struct: `AdsBanner`）

### 关键 API

- `AutoAdComponent` — 自动请求+展示一体化组件
- 广告类型: `adType: 8`

### 尺寸限制

| 尺寸 | 说明 |
|------|------|
| 360 x 57 | 标准横幅 |
| 360 x 144 | 大横幅 |

**注意**: 元服务仅支持这两种尺寸。

### 核心代码

```typescript
// 广告请求参数
private adRequestParams: advertising.AdRequestParams = {
  adId: 'testw6vs28auh3',   // 广告位ID
  adType: 8,                 // 广告类型（横幅=8）
  adWidth: 360,              // 广告位宽，单位vp
  adHeight: 57               // 广告位高，单位vp
};
private adOptions: advertising.AdOptions = {};
private adDisplayOptions: advertising.AdDisplayOptions = {
  refreshTime: 30000         // 轮播间隔，取值范围[30000, 120000]ms
};
private ratio: number = -1;

aboutToAppear() {
  if (this.adRequestParams.adWidth && this.adRequestParams.adHeight) {
    this.ratio = this.adRequestParams.adWidth / this.adRequestParams.adHeight;
  }
}

build() {
  Column() {
    AutoAdComponent({
      adParam: this.adRequestParams,
      adOptions: this.adOptions,
      displayOptions: this.adDisplayOptions,
      interactionListener: {
        onStatusChanged: (status: string, ad: advertising.Advertisement, data: string) => {
          switch (status) {
            case 'onAdOpen':
              break;
            case 'onAdClick':
              break;
            case 'onAdClose':
              break;
          }
        }
      }
    })
      .width('100%')
      .aspectRatio(this.ratio)
  }
}
```

### 注意事项

- `refreshTime` 范围 [30000, 120000]ms
- `onAdFail` 时需隐藏组件
- `onAdClose` 时需隐藏组件
- 组件宽高比需与 adWidth/adHeight 匹配（用 `.aspectRatio()`）

---

## 场景 2：插屏广告（Interstitial）

**文件**: `entry/src/main/ets/ads/ads-interstitial.ets`（struct: `AdsInterstitial`）

### 关键 API

- `AdLoader.loadAd` — 请求广告
- `advertising.showAd` — 展示广告
- 广告类型: `adType: 12`

### 事件订阅（必填）

- 事件名: `com.huawei.hms.pps.action.PPS_INTERSTITIAL_STATUS_CHANGED`
- publisherBundleName: `com.huawei.hms.adsservice`
- Key: `interstitial_ad_status`
- 状态: `onAdOpen` / `onAdClick` / `onAdClose` / `onVideoPlayBegin` / `onVideoPlayEnd`

### 核心流程

```typescript
// 1. 创建 AdLoader
const adLoader = new advertising.AdLoader(context)
// 2. 加载广告
adLoader.loadAd({ adId: 'testb4znbuh3n2', adType: 12 }, {}, {
  onAdLoadSuccess: (ads) => {
    // 3. 注册事件订阅（每次展示前）
    registerPPSReceiver()
    // 4. 展示广告
    advertising.showAd(ads[0], { mute: true }, context)
  }
})
```

### 注意事项

- **每次展示前**必须调用 `registerPPSReceiver()`
- `onAdClose` 后必须 `unRegisterPPSReceiver()`
- `publisherBundleName` 必须设为 `com.huawei.hms.adsservice` 防止伪造事件

---

## 场景 3：激励广告（Reward）

**文件**: `entry/src/main/ets/ads/ads-reward.ets`（struct: `AdsReward`）

### 关键 API

- `AdLoader.loadAd` — 请求广告
- `advertising.showAd` — 展示广告
- 广告类型: `adType: 7`

### 事件订阅（必填）

- 事件名: `com.huawei.hms.pps.action.PPS_REWARD_STATUS_CHANGED`
- publisherBundleName: `com.huawei.hms.adsservice`
- 状态 Key: `reward_ad_status`
- 奖励 Key: `reward_ad_data`

### 奖励数据

```typescript
// 从事件参数获取
const rewardData = commonEventData.parameters['reward_ad_data']
// rewardData.rewardType  — 奖励名称 (string)
// rewardData.rewardAmount — 奖励数量 (number)
```

### S2S 服务端验证

```typescript
const adDisplayOptions: advertising.AdDisplayOptions = {
  mute: true,
  customData: 'CUSTOM_DATA',  // 自定义数据，URL Encode 后不超过 1024 字符
  userId: '1234567'            // 用户 ID
}
```

### 注意事项

- `customData` 和 `userId` 必须在 **showAd 之前** 设置
- 应用上架超过 12 小时才能收到 S2S 回调
- `onAdClose` 后必须取消订阅
- 建议客户端即时奖励 + 服务端异步验证

---

## 场景 4：原生广告（Native）

**文件**: `entry/src/main/ets/ads/ads-native.ets`（struct: `AdsNative`）

### 关键 API

- `AdLoader.loadAdWithMultiSlots` — 多广告位请求
- `AdComponent` — 组件式展示
- 广告类型: `adType: 3`

### 两种展示样式

| 样式 | 建议宽高 | 说明 |
|------|---------|------|
| 原生信息流 | width: 100%, height: 不设置 | 自适应高度 |
| 原生插图 | width: 312vp, height: 284vp | 固定尺寸 |

### 核心代码

```typescript
// 请求多广告位
adLoader.loadAdWithMultiSlots(
  [{ adId: 'xxx', adType: 3, enableDirectReturnVideoAd: true }],
  {},
  { onAdLoadSuccess: (ads: Map<string, Array<Advertisement>>) => { /* ... */ } }
)

// 展示
AdComponent({
  ads: [ad],
  displayOptions: { mute: true },
  interactionListener: { onStatusChanged: (status, ad, data) => { /* ... */ } }
})
```

### 注意事项

- `enableDirectReturnVideoAd: true` 可直接返回广告，不等待素材下载完成
- 信息流样式**不要设置高度**，组件自适应
- `onAdFail` 和 `onAdClose` 都需隐藏组件
- 返回值为 `Map<string, Array<Advertisement>>`，需遍历收集

---

## 场景 5：贴片广告（Roll）

**文件**: `entry/src/main/ets/ads/ads-roll.ets`（struct: `AdsRoll`）

### 关键 API

- `AdLoader.loadAd` — 请求广告
- `AdComponent` — 组件式展示
- 广告类型: `adType: 60`

### 特有参数

```typescript
// AdOptions 中必须设置 totalDuration
const adOptions: advertising.AdOptions = {
  totalDuration: 30  // 贴片展示时长（秒），必填
}
```

### 特有回调状态

| 状态 | 说明 | 需要处理 |
|------|------|---------|
| `onPortrait` | 从全屏返回竖屏 | 设置竖屏方向 + 显示系统栏 |
| `onLandscape` | 点击全屏 | 设置横屏方向 + 隐藏系统栏 |
| `onMediaComplete` | 单条广告播放完成 | 计数，全部完成时播放正片 |
| `onMediaCountdown` | 倒计时 | 解析 data.countdownTime 显示倒计时 UI |
| `onBackClicked` | 点击返回 | 调用 router.back() |
| `onAdFail` | 加载失败 | 隐藏组件，直接播放正片 |

### 核心代码

```typescript
AdComponent({
  ads: [...this.ads],
  rollPlayState: this.rollPlayState,  // 1=播放
  displayOptions: { mute: true },
  interactionListener: {
    onStatusChanged: (status, ad, data) => {
      if (status === 'onMediaComplete') {
        this.playedAdSize++
        if (this.playedAdSize === this.ads.length) { this.isPlayVideo = true }
      }
      if (status === 'onMediaCountdown') {
        const parseData = JSON.parse(data)
        this.countDownText = `${parseData.countdownTime}s | VIP免广告`
      }
    }
  }
})
```

### 注意事项

- `totalDuration` 是**必填参数**，不设置会导致广告无法正常展示
- `rollPlayState` 控制播放状态，1=播放
- 需要 `window.getLastWindow()` 做横竖屏切换
- 播放完成后需还原屏幕方向和系统栏
- `data` 参数为 JSON 字符串，需 `JSON.parse` 解析

---

## 测试广告位 ID

| 广告类型 | 测试 adId |
|---------|-----------|
| 横幅广告 | `testw6vs28auh3` |
| 插屏广告 | `testb4znbuh3n2` |
| 激励广告 | `testx9dtjwj8hp` |
| 原生广告 | `testb4znbuh3n2` |
| 贴片广告 | `testy3cglm3pj0` |

**注意**: 以上为测试专用 ID，正式发布需替换为鲸鸿动能平台申请的广告位 ID。

---

## 通用注意事项

### 导入模块

```typescript
// 所有广告类型通用
import { advertising } from '@kit.AdsKit'
import { hilog } from '@kit.PerformanceAnalysisKit'

// 横幅广告额外
import { AutoAdComponent } from '@kit.AdsKit'

// 原生/贴片广告额外
import { AdComponent } from '@kit.AdsKit'

// 插屏/激励广告事件订阅额外
import { BusinessError, commonEventManager } from '@kit.BasicServicesKit'

// 贴片广告横竖屏额外
import { window } from '@kit.ArkUI'
```

### 常见问题

| 问题 | 原因 | 解决方案 |
|------|------|---------|
| 展示广告白屏 | 广告样式与展示组件不匹配 | 横幅用 AutoAdComponent，原生/贴片用 AdComponent，激励/插屏用 showAd |
| 鲸鸿动能平台打不开 | 个人开发者限制 | 需企业开发者认证 |
| 仅支持中国境内 | 地域限制 | 香港、澳门、台湾除外 |
| 模拟器支持 | API 6.0.0(20) Beta5+ | 与真机有差异，建议真机测试 |
| 编译报错找不到 AdsKit | SDK 版本 | 需 HarmonyOS NEXT SDK |

### 广告组件对应关系（避坑）

```
横幅广告 → AutoAdComponent（自动请求+展示）
原生广告 → AdComponent（需先 loadAd/loadAdWithMultiSlots）
贴片广告 → AdComponent（需先 loadAd + rollPlayState）
激励广告 → advertising.showAd（需先 loadAd + 事件订阅）
插屏广告 → advertising.showAd（需先 loadAd + 事件订阅）
```