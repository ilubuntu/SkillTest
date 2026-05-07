/**
 * contacts-add-via-ui — 通过系统UI新建联系人
 * contact.addContactViaUI() 拉起新建联系人界面
 * 元服务API: 从API version 15开始支持在元服务中使用
 * 无需特殊权限，通过系统UI让用户确认创建
 */
import { contact } from '@kit.ContactsKit'
import { common } from '@kit.AbilityKit'
import { BusinessError } from '@kit.BasicServicesKit'

@ComponentV2
export struct ContactsAddViaUI {
  @Local resultText: string = '点击按钮新建联系人'
  @Local resultId: string = '--'
  @Local inputName: string = '张三'
  @Local inputPhone: string = '13800138000'

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('新建联系人 (Add Contact Via UI)')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20, bottom: 10 })

        Text('contact.addContactViaUI() 拉起系统新建联系人界面')
          .fontSize(13)
          .fontColor('#666666')
          .width('90%')
          .textAlign(TextAlign.Center)

        // 结果展示
        Column({ space: 8 }) {
          Text('操作结果')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .width('100%')
          Text(this.resultText)
            .fontSize(13)
            .fontColor(this.resultText.includes('成功') ? '#00B578' :
              (this.resultText.includes('失败') || this.resultText.includes('错误') ? '#E84026' : '#333333'))
            .width('100%')
          Row() {
            Text('联系人ID: ')
              .fontSize(12)
              .fontColor('#999999')
            Text(this.resultId)
              .fontSize(12)
              .layoutWeight(1)
          }
          .width('100%')
        }
        .width('90%')
        .padding(16)
        .backgroundColor('#F5F5F5')
        .borderRadius(12)
        .alignItems(HorizontalAlign.Start)

        // 参数控制 - 联系人姓名
        Text('预设联系人信息')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Column({ space: 8 }) {
          Row() {
            Text('姓名: ')
              .fontSize(14)
              .width(60)
            TextInput({ text: this.inputName, placeholder: '输入姓名' })
              .layoutWeight(1)
              .onChange((value: string) => { this.inputName = value })
          }
          .width('100%')

          Row() {
            Text('电话: ')
              .fontSize(14)
              .width(60)
            TextInput({ text: this.inputPhone, placeholder: '输入电话号码' })
              .layoutWeight(1)
              .type(InputType.PhoneNumber)
              .onChange((value: string) => { this.inputPhone = value })
          }
          .width('100%')
        }
        .width('90%')
        .padding(16)
        .backgroundColor('#FFFFFF')
        .borderRadius(12)
        .border({ width: 1, color: '#E0E0E0' })

        // 操作按钮
        Button('新建联系人')
          .width('80%')
          .backgroundColor('#007DFF')
          .borderRadius(8)
          .onClick(() => this.doAdd())

        // 提示信息
        Column() {
          Text('注意事项')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 4 })
          Text('1. 预设的姓名和号码会填充到系统UI中，用户可修改')
            .fontSize(12)
            .fontColor('#996600')
            .width('100%')
          Text('2. 用户取消操作时返回错误码 16700103')
            .fontSize(12)
            .fontColor('#996600')
            .width('100%')
          Text('3. 此API无需申请权限，由系统UI代理操作')
            .fontSize(12)
            .fontColor('#996600')
            .width('100%')
          Text('4. 需要 API version 15+')
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
          Text('import { common } from "@kit.AbilityKit"')
            .fontSize(12)
            .fontColor('#007DFF')
            .fontFamily('monospace')
          Text('')
            .fontSize(8)
          Text('contact.addContactViaUI(context, contact)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('  : Promise<number>  // 返回新建联系人ID')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('')
            .fontSize(8)
          Text('// 错误码:')
            .fontSize(12)
            .fontColor('#999999')
            .fontFamily('monospace')
          Text('// 401 参数错误 | 801 SystemCapability未找到')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('// 16700001 通用错误 | 16700102 数据设置失败')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('// 16700103 用户取消')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('')
            .fontSize(8)
          Text('元服务API: 从API version 15开始支持')
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

  private doAdd(): void {
    try {
      let context = getContext(this) as common.Context
      this.resultText = '正在打开新建联系人界面...'
      this.resultId = '--'

      let contactInfo: contact.Contact = {
        name: {
          fullName: this.inputName
        },
        phoneNumbers: [{
          phoneNumber: this.inputPhone
        }]
      }

      contact.addContactViaUI(context, contactInfo).then((data: number) => {
        this.resultText = `成功创建联系人`
        this.resultId = String(data)
      }).catch((error: BusinessError) => {
        if (error.code === 16700103) {
          this.resultText = '用户取消了操作'
        } else {
          this.resultText = `创建失败: [${error.code}] ${error.message}`
        }
      })
    } catch (error) {
      const err = error as BusinessError
      this.resultText = `创建异常: [${err.code}] ${err.message}`
    }
  }
}
