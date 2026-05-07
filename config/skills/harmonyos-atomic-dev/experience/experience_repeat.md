# Repeat 组件开发经验

## 一、元服务 API 兼容性清单

### 可用 API（元服务 API 12+）

| API | 说明 | 元服务起始版本 |
|-----|------|---------------|
| `Repeat<T>(arr: Array<T>)` | 基础构造，以数组为数据源 | API 12 |
| `.each(itemGenerator)` | 组件生成函数，**必填**，否则运行时报错 | API 12 |
| `.key(keyGenerator)` | 键值生成函数，强烈建议自定义 | API 12 |
| `.virtualScroll(options?)` | 开启虚拟滚动/懒加载 | API 12 |
| `.template(type, itemBuilder, options?)` | 定义渲染模板 | API 12 |
| `.templateId(typedFunc)` | 为数据项分配模板类型 | API 12 |
| `VirtualScrollOptions.totalCount` | 期望加载的数据项总数 | API 12 |
| `RepeatItem<T>` | item + index 的封装对象 | API 12 |
| `TemplateOptions.cachedCount` | 模板缓存池大小 | API 12 |

### 可用 API（元服务 API 18+）

| API | 说明 | 元服务起始版本 |
|-----|------|---------------|
| `Repeat<T>(arr: RepeatArray<T>)` | 支持 ReadonlyArray / Readonly\<Array\> | API 18 |
| `VirtualScrollOptions.reusable` | 控制是否开启节点复用，默认 true | API 18 |

### 可用 API（元服务 API 19+）

| API | 说明 | 元服务起始版本 |
|-----|------|---------------|
| `VirtualScrollOptions.onLazyLoading` | 数据精准懒加载回调 | API 19 |
| `VirtualScrollOptions.onTotalCount` | 动态计算数据总长度 | API 19 |
| `.onMove(from, to)` | 拖拽排序（仅 List + ListItem） | API 19 |

### 不支持 / 限制

| 限制 | 说明 |
|------|------|
| V1 装饰器混用 | Repeat 不支持与 @State/@Prop/@Link 等 V1 装饰器混用，必须使用 @ComponentV2 + V2 装饰器 |
| 动画效果 | Repeat 子组件不支持动画过渡 |
| 容器内多 Repeat | 滚动容器内只能包含一个 Repeat，不建议与 ForEach/LazyForEach 混用 |
| 关闭懒加载时模板不可用 | 省略 .virtualScroll() 时，.template() 和 .templateId() 不可用 |
| 前插保持 | API 20+ 才完整支持 maintainVisibleContentPosition |
| 数组密封/冻结 | Object.seal() / Object.freeze() 会导致 Repeat 部分功能失效 |
| @Builder 按值传递 | 混用 @Builder 时必须按引用传递 RepeatItem 整体，按值传递不会触发 UI 刷新 |

## 二、核心调用方式

### 2.1 基础循环渲染（关闭懒加载）

适用于短列表（<30项），不限容器类型：

```typescript
Repeat<string>(this.dataList)
  .each((ri: RepeatItem<string>) => {
    Text(ri.item)
  })
  .key((item: string) => item)
```

### 2.2 虚拟滚动（懒加载）

必须与 List/Grid/Swiper/WaterFlow 配合使用：

```typescript
List() {
  Repeat<string>(this.dataList)
    .each((ri: RepeatItem<string>) => {
      ListItem() { Text(ri.item) }
    })
    .key((item: string) => item)
    .virtualScroll({ totalCount: this.dataList.length })
}
.cachedCount(2)
```

### 2.3 模板渲染

同一数据源渲染多种子组件：

```typescript
Repeat<T>(this.data)
  .each((ri) => { /* 默认模板 */ })
  .template('A', (ri) => { /* A模板 */ }, { cachedCount: 3 })
  .template('B', (ri) => { /* B模板 */ }, { cachedCount: 3 })
  .templateId((item) => item.type) // 根据 type 返回 'A' 或 'B'
  .virtualScroll()
```

要点：
- `.each()` 等价于 type 为空字符串的 `.template()`
- 只有相同 template type 的节点可以互相复用
- cachedCount 建议设置为容器显示区域内的节点个数，不建议小于 2

### 2.4 嵌套 Repeat

```typescript
List() {
  Repeat<Category>(this.categories)
    .each((ri) => {
      ListItem() {
        List() {
          Repeat<string>(ri.item.items)
            .each((subRi) => { ListItem() { ... } })
            .key((item, index) => `${ri.item.id}_${item}_${index}`)
            .virtualScroll()
        }
      }
    })
    .key((item) => item.id)
    .virtualScroll()
}
```

要点：内层 key 需包含外层标识，避免跨分类 key 冲突。

## 三、数据操作要点

Repeat 直接监听状态变量变化，无需手动通知更新：

| 操作 | 方式 |
|------|------|
| 添加数据 | `this.list.push(item)` / `this.list.unshift(item)` |
| 删除数据 | `this.list.splice(index, 1)` / `this.list.pop()` / `this.list.shift()` |
| 修改数据 | `this.list[index] = newValue` / `this.list.splice(index, 1, newValue)` |
| 交换数据 | 直接交换数组元素 |
| 截取数据 | `this.list = this.list.slice(0, n)` |
| 修改子属性 | 使用 `@ObservedV2` + `@Trace` 装饰类属性 |

### key 值生成最佳实践

- **推荐**：使用对象唯一 id（如 `item.id`），key 值与 index 无关
- **避免**：使用 index 作为 key，因为数据移动时 index 变化会触发不必要的重新渲染
- **要求**：key 在数组变化过程中必须保持唯一且确定（相同输入 -> 相同输出）


## 四、降级处理策略

1. **API 19+ 特性不可用时**：onLazyLoading/onTotalCount 不可用，改用 totalCount + onScrollIndex 手动触发数据加载
2. **动画需求**：Repeat 本身不支持动画，需在子组件内部使用 animateTo/explicitAnimator 实现
3. **V1 项目迁移**：将 @Component 改为 @ComponentV2，@State 改为 @Local，@Observed 改为 @ObservedV2 + @Trace，ForEach/LazyForEach 替换为 Repeat + .virtualScroll()
4. **关闭复用功能**：API 18+ 可通过 `.virtualScroll({ reusable: false })` 关闭 Repeat 自身复用，改用 @ReusableV2 装饰器管理生命周期
