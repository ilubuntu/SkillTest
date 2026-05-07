/**
 * device-info — 设备信息查询场景
 * @ohos.deviceInfo 模块 — 设备品牌、型号、类型、系统版本等
 * 元服务API: 无需权限，同步获取设备基础信息
 */
import deviceInfo from '@ohos.deviceInfo'
import { BusinessError } from '@kit.BasicServicesKit'

@ComponentV2
export struct DeviceInfo {
  @Local resultText: string = '点击按钮查询设备信息'
  @Local brand: string = '--'
  @Local model: string = '--'
  @Local deviceType: string = '--'
  @Local osVersion: string = '--'
  @Local sdkVersion: string = '--'
  @Local fullInfo: string = '--'

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('设备信息查询')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20, bottom: 10 })

        Text('deviceInfo.brand / model / deviceType / osFullName / sdkApiVersion')
          .fontSize(13)
          .fontColor('#666666')
          .width('90%')
          .textAlign(TextAlign.Center)

        // 结果展示
        Column({ space: 8 }) {
          Text('查询结果')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .width('100%')
          Text(this.resultText)
            .fontSize(13)
            .fontColor(this.resultText.includes('成功') ? '#00B578' :
              (this.resultText.includes('失败') || this.resultText.includes('错误') ? '#E84026' : '#333333'))
            .width('100%')
          Row() {
            Text('品牌: ')
              .fontSize(12)
              .fontColor('#999999')
            Text(this.brand)
              .fontSize(12)
              .layoutWeight(1)
          }
          .width('100%')
          Row() {
            Text('型号: ')
              .fontSize(12)
              .fontColor('#999999')
            Text(this.model)
              .fontSize(12)
              .layoutWeight(1)
          }
          .width('100%')
          Row() {
            Text('设备类型: ')
              .fontSize(12)
              .fontColor('#999999')
            Text(this.deviceType)
              .fontSize(12)
              .layoutWeight(1)
          }
          .width('100%')
          Row() {
            Text('系统版本: ')
              .fontSize(12)
              .fontColor('#999999')
            Text(this.osVersion)
              .fontSize(12)
              .layoutWeight(1)
          }
          .width('100%')
          Row() {
            Text('SDK版本: ')
              .fontSize(12)
              .fontColor('#999999')
            Text(this.sdkVersion)
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

        // 完整信息展示
        Column({ space: 8 }) {
          Text('完整设备信息 (JSON)')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .width('100%')
          Text(this.fullInfo)
            .fontSize(11)
            .fontColor('#333333')
            .width('100%')
            .maxLines(12)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .copyOption(CopyOptions.LocalDevice)
        }
        .width('90%')
        .padding(16)
        .backgroundColor('#F5F5F5')
        .borderRadius(12)
        .alignItems(HorizontalAlign.Start)

        // 操作按钮
        Row({ space: 12 }) {
          Button('查询基本信息')
            .layoutWeight(1)
            .backgroundColor('#007DFF')
            .borderRadius(8)
            .onClick(() => this.doQueryBasic())
          Button('查询全部信息')
            .layoutWeight(1)
            .backgroundColor('#00B578')
            .borderRadius(8)
            .onClick(() => this.doQueryAll())
        }
        .width('90%')

        // 提示信息
        Column() {
          Text('注意事项')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 4 })
          Text('1. deviceInfo 为同步API，无需异步调用，无需权限')
            .fontSize(12)
            .fontColor('#996600')
            .width('100%')
          Text('2. deviceType 返回值: "phone"(手机)、"tablet"(平板)、"2in1"(二合一) 等')
            .fontSize(12)
            .fontColor('#996600')
            .width('100%')
          Text('3. 部分属性如 serial、udid 在元服务中不可用（需系统权限）')
            .fontSize(12)
            .fontColor('#996600')
            .width('100%')
          Text('4. 建议用于UI适配、日志上报、兼容性判断等场景')
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
          Text('import deviceInfo from "@ohos.deviceInfo"')
            .fontSize(12)
            .fontColor('#007DFF')
            .fontFamily('monospace')
          Text('// 同步获取，无需权限')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('deviceInfo.brand          // 品牌 (如 "HUAWEI")')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('deviceInfo.model          // 型号 (如 "NOH-AN00")')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('deviceInfo.deviceType     // 设备类型')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('deviceInfo.osFullName     // 系统完整版本')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('deviceInfo.sdkApiVersion  // SDK API 版本号')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('deviceInfo.manufacturer   // 制造商')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('deviceInfo.productSeries  // 产品系列')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('deviceInfo.marketName     // 市场名称')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('')
            .fontSize(8)
          Text('元服务API: 无需权限，同步获取')
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

  private parseDeviceType(type: string): string {
    const typeMap: Record<string, string> = {
      'phone': '手机 (phone)',
      'tablet': '平板 (tablet)',
      '2in1': '二合一设备 (2in1)',
      'tv': '智慧屏 (tv)',
      'wearable': '穿戴设备 (wearable)',
      'car': '车机 (car)',
      'default': '默认设备 (default)',
    }
    return typeMap[type] || `未知 (${type})`
  }

  private doQueryBasic(): void {
    try {
      this.brand = deviceInfo.brand || '--'
      this.model = deviceInfo.productModel || '--'
      this.deviceType = this.parseDeviceType(deviceInfo.deviceType || '--')
      this.osVersion = deviceInfo.osFullName || '--'
      this.sdkVersion = `${deviceInfo.sdkApiVersion ?? '--'}`
      this.resultText = '基本信息查询成功'
    } catch (error) {
      const err = error as BusinessError
      this.resultText = `查询失败: [${err.code}] ${err.message}`
    }
  }

  private doQueryAll(): void {
    try {
      const info: Record<string, string> = {
        'brand': deviceInfo.brand || '',
        'model': deviceInfo.productModel || '',
        'deviceType': deviceInfo.deviceType || '',
        'manufacturer': '(原子化服务不支持 manufacture)',
        'productSeries': '(原子化服务不支持 productSeries)',
        'productModel': deviceInfo.productModel || '',
        'marketName': '(原子化服务不支持 marketName)',
        'osFullName': deviceInfo.osFullName || '',
        'osReleaseType': '(原子化服务不支持 osReleaseType)',
        'sdkApiVersion': `${deviceInfo.sdkApiVersion ?? ''}`,
        'displayVersion': '(原子化服务不支持 displayVersion)',
        'buildType': '(原子化服务不支持 buildType)',
        'hardwareModel': '(原子化服务不支持 hardwareModel)',
        'hardwareProfile': '(原子化服务不支持 hardwareProfile)',
        'serial': '(受限，需系统权限)',
        'udid': '(受限，需系统权限)',
      }
      this.brand = info['brand'] || '--'
      this.model = info['model'] || '--'
      this.deviceType = this.parseDeviceType(info['deviceType'] || '--')
      this.osVersion = info['osFullName'] || '--'
      this.sdkVersion = info['sdkApiVersion']
      this.fullInfo = JSON.stringify(info, null, 2)
      this.resultText = '全部信息查询成功'
    } catch (error) {
      const err = error as BusinessError
      this.resultText = `查询失败: [${err.code}] ${err.message}`
    }
  }
}
