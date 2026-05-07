# Preview Kit (文件预览服务) 开发经验

## 能力概述

Preview Kit 为应用提供系统级文件快速预览能力，通过 `@kit.PreviewKit` 导入 `filePreview` 模块使用。预览窗口以独立窗口形式打开（非应用内），支持文本、网页、图片、音频、视频、PDF、Office文档等多种文件类型。

---

## 元服务 API 兼容性

| API | 元服务支持 | 起始版本 | 备注 |
|-----|----------|---------|------|
| `PreviewInfo` | 支持 | 4.1.0(11) | 文件预览信息结构体 |
| `DisplayInfo` | 支持 | 4.1.0(11) | 悬浮窗口属性（x/y/width/height），仅PC/2in1有效 |
| `openPreview(ctx, file, info?)` 单文件 Promise | 支持 | 4.1.0(11) | 1秒内重复调用无效 |
| `openPreview(ctx, file, info, callback)` 单文件 Callback | 支持 | 4.1.0(11) | **注意: Callback重载必须传DisplayInfo作为第3个参数** |
| `openPreview(ctx, files, index?)` 多文件 Promise | 支持 | 5.0.0(12) | 不支持2in1设备 |
| `canPreview(ctx, uri)` Promise | 支持 | 4.1.0(11) | 仅检查文件存在+格式支持，不检查转授权 |
| `canPreview(ctx, uri, callback)` Callback | 支持 | 4.1.0(11) | |
| `hasDisplayed(ctx)` Promise | 支持 | 4.1.0(11) | 需等待窗口创建完成后再调用 |
| `hasDisplayed(ctx, callback)` Callback | 支持 | 4.1.0(11) | |
| `closePreview(ctx)` Promise | 支持 | 4.1.0(11) | 需等待窗口创建完成后再调用 |
| `closePreview(ctx, callback)` Callback | 支持 | 4.1.0(11) | |
| `loadData(ctx, file)` 单文件 Promise | 支持 | 4.1.0(11) | 仅当预览窗口已存在时有效，100ms防抖 |
| `loadData(ctx, file, callback)` 单文件 Callback | 支持 | 4.1.0(11) | |
| `loadData(ctx, files, index?)` 多文件 Promise | 支持 | 5.0.0(12) | 2in1端无效 |

**结论: Preview Kit 所有 API 均在元服务中可用，无需降级处理。**

---

## 核心调用方式

### 导入

```typescript
import { filePreview } from '@kit.PreviewKit'
```

### PreviewInfo 构造

```typescript
let fileInfo: filePreview.PreviewInfo = {
  title: '文件名.txt',       // 可选，不填会从uri解析
  uri: 'file://docs/...',    // 必填，需确保可转授权
  mimeType: 'text/plain'     // 必填，不确定时可填 ""
}
```

### DisplayInfo 构造（仅PC/2in1有效）

```typescript
let displayInfo: filePreview.DisplayInfo = {
  x: 100, y: 100,
  width: 800, height: 800
}
```

### 典型流程

1. `canPreview()` 检查文件是否可预览
2. `openPreview()` 打开预览窗口
3. `loadData()` 在已有窗口中切换文件
4. `closePreview()` 关闭窗口

---

## 编译问题与解决

### 1. `openPreview` Callback 重载签名问题

**问题**: `openPreview` 的 Callback 重载签名为 `openPreview(context, file, info: DisplayInfo, callback)`，第3个参数必须是 `DisplayInfo`，不能省略。

**错误**: `openPreview(context, fileInfo, callback)` 编译失败，提示参数类型不匹配。

**解决**: 即使在手机端 DisplayInfo 无效，也必须构造并传入：
```typescript
const displayInfo: filePreview.DisplayInfo = {
  x: 100, y: 100, width: 800, height: 800
} as filePreview.DisplayInfo
filePreview.openPreview(context, fileInfo, displayInfo, (err: BusinessError) => { ... })
```

### 2. ArkTS 对象字面量类型限制

**问题**: ArkTS 禁止无类型的对象字面量 (`arkts-no-untyped-obj-literals`)。

**错误**: `const items = [{ ext: 'txt', mime: 'text/plain' }]` 编译失败。

**解决**: 定义接口并用 `as` 显式声明：
```typescript
interface FileTypeInfo { ext: string; mime: string }
const items: Array<FileTypeInfo> = [
  { ext: 'txt', mime: 'text/plain' } as FileTypeInfo
]
```

### 3. Callback 参数不能使用隐式 `any` 类型

**问题**: ArkTS 禁止使用 `any`/`unknown` 类型 (`arkts-no-any-unknown`)。

**错误**: `filePreview.canPreview(ctx, uri, (err, result) => {})` 中 `err` 隐式为 `any`。

**解决**: 显式声明回调参数类型：
```typescript
filePreview.canPreview(context, uri, (err: BusinessError, result: boolean) => { ... })
filePreview.hasDisplayed(context, (err: BusinessError, result: boolean) => { ... })
filePreview.closePreview(context, (err: BusinessError) => { ... })
```

### 4. ForEach 中对象字面量同样需要类型声明

**问题**: `ForEach` 数组参数中的对象字面量也受 `arkts-no-untyped-obj-literals` 限制。

**解决**: 使用 `as` 断言每个元素：
```typescript
ForEach([
  { label: 'txt', uri: '...' } as UriItem,
  { label: 'png', uri: '...' } as UriItem
], (item: UriItem) => { ... })
```

---

## 注意事项

1. **预览窗口是单例** — 同一时间只能有一个预览窗口
2. **1秒防抖** — `openPreview` 1秒内重复调用无效
3. **100ms防抖** — `loadData` 100毫秒内重复调用无效
4. **异步窗口创建** — `hasDisplayed`/`closePreview`/`loadData` 需等待窗口创建完成后调用，否则无效
5. **URI 转授权** — 需确认传入的 uri 可进行转授权
6. **DisplayInfo** — 仅在 PC/2in1 设备上有效，手机/平板填写无效
7. **多文件预览不支持2in1** — `openPreview(context, files, index)` 在 2in1 设备不可用，会返回错误码 801
