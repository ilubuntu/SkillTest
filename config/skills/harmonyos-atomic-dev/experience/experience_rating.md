# Rating 组件开发经验

## 元服务 API 兼容性清单

### 可用 API（元服务 API 11+）

| API | 说明 | 默认值 | 备注 |
|-----|------|--------|------|
| `Rating(options?: RatingOptions)` | 构造函数 | - | rating + indicator 参数 |
| `RatingOptions.rating` | 评分值 | 0 | 范围 [0, stars]，支持 $$ 双向绑定 |
| `RatingOptions.indicator` | 是否指示器 | false | true=只读，false=可交互 |
| `stars(value: number)` | 星级总数 | 5 | 小于等于0按默认值 |
| `stepSize(value: number)` | 评分步长 | 0.5 | 范围 [0.1, stars] |
| `starStyle(options: StarStyleOptions)` | 自定义星级样式 | 系统默认 | 支持本地/网络图片，不支持 PixelMap |
| `onChange(callback: (value: number) => void)` | 评分变化回调 | - | 仅交互模式触发 |

### 可用 API（元服务 API 12+）

| API | 说明 | 备注 |
|-----|------|------|
| `contentModifier(modifier: ContentModifier<RatingConfiguration>)` | 自定义内容区 | RatingConfiguration 含 rating/indicator/stars/stepSize/triggerChange |

### 不可用 API（API 18+，元服务不支持）

| API | 替代方案 |
|-----|----------|
| `stars(starCount: Optional<number>)` | 使用 `stars(value: number)` |
| `stepSize(size: Optional<number>)` | 使用 `stepSize(value: number)` |
| `starStyle(options: Optional<StarStyleOptions>)` | 使用 `starStyle(options: StarStyleOptions)` |
| `contentModifier(modifier: Optional<...>)` | 使用 `contentModifier(modifier: ContentModifier<...>)` (API 12+) |
| `onChange(callback: Optional<OnRatingChangeCallback>)` | 使用 `onChange(callback: (value: number) => void)` |
| `rating !! 双向绑定` | 使用 `$$ 双向绑定` 或手动 onChange 管理 |

## 各场景核心调用方式

### 1. 基础评分

```typescript
Rating({ rating: 3, indicator: false })
  .stars(5)
  .stepSize(0.5)
  .onChange((value: number) => {
    // value 为新评分值
  })
```

### 2. 指示器模式（只读展示）

```typescript
Rating({ rating: 3.5, indicator: true })
  .stars(5)
// indicator=true 时默认高度 12.0vp，宽度=高度*stars
// indicator=false 时默认高度 28.0vp
```

关键差异：indicator 模式下组件尺寸更小，onChange 不会触发。

### 3. 自定义星级样式

```typescript
Rating({ rating: 3, indicator: false })
  .starStyle({
    foregroundUri: '选中的图片路径',
    backgroundUri: '未选中的图片路径',
    secondaryUri: '部分选中的图片路径'  // 可选
  })
```

注意事项：
- `starStyle` 支持本地图片和网络图片，不支持 PixelMap
- 图片异步加载，不支持同步
- 路径错误时保持上次结果，首次错误则不显示
- 建议宽高设为 `width = height * stars` 保持单个星星为方形

### 4. 动态步长控制

```typescript
Rating({ rating: this.currentRating, indicator: false })
  .stars(this.starCount)      // 动态调整星数
  .stepSize(this.stepSize)    // 动态调整步长
```

- 步长=1：仅整星评分
- 步长=0.5：支持半星（默认）
- 步长=0.1：精细评分

## 编译问题与解决方案

### 编译结果

Rating 组件所有 demo 一次编译通过，无报错。编译耗时约 5 秒（增量构建）。

### 无特殊编译问题

Rating 是 ArkUI 内置组件，不需要额外导入或添加系统能力声明。所有 API 11+ 属性均可在元服务中直接使用。

## 降级处理策略

API 18+ 的 `Optional<>` 重载版本在元服务中不可用，但这些重载仅增加了对 `undefined` 参数的支持，功能上完全可由非 Optional 版本替代：

- 需要重置为默认值时，直接传入默认值（如 `stars(5)`、`stepSize(0.5)`）
- 需要取消回调时，不传 `onChange` 即可
- 双向绑定使用 `$$` 而非 `!!`
