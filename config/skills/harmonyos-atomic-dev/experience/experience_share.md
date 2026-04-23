# Share 分享能力开发经验

## 元服务分享能力总览

元服务的分享能力从 API version 6.0.0(20) 开始支持，与普通应用的分享体系完全不同。元服务仅支持**主动发起分享**，不支持作为分享目标**接收**分享内容。

---

## API 兼容性清单

### 元服务可用

| API | Kit | 说明 | 起始版本 |
|-----|-----|------|---------|
| `UIAbility.onShare(wantParams)` | AbilityKit | 通过服务面板分享当前页面 | API 10（元服务 API 20） |
| `FunctionalButton(OpenType.SHARE)` | ScenarioFusionKit | 页面内嵌分享按钮 | API 20 |
| `functionalButtonComponentManager` | ScenarioFusionKit | 分享按钮控制器和配置 | API 20 |

### 元服务不可用（仅应用）

| API | Kit | 说明 | 起始版本 |
|-----|-----|------|---------|
| `systemShare.SharedData` | ShareKit | 构造分享数据对象 | API 11 |
| `systemShare.SharedRecord` | ShareKit | 分享数据记录 | API 11 |
| `systemShare.ShareController.show()` | ShareKit | 拉起系统分享面板 | API 11 |
| `systemShare.ShareController.on('dismiss')` | ShareKit | 监听面板关闭 | API 11 |
| `systemShare.ShareController.on('shareCompleted')` | ShareKit | 获取分享结果 | API 18 |
| `systemShare.getSharedData(want)` | ShareKit | 解析分享数据 | API 11 |
| `systemShare.getContactInfo(want)` | ShareKit | 获取推荐联系人 | API 11 |
| `systemShare.getWant(data, options)` | ShareKit | 构造 Want 数据 | API 12 |
| `ShareExtensionAbility` | AbilityKit | 接收分享内容 | API 11 |
| `harmonyShare` | ShareKit | 华为分享 | API 10+ |
| `@ohos.fileshare` | CoreFileKit | 文件分享 | API 10+ |

---

## 场景 1：onShare 页面分享

### 核心调用方式

在 `UIAbility`（如 `EntryAbility.ets`）中重写 `onShare` 生命周期回调：

```typescript
// EntryAbility.ets
export default class EntryAbility extends UIAbility {
  onShare(wantParams: Record<string, Object>) {
    wantParams['atomicservice.param.key.shareInfo'] = {
      showShareMenu: true,      // 必填，是否允许分享
      title: '页面标题',         // 可选，默认为元服务名称
      description: '页面描述',   // 可选，默认为元服务一句话描述
      previewUri: ''             // 预留字段，暂不起作用
    }
  }
}
```

### 关键参数

- **存储键名**: `atomicservice.param.key.shareInfo`
- **数据结构**: `Record<string, ShareInfo>`
- **showShareMenu**: 不填默认为 `false`（不允许分享）
- **previewUri**: 预留字段，当前不起作用，无需填写

### 依赖条件

- 必须使用 `Navigation` 组件实现页面导航
- 元服务面板会根据 `showShareMenu` 判断当前页面是否允许分享
- 不同 NavDestination 页面可配置不同的分享信息

---

## 场景 2：FunctionalButton 分享按钮

### 核心调用方式

```typescript
import { FunctionalButton, functionalButtonComponentManager } from '@kit.ScenarioFusionKit'

FunctionalButton({
  params: {
    openType: functionalButtonComponentManager.OpenType.SHARE,
    label: '元服务分享',
    shareParam: {
      previewUri: '',
      description: '分享描述'
    },
    styleOption: {
      styleConfig: new functionalButtonComponentManager.ButtonConfig()
        .fontSize(20)
    }
  },
  controller: new functionalButtonComponentManager.FunctionalButtonController()
    .onShare((err) => {
      if (err) {
        // 错误处理
        return
      }
      // 成功拉起分享页面
    })
})
```

### 关键参数

| 参数 | 类型 | 说明 |
|------|------|------|
| `openType` | `OpenType.SHARE` | 必须指定为 SHARE |
| `label` | string | 按钮显示文字 |
| `shareParam.previewUri` | string | 缩略图 URI，无长度校验 |
| `shareParam.description` | string | 分享描述，无长度校验 |
| `controller` | `FunctionalButtonController` | 必须使用 `.onShare()` 回调 |

### 重要限制

- **仅在已发布的元服务中可用**，调试模式会返回错误码
- 错误码：`10004`、`10006`、`10008` 表示非发布环境
- 需先完成开发准备（Scenario Fusion Kit 配置）并发布元服务
- 可通过 `ButtonConfig` 链式调用自定义按钮样式

---

## 编译过程中的注意事项

### 编译结果

编译通过，无新增错误。仅有来自其他现有文件的 `getContext` 弃用警告（与 share 无关）。

### 无额外权限需求

- `onShare` 生命周期回调不需要额外权限声明
- `FunctionalButton` 不需要额外权限声明
- 不涉及文件 URI 访问或跨应用数据传递

---

## 降级处理策略

对于元服务不可用的分享能力（systemShare、ShareExtensionAbility 等）