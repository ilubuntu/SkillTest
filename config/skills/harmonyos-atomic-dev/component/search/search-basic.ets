@ComponentV2
export struct SearchBasic {
  @Local resultLog: string = 'Search 组件开发中...'
  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('Search 搜索框')
          .fontSize(22).fontWeight(FontWeight.Bold).margin({ top: 20, bottom: 10 })
        Column() { Text(this.resultLog).fontSize(14).fontColor('#333333').width('100%').padding(12) }
          .width('90%').backgroundColor('#F5F5F5').borderRadius(8)
        Column() {
          Text('Search 组件基础用法待开发')
            .fontSize(14).fontColor('#FF6B00').width('100%')
        }.width('90%').backgroundColor('#FFF3CD').borderRadius(8).padding(12)
      }.width('100%').alignItems(HorizontalAlign.Center)
    }.width('100%').height('100%')
  }
}
