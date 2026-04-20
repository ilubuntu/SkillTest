# TextArea 组件 HarmonyOS 6.0 开发 Skill

## 概述

TextArea 组件是 OpenHarmony 中用于多行文本输入的组件。它是 TextInput 的多行版本，支持自动换行、高度自适应、滚动等特性。TextArea 广泛应用于评论输入、消息发送、长文本编辑等场景。

## 重要说明

- **基础组件**: TextArea 是 ArkUI 的基础内置组件，无需导入
- **多行输入**: TextArea 专用于多行文本输入，单行输入请使用 TextInput
- **高度自适应**: 支持 auto-height 模式，根据内容自动调整高度
- **滚动支持**: 当内容超出可视区域时自动显示滚动条
- **文本限制**: 支持通过 maxLength 限制输入字符数

## 模块信息

- **组件名称**: TextArea
- **SDK 版本**: HarmonyOS 6.0 (API 12+)
- **系统能力**: SystemCapability.ArkUI.ArkUI.Full
- **更新日期**: 2026-02-24
- **官方文档**:
  - [TextArea 多行文本输入 - 华为开发者](https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V5/ts-basic-components-textarea-V5)

## 一、组件基础

### 1.1 导入方式

```typescript
// TextArea 是内置组件，无需导入
// 直接使用即可
TextArea({ placeholder: '请输入多行文本' })
```

### 1.2 基础用法

```typescript
// 简单多行输入
TextArea({ placeholder: '请输入内容' })

// 设置默认文本
TextArea({ text: '默认的多行内容\n支持换行' })

// 设置高度和宽度
TextArea({ placeholder: '请输入评论' })
  .width('100%')
  .height(120)

// 限制输入长度
TextArea({ placeholder: '最多输入200个字符' })
  .maxLength(200)
```

## 二、API 参数

### 2.1 构造参数

| 参数 | 类型 | 必填 | 默认值 | 描述 |
|------|------|------|--------|------|
| placeholder | `string \| Resource` | 否 | - | 占位符文本 |
| text | `string \| Resource` | 否 | - | 输入框的当前文本内容 |
| controller | `TextAreaController` | 否 | - | 文本输入控制器 |

### 2.2 常用属性

| 属性 | 类型 | 默认值 | 描述 |
|------|------|--------|------|
| `placeholder` | `string \| Resource` | - | 设置占位符内容 |
| `placeholderColor` | `ResourceColor` | '#999999' | 占位符文本颜色 |
| `placeholderFont` | `Font` | - | 占位符字体样式 |
| `textAlign` | `TextAlign` | TextAlign.Start | 文本水平对齐方式 |
| `caretColor` | `ResourceColor` | - | 光标颜色 |
| `selectedBackgroundColor` | `ResourceColor` | - | 选中文本背景色 |
| `barState` | `BarState` | BarState.Auto | 滚动条状态 |
| `enableKeyboardOnFocus` | `boolean` | true | 获得焦点时是否自动弹出键盘 |

### 2.3 高度自适应属性

| 属性 | 类型 | 默认值 | 描述 |
|------|------|--------|------|
| `height` | `number \| string \| Resource` | - | 设置固定高度 |
| `type` | `TextAreaType` | TextAreaType.Normal | 设置为 AutoSize 实现高度自适应 |

### 2.4 样式属性

| 属性 | 类型 | 默认值 | 描述 |
|------|------|--------|------|
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

### 2.6 事件

| 事件 | 类型 | 描述 |
|------|------|------|
| `onChange` | `(value: string) => void` | 输入内容变化时触发 |
| `onEditChanged` | `(isEditing: boolean) => void` | 输入状态变化时触发 |
| `onFocus` | `() => void` | 获得焦点时触发 |
| `onBlur` | `() => void` | 失去焦点时触发 |
| `onCopy` | `(value: string) => void` | 复制文本时触发 |
| `onCut` | `(value: string) => void` | 剪切文本时触发 |
| `onPaste` | `(value: string) => void` | 粘贴文本时触发 |
| `onTextSelectionChange` | `(selectionStart: number, selectionEnd: number) => void` | 文本选择变化时触发 |

## 三、使用示例

### 3.1 基础多行输入

```typescript
@ComponentV2
struct BasicTextAreaExample {
  @Local textValue: string = ''

  build() {
    Column({ space: 16 }) {
      Text('基础多行输入')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)

      TextArea({ placeholder: '请输入多行内容...' })
        .width('100%')
        .height(120)
        .onChange((value: string) => {
          this.textValue = value
          console.info('输入内容: ' + value)
        })

      Text(`字符数: ${this.textValue.length}`)
        .fontSize(14)
        .fontColor('#666666')
    }
    .width('100%')
    .padding(16)
  }
}
```

### 3.2 自动高度

```typescript
@ComponentV2
struct AutoHeightExample {
  @Local textValue: string = ''

  build() {
    Column({ space: 16 }) {
      Text('自动高度')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)

      TextArea({ placeholder: '输入内容会自动调整高度...' })
        .width('100%')
        .type(TextAreaType.AutoSize)
        .onChange((value: string) => {
          this.textValue = value
        })

      Text('随着内容增加，输入框会自动增高')
        .fontSize(12)
        .fontColor('#999999')
    }
    .width('100%')
    .padding(16)
  }
}
```

### 3.3 限制字符数

```typescript
@ComponentV2
struct LimitedTextAreaExample {
  @Local textValue: string = ''
  readonly maxLength: number = 200

  build() {
    Column({ space: 16 }) {
      Text('限制字符数')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)

      TextArea({ placeholder: '请输入评论（最多200字）...' })
        .width('100%')
        .height(120)
        .maxLength(this.maxLength)
        .onChange((value: string) => {
          this.textValue = value
        })

      Row() {
        Spacer()
        Text(`${this.textValue.length}/${this.maxLength}`)
          .fontSize(12)
          .fontColor('#999999')
      }
      .width('100%')
    }
    .width('100%')
    .padding(16)
  }
}
```

### 3.4 自定义样式

```typescript
@ComponentV2
struct StyledTextAreaExample {
  @Local comment: string = ''

  build() {
    Column({ space: 16 }) {
      Text('自定义样式')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)

      // 圆角边框样式
      TextArea({ placeholder: '圆角样式的输入框...' })
        .width('100%')
        .height(100)
        .backgroundColor('#F9F9F9')
        .borderRadius(12)
        .padding(12)

      // 带边框样式
      TextArea({ placeholder: '带边框的输入框...' })
        .width('100%')
        .height(100)
        .border({ width: 2, color: '#007DFF', radius: 8 })
        .padding(12)

      // 阴影效果
      TextArea({ placeholder: '带阴影的输入框...' })
        .width('100%')
        .height(100)
        .backgroundColor('#FFFFFF')
        .borderRadius(8)
        .shadow({ radius: 8, color: '#1F000000', offsetX: 0, offsetY: 2 })
    }
    .width('100%')
    .padding(16)
  }
}
```

### 3.5 文本对齐

```typescript
@ComponentV2
struct TextAlignExample {
  @Local leftText: string = ''
  @Local centerText: string = ''
  @Local rightText: string = ''

  build() {
    Column({ space: 16 }) {
      Text('文本对齐')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)

      // 左对齐
      TextArea({ placeholder: '左对齐文本...' })
        .width('100%')
        .height(80)
        .textAlign(TextAlign.Start)
        .onChange((value: string) => {
          this.leftText = value
        })

      // 居中对齐
      TextArea({ placeholder: '居中对齐文本...' })
        .width('100%')
        .height(80)
        .textAlign(TextAlign.Center)
        .onChange((value: string) => {
          this.centerText = value
        })

      // 右对齐
      TextArea({ placeholder: '右对齐文本...' })
        .width('100%')
        .height(80)
        .textAlign(TextAlign.End)
        .onChange((value: string) => {
          this.rightText = value
        })
    }
    .width('100%')
    .padding(16)
  }
}
```

### 3.6 评论输入框

```typescript
@ComponentV2
struct CommentBoxExample {
  @Local comment: string = ''
  @Local isSubmitting: boolean = false

  submitComment(): void {
    if (!this.comment.trim()) {
      console.info('评论内容不能为空')
      return
    }

    this.isSubmitting = true
    // 模拟提交
    setTimeout(() => {
      console.info('评论已提交: ' + this.comment)
      this.comment = ''
      this.isSubmitting = false
    }, 1000)
  }

  build() {
    Column({ space: 16 }) {
      Text('评论输入框')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)

      Column({ space: 8 }) {
        TextArea({ placeholder: '写下你的评论...' })
          .width('100%')
          .height(100)
          .maxLength(500)
          .padding(12)
          .borderRadius(8)
          .backgroundColor('#F5F5F5')
          .onChange((value: string) => {
            this.comment = value
          })

        Row() {
          Text(`${this.comment.length}/500`)
            .fontSize(12)
            .fontColor('#999999')

          Spacer()

          Button('发布')
            .enabled(this.comment.trim().length > 0 && !this.isSubmitting)
            .backgroundColor(this.comment.trim().length > 0 ? '#007DFF' : '#CCCCCC')
            .onClick(() => {
              this.submitComment()
            })
        }
        .width('100%')
      }
    }
    .width('100%')
    .padding(16)
  }
}
```

### 3.7 消息发送框

```typescript
@ComponentV2
struct MessageInputExample {
  @Local message: string = ''

  sendMessage(): void {
    if (!this.message.trim()) {
      return
    }

    console.info('发送消息: ' + this.message)
    this.message = ''
  }

  build() {
    Column({ space: 16 }) {
      Text('消息发送框')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)

      Row({ space: 8 }) {
        TextArea({ placeholder: '输入消息...' })
          .layoutWeight(1)
          .height(40)
          .type(TextAreaType.AutoSize)
          .maxLines(4)
          .onChange((value: string) => {
            this.message = value
          })

        Button('发送')
          .height(40)
          .backgroundColor('#007DFF')
          .enabled(this.message.trim().length > 0)
          .onClick(() => {
            this.sendMessage()
          })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .padding(16)
  }
}
```

### 3.8 获得焦点和失去焦点

```typescript
@ComponentV2
struct TextAreaFocusExample {
  @Local textValue: string = ''
  @Local isFocused: boolean = false

  build() {
    Column({ space: 16 }) {
      Text('焦点控制')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)

      TextArea({ placeholder: '点击输入' })
        .width('100%')
        .height(100)
        .border({
          width: 2,
          color: this.isFocused ? '#007DFF' : '#E0E0E0',
          radius: 8
        })
        .backgroundColor(this.isFocused ? '#F0F8FF' : Color.Transparent)
        .padding(12)
        .onFocus(() => {
          this.isFocused = true
          console.info('获得焦点')
        })
        .onBlur(() => {
          this.isFocused = false
          console.info('失去焦点')
        })
        .onChange((value: string) => {
          this.textValue = value
        })

      Text('输入框状态: ' + (this.isFocused ? '聚焦' : '未聚焦'))
        .fontSize(14)
        .fontColor('#666666')
    }
    .width('100%')
    .padding(16)
  }
}
```

### 3.9 使用控制器

```typescript
@ComponentV2
struct TextAreaControllerExample {
  textAreaController: TextAreaController = new TextAreaController()
  @Local textValue: string = ''

  build() {
    Column({ space: 16 }) {
      Text('使用控制器')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)

      TextArea({
        placeholder: '请输入内容',
        controller: this.textAreaController
      })
        .width('100%')
        .height(100)
        .onChange((value: string) => {
          this.textValue = value
        })

      Row({ space: 12 }) {
        Button('清空')
          .onClick(() => {
            this.textAreaController.clear()
            this.textValue = ''
          })

        Button('获取焦点')
          .onClick(() => {
            this.textAreaController.requestFocus()
          })

        Button('失去焦点')
          .onClick(() => {
            this.textAreaController.stopEditing()
          })
      }
    }
    .width('100%')
    .padding(16)
  }
}
```

### 3.10 文本选择监听

```typescript
@ComponentV2
struct TextSelectionExample {
  @Local textValue: string = '这是一段可以选中的文本内容'
  @Local selectionInfo: string = '未选择文本'

  build() {
    Column({ space: 16 }) {
      Text('文本选择监听')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)

      TextArea({ text: this.textValue })
        .width('100%')
        .height(100)
        .onTextSelectionChange((start: number, end: number) => {
          if (start === end) {
            this.selectionInfo = '光标位置: ' + start
          } else {
            const selectedText = this.textValue.substring(start, end)
            this.selectionInfo = `已选择: ${selectedText} (${start}-${end})`
          }
        })

      Text(this.selectionInfo)
        .fontSize(14)
        .fontColor('#666666')
    }
    .width('100%')
    .padding(16)
  }
}
```

## 四、高级用法

### 4.1 带字数统计的评论框

```typescript
@ComponentV2
struct AdvancedCommentBox {
  @Local comment: string = ''
  readonly maxLength: number = 500
  textAreaController: TextAreaController = new TextAreaController()

  getRemainingChars(): number {
    return this.maxLength - this.comment.length
  }

  getColor(): string {
    const remaining = this.getRemainingChars()
    if (remaining > 100) return '#999999'
    if (remaining > 20) return '#FFC107'
    return '#FF0000'
  }

  build() {
    Column({ space: 12 }) {
      Text('发表评论')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)

      TextArea({ placeholder: '分享你的想法...', controller: this.textAreaController })
        .width('100%')
        .height(120)
        .maxLength(this.maxLength)
        .padding(12)
        .borderRadius(8)
        .border({ width: 1, color: '#E0E0E0' })
        .onChange((value: string) => {
          this.comment = value
        })

      Row() {
        Text(`还可以输入 ${this.getRemainingChars()} 字`)
          .fontSize(12)
          .fontColor(this.getColor())

        Spacer()

        Row({ space: 8 }) {
          Button('取消')
            .backgroundColor('#F5F5F5')
            .fontColor('#666666')
            .onClick(() => {
              this.comment = ''
              this.textAreaController.clear()
            })

          Button('发布')
            .backgroundColor('#007DFF')
            .enabled(this.comment.trim().length > 0)
            .onClick(() => {
              console.info('发布评论: ' + this.comment)
              this.comment = ''
              this.textAreaController.clear()
            })
        }
      }
      .width('100%')
    }
    .width('100%')
    .padding(16)
  }
}
```

### 4.2 实时字符统计

```typescript
@ComponentV2
struct CharCounterExample {
  @Local textValue: string = ''

  getCharCount(): number {
    return this.textValue.length
  }

  getLineCount(): number {
    return this.textValue.split('\n').length
  }

  getWordCount(): number {
    return this.textValue.trim().split(/\s+/).filter(w => w.length > 0).length
  }

  build() {
    Column({ space: 16 }) {
      Text('实时字符统计')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)

      TextArea({ placeholder: '开始输入...' })
        .width('100%')
        .height(150)
        .onChange((value: string) => {
          this.textValue = value
        })

      Row({ space: 20 }) {
        Column({ space: 4 }) {
          Text(this.getCharCount().toString())
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
          Text('字符数')
            .fontSize(12)
            .fontColor('#999999')
        }

        Column({ space: 4 }) {
          Text(this.getLineCount().toString())
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
          Text('行数')
            .fontSize(12)
            .fontColor('#999999')
        }

        Column({ space: 4 }) {
          Text(this.getWordCount().toString())
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
          Text('词数')
            .fontSize(12)
            .fontColor('#999999')
        }
      }
      .width('100%')
      .padding(16)
      .backgroundColor('#F5F5F5')
      .borderRadius(8)
    }
    .width('100%')
    .padding(16)
  }
}
```

### 4.3 富文本编辑器基础

```typescript
@ComponentV2
struct RichTextEditorExample {
  @Local content: string = ''
  @Local cursorPosition: number = 0

  insertText(text: string): void {
    const before = this.content.substring(0, this.cursorPosition)
    const after = this.content.substring(this.cursorPosition)
    this.content = before + text + after
    this.cursorPosition += text.length
  }

  build() {
    Column({ space: 16 }) {
      Text('富文本编辑器（基础）')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)

      // 工具栏
      Row({ space: 8 }) {
        Button('B')
          .width(40)
          .height(40)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)

        Button('I')
          .width(40)
          .height(40)
          .fontSize(18)
          .fontStyle(FontStyle.Italic)

        Button('U')
          .width(40)
          .height(40)
          .fontSize(18)
          .decoration({ type: TextDecorationType.Underline })

        Button('📷')
          .width(40)
          .height(40)
      }
      .width('100%')

      TextArea({ placeholder: '开始编辑...' })
        .width('100%')
        .height(200)
        .padding(12)
        .borderRadius(8)
        .border({ width: 1, color: '#E0E0E0' })
        .onChange((value: string) => {
          this.content = value
        })
    }
    .width('100%')
    .padding(16)
  }
}
```

## 五、最佳实践

### 5.1 高度设置

```typescript
// ✅ 推荐：根据场景设置合适的高度
TextArea({ placeholder: '评论' }).height(100)   // 短评
TextArea({ placeholder: '文章' }).height(200)   // 长文

// ❌ 避免：高度设置不当
TextArea({ placeholder: '评论' }).height(40)   // 太小，体验差
TextArea({ placeholder: '评论' }).height(500)  // 太大，浪费空间
```

### 5.2 字符限制

```typescript
// ✅ 推荐：明确告知用户字符限制
@ComponentV2
struct GoodLimit {
  @Local text: string = ''
  readonly maxLen: number = 200

  build() {
    Column({ space: 8 }) {
      TextArea({ placeholder: '请输入' })
        .maxLength(this.maxLen)
        .onChange((v) => { this.text = v })

      Text(`${this.text.length}/${this.maxLen}`)
        .fontSize(12)
    }
  }
}
```

### 5.3 占位符提示

```typescript
// ✅ 推荐：提供清晰的占位符
TextArea({ placeholder: '请分享您的使用体验，帮助其他用户做出选择。' })

// ❌ 避免：占位符过于简单
TextArea({ placeholder: '请输入' })
```

### 5.4 用户体验

```typescript
// ✅ 推荐：提供清除和提交功能
@ComponentV2
struct GoodUX {
  @Local text: string = ''
  controller: TextAreaController = new TextAreaController()

  build() {
    Column({ space: 12 }) {
      TextArea({ controller: this.controller })
        .onChange((v) => { this.text = v })

      Row({ space: 12 }) {
        Button('清空')
          .onClick(() => {
            this.text = ''
            this.controller.clear()
          })

        Button('提交')
          .enabled(this.text.trim().length > 0)
      }
    }
  }
}
```

### 5.5 性能优化

```typescript
// ✅ 推荐：使用防抖处理频繁输入
@ComponentV2
struct DebouncedInput {
  @Local text: string = ''
  private timer: number = -1

  handleInput(value: string): void {
    this.text = value

    if (this.timer !== -1) {
      clearTimeout(this.timer)
    }

    this.timer = setTimeout(() => {
      console.info('保存内容: ' + value)
    }, 500)
  }

  build() {
    TextArea({ placeholder: '输入内容...' })
      .onChange((value) => this.handleInput(value))
  }
}
```

## 六、常见问题

### Q1: TextArea 如何实现自动高度？

**解决方案**:
```typescript
// 使用 AutoSize 类型
TextArea({ placeholder: '自动高度' })
  .width('100%')
  .type(TextAreaType.AutoSize)
```

### Q2: 如何限制 TextArea 的最大行数？

**解决方案**:
```typescript
// 配合 AutoSize 和 maxLines 使用
TextArea({ placeholder: '最多4行' })
  .width('100%')
  .type(TextAreaType.AutoSize)
  .maxLines(4)
```

### Q3: TextArea 如何显示滚动条？

**解决方案**:
```typescript
// 设置滚动条状态
TextArea({ placeholder: '内容' })
  .height(100)
  .barState(BarState.Auto)  // 自动显示
  // 或
  .barState(BarState.On)    // 始终显示
  // 或
  .barState(BarState.Off)   // 始终隐藏
```

### Q4: 如何在 TextArea 中插入文本？

**解决方案**:
```typescript
@ComponentV2
struct InsertTextExample {
  @Local content: string = ''
  controller: TextAreaController = new TextAreaController()

  insertAtCursor(textToInsert: string): void {
    // TextArea 不直接支持在光标位置插入
    // 需要手动处理文本内容
    this.content += textToInsert
  }

  build() {
    Column({ space: 12 }) {
      TextArea({ controller: this.controller })
        .onChange((v) => { this.content = v })

      Button('插入日期')
        .onClick(() => {
          this.insertAtCursor(new Date().toLocaleDateString())
        })
    }
  }
}
```

### Q5: 如何让 TextArea 初始时获得焦点？

**解决方案**:
```typescript
@ComponentV2
struct InitialFocusExample {
  controller: TextAreaController = new TextAreaController()

  aboutToAppear(): void {
    setTimeout(() => {
      this.controller.requestFocus()
    }, 100)
  }

  build() {
    TextArea({ controller: this.controller })
  }
}
```

### Q6: TextArea 能否实现富文本编辑？

**答案**: TextArea 本身不支持富文本编辑，只能处理纯文本。如需富文本功能，需要：
1. 使用 RichText 组件显示富文本
2. 使用 WebView 嵌入 HTML 编辑器
3. 自建基于 Text + Span 的编辑器（复杂）

## 七、版本兼容性

| API 版本 | 支持状态 | 备注 |
|----------|----------|------|
| API 9+ | ✅ | 完全支持 |
| API 10+ | ✅ | 增加了更多样式属性 |
| API 11+ | ✅ | 增加了 AutoSize 类型 |
| API 12+ | ✅ | 优化了滚动和键盘交互 |

## 八、参考资料

- [TextArea 多行文本输入 - 华为开发者官方文档](https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V5/ts-basic-components-textarea-V5)
- [通用属性 - 华为开发者](https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V5/ts-universal-attributes-size-V5)
- [TextArea 实例 - 华为开发者社区](https://developer.huawei.com/consumer/cn/doc/harmonyos-samples-V5/textarea-component-V5)
