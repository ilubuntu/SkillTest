# TextInput 组件 HarmonyOS 6.0 开发 Skill

## 概述

TextInput 组件是 OpenHarmony 中用于单行文本输入的基础组件。它提供了丰富的输入功能，包括占位符、文本类型限制、输入过滤、光标控制等。TextInput 广泛应用于表单输入、搜索框、密码输入等场景。

## 重要说明

- **基础组件**: TextInput 是 ArkUI 的基础内置组件，无需导入
- **单行输入**: TextInput 用于单行文本输入，多行输入请使用 TextArea
- **键盘类型**: 根据不同的 inputType 自动弹出合适的键盘类型
- **文本限制**: 支持通过 maxLength 限制输入长度
- **安全输入**: 支持密码输入模式，可设置是否显示密码

## 模块信息

- **组件名称**: TextInput
- **SDK 版本**: HarmonyOS 6.0 (API 12+)
- **系统能力**: SystemCapability.ArkUI.ArkUI.Full
- **更新日期**: 2026-02-24
- **官方文档**:
  - [TextInput 输入框 - 华为开发者](https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V5/ts-basic-components-textinput-V5)

## 经验总结
1. 从 TextInput 不支持 passwordIcon 参数。密码可见性切换通过 InputType.Normal 和 InputType.Password 来实现，不需要额外的图标配置。

## 一、组件基础

### 1.1 导入方式

```typescript
// TextInput 是内置组件，无需导入
// 直接使用即可
TextInput({ placeholder: '请输入内容' })
```

### 1.2 基础用法

```typescript
// 简单文本输入
TextInput({ placeholder: '请输入用户名' })

// 设置默认文本
TextInput({ text: '默认内容' })

// 密码输入
TextInput({ placeholder: '请输入密码' })
  .type(InputType.Password)

// 限制输入长度
TextInput({ placeholder: '最多输入10个字符' })
  .maxLength(10)
```

## 二、API 参数

### 2.1 构造参数

| 参数 | 类型 | 必填 | 默认值 | 描述 |
|------|------|------|--------|------|
| placeholder | `string \| Resource` | 否 | - | 占位符文本 |
| text | `string \| Resource` | 否 | - | 输入框的当前文本内容 |
| controller | `TextInputController` | 否 | - | 文本输入控制器 |

### 2.2 输入类型

| 类型 | 描述 |
|------|------|
| `InputType.Normal` | 普通输入框 |
| `InputType.Password` | 密码输入框 |
| `InputType.Email` | 邮箱地址输入框 |
| `InputType.Number` | 纯数字输入框 |
| `InputType.Phone` | 电话号码输入框 |
| `InputType.URL` | URL 地址输入框 |

### 2.3 常用属性

| 属性 | 类型 | 默认值 | 描述 |
|------|------|--------|------|
| `type` | `InputType` | Normal | 设置输入框类型 |
| `placeholder` | `string \| Resource` | - | 设置占位符内容 |
| `placeholderColor` | `ResourceColor` | '#999999' | 占位符文本颜色 |
| `placeholderFont` | `Font` | - | 占位符字体样式 |
| `enterKeyType` | `EnterKeyType` | Done | 键盘回车键类型 |
| `maxLength` | `number` | - | 最大输入字符数 |
| `caretColor` | `ResourceColor` | - | 光标颜色 |
| `selectedBackgroundColor` | `ResourceColor` | - | 选中文本背景色 |

### 2.4 样式属性

| 属性 | 类型 | 默认值 | 描述 |
|------|------|--------|------|
| `height` | `number \| string \| Resource` | 40 | 输入框高度 |
| `width` | `number \| string \| Resource` | - | 输入框宽度 |
| `backgroundColor` | `ResourceColor` | - | 背景颜色 |
| `borderRadius` | `number \| string` | - | 圆角半径 |

### 2.5 文本样式属性

| 属性 | 类型 | 默认值 | 描述 |
|------|------|--------|------|
| `fontColor` | `ResourceColor` | '#e6000000' | 文本颜色 |
| `fontSize` | `number \| string \| Resource` | 16fp | 文本大小 |
| `fontStyle` | `FontStyle` | Normal | 文本样式 |
| `fontWeight` | `number \| FontWeight \| string` | Normal | 字体粗细 |
| `fontFamily` | `string \| Resource` | 'HarmonyOS Sans' | 字体列表 |

### 2.6 回车键类型

| 类型 | 描述 |
|------|------|
| `EnterKeyType.Go` | 显示"前往" |
| `EnterKeyType.Search` | 显示"搜索" |
| `EnterKeyType.Send` | 显示"发送" |
| `EnterKeyType.Next` | 显示"下一个" |
| `EnterKeyType.Done` | 显示"完成" |
| `EnterKeyType.Previous` | 显示"上一个" |
| `EnterKeyType.NewLine` | 显示"换行" |
| `EnterKeyType.Join` | 显示"加入" |

### 2.7 事件

| 事件 | 类型 | 描述 |
|------|------|------|
| `onChange` | `(value: string) => void` | 输入内容变化时触发 |
| `onSubmit` | `(enterKey: EnterKeyType) => void` | 按下回车键时触发 |
| `onEditChanged` | `(isEditing: boolean) => void` | 输入状态变化时触发 |
| `onFocus` | `() => void` | 获得焦点时触发 |
| `onBlur` | `() => void` | 失去焦点时触发 |
| `onCopy` | `(value: string) => void` | 复制文本时触发 |
| `onCut` | `(value: string) => void` | 剪切文本时触发 |
| `onPaste` | `(value: string) => void` | 粘贴文本时触发 |

## 三、使用示例

### 3.1 基础文本输入

```typescript
@ComponentV2
struct BasicTextInputExample {
  @Local textValue: string = ''

  build() {
    Column({ space: 16 }) {
      Text('基础文本输入')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)

      TextInput({ placeholder: '请输入内容' })
        .width('100%')
        .height(45)
        .onChange((value: string) => {
          this.textValue = value
          console.info('输入内容: ' + value)
        })

      Text(`输入的值: ${this.textValue}`)
        .fontSize(14)
    }
    .width('100%')
    .padding(16)
  }
}
```

### 3.2 密码输入

```typescript
@ComponentV2
struct PasswordInputExample {
  @Local password: string = ''
  @Local showPassword: boolean = false

  build() {
    Column({ space: 16 }) {
      Text('密码输入')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)

      TextInput({ placeholder: '请输入密码' })
        .width('100%')
        .height(45)
        .type(InputType.Password)
        .showPassword(this.showPassword)
        .onChange((value: string) => {
          this.password = value
        })

      Row({ space: 12 }) {
        Checkbox({ name: 'showPassword' })
          .select(this.showPassword)
          .onChange((value: boolean) => {
            this.showPassword = value
          })
        Text('显示密码')
          .fontSize(14)
      }
    }
    .width('100%')
    .padding(16)
  }
}
```

### 3.3 数字输入

```typescript
@ComponentV2
struct NumberInputExample {
  @Local numberValue: string = ''

  build() {
    Column({ space: 16 }) {
      Text('数字输入')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)

      TextInput({ placeholder: '请输入数字' })
        .width('100%')
        .height(45)
        .type(InputType.Number)
        .onChange((value: string) => {
          this.numberValue = value
        })

      Text(`输入的数字: ${this.numberValue}`)
        .fontSize(14)
    }
    .width('100%')
    .padding(16)
  }
}
```

### 3.4 限制输入长度

```typescript
@ComponentV2
struct LimitedInputExample {
  @LimitedText: string = ''

  build() {
    Column({ space: 16 }) {
      Text('限制输入长度')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)

      TextInput({ placeholder: '最多输入10个字符' })
        .width('100%')
        .height(45)
        .maxLength(10)
        .onChange((value: string) => {
          this.textValue = value
        })

      Text(`${this.textValue.length}/10`)
        .fontSize(12)
        .fontColor('#999999')
    }
    .width('100%')
    .padding(16)
  }
}
```

### 3.5 自定义样式

```typescript
@ComponentV2
struct StyledInputExample {
  @Local searchText: string = ''

  build() {
    Column({ space: 16 }) {
      Text('自定义样式')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)

      // 搜索框样式
      TextInput({ placeholder: '搜索...' })
        .width('100%')
        .height(45)
        .backgroundColor('#F5F5F5')
        .borderRadius(22)
        .placeholderColor('#999999')
        .placeholderFont({ size: 14 })
        .fontColor('#333333')
        .caretColor('#007DFF')
        .onChange((value: string) => {
          this.searchText = value
        })

      // 下划线样式
      TextInput({ placeholder: '下划线输入框' })
        .width('100%')
        .height(45)
        .backgroundColor(Color.Transparent)
        .border({ width: { bottom: 2 }, color: '#007DFF' })
    }
    .width('100%')
    .padding(16)
  }
}
```

### 3.6 带图标的输入框

```typescript
@ComponentV2
struct IconInputExample {
  @Local username: string = ''

  build() {
    Column({ space: 16 }) {
      Text('带图标的输入框')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)

      Row() {
        Text('\uE641') // 用户图标
          .fontSize(20)
          .fontColor('#999999')
          .margin({ left: 12, right: 8 })

        TextInput({ placeholder: '请输入用户名' })
          .layoutWeight(1)
          .backgroundColor(Color.Transparent)
          .border({})
          .onChange((value: string) => {
            this.username = value
          })
      }
      .width('100%')
      .height(45)
      .backgroundColor('#F5F5F5')
      .borderRadius(8)
    }
    .width('100%')
    .padding(16)
  }
}
```

### 3.7 回车键类型

```typescript
@ComponentV2
struct EnterKeyExample {
  @Local searchText: string = ''
  @Local username: string = ''
  @Local message: string = ''

  build() {
    Column({ space: 16 }) {
      Text('回车键类型')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)

      // 搜索
      TextInput({ placeholder: '搜索...' })
        .width('100%')
        .height(45)
        .enterKeyType(EnterKeyType.Search)
        .onSubmit((enterKey: EnterKeyType) => {
          console.info('执行搜索: ' + this.searchText)
        })

      // 下一个
      TextInput({ placeholder: '用户名' })
        .width('100%')
        .height(45)
        .enterKeyType(EnterKeyType.Next)

      // 发送
      TextInput({ placeholder: '发送消息' })
        .width('100%')
        .height(45)
        .enterKeyType(EnterKeyType.Send)
        .onSubmit((enterKey: EnterKeyType) => {
          console.info('发送消息: ' + this.message)
        })
    }
    .width('100%')
    .padding(16)
  }
}
```

### 3.8 获得焦点和失去焦点

```typescript
@ComponentV2
struct FocusExample {
  @Local inputValue: string = ''
  @Local isFocused: boolean = false

  build() {
    Column({ space: 16 }) {
      Text('焦点控制')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)

      TextInput({ placeholder: '点击输入' })
        .width('100%')
        .height(45)
        .backgroundColor(this.isFocused ? '#E3F2FD' : '#F5F5F5')
        .border({ width: 2, color: this.isFocused ? '#007DFF' : '#E0E0E0' })
        .borderRadius(8)
        .onFocus(() => {
          this.isFocused = true
          console.info('获得焦点')
        })
        .onBlur(() => {
          this.isFocused = false
          console.info('失去焦点')
        })
    }
    .width('100%')
    .padding(16)
  }
}
```

### 3.9 输入验证

```typescript
@ComponentV2
struct ValidationExample {
  @Local email: string = ''
  @Local isValidEmail: boolean = true

  build() {
    Column({ space: 16 }) {
      Text('输入验证')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)

      TextInput({ placeholder: '请输入邮箱' })
        .width('100%')
        .height(45)
        .type(InputType.Email)
        .border({ width: 2, color: this.isValidEmail ? '#E0E0E0' : '#FF0000' })
        .borderRadius(8)
        .onChange((value: string) => {
          this.email = value
          // 简单的邮箱验证
          const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
          this.isValidEmail = emailRegex.test(value)
        })

      if (!this.isValidEmail && this.email.length > 0) {
        Text('请输入有效的邮箱地址')
          .fontSize(12)
          .fontColor('#FF0000')
      }
    }
    .width('100%')
    .padding(16)
  }
}
```

### 3.10 使用控制器

```typescript
@ComponentV2
struct ControllerExample {
  textController: TextInputController = new TextInputController()
  @Local inputValue: string = ''

  build() {
    Column({ space: 16 }) {
      Text('使用控制器')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)

      TextInput({ placeholder: '请输入内容', controller: this.textController })
        .width('100%')
        .height(45)

      Row({ space: 12 }) {
        Button('清空')
          .onClick(() => {
            this.textController.clear()
            this.inputValue = ''
          })

        Button('获取焦点')
          .onClick(() => {
            this.textController.requestFocus()
          })

        Button('失去焦点')
          .onClick(() => {
            this.textController.stopEditing()
          })
      }
    }
    .width('100%')
    .padding(16)
  }
}
```

## 四、高级用法

### 4.1 表单验证

```typescript
@ComponentV2
struct FormValidationExample {
  @Local username: string = ''
  @Local password: string = ''
  @Local errors: Record<string, string> = {}

  validateForm(): boolean {
    this.errors = {}

    if (!this.username) {
      this.errors['username'] = '请输入用户名'
    } else if (this.username.length < 3) {
      this.errors['username'] = '用户名至少3个字符'
    }

    if (!this.password) {
      this.errors['password'] = '请输入密码'
    } else if (this.password.length < 6) {
      this.errors['password'] = '密码至少6个字符'
    }

    return Object.keys(this.errors).length === 0
  }

  build() {
    Column({ space: 16 }) {
      Text('表单验证')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)

      Column({ space: 8 }) {
        TextInput({ placeholder: '用户名' })
          .width('100%')
          .height(45)
          .onChange((value: string) => {
            this.username = value
          })

        if (this.errors['username']) {
          Text(this.errors['username'])
            .fontSize(12)
            .fontColor('#FF0000')
        }
      }

      Column({ space: 8 }) {
        TextInput({ placeholder: '密码' })
          .width('100%')
          .height(45)
          .type(InputType.Password)
          .onChange((value: string) => {
            this.password = value
          })

        if (this.errors['password']) {
          Text(this.errors['password'])
            .fontSize(12)
            .fontColor('#FF0000')
        }
      }

      Button('提交')
        .width('100%')
        .onClick(() => {
          if (this.validateForm()) {
            console.info('表单验证通过')
          }
        })
    }
    .width('100%')
    .padding(16)
  }
}
```

### 4.2 实时搜索

```typescript
@ComponentV2
struct RealtimeSearchExample {
  @Local searchText: string = ''
  @Local searchResults: string[] = []

  performSearch(query: string): void {
    if (!query) {
      this.searchResults = []
      return
    }

    // 模拟搜索
    const mockData = ['Apple', 'Banana', 'Cherry', 'Date', 'Elderberry']
    this.searchResults = mockData.filter(item =>
      item.toLowerCase().includes(query.toLowerCase())
    )
  }

  build() {
    Column({ space: 16 }) {
      Text('实时搜索')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)

      TextInput({ placeholder: '搜索水果...' })
        .width('100%')
        .height(45)
        .enterKeyType(EnterKeyType.Search)
        .onChange((value: string) => {
          this.searchText = value
          this.performSearch(value)
        })

      if (this.searchResults.length > 0) {
        Column({ space: 8 }) {
          ForEach(this.searchResults, (item: string) => {
            Text(item)
              .width('100%')
              .padding(12)
              .backgroundColor('#F5F5F5')
              .borderRadius(8)
          })
        }
        .width('100%')
      } else if (this.searchText.length > 0) {
        Text('未找到相关结果')
          .fontSize(14)
          .fontColor('#999999')
      }
    }
    .width('100%')
    .padding(16)
  }
}
```

## 五、最佳实践

### 5.1 占位符设计

```typescript
// ✅ 推荐：使用清晰的占位符
TextInput({ placeholder: '请输入手机号' })

// ❌ 避免：占位符过于简单或模糊
TextInput({ placeholder: '输入' })
TextInput({ placeholder: '请输入' })
```

### 5.2 输入长度限制

```typescript
// ✅ 推荐：设置合理的 maxLength
TextInput({ placeholder: '手机号' })
  .maxLength(11)  // 中国手机号11位

// ❌ 避免：不限制长度可能导致溢出
TextInput({ placeholder: '手机号' })
```

### 5.3 密码安全

```typescript
// ✅ 推荐：密码输入框默认隐藏密码
TextInput({ placeholder: '密码' })
  .type(InputType.Password)
  .showPassword(false)  // 默认隐藏

// ❌ 避免：默认显示密码
TextInput({ placeholder: '密码' })
  .type(InputType.Password)
  .showPassword(true)  // 不安全
```

### 5.4 输入类型匹配

```typescript
// ✅ 推荐：根据内容选择合适的输入类型
TextInput({ placeholder: '邮箱' }).type(InputType.Email)
TextInput({ placeholder: '手机号' }).type(InputType.Phone)
TextInput({ placeholder: '年龄' }).type(InputType.Number)

// ❌ 避免：全部使用普通类型
TextInput({ placeholder: '邮箱' }).type(InputType.Normal)
```

### 5.5 实时反馈

```typescript
// ✅ 推荐：提供实时验证反馈
@ComponentV2
struct GoodValidation {
  @Local isValid: boolean = true

  build() {
    TextInput({ placeholder: '邮箱' })
      .type(InputType.Email)
      .onChange((value: string) => {
        const regex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
        this.isValid = regex.test(value)
      })
      .border({ width: 2, color: this.isValid ? '#28A745' : '#FF0000' })
  }
}
```

## 六、常见问题

### Q1: TextInput 不显示光标？

**问题**: TextInput 无法输入，光标不显示。

**解决方案**:
```typescript
// 检查是否设置了 enabled(false)
TextInput({ placeholder: '请输入' })
  .enabled(true)  // 确保启用
```

### Q2: 如何限制只能输入数字？

**解决方案**:
```typescript
// 方案 1: 使用 Number 类型
TextInput({ placeholder: '数字' })
  .type(InputType.Number)

// 方案 2: 使用 onChange 过滤
TextInput({ placeholder: '数字' })
  .onChange((value: string) => {
    const numericValue = value.replace(/\D/g, '')
    if (value !== numericValue) {
      // 更新为过滤后的值
    }
  })
```

### Q3: 如何实现输入框的清空功能？

**解决方案**:
```typescript
@ComponentV2
struct ClearableInput {
  @Local textValue: string = ''
  textController: TextInputController = new TextInputController()

  build() {
    Row() {
      TextInput({ placeholder: '请输入', controller: this.textController })
        .layoutWeight(1)
        .onChange((value: string) => {
          this.textValue = value
        })

      if (this.textValue.length > 0) {
        Button('×')
          .onClick(() => {
            this.textController.clear()
            this.textValue = ''
          })
      }
    }
  }
}
```

### Q4: TextInput 如何获得初始焦点？

**解决方案**:
```typescript
@ComponentV2
struct AutoFocusExample {
  textController: TextInputController = new TextInputController()

  aboutToAppear(): void {
    // 组件即将出现时请求焦点
    setTimeout(() => {
      this.textController.requestFocus()
    }, 100)
  }

  build() {
    TextInput({ controller: this.textController })
  }
}
```

### Q5: 如何监听输入框的复制、粘贴操作？

**解决方案**:
```typescript
TextInput({ placeholder: '请输入' })
  .onCopy((value: string) => {
    console.info('复制文本: ' + value)
  })
  .onCut((value: string) => {
    console.info('剪切文本: ' + value)
  })
  .onPaste((value: string) => {
    console.info('粘贴文本: ' + value)
  })
```

### Q6: 如何自定义键盘的回车键？

**解决方案**:
```typescript
// 设置回车键类型
TextInput({ placeholder: '搜索' })
  .enterKeyType(EnterKeyType.Search)
  .onSubmit((enterKey: EnterKeyType) => {
    if (enterKey === EnterKeyType.Search) {
      console.info('执行搜索')
    }
  })
```

## 七、版本兼容性

| API 版本 | 支持状态 | 备注 |
|----------|----------|------|
| API 9+ | ✅ | 完全支持 |
| API 10+ | ✅ | 增加了 searchBar 等属性 |
| API 11+ | ✅ | 增加了 showPassword 等属性 |
| API 12+ | ✅ | 优化了键盘行为和输入体验 |

## 八、参考资料

- [TextInput 输入框 - 华为开发者官方文档](https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V5/ts-basic-components-textinput-V5)
- [通用属性 - 华为开发者](https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V5/ts-universal-attributes-size-V5)
- [TextInput 实例 - 华为开发者社区](https://developer.huawei.com/consumer/cn/doc/harmonyos-samples-V5/textinput-component-V5)
