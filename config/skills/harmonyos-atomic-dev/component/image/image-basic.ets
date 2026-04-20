/**
 * image-basic — 图片来源场景
 * 资源引用、网络图片、Base64
 */
@ComponentV2
export struct ImageBasic {
  @Local message: string = '图片来源演示'

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text(this.message)
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20, bottom: 10 })

        // 1. 资源引用 $r()
        Text('1. 资源引用 $r()')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16 })
        Image($r('app.media.icon'))
          .width(120)
          .height(120)
          .interpolation(ImageInterpolation.High)

        // 2. 网络图片
        Text('2. 网络图片')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })
        Image('https://img1.baidu.com/it/u=1407750889,3441968730&fm=253&fmt=auto&app=138&f=JPEG')
          .width(200)
          .height(150)
          .alt($r('app.media.icon'))
          .onComplete(() => {
            this.message = '网络图片加载完成'
          })
          .onError(() => {
            this.message = '网络图片加载失败'
          })

        // 3. 资源引用 $r() — startIcon
        Text('3. 资源引用 startIcon')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })
        Image($r('app.media.startIcon'))
          .width(100)
          .height(100)

        // 4. Base64 图片
        Text('4. Base64 图片')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })
        Image('data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAA4AAAAOCAYAAAAfSC3RAAAACXBIWXMAAAsTAAALEwEAmpwYAAABhElEQVQoka2SMUvDUBSGn3YLJm0UEroLghikSgVRKEiEegmdOHgIigUFUOlp6CUUFJQ6dOnSg4eQikK0CKIoQfqDDh2CiIggCLoIq0CbCbZxN+00bH+Y5Z93lyTz4XIbd20YBIbAdnAdtIATkAHGD4x4P0Yggg+BWMg++AJ0pNjGSYBhMxF6p/FBOxqy2dXXd//x9VqOC/qc2b+XyOXyx1AqxX8C+4zmkWYD9gAlJfxzPAa7BPrDd1fPehp0dW28Wg5nN8NyED+oy3B5dlGNzkuNxQTYQdShtOAlk56WHv+7Mow/N2XR5OCBdXLF4Tr96WZYnuw5S2BK3+cpQGXAmPAF5AE7q3XL0XWV4egdfgCHAJs/kF2+YDH0v2j0I5AW4B1wDXoNSdUts/j0CHAG3AbvAYWqqo7fPpPh9YVQX8BDAK/AQUKq7q6LTsE/Aq8AadSqadl11qEfwGY8a9vD9e6zAAAAABJRU5ErkJggg==')
          .width(100)
          .height(100)
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
  }
}
