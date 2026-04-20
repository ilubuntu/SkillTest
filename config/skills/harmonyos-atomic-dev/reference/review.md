# HarmonyOS Code Review Checklist

> 代码审查检查清单 - 用于审查 HarmonyOS/ArkTS 代码的常见问题和最佳实践

## 1. ArkTS 类型系统检查

1. 不支持 `{...obj}` 展开语法
2. 不支持 `obj[key]` 形式的动态访问
3. 错误：直接使用对象字面量类型 `const statusMap: Record<Status, { text: string; color: string }> = {...};` 需要先定义接口
4. 严格禁止将对象字面量作为类型声明使用，必须使用已定义的 interface 或 type
5. `Record` 字面量需要显式类型
6. 减少 `Array.from` 的使用
7. 禁止使用系统资源图标（sys.symbol.*），使用 Emoji 替代
8. 生成函数时确保括号闭环
9. **禁止 any 类型**，所有变量、参数、返回值必须有明确类型声明，用具体 interface 替代 any
10. **限制类型断言 as**，用正确的类型定义替代 `as`，使用 `Record<string, Object>` 替代动态属性访问
11. **禁止 for..in 循环**，用 `Object.keys().forEach()` 或 `for..of` 替代

## 2. build() 规则检查

1. 禁止提前 `return`，`build(){if(!this.data){return;//编译错误}Column(){/*...*/}}`
2. 禁止在 build() 中声明变量
3. null 类型在嵌套回调中的收窄
4. 条件渲染使用 If/Else 组件或三元表达式，不能在 build() 中处理条件逻辑

## 3. V2 状态管理使用检查

1. V2 状态管理装饰器（@ObservedV2、@Trace、@ComponentV2、@Local、@Param）可直接使用，无需 import，错误示例：`import { ObservedV2, Trace } from '@kit.ArkUI'` 
2. @Param 必须有默认值， `@Param item: DataType = {} as DataType`
3. 变量名称必须包含业务语义，**禁止使用 onClick、enable、borderRadius 等系统关键词作为变量名**，如 `borderRadius` → `cardBorderRadius`，`onClick` → `onCardClick`
4. import 语句必须置于文件顶部，ArkTS 不允许在其他语句之后出现 import
5. @ComponentV2 不支持通过 @Param 传递 builder 函数， 使用 `@BuilderParam` 装饰器替代

## 4. 组件属性检查

1. 尺寸约束使用 constraintSize， 如：`Column(){...}.constraintSize({maxHeight:'80%'})`
2. Scroller 使用时必须先声明实例，如：`private scroller:Scroller=new Scroller(); Scroll(this.scroller)`
3. `Column` / `Row` 的间距改用 `.margin()` 代替 `.space()`
4. `GradientDirection` 属性支持 Left、Top、Right、Bottom、LeftTop、LeftBottom、RightTop、RightBottom、None
5. Column 的 alignItems 属性支持 HorizontalAlign，不支持 VerticalAlign；Row 的 alignItems 属性支持 VerticalAlign 不支持 HorizontalAlign
6. Stack 不支持 justifyContent 属性，改用 `.alignContent(Alignment.Center)`
7. Row 不支持 scrollable 属性
8. FontWeight 不支持 SemiBold，用 Bold 或 Medium 替代，仅支持 Lighter/Normal/Regular/Medium/Bold/Bolder
9. borderWidth 各方向直接接受 Length 数值，不需要嵌套对象， `.borderWidth({ bottom: 1 })` 而非 `.borderWidth({ bottom: { width: 1 } })`

## 5. 资源与 API 检查

1. 禁止使用系统资源图标（sys.symbol.*），使用 Emoji 替代
2. 从零构建应用时，`Index.ets` 仅作为入口容器，使用 Navigation 组件管理页面路由。
3. showToast 已废弃，用 `this.getUIContext().getPromptAction().showToast()` 替代 `promptAction.showToast()`

## 6. 类型导入检查

1. 使用的类型必须显式导入，在文件头部添加缺失的类型导入，如 `import { TypeName } from '../../common/models/Models'`
2. interface/class 跨文件使用必须 export，ArkTS 中 interface 默认是模块私有的

## 7. 对象字面量检查

1. 所有对象字面量必须有对应 interface/class 声明，不能用 TypeScript 的类型推断
2. 禁止 `{ key: type }` 内联类型，须预定义 interface，如 `Array<{ icon: string }>` 改为预定义 interface
3. 数组元素类型不可推断（7 次）— `let items: SettingItem[] = []`

## 8. 导入路径检查（162 次）

1. 模块相对路径计算错误（162 次）— 创建文件时同步规划好导入路径，注意回退层级

## See Also

- [arkts.md](arkts.md) — ArkTS 语言完整限制
- [../SKILL.md](../SKILL.md) — 开发技能主文档
