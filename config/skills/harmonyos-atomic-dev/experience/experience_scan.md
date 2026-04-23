# HarmonyOS Scan Kit 扫码能力开发实践

## 概述

本文档总结了 HarmonyOS Scan Kit 在原子化服务 (atomicService) 场景下的开发经验，包含默认扫码、自定义扫码、码图生成三个子场景，重点记录了 API 兼容性问题和解决方案。

---

## Scan Kit 能力矩阵

| API | 功能 | atomicService 支持 | 说明 |
|-----|------|--------------------|------|
| `scanBarcode.startScanForResult` | 系统扫码界面 | 支持 | 拉起系统 UI，无需自行处理相机 |
| `customScan` | 自定义扫码界面 | 不支持 | 需配合 XComponent + SurfaceId |
| `generateBarcode.createBarcode` | 码图生成 | 不支持 | 生成 QR Code / 条形码 PixelMap |

---

## 场景 1：默认界面扫码

### API 调用方式

```typescript
import { scanBarcode, scanCore } from '@kit.ScanKit'
import { common } from '@kit.AbilityKit'

// 基础扫码
let context = getContext(this) as common.Context
scanBarcode.startScanForResult(context).then((result: scanBarcode.ScanResult) => {
  // result.scanType — 码类型
  // result.originalValue — 码内容
  // result.source — 来源 (0=相机, 1=相册)
})

// 带参数扫码
let options: scanBarcode.ScanOptions = {
  scanTypes: [scanCore.ScanType.QR_CODE],  // 指定码类型
  enableMultiMode: true,                     // 多码模式
  enableAlbum: true                          // 允许从相册选择
}
scanBarcode.startScanForResult(context, options)
```

### 注意事项

- `getContext(this)` 已标记为 deprecated，但仍可编译通过
- `ScanOptions.enableAlbum` 允许用户从相册选图扫码
- `enableMultiMode` 开启后可同时识别多个码

---