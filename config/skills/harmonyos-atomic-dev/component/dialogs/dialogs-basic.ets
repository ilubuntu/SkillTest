/**
 * dialogs-basic — 对话框基础用法
 * 展示 Toast、AlertDialog、ActionSheet、showDialog、showActionMenu、CustomDialog、openCustomDialog
 * 元服务兼容性：promptAction.showToast/showDialog/showActionMenu 从 API 11+ 可用
 *                AlertDialog/ActionSheet/CustomDialogController 从 API 8+ 可用
 */
import { promptAction } from '@kit.ArkUI'
import { BusinessError } from '@kit.BasicServicesKit'

@CustomDialog
struct CustomDialogExample {
  controller: CustomDialogController
  @State inputValue: string = ''

  build() {
    Column({ space: 16 }) {
      Text('自定义对话框')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
      TextInput({ placeholder: '请输入内容', text: this.inputValue })
        .width('80%')
        .onChange((value: string) => {
          this.inputValue = value
        })
      Row({ space: 12 }) {
        Button('取消')
          .onClick(() => {
            this.controller.close()
          })
        Button('确定')
          .onClick(() => {
            this.controller.close()
          })
      }
    }
    .padding(20)
  }
}

@ComponentV2
export struct DialogsAlert {
  @Local resultLog: string = '等待操作...'
  @Local toastDuration: number = 1500
  @Local customDialogController: CustomDialogController = new CustomDialogController({
    builder: CustomDialogExample(),
    alignment: DialogAlignment.Center,
    autoCancel: true
  })

  private appendLog(msg: string): void {
    const now = new Date()
    const time = `${now.getHours().toString().padStart(2, '0')}:${now.getMinutes().toString().padStart(2, '0')}:${now.getSeconds().toString().padStart(2, '0')}`
    this.resultLog = `[${time}] ${msg}\n${this.resultLog}`
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('Dialogs 对话框基础用法')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20, bottom: 10 })

        // 结果展示区
        Column() {
          Text(this.resultLog)
            .fontSize(13)
            .fontColor('#333333')
            .width('100%')
            .padding(12)
            .maxLines(10)
        }
        .width('90%')
        .backgroundColor('#F5F5F5')
        .borderRadius(8)
        .alignItems(HorizontalAlign.Start)

        // ---- 1. Toast 即时反馈 ----
        Text('1. Toast 即时反馈 (promptAction.showToast)')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        // 参数控制区
        Row({ space: 12 }) {
          Text(`持续时间: ${this.toastDuration}ms`)
            .fontSize(13)
            .fontColor('#666666')
          Button('+500ms')
            .fontSize(12)
            .onClick(() => {
              this.toastDuration = Math.min(this.toastDuration + 500, 10000)
            })
          Button('-500ms')
            .fontSize(12)
            .onClick(() => {
              this.toastDuration = Math.max(this.toastDuration - 500, 1500)
            })
        }
        .width('90%')
        .justifyContent(FlexAlign.Start)

        Row({ space: 12 }) {
          Button('显示 Toast')
            .fontSize(13)
            .onClick(() => {
              try {
                promptAction.showToast({
                  message: '这是一条 Toast 消息',
                  duration: this.toastDuration,
                  bottom: 100
                })
                this.appendLog('Toast 显示成功')
              } catch (error) {
                const err = error as BusinessError
                this.appendLog(`Toast 错误: code=${err.code}, msg=${err.message}`)
              }
            })
          Button('自定义位置 Toast')
            .fontSize(13)
            .backgroundColor('#FF6B00')
            .onClick(() => {
              try {
                promptAction.showToast({
                  message: '顶部 Toast',
                  duration: 2000,
                  alignment: Alignment.Top,
                  offset: { dx: 0, dy: 50 }
                })
                this.appendLog('自定义位置 Toast 显示')
              } catch (error) {
                const err = error as BusinessError
                this.appendLog(`Toast 错误: code=${err.code}`)
              }
            })
        }
        .width('90%')
        .justifyContent(FlexAlign.Center)

        // ---- 2. AlertDialog 警告对话框 ----
        Text('2. AlertDialog 警告对话框')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 12 })

        Row({ space: 12 }) {
          Button('单按钮 Alert')
            .fontSize(13)
            .onClick(() => {
              try {
                AlertDialog.show({
                  title: '提示',
                  message: '这是一个警告对话框',
                  confirm: {
                    value: '确定',
                    action: () => {
                      this.appendLog('AlertDialog — 用户点击了确定')
                    }
                  },
                  cancel: () => {
                    this.appendLog('AlertDialog — 用户取消了对话框')
                  }
                })
                this.appendLog('AlertDialog 已弹出')
              } catch (error) {
                const err = error as BusinessError
                this.appendLog(`AlertDialog 错误: code=${err.code}`)
              }
            })

          Button('双按钮 Alert')
            .fontSize(13)
            .backgroundColor('#FF6B00')
            .onClick(() => {
              try {
                AlertDialog.show({
                  title: '确认操作',
                  message: '确定要执行此操作吗？此操作不可撤销。',
                  primaryButton: {
                    value: '取消',
                    action: () => {
                      this.appendLog('双按钮 Alert — 取消')
                    }
                  },
                  secondaryButton: {
                    value: '确认',
                    action: () => {
                      this.appendLog('双按钮 Alert — 确认')
                    }
                  },
                  alignment: DialogAlignment.Center,
                  autoCancel: true
                })
                this.appendLog('双按钮 AlertDialog 已弹出')
              } catch (error) {
                const err = error as BusinessError
                this.appendLog(`AlertDialog 错误: code=${err.code}`)
              }
            })
        }
        .width('90%')
        .justifyContent(FlexAlign.Center)

        // ---- 3. ActionSheet 操作列表 ----
        Text('3. ActionSheet 操作列表')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 12 })

        Row({ space: 12 }) {
          Button('显示 ActionSheet')
            .fontSize(13)
            .onClick(() => {
              try {
                ActionSheet.show({
                  title: '选择操作',
                  message: '请选择以下操作之一',
                  confirm: {
                    value: '取消',
                    action: () => {
                      this.appendLog('ActionSheet — 取消')
                    }
                  },
                  sheets: [
                    { title: '拍照', action: () => { this.appendLog('ActionSheet — 拍照') } },
                    { title: '从相册选择', action: () => { this.appendLog('ActionSheet — 从相册选择') } },
                    { title: '删除', action: () => { this.appendLog('ActionSheet — 删除') } }
                  ]
                })
                this.appendLog('ActionSheet 已弹出')
              } catch (error) {
                const err = error as BusinessError
                this.appendLog(`ActionSheet 错误: code=${err.code}`)
              }
            })
        }
        .width('90%')
        .justifyContent(FlexAlign.Center)

        // ---- 4. promptAction.showDialog ----
        Text('4. promptAction.showDialog 对话框')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 12 })

        Row({ space: 12 }) {
          Button('showDialog')
            .fontSize(13)
            .onClick(() => {
              try {
                promptAction.showDialog({
                  title: '提示',
                  message: '这是通过 promptAction.showDialog 显示的对话框',
                  buttons: [
                    { text: '取消', color: '#999999' },
                    { text: '确定', color: '#007DFF' }
                  ]
                }).then((result: promptAction.ShowDialogSuccessResponse) => {
                  this.appendLog(`showDialog — 选中按钮索引: ${result.index}`)
                }).catch((error: BusinessError) => {
                  this.appendLog(`showDialog 错误: code=${error.code}`)
                })
              } catch (error) {
                const err = error as BusinessError
                this.appendLog(`showDialog 异常: code=${err.code}`)
              }
            })
        }
        .width('90%')
        .justifyContent(FlexAlign.Center)

        // ---- 5. promptAction.showActionMenu ----
        Text('5. promptAction.showActionMenu 操作菜单')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 12 })

        Row({ space: 12 }) {
          Button('showActionMenu')
            .fontSize(13)
            .onClick(() => {
              try {
                promptAction.showActionMenu({
                  title: '操作菜单标题',
                  buttons: [
                    { text: '选项一', color: '#333333' },
                    { text: '选项二', color: '#333333' },
                    { text: '选项三', color: '#333333' },
                    { text: '取消', color: '#999999' }
                  ]
                }).then((result: promptAction.ActionMenuSuccessResponse) => {
                  this.appendLog(`ActionMenu — 选中: 索引${result.index}`)
                }).catch((error: BusinessError) => {
                  this.appendLog(`ActionMenu 错误: code=${error.code}`)
                })
              } catch (error) {
                const err = error as BusinessError
                this.appendLog(`ActionMenu 异常: code=${err.code}`)
              }
            })
        }
        .width('90%')
        .justifyContent(FlexAlign.Center)

        // ---- 6. CustomDialogController 自定义对话框 ----
        Text('6. CustomDialogController 自定义对话框')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 12 })

        Row({ space: 12 }) {
          Button('打开自定义对话框')
            .fontSize(13)
            .onClick(() => {
              try {
                this.customDialogController.open()
                this.appendLog('CustomDialog 已打开')
              } catch (error) {
                const err = error as BusinessError
                this.appendLog(`CustomDialog 错误: code=${err.code}`)
              }
            })
        }
        .width('90%')
        .justifyContent(FlexAlign.Center)

        // ---- 7. openCustomDialog (promptAction) ----
        Text('7. openCustomDialog (promptAction 方式)')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 12 })

        Row({ space: 12 }) {
          Button('openCustomDialog')
            .fontSize(13)
            .onClick(() => {
              try {
                this.getUIContext().getPromptAction().openCustomDialog({
                  builder: (): void => {
                    this.customDialogBuilder()
                  },
                  autoCancel: true,
                  alignment: DialogAlignment.Bottom,
                  offset: { dx: 0, dy: -20 }
                }).then((dialogId: number) => {
                  this.appendLog(`openCustomDialog 成功, id=${dialogId}`)
                }).catch((error: BusinessError) => {
                  this.appendLog(`openCustomDialog 错误: code=${error.code}`)
                })
              } catch (error) {
                const err = error as BusinessError
                this.appendLog(`openCustomDialog 异常: code=${err.code}`)
              }
            })
        }
        .width('90%')
        .justifyContent(FlexAlign.Center)

        // API 说明区
        Column() {
          Text('API 说明')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 8 })
          Text('可用 API (元服务 API 11+):')
            .fontSize(12)
            .fontColor('#00B578')
            .fontWeight(FontWeight.Medium)
            .width('100%')
          Text('  promptAction.showToast — 即时反馈')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('  promptAction.showDialog — 按钮对话框')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('  promptAction.showActionMenu — 操作菜单')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('  AlertDialog.show — 警告对话框 (API 8+)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('  ActionSheet.show — 操作列表 (API 8+)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('  CustomDialogController — 自定义对话框 (API 8+)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('  openCustomDialog — 自定义弹窗 (API 12+)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('ShowToastOptions: message/duration/bottom/alignment/offset/showMode')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('  backgroundColor/textColor/backgroundBlurStyle/shadow (API 12+)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('元服务API: showToast/showDialog/showActionMenu 从 API 11+')
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

  @Builder
  customDialogBuilder(): void {
    Column({ space: 12 }) {
      Text('通过 openCustomDialog 创建')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
      Text('这是一个使用 promptAction.openCustomDialog 打开的自定义弹窗')
        .fontSize(14)
        .fontColor('#666666')
      Row({ space: 12 }) {
        Button('关闭')
          .fontSize(13)
          .onClick(() => {
            this.getUIContext().getPromptAction().closeCustomDialog(0)
            this.appendLog('openCustomDialog 已关闭')
          })
      }
    }
    .padding(20)
    .backgroundColor(Color.White)
    .borderRadius(16)
  }
}
