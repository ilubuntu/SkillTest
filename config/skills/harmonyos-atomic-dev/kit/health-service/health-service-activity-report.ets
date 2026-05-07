/**
 * health-service-activity-report — 读取实时三环数据（步数、活动热量、锻炼时长）
 * 元服务API：healthService.workout.readActivityReport() 从 5.0.0(12) 起支持
 * 调用前需先使用 healthStore.init() 进行初始化
 */

import { healthService, healthStore } from '@kit.HealthServiceKit'
import { common } from '@kit.AbilityKit'
import { BusinessError } from '@kit.BasicServicesKit'

@ComponentV2
export struct HealthServiceActivityReport {
  @Local resultText: string = '等待读取...'
  @Local steps: string = '--'
  @Local stepsGoal: string = '--'
  @Local activeCalories: string = '--'
  @Local activeCaloriesGoal: string = '--'
  @Local exercise: string = '--'
  @Local exerciseGoal: string = '--'
  @Local activeHours: string = '--'
  @Local activeHoursGoal: string = '--'
  @Local isInit: boolean = false

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('实时三环数据')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20, bottom: 10 })

        Text('通过 healthService.workout.readActivityReport() 读取当日步数、活动热量、锻炼时长等三环数据')
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

        // 操作按钮
        Row({ space: 12 }) {
          Button('初始化 HealthStore')
            .fontSize(13)
            .borderRadius(8)
            .onClick(() => this.initHealthStore())

          Button('读取三环数据')
            .fontSize(13)
            .borderRadius(8)
            .enabled(this.isInit)
            .onClick(() => this.readActivityReport())
        }
        .width('90%')
        .justifyContent(FlexAlign.Center)

        // 结果展示
        Column({ space: 8 }) {
          Text('读取结果:')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .width('100%')
          Text(this.resultText)
            .fontSize(13)
            .fontColor(this.resultText.startsWith('读取成功') ? '#00B578' : '#E84026')
            .width('100%')
        }
        .width('90%')
        .padding(12)
        .backgroundColor('#F5F5F5')
        .borderRadius(12)
        .alignItems(HorizontalAlign.Start)

        // 三环数据展示
        Column({ space: 10 }) {
          Text('三环数据详情')
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .width('100%')

          // 步数环
          Row() {
            Text('步数')
              .fontSize(13)
              .fontWeight(FontWeight.Medium)
              .layoutWeight(1)
            Text(`${this.steps} / ${this.stepsGoal}`)
              .fontSize(13)
              .fontColor('#007DFF')
          }
          .width('100%')

          // 活动热量环
          Row() {
            Text('活动热量(卡)')
              .fontSize(13)
              .fontWeight(FontWeight.Medium)
              .layoutWeight(1)
            Text(`${this.activeCalories} / ${this.activeCaloriesGoal}`)
              .fontSize(13)
              .fontColor('#FF6B00')
          }
          .width('100%')

          // 锻炼时长环
          Row() {
            Text('锻炼时长(分钟)')
              .fontSize(13)
              .fontWeight(FontWeight.Medium)
              .layoutWeight(1)
            Text(`${this.exercise} / ${this.exerciseGoal}`)
              .fontSize(13)
              .fontColor('#00B578')
          }
          .width('100%')

          // 活动小时数
          Row() {
            Text('活动小时数')
              .fontSize(13)
              .fontWeight(FontWeight.Medium)
              .layoutWeight(1)
            Text(`${this.activeHours} / ${this.activeHoursGoal}`)
              .fontSize(13)
              .fontColor('#9B59B6')
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
          Text('2. 需要用户已登录华为账号并同意隐私协议')
            .fontSize(12)
            .fontColor('#666666')
            .width('100%')
          Text('3. stepsGoal 等目标值可能为空（用户未设置目标时）')
            .fontSize(12)
            .fontColor('#666666')
            .width('100%')
          Text('4. 仅支持 Phone/Tablet 设备，不支持 Wearable')
            .fontSize(12)
            .fontColor('#666666')
            .width('100%')
          Text('5. 模拟器中不支持实时三环数据，需真机测试')
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
          Text('import { healthService, healthStore } from "@kit.HealthServiceKit"')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('')
            .fontSize(8)
          Text('// 初始化（仅首次调用需要）')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('await healthStore.init(context)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('')
            .fontSize(8)
          Text('// 读取实时三环数据')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('const report = await healthService.workout.readActivityReport()')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('// report.steps, report.activeCalories, report.exercise')
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

  private readActivityReport(): void {
    try {
      this.resultText = '正在读取...'
      healthService.workout.readActivityReport().then((report: healthService.workout.ActivityReport) => {
        this.steps = String(report.steps ?? '--')
        this.stepsGoal = report.stepsGoal !== undefined ? String(report.stepsGoal) : '未设置'
        this.activeCalories = String(report.activeCalories ?? '--')
        this.activeCaloriesGoal = report.activeCaloriesGoal !== undefined ? String(report.activeCaloriesGoal) : '未设置'
        this.exercise = String(report.exercise ?? '--')
        this.exerciseGoal = report.exerciseGoal !== undefined ? String(report.exerciseGoal) : '未设置'
        this.activeHours = String(report.activeHours ?? '--')
        this.activeHoursGoal = report.activeHoursGoal !== undefined ? String(report.activeHoursGoal) : '未设置'
        this.resultText = '读取成功'
      }).catch((error: BusinessError) => {
        this.resultText = `读取失败: [${error.code}] ${error.message}`
      })
    } catch (error) {
      const err = error as BusinessError
      this.resultText = `读取异常: [${err.code}] ${err.message}`
    }
  }
}
