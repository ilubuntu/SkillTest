/**
 * image-style — 图片样式与渲染场景
 * renderMode、fillColor、blur、interpolation
 */
@ComponentV2
export struct ImageStyle {
  @Local isOriginal: boolean = true
  @Local blurValue: number = 0

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('图片样式与渲染')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20, bottom: 10 })

        // 渲染模式
        Text('渲染模式')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16 })

        Row({ space: 12 }) {
          Button('原图')
            .fontSize(14)
            .height(36)
            .onClick(() => { this.isOriginal = true })
          Button('黑白模板')
            .fontSize(14)
            .height(36)
            .onClick(() => { this.isOriginal = false })
        }

        Image($r('app.media.startIcon'))
          .width(200)
          .height(150)
          .renderMode(this.isOriginal ? ImageRenderMode.Original : ImageRenderMode.Template)
          .fillColor(this.isOriginal ? '' : '#007DFF')
          .objectFit(ImageFit.Cover)
          .clip(true)
          .borderRadius(12)

        // fillColor 着色
        Text('fillColor 着色')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 16 })

        Row({ space: 16 }) {
          Image($r('app.media.icon'))
            .width(60)
            .height(60)
            .fillColor('#FF0000')
            .renderMode(ImageRenderMode.Template)
          Image($r('app.media.icon'))
            .width(60)
            .height(60)
            .fillColor('#00AA00')
            .renderMode(ImageRenderMode.Template)
          Image($r('app.media.icon'))
            .width(60)
            .height(60)
            .fillColor('#0000FF')
            .renderMode(ImageRenderMode.Template)
        }

        // 模糊效果
        Text(`模糊效果 (radius: ${this.blurValue})`)
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 16 })

        Slider({
          value: this.blurValue,
          min: 0,
          max: 50,
          step: 5
        })
          .width('80%')
          .onChange((value: number) => {
            this.blurValue = value
          })

        Image($r('app.media.startIcon'))
          .width(200)
          .height(150)
          .blur(this.blurValue)
          .objectFit(ImageFit.Cover)
          .clip(true)
          .borderRadius(12)

        // 插值质量
        Text('插值质量')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 16 })

        Row({ space: 12 }) {
          Column() {
            Image($r('app.media.icon'))
              .width(100)
              .height(100)
              .interpolation(ImageInterpolation.None)
            Text('None')
              .fontSize(12)
              .margin({ top: 4 })
          }
          Column() {
            Image($r('app.media.icon'))
              .width(100)
              .height(100)
              .interpolation(ImageInterpolation.Low)
            Text('Low')
              .fontSize(12)
              .margin({ top: 4 })
          }
          Column() {
            Image($r('app.media.icon'))
              .width(100)
              .height(100)
              .interpolation(ImageInterpolation.High)
            Text('High')
              .fontSize(12)
              .margin({ top: 4 })
          }
        }
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
  }
}
