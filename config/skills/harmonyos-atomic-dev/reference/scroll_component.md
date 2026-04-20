# Scroll Components

### Scroll - Single Direction Scroll

```typescript
@ComponentV2
struct ScrollDemo {
  @Local scroller: Scroller = new Scroller();
  @Local scrollOffset: number = 0;

  build() {
    Column() {
      Scroll(this.scroller) {
        Column() {
          ForEach(Array.from({ length: 50 }, (_, i) => i), (item: number) => {
            Text(`Item ${item}`)
              .width('100%')
              .height(80)
              .backgroundColor(item % 2 === 0 ? '#F5F5F5' : '#FFFFFF')
              .textAlign(TextAlign.Center)
          })
        }
        .width('100%')
      }
      .scrollable(ScrollDirection.Vertical)
      .scrollBar(BarState.Auto)
      .edgeEffect(EdgeEffect.Spring)
      .onScroll((xOffset: number, yOffset: number) => {
        this.scrollOffset = yOffset;
      })
      .onScrollEdge((side: Edge) => {
        if (side === Edge.Bottom) {
          console.info('Scrolled to bottom');
        }
      })

      // Scroll to top button
      if (this.scrollOffset > 500) {
        Button('Top')
          .position({ x: '80%', y: '85%' })
          .onClick(() => {
            this.scroller.scrollToIndex(0);
          })
      }
    }
    .width('100%')
    .height('100%')
  }
}
```

### Grid - Two-dimensional Layout

```typescript
@ComponentV2
struct GridDemo {
  @Local columnsNum: number = 3;

  @Computed
  get columnsTemplate(): string {
    return `1fr `.repeat(this.columnsNum).trim();
  }

  build() {
    Grid() {
      ForEach(this.products, (product: Product) => {
        GridItem() {
          ProductCard({ product: product })
        }
      }, (product: Product) => product.id)
    }
    .columnsTemplate(this.columnsTemplate)  // '1fr 1fr 1fr'
    .rowsTemplate('1fr 1fr')
    .rowsGap(12)
    .columnsGap(12)
    .width('100%')
    .height('100%')
    .padding(12)
  }
}

// Responsive Grid with breakpoints
@ComponentV2
struct ResponsiveGrid {
  @StorageProp('currentBreakpoint') breakpoint: string = 'sm';

  @Computed
  get columnsTemplate(): string {
    switch (this.breakpoint) {
      case 'sm':
        return '1fr 1fr';
      case 'md':
        return '1fr 1fr 1fr';
      case 'lg':
        return '1fr 1fr 1fr 1fr';
      default:
        return '1fr 1fr';
    }
  }

  build() {
    Grid() {
      ForEach(this.items, (item: Item) => {
        GridItem() {
          ItemCard({ item: item })
        }
      }, (item: Item) => item.id)
    }
    .columnsTemplate(this.columnsTemplate)
    .columnsGap(8)
    .rowsGap(8)
  }
}
```

### List - Vertical List

```typescript
@ComponentV2
struct ListDemo {
  @Local dataSource: BasicDataSource<Item> = new BasicDataSource();

  aboutToAppear(): void {
    this.loadData();
  }

  private loadData(): void {
    const items = Array.from({ length: 100 }, (_, i) => ({
      id: `${i}`,
      name: `Item ${i}`
    }));
    this.dataSource.setData(items);
  }

  build() {
    List() {
      LazyForEach(this.dataSource, (item: Item) => {
        ListItem() {
          Row() {
            Text(item.name)
              .fontSize(16)
            Blank()
            Image($r('app.media.arrow_right'))
              .width(16)
              .height(16)
          }
          .width('100%')
          .padding(16)
          .backgroundColor(Color.White)
          .borderRadius(8)
          .onClick(() => {
            console.info(`Clicked ${item.name}`);
          })
        }
      }, (item: Item) => item.id)
    }
    .width('100%')
    .height('100%')
    .divider({
      strokeWidth: 1,
      color: '#E8E8E8',
      startMargin: 16,
      endMargin: 16
    })
    .cachedCount(10)  // Cache 10 items for smooth scrolling
    .edgeEffect(EdgeEffect.Spring)
  }
}
```

### WaterFlow - Waterfall Layout

```typescript
@ComponentV2
struct WaterFlowDemo {
  @Local scroller: Scroller = new Scroller();

  build() {
    WaterFlow({ scroller: this.scroller }) {
      ForEach(this.images, (image: ImageData) => {
        FlowItem() {
          Image(image.url)
            .width('100%')
            .objectFit(ImageFit.Cover)
            .borderRadius(8)
        }
        .width('48%')
        .height(image.height * 1.5)  // Dynamic height
        .margin({ bottom: 8 })
      }, (image: ImageData) => image.id)
    }
    .columnsTemplate('1fr 1fr')
    .columnsGap(8)
    .rowsGap(8)
    .width('100%')
    .height('100%')
    .padding(8)
    .backgroundColor('#F5F5F5')
  }
}
```

### Swiper - Carousel

```typescript
@ComponentV2
struct SwiperDemo {
  @Local currentIndex: number = 0;
  @Local swiperController: SwiperController = new SwiperController();

  build() {
    Column() {
      Swiper(this.swiperController) {
        ForEach(this.banners, (banner: Banner) => {
          Image(banner.imageUrl)
            .width('100%')
            .height(200)
            .objectFit(ImageFit.Cover)
            .borderRadius(12)
            .onClick(() => {
              console.info(`Banner ${banner.id} clicked`);
            })
        }, (banner: Banner) => banner.id)
      }
      .loop(true)
      .autoPlay(true)
      .interval(3000)
      .indicator(true)  // Show indicator dots
      .indicatorStyle({
        color: '#E0E0E0',
        selectedColor: '#007AFF'
      })
      .duration(300)  // Animation duration
      .curve(Curve.EaseInOut)
      .onChange((index: number) => {
        this.currentIndex = index;
      })

      // Custom indicator
      Row({ space: 8 }) {
        ForEach(this.banners, (banner: Banner, index: number) => {
          Circle()
            .width(8)
            .height(8)
            .fill(this.currentIndex === index ? '#007AFF' : '#E0E0E0')
        }, (banner: Banner, index: number) => `${banner.id}_${index}`)
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .margin({ top: 16 })
    }
    .padding(16)
  }
}
```
