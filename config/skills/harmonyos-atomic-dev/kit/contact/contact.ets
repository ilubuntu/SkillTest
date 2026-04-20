import common from '@ohos.app.ability.common';
import abilityAccessCtrl, { Permissions } from '@ohos.abilityAccessCtrl';
import contact from '@ohos.contact';

@ComponentV2
export struct ContactExample {

  addContactByPermissions() {
    let context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    // WRITE_CONTACTS 需要单独申请权限
    const permissions: Array<Permissions> = ['ohos.permission.WRITE_CONTACTS'];
    const contactInfo: contact.Contact = {
      name: { fullName: '王小明' },
      phoneNumbers: [{ phoneNumber: '13912345678' }]
    }

    abilityAccessCtrl.createAtManager().requestPermissionsFromUser(context, permissions).then(() => {
      try {
        contact.addContact(context, contactInfo, (err, data) => {
          if (err) {
            console.log('addContact callback: err->' + JSON.stringify(err));
            return;
          }
          console.log('addContact callback: data->' + JSON.stringify(data));
        })
      } catch (err) {
        console.error('errCode: ' + err.code + ', errMessage: ' + err.message);
      }
    })
  }

  build() {
    Row() {
      Column() {
        Button('添加联系人')
          .onClick(() => {
            this.addContactByPermissions();
          })

        Button('打开联系人窗口')
          .onClick(() => {
            contact.selectContacts({
              isMultiSelect:false
            },(err: BusinessError, data) => {
              if (err) {
                console.error(`selectContact callback: err->${JSON.stringify(err)}`);
                return;
              }
              console.log(`selectContact callback: success data->${JSON.stringify(data)}`);
            });
          })
      }
      .width('100%')
    }
    .height('100%')
  }
}