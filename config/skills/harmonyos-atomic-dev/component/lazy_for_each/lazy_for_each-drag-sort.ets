/**
 * lazy_for_each-drag-sort — LazyForEach 拖拽排序
 * 展示 LazyForEach 配合 List onMove 实现拖拽排序
 * 元服务兼容性：onMove 拖拽排序属性 API 10+ 可用
 */
import { BusinessError } from '@kit.BasicServicesKit'

class BasicDataSource implements IDataSource {
  private listeners: DataChangeListener[] = []

  totalCount(): number {
    return 0
  }

  getData(_index: number): string | undefined {
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

  notifyDataAdd(index: number): void {
    this.listeners.forEach(listener => {
      listener.onDataAdd(index)
    })
  }

  notifyDataReload(): void {
    this.listeners.forEach(listener => {
      listener.onDataReloaded()
    })
  }
}

class DragSortDataSource extends BasicDataSource {
  private dataArray: string[] = []

  totalCount(): number {
    return this.dataArray.length
  }

  getData(index: number): string {
    return this.dataArray[index]
  }

  moveDataWithoutNotify(from: number, to: number): void {
    const tmp = this.dataArray.splice(from, 1)
    this.dataArray.splice(to, 0, tmp[0])
  }

  pushData(data: string): void {
    this.dataArray.push(data)
    this.notifyDataAdd(this.dataArray.length - 1)
  }

  resetData(data: string[]): void {
    this.dataArray = data
    this.notifyDataReload()
  }
}

@ComponentV2
export struct LazyForEachDragSort {
  @Local resultText: string = '拖拽排序就绪，长按列表项拖动排序'
  @Local dragCount: number = 0
  private dataSource: DragSortDataSource = new DragSortDataSource()

  aboutToAppear(): void {
    for (let i = 0; i < 20; i++) {
      this.dataSource.pushData(`列表项 ${i + 1}`)
    }
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('LazyForEach 拖拽排序')
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
        Text('操作')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Row({ space: 8 }) {
          Button('重置排序')
            .fontSize(13)
            .width(90)
            .height(36)
            .onClick(() => {
              try {
                this.dragCount = 0
                const data: string[] = []
                for (let i = 0; i < 20; i++) {
                  data.push(`列表项 ${i + 1}`)
                }
                // Re-create data source via public method
                this.dataSource.resetData(data)
                this.resultText = '排序已重置'
              } catch (err) {
                const e = err as BusinessError
                this.resultText = `重置失败: ${e.message}`
              }
            })
          Button('添加项')
            .fontSize(13)
            .width(80)
            .height(36)
            .onClick(() => {
              try {
                const count = this.dataSource.totalCount()
                this.dataSource.pushData(`新增项 ${count + 1}`)
                this.resultText = `添加成功，共 ${this.dataSource.totalCount()} 项`
              } catch (err) {
                const e = err as BusinessError
                this.resultText = `添加失败: ${e.message}`
              }
            })
        }

        // 拖拽排序列表
        Text('长按拖动排序')
          .fontSize(13)
          .fontColor('#999999')
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 4 })

        List({ space: 6 }) {
          LazyForEach(
            this.dataSource,
            (item: string, index?: number) => {
              ListItem() {
                Row() {
                  Text('☰')
                    .fontSize(16)
                    .fontColor('#BBBBBB')
                    .width(24)
                    .textAlign(TextAlign.Center)

                  Text(item)
                    .fontSize(15)
                    .fontColor('#333333')
                    .layoutWeight(1)
                    .margin({ left: 8 })

                  Text(`#${(index ?? 0) + 1}`)
                    .fontSize(12)
                    .fontColor('#999999')
                }
                .width('100%')
                .padding({ left: 12, right: 12, top: 12, bottom: 12 })
                .backgroundColor('#FFFFFF')
                .borderRadius(8)
              }
            },
            (item: string) => item
          )
          .onMove((from: number, to: number) => {
            this.dataSource.moveDataWithoutNotify(from, to)
            this.dragCount++
            this.resultText = `拖拽: ${from} → ${to}，累计 ${this.dragCount} 次`
          })
        }
        .width('90%')
        .height(300)
        .cachedCount(3)
        .borderRadius(8)
        .backgroundColor('#F0F0F0')
        .padding(6)

        // API 说明区
        Column() {
          Text('API 说明')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 8 })
          Text('拖拽排序通过 ListItem 的 onMove 事件实现')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('onMove(from, to) — 拖拽释放后触发')
            .fontSize(12)
            .fontColor('#999999')
            .fontFamily('monospace')
            .width('100%')
          Text('在 onMove 中直接修改 dataSource 数据')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('无需调用 DataChangeListener 通知更新')
            .fontSize(12)
            .fontColor('#FF6B00')
            .width('100%')
          Text('键值需保持不变，否则应使用删除+新增')
            .fontSize(12)
            .fontColor('#FF6B00')
            .width('100%')
          Text('元服务：onMove API 10+，LazyForEach API 11+')
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
