# Navigation 路由跳转开发经验（元服务）

## 一、NavPathStack API 元服务兼容性清单

### 1.1 页面跳转（入栈）

| 方法 | 元服务起始版本 | 签名 | 说明 |
|------|------------|------|------|
| `pushPath` | 11+ | `pushPath(info: NavPathInfo, animated?: boolean)` | 同步入栈，传入 NavPathInfo 对象 |
| `pushPath` | 12+ | `pushPath(info: NavPathInfo, options?: NavigationOptions)` | 支持 NavigationOptions 重载 |
| `pushPathByName` | 11+ | `pushPathByName(name: string, param: Object, animated?: boolean)` | 按名称入栈，最常用 |
| `pushPathByName` | 12+ | `pushPathByName(name, param, onPop: Callback<PopInfo>, animated?)` | 带 onPop 回调，接收子页面返回值 |
| `pushDestination` | 12+ | `pushDestination(info, animated?): Promise<void>` | 异步入栈，返回 Promise |
| `pushDestinationByName` | 12+ | `pushDestinationByName(name, param, animated?): Promise<void>` | 异步按名称入栈 |

**核心调用方式：**
```typescript
// 同步跳转（推荐，简单场景）
this.navPathStack.pushPathByName('TargetPage', paramObj, false)

// 异步跳转（需确认跳转结果）
this.navPathStack.pushDestination({ name: 'TargetPage' }, false)
  .then(() => { /* 成功 */ })
  .catch((err: BusinessError) => { /* 失败 */ })

// 带返回值回调跳转
this.navPathStack.pushPathByName('FormPage', initData, (popInfo: PopInfo) => {
  const result = popInfo.result  // 子页面 pop 时携带的返回值
}, false)
```

### 1.2 页面返回（出栈）

| 方法 | 元服务起始版本 | 签名 | 说明 |
|------|------------|------|------|
| `pop` | 11+ | `pop(animated?): NavPathInfo \| undefined` | 弹出栈顶页面 |
| `pop` | 12+ | `pop(result: Object, animated?)` | 携带返回值弹出栈顶 |
| `popToName` | 11+ | `popToName(name, animated?): number` | 弹出到指定名称页面 |
| `popToName` | 12+ | `popToName(name, result, animated?)` | 携带返回值弹出到指定页面 |
| `popToIndex` | 11+ | `popToIndex(index, animated?)` | 弹出到指定索引位置 |

**核心调用方式：**
```typescript
// 普通返回
this.pageInfo.pop()

// 携带返回值
this.pageInfo.pop(returnData as Object, false)

// 返回到指定页面
this.pageInfo.popToName('HomePage', false)
```

### 1.3 页面替换

| 方法 | 元服务起始版本 | 签名 | 说明 |
|------|------------|------|------|
| `replacePath` | 12+ | `replacePath(info, animated?)` | 替换栈顶页面 |
| `replacePathByName` | 12+ | `replacePathByName(name, param, animated?)` | 按名称替换栈顶 |
| `replaceDestination` | 18+ | `replaceDestination(info, options?): Promise<void>` | 异步替换（高版本） |

### 1.4 页面删除与移动

| 方法 | 元服务起始版本 | 签名 | 说明 |
|------|------------|------|------|
| `removeByName` | 12+ | `removeByName(name): number` | 移除所有同名页面，返回移除数量 |
| `removeByIndexes` | 12+ | `removeByIndexes(indexes): number` | 按索引批量移除 |
| `removeByNavDestinationId` | 12+ | `removeByNavDestinationId(id): boolean` | 按 NavDestination ID 移除 |
| `moveToTop` | 11+ | `moveToTop(name, animated?): number` | 将同名页面移到栈顶 |
| `moveIndexToTop` | 11+ | `moveIndexToTop(index, animated?)` | 将指定索引页面移到栈顶 |
| `clear` | 11+ | `clear(animated?)` | 清空路由栈 |

### 1.5 栈查询

| 方法 | 元服务起始版本 | 签名 | 说明 |
|------|------------|------|------|
| `getAllPathName` | 11+ | `getAllPathName(): Array<string>` | 获取所有页面名称 |
| `getParamByIndex` | 11+ | `getParamByIndex(index): Object \| undefined` | 按索引获取参数 |
| `getParamByName` | 11+ | `getParamByName(name): Array<Object>` | 按名称获取所有同名页参数 |
| `getIndexByName` | 11+ | `getIndexByName(name): Array<number>` | 按名称获取页面索引列表 |
| `size` | 11+ | `size(): number` | 获取栈深度 |
| `getParent` | 11+ | `getParent(): NavPathStack \| null` | 获取父 NavPathStack |
| `getPathStack` | 19+ | `getPathStack(): Array<NavPathInfo>` | 获取路由信息数组（高版本） |

### 1.6 拦截与动画

| 方法 | 元服务起始版本 | 签名 | 说明 |
|------|------------|------|------|
| `setInterception` | 12+ | `setInterception(interception: NavigationInterception)` | 设置路由拦截器 |
| `disableAnimation` | 12+ | `disableAnimation(value: boolean)` | 禁用/启用路由转场动画 |

**NavigationInterception 结构：**
```typescript
// 仅支持以下属性（API 12+）
{
  willShow?: InterceptionShowCallback  // 页面即将显示前
  didShow?: InterceptionShowCallback   // 页面显示完成后
  modeChange?: InterceptionModeCallback // 单双栏模式变更
}
// 注意：不存在 willHide / didHide 属性
```

**InterceptionShowCallback 签名：**
```typescript
type InterceptionShowCallback = (
  from: NavDestinationContext | NavBar,
  to: NavDestinationContext | NavBar,
  operation: NavigationOperation,
  isAnimated: boolean
) => void
```

---

## 二、跨模块路由（NavPushPathHelper）

### 2.1 适用场景

当目标 NavDestination 位于独立的 HSP 分包中，且主包未直接依赖该分包时，必须使用 NavPushPathHelper。它会自动检查并下载分包。

### 2.2 可用方法（元服务 API 12+ 全部支持）

| 方法 | 签名 |
|------|------|
| `pushPath` | `pushPath(moduleName, info, animated?): Promise<void>` |
| `pushPathByName` | `pushPathByName(moduleName, name, param, animated?): Promise<void>` |
| `pushDestination` | `pushDestination(moduleName, info, animated?): Promise<void>` |
| `pushDestinationByName` | `pushDestinationByName(moduleName, name, param, animated?): Promise<void>` |
| `replacePath` | `replacePath(moduleName, info, animated?): Promise<void>` |
| `replacePathByName` | `replacePathByName(moduleName, name, param, animated?): Promise<void>` |

每个方法的第一个参数 `moduleName` 是 HSP 分包名称。

### 2.3 关键注意事项

1. **HSP 分包 module.json5 中必须删除 `pages` 配置**，否则路由跳转白屏
2. 调试时需在 DevEco Studio 中勾选 `Deploy Multi Hap Packages`
3. 仅支持 HSP 分包，不支持 APP_PACKAGE 类型独立分包
4. 返回、删除、查询等操作仍使用 NavPathStack 方法，不需要 NavPushPathHelper

---

## 三、编译过程中的问题与解决方案

### 3.1 ArkTS 不允许 `unknown` 类型（arkts-no-any-unknown）

**问题：** `getParamByName`、`getParamByIndex` 等方法返回值为 `unknown` 或 `Array<unknown>`，ArkTS 编译器不允许直接使用 `unknown` 类型。

**解决方案：** 使用 `as` 断言为具体类型：
```typescript
// 错误
const param = this.navPathStack.getParamByName('pageName')

// 正确
const param = this.navPathStack.getParamByName('pageName') as Object[]
const paramByIndex = this.navPathStack.getParamByIndex(0) as Object | undefined
```

### 3.2 对象字面量必须对应显式类型（arkts-no-untyped-obj-literals）

**问题：** `pushPathByName`、`replacePathByName` 等方法的 `param` 参数不接受匿名对象字面量。

**解决方案：**
- 使用 `interface` 定义参数类型，创建变量后传入
- 或使用基础类型（string、null）替代对象参数

```typescript
// 错误
this.navPathStack.pushPathByName('page', { id: 100, type: 'article' }, false)

// 正确方案 1：定义接口
interface QueryParam { id: number; type: string }
const param: QueryParam = { id: 100, type: 'article' }
this.navPathStack.pushPathByName('page', param as Object, false)

// 正确方案 2：使用字符串
this.navPathStack.pushPathByName('page', 'param_value' as Object, false)

// 正确方案 3：传 null
this.navPathStack.pushPathByName('page', null, false)
```

### 3.3 NavigationInterception 不含 willHide/didHide

**问题：** `setInterception` 的 `NavigationInterception` 类型仅包含 `willShow`、`didShow`、`modeChange` 三个回调属性，不存在 `willHide` 和 `didHide`。

**解决方案：** 仅使用 `willShow` 和 `didShow` 实现拦截逻辑。

### 3.4 InterceptionShowCallback 参数类型

**问题：** 回调的 `from`/`to` 参数类型为 `NavDestinationContext | NavBar`，不是 `NavDestinationContext | null`。

**解决方案：** 使用正确的联合类型：
```typescript
willShow: (from: NavDestinationContext | NavBar, to: NavDestinationContext | NavBar,
  operation: NavigationOperation, isAnimated: boolean) => { ... }
```

---

## 四、降级处理策略

### 4.1 跨模块路由在单模块项目中无法演示

NavPushPathHelper 需要多 HSP 分包项目结构。在单模块（entry）项目中，无法实际调用跨模块跳转。采用 UI 骨架 + 黄色提示卡片方式说明限制，并列出完整的 API 参考和使用示例代码。

### 4.2 高版本 API 处理

- `replaceDestination`（API 18+）、`getPathStack`（API 19+）等高版本 API 在低版本设备不可用
- 不影响现有 demo（未使用这些 API），在实际开发中需通过设备 API 版本判断做兼容

---

## 五、Demo 文件索引

| 文件 | 场景 | 主要 API |
|------|------|----------|
| `navigation-router-push-by-name.ets` | 按名称跳转传参 | pushPathByName, getParamByName |
| `navigation-router-push-destination.ets` | 异步跳转 | pushDestination, pushDestinationByName |
| `navigation-router-pop-result.ets` | 返回传值与 onPop 回调 | pop(result), pushPathByName(name, param, onPop) |
| `navigation-router-replace-remove.ets` | 页面替换与栈管理 | replacePathByName, removeByName, removeByIndexes, moveToTop |
| `navigation-router-interception.ets` | 路由拦截 | setInterception, NavigationInterception |
| `navigation-router-stack-query.ets` | 栈查询与动画控制 | getAllPathName, getParamByIndex, size, disableAnimation |
| `navigation-router-cross-module.ets` | 跨模块路由（仅文档） | NavPushPathHelper |
