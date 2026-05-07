/**
 * health-service-unsupported — 元服务不支持的运动健康联动服务 API 说明
 * healthService.workout 中的联动控制、数据监听、事件发送等 API 在元服务中不可用
 * 这些 API 仅支持 Phone/Tablet/Wearable 普通应用，不支持 atomicService
 */

@ComponentV2
export struct HealthServiceUnsupported {
  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('健康联动服务 API 限制')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20, bottom: 10 })

        Text('healthService.workout 联动控制类 API 在元服务中不可用')
          .fontSize(13)
          .fontColor('#666666')
          .width('90%')
          .textAlign(TextAlign.Center)

        // 1. 联动配置
        Column({ space: 8 }) {
          Row() {
            Text('workout.config()')
              .fontSize(14)
              .fontWeight(FontWeight.Bold)
              .layoutWeight(1)
            Text('不可用')
              .fontSize(12)
              .fontColor('#E84026')
              .fontWeight(FontWeight.Medium)
          }
          .width('100%')
          Text('配置联动运动参数（联动类型、运动类型、目标等）')
            .fontSize(12)
            .fontColor('#666666')
            .width('100%')
          Text('起始版本 5.1.0(18)，元服务不支持')
            .fontSize(12)
            .fontColor('#996600')
            .width('100%')
        }
        .width('90%')
        .padding(16)
        .backgroundColor('#FFF3CD')
        .borderRadius(12)
        .alignItems(HorizontalAlign.Start)

        // 2. 联动控制
        Column({ space: 8 }) {
          Row() {
            Text('workout.start / pause / resume / stop')
              .fontSize(14)
              .fontWeight(FontWeight.Bold)
              .layoutWeight(1)
            Text('不可用')
              .fontSize(12)
              .fontColor('#E84026')
              .fontWeight(FontWeight.Medium)
          }
          .width('100%')
          Text('开启/暂停/恢复/停止运动联动，控制穿戴设备运动状态')
            .fontSize(12)
            .fontColor('#666666')
            .width('100%')
          Text('起始版本 5.1.0(18)，元服务不支持')
            .fontSize(12)
            .fontColor('#996600')
            .width('100%')
        }
        .width('90%')
        .padding(16)
        .backgroundColor('#FFF3CD')
        .borderRadius(12)
        .alignItems(HorizontalAlign.Start)

        // 3. 数据监听
        Column({ space: 8 }) {
          Row() {
            Text('workout.onData / offData')
              .fontSize(14)
              .fontWeight(FontWeight.Bold)
              .layoutWeight(1)
            Text('不可用')
              .fontSize(12)
              .fontColor('#E84026')
              .fontWeight(FontWeight.Medium)
          }
          .width('100%')
          Text('注册/取消联动运动数据监听，接收实时心率、步频等数据')
            .fontSize(12)
            .fontColor('#666666')
            .width('100%')
          Text('起始版本 5.1.0(18)，元服务不支持')
            .fontSize(12)
            .fontColor('#996600')
            .width('100%')
        }
        .width('90%')
        .padding(16)
        .backgroundColor('#FFF3CD')
        .borderRadius(12)
        .alignItems(HorizontalAlign.Start)

        // 4. 事件监听与发送
        Column({ space: 8 }) {
          Row() {
            Text('workout.onEvent / offEvent / sendEvent')
              .fontSize(14)
              .fontWeight(FontWeight.Bold)
              .layoutWeight(1)
            Text('不可用')
              .fontSize(12)
              .fontColor('#E84026')
              .fontWeight(FontWeight.Medium)
          }
          .width('100%')
          Text('监听联动设备事件、向联动设备下发控制事件')
            .fontSize(12)
            .fontColor('#666666')
            .width('100%')
          Text('起始版本 5.1.0(18)，元服务不支持')
            .fontSize(12)
            .fontColor('#996600')
            .width('100%')
        }
        .width('90%')
        .padding(16)
        .backgroundColor('#FFF3CD')
        .borderRadius(12)
        .alignItems(HorizontalAlign.Start)

        // 5. 数据发送
        Column({ space: 8 }) {
          Row() {
            Text('workout.sendData')
              .fontSize(14)
              .fontWeight(FontWeight.Bold)
              .layoutWeight(1)
            Text('不可用')
              .fontSize(12)
              .fontColor('#E84026')
              .fontWeight(FontWeight.Medium)
          }
          .width('100%')
          Text('下发融合运动数据到联动设备')
            .fontSize(12)
            .fontColor('#666666')
            .width('100%')
          Text('起始版本 5.1.0(18)，元服务不支持')
            .fontSize(12)
            .fontColor('#996600')
            .width('100%')
        }
        .width('90%')
        .padding(16)
        .backgroundColor('#FFF3CD')
        .borderRadius(12)
        .alignItems(HorizontalAlign.Start)

        // 6. syncAll
        Column({ space: 8 }) {
          Row() {
            Text('healthStore.syncAll')
              .fontSize(14)
              .fontWeight(FontWeight.Bold)
              .layoutWeight(1)
            Text('不可用')
              .fontSize(12)
              .fontColor('#E84026')
              .fontWeight(FontWeight.Medium)
          }
          .width('100%')
          Text('用户主动触发数据同步，无元服务API标记')
            .fontSize(12)
            .fontColor('#666666')
            .width('100%')
          Text('起始版本 5.1.0(18)，元服务不支持')
            .fontSize(12)
            .fontColor('#996600')
            .width('100%')
        }
        .width('90%')
        .padding(16)
        .backgroundColor('#FFF3CD')
        .borderRadius(12)
        .alignItems(HorizontalAlign.Start)

        // 替代方案
        Text('替代方案')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Column({ space: 6 }) {
          Text('方案一: 使用元服务支持的读取 API')
            .fontSize(13)
            .fontWeight(FontWeight.Bold)
            .width('100%')
          Text('readActivityReport() 可获取当日三环数据')
            .fontSize(12)
            .fontColor('#00B578')
            .width('100%')
          Text('aggregateData() 可聚合查询历史运动数据')
            .fontSize(12)
            .fontColor('#00B578')
            .width('100%')
        }
        .width('90%')
        .padding(12)
        .backgroundColor('#E8F5E9')
        .borderRadius(8)
        .alignItems(HorizontalAlign.Start)

        Column({ space: 6 }) {
          Text('方案二: 转为普通应用开发')
            .fontSize(13)
            .fontWeight(FontWeight.Bold)
            .width('100%')
          Text('如需完整的联动控制能力，需开发为普通应用而非元服务')
            .fontSize(12)
            .fontColor('#00B578')
            .width('100%')
        }
        .width('90%')
        .padding(12)
        .backgroundColor('#E8F5E9')
        .borderRadius(8)
        .alignItems(HorizontalAlign.Start)

        // 总结
        Column({ space: 4 }) {
          Text('降级策略总结')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 4 })
          Text('1. 联动控制 (config/start/pause/resume/stop) → 元服务不可用，需普通应用')
            .fontSize(12)
            .fontColor('#333333')
            .width('100%')
          Text('2. 数据监听 (onData/offData) → 元服务不可用，需普通应用')
            .fontSize(12)
            .fontColor('#333333')
            .width('100%')
          Text('3. 事件发送 (sendEvent/sendData) → 元服务不可用，需普通应用')
            .fontSize(12)
            .fontColor('#333333')
            .width('100%')
          Text('4. 数据同步 (syncAll) → 元服务不可用')
            .fontSize(12)
            .fontColor('#333333')
            .width('100%')
          Text('5. 可用替代 → readActivityReport() + aggregateData() 满足只读场景')
            .fontSize(12)
            .fontColor('#333333')
            .width('100%')
        }
        .width('90%')
        .padding(16)
        .backgroundColor('#E8F5E9')
        .borderRadius(12)
        .alignItems(HorizontalAlign.Start)
        .margin({ bottom: 20 })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
  }
}
