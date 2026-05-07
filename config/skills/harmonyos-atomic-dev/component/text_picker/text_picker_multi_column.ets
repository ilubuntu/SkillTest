/**
 * text_picker_multi_column — 多列选择器（非联动 + 级联联动）
 * 展示 string[][] 多列非联动 和 TextCascadePickerRangeContent 多列联动
 * 元服务兼容性：多列相关 API 11+ 可用
 */
@ComponentV2
export struct TextPickerMultiColumn {
  @Local multiResult: string = '等待选择...'
  @Local cascadeResult: string = '等待选择...'
  @Local eventLog: string = '等待操作...'

  private singleFruits: string[] = ['apple1', 'apple2', 'apple3', 'apple4']
  private singleOranges: string[] = ['orange1', 'orange2', 'orange3', 'orange4']
  private singlePeaches: string[] = ['peach1', 'peach2', 'peach3', 'peach4']
  private multi: string[][] = [this.singleFruits, this.singleOranges, this.singlePeaches]

  private cascade: TextCascadePickerRangeContent[] = [
    {
      text: '辽宁省',
      children: [
        {
          text: '沈阳市',
          children: [{ text: '沈河区' }, { text: '和平区' }, { text: '浑南区' }]
        },
        {
          text: '大连市',
          children: [{ text: '中山区' }, { text: '金州区' }, { text: '长海县' }]
        }
      ]
    },
    {
      text: '吉林省',
      children: [
        {
          text: '长春市',
          children: [{ text: '南关区' }, { text: '宽城区' }, { text: '朝阳区' }]
        },
        {
          text: '四平市',
          children: [{ text: '铁西区' }, { text: '铁东区' }, { text: '梨树县' }]
        }
      ]
    },
    {
      text: '黑龙江省',
      children: [
        {
          text: '哈尔滨市',
          children: [{ text: '道里区' }, { text: '道外区' }, { text: '南岗区' }]
        },
        {
          text: '牡丹江市',
          children: [{ text: '东安区' }, { text: '西安区' }, { text: '爱民区' }]
        }
      ]
    }
  ]

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('多列选择器')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20, bottom: 10 })

        // 结果展示区
        Column() {
          Text(this.multiResult)
            .fontSize(14)
            .fontColor('#333333')
            .width('100%')
            .padding(12)
        }
        .width('90%')
        .backgroundColor('#F5F5F5')
        .borderRadius(8)

        // 事件日志区
        Column() {
          Text(this.eventLog)
            .fontSize(12)
            .fontColor('#666666')
            .width('100%')
            .padding(12)
        }
        .width('90%')
        .backgroundColor('#F0F0F0')
        .borderRadius(8)

        // 多列非联动选择器
        Text('多列非联动选择器 (3列独立)')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        TextPicker({ range: this.multi })
          .onChange((value: string | string[], index: number | number[]) => {
            try {
              const v = value as string[]
              const i = index as number[]
              this.multiResult = `非联动: ${v.join(' / ')}`
              this.eventLog = `onChange → value: [${v.join(', ')}], index: [${i.join(', ')}]`
            } catch (err) {
              this.eventLog = `错误: ${(err as BusinessError).message}`
            }
          })

        // 级联联动选择器
        Text('多列联动选择器 (省/市/区)')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        TextPicker({ range: this.cascade })
          .onChange((value: string | string[], index: number | number[]) => {
            try {
              const v = value as string[]
              const i = index as number[]
              this.cascadeResult = `联动: ${v.join(' / ')}`
              this.eventLog = `级联 onChange → value: [${v.join(', ')}], index: [${i.join(', ')}]`
            } catch (err) {
              this.eventLog = `错误: ${(err as BusinessError).message}`
            }
          })

        // 级联结果显示
        Column() {
          Text(this.cascadeResult)
            .fontSize(14)
            .fontColor('#333333')
            .width('100%')
            .padding(12)
        }
        .width('90%')
        .backgroundColor('#F5F5F5')
        .borderRadius(8)

        // API 说明区
        Column() {
          Text('API 说明')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 8 })
          Text('多列非联动: range 传入 string[][]')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('多列联动: range 传入 TextCascadePickerRangeContent[]')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('TextCascadePickerRangeContent: { text, children? }')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('onChange 回调 value 为 string[]，index 为 number[]')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('元服务兼容: TextCascadePickerRangeContent API 11+ 可用')
            .fontSize(12)
            .fontColor('#4CAF50')
            .width('100%')
            .margin({ top: 4 })
        }
        .width('90%')
        .backgroundColor('#FFF9E6')
        .borderRadius(8)
        .padding(12)
        .margin({ top: 8, bottom: 20 })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
  }
}
