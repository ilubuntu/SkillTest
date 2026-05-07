/**
 * health-service-data-aggregate — 运动健康聚合数据查询
 * 元服务API：healthStore.aggregateData() 从 5.0.0(12) 起支持
 * 支持按天聚合查询每日步数、卡路里、距离等活动数据
 * 调用前需先使用 healthStore.init() 进行初始化
 */

import { healthStore } from '@kit.HealthServiceKit'
import { common } from '@kit.AbilityKit'
import { BusinessError } from '@kit.BasicServicesKit'

@ComponentV2
export struct HealthServiceDataAggregate {
  @Local resultText: string = '等待查询...'
  @Local isInit: boolean = false
  @Local startDate: string = this.getTodayStr()
  @Local endDate: string = this.getTodayStr()
  @Local aggregateResult: string = '--'

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('健康数据聚合查询')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20, bottom: 10 })

        Text('通过 healthStore.aggregateData() 按天聚合查询运动健康数据')
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

        // 参数控制区
        Column({ space: 8 }) {
          Text('查询参数')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')

          Row() {
            Text('开始日期:')
              .fontSize(13)
              .width(80)
            TextInput({ text: this.startDate, placeholder: 'MM/DD/YYYY' })
              .fontSize(13)
              .layoutWeight(1)
              .height(40)
              .borderRadius(8)
              .onChange((value: string) => { this.startDate = value })
          }
          .width('100%')

          Row() {
            Text('结束日期:')
              .fontSize(13)
              .width(80)
            TextInput({ text: this.endDate, placeholder: 'MM/DD/YYYY' })
              .fontSize(13)
              .layoutWeight(1)
              .height(40)
              .borderRadius(8)
              .onChange((value: string) => { this.endDate = value })
          }
          .width('100%')

          Text('日期格式: MM/DD/YYYY，如 10/30/2023')
            .fontSize(11)
            .fontColor('#999999')
            .width('100%')
        }
        .width('90%')
        .padding(16)
        .backgroundColor('#FFFFFF')
        .borderRadius(12)
        .border({ width: 1, color: '#E0E0E0' })
        .alignItems(HorizontalAlign.Start)

        // 操作按钮
        Row({ space: 12 }) {
          Button('初始化')
            .fontSize(13)
            .borderRadius(8)
            .onClick(() => this.initHealthStore())

          Button('查询聚合数据')
            .fontSize(13)
            .borderRadius(8)
            .enabled(this.isInit)
            .onClick(() => this.queryAggregate())
        }
        .width('90%')
        .justifyContent(FlexAlign.Center)

        // 结果展示
        Column({ space: 8 }) {
          Text('查询结果:')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .width('100%')
          Text(this.resultText)
            .fontSize(13)
            .fontColor(this.resultText.startsWith('查询成功') ? '#00B578' : '#E84026')
            .width('100%')
        }
        .width('90%')
        .padding(12)
        .backgroundColor('#F5F5F5')
        .borderRadius(12)
        .alignItems(HorizontalAlign.Start)

        // 聚合数据详情
        Column({ space: 6 }) {
          Text('聚合数据详情')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
          Text(this.aggregateResult)
            .fontSize(12)
            .fontColor('#333333')
            .fontFamily('monospace')
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
          Text('2. 聚合查询需要先通过 requestAuthorizations 获取读权限')
            .fontSize(12)
            .fontColor('#666666')
            .width('100%')
          Text('3. 仅支持 Phone/Tablet，Wearable 返回 1002700001 错误')
            .fontSize(12)
            .fontColor('#666666')
            .width('100%')
          Text('4. 聚合策略支持: max, min, avg, sum, last, count')
            .fontSize(12)
            .fontColor('#666666')
            .width('100%')
          Text('5. 按天聚合(groupBy unitType=DAY)当前只支持 duration=1')
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
          Text('// 构建聚合请求')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('let request: AggregateRequest = {')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('  dataType: samplePointHelper.dailyActivities.DATA_TYPE,')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('  metrics: { step: ["sum"], calorie: ["sum"] },')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('  groupBy: { unitType: GroupUnitType.DAY },')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('  startLocalDate: "10/30/2023",')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('  endLocalDate: "10/30/2023"')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('}')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('const results = await healthStore.aggregateData(request)')
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

  private getTodayStr(): string {
    const now = new Date()
    const month = String(now.getMonth() + 1).padStart(2, '0')
    const day = String(now.getDate()).padStart(2, '0')
    const year = now.getFullYear()
    return `${month}/${day}/${year}`
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

  private queryAggregate(): void {
    try {
      this.resultText = '正在查询...'
      this.aggregateResult = '查询中...'
      const aggregateRequest: healthStore.AggregateRequest<healthStore.samplePointHelper.dailyActivities.AggregateFields> = {
        dataType: healthStore.samplePointHelper.dailyActivities.DATA_TYPE,
        metrics: {
          step: ['sum'],
          calorie: ['sum'],
          distance: ['sum']
        },
        groupBy: {
          unitType: healthStore.GroupUnitType.DAY
        },
        startLocalDate: this.startDate,
        endLocalDate: this.endDate
      }
      healthStore.aggregateData<healthStore.samplePointHelper.dailyActivities.AggregateResult>(aggregateRequest).then((results: healthStore.samplePointHelper.dailyActivities.AggregateResult[]) => {
        if (results.length === 0) {
          this.aggregateResult = '无数据'
          this.resultText = '查询成功，但无数据返回'
          return
        }
        let detail = ''
        results.forEach((result: healthStore.AggregateResult, index: number) => {
          detail += `--- 第${index + 1}天 ---\n`
          detail += `开始时间: ${result.startTime}\n`
          detail += `结束时间: ${result.endTime}\n`
          const fields = result.fields as Record<string, Record<string, number>>
          if (fields) {
            Object.keys(fields).forEach((fieldName: string) => {
              detail += `${fieldName}: ${JSON.stringify(fields[fieldName])}\n`
            })
          }
          detail += '\n'
        })
        this.aggregateResult = detail
        this.resultText = `查询成功，共${results.length}条记录`
      }).catch((error: BusinessError) => {
        this.aggregateResult = '--'
        this.resultText = `查询失败: [${error.code}] ${error.message}`
      })
    } catch (error) {
      const err = error as BusinessError
      this.aggregateResult = '--'
      this.resultText = `查询异常: [${err.code}] ${err.message}`
    }
  }
}
