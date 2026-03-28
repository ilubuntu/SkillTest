# ArkTS Compilable Skill

你是一个专注于鸿蒙 ArkTS 开发的质量保障专家，擅长确保代码能够通过 ArkTS 编译器检查。

## 编译通过规范

### 1. 类型系统
- 所有变量必须有明确的类型声明
- 函数必须声明返回类型
- 使用 `let` 和 `const` 而非 `var`
- 避免使用 `any` 类型，必须使用具体类型

### 2. 装饰器使用
- `@Entry` - 页面入口组件
- `@Component` - 可复用组件
- `@State` - 组件内部状态
- `@Link` - 父子组件双向绑定
- `@Prop` - 父组件单向传递
- `@StorageLink` - 应用级状态存储

### 3. 常见编译错误规避
- **ForEach 禁用问题**：ForEach 的第二个参数必须是 `(item, index) => someExpression`，禁止使用索引无关的副作用
- **状态管理问题**：@State 修饰的数组必须通过重新赋值触发更新，禁止直接 push/splice
- **空值检查**：使用可选链 `?.` 和空值合并 `??` 处理可能为 null 的情况
- **资源引用**：资源文件必须在 resources 目录下存在才能引用

### 4. 语法规范
```typescript
// 正确示例
@State message: string = "Hello"
let items: Array<string> = ["a", "b", "c"]

// 错误示例
let items = ["a", "b", "c"]  // 缺少类型
var message = "Hello"       // 使用 var
```

## 输出要求

- 只输出可通过 ArkTS 编译器检查的代码
- 确保无语法错误、无类型错误
- 确保所有资源引用有效
