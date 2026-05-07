# LazyForEach 元服务开发经验

## API 兼容性清单

### 元服务可用 API（API 11+）

| API | 说明 | 元服务起始版本 |
|-----|------|---------------|
| `LazyForEach(dataSource, itemGenerator, keyGenerator?)` | 懒加载渲染 | API 11 |
| `IDataSource` 接口 | 数据源接口 | API 11 |
| `IDataSource.totalCount()` | 获取数据总数 | API 11 |
| `IDataSource.getData(index)` | 获取指定索引数据 | API 11 |
| `IDataSource.registerDataChangeListener(listener)` | 注册监听器 | API 11 |
| `IDataSource.unregisterDataChangeListener(listener)` | 注销监听器 | API 11 |
| `DataChangeListener.onDataReloaded()` | 全量重载 | API 11 |
| `DataChangeListener.onDataAdd(index)` | 添加数据通知 | API 11 |
| `DataChangeListener.onDataDelete(index)` | 删除数据通知 | API 11 |
| `DataChangeListener.onDataChange(index)` | 变更数据通知 | API 11 |
| `DataChangeListener.onDataMove(from, to)` | 移动数据通知 | API 11 |
| `ListItem.onMove(from, to)` | 拖拽排序属性 | API 10 |
| `cachedCount` | 预加载缓冲数量 | API 11 |

### 元服务可用 API（API 12+）

| API | 说明 | 元服务起始版本 |
|-----|------|---------------|
| `DataChangeListener.onDatasetChange(operations[])` | 精准批量操作 | API 12 |
| `DataOperationType.ADD/DELETE/CHANGE/MOVE/EXCHANGE/RELOAD` | 操作类型枚举 | API 12 |
| `DataAddOperation` | 添加操作（含 count 批量） | API 12 |
| `DataDeleteOperation` | 删除操作（含 count 批量） | API 12 |
| `DataChangeOperation` | 变更操作 | API 12 |
| `DataMoveOperation` | 移动操作 | API 12 |
| `DataExchangeOperation` | 交换操作 | API 12 |
| `DataReloadOperation` | 全量重载操作 | API 12 |

### 已废弃 API（不可使用）

| 废弃 API | 替代 API | 废弃版本 |
|----------|---------|---------|
| `onDataAdded(index)` | `onDataAdd(index)` | API 8 |
| `onDataDeleted(index)` | `onDataDelete(index)` | API 8 |
| `onDataChanged(index)` | `onDataChange(index)` | API 8 |
| `onDataMoved(from, to)` | `onDataMove(from, to)` | API 8 |

## 核心调用方式

### 1. IDataSource 实现（必需）

LazyForEach 要求开发者实现 `IDataSource` 接口作为数据源，必须包含以下四个方法：

```typescript
class BasicDataSource implements IDataSource {
  private listeners: DataChangeListener[] = []

  totalCount(): number { /* 返回数据总数 */ }
  getData(index: number): T { /* 返回指定索引数据 */ }
  registerDataChangeListener(listener: DataChangeListener): void { /* 注册监听 */ }
  unregisterDataChangeListener(listener: DataChangeListener): void { /* 注销监听 */ }
}
```

数据源内部需维护 `listeners` 数组，在数据变化时通过 listener 通知框架更新。

### 2. 通知方法封装

在 `BasicDataSource` 基类中封装通知方法：

```typescript
notifyDataAdd(index: number): void {
  this.listeners.forEach(l => l.onDataAdd(index))
}
notifyDataDelete(index: number): void {
  this.listeners.forEach(l => l.onDataDelete(index))
}
notifyDataChange(index: number): void {
  this.listeners.forEach(l => l.onDataChange(index))
}
notifyDataMove(from: number, to: number): void {
  this.listeners.forEach(l => l.onDataMove(from, to))
}
notifyDataReload(): void {
  this.listeners.forEach(l => l.onDataReloaded())
}
notifyDatasetChange(operations: DataOperation[]): void {
  this.listeners.forEach(l => l.onDatasetChange(operations))
}
```

### 3. 键值生成规则

- 必须提供 `keyGenerator` 参数，确保键值唯一且一致
- 推荐使用业务 ID 作为键值：`(item: DataItem) => item.id`
- 避免使用 `JSON.stringify` 生成键值（性能问题）
- 默认 keyGenerator 仅依赖 index，数据变化时组件不刷新

### 4. 拖拽排序

拖拽排序通过 ListItem 的 `onMove` 事件实现：

```typescript
LazyForEach(dataSource, (item) => {
  ListItem() { /* ... */ }
}, (item) => item)
.onMove((from: number, to: number) => {
  // 直接修改 dataSource 数据，无需调用 listener 通知
  dataSource.moveDataWithoutNotify(from, to)
})
```

关键点：onMove 回调中直接修改数据源，不需要调用 `DataChangeListener` 方法通知更新。

### 5. onDatasetChange 批量操作（API 12+）

```typescript
dataSource.notifyDatasetChange([
  { type: DataOperationType.CHANGE, index: 0 },
  { type: DataOperationType.ADD, index: 3, count: 2 },
  { type: DataOperationType.DELETE, index: 10, count: 2 },
  { type: DataOperationType.EXCHANGE, index: { start: 4, end: 6 } }
])
```

注意事项：
- **不能与 onDataAdd/onDataDelete 等其他 DataChangeListener 方法混用**
- 含 `RELOAD` 操作时其他操作均不生效
- operations 中的 index 基于修改前的原数组查找
- 同一 index 只执行第一个 operation

## 编译问题与解决方案

### 问题 1: 对象字面量类型推断错误

**错误**: `Object literal must correspond to some explicitly declared class or interface (arkts-no-untyped-obj-literals)`

**原因**: ArkTS 不允许使用 `map` 返回未声明类型的对象字面量

**解决**: 使用显式类型标注的循环替代 `map`:
```typescript
// 错误写法
this.dataArray = this.dataArray.map(item => ({ id: item.id, text: item.text + '!' }))

// 正确写法
const newData: DataItem[] = []
for (let i = 0; i < this.dataArray.length; i++) {
  const old = this.dataArray[i]
  newData.push({ id: old.id, text: old.text + '!' } as DataItem)
}
this.dataArray = newData
```

### 问题 2: 索引访问不支持

**错误**: `Indexed access is not supported for fields (arkts-no-props-by-index)`

**原因**: ArkTS 不支持 `obj['key']` 索引访问语法

**解决**: 为 DataSource 类添加 public 方法暴露数据修改能力，不使用索引访问私有字段

### 问题 3: 枚举值拼写错误

**错误**: `Cannot find name 'ItemStart'. Did you mean 'ItemState'?`

**解决**: 使用正确的枚举引用 `ItemAlign.Start` 替代 `ItemStart`

## 使用限制

1. **容器限制**: 仅 List、ListItemGroup、Grid、Swiper、WaterFlow 支持懒加载
2. **单容器限制**: 每个容器内只能包含一个 LazyForEach
3. **子组件限制**: 每次迭代必须且只能创建一个子组件
4. **dataSource 不可重赋值**: 重新赋值 dataSource 会导致异常
5. **高度缺失**: 子组件未设置明确高度会导致懒加载失效（框架认为全部可见）
6. **@Reusable 与 @ComponentV2 不可混用**: 会导致组件渲染异常，应使用 @Component 或 @ReusableV2
7. **onDatasetChange 不可与其他更新方法混用**: 同一 LazyForEach 只能选一种更新方式

## 降级处理策略

当数据量较小（< 100 条）时，可使用 `ForEach` 替代 `LazyForEach`：
- ForEach 更简单，无需实现 IDataSource
- ForEach 支持所有容器组件（无懒加载容器限制）
- 数据量 > 1000 时必须使用 LazyForEach 以保证性能

当 `onDatasetChange` (API 12+) 不可用时：
- 使用 `onDataReloaded` 全量重载替代批量操作
- 注意全量重载在 List.onScrollIndex 中可能导致屏幕闪烁
- 可通过改变键值触发精准重建来规避闪烁问题
