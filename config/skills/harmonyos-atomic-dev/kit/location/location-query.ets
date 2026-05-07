/**
 * location-query — 查询当前位置信息
 * 使用 @ohos.geoLocationManager 获取经纬度坐标
 * 元服务API: 需申请 ohos.permission.APPROXIMATELY_LOCATION 和/或 ohos.permission.LOCATION
 */
import geoLocationManager from '@ohos.geoLocationManager'
import { BusinessError } from '@kit.BasicServicesKit'
import { hilog } from '@kit.PerformanceAnalysisKit'

@ComponentV2
export struct LocationQuery {
  @Local resultText: string = '点击按钮获取当前位置'
  @Local latitude: string = '--'
  @Local longitude: string = '--'
  @Local altitude: string = '--'
  @Local accuracy: string = '--'
  @Local speed: string = '--'
  @Local locationDirection: string = '--'
  @Local timeStamp: string = '--'
  @Local isLocating: boolean = false
  @Local locationHistory: string[] = []
  @Local eventLog: string[] = []

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('位置查询')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20, bottom: 10 })

        Text('geoLocationManager.getCurrentLocation() 获取当前位置')
          .fontSize(13)
          .fontColor('#666666')
          .width('90%')
          .textAlign(TextAlign.Center)

        // 结果展示
        Column({ space: 8 }) {
          Text(this.isLocating ? '正在获取位置...' : this.resultText)
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.resultText.includes('成功') ? '#00B578' :
              (this.resultText.includes('失败') || this.resultText.includes('错误') ? '#E84026' : '#333333'))
            .width('100%')

          Row() {
            Text('纬度: ')
              .fontSize(13)
              .fontColor('#999999')
            Text(this.latitude)
              .fontSize(13)
              .fontWeight(FontWeight.Medium)
              .layoutWeight(1)
          }
          .width('100%')

          Row() {
            Text('经度: ')
              .fontSize(13)
              .fontColor('#999999')
            Text(this.longitude)
              .fontSize(13)
              .fontWeight(FontWeight.Medium)
              .layoutWeight(1)
          }
          .width('100%')

          Row() {
            Text('海拔: ')
              .fontSize(13)
              .fontColor('#999999')
            Text(this.altitude)
              .fontSize(13)
              .layoutWeight(1)
          }
          .width('100%')

          Row() {
            Text('精度: ')
              .fontSize(13)
              .fontColor('#999999')
            Text(this.accuracy)
              .fontSize(13)
              .layoutWeight(1)
          }
          .width('100%')

          Row() {
            Text('速度: ')
              .fontSize(13)
              .fontColor('#999999')
            Text(this.speed)
              .fontSize(13)
              .layoutWeight(1)
          }
          .width('100%')

          Row() {
            Text('方向: ')
              .fontSize(13)
              .fontColor('#999999')
            Text(this.locationDirection)
              .fontSize(13)
              .layoutWeight(1)
          }
          .width('100%')

          Row() {
            Text('时间: ')
              .fontSize(13)
              .fontColor('#999999')
            Text(this.timeStamp)
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

        // 操作按钮
        Row({ space: 12 }) {
          Button('获取当前位置')
            .layoutWeight(1)
            .backgroundColor('#007DFF')
            .borderRadius(8)
            .enabled(!this.isLocating)
            .onClick(() => this.getCurrentLocation())
          Button('获取单次定位(优先GPS)')
            .layoutWeight(1)
            .backgroundColor('#00B578')
            .borderRadius(8)
            .enabled(!this.isLocating)
            .onClick(() => this.getLastLocation())
        }
        .width('90%')

        Button('检查定位服务状态')
          .width('90%')
          .backgroundColor('#FF9800')
          .borderRadius(8)
          .onClick(() => this.checkLocationService())

        // 位置历史
        if (this.locationHistory.length > 0) {
          Text('位置历史')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .alignSelf(ItemAlign.Start)
            .margin({ left: 16, top: 8 })

          Column({ space: 4 }) {
            ForEach(this.locationHistory, (item: string, index: number) => {
              Text(item)
                .fontSize(12)
                .fontColor('#333333')
                .width('100%')
                .padding(8)
                .backgroundColor(index % 2 === 0 ? '#F9F9F9' : '#FFFFFF')
                .borderRadius(4)
            }, (item: string, index: number) => `${index}`)
          }
          .width('90%')
          .padding(8)
          .backgroundColor('#F5F5F5')
          .borderRadius(8)
        }

        // 权限说明
        Text('所需权限')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Column({ space: 4 }) {
          Text('ohos.permission.APPROXIMATELY_LOCATION')
            .fontSize(12)
            .fontColor('#007DFF')
            .fontFamily('monospace')
            .width('100%')
          Text('粗略位置权限 (user_grant)，获取大致位置')
            .fontSize(12)
            .fontColor('#666666')
            .width('100%')
          Text('')
            .fontSize(8)
          Text('ohos.permission.LOCATION')
            .fontSize(12)
            .fontColor('#007DFF')
            .fontFamily('monospace')
            .width('100%')
          Text('精确位置权限 (user_grant)，需同时申请粗略位置权限')
            .fontSize(12)
            .fontColor('#666666')
            .width('100%')
        }
        .width('90%')
        .padding(12)
        .backgroundColor('#F0F5FF')
        .borderRadius(8)
        .alignItems(HorizontalAlign.Start)

        // 注意事项
        Column({ space: 4 }) {
          Text('注意事项')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 4 })
          Text('1. 需在 module.json5 声明 APPROXIMATELY_LOCATION 和 LOCATION 权限')
            .fontSize(12)
            .fontColor('#996600')
            .width('100%')
          Text('2. LOCATION 为 user_grant 类型，需运行时动态申请')
            .fontSize(12)
            .fontColor('#996600')
            .width('100%')
          Text('3. 元服务中定位能力可能受限，需在真机测试验证')
            .fontSize(12)
            .fontColor('#996600')
            .width('100%')
          Text('4. getCurrentLocation 需先判断定位服务开关状态')
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
          Text('import geoLocationManager from "@ohos.geoLocationManager"')
            .fontSize(12)
            .fontColor('#007DFF')
            .fontFamily('monospace')
          Text('')
            .fontSize(8)
          Text('// 检查定位服务是否开启')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('geoLocationManager.isLocationEnabled()')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('')
            .fontSize(8)
          Text('// 获取当前位置（单次）')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('let location = await geoLocationManager.getCurrentLocation()')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('// location.latitude / location.longitude')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('// location.altitude / location.accuracy / location.speed')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('')
            .fontSize(8)
          Text('// 获取缓存位置（优先GPS）')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('let lastLoc = geoLocationManager.getLastLocation()')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
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
   * 获取当前位置
   */
  private async getCurrentLocation(): Promise<void> {
    this.isLocating = true
    this.resultText = '正在获取位置...'
    try {
      const location = await geoLocationManager.getCurrentLocation()
      hilog.info(0x0000, 'LocationQuery', `Location: ${JSON.stringify(location)}`)
      this.latitude = `${location.latitude}`
      this.longitude = `${location.longitude}`
      this.altitude = location.altitude !== undefined ? `${location.altitude} m` : '--'
      this.accuracy = location.accuracy !== undefined ? `${location.accuracy} m` : '--'
      this.speed = location.speed !== undefined ? `${location.speed} m/s` : '--'
      this.locationDirection = location.direction !== undefined ? `${location.direction} deg` : '--'
      this.timeStamp = new Date(location.timeStamp).toLocaleString()
      this.resultText = '获取位置成功'
      const time = new Date().toLocaleTimeString()
      this.locationHistory = [
        `[${time}] lat: ${location.latitude}, lng: ${location.longitude}`,
        ...this.locationHistory
      ].slice(0, 10)
    } catch (error) {
      const err = error as BusinessError
      hilog.error(0x0000, 'LocationQuery', `getCurrentLocation failed: ${err.code}, ${err.message}`)
      this.resultText = `获取位置失败: [${err.code}] ${err.message}`
    }
    this.isLocating = false
    this.addLog(this.resultText)
  }

  /**
   * 获取缓存位置（优先GPS）
   */
  private getLastLocation(): void {
    try {
      const location = geoLocationManager.getLastLocation()
      if (location) {
        hilog.info(0x0000, 'LocationQuery', `Last location: ${JSON.stringify(location)}`)
        this.latitude = `${location.latitude}`
        this.longitude = `${location.longitude}`
        this.altitude = location.altitude !== undefined ? `${location.altitude} m` : '--'
        this.accuracy = location.accuracy !== undefined ? `${location.accuracy} m` : '--'
        this.speed = location.speed !== undefined ? `${location.speed} m/s` : '--'
        this.locationDirection = location.direction !== undefined ? `${location.direction} deg` : '--'
        this.timeStamp = new Date(location.timeStamp).toLocaleString()
        this.resultText = '缓存位置获取成功'
        const time = new Date().toLocaleTimeString()
        this.locationHistory = [
          `[${time}] [缓存] lat: ${location.latitude}, lng: ${location.longitude}`,
          ...this.locationHistory
        ].slice(0, 10)
      } else {
        this.resultText = '无缓存位置数据'
      }
    } catch (error) {
      const err = error as BusinessError
      hilog.error(0x0000, 'LocationQuery', `getLastLocation failed: ${err.code}, ${err.message}`)
      this.resultText = `获取缓存位置失败: [${err.code}] ${err.message}`
    }
    this.addLog(this.resultText)
  }

  /**
   * 检查定位服务状态
   */
  private checkLocationService(): void {
    try {
      const enabled = geoLocationManager.isLocationEnabled()
      this.resultText = enabled ? '定位服务已开启' : '定位服务未开启，请在系统设置中开启'
      hilog.info(0x0000, 'LocationQuery', `Location enabled: ${enabled}`)
    } catch (error) {
      const err = error as BusinessError
      this.resultText = `查询定位状态失败: [${err.code}] ${err.message}`
    }
    this.addLog(this.resultText)
  }

  private addLog(msg: string): void {
    const time = new Date().toLocaleTimeString()
    this.eventLog = [`[${time}] ${msg}`, ...this.eventLog].slice(0, 15)
  }
}
