/**
 * image-list — 列表中的图片场景
 * 列表图片、占位图、sourceSize 解码优化
 */
interface ImageItem {
  id: number
  title: string
}

@ComponentV2
export struct ImageList {
  @Local images: ImageItem[] = this.buildImageList()

  private buildImageList(): ImageItem[] {
    const list: ImageItem[] = []
    for (let i = 0; i < 15; i++) {
      list.push({ id: i, title: `图片 ${i + 1}` })
    }
    return list
  }

  build() {
    Column() {
      Text('列表图片懒加载')
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 10 })

      List({ space: 12 }) {
        ForEach(this.images, (item: ImageItem) => {
          ListItem() {
            Row({ space: 12 }) {
              Image($r('app.media.icon'))
                .width(80)
                .height(80)
                .sourceSize({ width: 160, height: 160 })
                .objectFit(ImageFit.Cover)
                .clip(true)
                .borderRadius(8)
                .interpolation(ImageInterpolation.Medium)

              Column({ space: 4 }) {
                Text(item.title)
                  .fontSize(16)
                  .fontWeight(FontWeight.Medium)
                Text(`ID: ${item.id}`)
                  .fontSize(12)
                  .fontColor('#999999')
                Text('sourceSize 优化解码')
                  .fontSize(12)
                  .fontColor('#007DFF')
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)
            }
            .width('90%')
            .padding(12)
            .backgroundColor(Color.White)
            .borderRadius(12)
          }
        }, (item: ImageItem) => item.id.toString())
      }
      .width('100%')
      .layoutWeight(1)
      .margin({ top: 8 })
    }
    .width('100%')
    .height('100%')
  }
}
