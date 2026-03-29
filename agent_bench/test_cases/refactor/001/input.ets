// 代码重构任务
// 以下代码实现了登录功能，但结构混乱，请进行重构使其更清晰易维护

@Entry
@Component
struct LoginPage {
  @State username: string = ''
  @State password: string = ''
  @State isLoading: boolean = false
  @State errorMsg: string = ''

  build() {
    Column() {
      TextInput({ placeholder: '请输入用户名' })
        .onChange((v) => { this.username = v })
      TextInput({ placeholder: '请输入密码' })
        .type(InputType.Password)
        .onChange((v) => { this.password = v })
      Button('登录')
        .enabled(!this.isLoading && this.username !== '' && this.password !== '')
        .onClick(() => {
          this.isLoading = true
          this.errorMsg = ''
          setTimeout(() => {
            if (this.username === 'admin' && this.password === '123') {
              console.info('登录成功')
            } else {
              this.errorMsg = '用户名或密码错误'
            }
            this.isLoading = false
          }, 1000)
        })
      if (this.errorMsg !== '') {
        Text(this.errorMsg).fontColor('#FF0000')
      }
    }
  }
}
