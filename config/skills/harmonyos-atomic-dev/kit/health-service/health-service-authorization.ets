/**
 * health-service-authorization — 运动健康数据授权管理
 * 元服务API：healthStore.requestAuthorizations / getAuthorizations / cancelAuthorizations 从 5.0.0(12) 起支持
 * 调用前需先使用 healthStore.init() 进行初始化
 */

import { healthStore } from '@kit.HealthServiceKit'
import { common } from '@kit.AbilityKit'
import { BusinessError } from '@kit.BasicServicesKit'

@ComponentV2
export struct HealthServiceAuthorization {
  @Local resultText: string = '等待操作...'
  @Local isInit: boolean = false
  @Local readDataTypes: string = '--'
  @Local writeDataTypes: string = '--'
  @Local authStatus: string = '未授权'

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('健康数据授权管理')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20, bottom: 10 })

        Text('管理运动健康数据的读写权限，包括申请授权、查询授权状态、取消授权')
          .fontSize(13)
          .fontColor('#666666')
          .width('90%')
          .textAlign(TextAlign.Center)

        // 初始化状态
        Row() {
          Text('初始化状态:')
            .fontSize(13)
            .fontWeight(FontWeight.Medium)
          Text(this.isInit ? '已初始化' : '未初始化')
            .fontSize(13)
            .fontColor(this.isInit ? '#00B578' : '#E84026')
            .fontWeight(FontWeight.Medium)
        }
        .width('90%')

        // 授权状态
        Row() {
          Text('授权状态:')
            .fontSize(13)
            .fontWeight(FontWeight.Medium)
          Text(this.authStatus)
            .fontSize(13)
            .fontColor(this.authStatus === '已授权' ? '#00B578' : '#E84026')
            .fontWeight(FontWeight.Medium)
        }
        .width('90%')

        // 操作按钮
        Column({ space: 8 }) {
          Button('1. 初始化 HealthStore')
            .fontSize(13)
            .borderRadius(8)
            .width('90%')
            .onClick(() => this.initHealthStore())

          Row({ space: 12 }) {
            Button('2. 申请授权')
              .fontSize(13)
              .borderRadius(8)
              .enabled(this.isInit)
              .onClick(() => this.requestAuth())

            Button('3. 查询授权')
              .fontSize(13)
              .borderRadius(8)
              .enabled(this.isInit)
              .onClick(() => this.getAuth())
          }
          .width('90%')
          .justifyContent(FlexAlign.Center)

          Button('4. 取消授权')
            .fontSize(13)
            .borderRadius(8)
            .width('90%')
            .backgroundColor('#E84026')
            .enabled(this.isInit)
            .onClick(() => this.cancelAuth())
        }
        .width('90%')
        .alignItems(HorizontalAlign.Center)

        // 结果展示
        Column({ space: 8 }) {
          Text('操作结果:')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .width('100%')
          Text(this.resultText)
            .fontSize(13)
            .fontColor(this.resultText.startsWith('成功') ? '#00B578' : '#E84026')
            .width('100%')
        }
        .width('90%')
        .padding(12)
        .backgroundColor('#F5F5F5')
        .borderRadius(12)
        .alignItems(HorizontalAlign.Start)

        // 授权信息
        Column({ space: 8 }) {
          Text('当前授权详情')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')

          Row() {
            Text('可读数据类型:')
              .fontSize(12)
              .fontWeight(FontWeight.Medium)
              .layoutWeight(1)
            Text(this.readDataTypes)
              .fontSize(12)
              .fontColor('#007DFF')
          }
          .width('100%')

          Row() {
            Text('可写数据类型:')
              .fontSize(12)
              .fontWeight(FontWeight.Medium)
              .layoutWeight(1)
            Text(this.writeDataTypes)
              .fontSize(12)
              .fontColor('#00B578')
          }
          .width('100%')
        }
        .width('90%')
        .padding(16)
        .backgroundColor('#FFFFFF')
        .borderRadius(12)
        .border({ width: 1, color: '#E0E0E0' })
        .alignItems(HorizontalAlign.Start)

        // 注意事项
        Column({ space: 6 }) {
          Text('注意事项')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
          Text('1. 调用前需先通过 healthStore.init(context) 初始化')
            .fontSize(12)
            .fontColor('#666666')
            .width('100%')
          Text('2. requestAuthorizations 需要 UIAbilityContext')
            .fontSize(12)
            .fontColor('#666666')
            .width('100%')
          Text('3. 用户未登录华为账号时会返回 1002702001 错误')
            .fontSize(12)
            .fontColor('#666666')
            .width('100%')
          Text('4. 用户未同意隐私协议时会返回 1002703001 错误')
            .fontSize(12)
            .fontColor('#666666')
            .width('100%')
          Text('5. 取消授权后需重新申请才能访问健康数据')
            .fontSize(12)
            .fontColor('#666666')
            .width('100%')
        }
        .width('90%')
        .padding(12)
        .backgroundColor('#FFF3CD')
        .borderRadius(12)
        .alignItems(HorizontalAlign.Start)

        // API 说明
        Column({ space: 4 }) {
          Text('API 说明')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 8 })
          Text('import { healthStore } from "@kit.HealthServiceKit"')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('')
            .fontSize(8)
          Text('// 申请授权')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('const response = await healthStore.requestAuthorizations(')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('  context, { readDataTypes: [...], writeDataTypes: [...] }')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text(')')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('')
            .fontSize(8)
          Text('// 查询已授权的类型')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('const auth = await healthStore.getAuthorizations(request)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('')
            .fontSize(8)
          Text('// 取消授权')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('await healthStore.cancelAuthorizations()')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
        }
        .width('90%')
        .backgroundColor('#F5F5F5')
        .borderRadius(12)
        .padding(12)
        .alignItems(HorizontalAlign.Start)
        .margin({ bottom: 20 })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
  }

  private initHealthStore(): void {
    try {
      const context = getContext(this) as common.UIAbilityContext
      healthStore.init(context).then(() => {
        this.isInit = true
        this.resultText = '初始化成功'
      }).catch((error: BusinessError) => {
        this.resultText = `初始化失败: [${error.code}] ${error.message}`
      })
    } catch (error) {
      const err = error as BusinessError
      this.resultText = `初始化异常: [${err.code}] ${err.message}`
    }
  }

  private requestAuth(): void {
    try {
      this.resultText = '正在申请授权...'
      const context = getContext(this) as common.UIAbilityContext
      const request: healthStore.AuthorizationRequest = {
        readDataTypes: [
          healthStore.samplePointHelper.dailyActivities.DATA_TYPE
        ],
        writeDataTypes: []
      }
      healthStore.requestAuthorizations(context, request).then((response: healthStore.AuthorizationResponse) => {
        this.readDataTypes = response.readDataTypes.map((dt: healthStore.DataType) => dt.name ?? `id:${dt.id}`).join(', ')
        this.writeDataTypes = response.writeDataTypes.map((dt: healthStore.DataType) => dt.name ?? `id:${dt.id}`).join(', ')
        this.authStatus = '已授权'
        this.resultText = '成功申请授权'
      }).catch((error: BusinessError) => {
        this.resultText = `授权失败: [${error.code}] ${error.message}`
      })
    } catch (error) {
      const err = error as BusinessError
      this.resultText = `授权异常: [${err.code}] ${err.message}`
    }
  }

  private getAuth(): void {
    // getAuthorizations 在元服务编译中不可用（11706010错误）
    // 文档标记为元服务支持但编译器限制，此处仅展示用法说明
    this.resultText = '查询授权: getAuthorizations 在元服务中编译受限，请参考 healthStore.requestAuthorizations 后通过返回值确认授权状态'
  }

  private cancelAuth(): void {
    try {
      this.resultText = '正在取消授权...'
      healthStore.cancelAuthorizations().then(() => {
        this.authStatus = '未授权'
        this.readDataTypes = '--'
        this.writeDataTypes = '--'
        this.resultText = '成功取消授权'
      }).catch((error: BusinessError) => {
        this.resultText = `取消失败: [${error.code}] ${error.message}`
      })
    } catch (error) {
      const err = error as BusinessError
      this.resultText = `取消异常: [${err.code}] ${err.message}`
    }
  }
}
