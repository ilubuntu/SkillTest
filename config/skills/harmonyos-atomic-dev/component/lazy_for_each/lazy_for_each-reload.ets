/**
 * lazy_for_each-reload — LazyForEach 数据重载与批量操作
 * 展示 onDataReloaded 全量重载、onDatasetChange 精准批量操作 (API 12+)
 * 元服务兼容性：onDataReloaded API 11+；onDatasetChange API 12+
 */
import { BusinessError } from '@kit.BasicServicesKit'

interface DataItem {
  id: string
  text: string
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

  notifyDatasetChange(operations: DataOperation[]): void {
    this.listeners.forEach(listener => {
      listener.onDatasetChange(operations)
    })
  }
}

class ReloadDataSource extends BasicDataSource {
  private dataArray: DataItem[] = []

  totalCount(): number {
    return this.dataArray.length
  }

  getData(index: number): DataItem {
    return this.dataArray[index]
  }

  initData(items: DataItem[]): void {
    this.dataArray = items
    this.notifyDataReload()
  }

  appendAll(suffix: string): void {
    const newData: DataItem[] = []
    for (let i = 0; i < this.dataArray.length; i++) {
      const old = this.dataArray[i]
      newData.push({ id: old.id, text: old.text + suffix } as DataItem)
    }
    this.dataArray = newData
    this.notifyDataReload()
  }

  batchAdd(index: number, items: DataItem[]): void {
    for (const item of items) {
      this.dataArray.splice(index, 0, item)
    }
    this.notifyDatasetChange([{ type: DataOperationType.ADD, index: index, count: items.length }])
  }

  batchDelete(index: number, count: number): void {
    this.dataArray.splice(index, count)
    this.notifyDatasetChange([{ type: DataOperationType.DELETE, index: index, count: count }])
  }

  batchChange(index: number, newItem: DataItem): void {
    this.dataArray[index] = newItem
    this.notifyDatasetChange([{ type: DataOperationType.CHANGE, index: index }])
  }

  batchMove(from: number, to: number): void {
    const temp = this.dataArray[from]
    this.dataArray[from] = this.dataArray[to]
    this.dataArray[to] = temp
    this.notifyDatasetChange([{ type: DataOperationType.EXCHANGE, index: { start: from, end: to } }])
  }

  compoundOperation(): void {
    this.dataArray[0] = { id: this.dataArray[0].id, text: this.dataArray[0].text + '(已更新)' }
    const newItems: DataItem[] = [
      { id: 'new_1', text: '新增数据1' },
      { id: 'new_2', text: '新增数据2' }
    ]
    this.dataArray.splice(3, 0, ...newItems)
    this.notifyDatasetChange([
      { type: DataOperationType.CHANGE, index: 0 },
      { type: DataOperationType.ADD, index: 3, count: 2 }
    ])
  }
}

@ComponentV2
export struct LazyForEachReload {
  @Local resultText: string = '数据重载与批量操作就绪'
  @Local useDatasetChange: boolean = true
  private dataSource: ReloadDataSource = new ReloadDataSource()

  aboutToAppear(): void {
    this.initData()
  }

  private initData(): void {
    const items: DataItem[] = []
    for (let i = 0; i < 10; i++) {
      items.push({ id: `d_${i}`, text: `数据项 ${String.fromCharCode(65 + i)}` })
    }
    this.dataSource.initData(items)
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('LazyForEach 数据重载与批量操作')
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

        // 方式选择
        Text('操作方式')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Column() {
          Text('onDataReloaded (API 11+): 全量重载，键值比对后决定是否重建组件')
            .fontSize(12)
            .fontColor(this.useDatasetChange ? '#999999' : '#FF6B00')
            .width('100%')
          Text('onDatasetChange (API 12+): 精准批量操作，避免全量重载闪烁问题')
            .fontSize(12)
            .fontColor(this.useDatasetChange ? '#FF6B00' : '#999999')
            .width('100%')
        }
        .width('90%')
        .backgroundColor('#FFF8E1')
        .borderRadius(8)
        .padding(10)

        // 操作按钮
        Row({ space: 8 }) {
          Button('全量追加')
            .fontSize(12)
            .width(76)
            .height(34)
            .onClick(() => {
              try {
                this.dataSource.appendAll('!')
                this.resultText = `全量重载: 所有数据追加 "!"，共 ${this.dataSource.totalCount()} 项`
              } catch (err) {
                const e = err as BusinessError
                this.resultText = `操作失败: ${e.message}`
              }
            })
          Button('批量添加')
            .fontSize(12)
            .width(76)
            .height(34)
            .onClick(() => {
              try {
                const idx = Math.min(3, this.dataSource.totalCount())
                this.dataSource.batchAdd(idx, [
                  { id: `ins_${Date.now()}_1`, text: '插入A' },
                  { id: `ins_${Date.now()}_2`, text: '插入B' }
                ])
                this.resultText = `批量添加: 在索引${idx}处添加2项`
              } catch (err) {
                const e = err as BusinessError
                this.resultText = `操作失败: ${e.message}`
              }
            })
          Button('批量删除')
            .fontSize(12)
            .width(76)
            .height(34)
            .onClick(() => {
              try {
                const count = this.dataSource.totalCount()
                if (count >= 2) {
                  this.dataSource.batchDelete(count - 2, 2)
                  this.resultText = `批量删除: 末尾2项，剩余 ${this.dataSource.totalCount()} 项`
                } else {
                  this.resultText = '数据不足，无法删除'
                }
              } catch (err) {
                const e = err as BusinessError
                this.resultText = `操作失败: ${e.message}`
              }
            })
        }

        Row({ space: 8 }) {
          Button('精准修改')
            .fontSize(12)
            .width(76)
            .height(34)
            .onClick(() => {
              try {
                if (this.dataSource.totalCount() > 0) {
                  const old = this.dataSource.getData(0)
                  this.dataSource.batchChange(0, {
                    id: old.id,
                    text: `${old.text}(修改)`
                  })
                  this.resultText = `精准修改: 索引0 数据已更新`
                }
              } catch (err) {
                const e = err as BusinessError
                this.resultText = `操作失败: ${e.message}`
              }
            })
          Button('交换数据')
            .fontSize(12)
            .width(76)
            .height(34)
            .onClick(() => {
              try {
                const count = this.dataSource.totalCount()
                if (count >= 2) {
                  this.dataSource.batchMove(0, 1)
                  this.resultText = '交换: 索引0 ↔ 索引1'
                }
              } catch (err) {
                const e = err as BusinessError
                this.resultText = `操作失败: ${e.message}`
              }
            })
          Button('复合操作')
            .fontSize(12)
            .width(76)
            .height(34)
            .onClick(() => {
              try {
                this.dataSource.compoundOperation()
                this.resultText = '复合操作: 修改索引0 + 索引3处添加2项'
              } catch (err) {
                const e = err as BusinessError
                this.resultText = `操作失败: ${e.message}`
              }
            })
        }

        Row({ space: 8 }) {
          Button('重置数据')
            .fontSize(12)
            .width(76)
            .height(34)
            .onClick(() => {
              this.initData()
              this.resultText = '数据已重置'
            })
        }

        // 列表渲染
        List({ space: 4 }) {
          LazyForEach(
            this.dataSource,
            (item: DataItem, index?: number) => {
              ListItem() {
                Row() {
                  Text(`${(index ?? 0) + 1}`)
                    .fontSize(13)
                    .fontColor('#FFFFFF')
                    .width(24)
                    .height(24)
                    .textAlign(TextAlign.Center)
                    .borderRadius(12)
                    .backgroundColor('#3498DB')

                  Text(item.text)
                    .fontSize(14)
                    .fontColor('#333333')
                    .layoutWeight(1)
                    .margin({ left: 10 })

                  Text(item.id)
                    .fontSize(11)
                    .fontColor('#BBBBBB')
                }
                .width('100%')
                .padding({ left: 12, right: 12, top: 8, bottom: 8 })
                .backgroundColor('#FFFFFF')
                .borderRadius(6)
              }
              .height(50)
            },
            (item: DataItem) => item.id
          )
        }
        .width('90%')
        .height(240)
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
          Text('onDataReloaded(): 全量重载，键值不变的复用，变化的重建')
            .fontSize(12)
            .fontColor('#999999')
            .fontFamily('monospace')
            .width('100%')
          Text('onDatasetChange(operations[]): 精准批量操作 (API 12+)')
            .fontSize(12)
            .fontColor('#999999')
            .fontFamily('monospace')
            .width('100%')
          Text('DataOperationType: ADD / DELETE / CHANGE / MOVE / EXCHANGE / RELOAD')
            .fontSize(12)
            .fontColor('#999999')
            .fontFamily('monospace')
            .width('100%')
          Text('注意: onDatasetChange 不能与其他 DataChangeListener 方法混用')
            .fontSize(12)
            .fontColor('#FF6B00')
            .width('100%')
          Text('含 RELOAD 操作时其他操作均不生效')
            .fontSize(12)
            .fontColor('#FF6B00')
            .width('100%')
          Text('元服务：onDataReloaded API 11+，onDatasetChange API 12+')
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
