# Scenario Fusion Kit 开发经验

## 概述

Scenario Fusion Kit（融合场景服务）基于 ArkUI 框架组件开发，提供统一的 `FunctionalButton` 组件封装，通过 `OpenType` 枚举切换不同场景功能。所有场景共享相同的组件结构和回调模式。

---

## API 兼容性清单

### 元服务可用 — 通用场景

| OpenType | 说明 | 元服务起始版本 | 回调 | 关键参数 |
|----------|------|--------------|------|---------|
| `GET_PHONE_NUMBER` | 快速验证手机号 | API 11 | `onGetPhoneNumber` → `{ code }` | — |
| `LAUNCH_APP` | 打开APP | API 11 | `onLaunchApp` → `void` | `appParam: { bundleName, abilityName }` |
| `CHOOSE_AVATAR` | 选择头像 | API 11 | `onChooseAvatar` → `{ avatarUri }` | — |
| `CHOOSE_ADDRESS` | 选择收货地址 | API 12 | `onChooseAddress` → `{ userName, detailedAddress, ... }` | — |
| `CHOOSE_INVOICE_TITLE` | 选择发票抬头 | API 12 | `onChooseInvoiceTitle` → `{ type, title, taxNumber, ... }` | — |
| `CHOOSE_LOCATION` | 地图选点 | API 12 | `onChooseLocation` → `{ name, address, latitude, longitude }` | — |
| `PERMISSION_SETTING` | 权限设置 | API 14 | `onPermissionSetting` → `{ permissionResult }` | `permissionListParam` |
| `GET_PHONE_NUMBER_AND_RISK_LEVEL` | 手机号+风险等级 | API 22 | `onGetPhoneNumberAndRiskLevel` | — |

### 元服务可用 — 元服务专属场景

| OpenType | 说明 | 元服务起始版本 | 回调 | 关键参数 |
|----------|------|--------------|------|---------|
| `REQUEST_SUBSCRIBE_MESSAGE` | 服务动态授权码 | API 20 | `onRequestSubscribeMessage` → `{ code }` | `subSceneId`（必填） |
| `SHARE` | 元服务分享 | API 20 | `onShare` → `void` | `shareParam: { previewUri, description }` |
| `FEEDBACK` | 反馈与投诉 | API 20 | `onFeedback` → `void` | — |

### 暂不对外开放

| OpenType | 说明 | 状态 |
|----------|------|------|
| `GET_REALTIME_PHONENUMBER` | 实时验证手机号 | API 12 起停止开放 |
| `REAL_NAME_AUTHENTICATION` | 实名信息校验 | 预留，不开放 |
| `FACE_AUTHENTICATION` | 人脸核身 | 预留，不开放 |
| `SUBSCRIBE_LIVE_VIEW` | 实况窗订阅 | 预留，不开放 |

### 已废弃

| OpenType | 替代方案 |
|----------|---------|
| `OPEN_SETTING` (API 11) | 使用 `PERMISSION_SETTING` (API 14) |

---

## 核心调用方式

所有场景共享统一的调用模式：

```typescript
import { FunctionalButton, functionalButtonComponentManager } from '@kit.ScenarioFusionKit'

FunctionalButton({
  params: {
    openType: functionalButtonComponentManager.OpenType.XXX,  // 场景类型
    label: '按钮文字',
    styleOption: {
      styleConfig: new functionalButtonComponentManager.ButtonConfig()
        .fontSize(20)
    },
  },
  controller: new functionalButtonComponentManager.FunctionalButtonController()
    .onXxx((err, data) => { /* 回调处理 */ })
})
```

### 关键规则

1. **openType 与回调必须匹配**：每种 OpenType 有对应的 onXxx 回调，不可混用
2. **StyleOption 优先级**：在 Button 外设置的样式属性不生效，仅生效 styleOption 中的样式
3. **导入模块**：`@kit.ScenarioFusionKit`，统一导入 FunctionalButton 和 functionalButtonComponentManager

---

## 各场景参数说明

### GET_PHONE_NUMBER — 快速验证手机号

- 回调返回 `code: string`（授权码），需发送到服务端换取手机号
- 支持设备：Phone / Tablet / 2in1 / TV(18+)
- 模拟器：x86 不支持，arm 支持

### LAUNCH_APP — 打开APP

- **必填**：`appParam.bundleName`（目标应用包名）
- **可选**：`appParam.abilityName`（默认 EntryAbility）
- 回调仅返回成功/失败，无数据

### CHOOSE_AVATAR — 选择头像

- 回调返回 `avatarUri: string`（裁剪后的头像地址）
- 支持设备：Phone / Tablet / 2in1

### CHOOSE_ADDRESS — 选择收货地址

- 回调返回完整地址信息：`userName`, `mobileNumber`, `provinceName`, `cityName`, `districtName`, `streetName`, `detailedAddress`
- 必填字段：`userName`, `detailedAddress`

### CHOOSE_LOCATION — 地图选点

- 回调返回：`name`（位置名称）, `address`, `latitude`, `longitude`
- 依赖 Map Kit
- **注意**：字段名是 `name` 而非 `locationName`

### PERMISSION_SETTING — 权限设置

- 回调返回 `permissionResult: GrantStatus`（非 Map 类型）
- 可通过 `permissionListParam: Array<Permissions>` 指定关注权限
- 需先调用 `requestPermissionsFromUser`，否则无法拉起弹窗
- **注意**：字段名是 `permissionResult` 而非 `permissions`

### REQUEST_SUBSCRIBE_MESSAGE — 服务动态授权码

- **必填**：`subSceneId`（服务动态场景模板 ID，需先申请权益）
- 回调返回 `code: string`（动态授权码，当次服务进程唯一）
- 仅元服务可用
- 平台会检测诱导点击行为

### FEEDBACK — 反馈与投诉

- 回调仅返回成功/失败
- 仅元服务可用
- 需先完成开发准备并发布元服务

---

## 编译过程中的问题和解决方案

### 问题 1：ChooseLocationResult 字段名错误

**错误**：`Property 'locationName' does not exist on type 'ChooseLocationResult'`

**原因**：文档中描述为"位置名称"，但实际字段名为 `name` 而非 `locationName`

**解决**：将 `data.locationName` 改为 `data.name`

### 问题 2：PermissionSettingResult 字段名错误

**错误**：`Property 'permissions' does not exist on type 'PermissionSettingResult'`

**原因**：PermissionSettingResult 的实际结构是 `{ permissionResult: GrantStatus }`，而非 `Map<string, boolean>`

**解决**：将 `data.permissions` 改为 `data.permissionResult`

### 经验教训

FunctionalButton 各场景的回调数据结构（Result 类型）字段名需要以 API 参考文档中的实际定义为准，不能根据文字描述推测字段名。特别是：
- `ChooseLocationResult.name` 不是 `locationName`
- `PermissionSettingResult.permissionResult` 不是 `permissions`，且类型是 `GrantStatus` 而非 `Map`

---

## 设备与区域限制

### 区域限制

所有场景化 Button 组件只支持**中国境内**（不含香港、澳门、台湾）。

### 模拟器差异

| 场景 | x86 模拟器 | arm 模拟器 |
|------|-----------|-----------|
| 快速验证手机号 | 不支持 | 支持 |
| 选择头像 | 不支持 | 支持 |
| 打开APP | 支持 | 支持 |
| 选择收货地址 | 不支持 | 支持 |
| 选择发票抬头 | 不支持 | 不支持 |
| 地图选点 | 不支持 | 支持 |
| 权限设置 | 支持 | 支持 |
| 服务动态授权码 | 不支持 | 不支持 |
| 元服务分享 | 不支持 | 不支持 |
| 反馈与投诉 | 不支持 | 不支持 |

建议使用真机调试 Scenario Fusion Kit 的所有场景。
