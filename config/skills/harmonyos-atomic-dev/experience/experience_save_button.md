# SaveButton 保存控件 — 开发经验

## 一、组件定位

SaveButton 是 HarmonyOS **安全控件**（Security Component），用于在用户点击后临时获取媒体库存储权限，无需弹窗授权。属于 `SystemCapability.ArkUI.ArkUI.Full`。

**核心价值**：绕过 `ohos.permission.WRITE_IMAGEVIDEO` 权限申请流程，通过一次点击获得限时授权。

## 二、元服务 API 兼容性清单

### 完全可用（API 11+）

| API | 说明 | 元服务起始版本 |
|-----|------|--------------|
| `SaveButton()` | 默认构造（图标+文字+背景） | API 11 |
| `SaveButton(options)` | 带参数构造 | API 11 |
| `SaveButtonOptions` | icon / text / buttonType | API 11 |
| `SaveIconStyle` | FULL_FILLED / LINES | API 11 |
| `SaveDescription` DOWNLOAD~CONTINUE_TO_RECEIVE (0~7) | 基础文本描述 | API 11 |
| `SaveButtonOnClickResult.SUCCESS` | 授权成功 | API 11 |
| `SaveButtonOnClickResult.TEMPORARY_AUTHORIZATION_FAILED` | 授权失败 | API 11 |
| `onClick(SaveButtonCallback)` | 点击事件 | API 11 |
| 安全控件通用属性 | fontSize/fontColor/fontWeight/fontStyle/fontFamily/iconColor/backgroundColor/borderRadius/width/height/constraintSize/padding/enabled 等 | API 11 |

### API 12+ 可用

| API | 说明 | 元服务起始版本 |
|-----|------|--------------|
| `SaveDescription.SAVE_TO_GALLERY` (8) | 保存至图库 | API 12 |
| `SaveDescription.EXPORT_TO_GALLERY` (9) | 导出 | API 12 |
| `SaveDescription.QUICK_SAVE_TO_GALLERY` (10) | 快速保存图片 | API 12 |
| `SaveDescription.RESAVE_TO_GALLERY` (11) | 重新保存 | API 12 |

### API 18+ 可用

| API | 说明 | 元服务起始版本 |
|-----|------|--------------|
| `SaveDescription.SAVE_ALL` (12) | 全部保存 | API 18 |
| `SaveButtonCallback` 类型 | 完整回调签名 `(event, result, error?)` | API 18 |

### API 20+ 可用（部分需权限）

| API | 需要权限 | 说明 |
|-----|---------|------|
| `setIcon(icon: Resource)` | `CUSTOMIZE_SAVE_BUTTON` | 自定义图标 |
| `setText(text: string \| Resource)` | `CUSTOMIZE_SAVE_BUTTON` | 自定义文本 |
| `iconSize(size: Dimension \| SizeOptions)` | 无 | 图标尺寸 |
| `iconBorderRadius(radius)` | `CUSTOMIZE_SAVE_BUTTON` | 图标圆角 |
| `stateEffect(enabled: boolean)` | `CUSTOMIZE_SAVE_BUTTON` | 按压效果 |

### API 21+ 可用

| API | 说明 |
|-----|------|
| `userCancelEvent(enabled: boolean)` | 接收用户取消授权事件 |
| `SaveButtonOnClickResult.CANCELED_BY_USER` (2) | 用户取消授权结果 |

### 明确不支持

| 限制项 | 说明 |
|--------|------|
| 子组件 | 不支持 |
| 通用属性 | 不支持，仅继承安全控件通用属性 |
| 通用事件 | 不支持，仅支持 onClick |
| UIExtension | 不支持在其中使用 |
| 非主窗口 | 仅主窗口和子窗口有效 |

## 三、核心调用方式

### 3.1 基础构造

```typescript
// 默认样式（图标+文字+背景）
SaveButton()

// 自定义组合
SaveButton({
  icon: SaveIconStyle.FULL_FILLED,   // FULL_FILLED | LINES
  text: SaveDescription.SAVE,         // 13种描述
  buttonType: ButtonType.Capsule      // Capsule | Circle | Normal
})
```

**关键约束**：
- `icon` 或 `text` 至少传一个，否则 options 不生效，回退默认样式
- `icon`、`text`、`buttonType` 不支持动态修改（不能通过状态变量绑定后变更）

### 3.2 授权事件处理

```typescript
SaveButton()
  .onClick((event: ClickEvent, result: SaveButtonOnClickResult, error?: BusinessError) => {
    if (result === SaveButtonOnClickResult.SUCCESS) {
      // 授权成功，在限定时间内可访问媒体库
    } else {
      // 授权失败，查看 error?.code 和 error?.message
    }
  })
```

**授权时限**：API 19 及以下 10 秒，API 20+ 延长至 1 分钟。

### 3.3 样式设置（安全控件通用属性）

```typescript
SaveButton({ icon: SaveIconStyle.FULL_FILLED, text: SaveDescription.SAVE })
  .fontSize(16)                    // 字体大小
  .fontColor('#FFFFFF')            // 字体颜色
  .fontWeight(FontWeight.Bold)     // 字体粗细
  .backgroundColor('#007DFF')      // 背景色
  .borderRadius(20)                // 圆角
  .iconColor('#FFD700')            // 图标颜色
  .width(200)                      // 宽度
  .constraintSize({ maxWidth: 100 }) // 尺寸约束
```

**背景色陷阱**：alpha 值（高八位）低于 `0x1a` 会被系统强制调整为 `0xff`，即接近透明的背景色会被系统覆盖为不透明。

## 四、SaveDescription 全量枚举

| 枚举值 | 数值 | 中文文本 | API 版本 |
|--------|------|---------|---------|
| DOWNLOAD | 0 | 下载 | 11 |
| DOWNLOAD_FILE | 1 | 下载文件 | 11 |
| SAVE | 2 | 保存 | 11 |
| SAVE_IMAGE | 3 | 保存图片 | 11 |
| SAVE_FILE | 4 | 保存文件 | 11 |
| DOWNLOAD_AND_SHARE | 5 | 下载分享 | 11 |
| RECEIVE | 6 | 接收 | 11 |
| CONTINUE_TO_RECEIVE | 7 | 继续接收 | 11 |
| SAVE_TO_GALLERY | 8 | 保存至图库 | 12 |
| EXPORT_TO_GALLERY | 9 | 导出 | 12 |
| QUICK_SAVE_TO_GALLERY | 10 | 快速保存图片 | 12 |
| RESAVE_TO_GALLERY | 11 | 重新保存 | 12 |
| SAVE_ALL | 12 | 全部保存 | 18 |

## 五、CUSTOMIZE_SAVE_BUTTON 权限

`ohos.permission.CUSTOMIZE_SAVE_BUTTON` 是 **restricted（受限）** 级别权限，普通应用和元服务通常无法获取。影响以下 API：
- `setIcon` — 自定义图标
- `setText` — 自定义文本
- `iconBorderRadius` — 图标圆角
- `stateEffect` — 按压效果

无此权限时，这些 API 调用不会报错，但设置不生效，控件使用系统默认样式。

## 六、降级处理策略

对于无法使用 `setIcon`/`setText` 自定义图标文本的情况：
1. **使用内置枚举**：通过 `SaveIconStyle` 和 `SaveDescription` 选择最接近需求的组合
2. **样式属性调整**：通过 `backgroundColor`、`fontColor`、`iconColor`、`fontSize`、`borderRadius` 等安全控件通用属性进行外观调整
3. **布局控制**：通过 `width`/`height`/`constraintSize`/`padding` 控制尺寸和间距

## 七、编译注意事项

1. `onClick` 回调签名为 `(event: ClickEvent, result: SaveButtonOnClickResult, error?: BusinessError)`，不是普通 Button 的 `() => void`
2. `SaveButtonOnClickResult` 和 `SaveIconStyle` 等枚举无需额外 import，全局可用
3. 安全控件通用属性链式调用时，某些属性（如 `fontColor`）是安全控件专有属性，不要与通用 `Button` 的属性混淆
4. `ForEach` 渲染多个 SaveButton 时，`key` 函数需要正确生成以避免重复渲染问题
