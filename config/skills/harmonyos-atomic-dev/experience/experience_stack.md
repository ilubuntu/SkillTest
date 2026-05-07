# Stack 组件开发经验

## API 可用性清单

### 完全可用（元服务无限制）

| API | 版本 | 说明 |
|-----|------|------|
| `Stack(value?: { alignContent?: Alignment })` | API 7+ | 构造函数，创建层叠容器 |
| `.alignContent(value: Alignment)` | API 7+ | 设置子组件对齐方式，9 种枚举值 |
| `.zIndex(value: number)` | API 7+（通用属性） | Z 序控制，值越大层级越高 |
| 通用属性（width/height/margin/padding/backgroundColor 等） | API 7+ | 完整支持 |
| 通用事件 | API 7+ | 完整支持 |

### FolderStack 折叠屏扩展（元服务 API 12+ 可用，需折叠屏硬件）

| API | 版本 | 元服务版本 | 说明 |
|-----|------|-----------|------|
| `FolderStack(options?: FolderStackOptions)` | API 11+ | API 12+ | 继承 Stack，新增折叠屏悬停 |
| `FolderStackOptions.upperItems` | API 11+ | API 12+ | 设置悬停到上半屏的子组件 id 数组 |
| `.enableAnimation(boolean)` | API 11+ | API 12+ | 是否使用默认动效，默认 true |
| `.autoHalfFold(boolean)` | API 11+ | API 12+ | 是否开启自动旋转 |
| `.alignContent(value: Alignment)` | API 11+ | API 12+ | 同 Stack |
| `.onFolderStateChange(callback)` | API 11+ | API 12+ | 折叠状态变化回调 |
| `.onHoverStatusChange(callback)` | API 12+ | API 12+ | 悬停状态变化回调 |

**注意**: FolderStack 在常规手机/平板上作为普通 Stack 使用，悬停能力不生效。Wearable 设备上调用会异常（接口未定义）。

## 核心调用方式

### 1. 基础层叠

```typescript
Stack() {
  Column() { Text('底层') }.width(260).height(260).backgroundColor('#2196F3')
  Column() { Text('中层') }.width(180).height(180).backgroundColor('#4CAF50')
  Column() { Text('顶层') }.width(100).height(100).backgroundColor('#FF9800')
}
```

子组件按顺序入栈，后入栈覆盖前入栈。默认 `Alignment.Center` 居中对齐。

### 2. 对齐方式

```typescript
Stack({ alignContent: Alignment.Bottom }) {
  // 子组件...
}
```

9 种 Alignment 枚举：`TopStart / Top / TopEnd / Start / Center / End / BottomStart / Bottom / BottomEnd`。非法值按默认值 Center 处理。

也可通过属性方式设置：`.alignContent(Alignment.TopStart)`。与 `.align()` 同时设置时，后设置的生效。

### 3. Z 序控制

```typescript
Stack() {
  Column() { Text('1') }.width(100).height(100).zIndex(2)  // 最上层
  Column() { Text('2') }.width(150).height(150).zIndex(1)  // 中间
  Column() { Text('3') }.width(200).height(200).zIndex(0)  // 底层
}
```

当后入栈子元素尺寸更大时，前面的子元素会被完全隐藏。通过 zIndex 可改变显示层级。

### 4. 覆盖层场景

典型用法：
- **图片+文字覆盖**: `Stack({ alignContent: Alignment.Bottom })` + 底层背景 + 顶层文字
- **状态角标**: `Stack({ alignContent: Alignment.TopEnd })` + 底层卡片 + 顶层角标
- **悬浮操作栏**: `Stack({ alignContent: Alignment.Bottom })` + 底层内容 + 顶层按钮栏

## 编译问题与解决方案

### 问题：ArkTS 对象字面量类型限制

**错误**: `Object literals cannot be used as type declarations (arkts-no-obj-literals-as-types)`

**错误代码**:
```typescript
private alignList: Array<{ name: string; value: Alignment }> = [
  { name: 'TopStart', value: Alignment.TopStart },
  // ...
]
```

**解决**: ArkTS 不支持匿名对象字面量类型，必须使用显式声明的 class：
```typescript
class AlignItem {
  name: string = ''
  value: Alignment = Alignment.Center
}

// 在 aboutToAppear 中初始化
aboutToAppear(): void {
  const item = new AlignItem()
  item.name = 'TopStart'
  item.value = Alignment.TopStart
  this.alignList.push(item)
}
```

## 使用注意事项

1. **性能优化**: 过多嵌套 Stack 会导致性能劣化。优先使用组件属性（`position`、`markAnchor` 等）代替嵌套 Stack 实现定位效果。
2. **尺寸覆盖**: 后入栈子元素尺寸更大时，前面子元素完全隐藏，需使用 `zIndex` 控制。
3. **alignContent 与 align 冲突**: 同时设置时后设置的生效，注意避免冲突。
