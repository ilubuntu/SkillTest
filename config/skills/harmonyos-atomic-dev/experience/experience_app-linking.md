# HarmonyOS APP Linking 元服务链接开发实践

> 基于 atomic-wiki 查询 + 实际编译验证 | 2026-04-20

## 概述

本文档总结了 HarmonyOS APP Linking 在元服务（Atomic Service）场景下的开发经验，包含 3 个可编译通过的实例，覆盖链接拉起（openLink）、API 拉起（openAtomicService）和链接接收解析。

---

## 元服务 APP Linking 能力矩阵

元服务支持三种拉起方式：

| 拉起方式 | API | 适用范围 | 有效期 | 说明 |
|----------|-----|---------|--------|------|
| 元服务链接 | `context.openLink()` | 从通知/短信/网页等拉起 | 1~90天 | 密文 URL，固定域名 |
| API 直接拉起 | `context.openAtomicService()` | 从应用/元服务内拉起 | 无限制 | 仅需 appId |
| 普通链接二维码 | 扫码触发 | 线下场景扫码 | 长期有效 | 使用自有域名 |

---

## 场景 1：openLink — 元服务链接拉起

**文件**: `entry/src/main/ets/linking/applinking-open.ets`（struct: `AppLinkingOpen`）

### 核心 API

```typescript
import { common } from '@kit.AbilityKit'

let context = ... as common.UIAbilityContext
// 基础用法
context.openLink(link)

// 带 appLinkingOnly 选项
context.openLink(link, { appLinkingOnly: true })
```

### 参数说明

| 参数 | 类型 | 说明 |
|------|------|------|
| link | string | 元服务链接（如 `https://hoas.drcn.agconnect.link/9P7g`） |
| appLinkingOnly | boolean | true: 仅 App Linking，未匹配抛异常(16000019)；false(默认): 回退浏览器 |

### 动态参数

在链接末尾拼接 `?key=value`，无需 AGC 额外配置：

```
https://hoas.drcn.agconnect.link/9P7g?action=showall&page=2
```

### 静态参数

在 AGC 创建链接时配置，如 `pagePath=pages/SubPage`，运行时通过 `want.parameters` 获取。

---

## 场景 2：openAtomicService — API 直接拉起

**文件**: `entry/src/main/ets/linking/open-atomic-service.ets`（struct: `OpenAtomicService`）

### 核心 API

```typescript
import { common, AtomicServiceOptions } from '@kit.AbilityKit'

let context = ... as common.UIAbilityContext
let options: AtomicServiceOptions = {
  displayId: 0,
  parameters: { 'pagePath': 'pages/Detail' }
}
context.openAtomicService(appId, options)
```

### 参数说明

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| appId | string | 是 | 目标元服务的 appId |
| options | AtomicServiceOptions | 否 | displayId、parameters 等配置 |

### AtomicServiceOptions 关键字段

| 字段 | 类型 | 说明 |
|------|------|------|
| displayId | number | 屏幕ID（≥-1） |
| parameters | Record<string, Object> | 自定义参数（如 pagePath） |
| windowMode | number | 窗口模式 |
| withAnimation | boolean | 是否有启动动画 |

### 跳转规则

| 拉起方 | 被拉起方 | 体验 |
|--------|---------|------|
| 系统应用/元服务 | 元服务 | 不弹窗，直接跳转 |
| 三方应用/元服务 | 系统元服务 | 不弹窗，直接跳转 |
| 三方元服务(非关联) | 三方元服务 | 每次弹窗确认 |
| 关联主体账号组 | 三方元服务 | 首次弹窗，30天免弹 |
| 三方应用(非关联) | 三方元服务 | 禁止 |

---

## 场景 3：链接接收与解析

**文件**: `entry/src/main/ets/linking/applinking-receive.ets`（struct: `AppLinkingReceive`）

实际处理代码在 `EntryAbility` 的 `onCreate`/`onNewWant` 中：

```typescript
import { url } from '@kit.ArkTS'

// 1. 解析元服务链接 URI
let uri = want?.uri
if (uri) {
  let urlObject = url.URL.parseURL(uri)
  let action = urlObject.params.get('action')
}

// 2. 获取静态自定义参数
let pagePath = want.parameters['pagePath'] as string
let navRouterName = want.parameters['navRouterName'] as string

// 3. 获取二维码码值（5.1.1+）
let scanCode = want.parameters['orgScanCode'] as string
```

### 三种接收数据来源

| 来源 | 获取方式 | 版本要求 |
|------|---------|---------|
| 元服务链接动态参数 | `want.uri` → `url.URL.parseURL` | 5.0.0+ |
| AGC 静态参数 | `want.parameters['key']` | 5.0.0+ |
| 普通链接二维码 | `want.parameters['orgScanCode']` | 5.1.1+ |

---

## 编译验证

修复了 3 类编译错误：

| 错误 | 原因 | 修复 |
|------|------|------|
| `URL.path` 不存在 | HarmonyOS URL 类型用 `pathname` | 替换为 `urlObject.pathname` |
| `AtomicServiceOptions` 无 `path` 字段 | 实际无此字段，需用 `parameters` | 改用 `parameters: { 'pagePath': ... }` |
| Ads imports 缺失 | Index.ets 中缺少导入 | 补回 5 个 Ads 组件的 import |

编译通过（CompileArkTS 成功），无代码错误。

---

## 导入模块汇总

```typescript
// openLink
import { common } from '@kit.AbilityKit'
import { BusinessError } from '@kit.BasicServicesKit'
import { url } from '@kit.ArkTS'

// openAtomicService
import { common, AtomicServiceOptions } from '@kit.AbilityKit'
import { BusinessError } from '@kit.BasicServicesKit'

// EntryAbility 接收端
import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit'
import { url } from '@kit.ArkTS'
```

---

## 注意事项汇总

| 项目 | 说明 |
|------|------|
| 元服务链接域名 | 固定为 `hoas.drcn.agconnect.link`，不可自定义 |
| 链接有效期 | 1~90 天，过期需重新创建 |
| openAtomicService 无限制 | 仅需 appId，无有效期限制 |
| 普通链接二维码 | 需在域名服务器放置 `applinking.json`（`atomicServices` 字段） |
| URL 解析属性 | ArkTS 中 `url.URL` 使用 `pathname` 而非 `path` |
| AtomicServiceOptions | 无 `path` 字段，页面路径通过 `parameters` 传递 |
| 版本要求 | 元服务链接 5.0.0+，普通链接二维码 5.1.1+ |
| 仅企业开发者 | 需企业开发者账号 |
| 仅中国大陆 | 不含港澳台 |
| 模拟器 | 暂不支持 |
