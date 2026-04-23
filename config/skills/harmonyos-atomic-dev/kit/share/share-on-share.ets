/**
 * share-on-share — 元服务页面分享（onShare 生命周期）
 * UIAbility.onShare(wantParams) — 从 API version 10 起支持，元服务从 API 20 起支持
 * 通过服务面板入口分享当前元服务页面
 */
import { common } from '@kit.AbilityKit'
import { BusinessError } from '@kit.BasicServicesKit'

@ComponentV2
export struct ShareOnShare {
  @Local resultText: string = '等待操作'
  @Local shareTitle: string = '我的元服务页面'
  @Local shareDescription: string = '这是一个精彩的元服务内容'
  @Local showShareMenu: boolean = true

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('元服务页面分享')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20, bottom: 10 })

        Text('UIAbility.onShare(wantParams) — 通过服务面板分享页面')
          .fontSize(13)
          .fontColor('#666666')
          .width('90%')
          .textAlign(TextAlign.Center)

        // 结果展示
        Column({ space: 8 }) {
          Text('执行结果')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .width('100%')
          Text(this.resultText)
            .fontSize(13)
            .fontColor(this.resultText.includes('成功') ? '#00B578' :
              (this.resultText.includes('失败') || this.resultText.includes('错误') ? '#E84026' : '#333333'))
            .width('100%')
        }
        .width('90%')
        .padding(16)
        .backgroundColor('#F5F5F5')
        .borderRadius(12)
        .alignItems(HorizontalAlign.Start)

        // 参数控制区
        Text('分享参数配置')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Column({ space: 12 }) {
          Row() {
            Text('分享标题:')
              .fontSize(14)
              .width(80)
            TextInput({ text: this.shareTitle, placeholder: '分享标题' })
              .layoutWeight(1)
              .onChange((value: string) => {
                this.shareTitle = value
              })
          }
          .width('100%')

          Row() {
            Text('分享描述:')
              .fontSize(14)
              .width(80)
            TextInput({ text: this.shareDescription, placeholder: '分享描述' })
              .layoutWeight(1)
              .onChange((value: string) => {
                this.shareDescription = value
              })
          }
          .width('100%')

          Row() {
            Text('允许分享:')
              .fontSize(14)
              .width(80)
            Toggle({ type: ToggleType.Switch, isOn: this.showShareMenu })
              .onChange((isOn: boolean) => {
                this.showShareMenu = isOn
              })
          }
          .width('100%')
        }
        .width('90%')
        .padding(12)
        .backgroundColor('#F9F9F9')
        .borderRadius(8)

        // 操作按钮
        Button('模拟配置 onShare 参数')
          .width('90%')
          .backgroundColor('#007DFF')
          .borderRadius(8)
          .onClick(() => this.configureShareParams())

        Button('查看 ShareInfo 结构')
          .width('90%')
          .backgroundColor('#00B578')
          .borderRadius(8)
          .onClick(() => this.showShareInfoStructure())

        // 使用说明
        Column({ space: 8 }) {
          Text('使用说明')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
          Text('1. onShare 回调在 UIAbility 中配置，不是在页面组件中')
            .fontSize(12)
            .fontColor('#666666')
          Text('2. 在 EntryAbility.ets 中重写 onShare 方法')
            .fontSize(12)
            .fontColor('#666666')
          Text('3. 设置 wantParams["atomicservice.param.key.shareInfo"]')
            .fontSize(12)
            .fontColor('#666666')
          Text('4. showShareMenu 控制是否允许从面板分享当前页面')
            .fontSize(12)
            .fontColor('#666666')
          Text('5. 依赖 Navigation 组件实现分页能力')
            .fontSize(12)
            .fontColor('#666666')
        }
        .width('90%')
        .padding(12)
        .backgroundColor('#FFF8E1')
        .borderRadius(8)
        .alignItems(HorizontalAlign.Start)

        // API 说明
        Text('API 说明')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Column({ space: 4 }) {
          Text('// EntryAbility.ets 中配置')
            .fontSize(12)
            .fontColor('#999999')
            .fontFamily('monospace')
          Text('onShare(wantParams: Record<string, Object>) {')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('  wantParams["atomicservice.param.key.shareInfo"] = {')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('    showShareMenu: true,')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('    title: "页面标题",')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('    description: "页面描述",')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('    previewUri: ""  // 预留字段')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('  }')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('}')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('')
            .fontSize(8)
          Text('interface ShareInfo {')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('  showShareMenu: boolean  // 是否允许分享')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('  title?: string          // 分享标题')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('  description?: string    // 分享描述')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('  previewUri?: string     // 缩略图URI（预留）')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('}')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('')
            .fontSize(8)
          Text('元服务API: 从 API version 20 起支持')
            .fontSize(12)
            .fontColor('#00B578')
            .fontWeight(FontWeight.Medium)
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

  private configureShareParams(): void {
    try {
      const shareInfo: Record<string, Object> = {
        'showShareMenu': this.showShareMenu,
        'title': this.shareTitle,
        'description': this.shareDescription,
        'previewUri': ''
      }
      this.resultText = `ShareInfo 配置完成:\n` +
        `  showShareMenu: ${shareInfo['showShareMenu']}\n` +
        `  title: ${shareInfo['title']}\n` +
        `  description: ${shareInfo['description']}\n` +
        `\n注意: 需在 EntryAbility.ets 的 onShare 回调中设置 wantParams["atomicservice.param.key.shareInfo"]`
    } catch (error) {
      const err = error as BusinessError
      this.resultText = `配置失败: [${err.code}] ${err.message}`
    }
  }

  private showShareInfoStructure(): void {
    this.resultText = `ShareInfo 数据结构:\n` +
      `{ showShareMenu: boolean }  — 必填，是否允许分享\n` +
      `{ title?: string }          — 可选，默认为元服务名称\n` +
      `{ description?: string }    — 可选，默认为元服务一句话描述\n` +
      `{ previewUri?: string }     — 可选，预留字段暂不起作用\n` +
      `\n存储键名: "atomicservice.param.key.shareInfo"\n` +
      `结构: Record<string, ShareInfo>`
  }
}
