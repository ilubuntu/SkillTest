/**
 * repeat-nested — Repeat 嵌套使用
 * 展示 Repeat 嵌套渲染：外层 Repeat 渲染分类，内层 Repeat 渲染分类下的子项
 * 元服务兼容性：Repeat API 12+，元服务 API 12+ 可用
 */
import { BusinessError } from '@kit.BasicServicesKit'

interface CategoryItem {
  id: string
  name: string
  color: string
  items: string[]
}

@ComponentV2
export struct RepeatNested {
  @Local categories: CategoryItem[] = []
  @Local resultText: string = '嵌套 Repeat 就绪'

  aboutToAppear(): void {
    this.categories = [
      { id: 'cat_0', name: '水果', color: '#E74C3C', items: ['苹果', '香蕉', '橙子'] },
      { id: 'cat_1', name: '蔬菜', color: '#27AE60', items: ['胡萝卜', '西兰花', '菠菜'] },
      { id: 'cat_2', name: '饮料', color: '#3498DB', items: ['咖啡', '茶', '果汁'] },
      { id: 'cat_3', name: '零食', color: '#F39C12', items: ['饼干', '巧克力', '薯片'] },
      { id: 'cat_4', name: '主食', color: '#9B59B6', items: ['米饭', '面条', '面包'] }
    ]
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('Repeat 嵌套使用')
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

        // 操作按钮
        Row({ space: 8 }) {
          Button('添加分类')
            .fontSize(13)
            .width(90)
            .height(36)
            .onClick(() => {
              try {
                const idx = this.categories.length
                this.categories.push({
                  id: `cat_${idx}`,
                  name: `分类${idx}`,
                  color: '#607D8B',
                  items: [`项目${idx}_1`, `项目${idx}_2`]
                })
                this.resultText = `添加分类${idx}，共 ${this.categories.length} 个分类`
              } catch (err) {
                const e = err as BusinessError
                this.resultText = `添加失败: ${e.message}`
              }
            })
          Button('删除末尾')
            .fontSize(13)
            .width(90)
            .height(36)
            .onClick(() => {
              try {
                if (this.categories.length > 0) {
                  this.categories.pop()
                  this.resultText = `删除末尾分类，剩余 ${this.categories.length} 个`
                }
              } catch (err) {
                const e = err as BusinessError
                this.resultText = `删除失败: ${e.message}`
              }
            })
        }

        // 嵌套 Repeat 列表
        Text('外层 Repeat（分类） + 内层 Repeat（子项）')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        List({ space: 12 }) {
          Repeat<CategoryItem>(this.categories)
            .each((ri: RepeatItem<CategoryItem>) => {
              ListItem() {
                Column() {
                  // 分类标题
                  Row() {
                    Text('')
                      .width(8)
                      .height(8)
                      .borderRadius(4)
                      .backgroundColor(ri.item.color)
                    Text(ri.item.name)
                      .fontSize(16)
                      .fontWeight(FontWeight.Bold)
                      .margin({ left: 8 })
                    Text(`${ri.item.items.length}项`)
                      .fontSize(12)
                      .fontColor('#999999')
                      .margin({ left: 8 })
                  }
                  .width('100%')
                  .padding({ left: 12, top: 8, bottom: 4 })

                  // 内层 Repeat 渲染子项
                  List({ space: 4 }) {
                    Repeat<string>(ri.item.items)
                      .each((subRi: RepeatItem<string>) => {
                        ListItem() {
                          Row() {
                            Text(`  • ${subRi.item}`)
                              .fontSize(14)
                              .fontColor('#444444')
                          }
                          .width('100%')
                          .padding({ left: 24, top: 6, bottom: 6 })
                        }
                        .onClick(() => {
                          this.resultText = `分类[${ri.item.name}]: ${subRi.item}`
                        })
                      })
                      .key((item: string, index: number) => `${ri.item.id}_${item}_${index}`)
                      .virtualScroll()
                  }
                  .width('100%')
                  .height(ri.item.items.length * 36)
                }
                .width('100%')
                .padding(8)
                .backgroundColor('#FFFFFF')
                .borderRadius(8)
                .border({ width: 1, color: '#E0E0E0' })
              }
            })
            .key((item: CategoryItem) => item.id)
            .virtualScroll()
        }
        .cachedCount(2)
        .width('90%')
        .height(320)
        .border({ width: 1, color: '#E0E0E0' })
        .borderRadius(8)

        // API 说明区
        Column() {
          Text('API 说明')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 8 })
          Text('Repeat 支持嵌套使用，内层 Repeat 可独立管理数据')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('内层 key 需包含外层标识，避免跨分类 key 冲突')
            .fontSize(12)
            .fontColor('#FF6B00')
            .width('100%')
          Text('建议嵌套层级不超过3层，避免性能问题')
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
