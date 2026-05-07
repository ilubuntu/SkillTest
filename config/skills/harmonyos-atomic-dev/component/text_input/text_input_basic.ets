/**
 * text_input_basic — TextInput 基础输入类型
 * 展示 TextInput 各输入类型：Normal / Number / PhoneNumber / Email / NUMBER_DECIMAL
 * 元服务兼容性：TextInput API 7+，InputType.Normal/Number/PhoneNumber/Email/NUMBER_DECIMAL 元服务 API 11+ 可用
 */

@ComponentV2
export struct TextInputBasic {
  @Local resultText: string = '等待输入...'
  @Local normalText: string = ''
  @Local numberText: string = ''
  @Local phoneText: string = ''
  @Local emailText: string = ''
  @Local decimalText: string = ''

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('TextInput 基础输入类型')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20, bottom: 10 })

        // 结果展示区
        Column() {
          Text(this.resultText)
            .fontSize(14)
            .fontColor('#333333')
            .width('100%')
            .padding(12)
        }
        .width('90%')
        .backgroundColor('#F5F5F5')
        .borderRadius(8)

        // Normal 基本输入
        Text('Normal — 基本输入模式')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        TextInput({ placeholder: '请输入任意内容...', text: this.normalText })
          .type(InputType.Normal)
          .width('90%')
          .height(48)
          .onChange((value: string) => {
            try {
              this.normalText = value
              this.resultText = `[Normal] 输入: "${value}"\n长度: ${value.length}`
            } catch (e) {
              this.resultText = `onChange 异常: ${(e as Error).message}`
            }
          })

        // Number 数字输入
        Text('Number — 纯数字输入')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        TextInput({ placeholder: '请输入纯数字...', text: this.numberText })
          .type(InputType.Number)
          .width('90%')
          .height(48)
          .onChange((value: string) => {
            try {
              this.numberText = value
              this.resultText = `[Number] 输入: "${value}"`
            } catch (e) {
              this.resultText = `onChange 异常: ${(e as Error).message}`
            }
          })

        // PhoneNumber 电话号码
        Text('PhoneNumber — 电话号码')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        TextInput({ placeholder: '请输入电话号码...', text: this.phoneText })
          .type(InputType.PhoneNumber)
          .width('90%')
          .height(48)
          .onChange((value: string) => {
            try {
              this.phoneText = value
              this.resultText = `[PhoneNumber] 输入: "${value}"`
            } catch (e) {
              this.resultText = `onChange 异常: ${(e as Error).message}`
            }
          })

        // Email 邮箱
        Text('Email — 邮箱地址')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        TextInput({ placeholder: '请输入邮箱地址...', text: this.emailText })
          .type(InputType.Email)
          .width('90%')
          .height(48)
          .onChange((value: string) => {
            try {
              this.emailText = value
              this.resultText = `[Email] 输入: "${value}"`
            } catch (e) {
              this.resultText = `onChange 异常: ${(e as Error).message}`
            }
          })

        // NUMBER_DECIMAL 带小数点数字
        Text('NUMBER_DECIMAL — 带小数点数字')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        TextInput({ placeholder: '请输入数字(支持小数点)...', text: this.decimalText })
          .type(InputType.NUMBER_DECIMAL)
          .width('90%')
          .height(48)
          .onChange((value: string) => {
            try {
              this.decimalText = value
              this.resultText = `[NUMBER_DECIMAL] 输入: "${value}"`
            } catch (e) {
              this.resultText = `onChange 异常: ${(e as Error).message}`
            }
          })

        // 操作按钮
        Row({ space: 8 }) {
          Button('清空全部')
            .fontSize(13)
            .layoutWeight(1)
            .height(36)
            .onClick(() => {
              this.normalText = ''
              this.numberText = ''
              this.phoneText = ''
              this.emailText = ''
              this.decimalText = ''
              this.resultText = '已清空全部输入'
            })
          Button('查看汇总')
            .fontSize(13)
            .layoutWeight(1)
            .height(36)
            .onClick(() => {
              this.resultText =
                `Normal: "${this.normalText}"\nNumber: "${this.numberText}"\nPhone: "${this.phoneText}"\nEmail: "${this.emailText}"\nDecimal: "${this.decimalText}"`
            })
        }
        .width('90%')

        // API 说明区
        Column() {
          Text('API 说明')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 8 })
          Text('TextInput(value?: TextInputOptions)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('type(InputType): 设置输入框类型，不同类型拉起对应键盘')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('InputType.Normal(0) / Number(2) / PhoneNumber(3) / Email(5) / NUMBER_DECIMAL(12)')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('元服务：InputType.Normal/Number/PhoneNumber/Email/NUMBER_DECIMAL 从 API 11+ 可用')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('注意：Password / NUMBER_PASSWORD / USER_NAME / NEW_PASSWORD 需 API 12+，见密码输入场景')
            .fontSize(12)
            .fontColor('#FF6B00')
            .width('100%')
        }
        .width('90%')
        .backgroundColor('#FFF9E6')
        .borderRadius(8)
        .padding(12)
        .margin({ top: 8, bottom: 20 })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
  }
}
