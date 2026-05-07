/**
 * repeat-template — Repeat 模板渲染
 * 展示 Repeat 使用 .template() + .templateId() 在同一数据源中渲染多种子组件
 * 元服务兼容性：template/templateId API 12+，元服务 API 12+ 可用
 */
import { BusinessError } from '@kit.BasicServicesKit'

interface ContactItem {
  id: string
  name: string
  type: 'vip' | 'normal' | 'new'
  avatar: string
}

@ComponentV2
export struct RepeatTemplate {
  @Local contactList: ContactItem[] = []
  @Local resultText: string = '模板渲染就绪'

  aboutToAppear(): void {
    const names = ['张三', '李四', '王五', '赵六', '钱七', '孙八', '周九', '吴十', '郑十一', '冯十二']
    const types: ('vip' | 'normal' | 'new')[] = ['vip', 'normal', 'new']
    for (let i = 0; i < 10; i++) {
      this.contactList.push({
        id: `contact_${i}`,
        name: names[i],
        type: types[i % 3],
        avatar: `${i}`
      })
    }
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('Repeat 模板渲染')
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
          Button('添加VIP')
            .fontSize(13)
            .width(80)
            .height(36)
            .backgroundColor('#E74C3C')
            .onClick(() => {
              try {
                const id = `vip_${Date.now()}`
                this.contactList.unshift({ id, name: `VIP用户${this.contactList.length}`, type: 'vip', avatar: 'v' })
                this.resultText = `添加VIP联系人，共 ${this.contactList.length} 项`
              } catch (err) {
                const e = err as BusinessError
                this.resultText = `添加失败: ${e.message}`
              }
            })
          Button('添加普通')
            .fontSize(13)
            .width(80)
            .height(36)
            .backgroundColor('#3498DB')
            .onClick(() => {
              try {
                const id = `normal_${Date.now()}`
                this.contactList.unshift({ id, name: `用户${this.contactList.length}`, type: 'normal', avatar: 'n' })
                this.resultText = `添加普通联系人，共 ${this.contactList.length} 项`
              } catch (err) {
                const e = err as BusinessError
                this.resultText = `添加失败: ${e.message}`
              }
            })
          Button('删除首个')
            .fontSize(13)
            .width(80)
            .height(36)
            .onClick(() => {
              try {
                if (this.contactList.length > 0) {
                  const removed = this.contactList.shift()
                  this.resultText = `删除: ${removed?.name}，剩余 ${this.contactList.length} 项`
                }
              } catch (err) {
                const e = err as BusinessError
                this.resultText = `删除失败: ${e.message}`
              }
            })
        }

        // 模板渲染列表
        Text('List + Repeat + template（VIP/普通/新人三种模板）')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        List({ space: 8 }) {
          Repeat<ContactItem>(this.contactList)
            .each((ri: RepeatItem<ContactItem>) => {
              ListItem() {
                Row() {
                  Text(ri.item.avatar)
                    .fontSize(14)
                    .fontColor('#999999')
                    .width(40)
                    .height(40)
                    .textAlign(TextAlign.Center)
                    .borderRadius(20)
                    .backgroundColor('#F0F0F0')
                  Text(`[默认] ${ri.item.name}`)
                    .fontSize(15)
                    .margin({ left: 12 })
                    .layoutWeight(1)
                }
                .width('100%')
                .padding(12)
                .backgroundColor('#F8F8F8')
                .borderRadius(6)
              }
            })
            .key((item: ContactItem) => item.id)
            .virtualScroll({ totalCount: this.contactList.length })
            .templateId((item: ContactItem) => item.type)
            .template('vip', (ri: RepeatItem<ContactItem>) => {
              ListItem() {
                Row() {
                  Text('V')
                    .fontSize(16)
                    .fontColor('#FFFFFF')
                    .width(40)
                    .height(40)
                    .textAlign(TextAlign.Center)
                    .borderRadius(20)
                    .backgroundColor('#E74C3C')
                  Column() {
                    Text(ri.item.name)
                      .fontSize(16)
                      .fontWeight(FontWeight.Bold)
                      .fontColor('#E74C3C')
                    Text('VIP 联系人')
                      .fontSize(12)
                      .fontColor('#E74C3C')
                      .margin({ top: 2 })
                  }
                  .alignItems(HorizontalAlign.Start)
                  .margin({ left: 12 })
                  .layoutWeight(1)
                  Text('VIP')
                    .fontSize(11)
                    .fontColor('#FFFFFF')
                    .padding({ left: 8, right: 8, top: 2, bottom: 2 })
                    .borderRadius(4)
                    .backgroundColor('#E74C3C')
                }
                .width('100%')
                .padding(12)
                .backgroundColor('#FFF5F5')
                .borderRadius(6)
                .border({ width: 1, color: '#E74C3C' })
              }
            }, { cachedCount: 3 })
            .template('normal', (ri: RepeatItem<ContactItem>) => {
              ListItem() {
                Row() {
                  Text('N')
                    .fontSize(16)
                    .fontColor('#FFFFFF')
                    .width(40)
                    .height(40)
                    .textAlign(TextAlign.Center)
                    .borderRadius(20)
                    .backgroundColor('#3498DB')
                  Text(ri.item.name)
                    .fontSize(15)
                    .margin({ left: 12 })
                    .layoutWeight(1)
                }
                .width('100%')
                .padding(12)
                .backgroundColor('#FFFFFF')
                .borderRadius(6)
              }
            }, { cachedCount: 3 })
            .template('new', (ri: RepeatItem<ContactItem>) => {
              ListItem() {
                Row() {
                  Text('+')
                    .fontSize(16)
                    .fontColor('#FFFFFF')
                    .width(40)
                    .height(40)
                    .textAlign(TextAlign.Center)
                    .borderRadius(20)
                    .backgroundColor('#27AE60')
                  Column() {
                    Text(ri.item.name)
                      .fontSize(15)
                      .fontWeight(FontWeight.Medium)
                    Text('新联系人')
                      .fontSize(12)
                      .fontColor('#27AE60')
                      .margin({ top: 2 })
                  }
                  .alignItems(HorizontalAlign.Start)
                  .margin({ left: 12 })
                  .layoutWeight(1)
                  Text('NEW')
                    .fontSize(11)
                    .fontColor('#27AE60')
                    .padding({ left: 8, right: 8, top: 2, bottom: 2 })
                    .borderRadius(4)
                    .backgroundColor('#E8F8F0')
                }
                .width('100%')
                .padding(12)
                .backgroundColor('#F0FFF5')
                .borderRadius(6)
              }
            }, { cachedCount: 3 })
        }
        .cachedCount(2)
        .width('90%')
        .height(350)
        .border({ width: 1, color: '#E0E0E0' })
        .borderRadius(8)

        // API 说明区
        Column() {
          Text('API 说明')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 8 })
          Text('.template(type: string, itemBuilder, options?)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('.templateId(typedFunc: (item, index) => string)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('.each() 等价于 type 为空字符串的 .template()')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text('相同 template type 的节点可互相复用')
            .fontSize(12)
            .fontColor('#FF6B00')
            .width('100%')
          Text('cachedCount: 模板缓存池大小，建议 >= 显示区域节点数')
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
