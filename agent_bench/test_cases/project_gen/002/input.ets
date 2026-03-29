// ArkTS Navigation路由参考实现
@Entry
@Component
struct Index {
  build() {
    Navigation() {
      Column() {
        Text('Home Page')
          .fontSize(24)
          .margin(10)

        Button('Go to Detail')
          .onClick(() => {
            router.pushUrl({ url: 'pages/Detail' })
          })

        Button('Go to Settings')
          .onClick(() => {
            router.pushUrl({ url: 'pages/Settings' })
          })
      }
    }
    .title('Main Navigation')
    .width('100%')
    .height('100%')
  }
}
