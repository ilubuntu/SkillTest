/**
 * lazy_for_each-dynamic — LazyForEach 动态数据操作
 * 展示 onDataAdd/onDataDelete/onDataChange/onDataMove 增删改移操作
 * 元服务兼容性：DataChangeListener API 8+，元服务 API 11+ 可用
 */
import { BusinessError } from '@kit.BasicServicesKit'

interface DataItem {
  id: string
  title: string
  status: string
}

class BasicDataSource implements IDataSource {
  private listeners: DataChangeListener[] = []

  totalCount(): number {
    return 0
  }

  getData(_index: number): DataItem | undefined {
    return undefined
  }

  registerDataChangeListener(listener: DataChangeListener): void {
    if (this.listeners.indexOf(listener) < 0) {
      this.listeners.push(listener)
    }
  }

  unregisterDataChangeListener(listener: DataChangeListener): void {
    const pos = this.listeners.indexOf(listener)
    if (pos >= 0) {
      this.listeners.splice(pos, 1)
    }
  }

  notifyDataReload(): void {
    this.listeners.forEach(listener => {
      listener.onDataReloaded()
    })
  }

  notifyDataAdd(index: number): void {
    this.listeners.forEach(listener => {
      listener.onDataAdd(index)
    })
  }

  notifyDataChange(index: number): void {
    this.listeners.forEach(listener => {
      listener.onDataChange(index)
    })
  }

  notifyDataDelete(index: number): void {
    this.listeners.forEach(listener => {
      listener.onDataDelete(index)
    })
  }

  notifyDataMove(from: number, to: number): void {
    this.listeners.forEach(listener => {
      listener.onDataMove(from, to)
    })
  }
}

class DynamicDataSource extends BasicDataSource {
  private dataArray: DataItem[] = []

  totalCount(): number {
    return this.dataArray.length
  }

  getData(index: number): DataItem {
    return this.dataArray[index]
  }

  getAllData(): DataItem[] {
    return this.dataArray
  }

  initData(items: DataItem[]): void {
    this.dataArray = items
    this.notifyDataReload()
  }

  addData(item: DataItem): void {
    this.dataArray.push(item)
    this.notifyDataAdd(this.dataArray.length - 1)
  }

  insertData(index: number, item: DataItem): void {
    this.dataArray.splice(index, 0, item)
    this.notifyDataAdd(index)
  }

  deleteData(index: number): void {
    this.dataArray.splice(index, 1)
    this.notifyDataDelete(index)
  }

  changeData(index: number, item: DataItem): void {
    this.dataArray[index] = item
    this.notifyDataChange(index)
  }

  moveData(from: number, to: number): void {
    const temp = this.dataArray[from]
    this.dataArray[from] = this.dataArray[to]
    this.dataArray[to] = temp
    this.notifyDataMove(from, to)
  }
}

@ComponentV2
export struct LazyForEachDynamic {
  @Local resultText: string = 'LazyForEach 动态操作就绪'
  @Local nextId: number = 6
  private dataSource: DynamicDataSource = new DynamicDataSource()

  aboutToAppear(): void {
    const items: DataItem[] = []
    const titles = ['学习 ArkTS', '掌握 LazyForEach', '开发元服务', '性能优化', '发布上线']
    const statuses = ['已完成', '进行中', '未开始', '进行中', '未开始']
    for (let i = 0; i < titles.length; i++) {
      items.push({ id: `task_${i}`, title: titles[i], status: statuses[i] })
    }
    this.dataSource.initData(items)
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('LazyForEach 动态数据操作')
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

        // 操作按钮区
        Text('数据操作')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Row({ space: 8 }) {
          Button('尾部添加')
            .fontSize(12)
            .width(76)
            .height(34)
            .onClick(() => {
              try {
                const id = `task_${this.nextId++}`
                const tasks = ['代码审查', '编写测试', 'Bug修复', '文档编写', '部署上线']
                this.dataSource.addData({
                  id: id,
                  title: tasks[Math.floor(Math.random() * tasks.length)],
                  status: '未开始'
                })
                this.resultText = `尾部添加: ${id}，共 ${this.dataSource.totalCount()} 项`
              } catch (err) {
                const e = err as BusinessError
                this.resultText = `添加失败: ${e.message}`
              }
            })
          Button('头部插入')
            .fontSize(12)
            .width(76)
            .height(34)
            .onClick(() => {
              try {
                const id = `task_${this.nextId++}`
                this.dataSource.insertData(0, { id: id, title: `紧急任务(${id})`, status: '进行中' })
                this.resultText = `头部插入: ${id}，共 ${this.dataSource.totalCount()} 项`
              } catch (err) {
                const e = err as BusinessError
                this.resultText = `插入失败: ${e.message}`
              }
            })
          Button('删除末项')
            .fontSize(12)
            .width(76)
            .height(34)
            .onClick(() => {
              try {
                const count = this.dataSource.totalCount()
                if (count > 0) {
                  const removed = this.dataSource.getData(count - 1)
                  this.dataSource.deleteData(count - 1)
                  this.resultText = `删除: ${removed.title}，剩余 ${this.dataSource.totalCount()} 项`
                } else {
                  this.resultText = '列表已空'
                }
              } catch (err) {
                const e = err as BusinessError
                this.resultText = `删除失败: ${e.message}`
              }
            })
        }

        Row({ space: 8 }) {
          Button('修改首项')
            .fontSize(12)
            .width(76)
            .height(34)
            .onClick(() => {
              try {
                if (this.dataSource.totalCount() > 0) {
                  const old = this.dataSource.getData(0)
                  this.dataSource.changeData(0, {
                    id: old.id,
                    title: `${old.title}(已修改)`,
                    status: '已完成'
                  })
                  this.resultText = `修改首项: ${old.id} 状态→已完成`
                }
              } catch (err) {
                const e = err as BusinessError
                this.resultText = `修改失败: ${e.message}`
              }
            })
          Button('交换首尾')
            .fontSize(12)
            .width(76)
            .height(34)
            .onClick(() => {
              try {
                const count = this.dataSource.totalCount()
                if (count >= 2) {
                  this.dataSource.moveData(0, count - 1)
                  this.resultText = `交换: 索引0 ↔ 索引${count - 1}`
                }
              } catch (err) {
                const e = err as BusinessError
                this.resultText = `交换失败: ${e.message}`
              }
            })
          Button('重置')
            .fontSize(12)
            .width(60)
            .height(34)
            .onClick(() => {
              this.nextId = 6
              const items: DataItem[] = []
              const titles = ['学习 ArkTS', '掌握 LazyForEach', '开发元服务', '性能优化', '发布上线']
              const statuses = ['已完成', '进行中', '未开始', '进行中', '未开始']
              for (let i = 0; i < titles.length; i++) {
                items.push({ id: `task_${i}`, title: titles[i], status: statuses[i] })
              }
              this.dataSource.initData(items)
              this.resultText = '列表已重置'
            })
        }

        // LazyForEach 列表
        List({ space: 4 }) {
          LazyForEach(
            this.dataSource,
            (item: DataItem, index?: number) => {
              ListItem() {
                Row() {
                  Text(item.status === '已完成' ? '✓' : item.status === '进行中' ? '●' : '○')
                    .fontSize(16)
                    .fontColor(item.status === '已完成' ? '#27AE60' : item.status === '进行中' ? '#FF6B00' : '#CCCCCC')
                    .width(24)
                    .textAlign(TextAlign.Center)

                  Column() {
                    Text(item.title)
                      .fontSize(14)
                      .fontColor('#333333')
                      .decoration({
                        type: item.status === '已完成' ? TextDecorationType.LineThrough : TextDecorationType.None
                      })
                    Text(`ID: ${item.id} | ${item.status}`)
                      .fontSize(11)
                      .fontColor('#BBBBBB')
                      .margin({ top: 2 })
                  }
                  .alignItems(HorizontalAlign.Start)
                  .layoutWeight(1)
                  .margin({ left: 8 })

                  Text(`${(index ?? 0) + 1}`)
                    .fontSize(12)
                    .fontColor('#999999')
                    .width(20)
                    .textAlign(TextAlign.Center)
                }
                .width('100%')
                .padding({ left: 12, right: 12, top: 10, bottom: 10 })
                .backgroundColor('#FFFFFF')
                .borderRadius(6)
              }
              .height(60)
            },
            (item: DataItem) => item.id
          )
        }
        .width('90%')
        .height(260)
        .cachedCount(3)
        .borderRadius(8)
        .backgroundColor('#F0F0F0')
        .padding(4)

        // API 说明区
        Column() {
          Text('API 说明')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 8 })
          Text('DataChangeListener 方法（元服务 API 11+）:')
            .fontSize(12)
            .fontColor('#666666')
            .width('100%')
          Text('onDataAdd(index) — 在 index 位置添加子组件')
            .fontSize(12)
            .fontColor('#999999')
            .fontFamily('monospace')
            .width('100%')
          Text('onDataDelete(index) — 删除 index 位置的子组件')
            .fontSize(12)
            .fontColor('#999999')
            .fontFamily('monospace')
            .width('100%')
          Text('onDataChange(index) — 重建 index 位置的子组件')
            .fontSize(12)
            .fontColor('#999999')
            .fontFamily('monospace')
            .width('100%')
          Text('onDataMove(from, to) — 交换两位置的子组件')
            .fontSize(12)
            .fontColor('#999999')
            .fontFamily('monospace')
            .width('100%')
          Text('onDataReloaded() — 重载所有数据（键值比对）')
            .fontSize(12)
            .fontColor('#999999')
            .fontFamily('monospace')
            .width('100%')
          Text('注意: onDataChange 需改变键值才能触发组件重建')
            .fontSize(12)
            .fontColor('#FF6B00')
            .width('100%')
          Text('元服务：API 11+ 可用')
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
