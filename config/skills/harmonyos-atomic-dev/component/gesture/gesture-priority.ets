/**
 * gesture-priority — 手势优先级与竞争
 * gesture / priorityGesture / parallelGesture 三种绑定方式对比
 */
@ComponentV2
export struct GesturePriority {
  @Local normalLog: string = '默认：子优先'
  @Local priorityLog: string = 'priorityGesture：父优先'
  @Local parallelLog: string = 'parallelGesture：父子并行'

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('手势优先级与竞争')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20, bottom: 10 })

        // 默认 gesture — 子优先
        Text('1. 默认 gesture（子组件优先）')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16 })

        Text(this.normalLog)
          .fontSize(13)
          .fontColor('#666666')

        Column() {
          Column() {
            Text('子组件')
              .fontSize(14)
              .fontColor(Color.White)
          }
          .width(120)
          .height(60)
          .justifyContent(FlexAlign.Center)
          .backgroundColor('#007DFF')
          .borderRadius(8)
          .gesture(
            TapGesture()
              .onAction(() => {
                this.normalLog = '默认：子组件响应'
              })
          )
        }
        .width('80%')
        .height(120)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .backgroundColor('#E8E8E8')
        .borderRadius(12)
        .gesture(
          TapGesture()
            .onAction(() => {
              this.normalLog = '默认：父组件响应'
            })
        )

        // priorityGesture — 父优先
        Text('2. priorityGesture（父组件优先）')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 16 })

        Text(this.priorityLog)
          .fontSize(13)
          .fontColor('#666666')

        Column() {
          Column() {
            Text('子组件')
              .fontSize(14)
              .fontColor(Color.White)
          }
          .width(120)
          .height(60)
          .justifyContent(FlexAlign.Center)
          .backgroundColor('#007DFF')
          .borderRadius(8)
          .gesture(
            TapGesture()
              .onAction(() => {
                this.priorityLog = 'priorityGesture：子组件响应（不应该触发）'
              })
          )
        }
        .width('80%')
        .height(120)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .backgroundColor('#E8E8E8')
        .borderRadius(12)
        .priorityGesture(
          TapGesture()
            .onAction(() => {
              this.priorityLog = 'priorityGesture：父组件优先响应'
            })
        )

        // parallelGesture — 并行
        Text('3. parallelGesture（父子并行）')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 16 })

        Text(this.parallelLog)
          .fontSize(13)
          .fontColor('#666666')

        Column() {
          Column() {
            Text('子组件')
              .fontSize(14)
              .fontColor(Color.White)
          }
          .width(120)
          .height(60)
          .justifyContent(FlexAlign.Center)
          .backgroundColor('#007DFF')
          .borderRadius(8)
          .gesture(
            TapGesture()
              .onAction(() => {
                this.parallelLog = 'parallelGesture：子组件也响应了'
              })
          )
        }
        .width('80%')
        .height(120)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .backgroundColor('#E8E8E8')
        .borderRadius(12)
        .parallelGesture(
          TapGesture()
            .onAction(() => {
              this.parallelLog = 'parallelGesture：父子同时响应'
            })
        )

        // 绑定方式对比表
        Text('绑定方式对比')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 16 })

        Column({ space: 6 }) {
          Text('.gesture() — 子组件优先识别')
            .fontSize(13).fontColor('#666666')
          Text('.priorityGesture() — 父组件优先识别')
            .fontSize(13).fontColor('#666666')
          Text('.parallelGesture() — 父子同时识别')
            .fontSize(13).fontColor('#666666')
        }
        .alignItems(HorizontalAlign.Start)
        .margin({ left: 16 })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
  }
}
