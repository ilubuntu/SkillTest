/**
 * contacts-picker — 联系人选择器
 * contact.selectContacts() 拉起系统联系人选择界面
 * 元服务API: 从API version 11开始支持在元服务中使用
 * 无需特殊权限，通过系统UI让用户选择联系人
 */
import { contact } from '@kit.ContactsKit'
import { BusinessError } from '@kit.BasicServicesKit'

@ComponentV2
export struct ContactsPicker {
  @Local resultText: string = '点击按钮选择联系人'
  @Local selectedContacts: string = '--'
  @Local isMultiSelect: boolean = false

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('联系人选择器 (Contact Picker)')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20, bottom: 10 })

        Text('contact.selectContacts() 拉起系统联系人选择界面')
          .fontSize(13)
          .fontColor('#666666')
          .width('90%')
          .textAlign(TextAlign.Center)

        // 结果展示
        Column({ space: 8 }) {
          Text('选择结果')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .width('100%')
          Text(this.resultText)
            .fontSize(13)
            .fontColor(this.resultText.includes('成功') ? '#00B578' :
              (this.resultText.includes('失败') || this.resultText.includes('错误') ? '#E84026' : '#333333'))
            .width('100%')
          Text(this.selectedContacts)
            .fontSize(12)
            .fontColor('#666666')
            .width('100%')
            .maxLines(8)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .width('90%')
        .padding(16)
        .backgroundColor('#F5F5F5')
        .borderRadius(12)
        .alignItems(HorizontalAlign.Start)

        // 参数控制 - 多选/单选
        Text('选择模式')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Row({ space: 8 }) {
          Button('单选')
            .layoutWeight(1)
            .backgroundColor(!this.isMultiSelect ? '#007DFF' : '#CCCCCC')
            .borderRadius(8)
            .onClick(() => { this.isMultiSelect = false })
          Button('多选')
            .layoutWeight(1)
            .backgroundColor(this.isMultiSelect ? '#007DFF' : '#CCCCCC')
            .borderRadius(8)
            .onClick(() => { this.isMultiSelect = true })
        }
        .width('90%')

        // 操作按钮
        Button('选择联系人')
          .width('80%')
          .backgroundColor('#007DFF')
          .borderRadius(8)
          .onClick(() => this.doSelect())

        // 提示信息
        Column() {
          Text('注意事项')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 4 })
          Text('1. 无需申请权限，通过系统UI让用户主动选择')
            .fontSize(12)
            .fontColor('#996600')
            .width('100%')
          Text('2. 用户可取消选择操作（错误码 16700103）')
            .fontSize(12)
            .fontColor('#996600')
            .width('100%')
          Text('3. ContactSelectionOptions.isMultiSelect 控制单选/多选')
            .fontSize(12)
            .fontColor('#996600')
            .width('100%')
        }
        .width('90%')
        .backgroundColor('#FFF3CD')
        .borderRadius(8)
        .padding(12)

        // API 说明
        Text('API 说明')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Column({ space: 4 }) {
          Text('import { contact } from "@kit.ContactsKit"')
            .fontSize(12)
            .fontColor('#007DFF')
            .fontFamily('monospace')
          Text('')
            .fontSize(8)
          Text('// 基本选择（无筛选条件）')
            .fontSize(12)
            .fontColor('#999999')
            .fontFamily('monospace')
          Text('contact.selectContacts(): Promise<Array<Contact>>')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('')
            .fontSize(8)
          Text('// 带筛选条件选择')
            .fontSize(12)
            .fontColor('#999999')
            .fontFamily('monospace')
          Text('contact.selectContacts(options): Promise<Array<Contact>>')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('')
            .fontSize(8)
          Text('// ContactSelectionOptions:')
            .fontSize(12)
            .fontColor('#999999')
            .fontFamily('monospace')
          Text('{ isMultiSelect?: boolean, maxSelectable?: number }')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('')
            .fontSize(8)
          Text('元服务API: 从API version 11开始支持')
            .fontSize(12)
            .fontColor('#00B578')
            .fontWeight(FontWeight.Medium)
          Text('无需权限 | SystemCapability.Applications.Contacts')
            .fontSize(12)
            .fontColor('#00B578')
        }
        .alignItems(HorizontalAlign.Start)
        .margin({ left: 16, bottom: 20 })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
  }

  private doSelect(): void {
    try {
      this.resultText = '等待用户选择...'
      this.selectedContacts = '--'

      let options: contact.ContactSelectionOptions = {
        isMultiSelect: this.isMultiSelect
      }

      contact.selectContacts(options).then((data: Array<contact.Contact>) => {
        if (data && data.length > 0) {
          this.resultText = `成功选择 ${data.length} 个联系人`
          let details: string[] = []
          data.forEach((c: contact.Contact, index: number) => {
            let name = c.name?.fullName ?? '未知'
            let phones = c.phoneNumbers?.map(p => p.phoneNumber).join(', ') ?? '无号码'
            details.push(`[${index + 1}] ${name} - ${phones}`)
          })
          this.selectedContacts = details.join('\n')
        } else {
          this.resultText = '未选择任何联系人'
          this.selectedContacts = '返回数据为空'
        }
      }).catch((error: BusinessError) => {
        this.resultText = `选择失败: [${error.code}] ${error.message}`
      })
    } catch (error) {
      const err = error as BusinessError
      this.resultText = `选择异常: [${err.code}] ${err.message}`
    }
  }
}
