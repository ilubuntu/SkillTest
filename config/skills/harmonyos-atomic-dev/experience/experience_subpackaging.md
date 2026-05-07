# Subpackaging Kit (BundleManager) 开发经验

## 一、元服务 API 兼容性清单

### 可用 API

| API | 模块 | 说明 | 备注 |
|-----|------|------|------|
| `getBundleInfoForSelf(DEFAULT)` | `@ohos.bundle.bundleManager` | 查询自身基本信息 | 无需权限 |
| `getBundleInfoForSelf(WITH_APPLICATION)` | `@ohos.bundle.bundleManager` | 查询含应用信息的完整信息 | 无需权限 |
| `getBundleInfoForSelf(WITH_PERMISSIONS)` | `@ohos.bundle.bundleManager` | 查询含权限信息 | 无需权限 |
| `getAbilityInfo()` | `@ohos.bundle.bundleManager` | 查询 Ability 信息 | 受限于自身 |
| `getLaunchWantForBundle()` | `@ohos.bundle.bundleManager` | 获取启动 Want | 受限于自身 |

### 不可用/受限 API

| API | 模块 | 说明 | 原因 |
|-----|------|------|------|
| `getBundleInfo()` (其他应用) | `@ohos.bundle.bundleManager` | 查询其他应用信息 | 元服务仅能查询自身 |
| `getAllBundleInfo()` | `@ohos.bundle.bundleManager` | 获取所有已安装应用 | 需系统 API 权限 |
| `bundle.installer` | `@ohos.bundle.installer` | 安装/卸载 HAP | 元服务不支持动态安装 |
| 动态加载 HSP/HAP | 运行时 | 运行时动态加载模块 | 元服务为免安装形态 |
| `@ohos.bundle.freeInstall` | `@ohos.bundle.freeInstall` | 免安装管理 | 受限 |

## 二、核心调用方式

### 查询自身 Bundle 信息

```typescript
import bundleManager from '@ohos.bundle.bundleManager'

// 查询基本信息
let bundleInfo = await bundleManager.getBundleInfoForSelf(
  bundleManager.BundleFlag.GET_BUNDLE_INFO_DEFAULT
)
let name = bundleInfo.name               // 包名
let version = bundleInfo.versionName     // 版本名
let versionCode = bundleInfo.versionCode // 版本号
let installTime = bundleInfo.installTime // 安装时间

// 查询完整信息（含 appInfo）
let fullInfo = await bundleManager.getBundleInfoForSelf(
  bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION
)
let label = fullInfo.appInfo?.label
let modules = fullInfo.hapModulesInfo    // 模块列表

// 查询权限信息
let permInfo = await bundleManager.getBundleInfoForSelf(
  bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_REQUESTED_PERMISSION
)
let perms = permInfo.reqPermissionDetails // 已申请权限列表
```

## 三、编译问题与解决方案

1. **属性名差异**: `appInfo.label` 可用但 `appInfo.icon` 在元服务中返回值可能为空。`installTime` 属性可能不存在于某些返回结构中。
2. **仅能查询自身**: `getBundleInfoForSelf()` 是元服务中唯一可用的 Bundle 查询方法，不能查询其他应用。
3. **分包配置**: 分包在构建期通过 `build-profile.json5` 配置，运行时通过 `hapModulesInfo` 数组查看已加载模块。
4. **免安装形态**: 元服务为免安装形态，所有模块随元服务一起下发，不支持按需下载安装分包。
5. **包体积控制**: 建议控制包体积在 2MB 以内，以获得更好的加载性能。

## 四、降级处理策略

1. **查询自身信息** -- 使用 `getBundleInfoForSelf()` 配合不同的 `BundleFlag` 获取所需信息。
2. **查询其他应用** -- 元服务不支持，无替代方案。
3. **动态安装分包** -- 元服务不支持运行时动态安装，所有模块必须在编译时静态依赖并整体下发。
4. **HSP 共享** -- HSP 模块必须在编译时静态依赖，运行时直接调用，不支持动态加载。
5. **版本信息展示** -- 通过 `bundleInfo.versionName` 和 `versionCode` 在关于页面展示版本信息。
