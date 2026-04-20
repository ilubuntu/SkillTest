# Tabs Component

### Tabs

```typescript
@ComponentV2
struct TabsDemo {
  @Local currentIndex: number = 0;
  @Local tabController: TabsController = new TabsController();

  @Builder
  TabBuilder(title: string, targetIndex: number, icon: Resource) {
    Column() {
      Image(icon)
        .width(24)
        .height(24)
        .opacity(this.currentIndex === targetIndex ? 1 : 0.6)
      Text(title)
        .fontSize(12)
        .fontColor(this.currentIndex === targetIndex ? '#007AFF' : '#8E8E93')
        .fontWeight(this.currentIndex === targetIndex ? FontWeight.Medium : FontWeight.Normal)
        .margin({ top: 4 })
    }
    .width('100%')
    .height(56)
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      this.currentIndex = targetIndex;
      this.tabController.changeIndex(targetIndex);
    })
  }

  build() {
    Tabs({ barPosition: BarPosition.End, controller: this.tabController }) {
      TabContent() {
        HomePage()
      }
      .tabBar(this.TabBuilder('Home', 0, $r('app.media.home')))

      TabContent() {
        DiscoverPage()
      }
      .tabBar(this.TabBuilder('Discover', 1, $r('app.media.discover')))

      TabContent() {
        ProfilePage()
      }
      .tabBar(this.TabBuilder('Profile', 2, $r('app.media.profile')))
    }
    .barMode(BarMode.Fixed)  // or BarMode.Scrollable
    .barHeight(56)
    .animationDuration(300)
    .onChange((index: number) => {
      this.currentIndex = index;
    })
  }
}
```
