/**
 * account-kit-login-state — 获取华为账号登录状态
 * HuaweiIDProvider.getHuaweiIDState
 * 元服务API: 从版本 5.0.0(12) 起支持
 */
import { authentication } from '@kit.AccountKit'
import { BusinessError } from '@kit.BasicServicesKit'

@ComponentV2
export struct AccountKitLoginState {
  @Local resultText: string = '点击下方按钮查询登录状态'
  @Local loginState: string = '--'
  @Local stateDesc: string = '--'
  @Local isQuerying: boolean = false
  @Local inputIdValue: string = ''
  @Local selectedIdType: string = 'UNION_ID'

  private readonly ID_TYPE_OPTIONS: string[] = ['UNION_ID', 'OPEN_ID']

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('华为账号登录状态查询')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20, bottom: 10 })

        Text('HuaweiIDProvider.getHuaweiIDState')
          .fontSize(13)
          .fontColor('#666666')
          .width('90%')
          .textAlign(TextAlign.Center)

        // 结果展示卡片
        Column({ space: 8 }) {
          Row() {
            Text('登录状态: ')
              .fontSize(14)
              .fontColor('#999999')
            Text(this.loginState)
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
          }
          .width('100%')

          Row() {
            Text('状态描述: ')
              .fontSize(14)
              .fontColor('#999999')
            Text(this.stateDesc)
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .layoutWeight(1)
              .maxLines(3)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .width('100%')

          Text(this.resultText)
            .fontSize(13)
            .fontColor(this.resultText.includes('成功') ? '#00B578' : '#E84026')
            .width('100%')
        }
        .width('90%')
        .padding(16)
        .backgroundColor('#F5F5F5')
        .borderRadius(12)
        .alignItems(HorizontalAlign.Start)

        // 参数控制区
        Text('参数控制')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Text('ID 类型')
          .fontSize(14)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16 })

        Row({ space: 8 }) {
          ForEach(this.ID_TYPE_OPTIONS, (idType: string) => {
            Button(idType)
              .fontSize(13)
              .height(36)
              .backgroundColor(this.selectedIdType === idType ? '#007DFF' : '#CCCCCC')
              .borderRadius(8)
              .onClick(() => {
                this.selectedIdType = idType
              })
          }, (idType: string) => idType)
        }

        Text('ID 值 (UnionID 或 OpenID)')
          .fontSize(14)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        TextInput({ placeholder: '请输入 UnionID 或 OpenID', text: this.inputIdValue })
          .width('90%')
          .borderRadius(8)
          .onChange((value: string) => {
            this.inputIdValue = value
          })

        // 操作按钮
        Button(this.isQuerying ? '查询中...' : '查询登录状态')
          .width('80%')
          .backgroundColor('#00B578')
          .borderRadius(8)
          .enabled(!this.isQuerying)
          .onClick(() => {
            this.doGetLoginState()
          })

        // API 说明
        Text('API 说明')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Column({ space: 4 }) {
          Text('getHuaweiIDState(request: StateRequest): Promise<StateResult>')
            .fontSize(12)
            .fontColor('#007DFF')
            .fontFamily('monospace')
          Text('StateRequest:')
            .fontSize(12)
            .fontColor('#333333')
            .fontWeight(FontWeight.Medium)
          Text('  idType: IdType (UNION_ID | OPEN_ID)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('  idValue: string')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('')
            .fontSize(8)
          Text('State 枚举:')
            .fontSize(12)
            .fontColor('#333333')
            .fontWeight(FontWeight.Medium)
          Text('  UNLOGGED_IN(0) / AUTHORIZED(1) / UNAUTHORIZED(2)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('')
            .fontSize(8)
          Text('此接口不依赖网络连接，可在本地判断登录状态')
            .fontSize(12)
            .fontColor('#00B578')
          Text('元服务API: 从版本 5.0.0(12) 起支持')
            .fontSize(12)
            .fontColor('#E84026')
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

  /**
   * 查询登录状态
   */
  private doGetLoginState(): void {
    if (!this.inputIdValue.trim()) {
      this.resultText = '请输入 ID 值'
      return
    }
    this.isQuerying = true
    this.resultText = '正在查询...'
    try {
      const idType = this.selectedIdType === 'UNION_ID'
        ? authentication.IdType.UNION_ID
        : authentication.IdType.OPEN_ID
      const stateRequest: authentication.StateRequest = {
        idType: idType,
        idValue: this.inputIdValue.trim()
      }
      const provider = new authentication.HuaweiIDProvider()
      provider.getHuaweiIDState(stateRequest).then((result: authentication.StateResult) => {
        this.isQuerying = false
        this.loginState = `${result.state}`
        this.stateDesc = this.getStateDescription(result.state)
        this.resultText = '查询成功'
      }).catch((error: BusinessError) => {
        this.isQuerying = false
        this.resultText = this.getErrorMessage(error.code, error.message)
      })
    } catch (error) {
      this.isQuerying = false
      this.resultText = `查询异常: ${error.message}`
    }
  }

  /**
   * 获取状态描述
   */
  private getStateDescription(state: authentication.State): string {
    if (state === authentication.State.UNLOGGED_IN) {
      return '华为账号未登录'
    } else if (state === authentication.State.AUTHORIZED) {
      return '已登录，且传入ID与当前账号一致'
    } else if (state === authentication.State.UNAUTHORIZED) {
      return '已登录，但传入ID与当前账号不一致'
    }
    return `未知状态 (${state})`
  }

  private getErrorMessage(code: number, msg: string): string {
    if (code === 12300001) {
      return '系统服务异常'
    } else if (code === 1001502003) {
      return '参数无效，请检查 ID 值'
    }
    return `查询失败: [${code}] ${msg}`
  }
}
