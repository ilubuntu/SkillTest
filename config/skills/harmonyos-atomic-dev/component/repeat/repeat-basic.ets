/**
 * repeat-basic — Repeat 基础循环渲染
 * 展示 Repeat 基本用法：关闭懒加载模式、.each() + .key()、简单数组与对象数组
 * 元服务兼容性：Repeat API 12+，元服务 API 12+ 可用
 */
import { BusinessError } from '@kit.BasicServicesKit'

@ObservedV2
class ArticleItem {
  readonly id: string
  @Trace title: string
  @Trace likes: number
  constructor(id: string, title: string, likes: number) {
    this.id = id
    this.title = title
    this.likes = likes
  }
}

@ComponentV2
export struct RepeatBasic {
  @Local stringList: string[] = ['苹果', '香蕉', '橙子', '葡萄', '西瓜']
  @Local articleList: ArticleItem[] = [
    new ArticleItem('a1', 'ArkUI 声明式开发', 120),
    new ArticleItem('a2', 'Repeat 循环渲染指南', 85),
    new ArticleItem('a3', '状态管理 V2 最佳实践', 200),
    new ArticleItem('a4', '元服务开发入门', 150)
  ]
  @Local resultText: string = 'Repeat 基础渲染就绪'

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('Repeat 基础循环渲染')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20, bottom: 10 })

        // 结果展示区
        Column() {
          Text(this.resultText)
            .fontSize(14)
            .fontColor('#333333')
            .width('100%')
            .padding(12)
        }
        .width('90%')
        .backgroundColor('#F5F5F5')
        .borderRadius(8)

        // 场景1：关闭懒加载，字符串数组
        Text('场景1：字符串数组（关闭懒加载）')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Column({ space: 8 }) {
          Repeat<string>(this.stringList)
            .each((ri: RepeatItem<string>) => {
              Row() {
                Text(`${ri.index + 1}`)
                  .fontSize(14)
                  .fontColor('#FFFFFF')
                  .width(28)
                  .height(28)
                  .textAlign(TextAlign.Center)
                  .borderRadius(14)
                  .backgroundColor('#FF6B00')
                Text(ri.item)
                  .fontSize(15)
                  .margin({ left: 12 })
                  .layoutWeight(1)
              }
              .width('100%')
              .padding({ left: 12, right: 12, top: 10, bottom: 10 })
              .backgroundColor('#FFFFFF')
              .borderRadius(6)
            })
            .key((item: string) => item)
        }
        .width('90%')
        .padding(8)
        .backgroundColor('#F0F0F0')
        .borderRadius(8)

        // 场景2：对象数组 + @ObservedV2/@Trace
        Text('场景2：对象数组（子属性观测）')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Column({ space: 8 }) {
          Repeat<ArticleItem>(this.articleList)
            .each((ri: RepeatItem<ArticleItem>) => {
              Row() {
                Column() {
                  Text(ri.item.title)
                    .fontSize(15)
                    .fontWeight(FontWeight.Medium)
                  Text(`点赞: ${ri.item.likes}`)
                    .fontSize(12)
                    .fontColor('#999999')
                    .margin({ top: 4 })
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)

                Button('点赞')
                  .fontSize(12)
                  .width(60)
                  .height(30)
                  .backgroundColor('#FF6B00')
                  .onClick(() => {
                    try {
                      ri.item.likes += 1
                      this.resultText = `「${ri.item.title}」点赞数: ${ri.item.likes}`
                    } catch (err) {
                      const e = err as BusinessError
                      this.resultText = `操作失败: ${e.message}`
                    }
                  })
              }
              .width('100%')
              .padding(12)
              .backgroundColor('#FFFFFF')
              .borderRadius(6)
            })
            .key((item: ArticleItem) => item.id)
        }
        .width('90%')
        .padding(8)
        .backgroundColor('#F0F0F0')
        .borderRadius(8)

        // 操作按钮
        Text('数据操作')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Row({ space: 8 }) {
          Button('添加水果')
            .fontSize(13)
            .width(80)
            .height(36)
            .onClick(() => {
              try {
                const fruits = ['芒果', '草莓', '樱桃', '柠檬', '桃子']
                const newItem = fruits[this.stringList.length % fruits.length]
                this.stringList.push(newItem)
                this.resultText = `添加: ${newItem}，共 ${this.stringList.length} 项`
              } catch (err) {
                const e = err as BusinessError
                this.resultText = `添加失败: ${e.message}`
              }
            })
          Button('删除末项')
            .fontSize(13)
            .width(80)
            .height(36)
            .onClick(() => {
              try {
                if (this.stringList.length > 0) {
                  const removed = this.stringList.pop()
                  this.resultText = `删除: ${removed}，剩余 ${this.stringList.length} 项`
                } else {
                  this.resultText = '列表已空'
                }
              } catch (err) {
                const e = err as BusinessError
                this.resultText = `删除失败: ${e.message}`
              }
            })
          Button('重置')
            .fontSize(13)
            .width(60)
            .height(36)
            .onClick(() => {
              this.stringList = ['苹果', '香蕉', '橙子', '葡萄', '西瓜']
              this.resultText = '列表已重置'
            })
        }

        // API 说明区
        Column() {
          Text('API 说明')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 8 })
          Text('Repeat<T>(arr: Array<T>)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('.each(itemGenerator: (ri: RepeatItem<T>) => void)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('.key(keyGenerator: (item, index) => string)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('关闭懒加载时不限容器，适合短列表(<30项)')
            .fontSize(12)
            .fontColor('#FF6B00')
            .width('100%')
          Text('建议: 使用对象唯一 id 作为 key，避免用 index')
            .fontSize(12)
            .fontColor('#FF6B00')
            .width('100%')
          Text('元服务：API 12+ 可用')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
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
