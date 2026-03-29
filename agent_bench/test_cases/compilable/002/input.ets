// ArkTS Form表单可编译参考实现
@Entry
@Component
struct LoginForm {
  @State username: string = ''
  @State password: string = ''
  @State isSubmitting: boolean = false

  build() {
    Column() {
      Text('Login')
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .margin(20)

      TextInput({ placeholder: 'Username' })
        .width('80%')
        .height(40)
        .margin(10)
        .onChange((value: string) => {
          this.username = value
        })

      TextInput({ placeholder: 'Password' })
        .type(InputType.Password)
        .width('80%')
        .height(40)
        .margin(10)
        .onChange((value: string) => {
          this.password = value
        })

      Button('Submit')
        .width('80%')
        .height(40)
        .margin(20)
        .enabled(!this.isSubmitting)
        .onClick(() => {
          this.isSubmitting = true
          console.info('Form submitted: ' + this.username)
        })
    }
    .width('100%')
    .height('100%')
  }
}
