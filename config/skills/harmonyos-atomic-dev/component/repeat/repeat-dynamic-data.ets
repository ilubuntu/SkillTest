/**
 * repeat-dynamic-data — Repeat 动态数据操作
 * 展示 Repeat 配合 virtualScroll 后的增删改交换操作
 * 元服务兼容性：Repeat API 12+，元服务 API 12+ 可用
 */
import { BusinessError } from '@kit.BasicServicesKit'

@ObservedV2
class TaskItem {
  readonly id: string
  @Trace title: string
  @Trace status: string
  constructor(id: string, title: string, status: string) {
    this.id = id
    this.title = title
    this.status = status
  }
}

@ComponentV2
export struct RepeatDynamicData {
  @Local taskList: TaskItem[] = []
  @Local selectedIndex: number = 0
  @Local resultText: string = '动态数据操作就绪'
  private counter: number = 0

  aboutToAppear(): void {
    const tasks = ['设计评审', '代码开发', '单元测试', '集成测试', '性能优化',
      '文档编写', '部署上线', '用户反馈', 'Bug修复', '版本迭代']
    for (let i = 0; i < 10; i++) {
      this.taskList.push(new TaskItem(`task_${i}`, tasks[i], i % 3 === 0 ? '进行中' : (i % 3 === 1 ? '待处理' : '已完成')))
    }
    this.counter = 10
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('Repeat 动态数据操作')
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

        // 参数控制区
        Text('选择操作索引')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Row({ space: 8 }) {
          Text('当前索引:')
            .fontSize(13)
          Text(`${this.selectedIndex}`)
            .fontSize(13)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FF6B00')
        }
        .alignSelf(ItemAlign.Start)
        .margin({ left: 16 })

        // 操作按钮
        Row({ space: 6 }) {
          Button('插入')
            .fontSize(12)
            .width(65)
            .height(34)
            .onClick(() => {
              try {
                const idx = Math.min(this.selectedIndex, this.taskList.length)
                this.taskList.splice(idx, 0, new TaskItem(`task_${this.counter++}`, `新任务_${this.counter}`, '待处理'))
                this.resultText = `在索引 ${idx} 处插入，共 ${this.taskList.length} 项`
              } catch (err) {
                const e = err as BusinessError
                this.resultText = `插入失败: ${e.message}`
              }
            })
          Button('修改')
            .fontSize(12)
            .width(65)
            .height(34)
            .backgroundColor('#3498DB')
            .onClick(() => {
              try {
                if (this.selectedIndex < this.taskList.length) {
                  const task = this.taskList[this.selectedIndex]
                  task.title = `已修改_${this.counter++}`
                  task.status = '已修改'
                  this.resultText = `修改索引 ${this.selectedIndex} 的数据`
                } else {
                  this.resultText = '索引超出范围'
                }
              } catch (err) {
                const e = err as BusinessError
                this.resultText = `修改失败: ${e.message}`
              }
            })
          Button('删除')
            .fontSize(12)
            .width(65)
            .height(34)
            .backgroundColor('#E74C3C')
            .onClick(() => {
              try {
                if (this.selectedIndex < this.taskList.length) {
                  this.taskList.splice(this.selectedIndex, 1)
                  if (this.selectedIndex >= this.taskList.length && this.taskList.length > 0) {
                    this.selectedIndex = this.taskList.length - 1
                  }
                  this.resultText = `删除索引 ${this.selectedIndex}，剩余 ${this.taskList.length} 项`
                } else {
                  this.resultText = '索引超出范围'
                }
              } catch (err) {
                const e = err as BusinessError
                this.resultText = `删除失败: ${e.message}`
              }
            })
          Button('交换0↔1')
            .fontSize(12)
            .width(70)
            .height(34)
            .backgroundColor('#9B59B6')
            .onClick(() => {
              try {
                if (this.taskList.length >= 2) {
                  const temp = this.taskList[0]
                  this.taskList[0] = this.taskList[1]
                  this.taskList[1] = temp
                  this.resultText = '交换索引 0 和 1 的数据'
                }
              } catch (err) {
                const e = err as BusinessError
                this.resultText = `交换失败: ${e.message}`
              }
            })
        }

        Row({ space: 6 }) {
          Button('索引-1')
            .fontSize(12)
            .width(65)
            .height(34)
            .onClick(() => {
              if (this.selectedIndex > 0) {
                this.selectedIndex--
              }
            })
          Button('索引+1')
            .fontSize(12)
            .width(65)
            .height(34)
            .onClick(() => {
              if (this.selectedIndex < this.taskList.length - 1) {
                this.selectedIndex++
              }
            })
          Button('截取前5项')
            .fontSize(12)
            .height(34)
            .backgroundColor('#FF6B00')
            .onClick(() => {
              this.taskList = this.taskList.slice(0, 5)
              if (this.selectedIndex >= this.taskList.length) {
                this.selectedIndex = Math.max(0, this.taskList.length - 1)
              }
              this.resultText = `截取为 ${this.taskList.length} 项`
            })
        }

        // 列表区域
        Text('点击列表项选择操作目标，点击两个不同项可交换')
          .fontSize(13)
          .fontColor('#999999')
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        List({ space: 8 }) {
          Repeat<TaskItem>(this.taskList)
            .each((ri: RepeatItem<TaskItem>) => {
              ListItem() {
                Row() {
                  Column() {
                    Text(ri.item.title)
                      .fontSize(15)
                      .fontWeight(this.selectedIndex === ri.index ? FontWeight.Bold : FontWeight.Normal)
                    Text(`状态: ${ri.item.status}`)
                      .fontSize(12)
                      .fontColor('#999999')
                      .margin({ top: 2 })
                  }
                  .alignItems(HorizontalAlign.Start)
                  .layoutWeight(1)
                  Text(`#${ri.index}`)
                    .fontSize(12)
                    .fontColor(this.selectedIndex === ri.index ? '#FF6B00' : '#CCCCCC')
                }
                .width('100%')
                .padding(12)
                .backgroundColor(this.selectedIndex === ri.index ? '#FFF3E0' : '#FFFFFF')
                .borderRadius(6)
                .border({
                  width: this.selectedIndex === ri.index ? 2 : 1,
                  color: this.selectedIndex === ri.index ? '#FF6B00' : '#E0E0E0'
                })
              }
              .onClick(() => {
                this.selectedIndex = ri.index
                this.resultText = `选中: ${ri.item.title} (索引 ${ri.index})`
              })
            })
            .key((item: TaskItem) => item.id)
            .virtualScroll({ totalCount: this.taskList.length })
        }
        .cachedCount(2)
        .width('90%')
        .height(280)
        .border({ width: 1, color: '#E0E0E0' })
        .borderRadius(8)

        // API 说明区
        Column() {
          Text('API 说明')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 8 })
          Text('Repeat 直接监听状态变量变化，无需手动通知')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('支持操作: push/pop/splice/shift/unshift/slice/map')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('修改子属性需使用 @ObservedV2 + @Trace 装饰器')
            .fontSize(12)
            .fontColor('#FF6B00')
            .width('100%')
          Text('key 值在数组变化时必须保持唯一且一致')
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
