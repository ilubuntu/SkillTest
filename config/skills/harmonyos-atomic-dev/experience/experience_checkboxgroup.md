# CheckboxGroup 组件开发经验

## 元服务 API 兼容性清单

### 可用 API

| API | 元服务版本 | 说明 |
|---|---|---|
| `CheckboxGroup(options?: CheckboxGroupOptions)` | API 11+ | 复选框组 |
| `CheckboxGroupOptions.group` | API 11+ | 分组名称，需与 Checkbox.group 一致 |
| `.selectAll(bool)` | API 11+ | 全选控制 |
| `.selectedColor / .unselectedColor` | API 11+ | 颜色 |
| `.onChange((status: CheckboxGroupResult) => void)` | API 11+ | 状态回调，status.status/name[] |

### 不可用 API

| API | 所需版本 |
|---|---|
| `.shape(CheckBoxShape)` | API 12+ |
| `.contentModifier` | API 12+ |

## 核心调用方式

CheckboxGroup 通过 `group` 名称关联同名的 Checkbox 组件：

```typescript
CheckboxGroup({ group: 'group1' })
  .selectAll(this.selectAll)
  .onChange((status) => { /* status.name[] */ })

Checkbox({ name: 'item1', group: 'group1' })  // 同组
Checkbox({ name: 'item2', group: 'group1' })  // 同组
```
