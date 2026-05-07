# Health Service Kit 元服务开发经验

## 一、API 兼容性总览

### 1. healthService（运动健康联动服务）

| API | 元服务支持 | 起始版本 | 说明 |
|-----|-----------|---------|------|
| `healthService.workout` 对象 | ✅ | 5.0.0(12) | 运动健康联动服务入口 |
| `workout.ActivityReport` 类型 | ✅ | 5.0.0(12) | 实时三环数据类型定义 |
| `workout.readActivityReport()` | ✅ | 5.0.0(12) | 读取当日步数/热量/锻炼时长 |
| `workout.config()` | ❌ | 5.1.0(18) | 配置联动运动参数 |
| `workout.start()` | ❌ | 5.1.0(18) | 开启运动联动 |
| `workout.pause()` | ❌ | 5.1.0(18) | 暂停运动联动 |
| `workout.resume()` | ❌ | 5.1.0(18) | 恢复运动联动 |
| `workout.stop()` | ❌ | 5.1.0(18) | 停止运动联动 |
| `workout.onData()` | ❌ | 5.1.0(18) | 注册运动数据监听 |
| `workout.offData()` | ❌ | 5.1.0(18) | 取消运动数据监听 |
| `workout.onEvent()` | ❌ | 5.1.0(18) | 注册设备事件监听 |
| `workout.offEvent()` | ❌ | 5.1.0(18) | 取消设备事件监听 |
| `workout.sendData()` | ❌ | 5.1.0(18) | 下发融合运动数据 |
| `workout.sendEvent()` | ❌ | 5.1.0(18) | 下发控制事件 |

### 2. healthStore（运动健康数据服务）

| API | 元服务支持 | 起始版本 | 说明 |
|-----|-----------|---------|------|
| `healthStore.init()` | ✅ | 5.0.0(12) | 初始化（必须先调用） |
| `healthStore.requestAuthorizations()` | ✅ | 5.0.0(12) | 申请健康数据读写权限 |
| `healthStore.cancelAuthorizations()` | ✅ | 5.0.0(12) | 取消授权 |
| `healthStore.aggregateData()` | ✅ | 5.0.0(12) | 聚合查询运动数据 |
| `healthStore.getAuthorizations()` | ⚠️ | 5.0.0(12) | 文档标记支持但编译器报 11706010 错误 |
| `healthStore.syncAll()` | ❌ | 5.1.0(18) | 主动数据同步，无元服务标记 |
| `DataType` | ✅ | 5.0.0(12) | 数据类型定义 |
| `AggregateRequest` | ✅ | 5.0.0(12) | 聚合查询请求 |
| `AggregateResult` | ✅ | 5.0.0(12) | 聚合查询结果 |
| `GroupUnitType` | ✅ | 5.0.0(12) | 按天聚合 (DAY=3) |
| `SortOrder` | ✅ | 5.0.0(12) | 排序 (ASC=0, DESC=1) |

### 3. samplePointHelper 子模块

| 数据类型 | 元服务编译 | 说明 |
|----------|-----------|------|
| `dailyActivities` | ✅ | 每日活动数据（步数、卡路里、距离） |
| `heartRate` | ❌ | 心率数据，编译报 11706010 错误 |

---

## 二、核心调用方式

### 2.1 初始化（所有 API 调用的前提）

```typescript
import { healthStore } from '@kit.HealthServiceKit'
import { common } from '@kit.AbilityKit'

const context = getContext(this) as common.UIAbilityContext
await healthStore.init(context)
```

### 2.2 读取实时三环数据

```typescript
import { healthService } from '@kit.HealthServiceKit'

const report: healthService.workout.ActivityReport = await healthService.workout.readActivityReport()
// report.steps — 步数
// report.activeCalories — 活动热量（卡）
// report.exercise — 锻炼时长（分钟）
// report.stepsGoal — 步数目标（可能为 undefined）
```

注意：目标字段（stepsGoal、activeCaloriesGoal 等）在用户未设置时为 undefined，需做空值判断。

### 2.3 申请/取消授权

```typescript
// 申请授权 — 需要 UIAbilityContext
const request: healthStore.AuthorizationRequest = {
  readDataTypes: [healthStore.samplePointHelper.dailyActivities.DATA_TYPE],
  writeDataTypes: []
}
const response = await healthStore.requestAuthorizations(context, request)

// 取消授权
await healthStore.cancelAuthorizations()
```

### 2.4 聚合查询

```typescript
const request: healthStore.AggregateRequest<healthStore.samplePointHelper.dailyActivities.AggregateFields> = {
  dataType: healthStore.samplePointHelper.dailyActivities.DATA_TYPE,
  metrics: {
    step: ['sum'],
    calorie: ['sum'],
    distance: ['sum']
  },
  groupBy: { unitType: healthStore.GroupUnitType.DAY },
  startLocalDate: '04/22/2026',  // MM/DD/YYYY
  endLocalDate: '04/22/2026'
}
const results = await healthStore.aggregateData<healthStore.samplePointHelper.dailyActivities.AggregateResult>(request)
```

---

## 三、编译问题与解决方案

### 3.1 错误码 11706010: can't support atomicservice application

**表现**：使用某些 API 时编译器报错，即使文档标记为元服务支持。

**已知受影响的 API**：
- `healthStore.samplePointHelper.heartRate` — 心率数据类型不可用于元服务编译
- `healthStore.getAuthorizations()` — 查询授权 API 编译受限

**解决方案**：
- 避免使用 `heartRate`，改用 `dailyActivities` 等已验证可编译的数据类型
- `getAuthorizations` 可用 `requestAuthorizations` 的返回值替代（返回值中包含已授权的类型列表）

### 3.2 ArkTS 类型限制

**问题**：`Partial` 等 Utility Types 在 ArkTS 中不支持（arkts-no-utility-types）。

**解决方案**：使用 `AggregateRequest<T>` 的泛型形式，配合 `AggregateFields` 类型定义：
```typescript
// 错误写法
metrics: { step: ['sum'] } as Partial<Record<string, AggregateMetricScope[]>>

// 正确写法
const request: AggregateRequest<samplePointHelper.dailyActivities.AggregateFields> = {
  metrics: { step: ['sum'] }
}
```

**问题**：对象字面量必须对应显式声明的类或接口（arkts-no-untyped-obj-literals）。

**解决方案**：使用泛型参数声明类型，或在赋值前先用显式类型声明变量。

---

## 四、降级处理策略

| 需求 | 元服务方案 | 替代方案 |
|------|-----------|---------|
| 读取当日运动数据 | `readActivityReport()` ✅ | — |
| 查询历史运动数据 | `aggregateData()` ✅ | — |
| 管理数据权限 | `requestAuthorizations()` / `cancelAuthorizations()` ✅ | — |
| 控制穿戴设备运动 | ❌ 不支持 | 开发为普通应用 |
| 实时心率/运动数据流 | ❌ 不支持 | 开发为普通应用 |
| 读取心率历史数据 | ❌ heartRate 编译受限 | 服务端通过华为开放 API 获取 |
| 主动同步数据 | ❌ syncAll 不支持 | 开发为普通应用 |

---

## 五、关键注意事项

1. **初始化顺序**：所有 healthStore/healthService API 调用前必须先执行 `healthStore.init(context)`，且仅需调用一次
2. **账号依赖**：用户需已登录华为账号，未登录返回错误码 1002702001
3. **隐私协议**：用户需同意隐私协议，未同意返回错误码 1002703001
4. **设备限制**：仅 Phone/Tablet，不支持 Wearable（部分 API 在 Wearable 返回特定错误码）
5. **地区限制**：仅中国境内（香港、澳门、中国台湾除外）
6. **模拟器限制**：模拟器不支持实时三环数据，需真机测试
7. **日期格式**：聚合查询的日期格式为 `MM/DD/YYYY`（如 `10/30/2023`）
8. **聚合分组**：按天聚合（unitType=DAY）当前只支持 duration=1
