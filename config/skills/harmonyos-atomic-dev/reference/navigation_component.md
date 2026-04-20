# Navigation Component
```typescript
@Entry
@ComponentV2
struct NavigationDemo {
  @Local navPathStack: NavPathStack = new NavPathStack();

  @Builder
  PageBuilder(name: string, params: Object) {
    if (name === 'home') {
      HomePage()
    } else if (name === 'detail') {
      DetailPage({ params: params as DetailParams })
    } else if (name === 'settings') {
      SettingsPage()
    }
  }

  build() {
    Navigation(this.navPathStack) {
      Column() {
        Button('Go to Detail')
          .onClick(() => {
            this.navPathStack.pushPathByName('detail', { id: '123' });
          })

        Button('Go to Settings')
          .margin({ top: 12 })
          .onClick(() => {
            this.navPathStack.pushPathByName('settings', null);
          })

        Button('Back')
          .margin({ top: 12 })
          .onClick(() => {
            this.navPathStack.pop();
          })
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
    }
    .navDestination(this.PageBuilder)
    .title('Navigation Demo')
    .mode(NavigationMode.Stack)  // or NavigationMode.Single
  }
}

@ComponentV2
struct DetailPage {
  @Consumer('navPathStack') navPathStack: NavPathStack;
  @Param params: DetailParams = new DetailParams();

  build() {
    NavDestination() {
      Column() {
        Text(`Detail: ${this.params.id}`)
          .fontSize(24)
        Button('Back')
          .margin({ top: 24 })
          .onClick(() => {
            this.navPathStack.pop();
          })
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
    }
    .title('Detail Page')
    .hideBackButton(false)
  }
}
```

