/**
 * image-fit — 图片缩放与裁剪场景
 * objectFit 各种模式对比、圆角裁剪、clip
 */
@ComponentV2
export struct ImageFitScale {
  @Local fitMode: string = 'Cover'

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('图片缩放与裁剪')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20, bottom: 10 })

        Text(`当前模式: ${this.fitMode}`)
          .fontSize(16)
          .fontColor('#007DFF')

        Row({ space: 8 }) {
          ForEach(['Cover', 'Contain', 'Fill', 'ScaleDown', 'None'], (mode: string) => {
            Button(mode)
              .fontSize(12)
              .height(32)
              .onClick(() => { this.fitMode = mode })
          })
        }
        .margin({ top: 8 })

        // 切换展示
        Stack() {
          Image($r('app.media.startIcon'))
            .width(200)
            .height(200)
            .objectFit(this.getFitMode())
            .border({ width: 1, color: '#CCCCCC' })
        }
        .width(200)
        .height(200)
        .margin({ top: 16 })

        // 各模式对比
        Text('各模式对比')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 16 })

        Column() {
          Image($r('app.media.startIcon'))
            .width(160)
            .height(100)
            .objectFit(ImageFit.Cover)
          Text('Cover — 保持比例裁剪填满')
            .fontSize(12)
            .margin({ top: 4 })
        }
        .margin({ top: 8 })

        Column() {
          Image($r('app.media.startIcon'))
            .width(160)
            .height(100)
            .objectFit(ImageFit.Contain)
          Text('Contain — 保持比例完整显示')
            .fontSize(12)
            .margin({ top: 4 })
        }
        .margin({ top: 8 })

        Column() {
          Image($r('app.media.startIcon'))
            .width(160)
            .height(100)
            .objectFit(ImageFit.Fill)
          Text('Fill — 拉伸填满')
            .fontSize(12)
            .margin({ top: 4 })
        }
        .margin({ top: 8 })

        // 圆角裁剪
        Text('圆角裁剪')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 16 })

        Row({ space: 16 }) {
          Image($r('app.media.icon'))
            .width(80)
            .height(80)
            .clip(true)
            .borderRadius(10)
          Image($r('app.media.icon'))
            .width(80)
            .height(80)
            .clip(true)
            .borderRadius(40)
          Image($r('app.media.icon'))
            .width(80)
            .height(80)
            .clip(true)
            .borderRadius({ topLeft: 20, topRight: 20 })
        }
        .margin({ top: 8 })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
  }

  private getFitMode(): ImageFit {
    switch (this.fitMode) {
      case 'Cover': return ImageFit.Cover
      case 'Contain': return ImageFit.Contain
      case 'Fill': return ImageFit.Fill
      case 'ScaleDown': return ImageFit.ScaleDown
      case 'None': return ImageFit.None
      default: return ImageFit.Cover
    }
  }
}
