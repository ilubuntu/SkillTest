// ArkTS Swiper组件性能优化参考实现
@Entry
@Component
struct Index {
  @State currentIndex: number = 0
  private swiperItems: Array<Resource> = [
    $r('app.media.image1'),
    $r('app.media.image2'),
    $r('app.media.image3'),
    $r('app.media.image4'),
    $r('app.media.image5')
  ]

  build() {
    Swiper() {
      ForEach(this.swiperItems, (item: Resource) => {
        Image(item)
          .borderRadius(12)
          .objectFit(ImageFit.Cover)
      })
    }
    .autoPlay(true)
    .interval(3000)
    .indicator(new DotIndicator().selectedColor('#189AFFFF'))
    .cachedCount(2)
    .width('100%')
    .height('100%')
  }
}
