/**
 * text_input_password — TextInput 密码输入模式
 * 展示 TextInput 密码相关：Password / NUMBER_PASSWORD / NEW_PASSWORD / showPasswordIcon / passwordIcon / showPassword
 * 元服务兼容性：Password 类型 API 11+，NUMBER_PASSWORD/USER_NAME/NEW_PASSWORD/enableAutoFill/showPassword 元服务 API 12+
 */

import { BusinessError } from '@kit.BasicServicesKit'

@ComponentV2
export struct TextInputPassword {
  @Local resultText: string = '选择密码类型进行输入体验'
  @Local passwordText: string = ''
  @Local numPwdText: string = ''
  @Local newPwdText: string = ''
  @Local userNameText: string = ''
  @Local showPwd: boolean = false
  @Local securityState: boolean = false

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('TextInput 密码输入模式')
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

        // Password 基本密码输入
        Text('Password — 密码输入 (API 11+)')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        TextInput({ placeholder: '请输入密码...', text: this.passwordText })
          .type(InputType.Password)
          .width('90%')
          .height(48)
          .showPasswordIcon(true)
          .onChange((value: string) => {
            try {
              this.passwordText = value
              this.resultText = `[Password] 长度: ${value.length} 字符\n（内容已隐藏）`
            } catch (e) {
              this.resultText = `onChange 异常: ${(e as Error).message}`
            }
          })

        // NUMBER_PASSWORD 纯数字密码
        Text('NUMBER_PASSWORD — 纯数字密码 (API 12+)')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        TextInput({ placeholder: '请输入数字密码...', text: this.numPwdText })
          .type(InputType.NUMBER_PASSWORD)
          .width('90%')
          .height(48)
          .showPasswordIcon(true)
          .onChange((value: string) => {
            try {
              this.numPwdText = value
              this.resultText = `[NUMBER_PASSWORD] 长度: ${value.length}`
            } catch (e) {
              this.resultText = `onChange 异常: ${(e as Error).message}`
            }
          })

        // NEW_PASSWORD 新密码
        Text('NEW_PASSWORD — 新密码 (API 12+)')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        TextInput({ placeholder: '请输入新密码...', text: this.newPwdText })
          .type(InputType.NEW_PASSWORD)
          .width('90%')
          .height(48)
          .showPasswordIcon(true)
          .passwordRules('required: upper; required: lower; required: digit; minlength: 8')
          .onChange((value: string) => {
            try {
              this.newPwdText = value
              this.resultText = `[NEW_PASSWORD] 长度: ${value.length}`
            } catch (e) {
              this.resultText = `onChange 异常: ${(e as Error).message}`
            }
          })

        // USER_NAME 用户名
        Text('USER_NAME — 用户名 (API 12+)')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        TextInput({ placeholder: '请输入用户名...', text: this.userNameText })
          .type(InputType.USER_NAME)
          .width('90%')
          .height(48)
          .onChange((value: string) => {
            try {
              this.userNameText = value
              this.resultText = `[USER_NAME] 输入: "${value}"`
            } catch (e) {
              this.resultText = `onChange 异常: ${(e as Error).message}`
            }
          })

        // showPassword 密码显隐控制
        Text('showPassword 显隐控制 (API 12+)')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Row({ space: 8 }) {
          Button(this.showPwd ? '隐藏密码' : '显示密码')
            .fontSize(13)
            .layoutWeight(1)
            .height(36)
            .backgroundColor(this.showPwd ? '#E53935' : '#4CAF50')
            .onClick(() => {
              this.showPwd = !this.showPwd
              this.resultText = `密码显示: ${this.showPwd ? '明文' : '密文'}`
            })
          Button(`安全状态: ${this.securityState ? '显示' : '隐藏'}`)
            .fontSize(12)
            .layoutWeight(1)
            .height(36)
            .onClick(() => {
              this.resultText = `当前安全状态: ${this.securityState}\n（通过 onSecurityStateChange 同步）`
            })
        }
        .width('90%')

        TextInput({ placeholder: '密码显隐切换...' })
          .type(InputType.Password)
          .width('90%')
          .height(48)
          .showPassword(this.showPwd)
          .onSecurityStateChange((isSecure: boolean) => {
            this.securityState = isSecure
            this.resultText = `[onSecurityStateChange] 密码安全状态: ${isSecure ? '隐藏' : '显示'}`
          })

        // 操作按钮
        Row({ space: 8 }) {
          Button('清空全部')
            .fontSize(13)
            .layoutWeight(1)
            .height(36)
            .onClick(() => {
              this.passwordText = ''
              this.numPwdText = ''
              this.newPwdText = ''
              this.userNameText = ''
              this.resultText = '已清空'
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
          Text('InputType.Password(7) — 密码输入，元服务 API 11+')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('InputType.NUMBER_PASSWORD(8) — 纯数字密码，元服务 API 12+')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('InputType.NEW_PASSWORD(11) — 新密码（支持密码保险箱），元服务 API 12+')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('InputType.USER_NAME(10) — 用户名（支持密码保险箱），元服务 API 12+')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('showPasswordIcon(boolean) — 密码模式末尾图标，默认 true')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('showPassword(boolean) — 控制密码显隐，默认 false，元服务 API 12+')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('passwordRules(string) — 生成密码规则，元服务 API 12+')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('onSecurityStateChange(callback) — 密码显隐状态变化回调，元服务 API 12+')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('注意：密码模式下 showUnderline 和 decoration 不生效')
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
